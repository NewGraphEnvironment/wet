# Progress — Backlog move 27: The runoff products no report covers yet (#243)

## Session 2026-11-26

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `243-backlog-move-27-the-runoff-products-no-r` off origin/main
- Scaffolded PWF baseline from issue #243 with the drafted phases
- Next: parked 2026-11-26; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#243 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `243-backlog-move-27-the-runoff-products-no-r`,
parked 2026-11-26 by `/planning-init wet#243 park review`, branched from origin/main at da85a4c.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[243-backlog-move-27-the-runoff-products-no-r]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-243 243-backlog-move-27-the-runoff-products-no-r and cd there
git checkout 243-backlog-move-27-the-runoff-products-no-r   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- planning/backlog.md scripts/wb_cv_lib.R scripts/wb_fit_lib.R scripts/wb_province.R scripts/wb_term_diagnose.R   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- scripts/wally_compare.R scripts/gauge_monthly_compare.R scripts/departure_donors.R scripts/departure_donors_rule.R   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- scripts/wb_gauge_diversion.R scripts/pcic_coverage.R scripts/runoff_products_rule.R scripts/runoff_products_compare.R   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- tests/testthat/test-departure_donors_rule.R tests/testthat/test-runoff_products_rule.R R/wet_terraclimate_aet.R   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- R/wet_ws_sample.R R/wet_ws_fetch.R R/wet_upstream_means.R R/wet_bcwatertool.R inst/vignette-data/monthly_values.rds   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- research/runoff_prior_art.md research/runoff_products.md research/README.md research/pcic_scenarios.md   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- research/water_balance_method.md CLAUDE.md   # plan files that moved on main since the park
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

## Session 2026-11-27 (resume, m1, worktree wet-243)

- Merged origin/main (only `CLAUDE.md` and `planning/backlog.md` had moved; neither touches a phase). Members check `FREE #225`.
- The owner answered the three open decisions (all recommended); written into #243's body. Filed #244 (GEOGLOWS v2) and #245 (the BC Water Tool's estimates); #225's body rewritten.
- Phase 1: the rule committed alone at a5e867c; its test at db83be6 (34 expectations; four planted defects each turn it red).
- Phase 2: `scripts/runoff_products_compare.R` at 487dc7c. First run's isoline sampling ran 15–45 min a group (terra's ellipsoidal path on a projected CRS); sampled under a `"local"` label, the whole run took about 15 minutes with 6 workers, then a minute from cache.
- Phase 3: report at 7ecf867, two runs byte-identical; `research/runoff_products.md`, cross-references and the CLAUDE.md bullet at 57dbdb9.
- Validation: full suite 4,038 passed, 0 failed; `/code-check branch` round 1 four fragile findings fixed (096ac4b, report rebuilt and byte-identical again).
- Run logs: `<main checkout>/data/logs/243/` (runs 1–6 and the fetch log); caches `<main checkout>/data/runoff_products/`.
