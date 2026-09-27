# Review: #11 Phases 3-6 staged diff, round 1

Reviewer: subagent (read-only on repo; probes run in a scratch copy of the staged tree built with `git checkout-index`)

## Findings

### 1. [Medium] The staged `wet_wb_adjust()` fails on data with no zone columns. The fix exists but is not staged.
`R/wet_wb_adjust.R:300` (staged) calls `wet_zone_cols(d)`, which stops with "no zone columns (z<k>, zp<k>)" when `d` has no `z<k>` column (`R/wet_wb_fit.R:371`).

This is reachable on real data. Upstream basin `955` in this run (6,544 watersheds) has zero zone columns and coverage 0 everywhere, so applying the fit to it province-wide stops. The documented contract says a zone in `fit` that is missing from `d` counts as share 0, and the function breaks it in the all-missing case.

The working tree already has the fix: the `has_z` guard, plus a `none <- data.frame(raw = ...)` test in `test-wet_wb_fit.R`. Both show as `AM` in `git status`, meaning they are **unstaged**. Committing the index as it stands ships the failing version. Remedy: `git add R/wet_wb_adjust.R man/wet_wb_adjust.Rd tests/testthat/test-wet_wb_fit.R`.

### 2. [Medium] The CV numbers do not validate the fit that is shipped, for about a third of the stations.
`wet_wb_fit()` pools a zone when it has fewer than `min_gauges = 8` dominant gauges. Pooling is (correctly) decided per training fold. The consequence is that any zone near the threshold is pooled in the folds that hold out its gauges, while `fits.rds` (`ins_fit`, `scripts/wb_validate.R:757,769`) fits that zone on its own.

I measured this on the calibration set (scratch copy, staged code, same inputs; the report reproduced byte-identical first):
- Blocked CV: 94 of 280 held-out stations are predicted with their zone pooled, although the shipped fit gives that zone its own coefficients. That covers 13 zones: 01 07 10 13 18 19 20 21 22 23 24 27 28.
- LOO: 32 of 280 stations (zones 07, 10, 23, 24). Each of those zones has exactly 8 dominant gauges, so every LOO fold drops it to 7 and pools it.

The report labels the blocked CV block "the honest ungauged estimate" and LOO "comparable with Chapman". For these stations, both measure the pooled model, not the model in `fits.rds`. The clearest case is zone 24: CV MAE 228 %, in-sample 51.5 %, with zone-own coefficients a = -362, b = 0.0485 that CV never tests.

This is not leakage. Deciding pooling on all stations would be leakage. It is a gap between the numbers and their label: the gate (`hw(cv_v) < hw(raw_v)`) and the headline 33.6 % / 33.0 % describe a model structure that differs from the one shipped, for these zones. At minimum, report the count. Alternatively, report CV metrics split by "zone pooled in fold vs own in the full fit".

### 3. [Low-Medium] The `wet_wb_fit()` documentation is wrong about zones with no information.
`R/wet_wb_fit.R:331-332` says: "A zone whose columns carry no information in the data gets no adjustment (coefficient 0)."

With `min_gauges >= 1`, such a zone has 0 dominant gauges, so it is always pooled. It then receives the `"other"` coefficients whenever another pooled zone has data. It only gets 0 if every pooled zone is uninformative, or if `min_gauges <= 0`.

Demonstrated: take the second test's data (zone 10 pooled, with data) and add `z11 = zp11 = 0`. `wet_wb_fit(d)$coef` then gives zone 11 `a = 50, b = -0.10` (zone 10's pooled values), not 0.

The test at `test-wet_wb_fit.R:1006-1012` only checks the degenerate case where "other" contains nothing but the empty zone, so it passes. This changes what the province output means for a zone that no calibration gauge touches, and for zones emptied inside CV folds: they get the pooled adjustment, not "no adjustment". Fix the documentation, or the code if 0 is the intent.

### 4. [Low] `bc_fraction` is not the share of the basin inside BC for coastal ground.
`scripts/wb_province.R:559,599-600` computes `in_bc` as each 30" cell's fractional cover by the BC polygon, area-averaged over the cells a watershed polygon overlaps. It is not the share of the polygon inside BC. A watershed wholly inside BC that touches coastal cells (part ocean) therefore reads below 1.

