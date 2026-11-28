# Findings — Backlog move 21: Daily air temperature at every stream segment (#237)

## Issue context

**If we do it:** daily air temperature exists at every stream segment, so a temperature prediction can run at a reach with no station. **If we never do:** predicted parameters have nothing to run on away from the stations.

Order: `planning/backlog.md`, move 21. Run `/planning-init <this issue>`: one phase, one PR. It can start now.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 21, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

## Batch 23: daily air temperature at every segment

**Why here:** one lookup from segment to ERA5-Land cell and one published copy of each cell's series serve every reach (#216).

**Touches:** a new function under `R/` with its tests, a build script under `scripts/`, a receipt under `inst/receipt/`, a check report under `data/checks/`, `research/` (all named at the plan gate).

**Decided at the gate (stored data, the owner's):** the dataset's ID, keys and schema; which point of a segment takes the cell; how segments with no cell are listed. A capability `cd` lacks becomes an issue there that this move waits on.

| issue | title |
|---|---|
| #216 | Daily air temperature at every stream segment: an ERA5-Land cell lookup |

The issue's one comment is the claim notice (a report, nothing asked). #216 has no comments.

### #216, the member (body as read 2026-11-26)

**Problem.** `wet_temp_fill()` takes daily air temperature from `cd::cd_extract_daily()`, which samples ERA5-Land at points, and the points so far are stations. A prediction at an unmonitored reach needs the same series at that reach. Nothing in wet gives air temperature on stream segments.

**Proposed approach.** A lookup, not a series per segment (about 4.9 million segments, a few thousand cells): store each cell's daily series once, and a table that gives every segment its cell. Which point of a segment takes the cell is fixed in the plan and stated in the table's description. Record the cell's elevation and the segment's beside each other; whether to adjust is the model's question. Period: the cube's whole daily record. Edges: "cd's daily cube stops at 59.95 °N, and streams that cross the border leave the grid"; segments with no cell are listed, not dropped silently. Publish the lookup and the cell series as the per-segment discharge is published: parquet with a manifest. A capability cd lacks becomes an issue in cd that this one depends on, not code here.

**Out of scope.** Downscaling, lapse-rate correction or any other change to the air series; future-climate series.

**Done when.** Every segment on the main-flow tree has a cell or is listed as having none, with counts. At every station, the series read through the lookup equals `cd_extract_daily()` at the station's point, shown in a check report under `data/checks/` (that proves the lookup, not the air series: both read the same cube). The published tables load by segment id for any watershed group.

## What the code and the cube hold (read 2026-11-26, tree at da85a4c4)

- **cd's daily cube** (`cd::cd_extract_daily()`, cd 0.6.13 installed and in its checkout): one Cloud-Optimized GeoTIFF per variable and year under `https://stac-era5-land.s3.us-west-2.amazonaws.com/daily`, a band per local day (UTC−8). Its `manifest.json` lists 228 files, `tmean`, `tmax` and `tmin` for 1950–2025, 2,802,215,004 bytes in all, each with `file:checksum`, `processing:datetime` and the cd commit that built it. The 2025 `tmean` file, read over the network: extent −140.05 to −113.95° E, 47.95 to 60.05° N, 121 rows × 261 columns at 0.1°, 31,581 cells of which 20,746 hold data, EPSG:4326, units °C, tags `CD_SHA` 349f9d7 and `CD_VERSION` 0.6.3.
- **cd's cell rule** (its internal `daily_cells()`): a point takes the cell containing it; where that cell has no data it moves to the nearest of the eight around it that has (geodesic distance to the cell centre, ties to the lower cell number) with `cell_moved = TRUE`; with none it keeps its cell and its values are NA, with a warning; a point outside the box gets NA cells and a warning. The neighbour search runs point by point in R, so its time over millions of points in no-data cells is unmeasured (Phase 1 times it). The function is not exported; `cd_extract_daily()` returns `cell`, `cell_x`, `cell_y`, `cell_moved` per row, so a one-day call gives the lookup.
- **cd holds no elevation for the cube's cells**: no geopotential or orography layer in its `R/`, scripts or catalogue variables. That is the capability decision 5 turns on.
- **cd's open issues** (14, none a pull request): one on `cd_extract()` returning NaN without a warning for an area on sea cells only. It concerns areas; this move samples points through `cd_extract_daily()`, which warns.
- **The segments** (the local fwapg, 2026-11-26): `whse_basemapping.fwa_stream_networks_sp` holds 4,907,441 rows, `linear_feature_id` unique, no null geometry, in 246 watershed groups. `whse_basemapping.fwa_stream_networks_mainflow_tree` (columns `linear_feature_id`, `watershed_group_code`, `blue_line_key`, `source`, `upstream_area_ha`) holds 4,510,368.
- **The sizing probe** (midpoints by `ST_LineInterpolatePoint(geom, 0.5)` and downstream ends by `ST_StartPoint(geom)`, to EPSG:4326, cells by arithmetic on the grid above, counted in R):

  | measure | value |
  |---|---|
  | cells holding a segment's midpoint | 13,940 (13,929 for the tree's segments) |
  | cells holding a downstream end | 13,935 |
  | segments whose midpoint and downstream end fall in different cells | 141,708 (2.89 %), 137,924 of them on the tree |
  | midpoints outside the cube's box | 2, both on the tree |
  | midpoints north of 59.95° N / north of 60.0° N | 25,829 / 78 |
  | midpoint latitude, longitude range | 48.317 to 60.123° N, −138.680 to −114.065° E |

  So #216's edge premise has moved: the cube reaches 60.05° N, and 2 segments leave it.
