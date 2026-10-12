# Code-check round 1: wet #7 (publish discharge) + crate#31 (discharge schemas)

Reviewer ran both test suites in copies (scratchpad/rev1): crate all green; wet
test-wet_catalog.R 34 pass, test-wet_db_load.R 28 pass, 0 skip, 0 error (local fwapg).

## Findings

- **[severity: bug]** scripts/discharge_publish.R:41-55 with :246-268. PUBLISH can never run.
  The dirty guard at :41 covers `data/checks`, and BUILD itself writes the tracked
  report `data/checks/discharge_publish_<release>.txt` (:249), whose first line carries
  `wet commit <HEAD>`. So after a BUILD the tree is dirty and PUBLISH refuses ("commit
  these first"). Commit the report, and HEAD moves, so `:52` finds the manifest's
  `wet_commit` != HEAD and refuses ("rerun the build"). Rerunning the build rewrites the
  report with the new HEAD, which dirties `data/checks` again. That is a loop with no exit.
  It is the current state: the committed report says `wet commit 7e738e1`, and HEAD is
  3b277e9, the commit that added the report. Fix: in PUBLISH, compare code rather than the
  commit, e.g. `git diff --quiet <manifest commit> HEAD -- R scripts DESCRIPTION`, and/or
  leave `data/checks` out of the dirty check on the PUBLISH path.

- **[severity: bug]** scripts/discharge_publish.R:95-96 and R/wet_catalog.R:199-205. The
  manifest names a crate release that does not hold the schema. `crate_version` is
  `packageVersion("crate")`, and the crate#31 branch still says `Version: 0.6.0`. The
  build ran against that branch install: the report reads "crate 0.6.0", and the installed
  0.6.0 has `schemas/nge/discharge/...`. But tag `v0.6.0` holds no discharge schema
  (`git ls-tree -r v0.6.0 | grep discharge` is empty). So every `datasets[].schema.url` in
  the built manifest
  (`.../crate/blob/v0.6.0/inst/extdata/schemas/nge/discharge/fwa/v1/segment_monthly.yaml`)
  404s, and `schema.version` names the wrong contract. `publish_schema_cols()` checks only
  that the installed crate has the schema, not that the version it reports is a release
  that contains it. Fix: require a crate version newer than 0.6.0, or check that the tag
  holds the YAML, and rebuild after crate#31 is released.

- **[severity: fragile]** scripts/discharge_publish.R:220-234. A cross-check whose report
  line goes missing drops out of `checks` silently. `num()` returns `numeric(0)` when its
  regex finds no line, so e.g. `routed_rows = sum(rt$rows) == 13 * numeric(0)` is
  `logical(0)`, and `c(routed_rows = logical(0), ...)` removes the element: the report
  lists fewer checks, none FAIL, and `all(checks)` passes. A rewording of
  `segment_output`'s "both sources:" line therefore silently removes `routed_rows` and
  `balance_rows`. The `hive_read` assignment would error rather than pass, but only for the
  picked lines. Fix: `stopifnot(length(x) == 1L)` on each parsed number.

- **[severity: fragile]** scripts/discharge_publish.R:114-115. The "segment code changed
  since its report" guard misses a file the segment table depends on.
  `scripts/segment_output.R:118` uses `wet_month_days()`, which lives in
  `R/wet_mm_to_m3s.R`, and that file is not in `code_seg`. A change to the month lengths
  restates the segment table's monthly values, yet the build would publish the stale table
  under a manifest whose `wet_commit` claims it can rebuild it. Add `R/wet_mm_to_m3s.R`, or
  derive the list from what segment_output.R calls.

- **[severity: fragile]** scripts/discharge_publish.R:104-124 and :175-189. The watershed
  path has two edges where the guard passes the case it should catch, or crashes:
  - With no `output/*.parquet`, `mt(ws_files)` is `max(file.mtime(character(0)))` = `-Inf`.
    The freshness guard passes, and the watershed dataset is left out of the manifest with
    no error. Nothing else requires `ws_files`: the 13-month reduced-bundle check sits
    inside the empty loop.
  - A part whose rows are all NA errors at `x$period <- period_balance` ("replacement has 1
    row, data has 0") before the `if (nrow(x))` guard at :188 is reached, so that guard is
    dead code. Neither case occurs in today's data (the smallest part is 999 at 780 rows).

- **[severity: fragile]** scripts/discharge_publish.R:161-169. Segment rows whose `source`
  is not in `names(publish_forcing)` are silently left out of the tree. The pick check at
  :160 counts picks across every source, but the parts and cross-checks cover only these
  two. A third source added in `segment_output.R` would publish segments with no picked
  row and nothing would fail. Assert `all(x$source %in% names(publish_forcing))`.

## Checked and found sound

- wet_catalog: key paths cannot traverse, href is pinned to the manifest's directory.
- wet_db_load: one transaction; rollback on a failed append, on a picked duplicate and on
  a count mismatch, each proven by its test. Primary key and index on create. Columns
  checked on reuse.
- wet_part_fetch: writes to a temp file, then checks it, then renames.
- The manifest is written to a temp file and moved into place.
- Content-MD5 base64 encoding.
- Stale-key deletion is confined to the prefix.
- The crate schemas, the registry path rule and the recursive bundled-YAML test.
