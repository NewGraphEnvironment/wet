# Progress — Backlog move 12: Research files around the current state (#189)

## Session 2026-11-27

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `189-backlog-move-12-research-files-around-th` off origin/main
- Scaffolded PWF baseline from issue #189 with the drafted phases
- Next: parked 2026-11-27; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#189 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `189-backlog-move-12-research-files-around-th`,
parked 2026-11-27 by `/planning-init wet#189 park review`, branched from origin/main at 49afd87.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[189-backlog-move-12-research-files-around-th]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-189 189-backlog-move-12-research-files-around-th and cd there
git checkout 189-backlog-move-12-research-files-around-th   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only 49afd870e820ba4a6f218e3f8572133059c80244 origin/main -- research/water_balance_method.md research/discharge_publish.md research/station_flow_departure.md research/chinook_sites.md   # plan files that moved on main since the park
git diff --name-only 49afd870e820ba4a6f218e3f8572133059c80244 origin/main -- research/fwapg_mad_method.md research/README.md research/monthly_error.md research/station_sources.md   # plan files that moved on main since the park
git diff --name-only 49afd870e820ba4a6f218e3f8572133059c80244 origin/main -- research/station_snap.md research/segment_group.md research/pcic_hydrology.md research/pcic_scenarios.md planning/archive/   # plan files that moved on main since the park
git diff --name-only 49afd870e820ba4a6f218e3f8572133059c80244 origin/main -- planning/backlog.md CLAUDE.md vignettes/short-record-flow.Rmd vignettes/segment-discharge.Rmd   # plan files that moved on main since the park
git diff --name-only 49afd870e820ba4a6f218e3f8572133059c80244 origin/main -- vignettes/flow-departure-normal.Rmd vignettes/articles/flow-change-sparse-gauges.Rmd scripts/wb_score_md5.R   # plan files that moved on main since the park
git diff --name-only 49afd870e820ba4a6f218e3f8572133059c80244 origin/main -- scripts/wb_cv_lib.R scripts/wb_gate_rule.R scripts/wb_aet_compare.R scripts/wb_fit_accept.R scripts/discharge_publish.R   # plan files that moved on main since the park
git diff --name-only 49afd870e820ba4a6f218e3f8572133059c80244 origin/main -- scripts/discharge_publish_lib.R scripts/station_departure.R scripts/departure_site.R scripts/departure_site_snow.R   # plan files that moved on main since the park
git diff --name-only 49afd870e820ba4a6f218e3f8572133059c80244 origin/main -- scripts/departure_pcic.R scripts/pcic_coverage.R scripts/mad_parity.R scripts/mad_basin.R scripts/upstream_area_check.R   # plan files that moved on main since the park
git diff --name-only 49afd870e820ba4a6f218e3f8572133059c80244 origin/main -- R/wet_db_load.R R/wet_catalog.R R/wet_station_daily.R R/wet_window_stats.R R/wet_window_extend.R R/wet_departure_carry.R   # plan files that moved on main since the park
git diff --name-only 49afd870e820ba4a6f218e3f8572133059c80244 origin/main -- data-raw/chinook_sites_data.R data-raw/life_history_data.R inst/vignette-data/ tests/testthat/test-life_history_pin.R   # plan files that moved on main since the park
git diff --name-only 49afd870e820ba4a6f218e3f8572133059c80244 origin/main -- data/checks/ data/basin/100_report.txt data/basin/100_run.log   # plan files that moved on main since the park
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
answer (when the last item moves out, delete the heading), and write a fork you meet
yourself under that same heading.
Start Phase 1 and run every phase to the PR (/code-check branch, /planning-archive,
/gh-pr-push). This message is the resume instruction that starts the run-to-PR
mandate; the merge stays with me.
```

## Phase 1, 2026-11-27
- Completed: merged origin/main (clean); members #181, #183, #184 FREE, #206 open with no PR or branch on it; numbers_check.py written and proven; baseline recorded; #206 row added to #189's body
- Commits: this one
- Next: Phase 2
