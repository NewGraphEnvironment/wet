# Code review, round 2 (staged diff, #1 Phase 3/4)

## Clean

No issues found.

## Round 1 fixes checked

1. **`wet_upstream_mean()` with no upstream value (R/wet_upstream_mean.R:47-52).** The fix is complete. `any_value` has the same level order as `num_total`, `area_cov` and `up`, and `has` can never be `NA`, so the logical index is safe. The override applies in both modes. That matters for `"covered"`: a supplied `value` with `cover = NA` or `0` already gave `NA` through `area_cov > 0`. The result now matches fwapg (`sql/discharge03_wsd.sql`) in all three cases:
   - Some upstream rows are `NULL`: `SUM` skips them, the same as wet's `v[!has] <- 0`.
   - All upstream rows are `NULL`: fwapg gives `NULL` and wet gives `NA`.
   - No upstream polygon is in `discharge02_load`: fwapg writes no row and wet gives `NA`.

   I found no other place where 0 stands in for missing data. `coverage = 0` for a watershed with no value is a correct zero.

2. **`wet_ws_sample(method = "area")` past the raster's edge (R/wet_ws_sample.R:38).** The fix is complete. `snap = "out"` keeps the grid's origin and resolution, and it always contains the union. I checked 300 random rectangles against the planar truth. The raster had an offset origin and anisotropic cells (0.0625 x 0.05), and the rectangles overlapped each edge and corner. The largest `cover` error was 1.7e-4, which is the float precision of the exact-extract fractions. The centroid path never had the bug: a point beyond the extent gets an `NA` row, so `cover = 0`. The test at line 47 confirms this.
   - The checklist warns that `extend()` sizes the grid to the union of the raster and the features. At 0.0625 degrees that union is at most a few hundred cells a side, even for polygons spanning the whole province, so I did not flag it.

3. **`scripts/mad_parity.R` connection and rounding line.** The explicit `dbDisconnect` at line 142 is correct. The rounding parity line compares R's `round()` with Postgres `numeric` rounding, and the summation order also differs. Both effects can only turn a real tie into a reported mismatch, never the reverse. So the check errs toward failing and cannot overstate parity.

## Also checked, not flagged

- `wet_upstream_pairs` SQL matches fwapg's `weighted_avg` join exactly: same `FWA_Upstream` call, `ST_Area(uw.geom)` and `upstream_area_ha * 10000`. Live fwapg check: `FWA_Upstream(a, a)` is TRUE for 200/200 SALR polygons, so each watershed counts itself, as the docs and test fixture assume. SALR has no polygons with NULL `wscode_ltree` or `localcode_ltree`.
- fwapg runs `discharge02_load` for every group before `discharge03`, so it samples upstream polygons outside the target group. The script's cross-group sampling at lines 67-74 matches that.
- `factor()` on the ids and `as.integer(levels(key))` round-trip correctly for both integer and double ids.
- `wet_pcic_fetch`: on a 4xx, libcurl raises an error and the temp file is unlinked. A 200 that is not NetCDF is caught by the signature check. Only validated files are renamed into the cache.
- `wet_runoff_annual`: `as.Date()` on POSIXct times defaults to UTC, duplicate dates are refused, and each year is checked for completeness.
- The test suite passes (`devtools::test()`).
