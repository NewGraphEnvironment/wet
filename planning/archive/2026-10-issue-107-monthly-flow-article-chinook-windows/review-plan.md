# Plan review (#107) — Plan agent, 2026-10-23, after the baseline (287483c)

Spawned unnamed in the background at the baseline; findings arrived while Phase 1 was being written, so they are read against the code as landed in fa5e5a1. Each finding, with its disposition.

| # | Class | Finding | Disposition |
|---|---|---|---|
| 1 | Gap | The tie test needs the raw (pre-rounding) value, which `wet_routed_days()` throws away | Already done: the script calls `wet:::wet_routed_raw()` and keeps `raw` beside the rounded days |
| 2 | Assumption | Routing through `wet_routed_raw()` on a subset fold is the build's own path, so ties should be 0 and "differing minus ties" could mask a defect | Kept as decision 5 says (the user's), with `day_tie` recorded in provenance and printed in the article. The publish's values were made on another machine, so the rule still covers a last-bit summation difference; the article prints the count |
| 3 | Blocker | A Bulkley watershed missing from the reduced `up` would silently lower `compared` | Covered: `up_b <- up[match(...)]` then `stopifnot(!anyNA(up_b$watershed_feature_id))` |
| 4 | Gap | `q_mon` alignment with `wet_shape_predict()`'s rows | Covered: both built in `seg_bulk` order; months by `match(1:12, x$month)` |
| 5 | Scope | "months from the days" must run on the published days, not the recomputed ones | Covered: `mon_d` is aggregated from `pb_d` (the `wet_segment_daily()` read) |
| 6 | Gap | `compared` counts: 1095, 1095, 36 | Covered: `n_src` extended with `nrow(src_rd), nrow(src_bd), nrow(pb_b12)` |
| 7 | Ordering | `conn` is closed before the published read | Covered: weights, sub-basin days and the daily fingerprint are read before the disconnect |
| 8 | Gap | `write_bib()` emits two entries for wet; gq has no DOI; `RemoteSha` is NULL under a checkout install, so the commit never prints on the site | Taken: the chunk uses `utils::citation()` per package, prints a DOI only where one exists, the commit only when a 40-hex hash; the plan's verification bullet becomes "DOI and version; commit when a hash" |
| 9 | Acceptance | "the days close the gap" presupposes a sign the data has not shown | Taken: the prose and its `stopifnot()`s are written after the bundle lands, from its numbers |
| 10 | Ordering | `expect_named()` order | Covered: `segments_daily` second, in `no64()` |
| 11 | Scope | the daily windows must take the same two-gauge filter | Covered in the `windows` chunk |
| 12 | Gap | To do 3 needs a Limits sentence; provenance should record the BULK daily parts; header line 6 and `CLAUDE.md`'s "Its gaps are #67 and #6" go | Taken: all four done |

Environment finding of our own, not the reviewer's: m1's `pcic.subbasin_daily` was empty for both runs (`pcic.runs` described 13,786,122 rows). Loaded the 1981-2010 run from fwapg's public export with `load/pcic_run.sql` (90 s; `data/logs/107/` has the script log).
