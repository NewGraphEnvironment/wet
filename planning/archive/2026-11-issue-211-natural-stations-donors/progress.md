# Progress — Backlog move 18: Natural non-HYDAT stations as donors (#211)

## Session 2026-11-25

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `211-backlog-move-18-natural-non-hydat-statio` off origin/main
- Scaffolded PWF baseline from issue #211 with the drafted phases
- Next: parked 2026-11-25; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#211 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `211-backlog-move-18-natural-non-hydat-statio`,
parked 2026-11-25 by `/planning-init wet#211 park review`, branched from origin/main at cbeb348.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[211-backlog-move-18-natural-non-hydat-statio]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-211 211-backlog-move-18-natural-non-hydat-statio and cd there
git checkout 211-backlog-move-18-natural-non-hydat-statio   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- tests/testthat/test-departure_donors_rule.R tests/testthat/test-departure_site_rule.R scripts/departure_donors_rule.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- scripts/departure_donors.R scripts/departure_site.R scripts/departure_site_lib.R scripts/departure_sites.csv   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- scripts/station_regulation.R scripts/station_regulation_lib.R R/wet_window_extend.R R/wet_departure_carry.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- R/wet_station_select.R R/wet_station_list.R R/wet_station_daily.R R/wet_window_stats.R R/wet_station_snap.R   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- inst/vignette-data/life_history_bulk.csv inst/extdata/station_sources/regulation_20261028.csv   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- data/checks/departure_donors_20260717_20261028.txt data/checks/departure_site_swift_bulk_20260717.txt   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- data/checks/departure_site_naver_bulk_20260717.txt research/chinook_sites.md research/station_sources.md research/README.md   # plan files that moved on main since the park
git diff --name-only cbeb348930cd4e8b282a3961f1ac2684d62003a0 origin/main -- NEWS.md CLAUDE.md   # plan files that moved on main since the park
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

## Phase 1, 2026-11-25 (resumed)

- Resume checks passed; main moved only by a CLAUDE.md sync (a convention heading), so the plan stood. Merged origin/main.
- `members_check.sh --batch 20`: `FREE #202`.
- Open decisions 1 and 2 were already answered in #211's body (the owner, at the coordinator's plan gate): scope (a), the bar as drafted with the three extra lines reported. Folded into "Decided at the gate"; the heading removed.
- Step 1: rule registered at a7455e45 (`scripts/departure_donors_rule.R`, its tests, the research section), before `scripts/departure_donors.R` existed. 68 expectations pass; removing `dd_baseline_rows()`'s baseline filter turns two tests red (checked on a scratch copy).
- Step 2: `scripts/departure_donors.R` and its report. A first full run scored nothing: the script's station table dropped `regulation`, so `dd_candidate()` saw `NULL`, returned a zero-length vector and every box looked empty (the no-candidate identity held vacuously). Fixed in the script (the column kept; a refusal when `dd_candidate()` is not given its columns or answers the wrong length), not in the registered rule file. The final run started from an empty cache (24 min, `data/logs/211/final_cold.log`); a second from the cache wrote the report byte for byte (`final_warm.log`, `cmp`). In a scratch worktree, a one-character edit to the rule file made the script refuse.
- Result: the donor pool stays HYDAT-only. Median paired RMSE difference +0.0317 leave-one-gauge-out (50 gauges), +0.0147 leak-free (53); every sensitivity would not ship.
- Step 3: the result in `research/chinook_sites.md` (every number grepped in the tracked report), the superseded donor sentences in `research/station_sources.md`, the README row, the help text of `wet_station_list()` and `wet_station_select()`, NEWS under a development heading, and `CLAUDE.md` above the marker. Same-site continuation filed as #227; no selector follow-up, since the rule did not ship.

## Validation, 2026-11-25

- `devtools::test()`: 0 failed, 0 errors, 5 skipped (548 tests; one live-data gap warning in the Buck Creek test). Later commits touched no file under `R/` or `tests/`.
- `pkgdown::check_pkgdown()`: no problems. lintr: the R/ files carry the same 2 lints as on main; the new scripts' object-usage lints are functions sourced from the rule file.
- Nothing shipped moved: no change under `data/checks/departure_site_*`, `inst/vignette-data` or `vignettes`; the R/ diff is roxygen only.
- `/code-check branch`: 4 rounds, ended on an enumeration (`review-verdict.md`). Round 1: four fragile findings (the displacement claim, "median RMSE" wording, on.exit() in cached blocks, a narrow cache key). Round 2: two inside round 1's fixes (the key still missed the script; the rewritten bullet misnamed its years). Round 3 named the mechanism (a claim about a set written from the idea of the set, not counted over it) and found five more (a swallowed failing source, NEWS's "each was given one", the baseline claim measured on one statistic, a cross-reference, two research phrasings); fixing one, my first replacement was wrong again and was measured before commit. Round 4 re-walked both sets: one sentence scoped. Each round with a script change was rerun from an empty cache and again from the cache, byte for byte; only the added report lines differ.
