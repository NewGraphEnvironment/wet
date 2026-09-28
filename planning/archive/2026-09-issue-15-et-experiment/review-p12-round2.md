# Code review, round 2: `wet_landcover_nrcan()`, `wet_terraclimate_aet()`, wb_inputs additions

Reviewer: subagent, 2026-09-27. Diff: `git diff --cached` (diff_p12.patch).

## Findings

- **[fragile]** R/wet_landcover_nrcan.R:48-50: the fractions cache key covers only the grid, the classes and the codes. It leaves out the source raster. `wet_landcover_nrcan()` reads its source from `getOption("wet.nrcan_landcover_url")`, so pointing that option at another product (a different year, say) returns the fractions already cached from the 2020 file, because the grid and the table have not changed. The same happens if the source `.tif` is deleted and downloaded again as a revised file. `wet_terraclimate_aet()` does not have this problem because its key includes the md5 of its sources. Fix: add `url` to the key, plus the source's size and mtime (or its md5, which takes a few seconds on 2.1 GB).
- **[fragile]** R/wet_landcover_nrcan.R:70: `normalizePath(src)` goes into `<SourceFilename>` without `wet_xml_escape()`, although the SRS on line 76 is escaped. A cache `dir` whose absolute path contains `&` or `<` produces a malformed VRT, and `terra::rast(vrt)` fails. It fails loudly and returns nothing wrong. The fix is one call.

## Checked and found correct (probed, not assumed)

- **The VRT does not read overviews.** I built a COG with NEAREST overviews (800², 400²) from a 1600² random source. The 4×4 fractions from it are identical to those from the same source without overviews, and both match `aggregate()` to 1e-4. So `terra::project(method = "average")` reads full resolution through the LUT VRT and does not sample a nearest-resampled overview.
- **The VRT holds up across CRSs.** Source in EPSG:3979 at 30 m (codes 0/1/10/18 with NAflag 0), target in EPSG:4326 at 1/120°. The VRT grass fraction minus a plain `project(average)` of a 0/1 indicator raster is exactly 0 in every cell. No cell is NA, and the 0 (no-data) pixels count as uncovered.
- **LUT:** it lists every value from 0 to 255, so linear interpolation never produces a fraction. The source is uint8, so no value falls outside the range. The band dataType is Float32 and the VRT band has no NoDataValue. Confirmed by the tests and by the probe above.
- **GeoTransform:** xmin, xres, ymax and −yres, written at %.17g, are correct. `relativeToVRT="0"` with an absolute path is correct.
- **TerraClimate scale and fill:** terra applies `scale_factor` when it reads `data/terraclimate/TerraClimate_19812010_aet.nc`. The 12-month sum at (−119.852, 49.79458) is 392.2 mm, matching the expected value. Ocean points (−130/45, −125/49.9) read NA, so `_FillValue` is honoured. The north/south orientation is correct, since the point value matches.
- **`extend(ext, 2 * res(r))`:** a length-2 vector extends x by res_x and y by res_y. Correct.
- **`wet_download`:** it writes to `.part`, checks for status 200 and then renames, so a failed or partial fetch never lands at `dest`. A stale `.part` from a killed run is overwritten by `curl_fetch_disk`.
- **wb_inputs.R:** the Tmax/Tmin call goes into its own cache file, keyed on `vars` and the DEM values. The manifest vectors all have 14 elements.
- **Tests:** both files pass (11 and 9 expectations, with `NOT_CRAN=true`). `withr` is in Suggests, and testthat is pinned at ≥ 3.2.0 for `local_mocked_bindings`.
