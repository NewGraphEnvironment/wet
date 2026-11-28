# Plan review for #237 (backlog move 21: daily air temperature at every stream segment)

Blockers raised: 1
Owner forks: 4

A Plan review of `task_plan.md` against #237, #216 and the code they name, run on 2026-11-26 before the baseline, by a
read-only reviewer that opened each function, ran the plan's names through the existing helpers and read cd's
`cd_extract_daily()`. Each finding was probed by the plan session before it was folded or declined; "probed" says how.
The counts above are what the review raised, before anything was folded.

## Findings and verdicts

| | finding | probed | verdict |
|---|---|---|---|
| B1 Blocker | crate has no type for `cell_daily.date`: its types are integer, double, string, logical, datetime, and its datetime turns a Date into 00:00 UTC, the previous local day on cd's UTC−8 day. The publish pattern refuses a conform that changes a class. | `crate:::crt_schema_types()` and `crt_datetime_utc(as.Date(...))` run: as stated. `scripts/discharge_publish_lib.R` 137–142 read. | Owner fork: decision 4 (a `date` type in crate, a string, or year and day). Phase 1's crate pull request carries the type under 4(a). |
| A1 Acceptance | #216's station condition was rewritten as two checks under "mechanism". The first cannot disagree about the cell (cd chose it at that point); the second cannot fail on its own. Where a station and its segment's point sit in different cells, #216's wording is unmet. | `R/wet_station_snap.R` read: candidates within 1 km, chosen by drainage area. | Owner fork: decision 9. The plan now says what each check can and cannot prove, and the cell choice is proved by the recomputed checks instead. The count of stations in another cell is a Phase 1 measurement. |
| A2 Acceptance | Nothing independent checks which neighbour a `moved` row took; a mutation to another of the eight would pass. | cd's rule read in `daily_cells()`: nearest centre by geodesic distance, ties to the lower cell number. | Folded: Phase 4 recomputes the rule for every `moved` row, and the mutation list has that case. |
| A3 Acceptance | "Any watershed group" was shown on one group. | The plan's own text. | Folded: one segment read from each of the 246 groups, and one whole group. |
| A4 Acceptance | The "rows dropped" mutation had no check to turn red; "every segment in exactly one status" cannot fail. | The plan's own text. | Folded: a completeness check (every used cell, every day, every year; no other cell) and segments read held to `count(*)`. |
| O1 Ordering | With the upload owed after the merge, the copied guard (`git diff <build commit> HEAD -- R scripts`) refuses once anything else merges; the tree sits under a worktree's gitignored `data/`; a review fix after the BUILD costs a rebuild; the release ships a reader whose default address answers 403. | `scripts/discharge_publish.R` 76–83 and its `root` read: as stated. | Folded: the tree under `WET_DATA_ROOT`; the air guard compares the files the build reads, with a test deriving the list; `/code-check` before the BUILD; decision 8 now recommends the upload while the pull request is open and states the 403. |
| O2 Ordering | Three measurements came after the decisions they inform (the `moved` and `no_data` counts, one year's bytes, stations in another cell). | The status counts were measured by the plan session against the cube's mask (in `findings.md`): 41,734 `moved`, 962 `no_data`, 2 `outside`. | Folded: decision 6 carries the counts; Phase 1 measures the other two before the crate schema is opened, with a stop rule on bytes. |
| O3 Ordering | Nobody is asked to merge and release the crate pull request; the build checks each schema at the installed crate's release tag. | `scripts/discharge_publish.R` 170–186 read: as stated. | Folded: Phase 1 says what Phase 4 needs; Phase 3's tests run against a throwaway install of the branch; Phase 4 stops if the release is not there. The wait itself stands. |
| O4 Ordering | "Revise the phase it changes" missed text outside the phases that assumes the recommended answers. | The plan's own text. | Folded: Phase 1's box names each place; decision 6(c) says the lookup then differs from cd by design. |
| G1 Gap | The fixture cube cannot produce `moved` or `no_data`. | The three bundled files read with terra: 5 × 5, 365 bands, 4-byte float, no empty cell. | Folded: tests and the bundled tree use a masked copy. |
| G2 Gap | A stranded point keeps its own cell with `cell_moved` FALSE; statuses from warning text mean parsing ids; the mask is the first band of the first file opened, so the day must be pinned. | cd's `daily_cells()` and the template read in `cd_extract_daily()`: as stated. | Folded: statuses from the columns, the mask day pinned and named in the manifest. |
| G3 Gap | A stale cached cube file gives `checksum` NA with only a warning; a single cd commit as a receipt input assumes all 228 files share one. | cd's code as read; the commits not counted (no download). | Folded: any cd warning or NA checksum in the series step refuses; the receipt lists every distinct commit. |
| G4 Gap | `wet_db_load()` reads `cell_daily` as a day-of-year table and fails after fetching every part. | `wet_timebase()` run on both dataset IDs: `cell_daily` gives `doy` 1–365, `segment_cell` stops. | Folded: an early refusal with a test (Phase 2), under decision 10(a). |
| G5 Gap | Phase 2's catalog box named changes not needed (`wet_catalog()`, `wet_manifest_write()` accept the tree) and omitted the air manifest's default address, the roxygen title and crate's floor. | `R/wet_catalog.R` 252–283 and 374–404 read; the test pin at `tests/testthat/test-wet_catalog.R` 213 found. | Folded: the box rewritten. |
| G6 Gap | The station list's source was not named, and a station check inside the BUILD ties its report to an archive that grows. | `scripts/temp_fill_validate.R` and `scripts/temp_baseline_traits.R` read. | Folded: its own script and report, stations named. |
| G7 Gap | A second file states the stale 59.95° N edge. | `grep 59.95`: `research/station_temperature_fill.md` 23 and `scripts/temp_fill_validate.R` 37. | Folded: one wet issue for both; neither edited here, since the validation's results rest on the cube as it was. |
| S1 Assumption | cd's cell number is a stored key that renumbers if cd's box changes, and it has changed once. | The cube's extent read (60.05° N) against #216's 59.95. | Owner fork: decision 3. |
| S2 Assumption | The arithmetic cell check holds on 2,000,000 random points and disagrees with terra on points computed to lie on a cell edge. | Not rerun; the report now states the rule. | Folded: terra's rule on the grid's definition, named in the report. |
| C1 Scope | "No Postgres table" settled a reading of #216's third condition without the owner. | `research/discharge_publish.md`, "Postgres". | Owner fork: decision 10. |
| C2 Scope | Decision 1(a) departs from three written naming rules it did not quote; crate holds the same rule in a decision record. | `research/discharge_publish.md` 22–26 read; crate's record of 2026-10-12 exists. | Folded into decision 1; the crate pull request carries a decision record; Phase 5 restates the rule. |
| C3 Scope | One pull request is reasonable; nothing needs splitting. | — | Stands. |

## Found by the plan session while probing

- **The discharge guards compare every file under `R/` and `scripts/` not listed in `scripts/discharge_publish_own.R`.**
  This move's new files would read as a change to the discharge tree's code. Folded: Phase 2 adds them to the list.
- **The database's temporary space ran out on a `count(distinct)` over the segments.** Folded: every query the build
  and the measurements make streams, with no sort or aggregate in the database.

## Checked by the review and holds

- `air_temperature/fwa/v1`, `segment_cell`, `cell_daily`, `ERA5-Land`, `cd_daily`, a group code and a year pass
  `wet_id_check()` and `wet_part_parse()`; `wet_catalog_verify()` and `wet_catalog_digest()` assume nothing of discharge.
- `wet_temp_fill()` takes `id`, `date`, `variable`, `value` and reads `tmean`.
- Every one of the cube's 31,581 cell centres maps back to its own cell.
- cd refuses duplicate or missing ids; memory is not a concern at one day per group or one variable and year per call.
- cd holds no cell elevation; a new column does not bump the version.

## Files the plan names

R/wet_air_daily.R
R/wet_catalog.R
R/wet_db_load.R
R/wet_segment_daily.R
R/wet_segment_monthly.R
R/wet_station_snap.R
R/wet_temp_fill.R
tests/testthat/test-wet_air_daily.R
tests/testthat/test-wet_catalog.R
tests/testthat/test-wet_db_load.R
tests/testthat/test-publish_own.R
tests/testthat/test-air_publish_lib.R
scripts/air_publish.R
scripts/air_publish_lib.R
scripts/air_station_check.R
scripts/discharge_publish.R
scripts/discharge_publish_lib.R
scripts/discharge_publish_own.R
scripts/temp_fill_validate.R
scripts/temp_baseline_traits.R
data-raw/air_example_data.R
inst/extdata/air_example/
inst/receipt/air_temperature_fwa_v1.yaml
inst/receipt/discharge_fwa_v1.yaml
data/checks/air_publish_2025.txt
data/checks/air_station_check_2025.txt
research/air_temperature_segments.md
research/README.md
research/discharge_publish.md
research/station_temperature_fill.md
CLAUDE.md
NEWS.md
DESCRIPTION
_pkgdown.yml
