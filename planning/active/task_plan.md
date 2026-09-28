# Task: Key the pre-#15 input caches on their builder code (#19)

## Problem

`wet_cgiar_aet()`, `wet_climr_normals()` and `wet_dem_glo90()` return a cached file whenever its name matches. The hydrologic-zones raster built in `scripts/wb_inputs.R` does the same. Each name covers the source content, the parameters and the grid, but not the code that computes the grid. `scripts/wb_province.R` puts some of these R files in its run key. A builder fix therefore produces a fresh-looking run key over a stale input.

The zones raster's code lives in `scripts/wb_inputs.R`, which no key covers. A change there (such as dropping the rspatial/terra#2195 workaround) would never reach an existing `hydz_*.tif`.

Found in the #15 review. The two builders #15 added (`wet_landcover_nrcan()` and `wet_terraclimate_aet()`) carry a method-version string in their keys.

## Phase 1: Tests first
- [ ] `test-wet_cgiar_aet.R`: cache hit at the method-keyed name; a file at the pre-#19 name
      (`cgiar_aet_c4908-7920_r3588-5016.tif`) is not returned (network made to fail, expect error)
- [ ] `test-wet_dem_glo90.R`: same pair for `glo90v3_<key>.tif` vs the new name
- [ ] `test-wet_climr_normals.R`: `key()` helper gains the method; a file at the pre-#19 key is
      not returned (climr unavailable / refused before any build → error)
- [ ] Confirm the new tests fail on current code

## Phase 2: Method constants in the three builders
- [ ] `wet_cgiar_method` in `R/wet_cgiar_aet.R`, dest `cgiar_aet_c%d-%d_r%d-%d_<md5(method)[1:8]>.tif`,
      with the #15-style "bump when …" comment
- [ ] `wet_dem_method` in `R/wet_dem_glo90.R` replacing the literal `v3`; dest
      `glo90_<md5(grid key, method)[1:10]>.tif`
- [ ] `wet_climr_method` added to `vkey` in `R/wet_climr_normals.R`
- [ ] Roxygen `@return`/cache notes updated where they describe the key; `devtools::document()`
- [ ] Tests, lintr pass

## Phase 3: Zones raster and the province script
- [ ] `hz_method` constant in `scripts/wb_inputs.R` (names the terra#2195 in-memory workaround),
      hashed into the `hydz_*.tif` name alongside the zip md5
- [ ] `scripts/wb_province.R`: DEM pattern `^glo90_`; comment on `f_in` notes that input names now
      carry their builders' method, so builder files need not join `code_files`
- [ ] Grep `research/`, `CLAUDE.md`, README for the old names/patterns; update any hit

## Phase 4: Re-run the pipeline and prove it reproduces
- [ ] Freeze-copy and run `scripts/wb_inputs.R`; compare every rebuilt raster to its old cache by
      `wet_raster_md5()` (values, not bytes); record in findings
- [ ] Only if all match: remove the old cache files (the old names), so `one()` sees one file each
- [ ] Move `data/wb/adc88b19c8` aside (outside `data/wb/`), run `scripts/wb_province.R 4`, compare
      the new upstream `.rds` to the old ones
- [ ] `scripts/wb_validate.R <v>` for every variant, `scripts/wb_aet_compare.R`,
      `scripts/wb_validate.R <winner>`, `scripts/wb_output.R`, `scripts/wb_map.R`
- [ ] `git diff data/checks/` shows only run-key, date and input-name lines changed; any other
      difference is attributed before going on
- [ ] Commit the regenerated tracked reports; delete the moved-aside old run

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
