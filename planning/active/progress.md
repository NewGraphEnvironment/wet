# Progress — Publish per-segment discharge: the upload (#7)

## Session 2026-10-12

- Plan-mode exploration — phases approved by user
- Created branch `7-discharge-upload` off main
- Scaffolded PWF baseline from issue #7 with approved phases
- Next: start Phase 1
- Phase 1 on m4: worktree `~/Projects/repo/wet-7-upload` on this branch, `data/wb` symlinked; crate 0.7.0 installed (github c6a1d1f)
- First BUILD stopped at the segment guard: unquoted `system2()` args (findings, Errors). Fixed in `scripts/discharge_publish.R`.
- Phase 2: BUILD on m4 at 7c62b9e, 03:23–03:28 UTC: 67 parts, 1.80 GB, every cross-check ok. The report differs from 7e738e1's on line 3 only (commit, crate 0.6.0 → 0.7.0), as review AC2 predicted. Committed on m4 as e92ff15.
- Phase 3: PUBLISH launched on m4 at 03:29 UTC (`AWS_PROFILE=airvine`). The bucket's default encryption is AES256 (SSE-S3), so ETag = md5 (review G4).
- Phase 3: PUBLISH on m4 03:29–03:31 UTC from e92ff15: 67 parts put, 0 stale keys deleted, final line `published 67 parts, 0 stale keys deleted; all verify at https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json`.
- Phase 4, from m1 (unsigned):
  - The manifest's `wet_commit` is 7c62b9e, as the committed report names; rows sum to 102,790,688 (segment) and 41,904,356 (watershed); a HEAD verify gives 67 of 67.
  - A full GET of `segment_monthly/…/source=pcic_routed/part-400.parquet` returned 32,094,340 bytes, md5 db2beca3… = manifest, and 3,420,157 rows, 390,481 of them BULK.
- Phase 5: the first load attempt failed at once (findings, Errors). The reload was launched on m4 at 03:32:58 UTC.
- Phase 5, the m4 load from the published manifest (03:33–04:07 UTC), into tables dropped first:
  - segment 102,790,688 rows in 23.9 min (20 GB); watershed 41,904,356 in 10.7 min (8.5 GB);
  - fresh's subquery returned 3,152,838 + 1,380,005 = 4,532,843 rows, in 9.3 s as the first query after the load (6.7 s measured in #62);
  - the partial index `WHERE ((month = 0) AND pick)` was created by `wet_db_load()`;
  - both table comments name the https manifest and build 7c62b9e.
- Phase 6: `research/discharge_publish.md` gets a status line, the load measured from the published copy, and the policy and publish evidence.
- Phase 6:
  - #7's body: the Blockers section became "Status: published 2026-10-13".
  - fresh#114 (closed 2026-09-26, reads fwapg's own `fwa_stream_networks_discharge`): commented that the table is loadable. Checked the coverage claim on m4 (picked annual rows: BULK 30,037, LDEN 21,848).
  - m4: removed worktrees `wet-7-publish`, `wet-7-upload` and crate `/tmp/crate-31` with `git worktree remove` (crate-31's 536e8ed is in crate main); `data/wb` intact.
