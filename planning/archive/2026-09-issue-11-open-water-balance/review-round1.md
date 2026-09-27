# Code review, round 1: #11 Phase 1 staged diff

Reviewer: subagent, 2026-09-26. Every probe ran outside the repo, in /tmp or read-only against cached `data/`.

## Findings

- **[bug] R/wet_dem_glo90.R:36-40.** The GDAL config restore does not restore anything. It leaves both options set to the literal string `"NA"`, and that breaks every later `/vsicurl/` read in the R session.
  - `terra::getGDALconfig()` returns `""` for an unset option, so the restore passes `"CPL_VSIL_CURL_ALLOWED_EXTENSIONS="`.
  - terra 1.9.46 `setGDALconfig()` does `strsplit(option, "=")[1:2]`. `strsplit()` drops the trailing empty field, so the value comes out as `NA`, and `.gdal_setconfig()` stores it as the string `"NA"`.
  - Measured: after the set/restore round trip, `getGDALconfig()` returns `"NA"` for both options.
  - With `CPL_VSIL_CURL_ALLOWED_EXTENSIONS=NA`, `terra::rast("/vsicurl/.../Copernicus_DSM_COG_30_N55_00_W128_00_DEM.tif")` fails with `[rast] file does not exist`. The same URL opens once the option is set back to `.tif`.
  - The breakage lasts for the rest of the session. It hits whatever runs after `wet_dem_glo90()` in `scripts/wb_inputs.R`, and any user code that reads a remote COG.
  - Fix: use the two-argument form, `terra::setGDALconfig(c("GDAL_DISABLE_READDIR_ON_OPEN", "CPL_VSIL_CURL_ALLOWED_EXTENSIONS"), old)`. Measured: with an empty value this form unsets the option, and the `/vsicurl/` read then succeeds.

- **[bug] R/wet_climr_normals.R:29-32.** The cache key leaves out `vars`, so two calls with different variable sets collide.
  - Suppose `wet_climr_normals(dem, vars = c("PPT_07", "Tave_07"))` runs first. A later default call on the same grid, `dataset` and `years`, in the same `dir`, gets the cached 2-layer file back without comment.
  - Downstream, `r[["PPT_01"]]` then fails, or a consumer that indexes by position silently reads the wrong layers.
  - The `overwrite` escape hatch only helps if the caller knows about the collision. The accepted tradeoff says the key "encodes bbox/grid", but `vars` is part of the output's content, not its grid.

- **[fragile] R/wet_climr_normals.R:1-8 and 20-22.** The doc says that averaging anomalies before downscaling "gives the same normal". That is true only for variables that are linear in the anomalies: monthly PPT, Tmin, Tmax and Tave, and sums or means of them such as MAP and MAT.
  - `vars` is an open argument. climr derives DD5, NFFD, PAS, CMD, Eref, FFP, EMT and similar variables from the downscaled monthly T and P through non-linear functions.
  - For those, deriving from the mean anomaly is not the mean of the per-year derivations, so the function returns a biased normal without any warning.
  - The defaults and the driver are unaffected. Either restrict `vars` to linear variables or state the limit.

- **[fragile] R/wet_cgiar_aet.R:27-30.** The "already extracted" check tests only `aet_monthly/aet_1` and `AET_YR/aet_yr`, and those are directories that bsdtar creates before it writes their contents.
  - Suppose an extraction is interrupted, or bsdtar exits non-zero partway through (disk full, a killed run). Every later call then skips re-extraction.
  - It then fails in `wet_cgiar_stack()` with "CGIAR grid missing: aet_12", or with a GDAL read error on a truncated `.adf`. Nothing tells the user to delete `data/cgiar/src`.
  - The good RAR, verified by md5, sits right next to it and is never re-extracted. Checking all 13 grids, including a data file inside each one such as `w001001.adf`, would let the next run heal itself.

- **[fragile] scripts/wb_inputs.R:61-68.** `data/hydz/hydz_grid.tif` is cached by a fixed name and rebuilt only when it is missing. If `bbox` changes, the AET, DEM and climr files get new keyed names but the zones grid is the old one.
  - The overlay then misaligns, or fails later. The manifest records the stale grid's dims without comment.
  - This goes against the stated convention that a changed grid is a new cache file.
  - The zip download has the same shape (lines 55-59). `wet_download()` unlinks `dest` only on a non-200 status. A curl-level error such as a timeout or reset leaves a partial `bc_hydrologic_zones.zip`, the next run skips both download and unzip, and `list.files(...)[1]` is `NA`, so `terra::vect(NA)` fails.
  - The RARs are protected by the md5 check. The zip is not.

- **[fragile] scripts/wb_inputs.R:115-130.** `stats::aggregate(cbind(MAP, MAT) ~ id, ...)` uses `na.action = na.omit`, so a year with NA MAP or MAT is dropped without comment. That station's "30-year normal" then averages fewer years.
  - A station whose years are all NA disappears from `cl`, and `match()` gives it NA.
  - The earlier `complete.cases()` ran before this point, so the NA station stays in `obs`.
  - `sum(obs$map_ratio < 0.8 | obs$map_ratio > 1.25)` has no `na.rm`, so the report then prints "NA stations".
  - The current output is unaffected: 57 stations, count 5.

- **[minor, plan vs code] planning/active/task_plan.md.** The manifest checkbox is ticked as "(source URL, md5, date, dims)", but `data/checks/wb_inputs.txt` records no date: no download date and no build date.
  - The figshare and data.gov.bc.ca sources can change under the same URL, so the md5 alone does not say when the file was fetched.
  - Either add the date or reword the checkbox.

## Checked and not a finding

- The cache names match the tests: `format(nsmall=3)` for bbox, `%.3f` for the template extent, `e[c(1,3,2,4)]`.
- `wet_glo90_names()` is correct at whole-degree edges.
- The md5 re-download path is sound. A partial RAR is re-fetched.
- The CGIAR source types are Byte for monthly (nodata 255) and Int16 for annual (nodata -32768). INT2U holds both, and the crop layers are not factors despite the source RATs.
- In a 20k-cell sample, the monthly sum equals the annual exactly.
- `names<-` on `elev` does not mutate the caller's raster, because `dem[[1]]` copies.
- The regex in `wet_climr_anomaly_mean` handles the `.` in `cru.gpcc` and `mswx.blend`. It is a wildcard there, which is harmless.
