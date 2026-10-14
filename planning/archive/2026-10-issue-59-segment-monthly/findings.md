# Findings — Per-segment flow: wet_segment_monthly(), and wet_flow_window() for date windows (#59)

## Plan-mode exploration (2026-10-14)

- Published parts: 43 segment parts, 507 row groups, sorted by `watershed_group_code, linear_feature_id`. Measured: one segment with the group filter 3.3 s; without it 27 s; a random id falls in ~131 of 507 row groups, so many ids without groups read nearly the whole 1.8 GB. Hence an optional `groups` hint.
- m1 has no `discharge.*` table; m4 does. Postgres-path tests use the throwaway-schema trick from `tests/testthat/test-wet_db_load.R` (`local_load_catalog()`), so the internal reader takes the dataset ID.
- fwapg routed table: `linear_feature_id bigint, month, q_m3s` (months 1–12). `routed_annual()` = mean of 12 when all 12 non-null, else NA — same rule as published month 0.
- The monthly bundle read (`read_pub()` → `pub_bulk`, `pub_gauge`) needs `runoff_mm, coverage, period, pick`, which the 4-column contract does not carry. That read stays; the script's *recipe check* (which mirrors the article) switches.
- `from_months()` uses year 2001 (common year). `wet_windows_check()` (R/wet_window_stats.R) validates windows; `"02-29"` end = last day of February.

## Design

