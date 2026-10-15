# Code-check round 1 (#77), branch diff dcd15b0..f36eefd

## How it was checked

- Read the diff, the changed files in full where they changed, `scripts/wb_cv_lib.R`, `scripts/wb_validate.R` (cv / share_spec / saveRDS), `scripts/pcic_routed_lib.R::shipped_heldout()`, `scripts/vignette_data_lib.R`, `scripts/wb_score_md5.R`.
- Purled `vignettes/monthly-flow.Rmd` and `vignettes/segment-discharge.Rmd` into the scratchpad, pointed `vd()` at the repo's `inst/vignette-data/` and `load_all()`ed the source tree (repo not edited). Both ran to the end, so every `stopifnot` holds on the committed data.
- Printed the numbers behind each rewritten sentence (below) and checked the prose against them.
- Diffed the old (dcd15b0) and new `.rds` bundles. `segment_values.rds` / `segment_map.rds` differ only in provenance (commits, province run, part md5s/bytes). `monthly_values.rds` differs in `wb_mm`, the Bulkley `q_m3s`/`runoff_mm` and provenance, as expected.

Numbers on the committed data:
- Quick 08EE004, balance against observed: Jan 45.4/37.6, Feb 49.9/31.0, Mar 47.6/31.3, Apr 85.7/93.4. "High January to March" is right, and April really is below now.
- Buck 08EE013: May–June balance 9.36 against 16.37 observed (57 %), so it is above half. The balance's June peak of 10.34 is under half of the May 22.02. The balance is above the gauge Jul–Mar.
- Balance median error by month: +0.1 +4.6 +3.4 +10.7 +6.8 −2.2 −3.5 +2.7 +0.1 −2.4 −1.4 +1.8. So it is "high April–May (+7 % to +11 %), within ±5 % otherwise". Feb's +4.6 prints as "+5%" in the table, which is still within the band.
- Gauges routed does not reach (25, 19 of them in area 10): Jan −16 %, Feb −62 %, Mar −75 %.
- Freshet: 243 gauges, 65 % below, median −13 %. Within-band max 44 %. `r_closer` = 1 2 4 5 6 7 8 9 10 12.
- Upload date: the publish ran 03:16 UTC on 2026-10-15, so research's "uploaded 2026-10-15" is the correct UTC date.

Data-script guards. `$` partial matching fails toward stop: an absent `cv_share` matches `cv_shares`, a list whose `dim()` is NULL, so the check stops. `identical(dim(...), c(nrow(cal), 12L))` compares integers on both sides. Both `obs_share` matrices are `unname()`d. `shipped_heldout()` already pins `cv$code_md5 == score_code_md5`, which covers `wet_flow_validate.R`, `wet_share_*`, `wb_cv_lib.R`, `wb_validate.R` and the stations file. The re-score therefore largely restates the stored `cv_v`, but it cannot pass wrongly. Nothing after the removed `cal$raw <-` line reads `cal$raw`. The data were built at 5ad20df, after the script's last change (0b84766).

## Findings

- **[fragile] vignettes/monthly-flow.Rmd:572-575 with data-raw/monthly_vignette_data.R:62-66, 282-304.** The new sentence says the shares use "two snow terms from ERA5-Land … (`wet_share_fit()`, #16)" and that "the snow terms reduced the bias". It is the only rewritten claim that no `stopifnot` holds.
  - The data script checks that the stored months are under the fit's *shipped* spec (`identical(cvr$share_spec, fits$share_spec)` and `cv_share == cv_shares[[spec]]`). It never checks that the spec is `"snow"`.
  - It does not put `share_spec` in `provenance`, so the vignette cannot check it either.
  - So a fit that shipped `"base"` (#16's rule can ship either) passes every guard, and the article then describes snow predictors the data do not have.
  - Fix: add `share_spec = fits$share_spec` to `provenance`, and `stopifnot(identical(prov$share_spec, "snow"))` in the vignette beside the sentence.

- **[fragile, already on the plan] research/discharge_publish.md:5.** It still says the live build is wet 7c62b9e and that the tracked report `data/checks/discharge_publish_20260717.txt` "is the value-checked rebuild at wet 032242f, whose 67 parts are byte-identical to the 7c62b9e upload".
  - This branch rewrote that report (eb17bca, 67 of 67 identical to acb820f), so the sentence now contradicts the tracked file it cites.
  - It is the unchecked task at task_plan.md:37. It needs doing before the PR, not after.

Nothing else. Each new or changed `stopifnot` holds the sentence beside it:
- Quick 1:3.
- Buck freshet above half, and peak under half.
- `wb_spring` / `wb_rest` against "high Apr–May, within ±5 % otherwise".
- `un_winter[1] < 0` and Feb–Mar `< -50` against "−16 % in January, −62 % to −75 % in February–March".

The removed claims (Jan–Apr at Quick, "under half the gauge's" freshet, Jan–May high, the #16/#68 gaps) are gone from the prose as well as from the guards. CLAUDE.md's gaps list matches the vignette's "What's next".

/Users/airvine/Projects/repo/wet/planning/active/review-round1.md
