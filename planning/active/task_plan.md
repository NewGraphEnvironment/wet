# Task: Rescore fit_20260717 under #89's scoring code and rerun the outputs before the next publish (#91)

**If done:** the shipped fit `fit_20260717` is current under the scoring code on main again, so the output scripts, `discharge_publish.R`, both vignette data scripts and `wb_share_snow.R` run. **If never done:** each of those refuses the stale stamps, and nothing can be republished.

## Context

#89 (PR #90) changed `scripts/wb_aet_compare.R`, which is in `score_files_for()` (`scripts/wb_score_md5.R:14`), so every stamp on the shipped fit `fit_20260717` (m4 `data/wb/e675918817/fit_20260717/`, winner `cfu` stamped `49ab5f38…`) is stale. `wb_output.R`, `segment_output.R`, `pcic_routed_compare.R`, `discharge_publish.R`, `wb_share_snow.R` and both vignette data scripts refuse it. Separately, #83 and #85 changed `scripts/discharge_publish.R`, so the segment table's code guard (`discharge_publish.R:178`) already required `wb_output.R` + `segment_output.R` reruns. No code changes: this is an operational rerun on m4, with the rewritten reports committed. Values should not change (same AET, pooled variant `none`, gate override); only stamps, plus the compare report's stage 1 heading/rule text and (d) printing fail (nested 32.5 % vs 30.7 %) while cfu still wins.

Template: #81 Phase 3 (`planning/archive/2026-10-issue-81-retire-fit-20251014-gate/task_plan.md`), which ran the same chain and matched the live build acb820f on 67/67 parts.

Facts from exploration:
- m4's main checkout is on the old #57 branch with an uncommitted report edit: leave it alone, work from a fresh worktree (memory `m4_discharge_publish_state`).
- `segment_output.R:51`, `pcic_routed_compare.R:27` and `discharge_publish.R:54` refuse uncommitted `R/`, `scripts/`, `data/checks/`, so reports are committed **in the m4 worktree** between steps.
- Chain scripts read gitignored `data/{wb,pcic,cgiar,climr,dem,landcover,mod16,snow,terraclimate}` (and `data/hydz`); `data/basin/100_report.txt`, read by `wb_output.R:116`, is tracked, so it comes with the worktree.
- `pcic_routed_compare.R` needs `WET_FWAPG_COMMIT=341b078` (the tracked report's).
- The vignette guard (`scripts/vignette_data_lib.R:62`) needs the publish report's "parts identical to the published build acb820f: 67 of 67" line, so no upload is needed when every part matches.

## Phase 1: Set up on m4
- [x] Push the branch; on m4, `git worktree add ~/Projects/repo/wet-91 <branch>`; symlink `data/{wb,pcic,cgiar,climr,dem,landcover,mod16,snow,terraclimate,hydz}` to the main checkout's
- [x] Set aside identity copies in `data/wb/e675918817/_pre91/fit_20260717/` (59 files, md5s in `_pre91/MD5SUMS`) (fits.rds, aet_winner.txt, cv_aet-*.rds, output/, segment/), with md5s; `wb_key_dir()` does not look there
- [x] Logs under `wet-91/data/logs/91/`, every run under `caffeinate -i` with `WET_HYDAT_RELEASE=20260717`, one backgrounded chain per phase with a DONE marker cleared at launch

## Phase 2: Rescore and re-decide
- [x] `wb_validate.R <v>` for cgiar lc tc fu cfu fu15 fu20 fu35 mod16 cmod16, then `wb_aet_compare.R`
- [x] Check: `aet_winner.txt` = cfu, stamped with the new `score_code_md5`; all 94 outer folds chose cfu; (d) fails at 32.5 % vs 30.7 %. **If the winner is not cfu, or the report says DECISION TO USER: stop, commit the reports, and bring it to the user.** Nothing ships.
- [x] Commit `data/checks/wb_validation_aet-*_20260717.txt` and `wb_aet_compare_20260717.txt`

## Phase 3: Ship the fit and rerun the outputs

`WET_FWAPG_COMMIT=341b078` for the whole chain (review B2: `segment_output.R` reads it too); pcic ran before segment, as in #81. Reports committed on m4 at 9d1d190, e280f5d, 71af15a, 382eabe.

- [x] `wb_validate.R cfu`: `cv_ann`, `cv_share` identical to `_pre91`'s, `fits.rds` identical in every field but the md5s; else stop and report. Commit its report.
- [x] `wb_share_snow.R`; `wb_output.R` (output parquet identical to `_pre91`'s); commit reports
- [x] `segment_output.R` (segment parts identical to `_pre91`'s); commit its report
- [x] `WET_FWAPG_COMMIT=341b078 pcic_routed_compare.R`; commit its report
- [x] `discharge_publish.R` BUILD only; expect 67/67 parts identical to live acb820f, so no upload. Commit the report. **If any part differs: stop and bring the differing parts to the user before any `WET_PUBLISH=1`.**

## Phase 4: Bring m1 current and record
- [ ] Copy the reduced bundle to m1 (fits.rds, aet_winner.txt, cv_aet-cfu.rds; output/ only if changed)
- [ ] On m1, run `data-raw/segment_vignette_data.R` and `data-raw/monthly_vignette_data.R` as the check that they now run; commit their `.rds` only if the bytes change, and say which
- [ ] `research/water_balance_method.md` "The AET incumbent since #89": check the sandbox numbers against the real report; revise the section if any differ, and note it ran on the shipped fit
- [ ] On m4: move `wet-91/data/logs/91/` into the main checkout's `data/logs/91/` (beside `89/`), then remove the worktree; `_pre91/` stays until merge, then deleted
- [ ] Update memories `m4_discharge_publish_state` and `wb_data_reduced_bundle_m1` (new scoring md5, nothing owed)
- [ ] Edit #91's body with the outcome

## Validation
- [ ] Tests pass
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Verification
Identity checks against `_pre91` at each step (cmp / `identical()` on the R objects); the publish report's byte-identical count against the live manifest; the vignette data scripts running on m1 is the end-to-end check that every guard accepts the new stamps.
