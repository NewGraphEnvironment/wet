# Code review, round 2: #11 Phase 1 staged diff

Reviewer: subagent, 2026-09-26. Probes ran in /tmp only, and nothing in the repo was edited apart from this file.

## Findings

- **[bug] R/wet_climr_normals.R:41.** The fix for round 1 #2 put `vars` into the cache key, but `years` is still keyed only by `min(years)` and `max(years)`. This is the same defect on the next axis.
  - The function takes an arbitrary integer vector and averages exactly those years (`keep <- yr %in% years`).
  - Example: `wet_climr_normals(dem, years = c(1981, 2010))` builds a 2-year mean and caches it as `climr_climatena_1981-2010_..._<vkey>.tif`.
  - A later default call (`1981:2010`) on the same grid, `dataset` and `vars` then gets that 2-year mean back without comment. The same happens with any gapped selection, such as `seq(1981, 2010, 2)`.
  - The layer names and count are identical, so nothing downstream can tell the files apart.
  - Fix: key on the full set of years, for example by adding the sorted unique years to the text that `wet_md5_text()` hashes.
  - Line 58 builds the `period` label the same way, but only as a layer label, so it is harmless there.

- **[fragile] scripts/wb_inputs.R:55-58.** The hydrologic zones grid still escapes the round 1 #5 fix. It is now keyed on the grid, but `terra::rasterize(..., filename = f_hz)` writes straight to the cached path, and the cache check on line 56 trusts any file there.
  - If a run is killed or fails mid-write, a partial GeoTIFF is left at `f_hz`. Every later run skips the rebuild, the manifest records the md5 and dims of the truncated file, and Phase 2+ reads it.
  - Every other cached raster in this diff avoids this with a tempfile in the same directory plus `file.rename()`: the AET crop, the DEM, the climr normals and the downloads via `.part`.
  - Fix: rasterize to `tempfile(fileext = ".tif", tmpdir = hz_dir)`, then rename it to `f_hz`.

## Round 1 fixes: checked and sound

- **#1, GDAL config restore.** terra 1.9.46 C++ `gdal_setconfig()` calls `CPLSetConfigOption(key, NULL)` when the value is empty, so the two-argument form really unsets the option. It does not store `""`, which GDAL's `CPLTestBool` would read as TRUE for `GDAL_DISABLE_READDIR_ON_OPEN`. Measured: set, then restore with `c("", "")`, returns both options to `""`. A value containing `=` also survives the two-argument form.
- **#2, vars key.** The md5 is taken after `unique()`, and a different order gives a different key. That is correct, because layer order follows `vars`. The `years` gap is above.
- **#3, linear-vars regex.** It admits only monthly PPT/Tave/Tmax/Tmin plus MAP and MAT, and the check runs before climr is loaded. Refusing linear seasonal variables is conservative, not wrong.
- **#4, completion marker.** The marker is written only after both `wet_unrar()` calls return, and `wet_unrar()` stops on a non-zero bsdtar status. A missing marker removes `src` before anything is re-fetched. The test reaches the failure path: the downloader fails on port 9, and `src/AET_YR` is gone afterwards.
- **#5, `.part` download.** Measured: `curl::curl_fetch_disk()` creates the destination file even when the connection is refused. Without the `.part` pattern the old code would therefore have left a file at `dest`, so the test "a failed download leaves no file" does exercise the failure mode. The rename stays within the same directory.
- **#6, ECCC aggregation.** `tapply()` over `factor(cl$id, levels = obs$id)` keeps the order of `obs` and gives NA for stations with no rows. `mean()` without `na.rm` drops any station that has a partial-NA year instead of shortening its average. The dropped stations are counted.
- **#7, manifest date.** The `built:` line is present.
