# Code-check round 2 (#7, branch 7-discharge-upload vs main)

## Clean

No issues found.

## What was checked

Paths in `scripts/discharge_publish.R` that the one BUILD + PUBLISH run did not exercise, each run against the
script's own `git()` / `aws()` helpers (shQuote'd, as in the diff) in a scratch clone or with a faked `aws`:

- **Segment-table guard (L176), BUILD.** `653fc13..HEAD` with the four `:(exclude)` pathspecs returns
  `character(0)`. That is correct: the full diff `653fc13..7c62b9e -- R scripts` is exactly the four
  `publish_own` files. Against `653fc13~5` it returns 3 files (`R/wet_source_pick.R`,
  `scripts/pcic_routed_lib.R`, `scripts/segment_output.R`), so the guard fires.
- **Dirty check (L52).** In a scratch clone with a modified `scripts/discharge_publish.R` and an untracked
  `data/checks/*.txt`, it returns both lines (` M ...`, `?? "..."`), so the refusal fires. A filename with a
  space comes back quoted but non-empty, which is enough.
- **PUBLISH refusals.** An unknown `built_at` makes `git diff` fail, and the stop names the git error. A
  missing `HEAD:<report>` makes `git show` fail, which is caught as `character()`, and the stop fires. A
  NULL or empty `segment_commit` makes `paste0` give `^wet commit ;`, which matches nothing, and the stop
  fires.
- **Stale-key deletion (L104-113).** The real `list-objects-v2 --output text` output (aws-cli 2.34.34,
  read-only probe; `--page-size 10` gives one tab-separated line per page) and the empty-prefix output
  (`None`) both parse correctly through `unlist(strsplit(keys, "\t"))` and `setdiff(c("None", ""))`.
  - With fake output that mixes kept keys and two stale keys (one containing a space), only the stale keys
    reach `delete-object`.
  - Each key arrives at the program as one argument after the sh round trip (checked through
    `system2("printf", shQuote(...))`).
  - Nothing is deleted for `None`.
  - Stray stderr lines merged into `keys` would fail the `startsWith` stopifnot. That fails toward refusal,
    not deletion.
- **Live bucket.** It holds exactly 68 keys under the prefix (67 parts and the manifest).
- **stderr merged into stdout in `git()`.** Any warning git prints on exit 0 lands in
  `dirty` / `changed` / `wet_commit`, and in each case the run refuses: `changed` and `dirty` stop, and a
  2-element `wet_commit` becomes a JSON array that PUBLISH's `length(built_at) != 1L` rejects. Fragile, but
  it never passes or destroys data.
- **Cross-check failure (L351).** The report is written with FAIL, then the run stops. `manifest.json` was
  already unlinked at the start and `manifest.pending.json` is never read by PUBLISH, so the tree cannot be
  published. An NA in `checks` errors in `if (!all(checks))`, which is also a refusal.

## Research doc claims against the code and the artifact

- **Counts.** The anonymous `wet_catalog()` + `wet_catalog_verify()` of the published manifest gave
  43 + 24 parts, 144,695,044 rows (102,790,688 + 41,904,356, which matches the report's per-part sums), and
  1.795 GB. All 67 parts were ok, at `wet_commit` 7c62b9e and `segment_commit` 653fc13.
- **fresh subquery.** 3,152,838 + 1,380,005 = 4,532,843, which matches the report's hive rows.
- **The publish line.** The quoted `published 67 parts, 0 stale keys deleted; all verify` matches the
  stamp's format at L118.
- **`wet_db_load()`.**
  - It md5-checks every fetched part (`wet_part_fetch`).
  - It creates the partial index only when it created the table (`if (created)`).
  - The table comment carries the manifest URL, `built` and `wet_commit`.
  - All three match the doc.

Non-blocking, pre-existing and outside the diff: the script header (L13-14) says BUILD "prints what PUBLISH
would upload and delete". BUILD prints only a part count and a generic "then delete keys it no longer names".
It cannot list the stale keys without an S3 listing.
