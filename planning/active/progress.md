# Progress — Backlog move 10: Swift and Naver creeks under their own chinook windows (#187)

## Session 2026-11-22

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate (soul#928)
- Created branch `187-backlog-move-10-swift-and-naver-creeks-u` off origin/main
- Scaffolded PWF baseline from issue #187 with the drafted phases
- Next: parked 2026-11-22; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#187 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `187-backlog-move-10-swift-and-naver-creeks-u`,
parked 2026-11-23 by `/planning-init wet#187 park review`, branched from origin/main at eaa12d9.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[187-backlog-move-10-swift-and-naver-creeks-u]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-187 187-backlog-move-10-swift-and-naver-creeks-u and cd there
git checkout 187-backlog-move-10-swift-and-naver-creeks-u   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data-raw/life_history_data.R data-raw/station_vignette_data.R inst/vignette-data/life_history_bulk.csv   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- inst/vignette-data/life_history_morr.csv inst/vignette-data/life_history_ufra.csv inst/vignette-data/life_history_cotr.csv   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- scripts/departure_sites.csv scripts/departure_site_lib.R scripts/departure_site.R scripts/departure_site_snow.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data/checks/departure_site_swift_bulk_20260717.txt data/checks/departure_site_naver_bulk_20260717.txt   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data/checks/departure_site_snow_swift_bulk_20260717.txt data/checks/departure_site_snow_naver_bulk_20260717.txt   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data/checks/departure_site_swift_ufra_20260717.txt data/checks/departure_site_naver_cotr_20260717.txt   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- data/checks/departure_site_snow_swift_ufra_20260717.txt data/checks/departure_site_snow_naver_cotr_20260717.txt   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- tests/testthat/test-departure_site_parity.R data-raw/chinook_sites_data.R data-raw/chinook_sites_map.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- vignettes/articles/flow-change-sparse-gauges.Rmd vignettes/articles/flow-change-sparse-gauges.bib data-raw/vignette_bib.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- vignettes/flow-departure-normal.Rmd research/chinook_sites.md CLAUDE.md   # plan files that moved on main since the park
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

## Phase 1, 2026-11-25
- Resumed on m1 in worktree wet-187; merged origin/main (only CLAUDE.md among the plan's files had moved: conventions sync and #142/#144 station text, no chinook-site sentence).
- Owner decisions recorded (task_plan.md, Decisions): adopt now, pinned at knowledge a475dfe7 (knowledge#256 closed; notes-only change to UFRA/COTR rows); move only life_history_data.R's pin; site scripts unchanged.
- `data-raw/life_history_data.R` reads MORR, UFRA, COTR at a475dfe7; `lh_pin_guard()` holds MORR (every column), BULK (all but note) and BULK's chinook rows against c97c4d0 and life_history_bulk.csv; each group's chinook rows asserted with exact sources. `life_history_morr.csv` byte-identical; UFRA and COTR CSVs written (2 rows each).
- `tests/testthat/test-life_history_pin.R`: 16 expectations pass; with the MORR check disabled 2 fail (restored defect).

## Phase 2, 2026-11-25
- Site table: Swift `BULK UFRA`, Naver `BULK COTR` (6a… see git log).
- Pre-run checks passed (cd layers and pcic.series unchanged; 14 and 18 complete April-start migration years at the targets).
- Four runs from frozen copies, 13 min; four new reports; the four BULK reports byte-identical; Maxan parity test 21 pass under NOT_CRAN=true. Results in findings.md, "Phase 2 runs".
- Commit: 0472d3e.

## Phase 3, 2026-11-25
- Bundle rebuilt on m1 (log `data/logs/187/chinook_sites_data_20261125.log`): every element `identical()` to the old after dropping the UFRA/COTR rows, but `sites$windows` (swift, naver), five new `gauges` rows (swift 08KA007 snow; naver 08JE001 extension donor, 08KC001, 08KF001, 08KG001 carried donors; new stations 08JE001 and 08KF001) and `provenance` (commit, date, four new report md5s; the eleven old ones unchanged).
- Map rebuilt through `vm_write()`: bc, targets, places identical; the Fraser extent widened (Hausdorff 63.9 km) to take in 08JE001, so its streams, lakes and gauges changed; the keymap moved to the upper left; the rendered map checked.
- Article: one paragraph on Swift and Naver under their own windows (each number under `stopifnot()`), the limit rewritten, `:158` assertion rewritten, two comments say "every window set"; the other assertions over every window set hold unchanged. Citations checked in Zotero's full text: Bradford and Taylor (2023) p. 131 (PDF p. 3), Candy et al. (2002) p. 22 (PDF p. 23). `.bib` regenerated (three new entries; gq's own citation() now carries a new title and DOI). Body prose 1139 -> 1244, cap 1140 -> 1245.
- Merged origin/main again (PR #204 linked the Maxan article; clean).
- Rendered main and the branch from temp libraries; text diff shows only the new paragraph, the limit and the bundle commit line; no `citation ... not found`.

## Phase 4, 2026-11-25
- `research/chinook_sites.md`: verified line, the windows sentence (`:21`), and a section "Swift and Naver under their own windows (#187)" (windows and sources, estimate caveat, header-source note, change and scores, snow gauges, bundle).
- `CLAUDE.md`: the chinook-sites paragraph names each site's window sets and the separate pin with `lh_pin_guard()`; the shipped route holds under every window set; the article's cap 1,245.
- Follow-up issue drafted in `followup-issue.md`; `gh issue create` refused by the auto-mode classifier ("Sensitive Information Leakage"), left for the owner.
