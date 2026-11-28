# Plan review for #235 (move 19, batch 21: #215), 2026-11-26

Blockers raised: 2
Owner forks: 5

A Plan agent reviewed `task_plan.md` against #235, #215 and the code before the baseline. It ran synchronously, read
the files only, and made no request to the Skeena catalogue. Its key claims were probed before folding:
- `08NHX18` is in the archive (`data/checks/temp_coverage_report.txt:27`) and does not match `wet_hydat_number`
  (`R/wet_station_daily.R:265`).
- `rg_snap_pick()` sits in `scripts/station_regulation_rule.R:182`, with the tolerance and candidate constants at
  :118-119.
- `stream_of()` is in `scripts/station_sources_lib.R:35`.
- `wet_temp_fill()` defaults to `min_days = 365`.
- gsdd's `.gss` takes `min_length` from the window.

## Findings and verdicts

- **B1 Blocker**, refusing ids "of neither kind" breaks `08NHX18` and the scripts that pass the whole archive.
  Folded: ids are routed by registry membership only, nothing new is refused, and the 08ZZ999 warning test is kept.
- **B2 Blocker**, fetch-on-miss for every series would send agent requests to the catalogue whose robots.txt refuses
  AI agents. Folded: a manifest `fetch` column, with `FALSE` stopping through `wet_snapshot_unavailable()`.
- **G1 Gap**, the shoulders definition counted any fragment, and complete seasons will be near zero for seasonal
  loggers. Folded: the fill validation's shape (16 May–30 Sep unbroken), the near-zero expectation stated, and
  observed days reported against `min_days = 365`.
- **G2 Gap**, `NHG_…` ids would form their own fill pool. Folded: registry `subdrainage`/`nearest_eccc`/`nearest_km`,
  the `pool` roxygen and the CLAUDE.md line.
- **G3 Gap**, the QA rules were not concrete. Folded:
  - rule order;
  - deployment by a 6-hour gap;
  - stuck runs measured in hours, open-water months, above 0.5 °C;
  - air days on the diurnal range of hourly means;
  - a named threshold script and report;
  - constants held to the report.
  The percentiles and station subset go to the owner (Open decision 5).
- **G4 Gap**, the placement spec was thin. Folded:
  - the three sourced files;
  - 1000 m and 5 candidates;
  - a nearest-within-100 m leg for unnamed sites (decided in the plan as mechanism);
  - a separate placement file.
- **G5 Gap**, the main-flow tree may be absent. Folded: the tree is required, its row count recorded, and a rule for
  segments off the tree.
- **G6 Gap**, the pin was underspecified. Folded: the version is the record id, validated; zip members are listed;
  coordinates and formats are settled in Phase 1, with readxl if needed.
- **G7 Gap**, the earlier record was compared but not pinned. Folded: both are pinned, and a site's days come from the
  later record, else the earlier.
- **G8 Gap**, `wet_temp_daily()` mechanics were open. Folded:
  - `sources` uses `"provisional"` for ECCC;
  - a failed source is skipped with a warning;
  - the dependency checks move into the ECCC branch;
  - radix sort;
  - one `wet_logger_versions` constant.
- **G9 Gap**, the time zone was ambiguous. Folded: `utc_offset`, `dst` and `tz` columns, with the conversion rule.
- **G10 Gap**, Morice, the dashboard and Weigert's follow-up were missing. Folded into Phases 1 and 6.
- **G11 Gap**, four smaller items. Folded:
  - ECCC sites within 0.5 km are listed;
  - the registry path is in the roxygen;
  - the test files are named;
  - logger days are computed in R.
- **O1 Ordering**, the rules were to be registered in the research file only in Phase 5. Folded: a commit of their
  own in Phase 3, before screening.
- **O2 Ordering**, placement keyed to the md5 of a file it rewrites is circular. Folded: a separate placement file.
- **O3 Ordering**, "ask if still open" partway through the build. Folded: each phase names the Open decision it waits
  on.
- **O4 Ordering**, an overlap with move 20's gap screening. Folded: the logger QA applies to loggers only, and the
  research section stands alone.
- **O5 Ordering**, Phase 6(a) reopened Phase 5. Folded with S1.
- **A1 Assumption**, two of the backlog's gate questions were decided as mechanism. Folded: answered as
  recommendations and put to the owner (Open decision 4). The later-record-only scope choice is removed by reading
  both records.
- **A2 Assumption**, thresholds are the owner's, and river gauges understate small streams' range. Folded: Open
  decision 5, with a proposed small-basin subset.
- **A3 Assumption**, option 1(a) must say an agent processes the hand-fetched data. Folded into Open decision 1.
- **S1 Scope**, Nechako is one PR and Upper Bulkley is its own issue under both options. Folded: Phase 6, and
  "Closes #215" only when every readable series has loaded.
- **AC1–AC3 Acceptance**, coverage of "Done when", conditions for byte-identical output, and added tests. Folded into
  Phases 3 and 5 and the verification list.
- **Public-repo hygiene**, nothing flagged.

## Files the plan names

planning/active/task_plan.md
planning/active/findings.md
planning/active/progress.md
planning/backlog.md
R/wet_temp_daily.R
R/wet_temp_gsdd.R
R/wet_temp_fill.R
R/wet_hakai.R
R/wet_bcenv.R
R/wet_station_daily.R
R/wet_station_snap.R
R/wet_logger_daily.R
scripts/station_regulation_lib.R
scripts/station_regulation_rule.R
scripts/station_sources_lib.R
scripts/station_regulation.R
scripts/station_sources_hakai.R
scripts/temp_day_boundary.R
scripts/temp_coverage.R
scripts/temp_fill_validate.R
scripts/temp_baseline.R
scripts/temp_loggers.R
scripts/temp_logger_thresholds.R
data-raw/station_sources_hakai.R
data-raw/temperature_vignette_map.R
data-raw/temp_loggers_nhg.R
inst/extdata/temp_loggers/nhg_15053907.csv
inst/extdata/temp_loggers/nhg_15053907_sites.csv
inst/extdata/temp_loggers/nhg_15053907_placement.csv
inst/extdata/temp_loggers/nhg_6426024.csv
inst/extdata/station_sources/regulation_20261028.csv
data/checks/temp_loggers_nhg_15053907.txt
data/checks/temp_logger_thresholds.txt
data/checks/temp_coverage_report.txt
tests/testthat/test-wet_temp_daily.R
tests/testthat/test-wet_temp_fill.R
tests/testthat/test-wet_temp_gsdd.R
tests/testthat/test-wet_logger_daily.R
tests/testthat/helper-temp-loggers.R
tests/testthat/helper-temp-fill.R
tests/testthat/helper-bcwatertool.R
tests/testthat/helper-bcenv.R
tests/testthat/test-wet_bcenv.R
research/station_water_temperature.md
research/station_temperature_fill.md
man/wet_temp_daily.Rd
CLAUDE.md
NEWS.md
DESCRIPTION
