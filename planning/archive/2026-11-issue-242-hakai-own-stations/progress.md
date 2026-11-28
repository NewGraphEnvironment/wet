# Progress — Backlog move 26: A newer provincial pin, Hakai's other watersheds, and a HYDAT gauge continued at its site (#242)

## Session 2026-11-26

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `242-backlog-move-26-a-newer-provincial-pin-h` off origin/main
- Scaffolded PWF baseline from issue #242 with the drafted phases
- Next: parked 2026-11-26; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#242 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `242-backlog-move-26-a-newer-provincial-pin-h`,
parked 2026-11-26 by `/planning-init wet#242 park review`, branched from origin/main at a08f320.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[242-backlog-move-26-a-newer-provincial-pin-h]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-242 242-backlog-move-26-a-newer-provincial-pin-h and cd there
git checkout 242-backlog-move-26-a-newer-provincial-pin-h   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- planning/backlog.md R/wet_bcenv.R R/wet_bcenv_daily.R R/wet_hakai.R R/wet_bcwatertool.R R/wet_station_list.R   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- R/wet_station_daily.R R/wet_station_select.R man/wet_station_list.Rd man/wet_station_daily.Rd   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- data-raw/station_sources_snapshot.R data-raw/station_sources_hakai.R data-raw/station_sources_bcwatertool.R   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- scripts/station_sources_portal.R scripts/station_sources_portal_lib.R scripts/station_sources_lib.R   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- scripts/station_regulation.R scripts/station_regulation_rule.R scripts/station_regulation_lib.R   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- scripts/station_sources_harvest.R scripts/station_sources_hakai.R scripts/station_sources_bound.R   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- scripts/station_hydat_continue.R scripts/departure_donors.R scripts/departure_donors_rule.R research/station_sources.md   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- CLAUDE.md NEWS.md inst/extdata/station_sources/bcenv_20261028.csv inst/extdata/station_sources/bcenv_20261028_hydat.csv   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- inst/extdata/station_sources/bcwatertool_20261028_hydat.csv inst/extdata/station_sources/hakai_8318556d2baf_hydat.csv   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- inst/extdata/station_sources/regulation_20261028.csv data/checks/station_sources_20260717.txt   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- data/checks/station_sources_portal_20261125.txt data/checks/station_regulation_20261028.txt   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- data/checks/station_sources_harvest_20261028.txt data/checks/station_sources_hakai_8318556d2baf.txt   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- data/checks/station_sources_bound_20260717.txt tests/testthat/test-wet_station_list.R   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- tests/testthat/test-wet_station_daily.R tests/testthat/helper-bcenv.R tests/testthat/helper-bcwatertool.R   # plan files that moved on main since the park
git diff --name-only a08f3207a9b996b5634768238e6a4def66fe5a1f origin/main -- tests/testthat/test-wet_bcenv.R tests/testthat/test-wet_bcwatertool.R tests/testthat/test-station_regulation_rule.R   # plan files that moved on main since the park
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

## Phase 1 (rescoped to #233), 2026-11-27
- Resumed in a worktree; merged origin/main (docs only moved). The owner answered open decisions 1-5 as recommended.
- Registered the newer pin's portal bar and Amendment 4 (82aa3f24), pushed before any new file was read.
- The province's 2019-2021 archive was byte-identical to the 20261028 pin's, so the bar fails at four stations; the owner chose no new pin (answer 6). #232's body records it.
- #233: registered the own stations' rules (645abbca); reader, list, registry and regulation code (0fcb7462); regulation rerun and Hakai report (1d526aea): 257 statuses unchanged, the four own stations unknown, each passing the station test.
- Run logs: `data/logs/242/` in the main checkout.
- Commits: 82aa3f24, 488cbae7, 645abbca, 0fcb7462, 1d526aea, and the docs commit.
- Next: Validation; Phase 2 (#227) is a second PR.
