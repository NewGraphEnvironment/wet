# Progress — Backlog move 11: Small-basin error and the zone adjustment (#188)

## Session 2026-11-23

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `188-backlog-move-11-small-basin-error-and-th` off origin/main
- Scaffolded PWF baseline from issue #188 with the drafted phases
- Next: parked 2026-11-23; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#188 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `188-backlog-move-11-small-basin-error-and-th`,
parked 2026-11-23 by `/planning-init wet#188 park review`, branched from origin/main at 97f0759.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[188-backlog-move-11-small-basin-error-and-th]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-188 188-backlog-move-11-small-basin-error-and-th and cd there
git checkout 188-backlog-move-11-small-basin-error-and-th   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only 97f0759922c01427f98deebb1756f711caf3105a origin/main -- research/monthly_error.md research/README.md research/wally.md research/water_balance_method.md CLAUDE.md   # plan files that moved on main since the park
git diff --name-only 97f0759922c01427f98deebb1756f711caf3105a origin/main -- data/checks/gauge_monthly_compare_20260717.txt data/checks/wb_validation_20260717.txt   # plan files that moved on main since the park
git diff --name-only 97f0759922c01427f98deebb1756f711caf3105a origin/main -- data/checks/wally_compare_20260717.txt data/checks/wb_small_basin_20260717.txt scripts/wally_compare.R   # plan files that moved on main since the park
git diff --name-only 97f0759922c01427f98deebb1756f711caf3105a origin/main -- scripts/wally_zone_scores.csv scripts/wb_small_basin.R scripts/wb_small_basin_rule.R   # plan files that moved on main since the park
git diff --name-only 97f0759922c01427f98deebb1756f711caf3105a origin/main -- tests/testthat/test-wb_small_basin_rule.R tests/testthat/test-wb_gate_rule.R scripts/wb_cv_lib.R scripts/wb_fit_lib.R   # plan files that moved on main since the park
git diff --name-only 97f0759922c01427f98deebb1756f711caf3105a origin/main -- scripts/wb_gate_rule.R scripts/wb_score_md5.R scripts/wb_term_diagnose.R scripts/wb_province.R   # plan files that moved on main since the park
git diff --name-only 97f0759922c01427f98deebb1756f711caf3105a origin/main -- scripts/gauge_monthly_compare.R scripts/wb_validate.R scripts/wb_aet_compare.R R/wet_station_select.R R/wet_wb_fit.R   # plan files that moved on main since the park
git diff --name-only 97f0759922c01427f98deebb1756f711caf3105a origin/main -- R/wet_wb_adjust.R R/wet_share_fit.R R/wet_share_predict.R R/wet_donor_mean.R R/wet_flow_validate.R R/wet_cv_folds.R   # plan files that moved on main since the park
git diff --name-only 97f0759922c01427f98deebb1756f711caf3105a origin/main -- R/wet_wb_raw.R R/wet_mm_to_m3s.R inst/vignette-data/monthly_values.rds   # plan files that moved on main since the park
git diff --name-only 97f0759922c01427f98deebb1756f711caf3105a origin/main -- planning/archive/2026-10-issue-45-dry-interior-term/findings.md planning/backlog.md   # plan files that moved on main since the park
git merge origin/main   # a conflict: main moved meanwhile; resolve it, commit, and go on

