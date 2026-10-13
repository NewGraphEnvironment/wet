## Outcome

wet's per-segment and per-watershed discharge now has a publish path: Hive parquet plus a `manifest.json` under `s3://fresh-bc/discharge/fwa/v1/`, read with `wet_catalog()` and loaded into Postgres with `wet_db_load()` (`discharge.fwa_v1_segment_monthly`, which fresh joins with `month = 0 AND pick`).

- **Planning discussion with the user:**
  - STAC was dropped as out of place for one province-wide table; a manifest does its two jobs (naming keys without listing, provenance).
  - Naming was settled as one dataset ID (`<variable>/<network>/<version>/<unit>_<timebase>`) from which the S3 prefix, the crate schema (crate#31 / crate#32) and the Postgres table all derive.
  - Hive keys are `scenario` / `forcing` / `source`, sized for hydromosaic's 9 GCMs × 2 SSPs, its water temperature and oxygen saturation, Poisson Consulting estimates and a national network.
  - fresh-bc was chosen over a new bucket. The durable record is [`research/discharge_publish.md`](../../../research/discharge_publish.md).
- **`scripts/discharge_publish.R`:** BUILD conforms every part to its crate schema, writes one row group per watershed group, cross-checks against the tracked segment and balance reports, and only then renames the manifest into place. PUBLISH uploads with Content-MD5 and verifies anonymously.
- **Not done here:**
  - The upload, which waits on the bucket-policy change and the crate release.
  - The rebuild, which must follow that release, because the committed build report predates the code-check fixes and names crate 0.6.0.

## Measurement

On the full-run machine, from the shipped fit 20260717 and the segment table built at 653fc13:

- **BUILD:** 67 parts, 1.80 GB, about 5 min.
  - `segment_monthly`: routed 43,901,481 rows, balance 58,889,207.
  - `watershed_monthly`: 41,904,356 rows; 22,041 NA-flow watersheds × 13 dropped.
  - All match the #57 segment report and the balance report.
- **Pruning:** with one row group per group, a read for BULK opens 2 of 507 row groups in 43 segment parts. arrow's default would have written one row group per file, so nothing would have pruned (plan review B2).
- **Postgres** (`wet_db_load()`, while another long query ran on the same database):
  - segment table: 102,790,688 rows in 23.7 min, 19 GB with indexes;
  - watershed table: 11.3 min, 8.5 GB.
  - fresh's subquery returns 4,532,843 rows (3,152,838 routed, 1,380,005 balance), one per segment.
  - It took **197 s** unindexed. A partial index `(scenario, linear_feature_id) WHERE month = 0 AND pick` (built in 0.5 min) brings it to **6.7 s**, and to 0.7 s joined to one group. `wet_db_load()` now creates it.
- **Wrong turns:**
  - The first fixture shipped 120-byte parquet paths in `inst/extdata`, over tar's 100-byte limit (plan review G14). Now only the manifest ships.
  - Drainage labels came out alphabetical ("Annacis Channel" for the Fraser) until `count(*)` was cast from integer64.
- **`/code-check`:** four rounds, plus the plan review.
  - Round 1: PUBLISH could never run, because committing the build report moved HEAD.
  - Round 2: a defect inside round 1's fix; a cross-check stop protected BUILD but not PUBLISH.
  - Round 3 named the mechanism: guards placed by which run they stop, not by which file they keep out of a publish.
  - The loop ended on an enumeration that round 4 confirmed: one site creates `manifest.json`, after every check, and the old manifest is deleted before anything can refuse.

## Evidence

- `data/checks/discharge_publish_20260717.txt`: the build report, from 7e738e1, before the code-check fixes.
- `review-plan.md` and `review-round*.md` in this directory.

Closed by: PR for branch `7-publish-per-segment-discharge-parquet-st` (Relates to #7; the upload remains)
