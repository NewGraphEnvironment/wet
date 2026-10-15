# Code-check round 4 (#77)

## Findings

- **[fragile]** research/discharge_publish.md:105 — "Three things differed from that load and the measurement does not separate them: ... and the segment load ran alongside a publish BUILD reading the same database." The measurement does separate the BUILD out. The BUILD ran 03:21–03:30 UTC (progress.md; m4 `wet-16/data/logs/77/build.log` mtime 20:30 PDT = 03:30 UTC), so it overlapped only the first ~9 of the segment load's 46.1 min (03:20:53–04:07:00, `db_load.log`). The watershed load (04:07–04:28:33 UTC) ran with no BUILD and still took 2.0x its first load (21.6 against 10.7 min), the same ratio as the segments (46.1/23.9 = 1.9x). So the BUILD is not needed to explain the doubling, and the paragraph lists it as an equal candidate. That overstates the uncertainty: a reader would expect a reload with nothing alongside to be faster, and the watershed timing already shows it is not. Suggested fix: say the BUILD overlapped only the first ~9 min of the segment load, and that the watershed load, with nothing alongside, doubled too. That leaves the same-transaction delete and the existing primary key and indexes as the two causes the measurement does not separate.

## Verified true (round-3 fix, the rest of the paragraph)

- The delete runs in the same transaction: `R/wet_db_load.R`, `DELETE ... WHERE scenario = $1` inside `dbWithTransaction`. On an existing table the PK and indexes exist and are maintained per insert. On a created table they are built after the insert (`if (created)` block). True.
- "A reload can reuse only space a VACUUM freed before it, not that of the rows it deletes itself": true. Tuples deleted by the still-open transaction are not removable by pruning or (auto)vacuum until it commits. A later reload's COPY (RPostgres `dbAppendTable`) into a relation whose relfilenode was neither created nor truncated in that transaction does not set `TABLE_INSERT_SKIP_FSM`, so it fills FSM-recorded space that an earlier VACUUM freed.
- "A plain VACUUM ANALYZE marks the old rows' space for reuse but does not return it": true here. The dead rows are the front half of the heap and the new rows were appended after them, so there are no trailing empty pages to truncate. Measured now on m4 (2026-10-15 05:10 UTC, `pg_stat_user_tables`): segment 39 GB total (22 GB heap), watershed 17 GB total (10 GB heap), `n_dead_tup` 0 on both, and last_vacuum 05:03 UTC on both. The paragraph's 39 GB / 17 GB is correct.
- Side note, not a defect: autovacuum processed the watershed table at 04:50 UTC, during the manual VACUUM, and the manual VACUUM's watershed pass ended 2 s after its segment pass. "33.6 min for both" is the command's total, which is accurate.

## Rest of the diff, swept

- Status: the live manifest (fetched 2026-10-15) has wet_commit acb820f, segment_commit 1718a3d, 67 parts (43 + 24), 1.836 GB, and 102,790,688 / 41,904,356 rows. Matches.
- The report's lines 3 and 35, the 4-minute upload with 0 stale keys deleted, and the reader counts all match the logs and progress.md.
- The snow-term prose: `share_static$snow` in `scripts/wb_cv_lib.R:102` adds exactly `snowmelt_doy_50` and `swe_max`, so "two snow terms" is correct. `un_winter` is months 1:3 in order, so the January and February–March split in the prose matches its `stopifnot`. The CLAUDE.md and data-raw descriptions of the stored-month guard match the code.
- No stale "recomputed" / `predict_cv` / "no snow term" / #68-as-open claims remain in the changed files.
