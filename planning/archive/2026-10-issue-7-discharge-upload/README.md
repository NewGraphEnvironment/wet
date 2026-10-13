## Outcome

wet's per-segment and per-watershed discharge is published at `https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json`, which closes #7. PR #62 (`../2026-10-issue-7-publish-discharge/`) had built the path; this branch did the upload.

- **What was done:**
  - The tree was rebuilt on the full-run machine with crate 0.7.0 and the report committed.
  - `WET_PUBLISH=1` uploaded it.
  - The upload was verified anonymously from a second machine.
  - The published copy was loaded into fwapg with `wet_db_load()`.
- **What it turned up:**
  - **A guard that had never run.** BUILD's segment-table guard was added in #62's code-check rounds, after the last real build. Its `git diff … ':(exclude)…'` went through `system2()`, which hands its arguments to sh unquoted, so the `(` was a syntax error and BUILD stopped on every machine. `shQuote()` in the script's `git()` and `aws()` helpers fixed it.
  - **A recursion in the load script.** The ad hoc load script was first placed at `data/load_db.R`. `pkgload::load_all()` runs top-level `data/*.R` as package data scripts, so the script's own `load_all()` recursed until the stack overflowed. Moving it out of `data/` fixed it.
- **Recorded elsewhere:**
  - Status and measurements are in [`research/discharge_publish.md`](../../../research/discharge_publish.md).
  - #7's body now reads "published".
  - fresh#114 (closed, reads fwapg's own discharge table) has a note that wet's table can be loaded.

## Measurement

On the full-run machine, from fit 20260717 and the segment table built at 653fc13:

- **BUILD at 7c62b9e:**
  - 67 parts, 1.80 GB, about 5 min.
  - The report differs from #62's 7e738e1 build on line 3 only (commit, crate 0.6.0 → 0.7.0), as the plan review predicted: every row count and cross-check is unchanged.
- **PUBLISH:**
  - 2 min (03:29–03:31 UTC, 2026-10-13); 67 parts, 0 stale keys.
  - It ends `published 67 parts, 0 stale keys deleted; all verify`.
  - Bucket default encryption is SSE-S3, so ETag = md5.
- **Second machine, unsigned:**
  - The manifest names 7c62b9e.
  - Rows sum to 102,790,688 (segment) and 41,904,356 (watershed).
  - HEAD verify gives 67 of 67.
  - A full GET of `…/source=pcic_routed/part-400.parquet` matched its md5 and its 3,420,157 rows.
- **Load from the published manifest, into tables dropped first:**
  - The pre-fix tables lacked the partial index, which `wet_db_load()` creates only with the table.
  - Segments: 23.9 min, 20 GB. Watersheds: 10.7 min, 8.5 GB.
  - fresh's subquery returned 4,532,843 rows (3,152,838 routed, 1,380,005 balance), in 9.3 s as the first query after the load (6.7 s in #62).
  - The partial index was created by `wet_db_load()`, and the table comments name the manifest and the build.
- **Wrong turns:** both are under "Errors Encountered" in `findings.md`:
  - The first BUILD hit the unquoted `system2()`.
  - A remote launch backgrounded its own `cd` (`&` binds the whole `&&` list).
  - The first load recursed through `data/`.
- **Plan review and `/code-check branch`:** the plan review gave 14 findings, folded in before Phase 3. `/code-check branch` ran 3 rounds, all clean:
  - Round 2 exercised the script's unreached paths with a faked `aws`.
  - Round 3 enumerated every `system2()` call in the repo.

## Evidence

- `data/checks/discharge_publish_20260717.txt`: the build report at 7c62b9e.
- `review-plan.md` and `review-round*.md` in this directory.

Closed by: PR for branch `7-discharge-upload` (Fixes #7)