Then read planning/active/task_plan.md, findings.md, progress.md and review-plan.md if present.
The gate decisions, the measurements and the Plan-agent review are already folded in:
do not re-plan and do not re-ask them.
The Plan review ran before the park: do not run it again at this resume. This replaces
the review planning.md item 3 runs beside Phase 1. Check only what moved: each file a
git diff line above printed changed on origin/main since the park, so re-read it against
the phase that edits it and correct the plan where the code moved.
Nothing printed means the plan stands.
One exception: anything task_plan.md lists under its "## Open decisions" heading is not
settled. Ask me each before the phase that needs it, move it to the decisions once I
answer, and write a fork you meet yourself under that same heading.
Start Phase 1 and run every phase to the PR (/code-check branch, /planning-archive,
/gh-pr-push). This message is the resume instruction that starts the run-to-PR
mandate; the merge stays with me.
```

## Phase 0, 2026-11-23 (build session)

- Resumed at about 14:20 UTC (this machine's clock read 7 hours early until about 14:25 UTC, so `date -u` printed 07:20 and commits ef2e88e and 8864113 carry times 7 hours early); merged origin/main (ef2e88e); of the plan's files only `CLAUDE.md` (#142's paragraph) and `planning/backlog.md` (moves 8, 10) moved, neither touching a phase, so the plan stands.
- `data/wb`, `data/wb_term`, `data/hydz`, `data/wally` symlinked to the main checkout's; `data/wally/raw/` and `data/logs/188/` created there. Fit key `768876badf`, `fit_20260717`. `git status --porcelain` empty.

## Phase 1, 2026-11-23

- `research/monthly_error.md` arranged by subject: by region and season, by basin size, routed PCIC's seasonal shape, the Fraser benchmark; "The answer" first; issue numbers moved from headings to statements, and one sentence says they name the report's sections.
- Guard: with issue numbers and commit shas stripped, the body's number multiset is identical before and after (132 distinct values; none added, none dropped). `grep -c '^## #[0-9]'` is 0.
- Words: `wc -w` 1,886 → 1,941; soul's `research_check.sh` 1,727 prose words, 3 issue-headed sections (FLAG) → 1,782, 0 (OK). The rise is the tags on each statement and the pointer sentence. The README row names no old section, so it is unchanged.

## Phase 2, 2026-11-23

- `bcgov/WALLY` pinned at 9de322b; five files fetched into the main checkout's `data/wally/raw/<sha>/` (log `data/logs/188/wally_fetch.tsv`). The folder stores no k-fold output (`models/output/` is not committed), so WALLY's scores come from the PDF's Table 1 (p. 62), transcribed into `scripts/wally_zone_scores.csv`: digits checked by machine against the text layer (28 rows, 8 numbers each, no difference), columns from the page image, held to the table's Count and Average rows in the script.
- WALLY's MAR scores are in-sample (R² over training and test stations, p. 23); no held-out per-zone error exists in the folder or the report, which the report and `research/wally.md` say.
- Predictor list (Phase 3's input): precipitation in 16 of 27 zone models, slope 15, glacier 14, PET 13, median elevation 12, solar exposure 8, drainage area 2.
- `data/checks/wally_compare_20260717.txt`: two runs byte-identical (logs `data/logs/188/wally_compare_run{1,2}.log`). `research/wally.md` and its README row written.

## Phase 3, 2026-11-23

- Traits buildable: `p_yr`, `pet_yr`, `t_yr`, `elev`, `swe_max` in the upstream files; fwapg answers (connect timeout 10 s) and holds 13,648 FWA glacier polygons (no ltree codes on them, so glacier cover is intersected with the fundamental watersheds, which carry codes). Slope and solar exposure untested: they need the DEM, which the build machine lacks; slope is in 15 of WALLY's 27 zone models, solar exposure in 8; both carried to the follow-up.
- Open decision 1 asked and answered (the owner: thresholds as drafted), written into #188's body under "## Decisions".
- Rule registered alone at 9f5a0da: header of `scripts/wb_small_basin.R`, `scripts/wb_small_basin_rule.R`, `tests/testthat/test-wb_small_basin_rule.R` (41 expectations; four boundary mutations each turn the suite red).

## Phase 4, 2026-11-23

- Body committed at ae9d606 before the tracked runs. It reproduced the registered medians (small raw +1.9, adjusted +14.3; larger −15.1, −6.7) and the fit's scoring md5 (df3280b5) before any check.
- Verdicts: A concentrated (zone split 1 of 3 readable classes at +10; elevation and aridity 3 of 3); B undecided (full model: small median +2.7 %, interval −8.8 to +15.6 %, small MAE 40.4 → 33.7, larger +0.2; area-only +3.8 %, −5.6 to +19.1 %, 40.4 → 34.9, +0.6); C compensating on 48 PCIC-covered small basins (raw +14.8 %, adjusted +27.7 % there), so the raw contrast is unresolved. The copied `verdict()` reproduced #45's 21 stored zone verdicts.
- Held-out proof: `WET_SB_INSAMPLE=1` gives different predictions and a lower mean absolute log residual (0.23117 against 0.24369). Two runs byte-identical. Logs `data/logs/188/wb_small_basin_{dev1,run1,run2,insample}.log`. Glacier intersections sum to the table's 28,847 km².
- Follow-up filed as #199 (blending, a trait regression via a check B rerun with slope and solar exposure). `research/monthly_error.md` (basin-size statements, an answer bullet, header), `research/water_balance_method.md` (zone steps, follow-ups) and `research/README.md` revised.

## Phase 5 and validation, 2026-11-23

- Issue bodies edited: #176 (items ticked with verdicts), #178 (items 1 and 2 ticked, item 3 open, item 4 pointing at #199), #44 (scored in #199), #188 ("What this move carried", and the owner's decision under "Decisions"). Follow-up #199 filed. CLAUDE.md entries for both scripts. No file `scripts/wb_score_md5.R` hashes changed (`git diff --stat origin/main...HEAD` over them prints nothing), and the diagnosis held the fit's scoring md5 equal at each run.
- `devtools::test()`: 3,284 passed, 0 failed, 0 errors, 5 skipped (fwapg#41 snap tests), before and after the review fixes (`data/logs/188/devtools_test{,_final}.log`).
- `/code-check branch`: five rounds, ended by enumeration (`review-verdict.md`). R1: #45's cache checked by release only; two function outcomes the header did not name (amendment 1); a zone-class count. R2, inside R1's fix: the cache guard held one column; table order by locale; an ambiguous bullet subject. R3: the copied verdict() untied to #45's script; two prose scopes. R4, inside R3's fix: git dates as a proxy for "made by the current script"; constants not compared. Round 4's fix replaced the approach: check C evaluates #45's constants, derivations, ECCC filter and verdict() from its script by parse() and holds the cache to the fit and to #45's content-keyed caches (amendment 3). R5 enumerated every value check C reads by parsing (54 places) and found the row set untied, fixed and proven. Mutation probes in scratch worktrees refused 7 of 7 corrupted caches or script edits and passed the real cache. Both reports byte-identical through every fix except wording lines and one fixed table order.
