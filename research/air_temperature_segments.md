# Daily air temperature on every stream segment

**Verified:** 2026-11-28 (the province build and its checks, the station check, the fixture); 2026-11-27 (the method and the sizing) · **Issues:** #216 (from move 21, #237); crate#81 (the schemas and the `date` type); cd#161 (cell elevation, which cd does not hold); #246 (`cell_elev_m`, waiting on cd#161) · **Produced by:** `scripts/air_publish.R` → `data/checks/air_publish_2025.txt`, `scripts/air_station_check.R` → `data/checks/air_station_check_2025.txt`, `tests/testthat/test-wet_air_daily.R` and `test-air_publish_lib.R` on a masked copy of cd's example cube; the sizing probes, a trial of the build and the mutation table in `planning/archive/2026-11-issue-237-*/findings.md`; run logs `data/logs/237/`

**Status:** built for the province at wet e461b677 (crate 0.22.0, cd 0.6.13, the cube's 2025 manifest md5 125d1f83…), every check passing; not yet published: `air_temperature/*` needs anonymous reads opened on the bucket before the upload.

## What it is

A stream temperature model run at a reach with no station needs the air temperature series there. wet publishes daily air temperature for every Freshwater Atlas segment as one tree, `air_temperature/fwa/v1`, in two datasets under one manifest:

- `segment_cell`: one row per segment of `whse_basemapping.fwa_stream_networks_sp` (4,907,441, every segment, not only the main-flow tree's 4,510,368), one part per watershed group. It gives the segment's ERA5-Land cell (`cell_id`, `cell_x`, `cell_y`), the cell's status, and the point and elevation that took it.
- `cell_daily`: one row per used cell and local day, one part per year, 1950–2025: `tmean_c`, `tmax_c`, `tmin_c`.

The values are cd's daily cube (`cd::cd_extract_daily()`) copied unchanged: no downscaling, no lapse-rate or elevation adjustment. `wet_air_daily()` reads a segment's series in the shape `wet_temp_fill()` takes as `air`, through duckdb, with no cd, raster tooling or download of the cube. A segment-per-day table would hold about 4.9 million × 27,759 rows; the lookup and the series of 13,613 cells hold the same information in 1.7 GB.

## The cell rule

- **The point.** A segment takes the cell holding its midpoint along the line (`ST_LineInterpolatePoint(geom, 0.5)` in BC Albers, then to degrees). The downstream end was set aside: on a tributary's mouth segment it lies on the receiving river's centreline, and it falls in another cell than the midpoint for 141,708 segments (2.89 %).
- **cd's own call.** The lookup is `cd_extract_daily()` for one day at every midpoint, not a copy of cd's rule in wet, so it is cd's answer for that point. A point takes the cell containing it; where that cell has no data (the coast, large lakes) it moves to the nearest of the eight around it that has (geodesic distance to the cell centre, ties to the lower cell number). With none it keeps no cell; outside the cube's box likewise.
- **The mask day.** cd decides "has data" from band 1 of the first variable's file for the call's first year, so the one-day call asks for 1 January of the cube's last year (2025-01-01). The manifest names that file and its checksum.
- **Statuses** come from cd's columns, not its warning text: `outside` is a missing cell, `moved` is `cell_moved`, `no_data` is a kept cell with no value on the mask day; `own` otherwise. The cell's key is null for `no_data` and `outside`.
- **The key.** `cell_id` numbers the cell on the regular 0.1° latitude-longitude grid ERA5-Land is distributed on (row from 90° N, column from 0° E: `round((90 − y) × 10) × 3600 + round(((x + 360) mod 360) × 10)`), not cd's cell number, which renumbers every cell when cd's box grows (its northern edge has moved once, from 59.95° to 60.05° N).

## How many segments fall each way

From the build's report (cd's own call at every midpoint on the 2025-01-01 band; the sizing probe's arithmetic estimate before it gave the same counts):

| status | all segments | on the main-flow tree |
|---|---|---|
| `own` | 4,864,743 | 4,472,713 |
| `moved` | 41,734 (0.85 %) | 36,833 |
| `no_data` | 962 (0.020 %) | 820 |
| `outside` | 2 | 2 |

The no-data midpoints sit in 327 cells, 29 of them with no data around them. The cube reaches 60.05° N, so only 2 midpoints fall outside it.

## What the checks prove, and what they do not

The build checks the tree with code that did not make it: every `own` row's cell recomputed from its point and the grid's definition (terra's rule; a point on a cell edge is where plain `floor()` arithmetic disagrees); every `moved` row's cell by cd's stated rule from the mask and the point; every `no_data` row's nine cells empty; every `outside` point off the grid; every used cell on every day of every year in `cell_daily` and no other cell; every value against the cube's file read directly with terra. The checks run on the parts as read back from disk. Each is shown able to fail on a mutated fixture in `tests/testthat/test-air_publish_lib.R`. The station check holds the series read through the tree to `cd_extract_daily()` at each placed station's segment point.

On the province every check passed: 4,864,743 own, 41,734 moved, 962 no-data and 2 outside rows recomputed with none differing; 377,883,267 cell-days complete over 13,613 cells; 1,133,649,801 values equal to the cube. Each check, run on a mutated copy of the built parts, turned red. The station check found the series through the tree equal to cd at the segment point of all 314 archive stations the pinned HYDAT release places (26,065,701 values); 300 share their segment's cell, and 14 sit in a neighbouring one, 47 to 1,463 m from the midpoint. Given a neighbour's cell at one station's segment, it failed.

They prove the lookup and the copy. They do not test the air series: both sides read one cube.

## Limits

- **The day** is BC's local standard day (UTC−8), as cd defines it: an hour off in the Mountain Standard Time corner of eastern BC.
- **No elevation adjustment.** A cell about 9 km across has one surface elevation; the segment's midpoint elevation (`segment_elev_m`, from the line's own vertex elevations) is published beside the cell, and the cell's is not, because cd holds none (cd#161; #246 adds it).
- **Stations and cells.** A station and its segment's midpoint can fall in different cells (the snap picks among streams within 1 km by drainage area): 14 of 314 placed stations (the sizing probe, on an older station list, found 13 of 279 under the midpoint and 27 under the downstream end). The station report lists them with both cells and the distance.

## Size and time

- The lookup: about 6 min for the province from cd's cached file, nearly all of it cd's per-point neighbour search (about 8.4 ms per point in a no-data cell, about 42,700 such points; a point in a data cell costs next to nothing).
- The series: about 7.6 s per year for 13,613 cells and three variables from the cached cube. As parquet (zstd, values as 4-byte floats, which hold the cube's values exactly) `cell_daily` is 76 parts, 1.55 GB (one year alone projected 1.99 GB), and `segment_cell` 246 parts, 153 MB.
- The build: 1 h 52 min on its first run, nearly all of it downloading the cube's 228 files (2.8 GB) and reading every value back from them.
