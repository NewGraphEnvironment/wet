## Outcome

The snow-informed monthly balance (#16) is published: build acb820f replaced 7c62b9e at `https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json` on 2026-10-15, and m4's fwapg `discharge.*` tables were reloaded from it. The publish report now names the live build with all 67 parts identical, so both vignette data scripts run again. Their three bundles were regenerated from the live build. `data-raw/monthly_vignette_data.R` reads the fit's stored held-out months (#68) instead of rerunning `predict_cv()`, and the monthly-flow article was rewritten where the snow shares moved its numbers. Closes #77 and #68.

## Measurement

- **Upload** (m4, from worktree `wet-16` at a18406a): 03:16:30–03:20:24 UTC, 67 parts, 0 stale keys. An unsigned read from m1 shows the manifest naming acb820f, with 67 of 67 parts verified.
- **Rebuild for the report** at eb17bca: about 9 min, run alongside the load. 67 of 67 parts are identical to the live acb820f, nothing failed, and the reader lines equal a18406a's. Only lines 3 and 35 of the report changed.
- **fwapg reload** (in place):
  - Segments 46.1 min, watersheds 21.6 min, about twice #7's load into new tables. The BUILD overlapped only the first 9 min of the segment load, and the watershed load ran alone and still doubled. Two causes stay unseparated: the delete in the same transaction, and the indexes already existing.
  - `VACUUM ANALYZE` took 33.6 min. The tables stay at 39 GB and 17 GB, of which about 28 GB is dead space that can be reused.
  - A count of the rows fresh's subquery selects: 4,532,843, in 1.7 s.
- **What the snow shares moved in the monthly article** (held out, at the calibration gauges):
  - The balance's median error is +7 % to +11 % in April–May and within ±5 % in the other months. It was +8 % to +16 % from January to May.
  - At the Liard gauges routed PCIC does not reach: −16 % in January and −62 % to −75 % in February–March.
  - At Quick, the balance is high January–March but no longer in April.
  - At Buck Creek, the May–June balance is 57 % of the gauge's, though its peak month is still under half.
  - Median monthly NSE is 0.70. Held out, the balance is below the gauge in the peak month at 65 % of the 243 May–June-peaking gauges, by a median of −13 %. So the freshet is still flattened.

## Evidence

- `data/checks/discharge_publish_20260717.txt`: the eb17bca rebuild against the live acb820f.
- m4 `~/Projects/repo/wet-16/data/logs/77/`: `publish.log`, `build.log` and `db_load.log`. The load script is m4 `~/wet77/load_db.R`. (Deleted with the `wet-16` worktree on 2026-10-15, after #81, and not kept.)
- m1 `data/logs/77/`: the three vignette-data runs.
- `review-plan.md` and `review-round1.md` to `review-round4.md` in this directory.
- Recorded in [`research/discharge_publish.md`](../../../research/discharge_publish.md): the status, and the reload paragraph under "Postgres".

## Wrong turns

- The first render of the monthly article stopped on its first failed claim. Running the purled code with a recording `stopifnot` listed all three at once.
- The Buck Creek sentence "under half the gauge's" was still guarded, but only by the peak month. The May–June mean in the same sentence was 57 %, so the wording moved to the peak.
- The first reload paragraph credited the slowdown to the in-transaction delete alone (code-check round 3).

Closed by: PR for branch `77-publish-the-snow-informed-monthly-balanc` (Fixes #77, Fixes #68)
