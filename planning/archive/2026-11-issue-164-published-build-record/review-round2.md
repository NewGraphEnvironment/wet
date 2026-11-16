# Code-check round 2: branch 164 (git diff 797a5d4...HEAD, HEAD bea5ff7)

## Checklist read

- code-check.md: the prose of every H3 under `## Mechanisms`, table rows skipped (all 14): A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice. Standalone rules: index only. Not read in full: 24 of 38.
- code-check-r.md (121 headings): read in full: A database driver's value is not a base R type; `$` on a list partial-matches...; as.POSIXct on character infers ONE format...; as.POSIXct on a Date pins UTC midnight...; Postgres row order is never fixed unless the query fixes it...; A value compared as `::text` in SQL...; jsonlite writes an empty name as the element's position; `system2(stdout = TRUE)` warns on a non-zero exit.... Not read: 113 (index only).
- code-check-shell.md (71 headings): read in full: An S3 multipart ETag depends on the uploader's part size.... Not read: 70 (index only).
- code-check-spatial.md (94 headings): read in full: `arrow::write_parquet()` of a geoarrow table is not GeoParquet (to rule it out; the samples carry no geometry). Not read: 93 (index only).

## The round-1 fix (bea5ff7)

It closes the defect as reported: `WET_CATALOG_URL` is refused outside published mode, an
overridden published run reports to `data/logs/164/`, and the build line now names the manifest
read and says `live` only when it is `wet:::wet_catalog_url`. So no report can now say "live"
over a local tree. One residue is listed below (the destination and the label are decided by
two different predicates). Checked and sound: the refusal comes before any work; `catalog_url`
is defined in every mode, so `f_rep`'s first arm cannot error; `cat_fit` and `cat_pub` both read
the same option, so the fit line and the build line name one manifest; a local manifest's
hrefs are local paths, which `wet_part_fetch()` checks in place and duckdb reads with
`hive_partitioning = true`. Parse check of segment_group.R and discharge_publish.R: clean.

## Findings

- **[severity: fragile]** scripts/segment_group.R:486 and :532 — where the report goes is keyed on the env var (`nzchar(catalog_url)`), while the "live"/"UNPUBLISHED" label is keyed on the manifest actually read (`identical(attr(cat_pub, "manifest"), wet:::wet_catalog_url)`). `wet_catalog()` defaults to `getOption("wet.catalog_url", ...)`, and Rscript runs `~/.Rprofile`, so an option set there (or anywhere but `WET_CATALOG_URL`) slips past both the new refusal (line 71) and the routing: in either mode the run compares against that tree and overwrites the tracked `data/checks/segment_group_<WSG>[_published]_<release>.txt`. The label still reads UNPUBLISHED, so the report no longer claims the live build, but a tracked record is replaced by a run against an unpublished tree. Nothing in the repo sets the option today, so this needs an outside setting to fire. A one-line fix: route (and refuse in default mode) on the same `identical()` test the label uses, computed once, rather than on the env var.
  - **Rule:** code-check.md "One fact derived twice"

- **[severity: fragile]** scripts/discharge_publish.R:221-223 against scripts/segment_daily_output.R:80-82 — the branch adds `R/wet_segment_daily.R` and `scripts/segment_group.R` to `publish_own` ("read the published product and feed no table"), but `segment_daily_output.R` keeps its own copy of that exclusion list, which lacks both. This branch edits both files, and the monthly table was built at 66cf795. Measured: `git diff --name-only 66cf795 HEAD -- R scripts` with segment_daily_output.R's exclusions gives `R/wet_segment_daily.R` and `scripts/segment_group.R` (empty at 797a5d4). So after this merges, the next `scripts/segment_daily_output.R` run refuses with "code changed since the monthly segment table was built at 66cf795 ... rerun scripts/segment_output.R", a province-scale rebuild with no reason behind it. It fails toward refusal, and the publish BUILD and PUBLISH this branch needs do not run that script, so nothing breaks now. Fix: add the same two files to `own` in segment_daily_output.R, or share one list.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

Checked across the rest of the diff and found sound: `wet_load_record()` runs inside the transaction before the checks, and NA `built`, `subset` and `recipe_id` reach Postgres as NULL; the table comment's text is unchanged; the manifest's `fit` and `receipt` field checks (missing field, `..` key, malformed md5, duplicate key); `wet_catalog_files()` row order matches on the local and published sides, so the PUBLISH `identical()` on keys and md5s holds; `put()` given a NULL extra argument; the stale-delete `keep` covers every listed file; crate's `crt_receipt_write()` with `lockfile = NULL`, `publish = TRUE` and the declaration's inputs, settings and summary names; the new report lines carry no "FAIL" (hex only), so `vd_published()` and `publish_report_check()` still read the report; the BUILD removes `root` whole (line 313) before writing, so no earlier tree's fit or receipt can leak into the receipt's or manifest's file list.
