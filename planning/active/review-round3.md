# Review round 3 (#19): staged diff, R/ tests/ scripts/

## Clean

No issues found.

## What was checked

- **Zones key covers the grid.** The old name carried the CGIAR lattice cell
  indices plus the CGIAR method hash. The new key carries `wet_grid_key()`,
  which is the full-precision extent, dims and CRS. That identifies the grid at
  least as fully as the old name. It no longer carries the CGIAR method, which
  is correct because the zones grid depends on the AET grid and not on its
  values.
- **13-layer file keys the same grid.** Measured on the live
  `data/cgiar/cgiar_aet_c4908-7920_r3588-5016.tif`, which has 13 layers:
  `wet_grid_key(rast(f))`, `wet_grid_key(rast(f)[[1]])`, the existing hydz
  output and the existing DEM all return `98f0f8e0170760b96a225b3c14b33c22`.
  `wet_grid_key()` does not read `nlyr`.
- **Old name shapes in scripts/.** A grep for `hydz` and `glo90` across
  scripts/, R/ and tests/ finds no remaining parse of the old hydz name. The
  wb_inputs.R manifest uses `f_hz` only as a path, and `grid_of()` reads the
  raster. In wb_province.R, `^glo90_` does not match the old `glo90v3_` name,
  and the temp files in the data dirs are named `file*.tif`, which matches
  neither pattern. The old `hydz_c4908-...tif` still matches `^hydz_`, so
  `one()` will stop loudly until Phase 4 moves it out. That is the accepted
  stale-cache item.
- **climr version, test vs function.** Both call
  `utils::packageVersion("climr")` in the same R process, so the values cannot
  differ. Both tests that build a key are guarded by
  `skip_if_not_installed("climr")`. In the new "rebuilt" test, `name()` leaves
  out the climr version. The file it builds is therefore a non-matching name,
  which is what that test needs.
- **Tests run on the staged tree** (a copy in the scratchpad, `NOT_CRAN=true`).
  `test-wet_cgiar_aet.R`, `test-wet_dem_glo90.R` and `test-wet_climr_normals.R`
  all pass. The mocked `climr::get_bb` is reached, which confirms the stale
  names are not returned.
