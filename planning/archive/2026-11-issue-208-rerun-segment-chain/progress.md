# Progress — Backlog move 15: Re-run the segment chain and a publish BUILD after 0.4.40 (#208)

## Session 2026-11-25

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `208-backlog-move-15-re-run-the-segment-chain` off origin/main
- Scaffolded PWF baseline from issue #208 with the drafted phases
- Next: parked 2026-11-25; paste the block under ### Resume into a fresh session on the full-run machine

### Resume

```
Continue wet#208 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `208-backlog-move-15-re-run-the-segment-chain`,
parked 2026-11-25 by `/planning-init wet#208 park review`, branched from origin/main at cbeb348.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[208-backlog-move-15-re-run-the-segment-chain]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-208 208-backlog-move-15-re-run-the-segment-chain and cd there
git checkout 208-backlog-move-15-re-run-the-segment-chain   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- scripts/segment_output.R scripts/segment_daily_output.R scripts/discharge_publish.R scripts/discharge_publish_own.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- scripts/discharge_publish_lib.R scripts/vignette_data_lib.R scripts/wb_fit_lib.R scripts/pcic_routed_lib.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- data/checks/segment_output_20260717.txt data/checks/segment_daily_output_20260717.txt   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- data/checks/discharge_publish_20260717.txt   # plan files that moved on main since the park
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

## Session 2026-11-27 (resume)

- Merged origin/main (f943096d, v0.7.0). Of the plan's files only `scripts/discharge_publish_own.R` moved: #169 added non-inputs. Plan corrected.
- `members_check.sh` batch 17: `FREE #198`. #208's body is unchanged since the plan.
- Phase 1: probes pass; old `segment/` and `segment_daily/` md5s recorded and the directories moved to `_pre208` beside the fit.
- Phase 2: the three runs pass; commits 40e25e56, 2ee50dc4, 08a8c552 (one report each). Run logs in the main checkout's `data/logs/208/`.
- Phase 3: parts identical, so nothing to publish; the live manifest and receipt still name a0318b7 / 0.4.35. No part differed, so no issue is owed for a difference. No `data-raw/` script ran. The `_pre208` set-aside (40 GB) is left for the owner.
- Merged origin/main again (c64f84bf, v0.7.1). It moved none of this plan's three reports, nor `segment_output.R`, `segment_daily_output.R`, `discharge_publish.R`, `discharge_publish_own.R` or `wb_output.R`; it did change other reports, and files under `R/` and `scripts/` that the BUILD's code guards watch (findings.md). Next: code check, archive, PR.
- Code check round 2: the BUILD never reads a live part, so all 760 live objects were verified after it (findings.md); `research/discharge_publish.md` revised, since the tracked report is now a BUILD's, not a PUBLISH's.
- Code check round 3: three wording fixes, one of them a sentence already stale on `main`; claims enumerated in `review-enumeration.md`.
