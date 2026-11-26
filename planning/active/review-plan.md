# Plan review of #242 (move 26), 2026-11-26

Blockers raised: 3
Owner forks: 5

One Plan agent ran synchronously against `task_plan.md`, issues #242, #232, #233 and #227, the backlog's sections 29 and 30, and the code. It raised 3 blockers. The plan now carries 5 owner forks (two of them, Open decisions 4 and 5, came from the review). Each finding below was probed before it was folded in or declined.

## Blocker

- **B1. The plan re-opened decisions the owner had already made in #242's body.** Verdict: confirmed with `gh issue view 242`. The body gained `## Decisions` ("The owner's, 2026-11-26, at a plan gate") after this session first read it. Folded in: the four decisions are quoted verbatim under "Decided at the gate"; the draft's Open decisions on the failed-bar path, the read path and the same-flow rule are removed; the off-hour spans now decide at the bar; a failing station stops the pin. The snapshot date, which the owner left undecided, is now Open decision 1.
- **B2. The pin command could pin the survey's old files under a new date.** Verdict: confirmed. `data-raw/station_sources_snapshot.R:38` defaults `WET_STATION_SOURCES_RAW` to the survey's copy, and the md5 hold at `:47` runs only for 20261028. Folded in: the env var is required for a non-survey snapshot, and an md5 set already pinned is refused.
- **B3. Running the portal check on the new pin would make new portal requests and move the pick.** Verdict: confirmed from `scripts/station_sources_portal.R:95-150,199` (the pick is recomputed from the pinned snapshot, and `cached()` fetches a station it does not hold). Folded in: the new-pin mode uses #190's fixed list of ten stations, caps the window at 2026-10-27, refuses a missing cached file, and gets its own report name.

## Ordering

- **O1. How the portal check can read files not yet pinned.** Folded in: build locally without a backup, check, then back up and commit; a failure deletes the uncommitted files.
- **O2. Amendment 4 cannot restate counts it predates.** Folded in: the population is named by rule, and the counts go in the regulation report.
- **O3. The data-raw scripts read the constant.** Folded in: the constant moves before the rebuilds, and the Tool registry is rebuilt before Hakai's.
- **O4. Tests go red when the constant moves.** Folded in: the sweep lands in the same commit as the constant.

## Gap

- **G1. Tests hard-wired to 20261028, and their counts.** Folded in, by file and line.
- **G2. The harvest is one-snapshot throughout.** Folded in as an explicit split.
- **G3. The bound and Hakai reports overwrite their records.** Bound: renamed. Hakai: the overwrite is intended (named by package version, same package). A failed bound catch stops and goes to the owner.
- **G4. The #233 code list was short.** Folded in: names from the README, identity against the new pin, `continues_before` NA rule, own-number days, list columns, the regulation population and label, three-registry hold, headers and man.
- **G5. The duplicate check already exists.** Folded in: it is now a test, not new code.
- **G6. A test cannot source a script.** Folded in: a new `scripts/station_sources_portal_lib.R`, kept out of the file the regulation rule hashes.
- **G7. The claimed refusal message does not exist.** Folded in: Open decision 2(a) adds it with a test and states its cost.
- **G8. The join's place in `wet_station_daily()`.** Folded in: an internal accessor, its own try block, the cut through `wet_daily_after()`, docs, and the gap warning.
- **G9. The new column.** Folded in: `continues_hydat`, `wet_station_list_empty()`, `@return` and the tests.
- **G10. How the files were fetched.** Folded in: `fetch.tsv` and the harvest report.

## Assumption

- **A1. The off-hour spans against an older portal export.** Owner fork: Open decision 4.
- **A2. The 99.9 % bar was measured pooled.** Folded in: the arithmetic is registered, and the old pin's per-station share is quoted beside the bar before registering.
- **A3. Hakai identity checked against the old pin.** Folded in: classified against the new pin.
- **A4. Moved statuses need not come from the registries alone.** Folded in: each one is attributed, with the catalog digest printed.
- **A5. A new grade or archive name.** Folded in as a stop-and-ask condition.
- **A6. New Hakai quality codes.** Folded in as a stop-and-ask condition.
- **A7. The same-flow rule's mechanics.** Folded in: nearest, natural, spans both eras, complete month, and both-fail behaviour.

## Scope

- **S1. One PR is too much.** Owner fork: Open decision 5 recommends batch 30 in a second PR. The backlog said one PR, so it is the owner's to change.
- **S2. The portal verdict is a checkpoint.** Folded in.
- **S3. Open decision 1's cost.** Folded in, in what is now Open decision 2(a).
- **S4. Missing forks.** Folded in as Open decision 4, plus the stop-and-ask conditions.

## Acceptance

Folded in: tests that can fail for the pin, the per-station table the portal verdict reads, the own-station tests, the regulation md5 refusal test, the window-years line in the continue report, and the registry holds named as the correctness proof.

## Files the plan names

```
planning/backlog.md
R/wet_bcenv.R
R/wet_bcenv_daily.R
R/wet_hakai.R
R/wet_bcwatertool.R
R/wet_station_list.R
R/wet_station_daily.R
R/wet_station_select.R
man/wet_station_list.Rd
man/wet_station_daily.Rd
data-raw/station_sources_snapshot.R
data-raw/station_sources_hakai.R
data-raw/station_sources_bcwatertool.R
scripts/station_sources_portal.R
scripts/station_sources_portal_lib.R
scripts/station_sources_lib.R
scripts/station_regulation.R
scripts/station_regulation_rule.R
scripts/station_regulation_lib.R
scripts/station_sources_harvest.R
scripts/station_sources_hakai.R
scripts/station_sources_bound.R
scripts/station_hydat_continue.R
scripts/departure_donors.R
scripts/departure_donors_rule.R
research/station_sources.md
CLAUDE.md
NEWS.md
inst/extdata/station_sources/bcenv_20261028.csv
inst/extdata/station_sources/bcenv_20261028_hydat.csv
inst/extdata/station_sources/bcwatertool_20261028_hydat.csv
inst/extdata/station_sources/hakai_8318556d2baf_hydat.csv
inst/extdata/station_sources/regulation_20261028.csv
data/checks/station_sources_20260717.txt
data/checks/station_sources_portal_20261125.txt
data/checks/station_regulation_20261028.txt
data/checks/station_sources_harvest_20261028.txt
data/checks/station_sources_hakai_8318556d2baf.txt
data/checks/station_sources_bound_20260717.txt
tests/testthat/test-wet_station_list.R
tests/testthat/test-wet_station_daily.R
tests/testthat/helper-bcenv.R
tests/testthat/helper-bcwatertool.R
tests/testthat/test-wet_bcenv.R
tests/testthat/test-wet_bcwatertool.R
tests/testthat/test-station_regulation_rule.R
```
