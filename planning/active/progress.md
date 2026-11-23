# Progress — Backlog move 13: Second sources for the provincial stations (#195)

## Session 2026-11-23

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate (soul#928)
- Created branch `195-backlog-move-13-second-sources-for-the-p` off origin/main
- Scaffolded PWF baseline from issue #195 with the drafted phases
- Next: parked 2026-11-23; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#195 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `195-backlog-move-13-second-sources-for-the-p`,
parked 2026-11-23 by `/planning-init wet#195 park review`, branched from origin/main at 8b1bda6.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[195-backlog-move-13-second-sources-for-the-p]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-195 195-backlog-move-13-second-sources-for-the-p and cd there
git checkout 195-backlog-move-13-second-sources-for-the-p   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only 8b1bda65c05dfe68fc55f43ea208dfddab01cee2 origin/main -- planning/backlog.md R/wet_bcwatertool.R R/wet_station_daily.R R/wet_station_list.R R/wet_bcenv.R R/wet_bcenv_daily.R   # plan files that moved on main since the park
git diff --name-only 8b1bda65c05dfe68fc55f43ea208dfddab01cee2 origin/main -- data-raw/station_sources_bcwatertool.R data-raw/station_sources_snapshot.R inst/extdata/station_sources/   # plan files that moved on main since the park
git diff --name-only 8b1bda65c05dfe68fc55f43ea208dfddab01cee2 origin/main -- scripts/station_sources_harvest.R scripts/station_sources_lib.R scripts/station_sources_probe.R   # plan files that moved on main since the park
git diff --name-only 8b1bda65c05dfe68fc55f43ea208dfddab01cee2 origin/main -- data/checks/station_sources_20260717.txt data/checks/station_sources_harvest_20261028.txt research/station_sources.md   # plan files that moved on main since the park
git diff --name-only 8b1bda65c05dfe68fc55f43ea208dfddab01cee2 origin/main -- tests/testthat/test-wet_bcwatertool.R tests/testthat/helper-bcwatertool.R tests/testthat/test-wet_bcenv.R   # plan files that moved on main since the park
git diff --name-only 8b1bda65c05dfe68fc55f43ea208dfddab01cee2 origin/main -- tests/testthat/test-wet_station_daily.R tests/testthat/test-wet_station_list.R CLAUDE.md NEWS.md _pkgdown.yml   # plan files that moved on main since the park
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

## Phase 1, 2026-11-23

- Resumed from the park; main merged in (2771a11). Asked the four open decisions: the owner chose 1(b) chain earlier days, 2(a) per sub-drainage bound, 3 not read, 4 all 391 cached and backed up with the fetch process documented (21d81fa; #195's body, #190 and #192 split with their owner questions).
- Registered the Tool's bound before any code applied it (21d81fa).
- Reader, chain, pin, registry and tests (1ac68fc); the pin and backup ran on the survey machine with `WET_BACKUP=1`: 392 files, each held to its size and ETag; registry byte-identical on rerun.
- Harvest's Tool tier (d5ac974): the survey reproduced; 149 days dropped by the bound; report byte-identical on rerun.
- Research and CLAUDE.md (e98cea7); lint (2c121b5).
- `/code-check branch`: round 1 (6378c12) cut the chain at the provincial record's first hour, not its first complete day, so Tofino's four listings, the same gauges, add nothing; round 2 (9e50a1b) named the provincial snapshot in the Tool registry; round 3 (1b73c3f) keyed it on the provincial days and refused a station-day given twice; enumeration (666f509, 2e88099) held every registry column to its source.
- Full suite 3,397 passed, 0 failed, 5 fwapg skips; `check_pkgdown()` clean.
