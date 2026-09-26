# Code review, round 1 (staged diff, #1 Phase 3/4)

## Findings

- **[severity: bug]** R/wet_upstream_mean.R:36-38, 47. With `denom = "total"`, a watershed where no upstream polygon has a value gets `value = 0`, not `NA`. `v[!has] <- 0` zeroes the missing values, then `num_total / up` is `0 / up = 0`. fwapg does `sum(weighted_discharge)` over rows whose `discharge_mm` are all NULL (`sql/discharge03_wsd.sql`), and that gives NULL. If none of the upstream polygons are in `discharge02_load`, fwapg writes no row at all. Either way fwapg reports no value. wet reports 0 mm, and `wet_mm_to_m3s()` then gives 0 m3/s. That reads as a real zero flow. It will happen on any polygon, or chain of headwater polygons, whose centroid falls on PCIC fill cells or outside the fetched subset. The function's doc says this mode "reproduces fwapg". SALR never hits this case because its coverage is 1 everywhere (checked in `data/parity/SALR_parity.csv`), so the parity run cannot catch it.
  - Checked in R: pairs `1<-2` with both values `NA` gives `value = c(0, 0)`, `coverage = c(0, 0)`, and `wet_mm_to_m3s()` gives `0 0`.
  - `tests/testthat/test-wet_upstream_mean.R:27` (`expect_equal(tot$value[3], 0)`) currently asserts the wrong result.
  - Fix: set `value` to `NA` wherever `tapply(has, key, any)` is `FALSE`, then assert `NA` in that test.

- **[severity: bug]** R/wet_ws_sample.R:35-44. With `method = "area"`, `cover` is wrong when a polygon extends past the raster's extent. `tot` is the sum of the `fraction` values that `terra::extract(exact = TRUE)` returns, and extract returns no rows at all for ground beyond the extent. Only NA cells inside the extent get rows. So a polygon hanging half off the fetched subset reports `cover = 1`. The doc promises "a polygon half off the model domain reports `cover = 0.5`". `wet_upstream_mean(denom = "covered")` then weights that polygon by its full area (`a * cv`), and the reported `coverage` is overstated. The raster is always a bbox subset from `wet_pcic_fetch()`, so this isn't an exotic case.
  - Checked in R: on a 2x2 test grid, a polygon half inside a valued cell and half beyond `xmax` gives `value 20, cover 1`.
  - `scripts/mad_parity.R:81-82` guards against this with a bbox assertion, but the exported function does not.
  - Fix: take the denominator from the polygon's own size in cell units, not from the rows extract returned. Or pad the raster with NA past the polygons first (`terra::extend(r, terra::ext(poly), snap = "out")`, which is fine for one group). Or stop when `terra::ext(poly)` is not inside `terra::ext(r)`.

## Checked, not flagged

- `wet_pcic_index` grid constants (lon0/lat0/res/nlon 496/nlat 367, both axes ascending). I checked them against the live DDS and against the cached SALR subset's cell centres. Time index = day offset was confirmed on the historical run (`time[24105] = 24105`). The DAS for the scenario runs (CanESM2, HadGEM2-ES, ACCESS1-0) all declare `calendar "standard"`, and each has 56613 steps, which is 1945-01-01 to 2099-12-31.
- `terra::project(SpatExtent)` in `mad_parity.R:81` densifies the extent before projecting, so the guard does not suffer the corner-reprojection trap.
- `mad_parity.R:30` `on.exit()` at the top level of a script never fires. The connection is only closed when the process exits. That is harmless under `Rscript`.
- Weighting formula, m3/s constant and centroid sampling (`centroids(inside = FALSE)` vs `ST_Centroid`) all match fwapg. fwapg also excludes order-8+ river polygons as targets, so wet produces extra rows there, and the parity merge ignores them. No undeclared `::` imports (`tools:::.check_packages_used`).
