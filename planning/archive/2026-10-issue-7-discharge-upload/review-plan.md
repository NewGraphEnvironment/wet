# Plan review: the upload (#7)

A Plan agent reviewed `task_plan.md` at 5568a1b. This is its findings, condensed, each with what was done about it.

- **B1, Blocker if a log is tracked.** The dirty check (`scripts/discharge_publish.R:51`) refuses untracked files under `R/`, `scripts/`, `data/checks/`. Done: the log and marker are under `data/` (ignored).
- **G1, Gap.** `wet_db_load()` creates the primary key, the id index and the partial index only when it creates the table (`R/wet_db_load.R:81,119-130`). m4's tables are the pre-index 7e738e1 load. Done: drop both tables before loading, then check `pg_indexes` for `WHERE ((month = 0) AND pick)`.
- **G2, Gap.** `catalog` has no default, and the default dataset is segments only. Done: `wet_catalog()` from the https URL, then one `wet_db_load()` per dataset. Assert the manifest is https: a local path skips the download and md5 check.
- **G3, Gap.** `wet_catalog_verify()` only sends a HEAD (`R/wet_catalog.R:230-238`), which is what PUBLISH already runs. Done: on m1, download one part in full and md5 it. Check `provenance$wet_commit` against the committed report, and the row sums (102,790,688 segment, 41,904,356 watershed).
- **G4, Gap.** ETag equals md5 only without SSE-KMS. Checked: `get-bucket-encryption` says AES256 (SSE-S3).
- **G5, Gap.** A failed BUILD after the report is written leaves the report modified, and the next BUILD refuses at `:51`. Noted: `git checkout -- data/checks/discharge_publish_20260717.txt` before a rerun.
- **O1–O3, Ordering.**
  - Commits outside `R/` and `scripts/` between BUILD and PUBLISH are harmless.
  - The report must be committed in the m4 worktree.
  - Run from the worktree root.
  - Fetch before `worktree add`.
  - All followed.
- **A1, Assumption.** There is one complete run in `data/wb`, and `WET_HYDAT_RELEASE` is unset. BUILD's guards pass on m4.
- **A2, Assumption.** crate main is two commits past v0.7.0, touching only CITATION.cff and CLAUDE.md, so the install's schemas match the tag. BUILD checks this itself.
- **A3, Assumption.** arrow may not read a plain https URL. Done: download, then read the local copy.
- **S1, Scope.** `research/discharge_publish.md` has no blocker wording. Its stale line is the bucket-policy evidence (line 88). Done in Phase 6.
- **S2, Scope.** PUBLISH writes no log file. Done: its last line is recorded in `research/` and on #7.
- **AC1, Acceptance.** The expected numbers are all correct.
- **AC2, Acceptance.** Only the publish files changed since 7e738e1, so the rebuilt report should differ on line 3 alone (commit and crate version), plus perhaps the GB total.
- **AC3, Acceptance.** Check that the table comment names the https manifest and the new build commit.
- **AC4, Acceptance.** BULK sits in drainage 400 (Skeena). Its routed part is expected to hold 3,420,157 rows.
