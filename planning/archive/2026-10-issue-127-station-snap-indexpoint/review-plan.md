# Plan review (#127), Plan agent, delivered 2026-10-27

Findings as returned (condensed), with what was done.

| id | finding | action |
|----|---------|--------|
| Q1 | migration applies via RPostgres 1.4.10 `immediate = TRUE`; no pg_depend dependants on fwa_indexpoint; return types match | none: confirmed by the live trial too |
| Q2 | regex sound for this file; bypasses `COMMIT\n;`, `COMMIT -- c\n;`, `/* c */ COMMIT;`; xid backstop misses a smuggled `COMMIT … BEGIN` | regex allows whitespace and comments around the keyword; backstop asserts the SAME xid as at dbBegin() (G4) |
| G1 | gate fails toward pass: local_fwapg() skips (CI, NOT_CRAN, no connection) before WET_FWAPG_CURRENT is read; only "true" honoured | gate test connects directly with no skip helpers when the var is set, fails if it cannot; accepts true/TRUE/1 |
| G2 | WET_FWAPG_TRIAL satisfies the gate on a stale db | gate test reads the committed state on its own connection, never the trial |
| G3 | wet_pg_trial() hands back an open migrated transaction | wet_pg_trial(conn, file, env) defers the rollback itself |
| G5 | before run needs a transaction; use separate connections | before and after on separate connections, each in its own transaction |
| G6 | an error outside a savepoint aborts the trial and inflates counts | refuse the report if any captured message is "current transaction is aborted" |
| G7 | wet_station_snap() all-at-once | already falls back to per station |
| G8 | no statement timeout; 10BE001 takes 11 s | SET LOCAL statement_timeout in both runs; a timeout counts as an error |
| G9 | tie query must mirror the candidate set (edge_type != 6010), raw ST_Distance, per blue_line_key; report picked-stream ties separately | done |
| G10 | 08KD006's erroring calls are on unpicked candidates | kept picked-only (wet's path); findings note corrected |
| G11 | vignette station 08EE003 not in the sets | vignette stations 08EE013/08EE003/08EE004 added from HYDAT |
| G12 | outer ORDER BY now on unrounded distance + id, so the 5 surviving streams can change | report counts stations whose candidate stream set changed |
| A1 | exbc base is a state production will not have; cross-border stations | picked positions carry FWA_UpstreamBorderCrossings() before; report flags them |
| A2 | old tie choice is planner row order | noted in research |
| A3 | expect ~1 tie-driven move | noted |
| AC1 | the 08KD006 pin must take its measure from fwa_indexpoint() in the same connection; hard-code coordinates | done |
| AC2 | check the before run reproduces stations_20260717.rds | report counts disagreements |
| AC3 | live smoke test of wet_pg_trial() (second connection sees the old state) | added to test-wet_pg_trial.R |
| AC4 | fail-before evidence with NOT_CRAN=true and SKIP counts | done in Phase 3 |
| AC5 | issue's literal grep in the report | done |
| O1 | plan text behind the code | task_plan updated |
| S1 | wet_pg_trial ships, internal | noted in plan |
| S2 | report name lacks the release suffix | wb_report("station_snap_sweep", release) |
| S3 | machine label in setup notes | dropped from task_plan setup notes |
