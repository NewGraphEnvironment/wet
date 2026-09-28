# Findings — Key the pre-#15 input caches on their builder code (#19)

## Issue context

**If we do it:** a fix to an input builder always reaches the province run. **If we never do:** a corrected builder silently reuses its old output under the same file name, and the province run key (which hashes the builder's code) then labels stale inputs as fresh.

## Problem

`wet_cgiar_aet()`, `wet_climr_normals()` and `wet_dem_glo90()` return a cached file whenever its name matches. The hydrologic-zones raster built in `scripts/wb_inputs.R` does the same. Each name covers the source content, the parameters and the grid, but not the code that computes the grid. `scripts/wb_province.R` puts some of these R files in its run key. A builder fix therefore produces a fresh-looking run key over a stale input.

The zones raster's code lives in `scripts/wb_inputs.R`, which no key covers. A change there (such as dropping the rspatial/terra#2195 workaround) would never reach an existing `hydz_*.tif`.

Found in the #15 review. The two builders #15 added (`wet_landcover_nrcan()` and `wet_terraclimate_aet()`) carry a method-version string in their keys.

## Proposed Solution

Give each remaining builder a method-version constant in its cache key, as #15 did. For the zones raster, include `scripts/wb_inputs.R`'s rasterising step (or a version string) in `hydz_*.tif`'s name.

Relates to #15

## Plan-mode exploration (2026-09-28)

What exploration found:
- `R/wet_dem_glo90.R:24` already has a hand version (`glo90v3_`, comment "v3: VRT at the finest
  tile resolution"). The issue's premise is half-true there: it is versioned, just not by a
  named constant. Converting it to `wet_dem_method` makes all six builders one pattern.
- `R/wet_cgiar_aet.R:28` names the crop by integer lattice cells on purpose (comment 23-26);
  keep the cells readable and append a short method hash.
- `scripts/wb_inputs.R:79` derives the `hydz_*.tif` name from the CGIAR basename by `sub()`,
  plus the zip md5. It gets its own `hz_method` constant appended.
- `scripts/wb_province.R` picks inputs with `one()` / `climr_with()`, which demand exactly one
  match, and its DEM pattern is `^glo90v3_`. Renamed caches leave the old files beside the new
  ones, so the old files must go (after a value comparison) and the DEM pattern changes.
- Existing cache-hit tests hardcode names (`test-wet_cgiar_aet.R:40`, `test-wet_dem_glo90.R:19`,
  `test-wet_climr_normals.R:31-37`) and need the method in them.

Changing any input name changes the province run key, so the whole pipeline needs a re-run.
Code that computes values is unchanged, so every value should reproduce exactly: that re-run
is the verification.


## Errors Encountered

| Error | Resolution |
|-------|------------|

## Scoped out (plan review A2, G8)

- The CGIAR crop name keys the lattice cells, not the source archives' content; the rar md5s are checked against figshare only while `src/.extracted` is missing. The DEM name keys the grid, not the GLO-90 tiles on AWS. Both are source-content gaps, not code gaps, and are left for a follow-up.
- terra and GDAL versions are in no builder's key. climr's version is now in the normals key because most of that computation is climr's code.

## Code-check

Three rounds, all Clean. Round 2 noted that `wet_md5_text()` writes via text-mode `writeLines()`, so keys would differ on Windows (CRLF); this predates #19, is consistent per platform, and `data/` never moves between OSes.

## Phase 4: inputs rebuilt under the new keys (2026-09-28)

`wb_inputs.R` in 6.5 min (07:38–07:45 PT; DEM over `/vsicurl/` the bulk). Log: `data/logs/20260928_wb_inputs_run.log` (gitignored).
TerraClimate, land cover and MOD16 hit their caches; CGIAR, DEM, climr ×2 and zones rebuilt.

Every rebuilt raster against the cache it replaces (names, geometry, `wet_raster_md5()` values): **all identical**.
The byte md5s in `data/checks/wb_inputs.txt` are unchanged too; only the file names and the build date moved.
`data/checks/climr_eccc.txt` is unchanged (MAP ratio median 1.034).

So the pre-#19 caches were not stale, despite A3's timing: the CGIAR crop and DEM predate 156317e and the P/T
normals predate 3658923, and none of those changes altered the values. The old files are in
`data/wb_old/pre19_inputs/`; the #18 run `adc88b19c8` is in `data/wb_old/`.
