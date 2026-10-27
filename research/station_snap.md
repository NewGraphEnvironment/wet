# Station snapping on the FWA: fwa_indexpoint() and what fwapg#41 changes

**Verified:** 2026-10-27 · **Issues:** #127 (from NewGraphEnvironment/fwapg#41, PR NewGraphEnvironment/fwapg#43) · **Produced by:** `scripts/station_snap_sweep.R` → `data/checks/station_snap_sweep_20260717.txt`, HYDAT 2026-07-17, fwapg commit b088b43's `db/migrations/202610240132__indexpoint_tiebreak.sql` (md5 `98d84a339d18f1eb11a917c60f9012ad`) tried in a rolled-back transaction; run logs `data/logs/127/station_snap_sweep_*` · **Status:** measured; the database is not migrated (that waits on the upstream review)

## The answer

Migrating to fwapg#41's `fwa_indexpoint()` moves one station's snap among the 490 swept: **08KD006** (Willow River above Hay Creek, a calibration station). It moves from segment 703862843 to 703862887. Its fundamental watershed changes from 8483126 to 7713002, and its stored upstream area from 2,863.8 to 2,861.1 km². It is accepted either way. The catchment cut at its snapped measure, which came back empty before, is 2,861.2 km² after, against HYDAT's 2,863 km². Every other station keeps its segment, watershed, area, acceptance and lake flag.

Two more things come back:
- **`fwa_locatealong()`** now finds a point at every candidate's measure. Before the migration it found none at 114 of the 2,304 candidates.
- **One more catchment:** 08LB050's (Mann Creek near Blackpool) raised an error before and is 287.5 km² after, on the same segment.

The 480 picked catchments that came back before still come back after, with the same areas. Measures on the same segment moved by at most 1.9 mm (median 0.03 mm).

## What changes, by cause

| cause | where it shows | effect on wet |
|---|---|---|
| An exact tie between two segments of one stream now goes to the segment starting at the shared vertex; before, which one came back was the query plan's row order | 76 tied streams at 64 stations. 36 of them now return the other segment. At 4 of them the old segment and measure were ones `fwa_locatealong()` could not place. 3 ties are on the stream a station is snapped to. | 08KD006's snap moves. 08EC013 and 08LB050 are tied on their picked stream but already returned the segment the new rule picks. |
| The measure comes from the geometry's m, and the measure consumers accept a measure equal to the top of a stream's last segment | 110 candidates, all on the top segment of their stream. The old measure ran past that segment's top by up to 1.1 mm, or sat at it, and `fwa_locatealong()` returned nothing. | None: none of the 110 is a station's pick. |
| `FWA_SliceWatershedAtPoint` keeps its slice fraction in [0, 1] | 08LB050's catchment: `line_interpolate_point: 2nd arg isn't within [0,1]` before, 287.5 km² after | The vignette map path only (`scripts/vignette_map_lib.R`); 08LB050 is a test station. |
| The outer order is the raw distance and then the segment id, not the distance rounded to 3 decimals | 0 stations whose 5 returned streams changed | None. |

## What the migration does not fix

After the migration, `fwa_watershedatmeasure()` still returns nothing at 5 picked positions and raises an error at 3. All 8 behave the same way before. Their causes are unresolved; the migration does not touch them.

| station | set | accepted | gross km² | result |
|---|---|---|---|---|
| 07GC001 | test | yes | 2,403.0 | `more than one row returned by a subquery used as an expression` (upstream crosses into Alberta) |
| 08HF011 | test | yes | 25.0 | same error |
| 08MH141 | calibration | yes | 49.1 | same error |
| 08DA011 | test | no | 0.3 | no rows |
| 08HA066 | test | no | — | no rows |
| 08HA067 | test | no | 2.7 | no rows |
| 08NE021 | test | no | 1.0 | no rows |
| 08OA003 | calibration | yes | 0.6 | no rows |

Two of the eight, 08MH141 and 08OA003, are accepted calibration stations. wet's water balance does not cut catchments at the measure: it takes each gauge's fundamental watershed from the snap and sums upstream over FWA codes (`wet_upstream_sums()`). So these failures reach only a map drawn by `vignette_map_lib.R`, and none of the vignette stations is among them.

## The base the trial ran on

The local fwapg the trial ran on still has the `exbc` branch in `fwa_watershedatmeasure()`, which adds area outside BC from hydrosheds and NHD. fwapg's migration `202610131654__watershedatmeasure_drop_exbc` removes that branch and is not applied here. 30 picked positions have an upstream border crossing, where that branch applies. None of them is among the catchments that changed. So the migration's effect measured here does not hinge on the base, but a database that has both migrations has not been swept.

## What a migration would mean for wet's outputs

- **The station table:** rerunning `scripts/wb_stations.R` on a migrated database would change 08KD006's `linear_feature_id`, `watershed_feature_id` and `upstream_area_km2`, and nothing else. The before run reproduces `data/wb/stations_20260717.rds` at all 489 of its stations, so the comparison is not mixed up with changes to the database since July.
- **Rebuilding the stations file:** `research/water_balance_method.md` ("Reproducing #15 and #18") notes that before the migration, which segment of a tie came back depended on row order, and names 08EC013 and 08KD006. The migration makes it fixed: 08KD006 goes to the upper segment, and 08EC013 already returns it.
- **The fit:** not rerun for this (decided 2026-10-27; #133 closed). The shipped stations file and fit stay as they are, and the next HYDAT release's refit, which reruns `wb_stations.R` and the scoring chain anyway, picks up 08KD006's new snap. Until then, a rerun of `wb_stations.R` on a migrated database does not reproduce `stations_20260717.rds` at that one row; this is the known difference.

## How it is checked

`scripts/station_snap_sweep.R` sweeps once on the database as it is and once with the migration applied by `wet:::wet_pg_trial()`, each on its own connection. `wet_pg_trial()` blanks the migration's own `BEGIN;`/`COMMIT;` pair, refuses any other transaction control, and checks that the session still holds the transaction it opened. After the rollback, a third connection confirms the old signature is back.

The live tests in `tests/testthat/test-wet_station_snap.R` pin 08KD006, 07FA007 (stream heads), 07EA001 (a tie on a candidate stream) and 08LB050. They skip on a database without the migration and run against it under `WET_FWAPG_TRIAL`. Under `WET_FWAPG_CURRENT=true` they fail instead of skipping, and a gate test reads the database's committed state, so a trial cannot satisfy it.
