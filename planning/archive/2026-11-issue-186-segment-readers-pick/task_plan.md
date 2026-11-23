# Task: Backlog move 9: The segment readers return pick, and one list of non-inputs (#186)

Umbrella for batch 11 of `planning/backlog.md` (move 9, sonnet): #177 (`wet_segment_monthly()` and
`wet_segment_daily()` do not return `pick`) and #171 (`scripts/segment_daily_output.R`'s exclusion list
lacks the readers `publish_own` gained in #164). One phase, one PR. Both are the publish side's readers
and guards; #177 edits `R/wet_segment_daily.R`, which `scripts/segment_daily_output.R`'s `own` lacks, so
a fix to #177 alone trips the daily guard.

## Decided at the gate

No plan gate in this pane: dispatched by the coordinator, so this is a reviewed park and the
coordinator's plan gate decides. The forks the issue names are under `## Decisions (answered by the owner at the resume, 2026-11-22)

- **#171 now:** one shared list in `scripts/discharge_publish_own.R`; the daily rerun and a BUILD are owed after the merge.
- **`pick`:** a logical column appended last, in the published, database and fwapg modes; `NA` on a missing segment's rows and on every row for `from = "fwapg"`.
- **Guards refusing at the branch point:** classify the ten files; non-inputs join the list; if a real input moved the tables, stop and ask. Measured: none moved a table (`R/wet_station_snap.R`: roxygen text only; `scripts/pcic_routed_lib.R`: new functions only, no line removed). Both are real inputs, so they stay off the list and the BUILD still refuses until `scripts/segment_output.R` reruns on the province machine (owed, below).

## Phase 1: Readers return `pick`; one list of non-inputs

- [x] Baseline first: replay the three guards at the branch point and record which files each lists
  (`findings.md`), so a later "empty" means the branch's files only.
- [x] Tests first (`tests/testthat/test-wet_segment_monthly.R`, `test-wet_segment_daily.R`): the fixture
  parts carry `pick`; both readers return it from the parts and from Postgres after `wet_db_load()` (also
  with `pick_only` loads), `NA` on a missing segment's rows, `NA` for `from = "fwapg"`; update the
  `expect_named()` calls; a request for one source returns that source's picks.
- [x] `R/wet_segment_monthly.R`: `wet_segment_read()` carries `pick` through `wet_segment_parts()`
  (select it from the parts), `wet_segment_pg()` and `wet_segment_fwapg()` (logical `NA`), into the
  grid join; the duplicate-row check and zero-id early return keep the column; the `@return`, the
  example and `R/wet_segment_daily.R`'s docs name it.
- [x] Every frame the readers build carries `pick` (review): the zero-id early return (`pick = logical()`),
  the grid selection, the `wet_segment_pg()` SELECT, the empty-part frame and SELECT in
  `wet_segment_parts()`, and `wet_segment_fwapg()` after the month-0 `rbind`; a table loaded without a
  `pick` column errors naming `wet_db_load()` (the real schema has it). `NA` for a missing source's rows is
  not `FALSE`: the docs say so.
- [x] `data-raw/monthly_vignette_data.R:383-390` compares the recipe read to a four-column bundle subset
  with `identical()`: add `pick` to its subset (it must hold the published picks), or drop the column
  there, so the next run does not stop.
- [x] Check what takes the readers' output: `wet_flow_window()` (reads named columns, so extra ones are
  fine), `scripts/pcic_routed_lib.R:80` (`from = "fwapg"`, `routed_annual()`), `data-raw/segment_vignette_data.R`
  and `data-raw/monthly_vignette_data.R`, and `vignettes/segment-discharge.Rmd` (line 322 names the four
  columns: reword; its `reshape()` already subsets columns). No bundle changes value, so none is rebuilt.
- [x] #171: one list, `publish_own`, in a file both scripts source (a new `scripts/` file, named for the
  list, and in the list itself, as `discharge_publish_lib.R` is). `scripts/discharge_publish.R` and
  `scripts/segment_daily_output.R` source it; the daily script's `own` is that list plus itself. The list
  gains `R/wet_segment_monthly.R` (a reader, and the one `wet_segment_read()` lives in: without it the
  BUILD refuses #177's edit as a change to the monthly table and asks for a province rerun), and the
  daily script's list gains what only the publish one had (`R/wet_segment_daily.R`,
  `scripts/vignette_data_lib.R`, `scripts/segment_group.R`).
  `daily_own` stays out of the shared list: `scripts/segment_daily_output.R` must still show as changed to
  the BUILD's daily check. Excluding `R/wet_segment_monthly.R` whole also hides `wet_segment_sources()`
  (the routed run and table `pcic_routed_lib.R` reads); the routed-line check in both scripts covers part
  of that, and the trade-off is written in the list's comment.
- [x] Test that the two scripts share the one list (under `devtools::test()` with `skip_if_not(dir.exists("scripts"))`, as `test-publish_report_live.R` does; neither assigns its own; every entry exists on
  disk; the list names itself and `R/wet_segment_monthly.R`).
- [x] Replay both guards by hand from a worktree of the live segment commit: `git diff --name-only
  <seg_commit> HEAD -- R scripts` minus each list is empty for the branch's changes.
- [x] `NEWS.md` line; `devtools::document()`; `lintr`; `devtools::test()`; `pkgdown::check_pkgdown()`.

## Owed at the end (reported, done after merge)

- [ ] On the machine with the full province run: `scripts/segment_output.R` first (the guards still list `R/wet_station_snap.R` and `scripts/pcic_routed_lib.R`, real inputs changed without moving a table), then `scripts/segment_daily_output.R` (about 132 min), then
  `WET_FWAPG_COMMIT=5d50cc1 scripts/discharge_publish.R` BUILD; expect every part byte-identical to the
  live manifest and no upload. Commit the reports it leaves modified.
- [ ] Reply on `knowledge#42` (ours: NewGraphEnvironment) that the readers return `pick`, after the merge.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (once over the branch)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
- Verified by: the new reader tests over the fixture tree, the two-list test, and the by-hand replay of
  both guards; the live read `wet_segment_monthly(NULL, 17094080, groups = "BULK")` returns `pick`.
