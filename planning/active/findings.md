# Findings — Per-year ERA5-Land snow for a watershed, and the regression of the Maxan window series on peak SWE and melt date (#121)

## Issue context

**If we do it:** each year's peak snow water equivalent and 50 % melt date is known for any FWA watershed from 1950, and "more snow and later melt meant more flow during migration" is a regression with a coefficient and an error, tested at Maxan Creek. **If we never do:** the pilot's year-to-year flow has explanations only in prose.

Component 2 of #118.

## Problem

`wet_snow_normals()` reads cd's annual ERA5-Land snow layers (one band per year) and averages them over `years` onto a grid, for the 1981–2010 predictors (#16). Nothing in wet returns those values per year, and nothing returns them for one watershed.

## Proposed approach

1. **A per-year sibling of `wet_snow_normals()`** that returns `swe_max` and `snowmelt_doy_50` (and any other annual cd snow variable, such as `snowmelt_rate_peak`) by year for a watershed polygon, area-weighted over its fundamental watersheds as `wet_ws_sample()` does, with the same glacier cap. First measure which years cd's bands cover; if they do not reach 1950, or a variable is missing, that is a cd issue before anything here.
2. **The regression at the pilot.** The extended Maxan window series from #120, and the observed series at 08EE003 and 08EE013, against each year's `swe_max` and melt date for its watershed, with the coefficients, their intervals and the residual error reported. Also against the departure series rather than the raw flow, so the test is about change.
3. **Outputs.** The function with tests and an example on bundled data; a section in `research/station_flow_departure.md`.

Scope is the three pilot watersheds. Province-wide per-year snow is the last component's concern.

Depends on #120 for the series it explains; the function itself does not.

Relates to #118, #16.


## Exploration, 2026-10-26 (plan mode, before the baseline)

### cd's annual snow layers cover 1950–2025 (the issue's step 1)

Read from the remote GeoTIFF headers (`/vsicurl/https://stac-era5-land.s3.us-west-2.amazonaws.com/<var>_annual.tif`, no download), cd 0.5.0's `cd_catalog()`:

| variable | bands | first | last | res | extent |
|---|---|---|---|---|---|
| `swe_max` | 76 | 1950 | 2025 | 0.1° | −140.05…−113.95 × 47.95…60.05 |
| `snowmelt_doy_50` | 76 | 1950 | 2025 | 0.1° | same |
| `snowmelt_rate_peak` | 76 | 1950 | 2025 | 0.1° | same |
| `snowmelt`, `swe`, `snowfall` (annual) | 76 | 1950 | 2025 | 0.1° | same |

