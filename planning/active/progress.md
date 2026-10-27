# Progress — wet_station_snap(): measure the effect of fwapg's fwa_indexpoint() rework (#127)

## Session 2026-10-27

- Plan-mode exploration — phases approved by user
- Created branch `127-wet-station-snap-measure-the-effect-of-f` off main (fa9b31f)
- Scaffolded PWF baseline from issue #127 with approved phases
- Next: start Phase 1
- Phase 1: `wet_pg_trial()` / `wet_pg_trial_sql()`. Probed RPostgres 1.4.10 first: inside `dbBegin()`, `dbExecute(immediate = TRUE)` runs a multi-statement string, a `SAVEPOINT` recovers from an error, and `dbRollback()` undoes it all. Unit tests 15 pass; mutation (refusal disabled: >10 fail; pair not blanked: 2 fail). fwapg b088b43's migration (md5 98d84a339d18f1eb11a917c60f9012ad) passes the strip. A live trial on m1 took 0.03 s: new signature inside, 08KD006 on blk 356360570 -> 703862887, locatealong 1 row, watershedatmeasure 2861.2 km2; after `dbRollback()` a separate psql session reads the old signature.
