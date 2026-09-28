# Code-check round 2: wet_mod16_aet (#18)

Reviewer: subagent, 2026-09-27. Scope: the staged diff (`R/wet_mod16_aet.R`, `wet_download(netrc =)` in `R/wet_cgiar_aet.R`, tests, Rd, NAMESPACE), with the focus on round 1's fix: the 1 m tile shrink in `wet_modis_tiles()`. All probes ran in a scratch copy of the tracked files, with the staged `R/wet_wb_raw.R` in place. The repo and `data/mod16/` were not touched.

## Findings

- **[fragile]** R/wet_mod16_aet.R:56-59 and 106-108, 163-167. Nothing checks that `grid` is lon/lat. A projected grid, such as BC Albers (EPSG:3005, the org default), is not refused. Instead, `terra::densify(p, 0.01, flat = TRUE)` reads the 0.01 as metres and puts a vertex every centimetre. Measured: a 50 x 50 km EPSG:3005 grid gave 20,000,001 vertices and took 3.5 s. A provincial Albers extent is about 100 times the perimeter, so about 2e9 vertices, which will exhaust memory rather than fail with a message. If granules are missing, `wet_mod16_search()` would also send metres as the CMR `bounding_box`. The roxygen says "(EPSG:4326 here)", and no shipped caller passes a projected grid, so nothing is broken today. The failure mode is an OOM or a hang in an exported function. A one-line `if (!terra::is.lonlat(grid)) stop(...)` after line 56 would make it an error.

No other issues found.

## The round-1 fix, checked by measurement

- **Guard fires.** The shrink was reverted in a mutation copy (`ext(x0, x0 + tile, ...)`). The `ymax = 60` and `ymax = 50` expectations (test lines 48 and 50) then fail: 2 FAIL, 37 PASS. With the fix in place: 0 FAIL, 39 PASS, 0 SKIP (`NOT_CRAN=true`, `test_file`). No test reaches the network.
- **Size of the edge noise vs the 1 m tolerance.** `wet_modis_tile_m` equals R * pi/18 to 1e-9 m. The constant `wet_modis_ul` (the official MODIS values) is 0.9 mm off R * pi/2 in y and 1.8 mm off in x. Measured on every parallel: 40, 50 and 60 N project to within 8.99e-4 m of a tile edge, about 1000 times smaller than the shrink.
- **Exact edges on 40/50/60 N, top and bottom, at four longitude spans (24 grids).** Each selects only the row on the grid's side. There are no extra rows, and none is missing.
- **Does the shrink drop a tile the grid really reaches?** Only when the grid reaches it by less than 1 m. That strip can hold no sampled value. The values come from `project(method = "near")` at the centres of `disagg(grid, fact)` cells, and each centre is half a fine cell inside the grid edge: about 65 m for 30 arc-seconds with `fact = 4`, and about 150 m for 0.1 degree with `fact = 20`. A centre that falls in tile T therefore has grid area more than 1 m deep into T around it, so T is kept.
  - Checked with 300 random 30 arc-second grids, many with an edge on or near 40/50/60 N. Each was compared with an oracle, the tiles holding the `disagg(grid, 4)` cell centres. There were 0 cases of a needed tile going missing.
  - 9 cases selected a tile that holds no centre. In every one, the grid edge lay between 2 m and 0.1 degrees past a parallel, a real overlap that the design deliberately keeps. It costs extra downloads, never wrong values. Grids on the 1/120-degree lattice sit either exactly on a parallel (handled) or at least about 900 m from one, so this does not arise for the shipped grid.
- **Meridian chord error vs the shrink.** A 0.01-degree segment of the densified meridian edge sags about 4 cm from the true sinusoidal curve at lon -139 and 50 N, which is below the 1 m tolerance.
- **Other places with the same edge assumption.**
  - The CMR search is a superset for the selected tiles. One public GET was made: the CMR GPolygons of h10v03 and h11v03 for 2010 contain the true sinusoidal tile boundary, 800 boundary points each, and the only points outside were exact corners at 0 m. So a tile `wet_modis_tiles()` keeps cannot be missing from CMR's bbox match.
  - The mosaic origins were checked in round 1.
  - The test oracle `tiles_oracle()` is used only on a grid 1.3 km from a parallel.

## Also checked and clean

- `wet_download(netrc =)`: the figshare path is unchanged when `netrc = NULL`. libcurl scopes netrc credentials to the matching `machine`, and `unrestricted_auth` is not set.
- The cache key covers the grid, years, `min_years`, `fact`, the granule md5s and the method version. The temp files and `.part` files cannot match `wet_mod16_local()`'s regex. The result is written to a temp file in `dir` and renamed, and the rename is checked.
- `wet_mod16_grid()`: `s / n` where `n = 0` is masked by `ifel(n >= min_years, ...)`. The returned raster does not reference the `tmp` file that `on.exit` deletes (tests write it after return). `terra::rast(grid)` is used deliberately as an empty template.
- NAMESPACE export, and `curl`, `jsonlite` and `terra` are in Imports. `tools::` was already used in `R/wet_climr_normals.R`.
