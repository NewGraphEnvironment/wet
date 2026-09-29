# Review round 2 — #19 staged diff + unstaged scripts/

## Clean

No issues found.

What was checked (beyond round 1):

- **Downstream use of the names.** Only `scripts/wb_inputs.R` and `scripts/wb_province.R` touch
  the builders' file names (grep over `scripts/`, `R/`, `tests/`). The hydz `sub("^cgiar_aet_(.*)\\.tif$", ...)`
  still matches the new cgiar name and yields `hydz_c…_r…_<cgiar8>_<zip8>_<hzmethod8>.tif`; nothing
  parses the cells out of it. The other grid-keyed builders (`wet_terraclimate_aet()`,
  `wet_landcover_nrcan()`, `wet_mod16_aet()`, and `wet_dem_glo90()`/`wet_climr_normals()` themselves)
  key on `wet_grid_key()` of the template, not on the cgiar file name, so the cgiar rename does not
  force a MOD16/Earthdata rebuild. The new DEM pattern `^glo90_.*\\.tif$` does not match the old
  `glo90v3_…` name (so no DEM collision), nor `.aux.xml` sidecars or `tempfile()` leftovers. Scripts
  use `devtools::load_all()`, so no stale installed builder is picked up.
- **Run-key side effect.** `wb_province.R`'s key hashes `basename(f_in)`, so the new names make a
  new `data/wb/<key>`; `wb_output.R`, `wb_map.R` and `wb_cv_lib.R` require exactly one complete run.
  Phase 4 already moves `data/wb/adc88b19c8` aside, so this is covered. `data/checks/wb_inputs.txt`
  records the old file names and will change on the Phase 4 re-run, as the plan expects.
- **`wet_climr_normals()` ordering.** The key (including the method) is computed after the var
  check and `requireNamespace()` and before `dir.create()` and any climr call; no wasted or unsafe
  work precedes the cache check. (Pre-existing: a cached file cannot be returned when climr is not
  installed — unchanged by this diff.)
- **R CMD check.** Tests use only `wet:::`, `withr` (Suggests), `terra` (Imports) and
  `local_mocked_bindings(.package = "climr")` behind `skip_if_not_installed("climr")`; climr is in
  Suggests, `testthat (>= 3.2.0)` is pinned, and `get_bb` exists in climr 0.2.2's namespace. The
  method constants are defined after their functions but read at call time, so collation is fine.
- **Windows line endings.** `wet_md5_text()` writes via `writeLines()` to a path, i.e. a text-mode
  connection, so on Windows the hashed bytes end in `\r\n` and every `wet_md5_text()`-based name
  differs from macOS/Linux. This is pre-existing for every key in the package, is self-consistent on
  any one platform (the new tests derive names through the same function; no test hardcodes a hash),
  `data/` is per-machine, and the only CI workflow runs on ubuntu. Not a failure here; it would only
  matter if cache files or run keys were shared across OSes.
