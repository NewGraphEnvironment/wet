# Code review, round 2 (#59 branch against main, at e2a937c)

## Findings

- **[severity: fragile]** R/wet_segment_monthly.R:184-188 (`wet_segment_pg()`, the round-1 fix) — the
  `EXISTS (SELECT 1 ... WHERE scenario = ... AND source = ...)` check stops at the first matching row only
  if that row comes early, and for `pcic_routed` it comes late. `wet_db_load()` appends parts in catalog
  order, and the live catalog lists the 23 `wet_balance` parts (forcing `climr`) before the 20 `pcic_routed`
  parts (forcing `PNWNAmet`), so every balance row sits ahead of the first routed row in the heap. The
  planner assumes matching rows are spread evenly, prices a LIMIT-1 seq scan as nearly free, and then reads
  every balance row before it finds a routed one. The primary key does not help: `forcing` sits between
  `scenario` and `source`, and under the database's `en_US.utf8` collation `climr` sorts before `PNWNAmet`, so
  an index walk would also pass every balance entry first. The check runs whenever a requested segment has no
  routed row in the result. That is the common case the fix exists for: segments outside PCIC's routed
  coverage (the Liard, Yukon and Alsek headwaters, the Hay, the Skagit, outer islands), a `groups` value that
  does not hold the segment, or an ID not on the network. So `wet_segment_monthly(conn, <Liard segment>)`
  still scans roughly the balance half of the 102.8M-row table, about 58M rows. Only the axis has changed
  from round 1: a missing balance row finds its source on the first heap page, but a missing routed row
  scans. Measured on a temp table with the same key, indexes and load order (10.4M balance rows, then 9.1M
  routed): `EXISTS ... source = 'pcic_routed'` took 1,075 ms as a seq scan, with 10,400,000 rows removed by
  the filter, against 0.03 ms for `wet_balance`. The province table is about 5x larger and colder. The
  fixture tests cannot show this (26 rows). One fix that keeps the error: a loose index scan over the
  primary key, walking the scenario's distinct `forcing` values (a recursive CTE of `min(forcing) ... forcing
  > prev`) and probing `(scenario, forcing, source)` for each. On the same temp table it took 1.3 ms and gave
  the same answer. Recording the loaded sources in the table comment at load time would also work.

- **[severity: bug]** R/wet_segment_monthly.R:216 (`wet_segment_parts()`) — `DBI::dbExecute(duck, "LOAD httpfs")`
  without `INSTALL httpfs`. This is the default path of the new export (`conn = NULL`, the live manifest's
  `https://` hrefs, the README/vignette/example call), and it fails on any machine where httpfs has never
  been installed into duckdb's extension directory. Autoinstall is off in duckdb-r 1.5.2
  (`autoinstall_known_extensions` = FALSE). Reproduced with an empty HOME (same libraries):
  `wet_segment_monthly(NULL, 17094080, groups = "BULK")` errors with `IO Error: Extension ".../httpfs.duckdb_extension"
  not found ... Install it first using "INSTALL httpfs"`. It works here only because this machine installed
  httpfs earlier. The package's other exported readers use `"INSTALL httpfs; LOAD httpfs;"`
  (R/wet_station_daily.R:176, R/wet_temp_daily.R:112). The data-raw scripts and the segment-discharge
  vignette chunk have the same `LOAD`-only line, but those predate this branch and run on configured
  machines; this is the first exported function to ship it.

## Checked and found sound

- Round-1 fix, logic: the check runs only for a requested source absent from the main query's result. A
  loaded source whose requested segments are all missing returns 13 NA rows each, with no error. An unloaded
  scenario or source stops with the wet_db_load() hint. A subset-loaded table warns, then reads missing rows
  as NA. Both branches are reached by tests: `groups = "BULK"` (empty result, EXISTS true, NA rows) and
  `scenario = "ssp585"` (EXISTS false, error). Removing the loop would fail the ssp585 expectation, and an
  always-false check would fail the BULK one.
- The main Postgres query filters on `linear_feature_id IN (...)`, which the `linear_feature_id` index serves.
  A probe on the temp table chose the PK index for an absent scenario (0.1 ms), so the error path is cheap.
- Both new test files pass under `NOT_CRAN=true` against the source tree (segment reader 10 blocks, window
  8 blocks, 0 failed, 0 errors, 0 skipped, local fwapg present).
- Published parts carry `watershed_group_code` (checked on a live part with `hive_partitioning = false`), and
  so does fwapg's routed table, so the `groups` filter is valid on all three stores.
- `routed_annual()` resolves `wet:::wet_segment_sources()` after `load_all()` in all three callers.
  `scripts/pcic_routed_lib.R` and `R/wet_segment_monthly.R` are not among `score_files_for()`, so the branch
  does not stale any fit.
- `wet_flow_window()`: day lists for windows across 1 January and ending on 02-29 use a non-leap 2001/2002,
  zero-row input and `by = character()` work, and `wet_windows_check()` refuses a 02-29 start.
- The vignette's `wet_flow_window()` calls keep the per-station, per-window observed months (round-1 plan
  blocker 1) and `stopifnot(!anyNA(win))` still guards NA months.

## Disposition (main session)

1. Presence check still scanning (inside round 1's fix): confirmed on a 9.75M-row scratch table with the same key and load order. Plain EXISTS for pcic_routed 389 ms (seq scan, 5.2M rows removed); the suggested recursive CTE over forcing with an EXISTS per forcing 1,199 ms (the inner EXISTS took a seq scan, forcing being a parameter); per-forcing literal EXISTS also seq scans (894 ms; the planner expects an early match among few distinct values). Fixed with a walk of the key's distinct (forcing, source) pairs, `ORDER BY forcing, source LIMIT 1` seeks through a LATERAL: 1.2 ms, and 0.6 ms for an unloaded scenario. Guard proven: disabled, 1 test fails; restored, 45 pass.
2. `LOAD httpfs` without `INSTALL`: fixed as in wet_station_daily.R and wet_temp_daily.R.

Enumeration (the mechanism: a query whose cost depends on where rows sit or on an index the planner may not choose). Every statement the reader issues, R/wet_segment_monthly.R:
- `dbExistsTable` (catalog), `obj_description(to_regclass())` (catalog), fwapg `to_regclass()` (catalog): constant.
- published presence walk: one PK seek per (forcing, source) pair (measured above).
- published main query: `linear_feature_id IN (...)`, served by the `linear_feature_id` index wet_db_load() creates.
- fwapg main query: `linear_feature_id IN (...) AND month BETWEEN 1 AND 12`, served by the table's primary key `(linear_feature_id, month)`.
- duckdb `INSTALL httpfs; LOAD httpfs;`: once per call.
- parquet read per source: row-group pruning on `watershed_group_code`/`linear_feature_id` stats; its cost without `groups` is measured and documented (accepted).
