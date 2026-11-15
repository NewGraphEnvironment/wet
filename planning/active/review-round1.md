# Code-check round 1: branch 164 (git diff 797a5d4...HEAD, HEAD 05d6a59)

## Checklist read

- code-check.md: every H3 under `## Mechanisms`, prose read, table rows skipped (all 14): A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice. Standalone rules: index only. Not read in full: 24 of 38.
- code-check-r.md (121 headings): read in full: A database driver's value is not a base R type; Postgres row order is never fixed unless the query fixes it...; `$` on a list partial-matches...; A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check`...; as.POSIXct on character infers ONE format...; Under `R CMD check`, tests run from a temp dir against the INSTALLED package; `identical()` on two reader results tests the reader, not the file; `system2(stdout = TRUE)` warns on a non-zero exit.... Not read: 113 (index only).
- code-check-shell.md (71 headings): read in full: An S3 multipart ETag depends on the uploader's part size...; `aws s3 cp` cannot tell a missing key from a missing bucket. Not read: 69 (index only).
- code-check-spatial.md (94 headings): read in full: `arrow::write_parquet()` of a geoarrow table is not GeoParquet (to rule it out; the samples carry no geometry). Not read: 93 (index only).

## What was run (in a detached worktree of HEAD, since removed)

- `test-wet_catalog.R`: 74 passed, 0 failed, 0 errors, 0 skipped.
- `test-publish_report_live.R`: 32 passed, 0 failed, 0 errors, 0 skipped.
- `test-wet_db_load.R`, against the local fwapg (throwaway `wet_test_*` schema, dropped by the tests): 55 passed, 0 failed, 0 errors, 0 skipped.
- `tools:::.check_packages_used_in_tests()`: empty (crate, withr, jsonlite, duckdb all declared).
- `devtools::run_examples()`: no errors.

Checked and found sound: the load record is inside the transaction and before the checks (the rollback tests pass live); the table comment's text is unchanged, and link's `.lnk_discharge_wet_load_id()` still parses it; `wet_manifest_write()` and `wet_receipt_write()` both leave `fit/` parquet out of the parts, and no BUILD read globs the tree outside `segment_monthly/` or `segment_daily/`; `wet_part_fetch()`'s cache path for fit files (`<cache>/discharge/fwa/v1/fit/...`) cannot collide with a part's; the PUBLISH order (parts, then fit and receipt, then manifest) and the stale-key `keep` set cover every listed file; the `fwapg` input regex matches the tracked `routed:` line; data.frame row subsets keep the `fit`/`receipt` attributes, as the `wet_catalog_files()` comment claims; segment_group.R's published branch defines everything the report and the later checks read (`used`, `n_fit_ok`, `smp_from`, `smp_msgs`), and the sample indices follow `groups`' order.

## Findings

- **[severity: fragile]** scripts/segment_group.R:65 — `WET_CATALOG_URL` sets `options(wet.catalog_url = )` in every mode, not only under `WET_GROUP_FROM=published`, where the header documents it (lines 41-43). So in the default mode too, `cat_pub <- wet_catalog()` (line 153) can read a local, unpublished tree. The tracked report (`data/checks/segment_group_<WSG>_<release>.txt`) still heads its section "## Published product" with "live build <commit> (manifest built ...)" (lines 521-522) and never names the manifest it read. The published-mode report names the manifest only on its fit line, and its "live build" line has the same flaw. A run made to try a built tree can therefore commit a research record that says it compared against the live build. `vd_published()` guards the same option with `identical(attr(cat_pub, "manifest"), wet:::wet_catalog_url)`; this script has no such guard. One fix: write `attr(cat_pub, "manifest")` into the "live build" line, and either refuse the override outside published mode or route an overridden run's report away from `data/checks/`, as `WET_GROUP_DROP` routes its report to `data/logs/157/`.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

Nothing else found that could cause a failure, a security problem or data loss.
