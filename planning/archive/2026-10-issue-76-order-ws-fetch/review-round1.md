# Code-check round 1: branch 76-order-wet-ws-fetch-rows-so-province-runs (vs 47ed65e)

## Checklist read

- **code-check.md** (37 H3): read all 14 prose sections under `## Mechanisms`, table rows skipped (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice). Not read in full: 23 (standalone, security, spreadsheet rules; I checked them against their index lines only).
- **code-check-r.md** (111 H3): read 17 in full: Tests that silently do not run; testthat counts an uncaught error under `error`; A `skip_if_not()` skips only its own block; `expect_gt()` takes no `info`; A database driver's value is not a base R type; `identical()` on two reader results; Under `R CMD check`, tests run against the installed package; `sort()`/`order()` collate by `LC_COLLATE`; `identical(-0, 0)`; `match()` treats NA as a value; `tolerance` in testthat is relative; Postgres row order is never fixed unless the query fixes it; `sprintf("%g")` into SQL; An `information_schema` lookup; Rscript reads a script as it runs; A range total as the difference of running totals; A `pkg::` call in a test. Not read in full: 94 (checked against their index lines only).
- **code-check-shell.md** (67 H3): read 0 in full. The diff has no shell code, so I checked all 67 against their index lines only.
- **code-check-spatial.md** (93 H3): read 4 in full: terra `extract()` beyond the raster / by centre; Canonicalize geometry before hashing; terra keeps results in memory; sf and terra can link different GDALs. Not read in full: 89 (checked against their index lines only).

## Clean

No issues found.

### What I verified, so the verdict is not just a quiet round

- **The row-order guards fire when the bug is put back.** I ran `git archive HEAD` into a scratch copy and ran the three changed test files with `NOT_CRAN=true`, `WET_PGHOST=127.0.0.1` and live fwapg. All blocks pass: `test-wet_upstream_sums.R` 11/11, `test-wet_station_snap.R` 4/4, `test-wet_ws_sample.R` 7/7. Then I swapped in `R/wet_upstream_sums.R` exactly as it is at 47ed65e. All three new tests fail: "row order of ws" (2 failed), "row order of irregular_pairs" (2 failed) and "a basin from fwapg" (1 failed, at test-wet_upstream_sums.R:173: area_m2 differs in the last bits). Each counts `failed` with 0 `error`.
- **`wet_upstream_sums()` gives the same bits for any row order.** Three things decide the result, and none depends on input order:
  - the leaf values: `rowsum()` adds rows in the order given, which is now (key, id);
  - the segment-tree queries;
  - the irregular additions: they are grouped by `ia` and, within each watershed, added in `id_up` order.
  The `"irregular"` attribute still follows `ws` row order. It is not a sum, `wb_upstream_identity.R` compares it as a sorted set, and the fetch now returns rows in id order anyway.
- **Every new `ORDER BY` ends on a unique key**, checked on the local fwapg:
  - `fwa_watersheds_poly.watershed_feature_id`, `fwa_bcboundary.bcboundary_id` (28,001 rows, 28,001 distinct, pkey) and `fwa_streams_watersheds_lut.linear_feature_id` are primary keys;
  - `fwa_stream_networks_discharge.linear_feature_id` is a primary key and `fwa_stream_networks_sp.linear_feature_id` is unique (4,907,441 of 4,907,441), so the mad scripts' joins stay 1:1 on `linear_feature_id`;
  - in `wet_upstream_irregular()` and `wet_upstream_pairs()`, the pair `(a.id, b.id)` is unique.
- **The snap tie-break is safe.** `linear_feature_id` is unique within a station's candidates because the lut is keyed on it. The old `order()` is stable, so the new test with `cd[2:1, ]` would have returned 7 before this change.
- `identical(irr, irr[order(...), , drop = FALSE])` holds for automatic row names, both on a 0-row frame and on a non-empty one (measured).
- `sort(unique(ws$watershed_group_code))` sorts four-letter upper-case codes, so the order cannot depend on locale.
- Lint warnings in the changed files are all on lines this branch did not touch.

### Notes (not defects)

- `planning/active/findings.md:55` says the sums of a shuffled basin 925 "were identical even on main". In my run, main's `wet_upstream_sums.R` with the branch's ordered fetch fails that test's final `expect_identical` at line 173. So the fwapg test does reach the defect in the sums, not only the fetch-order premise. The findings row may describe an earlier version of the test, and is worth correcting.
- `scripts/wb_upstream_order.R` calls the irregular pairs from the live fwapg, against polygons stored by older runs. If the database has changed since those runs, `wet_upstream_sums()` stops with a pairs error rather than a clear "the database moved". The failure is loud, not silent, and the header already says the script needs fwapg.
- The R files changed here are also in `scripts/wb_term_diagnose.R`'s `pcic_key`, so its PCIC caches rebuild on the next run. That is a cache key, not a refusal.
