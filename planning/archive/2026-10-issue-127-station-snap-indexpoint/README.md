## Outcome

Measured what fwapg#41's `fwa_indexpoint()` rework (PR fwapg#43, commit b088b43, migration `202610240132__indexpoint_tiebreak.sql`) changes on wet's station-snap path, without migrating the database. `wet:::wet_pg_trial()` runs a migration inside a transaction rolled back when the caller's frame exits. Before anything runs, it refuses the migration's own transaction control and calls whose effect a rollback cannot undo; afterwards it checks the transaction id is unchanged. `scripts/station_snap_sweep.R` sweeps the 352 calibration stations, the 137 test stations and 08EE003, once on the database as it is and once inside a trial. Four cases are pinned as live tests: they skip on an older database, pass under `WET_FWAPG_TRIAL`, and fail under `WET_FWAPG_CURRENT=true`, whose gate test reads the committed state. The findings are in [`research/station_snap.md`](../../../research/station_snap.md).

Learned along the way:
- The trial guard is a regex model of PostgreSQL's lexer. The plan review and three code-check rounds found three places where that model differed from the server's: split words, the terminator, and PCRE giving up. The loop ended on an enumeration of the statements that end a transaction block.
- Effects outside the transaction (dblink, `COPY ... PROGRAM`, sequences) are a separate class with no finite list. The named calls are refused, and the docs say what is not caught.

## Measurement

From `data/checks/station_snap_sweep_20260717.txt`, HYDAT 2026-07-17, 490 stations:
- **Snaps:** only 08KD006's moves: segment 703862843 → 703862887, watershed 8483126 → 7713002, stored upstream area 2,863.8 → 2,861.1 km², accepted both ways.
- **`fwa_locatealong()`:** it found no point at 114 of 2,304 candidate measures before and at none after. 110 of those are at stream heads, where the old measure ran past the top segment by up to 1.1 mm; 4 are exact ties.
- **Picked catchments:** empty 6 → 5, erroring 4 → 3. 08KD006's comes back (empty → 2,861.2 km², against 2,863 km² gross), and so does 08LB050's (error → 287.5 km²). The 480 catchments that came back before keep the same areas.
- **Ties:** 76 streams tied at 64 stations, 36 of which return the other segment after; 3 of the ties are on a picked stream.
- **Measures:** on the same segment they moved by at most 1.86 mm (median 0.03 mm).
- **Stations file:** the before run reproduces `stations_20260717.rds` at all 489 of its stations.
- **Reproducibility:** a second full run gives a byte-identical report. Each run takes 38–40 min, almost all of it in `fwa_watershedatmeasure()` (about 2 s per station).

What changed because of these:
- The owed decision below is about one station, not a table.
- The wrong turn: the first full sweep (started 20:53 UTC) was stopped to fold in the plan review, then rerun.
- The planning probe's claim that 08KD006's erroring calls made "calls that error" a real count rested on unpicked candidates. The picked count is real anyway: 4 before, 3 after.

## Evidence

`data/logs/127/station_snap_sweep_*`, `data/logs/127/devtools_test_*`

## Owed

- When fwapg#41 merges and the database is migrated for real: run the tests with `WET_FWAPG_CURRENT=true`, then rerun `wb_stations.R` and the fit chain it stales (the user decided 2026-10-27 that it will be rerun: 08KD006's watershed moves 8483126 -> 7713002). Tracked in #133.

Closed by: PR (this branch, `127-wet-station-snap-measure-the-effect-of-f`)