Measured case: 08OA003 Premier Creek (Haida Gwaii, entirely in BC) has `bc_fraction` 0.899. In this run no calibration station was excluded by this alone: Premier Creek also has coverage 0, and every other station below 0.95 is a genuine cross-border basin. The label "basin >= 95 % in BC" in the report still overstates what the filter measures, and small coastal basins can be dropped.

### 5. [Low] The report says "309 accepted snaps with predictors", but 9 of them have no predictors.
`scripts/wb_validate.R:788` prints `nrow(st)` after the merge. Nine of those 309 have coverage 0 and NA for every layer (for example `p_yr`). The correct figure is "300 with predictors", or the line should drop "with predictors".

### 6. [Low, latent] One NA prediction makes the group summaries NA while still being counted in `n`.
In `R/wet_flow_validate.R:149-155`, a station with `obs >= min_obs` but NA `mod` is counted in `n`. Its NA `err_pct` then makes `mean_err_pct`, `mae_pct` and `within_20` NA for every group it belongs to, because `mean()` is called without `na.rm`, while the medians use `na.rm`. It is not triggered now: all 280 predictions are finite. The first NA from any upstream change will blank the headline MAE rather than drop or flag the station.

### 7. [Low] Housekeeping in `scripts/wb_province.R`
- Header line 10 says "the tracked run log data/wb/province_run.log". That path is gitignored (`.gitignore:8`, confirmed with `git check-ignore -v`). The tracked copy is `data/checks/wb_province_run.txt`, which is written by hand.
- Line 611: `on.exit(parallel::stopCluster(cl), add = TRUE)` at the top level of an Rscript never fires (code-check-r). If `clusterApplyLB` errors, the cluster is not stopped explicitly.
- The run key (line 514) hashes input file names and a manual tag only. A `WET_WB_GROUPS` smoke test writes `sample/<WSG>.rds` under the same key, and a later full run reuses those files silently even if the sampling code changed in between. In this run SALR and BULK were written at 18:41:30 by the smoke test and reused. I could not verify that the code was identical. Bump the tag, or delete the smoke-test outputs, whenever `sample_group` changes.

## Verified clean (checked, no issue)
- **FWA_Upstream port.** `wet_fwa_upstream()` matches fwapg `whse_basemapping.fwa_upstream()` on all 280 x 280 calibration-station pairs: 219 pairs in both, 0 mismatches. The collation locale is restored afterwards.
- **`wet_cv_folds` quantities.** `leak_down` (column sums of `up & other`), `nesting` and `leak_up` match their documentation.
- **Layer identities in the station upstream means.** Sum of `ppt_MM` = `p_yr` (|diff| < 3e-5). Sum of `aet_MM` / `aet_yr` = 1. `ro_raw` = `p_yr - aet_yr`. Mean of `tave` = `t_yr`.
- **Zone columns in the upstream files** (checked in basins 300, 500, 900, 915, 999). The z shares sum to exactly 1 and the zp columns sum to `p_yr` (diff about 1e-12) wherever coverage > 0; everything is NA where coverage = 0. Filling a zone absent from a group or basin with 0 is correct for covered polygons and irrelevant for uncovered ones.
- **Units.** Observed mm = `q * days * 86400 / area_m2 * 1000`, with 365.25 days = the sum of the monthly days. The sum of monthly volumes over the annual volume is 1, and the monthly shares sum to 1. The accumulated FWA area over fwapg's stored upstream area is 1 for accepted stations; FWA over HYDAT gross area ranges 0.90-1.10.
- **`wet_ws_sample` rowsum alignment.** `rownames` round-trip through `as.integer` (including the "1e+05" form). The largest group has 58,075 polygons. Row-wise recycling of `v * fr` and `wv / cov` is correct.
- **`long()` reshaping.** It is column-major, consistent with `rep(..., each = n)`.
- **Share prediction.** Renormalisation and flooring are correct.
- **`lm.fit` rank deficiency.** Setting NA coefficients to 0 is still a valid least-squares solution, so fitted values are unaffected.
- **No CV leakage** from zone pooling, share fits or folds: all are fitted on the training rows only. The report's `zone` and `area_class` columns are used for grouping only.
- **`wb_validate.R` reproduces the staged report byte for byte** from the run outputs. Note: `data/wb/d73b4ef710` was moved to `data/wb_old/climatena_d73b4ef710` at 19:01 by another process while this review ran. The probes used the moved copy.
