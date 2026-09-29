# Task: Key the pre-#15 input caches on their builder code (#19)

## Problem

`wet_cgiar_aet()`, `wet_climr_normals()` and `wet_dem_glo90()` return a cached file whenever its name matches. The hydrologic-zones raster built in `scripts/wb_inputs.R` does the same. Each name covers the source content, the parameters and the grid, but not the code that computes the grid. `scripts/wb_province.R` puts some of these R files in its run key. A builder fix therefore produces a fresh-looking run key over a stale input.

The zones raster's code lives in `scripts/wb_inputs.R`, which no key covers. A change there (such as dropping the rspatial/terra#2195 workaround) would never reach an existing `hydz_*.tif`.

Found in the #15 review. The two builders #15 added (`wet_landcover_nrcan()` and `wet_terraclimate_aet()`) carry a method-version string in their keys.

## Phase 1: Tests first
- [x] `test-wet_cgiar_aet.R`: cache hit at the method-keyed name; a file at the pre-#19 name
      (`cgiar_aet_c4908-7920_r3588-5016.tif`) is not returned (network made to fail, expect error)
- [x] `test-wet_dem_glo90.R`: same pair for `glo90v3_<key>.tif` vs the new name
- [x] `test-wet_climr_normals.R`: `key()` helper gains the method; a file at the pre-#19 key is
      not returned (climr mocked to error, reached only on a cache miss)
- [x] Confirm the new tests fail on current code

## Phase 2: Method constants in the three builders
- [x] `wet_cgiar_method` in `R/wet_cgiar_aet.R`, dest `cgiar_aet_c%d-%d_r%d-%d_<md5(method)[1:8]>.tif`,
      with the #15-style "bump when …" comment
- [x] `wet_dem_method` in `R/wet_dem_glo90.R` replacing the literal `v3`; dest
      `glo90_<md5(grid key, method)[1:10]>.tif`
- [x] `wet_climr_method` added to `vkey` in `R/wet_climr_normals.R`
- [x] Roxygen `@return`/cache notes updated where they describe the key (none describe it; no roxygen changed)
- [x] Tests, lintr pass

## Phase 3: Zones raster and the province script
- [x] `hz_method` constant in `scripts/wb_inputs.R` (names the terra#2195 in-memory workaround);
      zones keyed `hydz_<md5(grid key, zip md5, hz_method)>.tif`, no longer derived from the CGIAR name
      (plan review G3)
- [x] `scripts/wb_province.R`: DEM pattern `^glo90_`; `code_files` comment says input names carry their
      builder's method and why `wet_climr_normals.R` stays (plan review G7)
- [x] climr's own version in the normals key (plan review G8)
- [x] Grep `research/`, `CLAUDE.md`, README for the old names/patterns; update any hit
- [x] All code committed and `/code-check` clean before Phase 4: the run key and `score_code_md5` hash
      it (plan review O1)

## Phase 4: Re-run the pipeline and prove it reproduces
Each script runs from a frozen copy (Rscript reads incrementally) under `caffeinate -i`.
`scripts/wb_stations.R` is not re-run (plan review A4).
- [x] `wb_inputs.R`: rebuilds CGIAR, DEM, climr x2 and zones; TerraClimate, land cover, MOD16 still hit
- [x] Compare each rebuilt raster to the cache it replaces: names, geometry, `wet_raster_md5()` values.
      On a mismatch attribute it (A3: CGIAR/DEM predate 156317e, P/T normals predate 3658923; DEM and
      climr read remote data) and stop and report; never let a changed input into a no-op re-run (G2)
- [x] Move the old CGIAR, DEM (`glo90v3_*`), climr x2 and zones files to `data/wb_old/`, so `one()` and
      `climr_with()` see one file each (O3)
- [x] `mv data/wb/adc88b19c8 data/wb_old/`; `wb_province.R 4 | tee data/checks/wb_province_run.txt` (G5)
- [x] `layers.tif` identical layer by layer; upstream means equal matched by `watershed_feature_id`
      within 1e-12 relative (G1)
- [x] `wb_validate.R` for `cgiar lc tc fu cfu fu15 fu20 fu35 mod16 cmod16`; `wb_aet_compare.R` (its
      stage-1 check `stop()`s unless #15 reproduces); `wb_validate.R cfu`; `wb_output.R`; `wb_map.R`
- [x] Acceptance (B1): winner cfu; `research/wb_runoff_annual.png` byte-identical (G6); report diffs
      limited to run key, dates, timings, zone/coefficient row order, and `wb_inputs.txt` byte md5s
      whose values matched; `climr_eccc.txt` unchanged or its drift attributed to ECCC
- [x] Update `research/water_balance_method.md`'s run citation to the new key (G4)
- [x] Commit the regenerated tracked reports and the run record in findings

## Validation

- [x] Tests pass
- [x] `/code-check` clean on each commit
- [x] PWF checkboxes match landed work
- [x] `/planning-archive` on completion
