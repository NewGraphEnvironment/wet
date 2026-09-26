# Findings — Scope: monthly, seasonal and scenario discharge per FWA segment (#1)

## Issue context

**If we do it:** habitat models can use seasonal and monthly flow, not just one mean-annual number, tied to when each species is in the stream, with climate scenarios on the same network. **If we never do:** discharge stays a mean-annual value covering three basins (fwapg's `extras/discharge`). Nothing can ask "is there enough water in this reach during CH spawning or BT incubation, now and in 2050".

## Problem

The only per-segment discharge available is fwapg's `extras/discharge` (`whse_basemapping.fwa_stream_networks_discharge`: `mad_mm`, `mad_m3s`):

- PCIC VIC-GL baseflow + runoff, ~30 km cells, collapsed with `cdo` to one mean annual value over a daily slice spanning roughly 1981–2010. Monthly structure and scenario runs are discarded.
- Fraser, Columbia and Peace only; rivers of order ≥ 8 skipped. Locally, 2.0 M of 2.7 M segments carry a value.
- bash + cdo + SQL, run by hand.

Station data is separate: water-temp-bc holds ~290 ECCC stations (temperature, discharge, level) over the ~18-month realtime window. Long HYDAT records are reachable through `tidyhydat` / `fasstr`, but nothing combines them with modelled flow on the network.

## Proposed Solution (scope to settle here)

1. **Reproduce fwapg's MAD in R** (`terra`/`stars` + the fwapg database for FWA topology), and compare it with `fwa_stream_networks_discharge` as a parity check.
2. **Keep the time axis:** monthly climatologies and seasonal summaries (e.g. Aug–Sep low flow, freshet peak) per segment.
3. **Scenarios:** the PCIC hydrologic model output that is forced by projected climate, as period means (e.g. 2041–2070) next to the historical baseline.
4. **Coverage:** establish what PCIC now covers beyond the three basins, and what fills the gaps (regional regression from HYDAT stations, other published products).
5. **Station check:** compare modelled monthly flow with HYDAT at gauged outlets, and report bias by region and season.
6. **Publish:** per-segment monthly table (`linear_feature_id` × period × month × scenario) as parquet on S3 with a STAC entry, in the pattern of `cd`. fresh joins it like channel width (fresh#114); link matches months to species- and region-specific life-cycle timing.

## Open questions

- Other published products to evaluate before building (PCIC's routed streamflow at stations, provincial water tools, other groups' scenario runs). List them, with licence and coverage, before writing code.
- Segment-level vs fundamental-watershed-level output.
- R package or scripts-plus-data repo.

Relates to NewGraphEnvironment/fresh#114, NewGraphEnvironment/link#284, NewGraphEnvironment/knowledge#19


## Exploration (plan mode, 2026-09-25)


### How fwapg's MAD is built
- Files are under `fwapg/extras/discharge/`: `discharge.sh`, then `sql/discharge02_load.sql`, `discharge03_wsd.sql` and `discharge.sql`.
- Download: PCIC OPeNDAP `allwsbc.TPS_gridded_obs_init.1945to2099.{BASEFLOW,RUNOFF}.nc.nc`, time indices `[13149:24105]` (1981-01-01 to 2010-12-31, daily).
- Per cell: `cdo yearsum` then `timmean`, and runoff + baseflow, giving mm/yr.
- Per fundamental watershed: `ST_Value` at the **centroid** (a single sample, not area-weighted).
- Upstream: area-weighted by `ST_Area(uw)/upstream_area_ha*1e4` through `FWA_Upstream` and `fwa_watersheds_upstream_area`.
  - `mad_m3s = mm * upstream_area_m2 / 31536000000`.
  - A NULL upstream cell drops out of the sum while still counting in the denominator, which biases results low.
  - Mainstems of order ≥ 8 are skipped (`order8rivs` CTE).
- Watershed → segment goes through `fwa_streams_watersheds_lut`.

### Corrections to the issue text
- The grid is **0.0625°** (about 30 km² per cell), not ~30 km.
- The forcing is **PNWNAmet observed** (VICGL+RGM+HydroConductor, historical), not a BCCAQ scenario.
- fwapg's README citation and the `fwa_streams.mad_m3s` column comment mislabel the forcing.

### Earlier R work on PCIC data
- `fish-passage-22/functions.R:123-215` `pcic_dl_sh()` reads PCIC `catalog.json`, uses ncdf4 to resolve OPeNDAP index slices for a bbox and date range, and pulls scenario runs (for example `ACCESS1-0_rcp85`).
- `read-discharge.R` reads the result with tidync.
- There is a 9 GB local historical BASEFLOW file at `~/Projects/repo/pcic/data/baseflow.nc`, but no RUNOFF.
- Nobody has checked whether the endpoints are still live; fwapg moved its README links to uvic.ca in July 2026.

### How fresh consumes discharge (fresh#114)
- fresh joins in Postgres with `frs_col_join(conn, table, from, cols, by = "linear_feature_id")` (`fresh/R/frs_col_join.R:73`).
- A `wet` parquet would therefore need loading into fwapg, or a foreign table or subquery, before fresh can use it.
- The MAD predicate is not wired yet.

### The `cd` pattern
- `cd` is an R package: COGs, `aws s3 sync`, and a hand-built STAC Catalog with items inline. It has no parquet, no Collection, no table extension and no versioning.
- Copy its package and pipeline layout (`R/wet_*`, `scripts/pipeline_*.R`, one test per exported function, a STAC round-trip test). Design the parquet and STAC Collection side fresh; `stac_dem_bc` uses pystac with a Collection and the Version extension.

### Stations
- `water-temp-bc` holds about 290 ECCC stations with no FWA snapping.
- `fresh::frs_point_snap()` wraps `fwa_indexpoint` and takes `num_features`.
- HYDAT is available locally (2025-12-04).
- `fasstr` (CRAN 0.5.3) has `calc_longterm_monthly_stats` and low-flow functions.

### Life-cycle timing (knowledge#19)
- No structured timing table exists apart from a Skeena-only gantt CSV that has been copied into the fish_passage_* repos.
- knowledge#19 plans to build one, and it is the consumer of the monthly output.

### Local tooling
- Installed: terra, stars, arrow, duckdb, fwapgr, tidyhydat.
- Not installed: exactextractr.
- The database follows the `PG_*_SHARE` pattern (`fresh::frs_db_conn`, `link::lnk_db_conn`).


## Phase 1 — Product inventory (2026-09-25)

### Endpoint status

| Endpoint | Status 2026-09-25 |
|---|---|
| `data.pacificclimate.org/...` (host fwapg and `pcic_dl_sh()` use) | **301 → `services.pacificclimate.org/...`** |
| `services.pacificclimate.org/portal/hydro_model_out/catalog/catalog.json` | 200, 169 datasets |
| `services.pacificclimate.org/data/hydro_model_out/<file>.nc` (OPeNDAP: `.das`, `.dds`, `?VAR[t][y][x]`) | 200 |
| `services.pacificclimate.org/portal/hydro_stn_cmip5/` | 200 ("Modelled Streamflow Data" portal) |
| `services.pacificclimate.org/portal/downscaled_cmip6/catalog/catalog.json` | 200 (BCCAQv2 CMIP6 *climate*, not hydrology) |
| `uvic.ca/pcic/data-analysis-tools/data-portal/hydrology-gridded/` | 200 (human docs) |

fwapg's `discharge.sh:13-14` runs `curl -o` **without `-L`**. Against the redirecting host it saves the 301 body, not the NetCDF, so the script is broken as written. Put this in the fwapg issue draft (Phase 5).

### PCIC `hydro_model_out` (gridded VIC-GL), parsed from `catalog.json`

- **Historical:** `VICGL-RGM-HydroConductor`, forcing PNWNAmet (observed), 1945-01-01 to 2012-12-31, domain `nwna`. The file name says "1945to2099" but the data end in 2012. Has 13 variables, including RUNOFF, BASEFLOW, SWE, SNOW_MELT, GLAC_OUTFLOW, PREC and EVAP. This is the run fwapg uses.
- **Scenarios:** `VICGL` (no glacier dynamics), BCCAQ-downscaled CMIP5 driven by 6 GCMs × 2 RCPs = 12 runs, 1945-01-01 to 2099-12-31, domain attribute `columbia`. The title reads "COLUMBIA+PEACE+FRASER_CMIP5_Hydrologic_Projection". There are 13 variables per run in the catalog, and RUNOFF and BASEFLOW are present for every run.
  - GCMs: ACCESS1-0, CanESM2, CCSM4 (r2i1p1), CNRM-CM5, HadGEM2-ES, MPI-ESM-LR (r3i1p1).
- **Grid:** 0.0625°, sliced to lon −139.97…−109.03, lat 41.09…63.97. Only Peace, Fraser and Columbia hold values; the rest is fill.
- **Units:** mm per day, stored as packed shorts (`_FillValue` −32767). Calendar `standard`, time "days since 1945-1-1". Calibration 1985–2005 against the TPS/ClimateWNA target.
- **The historical and scenario model versions differ** (RGM glacier model vs none). A delta computed as scenario minus historical mixes model structure with climate signal. Deltas must come from the same run: scenario future period minus scenario baseline period.
- **Terms:** PCIC terms of use, "AS IS", and cite as "Pacific Climate Impacts Consortium, University of Victoria, (Jan 2020). VIC-GL BCCAQ CMIP5: Gridded Hydrologic Model Output." No open licence is named; confirm redistribution rights before publishing derived values.
- **No CMIP6 hydrology on the portal.**

### PCIC `hydro_stn_cmip5` (routed station streamflow)

- 190 locations in Peace, Fraser and Columbia. VIC-GL runoff routed with RVIC.
- One CSV per station: daily m³/s, 1945–2099, with a PNWNAmet column plus 12 CMIP5 columns. Released Feb 2020.
- Use: an **independent check on the station comparison** — routed modelled flow vs our area-weighted accumulation at the same outlets, plus HYDAT where gauged. Not a per-segment product.

### PCIC Salmon Climate Impacts Portal (Mar 2024)

- VIC-GL coupled to dynWat (streamflow + water temperature), BC coastal domain.
- 10 streamflow/temperature hazard indices at yearly, monthly and daily resolution. 6 CMIP5 GCMs × RCP 4.5/8.5 × historical, 2020s, 2050s, 2080s.
- Regions: watershed group, salmon conservation unit, or a custom outlet. The spatial unit behind them is not documented on the page.
- Terms: PCIC terms of use.

### PCIC VIC-GL → Raven, CMIP6 (announced Feb 2026, NOT yet released)

- PCIC Update Feb 2026, "Improved Modelling of BC's Salmon Habitats".
- VIC-GL runoff drives Raven routing on a **vector (sub-basin + channel) discretisation**, "about a factor of five" finer than VIC-GL's ~25 km² minimum. Outputs are streamflow, water temperature and saturated dissolved oxygen.
- Deployed "across BC's entire coastal domain, including the Fraser Basin" (~405,000 km²), driven by CMIP6. The example is CNRM-ESM2-1, SSP5-8.5.
- "Near completion … will be available from a new data portal." Funded by BCSRIF and BC Hydro.
- **This is the biggest scope risk for `wet`.** It overlaps the monthly, scenario and coverage items for the coastal domain and the Fraser, it adds water temperature, and it is routed. It is not expected to cover the Peace, Columbia or northern interior. Things to find out before building scenarios: the sub-basin geometry (can it be crosswalked to FWA?), the release date, and the licence. Contact Markus Schnorbus (PCIC hydrology lead, named in the NetCDF metadata).

### Provincial and other products

| Product | Coverage | Time axis | Scenarios | Access / licence | Relevance |
|---|---|---|---|---|---|
| BC Water Tools (NEWT: BC Energy Regulator; Omineca, Cariboo, Kootenay-Boundary, NW: FLNRORD; built by Foundry Spatial) | Regional, together covering much of the interior and north | Mean annual + monthly discharge for a user-picked watershed | Climate summary only | Web UI, per-watershed reports. No bulk per-segment download found | A reference to compare against in gap regions (Skeena, north). Not a data source |
| HYDAT (ECCC), via `tidyhydat` | ~ all gauged stations; local sqlite 2025-12-04 | Daily/monthly, long records | None | Open Government Licence – Canada | Station check (item 5); training data for gap-fill regression |
| ECCC realtime (`water-temp-bc`) | ~250 discharge stations | 18-month window | None | OGL-Canada | Short; not useful for climatologies |
| BCUB (ESSD 2025): British Columbia Ungauged Basin attributes | 1.2 M ungauged catchments, BC-wide | Static attributes (terrain, soil, land cover, climate indices) | None | Open (ESSD data paper) | Predictors for a regional regression gap-fill (item 4) |
| Morrison et al. 2012 (Atmos-Ocean), monthly freshwater discharge to BC coastal waters | Coastal BC | Monthly | None | Paper | Method precedent for pluvial vs nival regional regression |
| ClimateBC / `climr` (already used in fwapg `extras/precipitation`) | BC + transboundary | Monthly normals, CMIP6 scenarios | Yes (CMIP6) | Open | Possible precipitation-scaled downscaling of VIC-GL (the fwapg README's "upsampling" idea), or a regression predictor |

### Coverage gap (item 4)

PCIC gridded hydrology covers only Peace, Fraser and Columbia. The Skeena, Nass, Stikine, coastal and northern basins have no VIC-GL product on the portal. The Raven CMIP6 release would add the coastal domain. The north (Liard, Stikine, Nass, Skeena interior) stays uncovered by any modelled product, so it needs regional regression: HYDAT response + BCUB/ClimateBC predictors.

### Corrections to the issue text (confirmed)

- Grid is 1/16° (≈ 30 km², PCIC's own number is ~25 km²), not "~30 km cells".
- fwapg's MAD uses the **historical PNWNAmet run with the RGM glacier model**, not a CMIP5 scenario.
- The raster → watershed step is a **centroid point sample**, not area-weighted.
- The 1981–2010 slice is exact (time indices 13149–24105).

## Decisions (proposed — pending user review in the PR)

The user asked for all phases through to a PR in one pass. So these are **proposals with reasons**, not user-approved decisions. Each one is open for revision in PR review. D3 was revisited after the Phase 4 sensitivity run (see below).

### D1. R package, not scripts-plus-data

`wet` is an R package: `wet_*` prefix, `noun_verb` naming, testthat 3e, and producer scripts in `scripts/`. This mirrors `cd`/`fresh`/`link`.

- The same logic runs in several places: the parity check, historical monthly, 12 scenario runs, and later regions. As exported functions with fixture tests it is written once and tested once.
- Scripts-plus-data (`water-temp-bc`, `stac_dem_bc`) suits repos whose code is mostly one ingestion job.
- A consumer-side reader (`wet_catalog()`, as with `cd_catalog()`) will be wanted by fresh/link, and that needs a package.

### D2. Compute per fundamental watershed, publish per FWA segment

The raster → polygon step and the upstream accumulation are both defined on `fwa_watersheds_poly`. Segments inherit their watershed's accumulated value through `fwa_streams_watersheds_lut`, exactly as fwapg does.

- **Published key:** `linear_feature_id`. This is what `fresh::frs_col_join(by = "linear_feature_id")` and fresh#114 consume.
- **Also kept:** `watershed_feature_id`, as a published intermediate. It is about 3× smaller, and it is the unit a regression gap-fill would predict on.

### D3. Method: fix fwapg's two biases, keep parity reproducible

- **Keep `wet_mad_parity()` as a parity mode.** It uses a centroid sample and divides by total area, so any run can still be diffed against `fwa_stream_networks_discharge`.
- **Production default:** area-weighted cell extraction (exact polygon ∩ cell fraction), and normalisation by **covered** area. Publish a `coverage` fraction (covered upstream area / total upstream area) so consumers can mask partial coverage instead of receiving silently low values.
  - Phase 4 measured how far each of these moves results (see below).
- **Do not skip order ≥ 8 mainstems.** fwapg skipped them for SQL runtime, because each polygon joins every upstream polygon through `FWA_Upstream`, so cost grows with depth.
  - The Fraser at Hope is exactly the kind of reach a station check needs.
  - The fix is to accumulate once per watershed group, pre-aggregated by `wscode`/`localcode` (fwapg's own `discharge.sh:48-56` comment points at this), and carry group totals downstream across group boundaries. The full-province build issue should design and benchmark this; Phase 4 runs on one headwater group and does not settle it.
- **Sum runoff and baseflow before or after averaging:** mathematically identical when both share one NA mask (checked in Phase 4, below). `wet` sums per time step, then aggregates.

### D4. Publish shape

- **Format:** Hive-partitioned parquet.
  - Path: `s3://<bucket>/wet/v<major>/unit=segment/scenario=<run>/period=<yyyy-yyyy>/part-0.parquet`
  - Columns: `linear_feature_id`, `month` (1–12, plus 0 = annual), `runoff_mm`, `discharge_m3s`, `coverage`.
  - Readers stream it with duckdb/arrow and push predicates down to the partitions.
- **Versioning:** in the key (`v1/`), not in place (a fix over `cd`). A breaking method change bumps `v`, and old versions stay readable.
- **STAC:** one proper `Collection` (not `cd`'s inline-items Catalog), one Item per scenario × period, declaring the **table extension** (`table:columns`, `table:row_count`) and the version extension.
- **Bucket:** open question for the user. Options are a prefix under `s3://fresh-bc` (needs a bucket-policy grant; public read is only on `bcfishpass/*` today) or a dedicated bucket as `cd` has.
- **Getting it into fwapg for fresh#114:** `wet_db_load()` writes one scenario/period slice into a Postgres table (for example `wet.discharge_monthly`). `frs_col_join(from = "(select linear_feature_id, discharge_m3s as mad_m3s from wet.discharge_monthly where month = 0 and scenario = 'PNWNAmet')")` then works unchanged. fresh needs no S3 reader.
- **Licence caveat (blocker for public publish):** PCIC data come under PCIC terms of use with no named open licence. Before publishing derived values publicly, confirm redistribution with PCIC (the same contact as the Raven question).

## Phase 4 — MAD parity prototype (SALR, 2026-09-25)

Run it with `Rscript scripts/mad_parity.R SALR` against the local fwapg (`fresh-db`). It takes about 1.5 min on a cold cache (the PCIC fetch is ~54 s) and ~8 s warm. Outputs go to `data/parity/` (gitignored).

### Why SALR

- Of the groups where fwapg MAD has good coverage, SALR (Salmon River, Fraser) is a **headwater** group: its maximum `upstream_area_ha` equals the group's area (ratio 1.000).
- It is small: 9,384 segments, 4,587 fundamental watersheds, maximum stream order 6. So fwapg's order ≥ 8 skip does not touch it.
- Candidates with the same ratio: SALR, MUSK, DEAD, CRKD, BOWR, HORS, UFRA, NATR, and others.
- **Group boundaries cut mainstems.** Two small LSAL polygons (0.7 ha and 2 ha, on wscode `100.591289`) sit upstream of two SALR polygons. The script therefore samples every polygon that `wet_upstream_pairs()` returns, not only the group's own. The first run, which sampled only the group, stopped on exactly this.

### Coverage ceiling is the lookup, not PCIC

- 384 of SALR's 9,384 segments (4 %) are not in `fwa_streams_watersheds_lut`, mostly edge types 1400 and 1100. So neither fwapg nor `wet` can give them a value.
- All 9,000 segments in the lookup have fwapg MAD.
- The "2.0 M of 2.7 M" province-wide figure in the issue mixes three things: this lookup gap, the order ≥ 8 skip, and the basins PCIC does not cover.

### Parity result

| Check | Result |
|---|---|
| Segments compared | 9,000 of 9,000 |
| `mad_mm`, abs diff | ≤ 5.8e-6 mm on all segments (fwapg stores 5 decimals) |
| `mad_m3s`, after rounding `wet` to 5 decimals | **identical on 100 %** |
| `mad_m3s`, raw abs diff | ≤ 5e-6 m³/s on all segments (the 5-decimal rounding) |
| `mad_m3s` ≥ 0.01 m³/s (3,859 segments), max rel diff | 0.045 % |
| `mad_m3s` range in SALR | 2e-5 to 10.2 m³/s; `mad_mm` 52.5 to 504.6 |

The planned threshold (≥ 99 % within 0.1 % relative) is **the wrong test for small flows**. fwapg rounds `mad_m3s` to 5 decimals, so a 2e-5 m³/s headwater carries up to 25 % rounding error. The right parity statement is the absolute one above: identical after rounding. **The R chain reproduces fwapg exactly**, including the PCIC data (same values after PCIC's host move) and fwapg's centroid rule. The plan's threshold is kept for large flows, where it holds with a wide margin.

### The two aggregation orders

- Runoff and baseflow share one NA mask (0 NA in the 255 cells of this subset).
- max |sum per day, then annual − annual each, then add| = 5.7e-14 mm/yr, which is float noise. D3 is confirmed: the order doesn't matter.

### Sensitivity (per watershed, `mad_mm`, vs the parity build)

| Variant | Median | 1st–99th percentile | Share with change > 5 % |
|---|---|---|---|
| Area-weighted cells, total denominator | +0.00 % | −10.75 % to +19.85 % | 9.6 % |
| Centroid, covered denominator | +0.00 % | 0 | 0 % |
| Area-weighted + covered | +0.00 % | −10.75 % to +19.85 % | 9.6 % |

Area-weighted sampling, broken down by upstream area:

| Upstream area | Watersheds | 1st–99th percentile | Max \|change\| |
|---|---|---|---|
| > 1 km² | 2,167 | −10.6 % to +18.9 % | 84 % |
| > 10 km² | 827 | −3.7 % to +8.4 % | 13 % |
| > 100 km² | 314 | −0.3 % to +2.8 % | 2.8 % |
| SALR outlet (1,794 km²) | 1 | | +0.09 % |

**What this means for D3.**
- Centroid sampling gives a headwater watershed the value of whichever single cell its centroid lands in. With 1/16° cells (~25–30 km²), a watershed of a few km² can take a cell that mostly lies over a different slope, which moves its value by up to 84 %. Area weighting removes that arbitrariness. Large rivers barely change, so the choice matters for exactly the small streams that habitat models (fresh/bcfishpass MAD thresholds such as CH spawning ≥ 0.46 m³/s) sit near.
- Keep the proposal: area-weighted by default, centroid for the parity mode.
- **The covered denominator had no effect in SALR** because every cell has a value; this subset cannot test it. It matters only where polygons fall on NA cells at the edge of the PCIC domain. The build issue should measure it on a group on the domain boundary.

### What Phase 4 does not settle

- **Scaling:** `wet_upstream_pairs()` materialises every (watershed, upstream polygon) pair. That is 722 k pairs for SALR in 3–45 s. It will not scale to the Fraser mainstem, so pre-aggregate by `wscode`/`localcode` as D3 says.
- **Monthly climatology:** not built. It is the same chain with `tapp` by month, and belongs to the monthly child issue.
- **Performance of `terra::extract(exact = TRUE)`** over ~1.3 M province polygons has not been measured.

### Code check (Phase 4 commit)

Four review rounds, then a full list of affected code. Files: `planning/active/review-round{1..4}.md`.

| Round | Findings | Fixed | Accepted | Inside previous fix? |
|---|---|---|---|---|
| 1 | 2 | 2 | 0 | — |
| 2 | 0 | 0 | 0 | n |
| 3 | 2 (1 bug, 1 fragile) | 2 | 0 | n (same mechanism, pre-existing code) |
| 4 | 1 (fragile) | 1 | 0 | **y**: the no-data guard still tested value presence after the numerator became cover-weighted |

**Mechanism.** Rows or values present were taken to stand for the whole population. Missing data became a neutral 0, or dropped out of a denominator.
- **Fixes:**
  - No upstream data now gives `NA`, not 0 m³/s.
  - Ground beyond the raster edge counts as uncovered (the raster is padded before `extract`).
  - The "total" numerator is cover-weighted.
  - The no-data guard is `area_cov > 0`.
  - The sensitivity summary counts watersheds that are NA in only one build.
- **The loop ended on an enumeration**: every term in `wet_upstream_mean()` (`cv`, `v`, `num`, `area_cov`, `up`, both value formulas, the NA guard, `coverage`, unmatched ids), plus round 3's ~30-site sweep, which round 4 re-verified.
- **None of these changed a SALR number.** Parity is identical after rounding, before and after the fixes, because SALR is fully covered and centroid cover is 0 or 1.

**Accepted divergence from cdo.** One missing day makes the whole annual cell NA; `cdo yearsum` skips missing days. This can only happen if PCIC's mask varies in time, and it does not.
