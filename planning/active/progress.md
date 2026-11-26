# Progress — Backlog move 17: Provincial station records, current copy and Hakai's early years (#210)

## Session 2026-11-25

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `210-backlog-move-17-provincial-station-recor` off origin/main
- Scaffolded PWF baseline from issue #210 with the drafted phases
- Next: parked 2026-11-25; paste the block under ### Resume into a fresh session

## Phase 1, 2026-11-25 (#190)
- Resumed; main moved only CLAUDE.md (a convention heading) and a temperature research file, so the plan stands. The owner answered the six open decisions (all as recommended; the disclaimer accepted, publishing unrestricted).
- Registered the portal script's rules and pick, committed before any portal read (a6a029f5); read 10 of 11 stations; the report is byte-identical on a rerun from cache.
- Where the portal logs on the hour, the pinned files equal it from October 2021 to May 2026; January–September 2021 has been revised since at four of five stations; the portal holds months the pin lacks, and off-the-hour spans were not compared (corrected at code-check rounds 3 to 5); the newer pin is filed as #232; #190's body edited.
- Next: Phase 2 (#192, Hakai).

## Phase 2, 2026-11-25 (#192)
- Read the package (GitHub, Git LFS, CC-BY 4.0); downloaded the hourly discharge at commit 8318556d2baf; found the `Z` timestamps are PST hour ends (three checks); registered the rules before counting any day (a7a454fc).
- Refactor commit with no output change (8aa96d36); tests written against a fixture, failing 12 before the pin; `R/wet_hakai.R`, the pin (`data-raw/station_sources_hakai.R`, backed up privately), wiring into `wet_station_daily()`/`wet_station_list()`; the report `data/checks/station_sources_hakai_8318556d2baf.txt` byte-identical on a rerun, registry held to the reader.
- Plan corrected: the registry check covers the registries a call opens (a shipped test forbade opening the Tool registry without `"bcwatertool"`).
- Filed #233 (the other four watersheds); draft ask to Hakai in findings, unsent.
- Next: Phase 3 (#207).

## Phase 3, 2026-11-25 (#207)
- Fetched and merged origin/main (106e6c7a): #211 had landed, touching `R/wet_station_list.R` docs and this research file; conflicts in CLAUDE.md, NEWS.md and the research file resolved by keeping both sides. #181 (still open) consolidates other files, so no shape to follow.
- Rewrote `research/station_sources.md` around the current state: 6,035 prose words before, 2,916 after (research_check OK; total words 7,565 before). The floor was set by the three registrations kept in full (the provincial and Tool bounds, Hakai's), which are their rules' authority; the regulation rule's authority is its script header, so it is summarised. History (the bar's revision, the failed first bound, the Tool section as it stood, the amendments' counts) moved verbatim into the #123, #179, #195 and #196 archive READMEs under "History moved from research/station_sources.md".
- Every cited section name kept; the bound report's heading unchanged; `research/README.md` row rewritten.
- Next: validation (/code-check branch), archive, PR.

### Resume

```
Continue wet#210 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `210-backlog-move-17-provincial-station-recor`,
parked 2026-11-25 by `/planning-init wet#210 park review`, branched from origin/main at cbeb348.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[210-backlog-move-17-provincial-station-recor]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-210 210-backlog-move-17-provincial-station-recor and cd there
git checkout 210-backlog-move-17-provincial-station-recor   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- R/wet_station_daily.R R/wet_station_list.R R/wet_bcwatertool.R R/wet_bcenv_daily.R R/wet_bcenv.R R/wet_hakai.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- data-raw/station_sources_hakai.R data-raw/station_sources_bcwatertool.R scripts/station_sources_portal.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- scripts/station_sources_lib.R scripts/station_regulation.R scripts/station_sources_bound.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- inst/extdata/station_sources/bcenv_20261028_hydat.csv inst/extdata/station_sources/bcwatertool_20261028_hydat.csv   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- inst/extdata/station_sources/regulation_20261028.csv tests/testthat/test-wet_station_daily.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- tests/testthat/test-wet_station_list.R research/station_sources.md research/README.md   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- data/checks/station_sources_20260717.txt data/checks/station_sources_bound_20260717.txt CLAUDE.md NEWS.md   # plan files that moved on main since the park
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
