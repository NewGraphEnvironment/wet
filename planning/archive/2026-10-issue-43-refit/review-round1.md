# Code review, round 1 (#43, staged diff)

## Findings

- **[severity: bug]** scripts/wb_score_md5.R:70-72 with scripts/wb_validate.R:24-47, 88, 92 and scripts/wb_aet_compare.R:25-28. Once `wb_pooled_test.R` writes `pooled_variant.txt`, the fit can never ship again without someone deleting files by hand, and the amended rule 6 gate stop is skipped on the rerun the plan prescribes.
  - The new file goes into `score_files`, so `score_code_md5` changes. I checked this in a temp copy: md5 `48d156c6…` became `e48c2cd1…`.
  - `aet_winner.txt` line 2 still holds the old md5, carried or compared alike. On the rerun the carry branch is skipped because the winner file exists, so `ship_aet <- NA` (validate:45).
  - Then `wb_validate.R cfu` (Phase 4's "rerun wb_validate.R cfu") does three things wrong:
    - It writes no `fits.rds`, because `"cfu" %in% NA` is FALSE.
    - It never evaluates the amended rule 6 gate stop at :88, which has the same `aet_v %in% ship_aet` guard. So the gate result for the fixed variant is never enforced.
    - It prints "rerun scripts/wb_aet_compare.R". `wb_aet_compare.R` refuses any fit that has `pooled_variant.txt` (amendment 7).
  - Without an argument, `aet_v` is NA and `wet_wb_raw(cal, NA)` fails.
  - `wb_output.R:37-38` and `data-raw/segment_vignette_data.R:76` then refuse the fit as well.
  - A carried fit (20260717) can only be recovered by deleting `aet_winner.txt` by hand and re-carrying. A compare-chosen fit (20251014, if the pooled test runs on it while it is still shipped, as Phase 4 step 4 reads) cannot be recovered at all.
  - Fix: hash the AET winner against an md5 that excludes `pooled_variant.txt`, or have `wb_validate.R` re-carry whenever `WET_AET_CARRY` is set and the winner's line 3 says it was carried. In either case the gate stop must run whenever `aet_v` is the fit's AET.
  - Related: any edit to a scoring script also stales a carried winner, and the only remedy the message offers is `wb_aet_compare.R`. On 20260717 that script deletes `aet_winner.txt` (:29) and then stops on the #15 reproduction.

- **[severity: fragile / rule interpretation]** scripts/wb_pooled_test.R:56-60, 63-67. The rule says "a zone the fit has not seen gets no adjustment, as in `wb_output.R`", and amendment 1 makes the predicting fit the fold fit on `tr`. But `adjust_test()` treats a zone as seen when it is in `cal` (`fit$coef$zone`), not when it is in `tr`.
  - Take a zone whose calibration presence lies entirely in the held-out sub-sub-drainage. It has all-zero columns in `tr`, so `wet_wb_pooled(tr)` counts it as pooled. Under `"other"` it gets the pooled coefficients; under `"none"` it gets 0.
  - So a test gauge dominated by that zone becomes a decision gauge on which `"other"` applies a level that was never fitted on that zone. Under the literal rule both variants would give it no adjustment, and it would not separate them.
  - This is consistent with how `predict_cv` treats the headline CV, but not with the rule's wording. Decide which is meant before scoring: drop zones with `colSums(tr[z]) == 0` in `adjust_test`, or amend the rule. Count how many decision gauges it affects either way.

- **[severity: fragile]** scripts/wb_fit_accept.R:146-158. It checks only `cv_variant` and `release`. Three gaps:
  - It does not check that both fits ship the same AET. For example, `wb_validate.R` run on 20260717 without `WET_AET_CARRY` and without an argument silently writes a cgiar `fits.rds`, which `wb_output.R` accepts without a winner. The rule fixes AET at cfu, yet the verdict would compare cgiar against cfu, with only an "AET:" line in the report to show it.
  - It does not check that `fits.rds` and `cv_aet-<aet>.rds` come from the same run (`fits$code_md5` against `x$code_md5`). The `gate` comes from `fits.rds` while the MAE comes from the cv file.
  - It does not check that either fit is current with the present code.
  - Fix: add `stopifnot(identical(old$aet[1], new$aet[1]), identical(fits$code_md5, x$code_md5))` per fit, and require the new fit's AET to equal the carried one.

- **[severity: fragile]** scripts/wb_fit_accept.R:163. Each fit's MAE drops its own NA `err` (observed under 10 mm, or no modelled value) separately. If a gauge is NA in one release and not in the other, the two MAEs are taken over different gauges, so the comparison is no longer paired.
  - Rule 8 says "NAs dropped" without saying whether per fit or jointly. Restricting `common` to gauges that are non-NA in both is the paired reading. At minimum, report the n behind each MAE.

- **[severity: minor, report text]** scripts/wb_validate.R:155-176. Amendment 4 says that when the test is uninformative, "the nested choice stays and the caveat stays, softened to name the test". `wb_validate.R` cannot tell that the test ran and was uninformative: no `pooled_variant.txt` is written. So the report keeps the original "mildly optimistic" caveat unchanged and does not name the test. The original rule also says "the test-gauge MAE of the fixed variant is reported beside it" in the headline. That figure appears only in `wb_pooled_test.txt`, not in `wb_validation*.txt`.

## Checked and fine

- No reader is left on the old layout; grep finds no `data/wb/stations.rds`, key-dir `fits.rds`, or untagged report paths in `scripts/`, `data-raw/`, `R/` or `vignettes/`.
- `wb_hydat()` checks the release against the `VERSION` table. Tested on real HYDAT 20260717: the `Date` is text `2026-07-17 08:08:08.000` and reads as `20260717`.
- The test for `wet_hydat_release` passes (13/13 with `NOT_CRAN=true`).
- `score_code_md5` is computed the same way in `wb_cv_lib.R` and `wb_output.R`, since `release` is set before sourcing in both. `wb_pooled_test.R` computes it before writing `pooled_variant.txt` and reads nothing md5-dependent afterwards.
- The test set:
  - Its `years` attribute is reassigned after `[` drops it, and is guarded for NA names.
  - `station_name` survives both `merge(test, test_sn)` and `with_predictors`.
  - `subsubdrainage` is present on both `cal` (from `s$stations`) and `tst`. It matches `wet_cv_folds()`'s blocks (`substr(station_number, 1, 4)`).
- The screens are in place: CHANNEL/OVERFLOW/DIVERSION, `obs >= 10`, and accepted with both fractions at least 0.95.
- The decision logic is correct: dominant zone pooled in `tr`, at least 10 gauges, a tie band of `<= 1.0`, `choose_variant(cal)` on a tie, and a bootstrap with seed 43 drawing 2000 resamples.
- The acceptance verdict direction is right: it ships when `m_new - m_old <= 1.0`.
- `fits.rds` and `cv_aet-*.rds` stay identical where the plan requires it, by inspection of the fixed/nested branches in `predict_cv`.
