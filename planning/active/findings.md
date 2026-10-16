# Findings — Rescore fit_20260717 under #89's scoring code and rerun the outputs before the next publish (#91)

## Issue context

**If done:** the shipped fit `fit_20260717` is current under the scoring code on main again, so the output scripts, `discharge_publish.R`, both vignette data scripts and `wb_share_snow.R` run. **If never done:** each of those refuses the stale stamps, and nothing can be republished.

## What is owed

Merging #89 (PR #90) changed `scripts/wb_aet_compare.R`, which is in `score_files_for()`. That stales every fit's stamps. The output reruns were already owed after #83 and #85 changed `scripts/`. On the machine with the full province run, in this order:

1. `Rscript scripts/wb_validate.R <v>` for all ten AET variants
2. `Rscript scripts/wb_aet_compare.R`: it should write `aet_winner.txt` = cfu, with all 94 outer folds choosing cfu, as the #89 sandbox found
3. `Rscript scripts/wb_validate.R cfu` (unlinks `output/`)
4. `Rscript scripts/wb_output.R`, then `Rscript scripts/segment_output.R`
5. `discharge_publish.R` BUILD; publish only where parts differ from the live manifest

The shipped values should not change: the AET, pooled variant and gate are all the same. `data/checks/wb_aet_compare_20260717.txt` will be rewritten in substance. Its stage 1 heading and rule text change, and (d) prints fail (nested 32.5 % against cfu's as-shipped 30.7 %, which is post-selection) while cfu still wins (`research/water_balance_method.md`, "The AET incumbent since #89"). Commit the rewritten reports.

Related: #89, #83, #85.


## Errors Encountered

| Error | Resolution |
|-------|------------|

## Plan review (Plan agent, 2026-10-16), verified

- **B1, confirmed.** `data-raw/segment_vignette_data.R:170` requires the tracked segment report to begin `wet commit <live manifest segment_commit>;`. The live manifest names `wet_commit acb820f, segment_commit 1718a3d` (read with `wet_catalog()`), while the tracked report has named `f854c21` since #81, so this script has refused since #81, independent of #89. A rerun of `segment_output.R` names the new HEAD, so it keeps refusing unless the build is republished with the new segment commit. Taken to the user.
- **B2, confirmed.** `segment_output.R:85` calls `routed_commit()`, which stops without `WET_FWAPG_COMMIT`; set `341b078` for the whole Phase 3 chain and the m1 vignette runs.
- G1: `fits.rds` changes exactly `code_md5` and `aet_md5`; each `cv_aet-*.rds` only `code_md5`. G2: assert `fits$code_md5 == aet_winner.txt[2]`, differs from `_pre91`, and `output/` was unlinked, so "identical but md5s" cannot pass on a no-op. G5: `runoff_annual.tif` added to `_pre91`.
- S1: `wb_term_diagnose_20260717.txt` and `wb_gauge_diversion_20260717.txt` print the scoring md5 and are not rerun here; they keep naming `49ab5f38…`, and those scripts refuse until rerun. Out of scope (diagnostics, not the publish chain).
- AC1: both vignette `.rds` embed `built = Sys.Date()` and `wet_commit` (and `monthly_values.rds` the fit md5s), so a rerun always changes bytes.

## Phase 2 result (m4, 2026-10-16 21:20–21:25 UTC)

- All ten `cv_aet-*.rds` identical to `_pre91` in every field but `code_md5` (now `a80b045ab7a74678d4dff01dddf77fcb`).
- The ten `wb_validation_aet-*_20260717.txt` reports are byte-identical (no diff).
- `aet_winner.txt` = cfu, `a80b045a…`. `wb_aet_compare_20260717.txt`: stage-1 heading, rule and disclosure; (d) nested 32.5 against cfu 30.7, fail; folds cfu 94 (was fu 26, cfu 68 under cgiar as incumbent). As-shipped table unchanged.
