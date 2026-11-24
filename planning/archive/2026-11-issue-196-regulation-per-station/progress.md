# Progress — Backlog move 14: Regulation per non-HYDAT station (#196)

## Session 2026-11-23

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `196-backlog-move-14-regulation-per-non-hydat` off origin/main
- Scaffolded PWF baseline from issue #196 with the drafted phases
- Next: parked 2026-11-23; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#196 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `196-backlog-move-14-regulation-per-non-hydat`,
parked 2026-11-24 by `/planning-init wet#196 park review`, branched from origin/main at 0e56d60.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[196-backlog-move-14-regulation-per-non-hydat]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-196 196-backlog-move-14-regulation-per-non-hydat and cd there
git checkout 196-backlog-move-14-regulation-per-non-hydat   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only 0e56d60ed19c34f8534df5292dfa04c1699f1047 origin/main -- R/wet_station_list.R R/wet_station_select.R R/wet_station_daily.R R/wet_bcwatertool.R R/wet_station_snap.R   # plan files that moved on main since the park
git diff --name-only 0e56d60ed19c34f8534df5292dfa04c1699f1047 origin/main -- R/wet_segment_monthly.R R/wet_window_extend.R scripts/wb_gauge_diversion.R scripts/wb_small_basin_rule.R   # plan files that moved on main since the park
git diff --name-only 0e56d60ed19c34f8534df5292dfa04c1699f1047 origin/main -- scripts/station_sources_lib.R scripts/station_sources_harvest.R scripts/segment_group.R scripts/departure_site.R   # plan files that moved on main since the park
git diff --name-only 0e56d60ed19c34f8534df5292dfa04c1699f1047 origin/main -- scripts/station_regulation_rule.R scripts/station_regulation_lib.R scripts/station_regulation.R   # plan files that moved on main since the park
git diff --name-only 0e56d60ed19c34f8534df5292dfa04c1699f1047 origin/main -- data-raw/station_sources_snapshot.R data-raw/station_sources_bcwatertool.R inst/extdata/station_sources/   # plan files that moved on main since the park
git diff --name-only 0e56d60ed19c34f8534df5292dfa04c1699f1047 origin/main -- research/station_sources.md tests/testthat/test-wet_station_list.R tests/testthat/test-wet_station_daily.R   # plan files that moved on main since the park
git diff --name-only 0e56d60ed19c34f8534df5292dfa04c1699f1047 origin/main -- tests/testthat/test-wet_station_select.R tests/testthat/test-wb_small_basin_rule.R   # plan files that moved on main since the park
git diff --name-only 0e56d60ed19c34f8534df5292dfa04c1699f1047 origin/main -- tests/testthat/test-station_regulation_rule.R CLAUDE.md NEWS.md planning/backlog.md   # plan files that moved on main since the park
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

## Phase 1, 2026-11-24
- Resumed on m1 (worktree wet-196); nothing on main had moved since the park; the four plan-gate decisions were in #196's body
- Read both layers' catalogue records: the licence layer is Access Only and pending archive (its successor not on the public WFS); owner's decision 5, derived values only
- Tool drainage areas checked as km^2; the rule, its closed code sets and tests registered with research's Regulation section
- Commit: 2d93787f (the registering commit)

## Phase 2, 2026-11-24
- First run stopped on #53's shared-POD check (a licence with a rediversion POD): Amendment 1, owner's decision
- Script and lib written; WFS snapshot 20261124; 204 of 257 snapped; rerun from cache byte-identical
- Commits: 0c6d31ff (Amendments 1-2), c74e7382

## Phase 3, 2026-11-24
- Status file and the internal reader `wet_station_regulation()`; docs of `wet_station_list()`, `wet_station_select()`, `wet_station_daily()`; reader guards and script guards each shown firing (planted in a detached worktree)
- Commit: b531469f

## Phase 4, 2026-11-24
- Report, research and CLAUDE.md; donor-pool issue #202 filed; NEWS left to the release step
- /code-check branch: four rounds, ended on an enumeration. Round 1: groundwater in L and S (fixed), licence identifiers in tracked text (removed; the unpushed commits rebuilt), no-volume licences (Amendment 2). Round 2: doc gap, unplaced points, unchecked subtypes. Round 3: the own-reach 1 mm test (Amendment 3, 100 m), unlocated licences, NA codes, power counted over repeats. Round 4: the report's amendment list hand-typed (now derived, with statuses per version)
- Final: 75 natural, 110 regulated, 72 unknown; full suite 3,534 expectations, 0 failed
- Commits: 6c1194e1, a06b54b3, 6c9cb1e5 (Amendment 3), 71bea115, afb7900c
