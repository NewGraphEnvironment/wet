# Code review, round 1 (#59 branch against main)

## Findings

- **[severity: fragile]** R/wet_segment_monthly.R:155-159 (`wet_segment_pg()`, the `have` query) — every
  Postgres read starts with
  `SELECT DISTINCT source FROM discharge.fwa_v1_segment_monthly WHERE scenario = ... AND source IN (...)`.
  On the published table every row matches (102,790,688 rows, one scenario, both sources), and no index lets
  Postgres answer a DISTINCT without visiting them all: `wet_db_load()` creates the primary key
  `(scenario, forcing, source, linear_feature_id, month, period)`, an index on `linear_feature_id`, and the
  partial `(scenario, linear_feature_id) WHERE month = 0 AND pick`, and Postgres 17 has no loose/skip index
  scan for DISTINCT. So each `wet_segment_monthly(conn, ...)` call, even for one segment, pays a full scan of
  the ~19 GB table before the indexed `linear_feature_id IN (...)` query that actually returns its rows.
  Analog measured here on the 40.5M-row fwapg routed table (cached, 4 parallel workers):
  `SELECT DISTINCT month ... WHERE month IN (1, 2)` took 0.96 s as a parallel seq scan, so the published table
  is several seconds cached and far more cold (research/discharge_publish.md records 197 s for a full-table
  pass of the same table without its index). The fixture tests cannot show it (26 rows), and the research
  paragraph added on this branch gives timings for the parts path only, though its header now says "the
  reader's timings under 'Postgres'". It is not a wrong result, but it turns the per-segment Postgres read
  into a per-call table scan, and any caller looping over segments or groups multiplies it.
  Fix: run the presence check only for a source that the main query returned no rows for (the only case
  where "not loaded" and "segments missing" need telling apart), or make it per source with
  `EXISTS (SELECT 1 ... LIMIT 1)` so it stops at the first match.

## Checked and found sound

- New tests pass under `NOT_CRAN=true` against the source tree (segment reader: 10 blocks, 0 failed/0 error/0
  skipped with local fwapg; flow window: 8 blocks, all pass).
- `roxygenise()` in a scratch copy leaves `man/` and `NAMESPACE` unchanged; `_pkgdown.yml` has no reference
  index, so the new exports need no entry.
- SQL built from user input is quoted (`dbQuoteString` for groups, scenario, sources, hrefs); ids are validated
  whole numbers converted to integer; the fwapg table name is an internal constant.
- fwapg routed table: max `linear_feature_id` 868,144,671 (the `::int` cast is safe), no null flows, no
  segment with other than 12 months, no null `watershed_group_code`, so the `groups` filter and month 0 rule
  behave as the old `HAVING count(q_m3s) = 12` did.
- `integer64` ids (RPostgres bigint) pass the `segments` validation and convert correctly.
- Zero-segment and zero-row paths (`paste()` of all-zero-length vectors returns `character(0)`), tibble input
  to `wet_flow_window()`, `by = character()`, windows across 1 January and ending on 02-29 all behave as
  documented.
- `scripts/pcic_routed_lib.R` is sourced before `wb_cv_lib.R` in the data-raw scripts, but `routed_annual()`
  (and its `wet:::` lookup) runs only after `load_all()`, so it resolves against the source tree.
