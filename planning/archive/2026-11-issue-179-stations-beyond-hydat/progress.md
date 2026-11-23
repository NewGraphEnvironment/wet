# Progress — Backlog move 8: Stations beyond HYDAT (#179)

## Session 2026-11-22

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate (soul#928)
- Created branch `179-backlog-move-8-stations-beyond-hydat` off origin/main
- Scaffolded PWF baseline from issue #179 with the drafted phases
- Next: parked 2026-11-22; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#179 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `179-backlog-move-8-stations-beyond-hydat`,
parked 2026-11-22 by `/planning-init wet#179 park review`, branched from origin/main at eaa12d9.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[179-backlog-move-8-stations-beyond-hydat]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-179 179-backlog-move-8-stations-beyond-hydat and cd there
git checkout 179-backlog-move-8-stations-beyond-hydat   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- planning/active/task_plan.md planning/active/findings.md planning/active/progress.md planning/backlog.md   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- R/wet_station_daily.R R/wet_temp_daily.R R/wet_temp_gsdd.R R/wet_window_stats.R R/wet_hydat.R R/wet_pcic_years.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- R/wet_station_select.R R/wet_bcenv.R R/wet_bcenv_daily.R R/wet_station_list.R scripts/station_sources_probe.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- scripts/station_sources_bound.R scripts/station_sources_harvest.R scripts/wb_gauge_diversion.R scripts/station_departure.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- scripts/wb_shape_daily.R scripts/departure_pcic.R scripts/departure_site.R data-raw/station_vignette_data.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data-raw/station_sources_snapshot.R research/station_sources.md data/checks/station_sources_20260717.txt   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data/checks/station_sources_bound_20260717.txt data/checks/station_sources_harvest_20261028.txt   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- inst/extdata/station_sources/bcenv_20261028.csv inst/extdata/station_sources/bcenv_20261028_hydat.csv   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- tests/testthat/test-wet_station_daily.R tests/testthat/test-wet_station_list.R tests/testthat/fixtures/ DESCRIPTION   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- _pkgdown.yml CLAUDE.md NEWS.md   # plan files that moved on main since the park
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

## Session 2026-11-22 (resume, run to PR)

- Resumed from the park; nothing the plan names had moved on main. The owner answered the seven open decisions, each with its recommendation.
- Phase 1 (82af4902): snapshot pinned, manifest tracked, cache seeded, private backup made and checked.
- Phase 2 (c4111983 registration, bc8f6457 reader and failed measurement, 64b2feba re-registration, b6d1ef5b shipped bound): the province-wide bound (2,490.71, 07FD007) missed 08HD0003's impossible days; the owner chose the per-sub-drainage form (decision 8), which passes all four catches and drops 208 days at 8 stations.
- Phase 3 (a08467e2): `"bcenv"` in `wet_station_daily()`, `wet_station_list()`, the registry, `frac_provisional`.
- Phase 4: harvest report (tier (i) reproduces the survey exactly; tier (ii): one station moves, 110 still pass), research revised, #190–#192 filed, #142 and #144 bodies edited.
- Validation: full suite 478 tests, 0 failures; `/code-check branch` five rounds (1: an en dash failing R CMD check's ASCII check; 2: five stand-ins without a check; 3: two in the harvest, one inside round 2's fix; 4: the enumeration incomplete; 5: an unknown grade read as graded, the Mountain-time note wrong), ended by an enumeration of 25 places.
