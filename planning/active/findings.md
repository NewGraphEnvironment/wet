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
