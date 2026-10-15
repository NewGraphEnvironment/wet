# Plan review (#81), Plan agent, 2026-10-15

Reviewed the plan against HEAD and the Phase 2 working tree. The findings, with what was done about each:

| ID | Finding | Disposition |
|---|---|---|
| B1 | Three-line carried winner makes the new `wb_validate.R` stop before scoring | Already in the chain (rm after the `_pre81` copy); added to task_plan Phase 3 |
| G1 | Winner stamp moved to `score_code_md5`, which the plan didn't record; a decision file written later stales the winner | Recorded in task_plan and findings; CLAUDE.md states the order |
| G2 | Dropping the #15 assertion removed the only guard that stage 2 runs as #18 registered it; a non-cfu winner would ship on a bare `wb_validate.R` | `wb_aet_compare.R`: no winner file when the winner is not the AET shipped now (`wb_shipped_release`'s fits.rds); report says DECISION TO USER, and flags a stage 1 other than cfu as outside #18's registration |
| G3 | Compare can pick a variant that ships raw under the fixed pooled variant, which `wb_validate.R` refuses | Same rule: such a winner gets no winner file and goes to the user. Stale comment in `wb_validate.R` rewritten |
| G4 | Report can't show the override | Column reads `adjusted*` when the override kept the adjustment, plus a disclosure line that the tolerance and fixed variant were set for the incumbent |
| G5 | Missed doc consumers | research (`water_balance_method.md` lines on carry and the #18 precondition; `discharge_publish.md`, where the AET said CGIAR), `wb_pooled_test.R` comment, memories (Phase 3). NEWS is left to `/gh-pr-merge` |
| G6 | Tag recipe depends on m4's `stations_20251014.rds`, province run `e675918817` and `fit_20251014/`, not only the HYDAT backup | The research paragraph states the dependencies (option b) |
| G7 | Follow-up too narrow: AET switch blocks `wb_fit_accept.R:47`; pooled test needs a winner; manifest hard-codes cfu | Added to wet#83's body |
| O1 | Run `/code-check` before Phase 3, or a fix to a hashed file reruns everything | Chain stopped after the ten scoring runs; code-check runs before the rerun |
| O2 | Compare at the tag unlinks `fit_20251014/aet_winner.txt` first | Happened: my `pkill` killed that run mid-way. Winner restored byte-identical (md5 b5451e9b…) and backed up to `~/wet81/` on m4 |
| O3 | Map of what deletes what | Matches the chain order |
| O4 | m1 copy-back is the reduced form | Phase 3 copy-back: fits.rds, aet_winner.txt, cv_aet-cfu.rds, output/{100,400}.parquet month 0 |
| A1–A4 | Assumptions | A1 disclosed in the report and research; A2/A3 noted |
| AC1 | Phase 1 tests the compare only, not the ten scoring runs | Phase 1 now runs the full recipe at the tag and `git diff --exit-code` on all unsuffixed reports, with fit_20251014 backed up first |
| AC2 | Explicit identity criteria for Phase 3 | `identity81.R` (cv_aet-cfu and fits.rds fields, output parquet); reports diffed after the chain |
| AC3 | Fold path vs `predict_cv` check | Not done: the cv_ann identity against `_pre81` covers `wb_validate.R`'s path |