Tags on the files: `CD_RUN_TIME 2026-10-10T22:36:36Z`, `CD_VERSION 0.6.3`, `CD_SHA 349f9d72…`. Units (cd's `R/cd_variables.R`): `swe_max` mm, `snowmelt_doy_50` day of year, `snowmelt_rate_peak` mm/wk ("peak weekly melt rate", the annual maximum of the 7-day rolling daily melt).

NA pattern: over the pilot box (−127.6…−125.6 × 53.9…54.9, 200 cells) no band of the three variables has an NA cell; domain-wide every `snowmelt_doy_50` band has the same 10,842 NA cells (the sea). So sampling all years at once through `wet_ws_sample()` (a cell counts only where every layer has a value) drops nothing on land here. Value ranges in the box: `swe_max` 2–1,783 mm, `snowmelt_doy_50` day 97–212, `snowmelt_rate_peak` 1.5–329 mm/wk.

### The pilot gauges on fwapg

`wet_station_snap()` on the local fwapg (`fresh-db`, localhost:5432; `WET_PG*` unset, defaults reach it) from HYDAT 20260717 `STATIONS` coordinates and gross drainage area:

| gauge | `watershed_feature_id` | `wscode` | upstream km² (fwapg) | area ratio | fundamental watersheds | WKB |
|---|---|---|---|---|---|---|
| 08EE003 Bulkley near Houston | 7653689 | 400.431358 | 2,315.1 | 0.998 | ~5,450 | 6.2 MB |
| 08EE013 Buck Creek | 7619666 | 400.431358.623573 | 566.8 | 0.997 | ~1,005 | 1.25 MB |
| 08EE018 Maxan Creek | 9939958 | 400.431358.918528 | 364.0 | 1.002 | ~790 | 0.9 MB |

All three `accepted`. The counts came back as `integer64` printed as doubles (the driver-type trap in `code-check-r.md`), so they are read off the bit pattern and marked approximate; the data-raw script asserts them as integers. Only 08EE013 is in `data/wb/stations_20260717.rds`; 08EE003 and 08EE018 are snapped in the script. Upstream set: `FWA_Upstream(a.wscode_ltree, a.localcode_ltree, b.wscode_ltree, b.localcode_ltree)` with `b.wscode_ltree <@ a.wscode_ltree` (`scripts/upstream_area_check.R:69`).

### What exists to reuse

- `wet_snow_normals()` (`R/wet_snow_normals.R`): catalog lookup (one `annual` row per variable), `cd::cd_cache_fetch()` for a remote href, the band-year check, the CRS check, `cap` validation, the 2-cell crop margin. `wet_snow_method` is its version string.
- `wet_ws_sample(r, ws, "area")` (`R/wet_ws_sample.R`): exact-fraction cell means per polygon, one `cover` across layers; `wet_ws_frame()` shapes the result.
- `wet_upstream_means()` (`R/wet_upstream_means.R`): `sum(x * area * cover) / sum(area * cover)`, the aggregation the new function uses over polygons.
- `local_snow()` in `tests/testthat/test-wet_snow_normals.R`: synthetic one-band-per-year layers (value = year − 1980, optional sea columns).
- `scripts/departure_pilot.R`: `mx[[paste(v, p)]]$e` is Maxan's extended series (`year, value, dep, source, donor`, attribute `donors`) and `$a` the carried departures (`wet_departure_carry()`'s frame), per statistic × window (lines ~674–730); `ws` holds `wet_window_stats()` rows for the box pool. The script writes only the report, so the series must be saved for the regression. Its five code-check rounds, each regenerating the report twice, were 10–15 min apart: a run takes a few minutes.
- `tests/testthat/helper-fwapg.R`: `local_fwapg()` (skip without a database, never on CI).

### Open until the body is written

- The bundle's size: Maxan's outline alone is small; the raster crop (three variables × 76 bands × roughly 15 × 12 cells) is about 160 KB uncompressed. Measured by `data-raw/snow_pilot_data.R`, which refuses over 500 KB.
- Whether `snowmelt_doy_50` is ever NA over land in a snow-free year anywhere in BC: not in the pilot box, not in the domain-wide count (constant 10,842). Noted for a province-wide user of the function; the function reports `cover`.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `count(*)` over fwapg printed as `2.69e-320` | RPostgres returns `integer64`; `print()` shows its bits as a double. Cast in SQL (`count(*)::int`) or `as.integer()` before printing. |

## Results (2026-10-26, `data/checks/departure_snow_20260717.txt`)

- Migration-window mean: both slopes positive with 90 % intervals excluding zero in all four series (both-predictor fits); R² 0.40-0.50; residual SE 0.20-0.28 log. Spawning window: R² <= 0.07, every interval spans zero.
- Snow change 1950-1980 to 2011-2025: peak SWE -9 to -11 mm (3-4 %), melt date 9-11 days earlier, in all three watersheds.
- Parity with the shipped normals: within 0.86 mm and 0.49 days; the normals' cache key reproduces from the bands read.
- Maxan's carried departure equals Houston's in 1950 and 1951 (its only donor then).
- R's environment sets bare `PG*` to the tailnet fwapg host; `WET_PG*` default to localhost. Both answered; the pilot's leak-free lines read the former.
