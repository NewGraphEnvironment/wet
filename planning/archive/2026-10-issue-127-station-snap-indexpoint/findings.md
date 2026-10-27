# Findings — wet_station_snap(): measure the effect of fwapg's fwa_indexpoint() rework (#127)

## Issue context

`wet_station_snap()` calls `whse_basemapping.fwa_indexpoint(pt, tolerance, num_features)` directly (`R/wet_station_snap.R:58`), and downstream work uses `fwa_watershedatmeasure()` at the snapped measure (e.g. `data-raw/station_vignette_map.R`). So wet is the package the fwapg change below reaches directly. A gauge on a shared vertex will get the upper segment, its measure moves by a few mm at most, and an upstream watershed that came back empty because the old measure fell between two segments will now come back. `geom` is not selected, so the PointZM change does not reach wet.

## What changes in fwapg

NewGraphEnvironment/fwapg#41 (PR NewGraphEnvironment/fwapg#43, offered upstream as smnorris/fwapg#201) reworks one migration. None of it reaches this package until the database it connects to is migrated.

- `fwa_indexpoint()`:
  - An exact distance tie between two segments of one stream goes to the segment **starting** at the shared vertex, then `linear_feature_id`. Before, the plan picked.
  - The measure is the stream geometry's m, not `downstream_route_measure + fraction * length_metre` (up to ~5 mm apart).
  - `geom` is PointZM.
  - Optional `include_disconnected` / `include_null_localcodes` filters run before the per-stream pick.
  - A point on a watershed-group boundary no longer errors.
- `FWA_LocateAlong`, `FWA_UpstreamTrace`, `FWA_DownstreamTrace`, `FWA_WatershedHex` and `FWA_WatershedStream` take the highest segment whose measure range, closed at the top, holds the measure. A measure at a stream's head now works. `FWA_UpstreamBorderCrossings` and `FWA_SliceWatershedAtPoint` no longer error near a segment's top.

Measured on a loaded fwapg:
- `FWA_WatershedAtMeasure` failed to place 156 of 1,190 random-point snaps (5 streams each); after the change, none.
- `FWA_LocateAlong` misses fell from 1,627 to 34 of 11,182 indexed measures.
- Nothing that returned rows before changed.

## Work here

1. **Sweep, before and after.** Run this package's own path over its real inputs (listed below) and count three things: snapped positions where `FWA_LocateAlong` or `FWA_WatershedAtMeasure` returns nothing; points tied on two segments of one stream; calls that error. Run once against the current database, then against the migration applied inside a transaction that is rolled back (`BEGIN`, the migration body without its own `BEGIN`/`COMMIT`, the sweep, `ROLLBACK`). That gives both numbers without migrating a shared database. Record them in `research/`.
   **This issue does not migrate the database.** The migration file carries its own `BEGIN;` and `COMMIT;`, and left in place that `COMMIT;` commits the outer transaction, migrating the shared database for everyone. Strip both, and check with `grep -nE '^(BEGIN|COMMIT|ROLLBACK);' <body file>` (expect no output) before running. Migrating for real waits on the upstream review (NewGraphEnvironment/fwapg#41).
2. **Pin what the sweep finds as live-database tests**, skipped without a connection, as the package's other live tests are. Each one is shown to fail before the change and pass after.
3. **Gate on the database, without hiding a stale one.** Tests that need the new behaviour check the database has it: `pg_get_function_arguments('whse_basemapping.fwa_indexpoint'::regproc)` names `include_disconnected`. Where it doesn't, they skip and say which migration is missing. One test *fails* instead of skipping when an environment variable says the database should be current, so a stale database cannot turn the suite green.

Inputs for the sweep: the stations `wet_station_snap()` is run on (the station sets behind `data/checks/stations_wb*.txt`), and the snapped position fed to `fwa_watershedatmeasure()`. Case to pin, from the fwapg tests: WSC 08KD006 (Willow River above Hay Creek) snaps to segment 703862887, and `fwa_watershedatmeasure()` at its measure returns about 2,861 km². Before the change it can return nothing.



## Planning probes (2026-10-27, m1 fwapg, PostgreSQL 17.5)

- 08KD006 at (-122.373062133789, 54.0455589294434), fwa_indexpoint(pt, 1000, 5) today:
  703862918 blk 356302336 m 66.223 d 9.432 (locatealong 1; watershedatmeasure 1 row, 3 km2)
  703862843 blk 356360570 m 14040.005812552621 d 67.564 (locatealong 0; watershedatmeasure 0 rows) <- Willow; 703862887 starts at 14040.0058125527
  703863073 blk 355999967 m 40.408 d 140.044 (watershedatmeasure ERROR more than one row returned by a subquery)
  703862675 blk 356239203 m 661.634 d 335.806 (watershedatmeasure 0 rows)
  703862891 blk 356033213 m 0 d 372.500 (watershedatmeasure ERROR more than one row returned by a subquery)
- m1 fwa_watershedatmeasure still carries the exbc branch: fwapg#200's migration 202610131654 not applied; no fwapg.db_version table.
- fwapg PR #43 head b088b43a628690b315100785b23a26dbaa54505e; migration db/migrations/202610240132__indexpoint_tiebreak.sql, 1369 lines, BEGIN; line 1, COMMIT; line 1369; plpgsql bare BEGIN/END at column 0.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `WET_FWAPG_TRIAL` relative path: `file(con, "r"): cannot open the connection` | tests run from tests/testthat; helper refuses a missing file and asks for an absolute path |
| `wet_pg_trial()` deferring to its caller's frame rolled back inside `local_fwapg_indexpoint()` before the test ran | pass `env = env` from the helper |

## Note on the planning probe (plan review G10)

The two 08KD006 candidates whose `fwa_watershedatmeasure()` errors are not the picked one; the sweep calls it only at picked positions, which is wet's path (`vignette_map_lib.R`). The picked-position error count is real anyway: 4 before, 3 after.
