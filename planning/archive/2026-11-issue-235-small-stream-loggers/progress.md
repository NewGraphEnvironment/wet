# Progress — Backlog move 19: Small-stream logger records into wet (#235)

## Session 2026-11-26

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `235-backlog-move-19-small-stream-logger-reco` off origin/main
- Scaffolded PWF baseline from issue #235 with the drafted phases
- Next: parked 2026-11-26; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#235 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `235-backlog-move-19-small-stream-logger-reco`,
parked 2026-11-26 by `/planning-init wet#235 park review`, branched from origin/main at b959b38.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[235-backlog-move-19-small-stream-logger-reco]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-235 235-backlog-move-19-small-stream-logger-reco and cd there
git checkout 235-backlog-move-19-small-stream-logger-reco   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- planning/active/task_plan.md planning/active/findings.md planning/active/progress.md planning/backlog.md R/wet_temp_daily.R   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- R/wet_temp_gsdd.R R/wet_temp_fill.R R/wet_hakai.R R/wet_bcenv.R R/wet_station_daily.R R/wet_station_snap.R   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- R/wet_logger_daily.R scripts/station_regulation_lib.R scripts/station_regulation_rule.R scripts/station_sources_lib.R   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- scripts/station_regulation.R scripts/station_sources_hakai.R scripts/temp_day_boundary.R scripts/temp_coverage.R   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- scripts/temp_fill_validate.R scripts/temp_baseline.R scripts/temp_loggers.R scripts/temp_logger_thresholds.R   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- data-raw/station_sources_hakai.R data-raw/temperature_vignette_map.R data-raw/temp_loggers_nhg.R   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- inst/extdata/temp_loggers/nhg_15053907.csv inst/extdata/temp_loggers/nhg_15053907_sites.csv   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- inst/extdata/temp_loggers/nhg_15053907_placement.csv inst/extdata/temp_loggers/nhg_6426024.csv   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- inst/extdata/station_sources/regulation_20261028.csv data/checks/temp_loggers_nhg_15053907.txt   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- data/checks/temp_logger_thresholds.txt data/checks/temp_coverage_report.txt tests/testthat/test-wet_temp_daily.R   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- tests/testthat/test-wet_temp_fill.R tests/testthat/test-wet_temp_gsdd.R tests/testthat/test-wet_logger_daily.R   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- tests/testthat/helper-temp-loggers.R tests/testthat/helper-temp-fill.R tests/testthat/helper-bcwatertool.R   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- tests/testthat/helper-bcenv.R tests/testthat/test-wet_bcenv.R research/station_water_temperature.md   # plan files that moved on main since the park
git diff --name-only b959b3864451710c3e6d3428a050159e33b99614 origin/main -- research/station_temperature_fill.md man/wet_temp_daily.Rd CLAUDE.md NEWS.md DESCRIPTION   # plan files that moved on main since the park
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

## Build, 2026-11-27 (resumed from the park)

- Merged origin/main (#187's release; no plan file moved in substance). Members check: `FREE #215`.
- Phase 1: inventory (Zenodo robots.txt read first; both Nechako records read at Zenodo's md5s). eae9ba04
- Owner's decisions 1-5 answered (all recommended), then Amendment 1 to decision 5 after the first threshold run.
- Phase 2: pin and registry, backup to s3. 734a3565
- Phase 3: thresholds registered in their own commit 150807c9; reader and QA fec2cddd; every guard shown red with its rule removed (stuck, deployment, air, hours, routing, valid, ice exemption, fetch flag).
- Phases 4-5: placement and report d78d0b34; research, CLAUDE.md, NEWS e88a6185; issues #251, #252, #253.
- Validation: full suite 4,104 passed, 0 failed, 5 skipped (fwapg-version skips in the snap tests); lint_package against origin/main: 15 new lints, the 6 indentation ones fixed, the rest in classes the baseline carries (test helpers and sourced script helpers seen as undefined); check_pkgdown clean.
