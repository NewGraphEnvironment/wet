# Progress — Backlog move 9 (#186)

## Session 2026-11-22

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate (soul#928)
- Created branch `186-backlog-move-9-the-segment-readers-retur` off origin/main
- Scaffolded PWF baseline from issue #186 with the drafted phases
- Next: parked 2026-11-22; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#186 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `186-backlog-move-9-the-segment-readers-retur`,
parked 2026-11-22 by `/planning-init wet#186 park review`, branched from origin/main at eaa12d9.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[186-backlog-move-9-the-segment-readers-retur]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-186 186-backlog-move-9-the-segment-readers-retur and cd there
git checkout 186-backlog-move-9-the-segment-readers-retur   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- R/wet_segment_monthly.R R/wet_segment_daily.R R/wet_flow_window.R R/wet_db_load.R scripts/discharge_publish.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- scripts/discharge_publish_lib.R scripts/segment_daily_output.R scripts/segment_output.R scripts/pcic_routed_lib.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- scripts/vignette_data_lib.R scripts/segment_group.R data-raw/monthly_vignette_data.R data-raw/segment_vignette_data.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- vignettes/segment-discharge.Rmd tests/testthat/helper-discharge.R tests/testthat/test-wet_segment_monthly.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- tests/testthat/test-wet_segment_daily.R tests/testthat/test-publish_report_live.R NEWS.md   # plan files that moved on main since the park
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
