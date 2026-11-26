# Plan review for #210 (move 17: #190, #192, #207), 2026-11-25

Blockers raised: 2
Owner forks: 3

Plan agent, run on the baseline draft of `task_plan.md`; each finding probed before it was folded or declined.

## Blocker

1. **Phase 1 compared days defined differently.** The survey's 0.1 % comparison is on 24-hour UTC days (`data/checks/station_sources_20260717.txt`, "the same station's 24-hour UTC days"); the Tool's days are UTC days (`R/wet_bcwatertool.R:124-128`); `wet_station_daily(sources = "bcenv")` gives local-standard-time days with the 20-hour rule and the bound. **Confirmed** (probed). Folded: hours against `wet_bcenv_hours()`, UTC days against `wet_bcenv_days(utc = TRUE)` unbounded, never `wet_station_daily()`; definitions in the script header.
2. **The "by year" table is in the survey report, and gives totals, not stations.** **Confirmed** (the survey report holds the Tool comparison; the harvest report does not). Folded: the portal script ranks stations itself through a provincial-number → Tool-id lookup, and writes its pick before reading the portal.

## Gap

3. Registry needs `bcenv_snapshot`, `bcenv_days` and an against-check, and a `licence` column (the splice hard-codes "none stated"). **Confirmed** (`R/wet_bcwatertool.R:235-249`, `R/wet_station_list.R:91`). Folded.
4. Nothing held the Hakai registry to the reader. Folded: the Hakai report checks `first`, `last`, `continues_before` and fails on a difference.
5. The two-publisher refusal could be skipped (Tool registry opened only when asked) or downgraded by `wet_daily_try()`. Folded: one check over all three registries, read whatever `sources`, raising `wet_registry_conflict`.
6. `wet_station_list(sources = "hakai")` alone returns `NULL`. Folded: typed zero-row frame, tested.
7. Missing tests (not-continued number never calls the reader; row without `continues`; wrong md5; the gap warning). Folded into the tests checkbox.
8. Hakai ids fall to the `.default` bound. **Confirmed** (`wet_bcenv_ratio()` takes `sub =`, `R/wet_bcenv_daily.R:84-91`). Folded: `sub = "08K"` explicit.
9. The identity distance was unstated. Folded: the survey's same-site 0.5 km.
10. Editing `scripts/station_sources_lib.R` would make `scripts/station_regulation.R` refuse. **Confirmed** (`scripts/station_regulation.R:28-41`, commit 6c9cb1e5). Folded as a decided rule.
11. Renaming the bound section stales a tracked report. **Confirmed** (`scripts/station_sources_bound.R:98`, `data/checks/station_sources_bound_20260717.txt:4`). Folded into Phase 3.
12. A new provincial pin rebuilds three registries, not two. Folded.

## Ordering

13. Flags are seen only after download, yet registration came first. Folded: download and list flags, counting no day, before registering.
14. The shared helper lands first as a pure refactor. Folded.

## Assumption

15. Line refs and section count were off (cut at `R/wet_station_daily.R:187-191`; 13 `##` sections). **Confirmed** (`grep -c '^## '` = 13). Corrected.
16. Status mapping presented as mechanism for a peer-reviewed release. Accepted: raised as open decision 5.
17. Whether `"hakai"` joins default `sources` was unstated; if so `test-wet_station_list.R:47-51` gains three rows. **Confirmed** (the test's set is exactly 08HB0008/0011/0012). Folded: joins the defaults, test updated.

## Scope

18. One PR only if Phase 1 stays small; refactor and Hakai separate commits. Folded (refactor commit; Phase 1 about a dozen stations).
19. #181 (first consolidation) still open; move 18 live in its own worktree. **Confirmed** (#181 OPEN; worktree on branch `211-backlog-move-18-natural-non-hydat-statio`, no commits beyond `main` yet). Folded: Phase 3 opens by fetching and merging what landed.

## Acceptance

20. "08HB0008 unchanged" too narrow. Folded: whole `wet_station_list(c("bcenv", "bcwatertool"))` against `origin/main`, and an empty `git diff --stat` on the shipped registries and status file.
21. Hakai report needs its registry check. Folded (with 4).
22. Portal report holds shares only, raw values untracked. Folded.

## Forks for the owner

- A. The package's other four watersheds → open decision 6.
- B. Who can read the Hakai days (private backup only, or a reader that downloads the DOI's files) → open decision 4.
- C. Whether any Hakai day is `"approved"` → open decision 5.
- D. Donors not delivered (the H08KC stations are `unknown`, no accepted snap) — not a fork: recorded as a decided limit, said in the PR and #192's body.

## Files the plan names

R/wet_station_daily.R
R/wet_station_list.R
R/wet_bcwatertool.R
R/wet_bcenv_daily.R
R/wet_bcenv.R
R/wet_hakai.R
data-raw/station_sources_hakai.R
data-raw/station_sources_bcwatertool.R
scripts/station_sources_portal.R
scripts/station_sources_lib.R
scripts/station_regulation.R
scripts/station_sources_bound.R
inst/extdata/station_sources/bcenv_20261028_hydat.csv
inst/extdata/station_sources/bcwatertool_20261028_hydat.csv
inst/extdata/station_sources/regulation_20261028.csv
tests/testthat/test-wet_station_daily.R
tests/testthat/test-wet_station_list.R
research/station_sources.md
research/README.md
data/checks/station_sources_20260717.txt
data/checks/station_sources_bound_20260717.txt
CLAUDE.md
NEWS.md
