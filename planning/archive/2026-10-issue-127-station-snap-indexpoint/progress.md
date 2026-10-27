# Progress — wet_station_snap(): measure the effect of fwapg's fwa_indexpoint() rework (#127)

## Session 2026-10-27

- Plan-mode exploration — phases approved by user
- Created branch `127-wet-station-snap-measure-the-effect-of-f` off main (fa9b31f)
- Scaffolded PWF baseline from issue #127 with approved phases
- Next: start Phase 1
- Phase 1: `wet_pg_trial()` / `wet_pg_trial_sql()`. Probed RPostgres 1.4.10 first: inside `dbBegin()`, `dbExecute(immediate = TRUE)` runs a multi-statement string, a `SAVEPOINT` recovers from an error, and `dbRollback()` undoes it all. Unit tests 15 pass; mutation (refusal disabled: >10 fail; pair not blanked: 2 fail). fwapg b088b43's migration (md5 98d84a339d18f1eb11a917c60f9012ad) passes the strip. A live trial on m1 took 0.03 s: new signature inside, 08KD006 on blk 356360570 -> 703862887, locatealong 1 row, watershedatmeasure 2861.2 km2; after `dbRollback()` a separate psql session reads the old signature.
- Plan review (Plan agent, spawned 20:47 UTC, delivered ~20:58 UTC): no blocker; 12 gaps and acceptance points folded in (`review-plan.md`). The first full sweep (started 20:53 UTC) was stopped to take them; the database read the old signature after.
- Phase 2 run: `data/logs/127/station_snap_sweep_20261027T2102Z.log`, 21:02-21:41 UTC (38 min), from a frozen copy of 3a967f0's script, fwapg b088b43's migration (md5 98d84a339d18f1eb11a917c60f9012ad). Report `data/checks/station_snap_sweep_20260717.txt`. 490 stations (352 calibration, 137 test, 08EE003). Before run equals the stations file at all 489. Only 08KD006's snap moves; fwa_locatealong() empty at 114 candidates before, 0 after (110 at stream heads, measure past the top by up to 1.1 mm; 4 ties); picked catchments empty 6 -> 5, errors 4 -> 3 (08KD006 and 08LB050 come back). 64 stations tied on 76 streams; 3 on the picked stream.
- Phase 3: pinned 08KD006 (tie on the picked stream), 07FA007 (stream heads), 07EA001 (tie on a candidate stream), 08LB050 (catchment errored). Evidence, `NOT_CRAN=true`, per test (fail/err/skip/pass):
  - no variables: gate skip; four pins skip
  - `WET_FWAPG_CURRENT=true`: gate fail 1; 08KD006 fail 4; head fail 2; tie fail 2; 08LB050 error
  - `WET_FWAPG_TRIAL=<abs path>`: gate skip; pins pass 6, 3, 2, 2
  - both: gate fail 1 (the trial cannot satisfy it); pins pass
  - `WET_FWAPG_CURRENT=true WET_PGPORT=1`: gate error (not a skip); pins skip
  - the database read the old signature after each run. A relative `WET_FWAPG_TRIAL` failed (tests run from tests/testthat): the helper now refuses it by name.
- Full suite (`data/logs/127/devtools_test_20261027T2145Z.log`, ~2 min): 1542 pass, 5 skip, 2 fail. Both failures are the live Buck Creek real-time test (`test-wet_station_daily.R:293`): ECCC real-time has nothing after 2026-10-01, so "realtime" is absent and the record ends 16 days short. Untouched by this branch; external.
- `/code-check branch`, rounds spawned 21:46, 21:53, 21:59 UTC (findings in `review-round{1,2,3}.md`):

  | Round | Findings | Fixed | Accepted | Inside previous fix? |
  |-------|----------|-------|----------|----------------------|
  | 1 | 2 | 2 | 0 | — (one in the plan-review regex widening) |
  | 2 | 1 | 1 | 0 | y (PCRE match limit; round 1 put the comment class between words) |
  | 3 | 2 + 1 lexer gap | 3 | 1 (DO-wrap not taken) | y (`\r` ends a `--` comment; in the comment class) |

  Ended by enumeration (round 3): the statements that end an explicit block in PostgreSQL 17 are ABORT, COMMIT, END, ROLLBACK, PREPARE TRANSACTION (TransactionStmt and TransactionStmtLegacy); COMMIT/ROLLBACK PREPARED and COMMIT in DO/CALL raise instead. Every statement starts at input start or after `;`, both anchored. The comment and whitespace grammar was compared with the server's lexer; its one difference (`\r`) is fixed. Effects a rollback cannot undo are a different class with no finite list: the named calls are refused and CLAUDE.md and the function header say what is not caught. Not taken: wrapping the body in `DO ... EXECUTE` so the server refuses transaction statements itself (measured by round 3); the enumeration already covers them, and it would lose line numbers in errors.
  Agents this task: plan review + 3 code-check rounds = 4.
- Reproducibility: a second full run from 3a967f0's script (`data/logs/127/station_snap_sweep_rerun_20261027T2144Z.log`, 21:44-22:24 UTC) wrote a report byte-identical to `data/checks/station_snap_sweep_20260717.txt` (`cmp`). The database read the old signature after. A 2-station smoke of the current script (after rounds 1-3) gives the same lines for 08KD006 and 08LB050 and the same migration md5.
