# Code-check round 2: branch 121-per-year-era5-land-snow-for-a-watershed

## Checklist read

- code-check.md: the prose of all 14 H3s under `## Mechanisms` (tables skipped). Of the 26 other headings (Rules that stand alone, Security, Spreadsheets and PDFs), none read: none applies to this diff.
- code-check-spatial.md: read 4, "terra `metags<-` merges ...", "terra `metags()`: the empty case is `NULL` ...", "terra: `extract()` returns no row for ground beyond the raster ...", "terra: `sources()` on a derived raster ...". About 100 not read.
- code-check-r.md: none read in full. The index lines I checked the diff against are `$` partial matching (pr$mx / m$e / s$n), `data-raw/` loads the source tree (it calls devtools::load_all), `pkg::` in a test needs a declared package (sf and withr are in Suggests), Postgres row order (ds_watershed orders by id), regenerated binaries, and `sort()`. About 130 not read.
- code-check-shell.md: none read (the diff has no shell). About 150 not read.

## Probes (run on a `git archive HEAD` copy in a temp dir, loaded with load_all)

- Ran the roxygen example on the bundle. It runs and gives 1950-2025, cover 1.
- An EPSG:3005 outline against the EPSG:4326 layers gives the same values as the outline projected to 4326 first.
- A polygon half past the raster's east edge gives the land value and cover 0.5, in 4326 and in 3005.
- A polygon wholly off the grid returns NA values and cover 0. `terra::intersect()` returns NULL for extents that only touch, so the early return also catches that case.
- A disjoint multipolygon and a polygon with a hole give the exact means.
- A single variable over a single year works, with `years` as "1990".
- `years = c(1990, 1990.5)` stops with an unclear message, but it does stop.
- data-raw guards: `identical(a, b)` compares the bundle with cd's whole files (`cd_cache_fetch`), a different read path, so it can fire. A crop narrower than the window the function reads would give cover < 1, and `all(a$cover == 1)` would fire too. The tag and cell checks read the written file back against a separate read of the remote. None of these guards passes when it should fail.
- The wet_snow_normals() refactor moves code without changing behaviour. The order of the checks and their messages is unchanged.

## Findings

- **[severity: fragile]** R/wet_snow_annual.R:4,10 (roxygen "area-weighted mean") and :105 (`wet_ws_sample(stack, u, method = "area")` on the one dissolved polygon). Each cell's weight is its covered fraction of a 0.1-degree lon/lat cell, and the weight ignores the cell's true area. The two match only while cos(lat) barely changes across the watershed. That holds for fundamental watersheds and for the three pilot watersheds (about 0.5 degrees of latitude). Dissolving one large basin into a single polygon breaks it. Measured on a box from 49 to 58 N (in EPSG:3005, layer value = latitude): the function returns 54.50, against a true area-weighted mean (exact fraction x `cellSize()`) of 54.34. Cells at 49 N get about 24 % too little weight against cells at 58 N. The province pipeline is not affected: it samples each fundamental watershed and weights by true area in wet_upstream_mean(). So the same basin's snow from this function and from the normals path differ. The parity line in scripts/departure_snow.R samples both sides through the same dissolved wet_ws_sample() and cannot detect this. Either weight by `cellSize()` (or by fraction x cos(lat)) or say in the roxygen that the weight is the covered fraction of a lon/lat cell. Either one fixes the contract for users outside the pilot. The pilot's numbers do not move materially.
- **[severity: fragile]** R/wet_snow_annual.R:79-81 and :92. The NA and duplicate check on `years` runs before the coercion, and `sort(as.integer(years))` then drops any NA it creates. So `years = c("1990", "x")` returns only 1990, with nothing but a coercion warning. Asked-for years go missing from the result. A fractional year is also truncated silently (`years = 1990.7` returns 1990). Coerce first and check afterwards: anyNA, anyDuplicated, and `years == round(years)`.

No bugs, security issues or data-loss paths found. The registered header, the report and the refactor were confirmed in round 1 and were not re-litigated here.
