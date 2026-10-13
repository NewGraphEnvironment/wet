# Task: Publish per-segment discharge: the upload (#7)

PR #62 (v0.4.0) merged the publish path; #7 stayed open because nothing was uploaded. Both blockers have cleared: crate#32 is released as v0.7.0, and anonymous `s3:GetObject` on `fresh-bc/discharge/*` is live. What remains is the rebuild (the committed report predates the code-check fixes and names crate 0.6.0), the upload, an independent verify, and the Postgres load fresh#114 joins. It runs on m4, from one worktree on this branch: BUILD, commit the report, PUBLISH.

## Phase 1: m4 setup
- [x] Push this branch. On m4: `git worktree add ~/Projects/repo/wet-7-upload <branch>`, then symlink `data/wb` to the main checkout's `data/wb` (as `wet-7-publish` did)
- [x] Install crate from main into m4's R library (`pak::pak("NewGraphEnvironment/crate")`) and confirm `packageVersion("crate") == "0.7.0"`

## Phase 2: rebuild
- [x] On m4 in the worktree, run `Rscript scripts/discharge_publish.R` (BUILD, about 5 min) in the background, logging to a file, with a completion marker cleared at launch
- [x] Check the report:
  - [x] It names the worktree's HEAD and crate 0.7.0, and fails no check.
  - [x] It has 67 parts: routed 43,901,481 rows, balance 58,889,207, watershed 41,904,356.
  - [x] It matches the #57 segment report.
  - [x] Any number that differs from 7e738e1's is attributed.
- [x] Commit `data/checks/discharge_publish_20260717.txt` on m4, push, and pull on m1

## Phase 3: publish
- [x] On m4, run `AWS_PROFILE=airvine WET_PUBLISH=1 Rscript scripts/discharge_publish.R`. It uploads 67 parts plus the manifest with Content-MD5, deletes stale keys, and verifies anonymously; it should end on "published 67 parts … all verify".
  - If auto mode refuses this as a production write, the fallback is to hand over the bare command once, not to retry.
- [x] PUBLISH writes no log file (review S2): record its final line in `research/` and on #7

## Phase 4: independent verify from m1
- [x] `wet_catalog()` against the live manifest (unsigned): 67 parts; `provenance$wet_commit` is the committed report's build; rows sum to 102,790,688 (segment) and 41,904,356 (watershed)
- [x] Download one part in full (`segment_monthly/…/source=pcic_routed/part-400.parquet`, BULK's drainage) and md5 it against the manifest; read the local copy with arrow: 3,420,157 rows (review G3, A3, AC4)

## Phase 5: Postgres from the published copy
- [x] On m4, drop the pre-fix 7e738e1 tables (`wet_db_load()` builds its indexes only when it creates a table, review G1), then `cat <- wet_catalog()` (https manifest asserted) and `wet_db_load(conn, cat)` plus `wet_db_load(conn, cat, dataset = "discharge/fwa/v1/watershed_monthly")` (about 35 min)
- [x] Run fresh's subquery (`month = 0 AND pick`): expect 4,532,843 rows (3,152,838 routed, 1,380,005 balance); `pg_indexes` holds the partial index; the table comment names the https manifest and the new build commit (review AC3)
- m1's fwapg is not loaded (19 + 8.5 GB). That is left for whoever runs fresh#114 locally.

## Phase 6: record and close
- [x] `research/discharge_publish.md`: status "published <date>" with the manifest URL, build commit and part count; remove the open-blocker wording
- [x] Edit #7's body: mark the blockers resolved and record the publish. Comment on fresh#114 that `discharge.fwa_v1_segment_monthly` can be loaded with `wet_db_load()`
- [x] m4 cleanup: `git worktree remove` for `wet-7-publish` and `wet-7-upload`; remove crate's `/tmp/crate-31` registration with `git worktree remove` (not prune). Update the m4 memory file.
- [ ] `/planning-archive`, then `/gh-pr-push` with "Fixes #7"

## Validation

- [ ] Report fails no check; anonymous verify passes on both machines; fresh's subquery count matches
- [ ] `/code-check` on any change to code or instructions. This branch is expected to touch only a report, `research/` and planning, so it is skipped if no such file changes; the PR says which.
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
