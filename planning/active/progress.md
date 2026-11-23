# Progress — Backlog move 11: Small-basin error and the zone adjustment (#188)

## Session 2026-11-23

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate (soul#928)
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
