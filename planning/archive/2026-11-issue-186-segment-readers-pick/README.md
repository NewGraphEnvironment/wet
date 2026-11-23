## Outcome

`wet_segment_monthly()` and `wet_segment_daily()` return `pick` as a logical fifth column from the published parts, Postgres and (as `NA`) fwapg (#177). The two publish guards now share one list of files no table is built from, `scripts/discharge_publish_own.R`, which gains the readers, itself and eight chinook-site and departure files (#171). Replaying the guards from the segment report's commit showed ten files in neither old list; eight were non-inputs, and `R/wet_station_snap.R` (roxygen text only) and `scripts/pcic_routed_lib.R` (new functions only) are real inputs that changed without moving a table, so they stay off the list and the guards still name them. `/code-check branch`: three rounds, one fragile test finding (fixed), no defect inside a fix.

## Owed

- On the machine with the full province run: `scripts/segment_output.R` first (the guards still list `R/wet_station_snap.R` and `scripts/pcic_routed_lib.R`, real inputs changed without moving a table), then `scripts/segment_daily_output.R` (about 132 min), then `WET_FWAPG_COMMIT=5d50cc1 scripts/discharge_publish.R` BUILD; expect every part byte-identical to the live manifest and no upload. Commit the reports it leaves modified.
- Reply on `knowledge#42` (ours: NewGraphEnvironment) that the readers return `pick`, after the merge.
