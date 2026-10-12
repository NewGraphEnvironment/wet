# Code-check round 4 (commits 262c252, 10506bd)

## Clean
No issues found.

What was checked:

- **Early manifest delete (discharge_publish.R:34-39).** It runs only in BUILD, before load_all and before the
  dirty check. It fails closed: an unremovable path (for example a directory named manifest.json) trips the
  `stopifnot`. The `manifestXXXX.json` temp file that `wet_manifest_write()` can leave in `root` is never read by
  PUBLISH, and the next BUILD's `unlink(root)` clears it.
- **Enumeration of manifest.json writers.** I grepped R/, scripts/, data-raw/ and tests/. Line 351 is the only site
  that produces `data/publish/.../manifest.json`. `wet_manifest_write()` defaults to `manifest.json`, but its only
  caller under data/publish passes `f_pending`. The other callers (the test helper and test-wet_catalog) write to
  temp dirs.
- **Files that outlive a run, tested against the mechanism.**
  - The parts are md5-bound to the manifest.
  - The manifest exists only after every check: the report is written before the rename, and the only steps
    between them are `if (!all(checks))` and the rename itself.
  - The build report must be at HEAD, name `built_at` and contain no FAIL. With data/checks clean, the working copy
    equals HEAD.
  - The segment report must name `segment_commit`.
  - Scenarios walked through:
    - Two BUILDs at one commit.
    - A failed BUILD after a passing one.
    - A discarded new report.
    - A tree built by the pre-round-3 code (7e738e1): `git diff built_at HEAD -- R scripts` refuses it.
  - Each scenario ends either refused or self-consistent.
  - An NA check is written as "NA", not "FAIL", but `if (!all(checks))` errors before the rename.
- **Regexes against the tracked reports.**
  - wb_output_20260717.txt parses to 24 basins summing to 13 × 3245453 = 42190889, the report's own row total, with
    no duplicate codes. Only the by-basin lines match: station lines start with 7 characters.
  - The segment report matches `^wet commit 653fc13;`.
  - `git show HEAD:data/checks/discharge_publish_20260717.txt` matches `^wet commit 7e738e1 ` and has no FAIL.
  - The upstream/ directory holds the same 24 codes plus `_complete`, which the `.rds` filter excludes.
- **Partial basin copies.**
  - A temp file left in output/ or segment/ by a killed wb_output.R or segment_output.R ends in `.parquet`, so its
    code breaks the basin set check and the build stops.
  - A segment table missing a basin passes the `%in%` check, but the province-total cross-checks catch it before
    the rename.
- **wet_db_load partial index and ANALYZE.**
  - ANALYZE is allowed inside a transaction, and its stats count the transaction's own inserts and deletes
    correctly.
  - `month = 0 AND pick` is valid for the integer and boolean columns.
  - The tests pass: 29 expectations, 0 failures, against the local fwapg, run in a copy.
  - Mutation: removing `AND pick` from the index predicate makes the new assertion fail (FAIL 1). The guard fires.
