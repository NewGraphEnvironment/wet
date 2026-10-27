# Task: wet_station_snap(): measure the effect of fwapg's fwa_indexpoint() rework, and pin it in live tests (#127)

`wet_station_snap()` calls `whse_basemapping.fwa_indexpoint(pt, tolerance, num_features)` directly (`R/wet_station_snap.R:58`), and downstream work uses `fwa_watershedatmeasure()` at the snapped measure (e.g. `data-raw/station_vignette_map.R`). So wet is the package the fwapg change below reaches directly. A gauge on a shared vertex will get the upper segment, its measure moves by a few mm at most, and an upstream watershed that came back empty because the old measure fell between two segments will now come back. `geom` is not selected, so the PointZM change does not reach wet.

## Context

fwapg#41 (PR fwapg#43, head `b088b43`) replaces `fwa_indexpoint()`. The changes: an exact tie between two segments of one stream goes to the upper segment, the measure comes from the geometry's m, there are new filter arguments, and a closed-top segment rule applies in `FWA_LocateAlong` and the traces. `wet_station_snap()` calls `fwa_indexpoint()` directly (`R/wet_station_snap.R:58`). `scripts/vignette_map_lib.R:30-38` feeds the snapped measure to `fwa_watershedatmeasure()`. This work measures what the migration changes on wet's own inputs without migrating the shared database. It records the result and pins it in live tests that are gated on the database, and the gate cannot let a stale database turn the suite green.

