# Findings — Backlog move 9 (#186)

## Issue context

Batch 11 of `planning/backlog.md`: #177 (readers do not return `pick`) and #171 (the daily script's
`own` list lacks the readers `publish_own` gained in #164). Issue body and both member issues read at
branch point eaa12d9d; no comments beyond the in-flight claim.

## Measured at the branch point

- `scripts/discharge_publish.R:222` `publish_own` holds `R/wet_catalog.R`, `R/wet_db_load.R`,
  `R/wet_values_compare.R`, `R/wet_segment_daily.R`, `scripts/discharge_publish.R`,
  `scripts/discharge_publish_lib.R`, `scripts/vignette_data_lib.R`, `scripts/segment_group.R`;
  `daily_own` is `scripts/segment_daily_output.R`.
- `scripts/segment_daily_output.R:80` `own` holds only the first three R files, the daily script and the
  two publish scripts.
- Neither list holds `R/wet_segment_monthly.R`, where `wet_segment_read()` lives; #177 edits it, so the
  BUILD's monthly check (`discharge_publish.R:230`) would refuse the branch and ask for a province rerun.
  The issues name only `R/wet_segment_daily.R`.
- The BUILD's daily check (`discharge_publish.R:264`) excludes `publish_own` but not `daily_own`, so any
  edit to `scripts/segment_daily_output.R` forces a daily rerun.
- `wet_flow_window()` reads named columns only, so a fifth column is accepted.

## Errors Encountered

| Error | Resolution |
|-------|------------|

## Plan review (2026-11-22, Plan agent; each claim below probed)

- Segment report names commit 66cf795, daily report bc55d30 (segment table built at 66cf795). `git diff
  --name-only 66cf795 HEAD -- R scripts` lists 17 files: six in `publish_own`, `scripts/vignette_data_lib.R`
  (BUILD-excluded, not in the daily `own`), and ten in neither list (see `task_plan.md` Open decisions).
  The guards refuse at the branch point.
- `pick` is constant per segment and source (13 rows monthly, 365 daily).
- `data-raw/monthly_vignette_data.R:383-390` compares the reader's result to a four-column subset with
  `identical()`; a fifth column stops it.
- Fixtures (`tests/testthat/helper-discharge.R`) already carry `pick`; tests pinning four columns:
  `test-wet_segment_monthly.R:25,72`, `test-wet_segment_daily.R:22`.