**`wet_segment_monthly(conn, segments, source = c("pcic_routed", "wet_balance"), from = c("published", "fwapg"), scenario = "historical", groups = NULL, catalog = NULL)`** → `data.frame(linear_feature_id int, month int, q_m3s dbl, source chr)`, ordered by source, segment (input order), month.
- `from = "published"`: `conn` given → `discharge.fwa_v1_segment_monthly` (via `wet_dataset_table()`); `conn = NULL` → parquet parts from `catalog` (default `wet_catalog()`), duckdb + httpfs, keys from the catalog (as `wet_db_load()` does). Warns when the table comment records a subset load.
- `from = "fwapg"`: routed table, month 0 = mean of 12 when all 12 present; `wet_balance` refused (not in fwapg); scenario other than historical refused.
- Missing table/dataset/parts → stop naming it and where it comes from (`wet_db_load()`; the NewGraphEnvironment fwapg fork, `extras/pcic_crosswalk`, NewGraphEnvironment/fwapg#9/#20). Never an empty frame.
- Duplicate (segment, month, source) rows (e.g. several forcings in a future scenario) → stop. `segments` deduped; NA refused.
- Internals: `wet_segment_sources()` (lookup: from, source, dataset or table, origin text) and `wet_segment_read(conn, dataset, ...)` with the timebase → time column map (`monthly` → `month`, 0:12; #70 adds `daily`).

**`wet_flow_window(x, windows, by = c("linear_feature_id", "source"))`** → `by` columns, `window`, `q_m3s`, `basis`.
- `x` has `month` (→ `basis = "monthly"`: each day of the window takes its month's mean, window = mean over days; month 0 ignored) or `doy` (→ `"daily"`: mean of the window's days; doy of a common 365-day year). Both or neither → error.
- Days laid on a common year (2001; a window crossing 1 January ends in 2002), `"02-29"` end = Feb 28 — as `from_months()` and `wet_window_stats()`.
- NA when any day of the window has no value; duplicate (key, month|doy) → error. Windows via `wet_windows_check()`.
- `by = "station_number"` takes `wet_station_monthly()` output.
- No week helper (optional in the issue; not needed by any caller).

## Errors Encountered

| Error | Resolution |
|-------|------------|

## Issue context

**If we do it:** any script or report gets flow on FWA segments, from any source, with one call, in the same shape as station flow, so a gauge comparison is a join. Flow over any date window, such as a life stage or a week, comes from one function that says whether it rests on daily values or on monthly means. **If we never do:** each script writes its own SQL or duckdb read, every window is computed by hand from months, and each of those callers has to be rewritten when daily flow lands (#70).

*Revised 2026-10-14. The body was written before the published product (#7) existed. It now reflects that #7 shipped, that NewGraphEnvironment/fwapg#9 is closed (so it no longer blocks this issue), that the published routed month 0 is a plain mean of its twelve months, and that the reader is built to take the daily dataset #70 plans. The window function is in scope here, decided 2026-10-14.*

## Problem

Segment flow is read in at least four places, each with its own code:
- `scripts/mad_basin.R`, `scripts/mad_parity.R` and `scripts/wb_term_diagnose.R` join fwapg's gridded annual table (`fwa_stream_networks_discharge`) by hand.
- `scripts/pcic_routed_compare.R` (#58) has its own SQL against the routed table, plus `routed_annual()` in `scripts/pcic_routed_lib.R`.
- `data-raw/monthly_vignette_data.R` reads the published parts with duckdb. `vignettes/monthly-flow.Rmd` shows that read and says this function replaces it.
- The monthly article computes window flow from monthly means by hand (`from_months()` in its `windows` chunk). It measured that estimate at up to 27 % off the gauge's daily record.

Life-stage windows straddle months, and a freshet can rise and fall inside one month. Until daily flow exists (#70), a window estimated from months is the best available, and it should be labelled as such rather than computed silently in each caller.

## Proposed

### One reader keyed on the dataset ID, with thin wrappers

- An internal reader takes the dataset ID (`discharge/fwa/v1/segment_monthly` now, `segment_daily` once #70 publishes it), the segments and the sources. The source lookup, the missing-table error and the `NA` for a missing segment are written once there.
- `wet_segment_monthly(conn, segments, source = c("pcic_routed", "wet_balance", "pcic_gridded"))` returns `data.frame(linear_feature_id, month, q_m3s, source)`. `month` runs 1 to 12, with 0 for the annual value.
  - This is the same contract as `wet_station_monthly()` (`station_number, month, q_m3s`), so `wet_station_snap()` → `wet_segment_monthly()` → join with `wet_station_monthly()` → `wet_flow_validate()` needs no reshaping.
  - Several sources at once give a long table, so comparing them is a pivot.
- `wet_segment_daily()`, added by #70 with the same arguments, returns `linear_feature_id, doy, q_m3s, source`. It mirrors `wet_station_daily()` the way this one mirrors `wet_station_monthly()`. It is not built here, but nothing here should need changing to add it.
- `segments` is a vector of `linear_feature_id` (decided 2026-10-11): the key fwapg's tables, the published product and fresh all join on, and what `wet_station_snap()` returns per gauge. A missing segment comes back as `NA`, not as a dropped row, so missing coverage is visible.
- If a source's table or dataset is missing, the function stops and names it, along with where it comes from (`wet_db_load()`, or the fwapg issue that loads it). It never returns an empty frame.
- Column name `q_m3s`, as in the station family (decided 2026-10-11; #7 aligned to it).

### Month 0 follows the published product

The published routed month 0 is the **plain mean of its twelve months**. `scripts/discharge_publish.R` checks exactly that ("routed month 0 = mean of 1-12"), and fresh joins `month = 0 AND pick` from it. The original body asked for a mean weighted by days in the month. That would differ from the published value on every routed segment, so it is dropped: month 0 is whatever the published product holds. A day-weighted annual is available as the window function over the whole year.

### Window flow: `wet_flow_window()`

- `wet_flow_window(x, windows)` takes the output of `wet_segment_monthly()`, or of `wet_segment_daily()` later. It returns one row per key and window, for segments `linear_feature_id, source, window, q_m3s, basis`.
  - `windows` is the `data.frame(window, start, end)` format that `wet_window_stats()` and `wet_windows_calendar()` already use (month-day, both ends inclusive, checked by `wet_windows_check()`). Species windows are rows added to it.
  - From monthly input, each day of the window takes its month's mean, and the window's flow is the mean over its days: `basis = "monthly"`. This is the monthly article's `from_months()`, moved into the package. The article then calls the function.
  - From daily input, the window's flow is the mean of its days: `basis = "daily"`.
  - A week is a window: fixed day-of-year bins, as NewGraphEnvironment/fwapg#25 defines them. A helper may generate them. Nothing is stored per week.
- Station flow goes through the same function: a `by` argument (default `c("linear_feature_id", "source")`) lets `wet_station_monthly()` output (`station_number`) in too, so a window can be compared between a gauge and its segment.
- `basis` is how the coarse estimate stays visible. When daily lands, a caller swaps `wet_segment_monthly()` for `wet_segment_daily()` and the same `wet_flow_window()` call returns `basis = "daily"`. Nothing else in the caller changes.
- Tests: the monthly path reproduces the article's `from_months()` values. A window inside one month equals that month's mean. A window spanning the year end (`"12-15"` to `"01-15"`) and a window ending on `"02-29"` behave as `wet_window_stats()` defines them. A daily fixture gives `basis = "daily"`.

### Where the values come from (decide at the plan gate)

1. **Recommended: the published product** (`s3://fresh-bc/discharge/fwa/v1/`). Read through Postgres `discharge.fwa_v1_segment_monthly` after `wet_db_load()`, or straight from the parquet parts through `wet_catalog()` and duckdb, where there is no database. One read path gives `pcic_routed` and `wet_balance`, values already checked against their sources by the publish report, and the same month 0 fresh uses. A `segment_daily` dataset slots in by ID.
2. **fwapg's own tables** (`whse_basemapping.fwa_stream_networks_discharge_monthly`, `fwa_stream_networks_discharge`): what the original body proposed.

Whichever is chosen, `pcic_gridded` exists only in fwapg's old annual table, and the published product doesn't carry it. So that source reads fwapg, month 0 only, or is left out if its readers (the parity and diagnosis scripts above, which reproduce fwapg's own numbers) keep their SQL. Either way, the source → table or dataset mapping is held in one internal lookup (e.g. `wet_segment_sources()`), never in SQL scattered across functions and scripts.

### Callers that switch to it

- `scripts/pcic_routed_compare.R` and `routed_annual()` in `scripts/pcic_routed_lib.R`. Check that the tracked report `data/checks/pcic_routed_compare_<release>.txt` reproduces.
- `data-raw/monthly_vignette_data.R`, and the read shown in `vignettes/monthly-flow.Rmd`.
- `from_months()` in `vignettes/monthly-flow.Rmd` becomes a call to `wet_flow_window()`, and the article's numbers must not move.

## The fwapg fork

`pcic_routed` in fwapg comes from the NewGraphEnvironment fork (`extras/pcic_crosswalk` on its `newgraph` branch, loaded by NewGraphEnvironment/fwapg#9, now closed). A database loaded from upstream smnorris/fwapg has the gridded table and not the routed one. NewGraphEnvironment/fwapg#20 (open) offers the crosswalk upstream, and its outcome may move table or column names. If option 1 above is chosen, wet reads routed values from its own published product and this dependency shrinks to the publish script. In either case, the lookup keeps a rename down to one line, and the missing-table error names the fork.

## Not in scope

- Daily flow itself: #70. The routed side of it is NewGraphEnvironment/fwapg#25.
- The default pick between sources stays in #57 (it is the published `pick` column). A later `source = "default"` could apply it.
- Projections are #4 and #9.

Relates to #7, #57, #58, #65, #70, NewGraphEnvironment/fwapg#20, NewGraphEnvironment/fwapg#25.


