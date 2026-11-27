# Progress — Backlog move 22: What we can bring, written down, and the baseline read against Bayesian practice (#238)

## Session 2026-11-26

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `238-backlog-move-22-what-we-can-bring-writte` off origin/main
- Scaffolded PWF baseline from issue #238 with the drafted phases
- Next: parked 2026-11-26; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#238 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `238-backlog-move-22-what-we-can-bring-writte`,
parked 2026-11-26 by `/planning-init wet#238 park review`, branched from origin/main at da85a4c.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[238-backlog-move-22-what-we-can-bring-writte]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-238 238-backlog-move-22-what-we-can-bring-writte and cd there
git checkout 238-backlog-move-22-what-we-can-bring-writte   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- planning/active/task_plan.md research/temperature_bayesian_alignment.md research/temperature_network_model.md   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- research/README.md research/station_temperature_fill.md research/station_water_temperature.md   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- scripts/temperature_bayesian_alignment_check.R R/wet_temp_fill.R R/wet_temp_gsdd.R R/wet_donor_mean.R R/wet_cv_folds.R   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- scripts/wb_cv_lib.R scripts/temp_fill_validate.R scripts/temp_fill_parity.R scripts/temp_baseline.R   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- scripts/temp_baseline_lib.R scripts/temp_baseline_rule.R scripts/temp_baseline_traits.R scripts/temp_baseline_recover.R   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- scripts/wb_score_md5.R data/checks/temp_baseline.txt data/checks/temp_baseline_recover.txt   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- data/checks/temp_baseline_frame.txt data/checks/temp_fill_validate.txt CLAUDE.md planning/backlog.md   # plan files that moved on main since the park
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

- Resumed in worktree wet-238; merged origin/main (only CLAUDE.md and planning/backlog.md had moved, neither changing the plan). The owner answered the three open decisions (outlets: options listed, move 23 settles; traits per segment: an issue; outside reader: after the PR), moved into the plan's decisions and #238's body.
- Members re-check: FREE #217, FREE #218. Preflight: pdftotext, both PDFs, the `statistics` store (from knowledge's `data/rag`).
- Wrote `research/temperature_bayesian_alignment.md` (20 quotes, 64 choices, the brief) and `scripts/temperature_bayesian_alignment_check.R`; PASS, log `data/checks/temperature_bayesian_alignment_20261127.txt`; mutation table in findings; README row and CLAUDE.md line.
- Next: Phase 2, #217's file.
