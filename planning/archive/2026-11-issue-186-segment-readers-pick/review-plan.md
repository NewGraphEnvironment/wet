# Plan review for #186 (Plan agent, 2026-11-22; findings probed before folding)

Blockers raised: 1
Owner forks: 2

- Blocker (confirmed): the three guards already refuse at the branch point on ten files in neither list;
  folded into `task_plan.md` as an open decision plus a baseline-replay task.
- Gap (folded): `data-raw/monthly_vignette_data.R` recipe `identical()` check; every reader frame needs
  `pick` (zero-id return, SELECTs, empty-part frame, fwapg); absent column on an older table.
- Scope (folded): excluding `R/wet_segment_monthly.R` whole hides `wet_segment_sources()`; keep
  `daily_own` out of the shared list so guard B still sees the daily script.
- Ordering (folded): the list file exists, and names itself, before either script sources it; the daily
  rerun is on merged HEAD before the BUILD.
- Acceptance (folded): no-upload outcome is owed and checkable only after the daily rerun.
- Verified, no change: `pick` constant per segment and source; fixtures carry `pick`; `wet_flow_window()`
  takes extra columns.

## Files the plan names
R/wet_segment_monthly.R
R/wet_segment_daily.R
R/wet_flow_window.R
R/wet_db_load.R
scripts/discharge_publish.R
scripts/discharge_publish_lib.R
scripts/segment_daily_output.R
scripts/segment_output.R
scripts/pcic_routed_lib.R
scripts/vignette_data_lib.R
scripts/segment_group.R
data-raw/monthly_vignette_data.R
data-raw/segment_vignette_data.R
vignettes/segment-discharge.Rmd
tests/testthat/helper-discharge.R
tests/testthat/test-wet_segment_monthly.R
tests/testthat/test-wet_segment_daily.R
tests/testthat/test-publish_report_live.R
NEWS.md
