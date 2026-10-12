# Code-check round 2 (#7, crate#31)

Scope: wet branch diff (R/wet_catalog.R, R/wet_db_load.R, scripts/discharge_publish*.R, tests, fixture), the round-1 fix commit 8d923b7, and the crate#31 diff. crate's registry-integrity and discharge tests pass in a copy (0 failed, 0 errors, 0 skipped).

## Findings

- **[bug]** scripts/discharge_publish.R:49-60 against :228-291. PUBLISH accepts a tree from a BUILD that failed its own checks. BUILD writes a complete, self-consistent `manifest.json` at line 228. Everything that can still refuse the build runs after that: the `stopifnot` at 234, round 1's new `num()` stop at 240, the cross-checks, and `stop("cross-checks failed")` at 291. PUBLISH then checks only two things. First, that no code changed between the manifest's `wet_commit` and HEAD. Second, that the files match the manifest (`wet_catalog_verify`). A failed build passes both, because its manifest was written at HEAD and its files match it. Two paths reach this:
  - `num()` stops at 240 when the segment report has no matching line. That happens before the report is written at 271, so `data/checks` stays clean and the dirty check passes. `WET_PUBLISH=1` then uploads a tree whose cross-checks never ran. Round 1 made `num()` stop so that a missing check could not pass. That only works for BUILD; for PUBLISH it is the same defect one step over.
  - A cross-check FAIL writes the report and then stops. If the operator reverts that dirty report (`git checkout data/checks/...`), PUBLISH proceeds. It also proceeds if they commit it, since the report is never read.

  Fix: make the manifest the last thing a successful BUILD produces. Write it to a temporary name, run the checks against that, and rename it to `manifest.json` only after `all(checks)`. Alternatively, have PUBLISH read the committed `discharge_publish_<release>.txt` and require that it names `built_at` and has no `FAIL` line.

  A related hole in the same guard: if the manifest has no `provenance$wet_commit`, then `built_at` is NULL. The call becomes `git diff --name-only HEAD -- R scripts DESCRIPTION`, which compares the working tree with HEAD. The dirty check has already made that empty, so the guard passes. Refuse a NULL or empty `built_at`.

- **[fragile]** scripts/discharge_publish.R:104-112. The round-1 schema check tests that the schema file *exists* at tag `v<crate_version>`. It does not test that the file there is the schema the parts were conformed to. The comment gives the reason for the check: a branch install reports the last release's version. Take a crate install from main or a branch made after the release that carries crate#31, with that schema edited (columns, order or types) but the version not yet bumped. The bump is the last commit of a branch under NGE convention. The HEAD request returns 200, and the manifest names `v<ver>`'s schema while the parts follow the edited one. Fix: GET the body and compare it byte for byte (or by md5) with `system.file("extdata", row$schema_yaml, package = "crate")`. It is the same request, minus `nobody = TRUE`.

- **[fragile]** scripts/discharge_publish.R:127-133. The freshness guard over what built the published data is a hand-kept file list. Round 1 added `R/wet_mm_to_m3s.R`, and the list still leaves out code the published values depend on:
  - `scripts/wb_output.R`. It writes `output/<code>.parquet`, which is published directly as `watershed_monthly` and feeds the balance rows of `segment_monthly`.
  - The scoring code. CLAUDE.md says any change to it stales every fit: `R/wet_wb_fit.R`, `wet_wb_adjust.R`, `wet_share_fit.R`, `wet_share_predict.R`, `wet_wb_raw.R`, `wet_cv_lib.R`, `wb_validate.R` and the rest of `score_files_for()`.

  Commit a change to any of these after the segment table was built and BUILD still passes. It publishes a balance from a fit that `wb_output.R` and `segment_output.R` would now refuse. The mtime check does not cover this; it only orders the files. The segment report already records the scoring code's md5 (`... scoring code <md5>`). Fix: source `scripts/wb_score_md5.R`, then require `fits.rds`'s `code_md5` and the report's md5 to equal `score_code_md5`, as segment_output.R:67-70 does. Also add `scripts/wb_output.R` to `code_seg`. Or diff all of `R/` and `scripts/` since `seg_commit`, excluding the publish files.

No other issues found. I checked:
- crate's schemas, registry rows, path-rule test and `crt_schema_conform` typing.
- wet_catalog parsing, verify and fetch, and wet_db_load's transaction, pick check and cache.
- The other round-1 fixes: the forcing-label check, the empty balance output, the all-NA watershed part, and the `num()` length check within BUILD.
