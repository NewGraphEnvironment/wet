# Code-check round 1: #101 branch diff (main...HEAD, planning/ excluded)

Reviewer: subagent, 2026-10-18, on m1 against the local fwapg (read-only queries; one session-local temp table).

## Findings

- **[severity: bug]** scripts/segment_output.R:147-150 (with :154): the added `ORDER BY r.linear_feature_id, r.month`
  changes the routed month 0 (`q_m3s`, and `runoff_mm` derived from it) in the last bits for roughly 15 % of routed
  segments in every basin large enough that the old query ran as a hash join. So the routed parts will **not** be
  byte-identical to the live build, which is the branch's own acceptance criterion (task_plan.md Phase "m4 …
  every segment part byte-identical"). findings.md:78 adopted the ORDER BY as "cheap insurance for byte-identical
  month 0"; measured, it does the opposite.

  Mechanism: `rt0 <- stats::aggregate(q_m3s ~ linear_feature_id, rt, mean)` sums the twelve months in the order the
  rows arrive (arm64 long double is double, so order changes bits). The published month 0 was computed in the old
  table's arrival order, and for a large `seg_ids` the old query was a Hash Join over a Seq Scan of the old table, i.e.
  that table's physical order, in which months are not ascending within a segment.

  Evidence (m1, local fwapg, values of the old table and the new run are bit-identical: full join on
  (linear_feature_id, month) of `whse_basemapping.fwa_stream_networks_discharge_monthly` against
  `pcic.discharge_monthly` for the run gives 40,524,444 rows, 0 only-old, 0 only-new, 0 `q_m3s IS DISTINCT`):
  - Old query with 1,000,000 ids in a temp `seg_ids`: plan is Hash Join + Seq Scan on the old table; 960,420 of
    1,000,000 segments come back with months not ascending; month-0 mean in returned order vs sorted order differs in
    154,816 segments. With 2,000 ids the plan is Nested Loop + PK index scan and months come back ascending (0 differ),
    so small basins are unaffected.
  - Against the live published parts (read via `wet_catalog()` + duckdb httpfs, routed parts, by group): published
    month 0 differs from the sorted-order mean (what the branch's ORDER BY gives) in 3,393 of 23,643 QUES segments and
    5,649 of 30,037 BULK segments; it differs from the mean in the old table's ctid order in only 17 and 36. The
    published bits came from the old physical order, which `pcic.discharge_monthly` cannot reproduce.

  Consequences on rerun: `discharge_publish.R` BUILD still reports every check `ok` (its month-0 check has
  tol 1e-9, and "parts identical to the published build" is reported, not checked, so the BUILD does not fail), but
  that line will read fewer than 67 of 67; the report then differs beyond the `wet commit` / `routed:` lines, and
  `vd_published()` (scripts/vignette_data_lib.R) refuses both vignette data scripts until a republish. The changes
  are ~1e-16 relative, so nothing material moves, but the stated goal "every parquet part byte-identical" cannot be
  met by the branch as written, and dropping the ORDER BY would not restore it either (the new table's physical
  order is not the old one's). This is a decision for the author: accept a republish of the routed parts (month 0
  equal within the existing 1e-9 check) and restate the acceptance criterion, or find another way to reproduce the
  old order. Either way findings.md:78's rationale should be corrected.

## Checked and clean

- Every read of the routed table carries the run filter: `wet_segment_fwapg()` (EXISTS guard and SELECT),
  `routed_fingerprint()` (rows and `pcic.runs`), segment_output.R (per-basin read and `n_routed_unplaced`),
  discharge_publish.R (`rt_all`), monthly_vignette_data.R (`src_routed`); segment_vignette_data.R reads through
  `routed_annual()` -> `wet_segment_monthly()`. No other code reads `fwa_stream_networks_discharge_monthly`
  (`fwa_stream_networks_discharge`, the annual table, is a different table).
- Fingerprint unchanged: the run's `count/distinct/null/sum(round(q::numeric,6))` is
  `40524444 rows, 3377037 segments, 0 null flows, total 178035348.248310 m3/s`, the tracked `table:` line, and equals
  `pcic.runs` (178035348.248310, 40524444, 3377037). `routed_fingerprint()`'s `pcic.runs` comparison fails closed
  (no row, NULL sum, or mismatch all stop).
- Report text: `routed per gauge … (%s …)`, `Routed flow is %s`, segment `periods: routed %s`, and the manifest's
  `monthly means %s` all render `1951-2012` as before.
- Sourcing order: every script that sources pcic_routed_lib.R has run `devtools::load_all()` first (segment_output.R
  and discharge_publish.R directly, pcic_routed_compare.R and both data-raw scripts through wb_cv_lib.R); the lib's
  `is_dev_package()` guard refuses otherwise. wb_cv_lib.R's globals collide with no name the data scripts set
  before or after it.
- `publish_forcing[["pcic_routed"]]` is `"PNWNAmet"`, equal to `routed_run$model`.
- Tests: the three fwapg tests in test-wet_segment_monthly.R pass against the local DB (12 expectations, 0 skipped,
  run from a scratch copy with NOT_CRAN=true). With both runs loaded, dropping the run filter from the main SELECT
  would trip the duplicate-row error in the first test, and the EXISTS guard is exercised by the 1900-1901 mock.
- `routed` added to both bundles' provenance: test-vignette_data.R checks names with `%in%`, so it is additive.
