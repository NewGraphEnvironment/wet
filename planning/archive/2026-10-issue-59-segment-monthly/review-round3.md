# Code review, round 3 (#59 branch against main, at eda4b15)

## Mechanism

The reader relies on physical properties of a store that it neither creates nor checks: where rows sit in
the heap, which indexes exist, what order the index keys sort in, and whether every source loaded. These
come from whoever loaded the store (wet_db_load() for the published table, the fwapg fork for the routed
table, crate and discharge_publish.R for the parts). Rounds 1 and 2 each picked a query by its logical
result and assumed the planner would find a cheap path to it. Round 1's `DISTINCT` assumed a small table.
Round 2's `EXISTS` assumed the matching rows were spread evenly through the heap, when wet_db_load()
appends parts in catalog order. The round-3 fix is sound because it no longer depends on heap order: it
depends on the primary key wet_db_load() always adds. So the question for every statement is which
loader-made property it depends on, and whether that property holds for every table the reader can be
handed.

## Enumeration

Every statement the new code issues, and every other place the mechanism reaches. Each verdict was
measured unless it says otherwise.

| # | Where | Depends on | Verdict |
|---|---|---|---|
| 1 | `wet_segment_pg()`: `dbExistsTable`, `obj_description(to_regclass())` | catalog only | Sound, constant cost. The subset warning needs the comment wet_db_load() writes. A table loaded some other way has no comment and gives no warning, but such a table is outside the contract. |
| 2 | `wet_segment_pg()`: presence walk (recursive CTE) | PK `(scenario, forcing, source, …)` and its NOT NULL columns | Sound. The PK has had these columns since the first commit of wet_db_load() (acde0a9; unchanged through cec3b20 and 10506bd), and it is added inside the creating transaction, so no table wet_db_load() made lacks it. On a 5.2M-row scratch copy (same key, same load order, ANALYZEd), the plan is an Index Only Scan on the PK with a `ROW(forcing, source) > ROW(...)` index condition, in 0.105 ms. NULLs: impossible under the PK. A table with no PK and a NULL `forcing` would end the walk early and give a false "no rows … load it" error. Without the index, each step is a full scan (pairs + 1 = 3 scans). Both cases need a table wet_db_load() did not create. Collation: both sides of the row comparison and the index use the column's collation, so the walk agrees with itself under `en_US.utf8` or `C`. It does trust the index order, so an index made stale by a glibc collation change could skip a pair. That fails loudly (false error) and would corrupt the PK anyway. |
| 2a | Same walk, after a reload that drops a source or renames a forcing | dead index entries until VACUUM | Transient cost, correct result. wet_db_load() runs DELETE and re-INSERT in one transaction, so the dropped pair's index entries remain, dead, until vacuum, and the walk must step over all of them. Measured on the scratch table (2.6M dead `pcic_routed` entries): the first walk took 594 ms, and the next 24 ms once `kill_prior_tuple` had marked them. At province scale that is roughly 10 s for the first call, then about 0.5 s, until autovacuum runs, which a delete that large triggers. A normal reload of the same sources is unaffected: each key's dead entry sorts just before its live one, so a step visits one dead tuple. Not a finding. |
| 3 | `wet_segment_pg()`: main query `scenario = … AND source IN … AND linear_feature_id IN (…)` | the `linear_feature_id` index wet_db_load() creates | Sound. The parts store `linear_feature_id` as INT32, checked on the live parts, so wet_db_load()'s template creates an `integer` column and the integer literals need no cross-type cast. |
| 4 | `wet_segment_fwapg()`: `to_regclass($1)` | catalog | Sound. |
| 5 | `wet_segment_fwapg()`: `linear_feature_id IN (…) AND month BETWEEN 1 AND 12 [AND watershed_group_code IN …]` | the fork's PK `(linear_feature_id, month)`; `::int` | Sound. The local table has PK `(linear_feature_id, month)`. It holds 40,524,444 rows, months 1–12, no NULL `q_m3s`, and no NULL `watershed_group_code`. Every row's group agrees with `fwa_stream_networks_sp`. The largest `linear_feature_id` is 868,144,671, below 2^31, so `::int` and `as.integer()` cannot overflow. Month 0 by `wet_segment_annual()` equals the old `HAVING count(q_m3s) = 12` rule under that PK. |
| 6 | `wet_segment_parts()`: `INSTALL httpfs; LOAD httpfs;` | the duckdb extension directory | Sound. Runs only for http(s) hrefs. INSTALL is a no-op once installed; on first use it needs the network, the same as `wet_station_daily()` and `wet_temp_daily()`. |
| 7 | `wet_segment_parts()`: `read_parquet([...], hive_partitioning = false) WHERE linear_feature_id IN … [AND watershed_group_code IN …]` | identical part schemas; non-NULL keys; parts sorted by group (pruning) | Sound. The live wet_balance and pcic_routed parts have identical schemas (`linear_feature_id` INT32, `watershed_group_code` string, `month` INT32, …). The null count is 0 for `linear_feature_id`, `watershed_group_code`, `month` and `period` across all 507 row groups. The keys come from the catalog, not the path. The cost without `groups` is documented (accepted). |
| 8 | `wet_segment_read()` duplicate guard | one forcing and one period per (scenario, source) | Holds for `historical`: the live catalog has one forcing per source (climr / PNWNAmet) and one period each. A future scenario with several GCM forcings or periods per source would stop with "more than one row" instead of returning values. That fails loudly and is outside this PR's scope (fwapg holds historical only, and nothing else is published). Not a finding. |
| 9 | `scripts/pcic_routed_lib.R` `routed_annual()` | `wet:::wet_segment_sources()` naming `routed_table` | Sound. The `stopifnot` ties the read to the table the fingerprint describes. Both callers pass integer IDs (`as.integer` in pcic_routed_compare.R:37 and segment_vignette_data.R:62), so the output types are unchanged. |
| 10 | `data-raw/monthly_vignette_data.R`: `wet_segment_monthly(NULL, …, catalog = parts)` | the parts `vd_verify()` checked before and after | Sound. The script's own earlier `LOAD httpfs` without INSTALL (line 137) predates this branch and runs on configured machines. |

Checks on the main session's enumeration in review-round2.md: its six entries are correct. It left out
entries 2a, 7's schema and null checks, 8, and 10, and it gave 2's dependence on the PK without saying
which tables lack it. None of these is a defect.

Outside the mechanism, noted rather than a finding. `scripts/discharge_publish.R:172-182` refuses a BUILD
when any file under `R/` or `scripts/` outside `publish_own` has changed since the segment report's commit.
`R/wet_segment_monthly.R`, `R/wet_flow_window.R` and `scripts/pcic_routed_lib.R` are not in `publish_own`.
So after this merges, the next rebuild of the published tree first needs `scripts/wb_output.R` and
`scripts/segment_output.R` rerun on the machine with the full run. The PUBLISH guard at line 69 likewise
refuses to upload any tree built before this change. The guard is deliberately over-inclusive, and its
comment says so, but nothing on the branch records this consequence.

Tests: both new files pass at eda4b15 under `NOT_CRAN=true` (segment reader: 10 blocks; window: 8; 0
failed, 0 errors, 0 skipped). The scratch schema `wet_scratch_r3_walk` was dropped.

## Clean

No issues found.
