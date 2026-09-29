# Code review, round 1 (#19, staged diff: method versions in the input-builder cache keys)

## Clean

I found no bugs, security issues or data-loss risks in the staged diff.

## What was checked

- **The new tests can fail.** In a temp copy (under the scratchpad, not the repo) I put
  the pre-change `HEAD` versions of `R/wet_cgiar_aet.R`, `R/wet_dem_glo90.R` and
  `R/wet_climr_normals.R` under the new tests. Each of the three "cached under another
  builder method is rebuilt, not returned" tests then records `failed = 1, error = FALSE`,
  so the expectation itself fails: the old-name file is returned, and there is no error
  to match. The existing "returns cached" tests error there, as expected, because the
  constants are missing. Against the staged code, all three files pass
  (`NOT_CRAN=true`, 21 + 9 + 10 expectations).
- **The error regexes match the real error, not something incidental.**
  - cgiar: with a fresh tempdir there is no `src/.extracted`, so `wet_figshare_files()`
    fetches from `wet.figshare_api = http://127.0.0.1:9`. The curl or HTTP error names
    that host. Nothing earlier in the function can raise.
  - dem: the first network call is `tileList.txt` from `wet.glo90_base = http://127.0.0.1:9`.
    Same reasoning.
  - climr: `"climr reached"` can only come from the mocked `get_bb`. Between the cache
    check and `get_bb` there is only `dir.create` and `names<-`.
- **The climr mock is sound.** `local_mocked_bindings(.package = "climr")` needs testthat
  >= 3.2.0, and DESCRIPTION pins exactly that. climr is in Suggests with a Remotes entry,
  and the test carries `skip_if_not_installed("climr")`. `climr::get_bb` resolves through
  `getExportedValue()` to the namespace binding the mock replaces. The test passing
  proves this: an unmocked `get_bb` would go on to `input_refmap()`, and its error would
  not match `"climr reached"`.
- **Every cache key still covers what affects its output.** cgiar: lattice cells, plus the
  method. The source is pinned by figshare md5. dem: the full-precision grid key, plus the
  method. climr: dataset and years in the name; the years, vars, elevation values and
  method in the hash. A DEM method bump reaches the climr normals through
  `wet_raster_md5(elev)`. No new name can collide with an old one: the old names had no
  hash suffix (cgiar), a `glo90v3_` prefix (dem), or a hash over a different string (climr).
- **Other readers of these filenames.** Nothing in `R/` or `tests/` parses them. In
  `scripts/` (unstaged, next commit):
  - `wb_inputs.R:83` builds the hydz name by `sub()` on the cgiar basename. The new
    suffix passes through, so the hydz key now also carries the cgiar method. That is fine.
  - `wb_province.R:39-40`: `^cgiar_aet_c` and `^glo90_` match the new names. `^glo90_`
    no longer matches the old `glo90v3_` file. Note (fails loudly, not silently): on the
    local `data/` tree, the stale `cgiar_aet_c4908-7920_r3588-5016.tif` and the two
    stale `data/climr/climr_mswx.blend_*` files will sit beside the rebuilt ones.
    `one()` and `climr_with()` would then find 2 files and `stop()`. Delete the stale
    caches, or make the script patterns match only the new names. They stop the run and
    cannot pick the wrong input.
