# Progress — Backlog move 10: Swift and Naver creeks under their own chinook windows (#187)

## Session 2026-11-22

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate (soul#928)
- Created branch `187-backlog-move-10-swift-and-naver-creeks-u` off origin/main
- Scaffolded PWF baseline from issue #187 with the drafted phases
- Next: parked 2026-11-22; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#187 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `187-backlog-move-10-swift-and-naver-creeks-u`,
parked 2026-11-23 by `/planning-init wet#187 park review`, branched from origin/main at eaa12d9.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[187-backlog-move-10-swift-and-naver-creeks-u]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-187 187-backlog-move-10-swift-and-naver-creeks-u and cd there
git checkout 187-backlog-move-10-swift-and-naver-creeks-u   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data-raw/life_history_data.R data-raw/station_vignette_data.R inst/vignette-data/life_history_bulk.csv   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- inst/vignette-data/life_history_morr.csv inst/vignette-data/life_history_ufra.csv inst/vignette-data/life_history_cotr.csv   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- scripts/departure_sites.csv scripts/departure_site_lib.R scripts/departure_site.R scripts/departure_site_snow.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data/checks/departure_site_swift_bulk_20260717.txt data/checks/departure_site_naver_bulk_20260717.txt   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data/checks/departure_site_snow_swift_bulk_20260717.txt data/checks/departure_site_snow_naver_bulk_20260717.txt   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data/checks/departure_site_swift_ufra_20260717.txt data/checks/departure_site_naver_cotr_20260717.txt   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data/checks/departure_site_snow_swift_ufra_20260717.txt data/checks/departure_site_snow_naver_cotr_20260717.txt   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- tests/testthat/test-departure_site_parity.R data-raw/chinook_sites_data.R data-raw/chinook_sites_map.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- vignettes/articles/flow-change-sparse-gauges.Rmd vignettes/articles/flow-change-sparse-gauges.bib data-raw/vignette_bib.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- vignettes/flow-departure-normal.Rmd research/chinook_sites.md CLAUDE.md   # plan files that moved on main since the park
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
