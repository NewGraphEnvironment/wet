## Outcome

Daily air temperature now exists at every Freshwater Atlas stream segment (#216, backlog move 21), as a second published tree beside discharge, `air_temperature/fwa/v1`: `segment_cell` gives each of the 4,907,441 segments the ERA5-Land cell cd's own `cd_extract_daily()` call gives its midpoint (moved to the nearest of the eight cells around it with data where its own has none, or listed as `no_data` or `outside`), and `cell_daily` holds each of the 13,613 used cells' daily tmean, tmax and tmin from 1950, copied unchanged from cd's cube. `wet_air_daily()` reads a segment's days through duckdb in the shape `wet_temp_fill()` takes as `air`. The owner took all ten plan-gate decisions as recommended (one tree, `cell_id` on ERA5-Land's regular grid, a crate `date` type, the midpoint, every segment listed, publish v1 without the cell elevation, upload from the open PR). crate PR #82 added the two schemas and the `date` type, merged and released as crate 0.22.0 with the owner's approval. The build was checked without the code that made it (cells from the point, the grid and cd's rule on the mask; completeness; every value against the cube read with terra), each check shown able to fail, and rebuilt byte-identical. The code review (5 rounds) kept finding one mechanism, a fact held in two places with nothing holding them equal (the cube address cd reads against the one checked; the frames against the parts written; the station check's mask band against the lookup's); it ended on an enumeration of 20 such facts, each now held. Findings: `research/air_temperature_segments.md`.

## Measurement

- Lookup: about 8.4 ms per point in a no-data cell (cd's neighbour search), next to nothing otherwise; about 6 min for the province, so no cd issue on speed (the stop rule was 6 h).
- Status counts (cd's own, equal to the sizing probe's arithmetic estimate): own 4,864,743, moved 41,734, no_data 962, outside 2; all 4,510,368 main-flow tree segments have a row. The cube now reaches 60.05° N, so #216's premise that everything north of 59.95° N leaves the grid was wrong: 2 midpoints do.
- Size: `cell_daily` 377,883,267 rows, 1.55 GB (one year projected 1.99 GB; the stop rule was 10 GB); `segment_cell` 153 MB. The cube's 4-byte floats survive float32 parquet exactly.
- Checks: 1,133,649,801 values equal to the cube; the station check equal at all 314 placed stations (26,065,701 values), 14 stations in a neighbouring cell (13 of 279 in the sizing probe; 27 under the downstream end, which is why the midpoint was chosen).
- Build: 1 h 52 min cold, 1 h 19 min with the cube cached; the second build's parts byte-identical (digest 97d7eeea). Reader: 0.02 s for one segment's year from local parts; 30 s for a whole group (VICT) over 76 years.
- A wrong turn kept: the first size probe read every cell as no-data because `terra::rast()` on cd's SpatRaster returns an empty template.

## Evidence

`data/logs/237/air_publish_2026112*`, `data/logs/237/air_station_check_2026112*` (main checkout); reports `data/checks/air_publish_2025.txt`, `data/checks/air_station_check_2025.txt`.

## Owed

- After the owner's upload: the report it rewrote is committed on the branch; `wet_air_daily()` reads one group over HTTPS, timed, the time added to `research/air_temperature_segments.md`.
- `cell_elev_m`, once cd holds the cube's cell elevation (the wet issue Phase 1 files).

Closed by: the PR for #237 (closes #216 once the upload lands).
