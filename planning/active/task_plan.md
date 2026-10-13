# Task: Publish per-segment discharge: the upload (#7)

PR #62 (v0.4.0) merged the publish path; #7 stayed open because nothing was uploaded. Both blockers have cleared: crate#32 is released as v0.7.0, and anonymous `s3:GetObject` on `fresh-bc/discharge/*` is live. What remains is the rebuild (the committed report predates the code-check fixes and names crate 0.6.0), the upload, an independent verify, and the Postgres load fresh#114 joins. It runs on m4, from one worktree on this branch: BUILD, commit the report, PUBLISH.

## Phase 1: m4 setup
- [ ] Push this branch. On m4: `git worktree add ~/Projects/repo/wet-7-upload <branch>`, then symlink `data/wb` to the main checkout's `data/wb` (as `wet-7-publish` did)
- [ ] Install crate from main into m4's R library (`pak::pak("NewGraphEnvironment/crate")`) and confirm `packageVersion("crate") == "0.7.0"`

## Phase 2: rebuild
- [ ] On m4 in the worktree, run `Rscript scripts/discharge_publish.R` (BUILD, about 5 min) in the background, logging to a file, with a completion marker cleared at launch
- [ ] Check the report:
  - [ ] It names the worktree's HEAD and crate 0.7.0, and fails no check.
  - [ ] It has 67 parts: routed 43,901,481 rows, balance 58,889,207, watershed 41,904,356.
  - [ ] It matches the #57 segment report.
  - [ ] Any number that differs from 7e738e1's is attributed.
- [ ] Commit `data/checks/discharge_publish_20260717.txt` on m4, push, and pull on m1

## Phase 3: publish
- [ ] On m4, run `AWS_PROFILE=airvine WET_PUBLISH=1 Rscript scripts/discharge_publish.R`. It uploads 67 parts plus the manifest with Content-MD5, deletes stale keys, and verifies anonymously; it should end on "published 67 parts … all verify".
  - If auto mode refuses this as a production write, the fallback is to hand over the bare command once, not to retry.
- [ ] Commit the publish log line or log, if the script writes one (check before committing; nothing extra is invented)

## Phase 4: independent verify from m1
- [ ] `wet_catalog()` against the live manifest (unsigned): 67 parts, with md5s identical to m4's local manifest
- [ ] Run `wet_catalog_verify()` on the published catalogue, and read one part (BULK's drainage) over HTTPS with arrow; its rows equal the manifest's count

## Phase 5: Postgres from the published copy
- [ ] On m4, `wet_db_load()` the `historical` scenario of both datasets from the published manifest (about 35 min). This replaces the pre-fix 7e738e1 tables.
- [ ] Run fresh's subquery (`month = 0 AND pick`): expect 4,532,843 rows (3,152,838 routed, 1,380,005 balance), with the partial index present
- m1's fwapg is not loaded (19 + 8.5 GB). That is left for whoever runs fresh#114 locally.

## Phase 6: record and close
- [ ] `research/discharge_publish.md`: status "published <date>" with the manifest URL, build commit and part count; remove the open-blocker wording
- [ ] Edit #7's body: mark the blockers resolved and record the publish. Comment on fresh#114 that `discharge.fwa_v1_segment_monthly` can be loaded with `wet_db_load()`
- [ ] m4 cleanup: `git worktree remove` for `wet-7-publish` and `wet-7-upload`; remove crate's `/tmp/crate-31` registration with `git worktree remove` (not prune). Update the m4 memory file.
- [ ] `/planning-archive`, then `/gh-pr-push` with "Fixes #7"

## Validation

- [ ] Report fails no check; anonymous verify passes on both machines; fresh's subquery count matches
- [ ] `/code-check` on any change to code or instructions. This branch is expected to touch only a report, `research/` and planning, so it is skipped if no such file changes; the PR says which.
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
