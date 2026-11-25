# Progress — Backlog move 7: Scenarios and coverage, after the channel-scale pilot (#169)

## Session 2026-11-25

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `169-backlog-move-7-scenarios-and-coverage-af` off origin/main
- Scaffolded PWF baseline from issue #169 with the drafted phases
- Next: parked 2026-11-25; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#169 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `169-backlog-move-7-scenarios-and-coverage-af`,
parked 2026-11-25 by `/planning-init wet#169 park review`, branched from origin/main at cbeb348.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[169-backlog-move-7-scenarios-and-coverage-af]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-169 169-backlog-move-7-scenarios-and-coverage-af and cd there
git checkout 169-backlog-move-7-scenarios-and-coverage-af   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- research/pcic_hydrology.md research/station_sources.md research/README.md research/pcic_channel_scale.md   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- research/pcic_scenarios.md research/pcic_coverage.png research/discharge_publish.md CLAUDE.md NAMESPACE _pkgdown.yml   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- R/wet_pcic_fetch.R R/wet_pcic_annual.R R/wet_runoff_annual.R R/wet_pcic_index.R R/wet_runoff_monthly.R R/wet_pcic_monthly.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- R/wet_upstream_mean.R R/wet_mm_to_m3s.R R/wet_ws_fetch.R R/wet_ws_sample.R man/wet_pcic_fetch.Rd man/wet_runoff_monthly.Rd   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- man/wet_pcic_monthly.Rd tests/testthat/test-wet_pcic_fetch.R tests/testthat/test-wet_pcic_annual.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- tests/testthat/test-wet_runoff_monthly.R tests/testthat/test-wet_pcic_monthly.R scripts/channel_scale_pilot.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- scripts/channel_scale_sites.csv scripts/scenario_basis.R scripts/scenario_basis_lib.R scripts/pcic_coverage.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- scripts/pcic_coverage_map.R scripts/discharge_publish_own.R scripts/wb_term_diagnose.R scripts/vignette_data_lib.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- scripts/vignette_map_lib.R scripts/wb_map.R inst/cartography/wet_coverage.csv inst/vignette-data/monthly_values.rds   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- inst/vignette-data/segment_map.rds vignettes/segment-discharge.Rmd data/checks/channel_scale_pilot_20260717.txt   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- data/checks/scenario_basis_20260717.txt data/checks/pcic_coverage_20260717.txt data/checks/segment_output_20260717.txt   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- data/checks/discharge_publish_20260717.txt data/checks/pcic_routed_compare_20260717.txt   # plan files that moved on main since the park
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

## Phase 1, 2026-11-25
- Resumed on m1 in worktree wet-169; merged origin/main (a CLAUDE.md convention heading only; the plan stands). Owner's decisions read from #169's body and moved into the plan: (a) ask PCIC first, split yes, rule 3 kept.
- Member re-check: FREE #4, #5, #205.
- `research/pcic_hydrology.md` re-read from what robots.txt allows, revised in place, "Access and robots.txt" added; README row. PCIC note drafted for the owner, outside this repository. #205 body edited to what is left; open.
- Next: Phase 2 (readers).

## Phase 2, 2026-11-25
- `wet_runoff_monthly()`, `wet_pcic_monthly()`; `wet_pcic_fetch()` through curl (`wet_http_disk()`, user agent `wet`), 429/503 waits, status and days checks. Each guard restored once and its test went red. `wet_pcic_annual()` on the cached Fraser year 1981, offline, `identical()` to origin/main's. Full suite: FAIL 0, PASS 3562 (one live-data warning, five fwapg-migration skips, all unrelated). Lints: none new.
- Commits: 215b63e

## Phase 3, 2026-11-25
- Rules registered (4ef1af5), coded (9bafb95, 3b6c16c); offline runs: parity holds, rule 4 and the CMIP5 score not run (PCIC asked first); byte-identical on a second run.
- Next: Phase 4 (coverage report and map).