Measured during planning, on the local fwapg (PostgreSQL 17.5):
- The old signature is still installed (`point, tolerance, num_features`); the database has no `fwapg.db_version`.
- m1's `fwa_watershedatmeasure()` still has the `exbc` branch, so fwapg main's `202610131654__watershedatmeasure_drop_exbc` (fwapg#200) is not applied. The trial applies only #41's migration. That isolates its effect, and the report states the base.
- **08KD006** (Willow River above Hay Creek, 2,863 km² gross): today the nearest candidate on its stream is segment 703862843, at measure 14040.0058125526. That is a hair below the start of 703862887 (…27), so `fwa_locatealong()` returns 0 rows and `fwa_watershedatmeasure()` returns 0 rows. Two of its other four candidates make `fwa_watershedatmeasure()` raise `more than one row returned by a subquery`. So "calls that error" is a real count here, and errors must be caught one call at a time.
- The migration file (1,369 lines) has `BEGIN;` on line 1 and `COMMIT;` on line 1369. Its plpgsql bodies have bare `BEGIN`/`END` lines with no semicolon.
- Station sets: `data/wb/stations_20260717.rds` holds 352 calibration and 137 test stations, 08KD006 among them. Only HYDAT 20260717 is cached here. Plus the vignette maps' 08EE003, which neither set holds (plan review G11).

## Decided at the gate (proposed by Claude, approved by the user 2026-10-27)

- **Sweep inputs:** the shipped release's 352 calibration and 137 test stations, from `stations_20260717.rds`. The 20251014 set is #15's frozen record and is not cached here, so it is not swept.
- **Trial base:** only #41's migration, applied on top of the local fwapg as it is. fwapg#200's migration is not applied with it, and the report records the base.
- **Scope of "this package's path":** beyond the issue's three counts, the sweep also diffs `wet_station_snap()`'s own output before and after (segment, watershed, area, accepted, lake). That diff answers whether migrating would change the station table, and through it the fit.
- **Database is never migrated.** The migration goes inside `BEGIN … ROLLBACK`. After the rollback, the run asserts that the signature is the old one again.

## Phase 1: Trial a migration without committing it
- [x] `R/wet_pg_trial.R` (internal): `wet_pg_trial_sql(sql)` strips the leading `BEGIN;` line and the trailing `COMMIT;` line. It then refuses any remaining `^\s*(BEGIN|COMMIT|ROLLBACK|END|START\s+TRANSACTION)\b[^;\n]*;` (case-insensitive), which bare plpgsql `BEGIN`/`END` lines pass. `wet_pg_trial(conn, file, env)` runs `dbBegin()`, defers the rollback to `env`, records `pg_current_xact_id()`, runs `dbExecute(immediate = TRUE)`, then checks the session still holds that same transaction id. Internal, shipped because scripts and tests both use it. The regex also allows whitespace and comments around the keyword (plan review Q2).
- [x] `tests/testthat/test-wet_pg_trial.R`: unit tests without a database. They cover stripping, refusal of a nested `COMMIT;`, `commit ;`, `ROLLBACK;` and `END;`, and acceptance of plpgsql `BEGIN`/`END` lines.

## Phase 2: Sweep, before and after
- [x] `scripts/station_snap_sweep.R <migration file>` (reworked after the plan review, `review-plan.md`: separate connections, statement timeout, vignette stations, stream-set and border flags, stations-file check, issue's grep, report `wb_report("station_snap_sweep", release)`). It reads the stations rds and connects through `WET_PG*`. Then, once on the current database and once inside `wet_pg_trial()`, it does the following. Each call runs under its own `SAVEPOINT`, so an error is counted and the run goes on:
  - every candidate `fwa_indexpoint(pt, 1000, 5)`, and `fwa_locatealong()` at each candidate's measure (counted empty);
  - ties: stations with two segments of one `blue_line_key` within 1e-6 m of the minimum distance;
  - `wet_station_snap()` on all stations, plus each picked position's `fwa_locatealong()` and `fwa_watershedatmeasure()`, counted empty or erroring, with the area set against the gross area;
  - calls that error, by function.
  It then rolls back and asserts that the old signature is back. It diffs the two `wet_station_snap()` outputs and writes `data/checks/station_snap_sweep_20260717.txt` (tracked), which records the migration's md5 and the fwapg commit it came from (`WET_FWAPG_MIGRATION_COMMIT`).
- [x] Run it on the local fwapg with fwapg `b088b43`'s migration. Log to `data/logs/127/`.
- [x] `research/station_snap.md` (new topic file, with its `research/README.md` row): what changes for wet, the counts before and after, which stations' snaps move and why, and the base. Fix the comment in `wet_snap_pick()` that already credits `fwa_indexpoint()` with the tie rule, which holds only once the database is migrated.

## Phase 3: Gate and pin in live tests
- [x] `helper-fwapg.R`: add `local_fwapg_indexpoint()`. It calls `local_fwapg()`. If `WET_FWAPG_TRIAL` names a migration file, it applies the file with `wet_pg_trial()` and defers a rollback. If `pg_get_function_arguments('whse_basemapping.fwa_indexpoint'::regproc)` then lacks `include_disconnected`, it skips with a message naming `202610240132__indexpoint_tiebreak` (fwapg#41), unless `WET_FWAPG_CURRENT=true`, in which case it runs on so the assertions fail.
- [x] One gate test fails, rather than skips, when `WET_FWAPG_CURRENT=true` and the function is old.
- [x] Pin 08KD006: the snap is 703862887; `fwa_locatealong()` at the snapped measure returns one point; `fwa_watershedatmeasure()` gives about 2,861 km², checked with an absolute tolerance. Also pin up to three cases the sweep turns up, such as a station whose snap moves, or an empty or erroring call that comes back.
- [x] Show each pinned test failing before and passing after: `WET_FWAPG_CURRENT=true` on the current database (fails), then `WET_FWAPG_TRIAL=<file>` (passes), with the output in `progress.md`.

## Phase 4: Docs and wrap
- [x] CLAUDE.md: the sweep script, `WET_FWAPG_TRIAL` and `WET_FWAPG_CURRENT`.
- [x] Run the full `devtools::test()` and `lintr`, then `/code-check branch`, then `/planning-archive` and `/gh-pr-push`.

## Owed at the end (reported, done after merge)
- [ ] When fwapg#41 merges and the database is migrated for real: run the tests with `WET_FWAPG_CURRENT=true`. (`wb_stations.R` is not rerun for this: the user decided 2026-10-27 to leave the shipped stations file and fit, and let the next HYDAT release's refit pick up 08KD006's new snap; #133 closed.)

## Validation
- [x] Tests pass (no-DB unit tests; live tests skip with the reason on the old DB; fail under `WET_FWAPG_CURRENT=true`; pass under `WET_FWAPG_TRIAL`)
- [x] `/code-check` clean
- [x] PWF checkboxes match landed work
- [x] `/planning-archive` on completion

Verification: the sweep's post-rollback signature check, plus a separate `psql` query after the run, proves the shared database is unmigrated. The fail-before and pass-after runs prove that each pinned test discriminates. The report is regenerated byte-identically on a second run, up to timing lines, which it does not carry.