- **Midpoints against the cube's data mask** (band 2025-01-01 of the 2025 `tmean` file, the cell by `terra::cellFromXY()`, a neighbour with data sought among the eight around a no-data cell; an estimate of cd's statuses, not cd's own call):

  | status | all segments | on the main-flow tree |
  |---|---|---|
  | `own` (the cell has data) | 4,864,743 | 4,472,713 |
  | `moved` (no data, a neighbour has) | 41,734 (0.85 %) | 36,833 |
  | `no_data` (none of the nine has) | 962 (0.020 %) | 820 |
  | `outside` the box | 2 | 2 |

  The no-data midpoints sit in 327 cells, 29 of them with no data neighbour. cd's per-point neighbour search would therefore run about 42,700 times over the province.
- **What the Plan review added** (`review-plan.md`, each probed): crate's schema types are integer, double, string, logical and datetime, with no date; the cube cd ships as an example (5 × 5 cells, one year, 4-byte float) has no empty cell; `wet_timebase()` reads `air_temperature/fwa/v1/cell_daily` as a day-of-year table; `scripts/discharge_publish.R` holds each schema to the installed crate's release tag and refuses an upload when any file under `R/` or `scripts/` outside `scripts/discharge_publish_own.R`'s list changed since the build; `research/station_temperature_fill.md` also states the 59.95° N edge.
- **The series' size**: 13,940 cells × 27,759 days (1950–2025) is about 387 million cell-days; one year is about 5.1 million.
- **How discharge is published** (`research/discharge_publish.md`, `R/wet_catalog.R`, `scripts/discharge_publish.R`): a dataset ID is `<variable>/<network>/<version>/<unit>_<timebase>`; the research file reserves `temperature` names for water and says cd publishes air temperature. `wet_id_check()` accepts `air_temperature/fwa/v1`; `wet_part_parse()` requires `<unit>_<timebase>/scenario=/forcing=/source=/part-<code>.parquet` with the unit matching `[a-z]+_[a-z]+`, the source `[a-z]+_[a-z]+` and the code `[A-Za-z0-9]+`, which `segment_cell`, `cell_daily`, `cd_daily`, `ERA5-Land`, a group code and a year all satisfy. `wet_manifest_write()` needs a label per code (`drainage`) and a description per source. `wet_receipt_write()` hard-codes the three discharge datasets' row counts and the discharge declaration as its default, so it needs the change Phase 2 names. `wet_timebase()` knows `monthly` and `daily` only (`doy` 1–365), which is why the air reader is its own function and not `wet_segment_read()`.
- **crate** holds the three discharge schemas under `inst/extdata/schemas/nge/discharge/fwa/v1/`; the air tree's two are new there (Phase 1). crate 0.21.0 is installed.
- **Anonymous reads** are open on the bucket for `discharge/*` and a few other prefixes (`research/discharge_publish.md`, "Evidence"); `air_temperature/*` is not among them.
- **`wet_temp_fill()`** requires `air` to carry `id`, `date`, `variable`, `value` with `date` a Date, and reads the `tmean` rows. `wet_air_daily()` returns that shape, so a later move can hand it a reach's series.
- **A stale note found, not this move's**: `scripts/temp_fill_validate.R` says the cube stops at 59.95° N and that one point outside it aborts the call; cd now reaches 60.05° N and warns.
- **Installed packages** (the organisation's stale-install check, read-only): wet 0.4.44 installed against 0.6.0 in the tree. Scripts load the tree, but lintr resolves names against the installed copy.

## Phase 1 measurements (2026-11-27, m1, cd 0.6.13, the cube's 2025 files cached)

Script kept out of the repo (a scratch probe); every number below is its printed output.

- **The lookup's time.** One day of `tmean` from `cd::cd_extract_daily()` at every segment midpoint of a group:

  | group | points | `moved` | no data (NA value) | elapsed |
  |---|---|---|---|---|
  | BULK (interior) | 32,472 | 0 | 0 | 0.3 s |
  | GRAI (Haida Gwaii, coast) | 36,937 | 4,088 | 16 | 34.4 s |
  | VICT (coast) | 2,147 | 289 | 125 | 3.5 s |
  | CLAY (coast) | 17,112 | 467 | 0 | 3.8 s |

  The time is cd's neighbour search: about 8.4 ms per point in a no-data cell (34.4 s / 4,104; 3.5 s / 414), and a
  point in a data cell costs next to nothing. With about 42,700 such points in the province (sizing probe above), the
  lookup projects to about 6 minutes: far under the 6-hour stop rule, so no cd issue on speed.
  cd warns once per call with "No ERA5-Land data in or around the cell for: <ids>" for `no_data` points.
- **The cells.** All 4,907,441 midpoints streamed (no sort in the database) fall in 13,940 cells; 13,613 of them hold
  data on 2025-01-01 (the rest are the no-data cells whose segments move or stay `no_data`). The `moved` targets add
  a few cells beyond those, so `cell_daily` holds about 13,620 cells.
- **One year of the series.** `cd_extract_daily()` at the 13,613 data-cell centres for all of 2025, three variables:
  7.6 s, 4,968,745 cell-days, no cell moved, no NA value. Written as parquet (zstd; `cell_id` int32, `date` date32,
  values float32, sorted by cell then date): 26,189,939 bytes with three variables, 11,756,863 with `tmean` alone;
  projected to 76 years, **1.99 GB and 0.89 GB**: under the 10 GB stop rule. The cube's 4-byte floats round-trip
  exactly through float32 parquet.
- **Stations and cells.** The temperature archive's stations as cached for #40 (303), with a gross drainage area in
  HYDAT 20260717 (294), placed by `wet_station_snap()` and accepted (279): the station's own coordinates fall in a
  different cell than its segment's midpoint at **13** stations, than its downstream end at **27**. The midpoint
  (decision 5) halves the stations decision 9 lists.
- A probe slip worth keeping: `terra::rast()` on the SpatRaster cd returns an empty template, so the first try read
  every cell as no data; the probe then used cd's raster as returned.

## A trial of the build (2026-11-27, before the province build)

`scripts/air_publish.R` copied to the scratch directory and patched to skip the crate release-tag check (the schemas were on crate's branch, installed into a throwaway library), to read only watershed groups VICT and CLAY and their table and tree counts, and years 2024 and 2025, writing under a scratch `WET_DATA_ROOT`. Not the build: no report was committed. Its report: 19,259 segments read against 19,259 in the table, all 18,199 tree segments with a row; 18,378 `own`, 756 `moved`, 125 `no_data`, 0 `outside`; 73 cells used; every check passing (18,378 own, 756 moved and 125 no-data rows recomputed with 0 differing; 53,363 cell-days complete; 160,089 values equal to the cube read with terra). A second run after round 1's fixes (the checks reading the written parts) wrote the same report byte for byte. Under a minute each from the cached cube.

## The province build and its mutation table (2026-11-28)

BUILD at wet e461b677 (crate 0.22.0, cd 0.6.13, fwapg 5d50cc1), 1 h 52 min, nearly all of it the first download of the cube's 228 files and the per-year value check: report `data/checks/air_publish_2025.txt`, every check passing. 4,907,441 segments read against `count(*)`; all 4,510,368 main-flow tree segments have a row; own 4,864,743, moved 41,734, no_data 962, outside 2 (the sizing probe's estimates, exactly); 13,613 cells used (the moved targets fall in cells already used); `cell_daily` 76 parts, 377,883,267 rows, 1.55 GB (the projection said 1.99: zstd does better over more years); `segment_cell` 246 parts, 153 MB; 1,133,649,801 values equal to the cube read with terra. Log `data/logs/237/air_publish_20261128T002555Z.log` (main checkout).

The build's check functions on mutated copies of the built parts (`air_check_cells()` on every non-own row and 2,000 own rows; the completeness and value checks on the 1990 part read back; a scratch script, not committed):

| mutation | check | result |
|---|---|---|
| none (the sample as built) | all four cell checks | pass |
| an own segment's cell moved to its east neighbour | own rows | FAIL |
| a moved segment's cell changed to another of the eight around its own | moved rows | FAIL |
| an own segment's status flipped to moved | moved rows | FAIL |
| a no_data segment's status flipped to outside | outside rows | FAIL |
| none (cell_daily 1990 as written) | completeness and values | pass |
| one cell_daily value changed by 0.25 degrees | values against the cube | FAIL |
| one cell's rows for 1990 dropped | completeness | FAIL |

The station check (`data/checks/air_station_check_2025.txt`, 4 min): 342 archive stations, 314 placed; through the tree against cd at the segment's point, 26,065,701 values compared, 0 differing; 300 stations share their segment's cell (24,983,100 values equal) and 14 sit in a neighbouring cell, 47 to 1,463 m from the midpoint. On a copy of the tree with 08EE013's segment (17094080) given its east neighbour's cell, it failed as it must: 74,696 values differing, largest 4.75 °C.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `terra::rast(r)` on cd's SpatRaster gave all-NA extracts in the size probe | It returns an empty template (code-check-spatial); use the raster cd returns |
| The first sizing probe counted distinct cells in the database and failed: `could not write to file "base/pgsql_tmp/…": No space left on device` | A sort or `count(distinct)` over 4.9 million rows needs temporary space in the database. The probe was rerun as a streaming select with the counting done in R (19 s). The build's segment query is written the same way (Phase 3). |
