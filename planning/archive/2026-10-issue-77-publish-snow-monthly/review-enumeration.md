# Code-check termination by enumeration (#77), after round 4

Round 4 found a defect inside round 3's fix (the reload's causes), so the loop ends only by enumeration. The candidate set is the mechanism both rounds named: a claim stated beyond its evidence. It covers every factual sentence this branch added outside the vignette, 18 claims in all. The vignette's changed numbers are each held by a `stopifnot` (rounds 1–4). Its one unheld sentence, on the snow terms reducing the winter bias, cites research and was checked against `cv_shares` in round 3.

| # | claim (file) | artifact | verdict |
|---|---|---|---|
| 1 | Verified line names #77 (discharge_publish.md:3) | this branch | true |
| 2 | first published 2026-10-13 at 7c62b9e (:5) | the #7 archive README | true |
| 3 | replaced 2026-10-15 by acb820f (:5) | publish.log 03:16–03:20 UTC; manifest | true |
| 4 | segment table 1718a3d, fit 20260717, run e675918817, crate 0.7.0 (:5) | report line 3; manifest (round 3) | true |
| 5 | 67 parts, 1.84 GB, 43/24, 102,790,688 / 41,904,356 rows (:5) | manifest (round 3: 1,836,285,495 bytes) | true |
| 6 | row counts and picks equal 7c62b9e's (:5) | the report's parts table against a18406a's (round 3) | true |
| 7 | the balance's months changed (:5) | 6 of 67 parts identical before the upload (a18406a report) | true |
| 8 | report = eb17bca rebuild, 67 of 67 identical (:5) | report lines 3 and 35 | true |
| 9 | upload about 4 min, 0 stale keys (:5) | publish.log | true |
| 10 | indexes stayed (:105) | pg_indexes in db_load.log | true |
| 11 | 46.1 and 21.6 min (:105) | db_load.log 20:20:53 / 21:07:00 / 21:28:33 PDT | true |
| 12 | BUILD overlapped the first 9 min; watersheds doubled alone (:105) | build.log 20:21–20:30:36 PDT; 21.6 against 10.7 | true (round 4 fix) |
| 13 | two causes unseparated (:105) | R/wet_db_load.R:92, 119–130 | true |
| 14 | VACUUM 33.6 min; 39 / 17 GB against 20 / 8.5 GB (:105) | VACUUM output; :103 | true |
| 15 | reuse only of space a prior VACUUM freed (:105) | PostgreSQL MVCC (round 4) | true |
| 16 | "fresh's subquery … in 1.7 s" (:105) | the timed query was `count(*)`, not fresh's select | **overstated: fixed here** to "a count of the rows … not comparable with 9.3 s" |
| 17 | uploaded 2026-10-15, build acb820f (water_balance_method.md:447) | publish.log | true |
| 18 | CLAUDE.md monthly sentence: stored months, three guards | data-raw/monthly_vignette_data.R:58–75 | true (round 4) |

18 claims. The one found (16) was an original sentence, not one inside a fix, and it is fixed. Nothing else sits above its source. The loop ends here.
