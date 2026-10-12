# Plan review (Plan agent, 2026-10-12)

Extracted by script from the reviewer's transcript.

# Review of the #7 publish plan (`/Users/airvine/Projects/repo/wet/planning/active/task_plan.md`)

**Verdict:** the layout holds together and nothing in it is unworkable. The three suspected blockers turn out not to be blockers:
- **crate types:** every column fits a type crate already has.
- **arrow vs duckdb:** package code can use duckdb only; arrow stays in the scripts.
- **duckdb and RPostgres in Suggests:** a guard pattern already exists for this.

Two things need fixing before the phases run:
- The Phase 4 tests would overwrite the real Postgres table.
- With arrow's defaults, the "sized row groups" goal can't be met.

The rest is gaps in guards, the manifest shape and the load strategy, plus some m4 preconditions nobody has checked.

Housekeeping: `research/discharge_publish.md` and its README row are already committed (d9e34ee, which landed during this review). Phase 1's boxes and `progress.md` ("Next: start Phase 1") are behind.

---

## Blockers

**B1. Phase 4 tests would overwrite the real table.**
- Evidence: `tests/testthat/helper-fwapg.R:3-18` connects `local_fwapg()` to the same local fwapg that Phase 6 loads into (task_plan.md:96, :114). The plan derives the table name from the dataset ID with no override (task_plan.md:95).
- Effect: any test run after Phase 6 replaces the real `historical` rows of `discharge.fwa_v1_segment_monthly` with fixture rows.
- Fix: give `wet_db_load()` a schema/table override, either an internal argument or `getOption("wet.db_schema")`. Tests create `wet_test_<random>`, `withr::defer()` a `DROP SCHEMA … CASCADE`, and assert they never touch the `discharge` schema.

**B2. With arrow's defaults, a part file is one row group, so nothing prunes.**
- Evidence:
  - `arrow::write_parquet(chunk_size = NULL)` calls `arrow:::calculate_chunk_size()`, which writes a single row group when rows × columns is under 2.5e8 cells.
  - The Fraser routed part is about 13.1M rows × 8 columns ≈ 1.05e8 cells.
  - The existing `data/wb/962a9cc2c4/fit_20260717/output/100.parquet` has 644,710 rows in 1 row group.
  - `segment_output.R:195` and `wb_output.R:74` both use the default.
- Effect: "sized row groups" (task_plan.md:46, :106) and the Phase 6 pruning measure (:113) fail with the obvious implementation.
- Fix: in `discharge_publish.R`, open `arrow::ParquetFileWriter$create(schema, sink, properties = ParquetWriterProperties$create(..., write_statistics = TRUE))`. Then call `writer$WriteTable(tbl_g, chunk_size = nrow(tbl_g))` once per watershed group, in sorted order. That gives exactly one row group per group per file: 246 groups, about 2.1k–66k segments each, so roughly 28k–860k rows per row group.
  - Measure pruning from footer statistics, not timing: for one group, count the row groups whose min ≤ g ≤ max against the total.
  - Target: 1 per file, or 2 where a group straddles basins.

### Not blockers (stated so they aren't re-raised)

- **crate types.** crate supports `integer`, `double`, `string`, `logical` and `datetime` (`~/Projects/repo/crate/R/crt_schema_apply.R:213-215`). Every segment and watershed column maps onto them:
  - `linear_feature_id` and `watershed_feature_id` are int32; `segment_output.R:111` asserts the max is below `.Machine$integer.max`.
  - `month` is integer, `pick` is logical, `period` and `watershed_group_code` are string, and the rest are double.
  - The nested YAML path works: `crt_schema_read()` uses `system.file(file.path("extdata", yaml_path))`, and the "every bundled schema YAML is registered" test lists files recursively (`tests/testthat/test-crt_registry_integrity.R:110-117`).
  - `file_name` is only ever compared as a string (`R/crt_registry_entry.R:9`), so a value with slashes is fine for `schema_only`.
- **arrow vs duckdb.** arrow is in no DESCRIPTION field, but only `scripts/` and `data-raw/` use it, and both are `.Rbuildignore`d. arrow 25.0.1 is on m1 with dataset, parquet and S3 support. Package code (Phases 3–4) must use duckdb only, including for writing test fixtures (`COPY … TO 'x.parquet' (FORMAT parquet)`).
- **duckdb and RPostgres in Suggests.** Use the existing guard pattern (`R/wet_station_daily.R:167-168`) and `skip_if_not_installed("duckdb")` in tests. `wet_db_load()` takes `conn` as an argument, so it only needs DBI (Imports). Check `inherits(conn, "PqConnection")` up front, because the DDL is Postgres-specific (`COMMENT ON`, schemas).

---

## Gaps

**G1. `crt_schema_conform()` sets a floor, not a ceiling, and changes values silently.**
- Evidence:
  - Undeclared columns pass through untouched (`crate/R/crt_schema_conform.R:25-28`; `crt_schema_apply.R:62`).
  - Columns are not reordered.
  - Coercion is `suppressWarnings(as.integer(x))` (`crt_schema_apply.R:66`), so 3.7 becomes 3 and an overflow becomes NA, with no message.
- Plan conflict: Hive keys are "documented but not columns" (task_plan.md:76), and `segment_output.R:119` writes a `source` column. `source` would therefore pass straight through conform into the files unless the script drops it.
- Fix, in `discharge_publish.R`:
  1. Assert each split frame has exactly one `source` value, then drop it.
  2. Read the ordered column list from the YAML and assert `identical(names(x), cols)`.
  3. Treat conform as a check, not a repair: assert column classes and NA counts are the same before and after.
  - Optionally add an exported `crt_schema_cols(source, file_name)` in the crate PR so wet doesn't need `crate:::crt_schema_read`.

**G2. crate has no nullability, range or enum checks** (`crt_schema_validate.R:232-240` lists them as future work).
- Fix: the publish script asserts these itself:
  - `month %in% 0:12`
  - `pick` has no NA
  - the key columns and `watershed_group_code` have no NA
  - `period` matches `^\d{4}-\d{4}$`
  - `q_m3s >= 0` where not NA
  - each part's rows are unique on (`linear_feature_id`, `month`)

**G3. The `pick` invariant is never re-checked after the split, and it is undefined for projections.**
- Splitting by source keeps `pick` correct only if both source files are cut from the same per-basin frame, which they are (`segment_output.R:186-193`). Nothing re-checks it after the split and conform, though.
- Internal inconsistency in the decided layout: `pick` spans sources and periods within a scenario (task_plan.md:41-42), yet projection partitions "will hold several periods". In `ssp245`, "one pick per segment and month" can't hold across several periods. The uniqueness key would have to be (scenario, period, …), but in `historical` the pick spans two different periods.
- Fix for v1:
  - Write the key down as (scenario, linear_feature_id, month) in the research doc and the crate YAML notes, and mark the projection pick as to be decided.
  - In publish, assert exactly one `pick` per (`linear_feature_id`, `month`) across all of a scenario's files before writing.
  - In Postgres, enforce it in the database with `CREATE UNIQUE INDEX … ON discharge.fwa_v1_segment_monthly (scenario, linear_feature_id, month) WHERE pick`. That index also serves fresh's subquery.
  - Any primary key must include `forcing`, `source` and `period`: (scenario, forcing, source, period, linear_feature_id, month). Otherwise it breaks when projections land, and that would be a key change without a column change, so no version bump.

**G4. The manifest shape is under-specified, so the writer and reader can drift.**
- Fix:
  - **Version field:** add `manifest_version: 1`. `wet_catalog()` refuses unknown versions; that is part of the "malformed manifest" test.
  - **Per-partition provenance, not one set per manifest.** The routed fingerprint and fwapg commit belong to `pcic_routed`. The fit release, province key and scoring md5 belong to `wet_balance`. A later separate rebuild of `ssp245` would make a single manifest-level block wrong. Return it as a second data frame attribute keyed by (dataset, scenario, forcing, source).
  - **Two commits:** the segment-build commit, parsed from `data/checks/segment_output_<release>.txt` line 3, and the publish commit.
  - **Schema reference:** crate version, `(source, file_name)`, and a raw GitHub URL to the YAML at the crate release tag, so non-R readers can resolve "names the schema".
  - **Drainage labels:** a top-level `codes` → `drainage` map.
  - **Merge rule:** state that each publish rewrites the whole manifest from the local tree, so the local tree must hold every scenario. Or define how entries for scenarios not being rebuilt are carried over.
  - The writer asserts every Hive value matches `^[A-Za-z0-9._-]+$`.

**G5. Href handling.**
- Fix:
  - Write hrefs relative to the manifest directory only, so the local `data/publish/…/manifest.json` and the uploaded one are byte-identical.
  - Resolve with `dirname()`, which works for both a path and a URL (cd does the same, `~/Projects/repo/cd/R/cd_catalog.R`).
  - The reader refuses hrefs that are absolute, start with a scheme, or contain `..`, so a manifest can't point outside its prefix.
- `wet_db_load()` must also read local hrefs in place. Phase 6 loads from the local tree before any upload (task_plan.md:114), but Phase 4 only describes "downloads each part with curl".

**G6. The Hive columns are gone from the files.**
- Fix:
  - `wet_db_load()` adds `scenario`, `forcing` and `source` as literals from the manifest row (`SELECT 'historical' AS scenario, … FROM read_parquet(?)`), not by parsing cache paths. Cache paths are flat and needn't follow the Hive layout.
  - Document a consumer recipe in `?wet_catalog`: `read_parquet([hrefs], hive_partitioning = true)` in duckdb gets the keys back from the URL paths. Make it a Phase 6 check.

**G7. Post-upload verification is size-only, and ETag is not md5 for multipart uploads.**
- Evidence:
  - task_plan.md:109 checks size only.
  - `aws s3 cp` goes multipart above 8 MB, and the larger parts (the Fraser files especially) are well past that. A multipart ETag is `md5-of-part-md5s-N`, not the file md5.
  - trap already rejected size as a proxy and reads back the md5 instead (`~/Projects/repo/trap/R/trp_snapshot_push.R:47-49, 313-325`).
  - No KMS appears in rtj's `modules/s3`, so the bucket uses SSE-S3, where a single-part ETag equals the md5.
- Fix:
  - Upload each part with `aws s3api put-object --content-md5 <base64>`. That is a single PUT, up to 5 GB, and S3 rejects a mismatch with `BadDigest`.
  - Then verify through the public href: either an anonymous HEAD comparing `ETag == md5` and `Content-Length == bytes`, or a download plus `tools::md5sum`. Going through the public href also proves the rtj policy applied.
  - Put the verify step in `R/` as an internal function, e.g. `wet_catalog_verify(catalog)`, sharing the download and md5 code with `wet_db_load()`, and test it on the local fixture tree. As written, the upload and verify path first runs after the PR, untested.

**G8. Removing stale parts and the overwrite window.**
- "Stale parts removed" needs credentialed listing with ListBucket, scoped to `s3://fresh-bc/discharge/fwa/v1/`. The script must refuse any key outside that prefix, and the dry run must print the planned deletes.
- Diffing against the old manifest alone misses orphans from an aborted publish.
- Because keys are overwritten in place with versioning off, readers between "parts uploaded" and "manifest uploaded", or after an aborted run, see md5 mismatches. That is fail-safe given G9's checks. Document it as "retry after the publish completes".

**G9. `wet_db_load()` details are missing.**
- Fix:
  - Verify size and md5 for every part before opening any transaction. That is what makes the "nothing is written" test meaningful: the test should assert the row count is unchanged after a prior load, not just that the table is absent.
  - Use `tools::md5sum` (base R; no `digest` dependency).
  - Cache under `getOption("wet.cache_dir", tools::R_user_dir("wet", "cache"))`, keyed by md5 rather than href, since hrefs are overwritten in place. Tests set the option to a tempdir.
  - Add a test for `watershed_monthly`. `pick_only = TRUE` must error for it, since it has no `pick` column.

**G10. Subset loads silently shrink the shared table.**
- The signature has `months` and `pick_only` filters (task_plan.md:93) and replaces the whole scenario's rows (:95). Loading `months = 0, pick_only = TRUE` would delete about 98M rows for every other consumer.
- Fix: record the filters in the table comment, and refuse a load whose filters differ from the existing table's unless `replace = TRUE`.

**G11. The publish freshness guards are weak.**
- "Segment table older than the fit" is an mtime check, as in `segment_output.R:75`. Add:
  - Refuse segment files that lack `watershed_group_code` (built before the Phase 5 change).
  - Refuse if `git diff --quiet <report_commit> HEAD -- scripts/segment_output.R scripts/pcic_routed_lib.R R/wet_source_pick.R` fails, i.e. the segment code changed since the table was built.
  - Optionally have `segment_output.R` write parquet key-value metadata (wet commit, routed fingerprint, release) and have publish check it.
- Reuse `segment_output.R:46-53`'s dirty check, and print `PUBLISH run` or `DRY RUN` as the first line (CLAUDE.md:545).

**G12. Watershed dataset decisions are missing.**
- The `discharge_m3s` → `q_m3s` rename is in the plan but nothing tests it.
- The `period` constant is hard-coded in `segment_output.R:120-121`. Move `period_routed` and `period_balance` to a shared lib so publish doesn't redefine them.
- NA rows: `wb_output_20260717.txt:5` reports 22,041 watersheds with NA annual. `segment_output.R:159` drops NA-balance segments. Decide whether `watershed_monthly` keeps NA rows, and record the choice.
- `wb_output.R` writes month-major order (`wb_output.R:66-67`), so publish must re-sort.

**G13. Phase 2 misses crate's own process.**
- crate's `inst/extdata/schemas/README.md` (steps 5–6) and `data-raw/crate_registry.R:30-31` require:
  - a decision entry, `decisions/nge/<YYYYMMDD>_discharge_dataset_ids.md`, recording that `file_name` may now be a path-style dataset ID;
  - a conform test in `tests/testthat/test-crt_schema_conform.R`.
- The proposed integrity test should cover every row, since all existing rows already satisfy `schema_yaml == schemas/<source>/<file_name>.yaml`. Also assert the YAML's `file:` field equals `file_name`.
- `units:` and `notes:` keys are ignored at runtime, so they are safe as documentation.

**G14. The fixture tree under `inst/extdata` produces an R CMD check NOTE.**
- Evidence: `wet/inst/extdata/discharge/fwa/v1/segment_monthly/scenario=historical/forcing=PNWNAmet/source=pcic_routed/part-100.parquet` is 122 bytes. `tools:::.check_packages`' `check_file_names()` flags any path over 100 bytes as non-portable. `=` itself is allowed.
- Fix:
  - Ship only a short-named manifest in `inst/extdata`, for example `inst/extdata/discharge_manifest.json`, for the `wet_catalog()` example. The example reads only the manifest.
  - Tests build the Hive tree in `withr::local_tempdir()` with duckdb `COPY` plus the internal manifest writer. That exercises the writer, keeps binaries out of git, and avoids arrow.

**G15. The drainage-label rule is undefined.**
- task_plan.md:43 says "named mainstem, or else largest watershed groups" without saying how.
- Note what `code` actually is: the basin of the segment's lut watershed (`segment_output.R:128-132`). In local fwapg it equals the first field of the segment's own wscode for all but about 10 segments.
- All 208,189 segments coded 999 have no lut row and get no rows; `segment_output_20260717.txt` shows 0 segments for 999.
- Fix: write the label rule as SQL in the publish script:
  - the `gnis_name` of the blue line whose `wscode_ltree` is `<code>`;
  - else the top 2–3 groups by segment count.
  - Hard-code nothing.

**G16. Phase 7's pkgdown step is bigger than it looks.** `_pkgdown.yml` has no `reference:` section (3 lines total). Adding "reference entries" means listing all 41 exported functions, or `check_pkgdown()` fails. Either skip it or do the full index as a separate task.

---

## Ordering

**O1. Open the crate PR first, and branch from crate's `main`.**
- The local crate checkout is on `11-nothing-runs-the-test-suite-add-r-cmd-ch`, with PR #30 open. Branch from `main`.
- Merge and release it, as 0.7.0 or whatever crate's flow assigns, before any Phase 5 code calls it.
- Phases 3–4 don't depend on crate and can proceed in parallel.

**O2. Depend on crate without a branch pin, using the cd pattern.**
- Add `crate (>= 0.7.0)` to Suggests and `NewGraphEnvironment/crate` to Remotes. `DESCRIPTION:32, 50-54` already do this for cd. Remotes without a ref resolves to the default branch.
- The script checks `packageVersion("crate") >= "0.7.0"` and writes the version into the manifest.
- m1 has crate 0.4.0 installed (current is 0.6.0). m4 needs `pak::pak("NewGraphEnvironment/crate")` after the release.

**O3. Within Phases 5–6:**
- The `segment_output.R` change must be committed before the m4 rerun, or the dirty check at `:51-53` refuses.
- Never rerun `wb_output.R` in between: it deletes `segment/` (`wb_output.R:30-33`).
- Alternative: add `watershed_group_code` in publish from fwapg, as is already planned for watersheds. That needs no `segment_output.R` change and no rerun. Either works; the plan currently does both the column and the sort in two places.

**O4. Do Phase 3 before Phase 4.** `wet_db_load()`'s tests consume `wet_catalog()` and the internal writer.

**O5. Upload ordering in the "After the PR" step is right:** the rtj apply comes first, so the anonymous verification (G7) is possible.

---

## Assumptions

**A1. m4 must be in a known state.**
- Unverified preconditions:
  - The routed table's fingerprint must still equal `40524444 rows, 3377037 segments, 0 null flows, total 178035348.248310 m3/s` from `pcic_routed_compare_20260717.txt`, with `WET_FWAPG_COMMIT=341b078`. Otherwise `segment_output.R:97-100` refuses, and `pcic_routed_compare.R` has to be rerun first, producing new tracked reports.
  - m4 needs arrow, crate ≥ the new release, and a clean checkout of this branch.
- Make "run `routed_fingerprint(conn)` on m4" the first step of Phase 6.
- m1 cannot stand in:
  - `data/wb/962a9cc2c4/fit_20260717/output/` holds only `100.parquet` and `400.parquet`, month 0 only.
  - There is no `segment/`.
  - `segment_output.R:80-83, 138` refuses this bundle.
- So `discharge_publish.R` needs a way to be exercised before m4: put its split, conform, row-group writer and manifest core in functions run on a small synthetic frame.

**A2. Memory.**
- Publish works per code. The Fraser is about 26.3M rows: balance 13 × 1,012,084 plus routed 13 × 1,010,776. That is roughly 1.5–2.5 GB per copy in R, fine on m4; `segment_output.R` already uses about 10 GB for the Fraser.
- `wet_db_load()` must not materialise a dataset. A segment row is about 52 B in R, so all 102.8M rows would be over 5 GB. On top of that, `RPostgres:::db_append_table` → `sql_data_copy()` makes a converted copy per append.
- Stream instead: duckdb `dbSendQuery()` + `dbFetch(n = 1e6)` → `dbAppendTable()`. COPY is the default for `PqConnection`, confirmed in RPostgres 1.4.10.

**A3. Postgres size and time.**
- Roughly 102.8M rows × about 110 B is about 11 GB of heap, plus indexes.
- DELETE plus INSERT of a whole scenario in one transaction doubles the space, writes about 20 GB of WAL, and maintains the indexes row by row.
- Fix: LIST-partition by `scenario`. Load into a standalone staging table with `CHECK (scenario = '…')`, build its indexes and run `ANALYZE`, then in one short transaction detach and drop the old partition and attach the new one.
- Phase 6 should record load time, table size, index size, and free space on the fresh-db Docker volume on m4.

**A4. Integer width.**
- Use `bigint` for `linear_feature_id` in Postgres, to match FWA.
- crate has no int64 type, so a future `discharge/chn/v1` with 64-bit IDs would need a new crate type. Note it in the decision entry.

**A5. The upload tool and machine are unspecified.**
- The aws CLI is at `/opt/homebrew/bin/aws` on m1; m4's credentials are unknown.
- The manifest makes the tree self-verifying, so it can be rsynced from m4 to m1 and uploaded there. Say which.

**A6. `forcing=climr` names only the balance's climate input.** Its AET is CGIAR. The research doc covers this; the manifest's source description should too.

---

## Scope

- **S1.** `watershed_monthly` roughly doubles the surface of Phases 4–5, so give it explicit tests (G9, G12) or defer its Postgres load.
- **S2.** The upload code ships in the PR but first runs after it. Move verification into tested `R/` code (G7), or accept and state that the upload path is untested.
- **S3.** Phase 7's pkgdown item (G16).

---

## Acceptance (Validation, task_plan.md:127-132, is generic)

Add numbers checked against the tracked reports:

**Segment dataset** (from `segment_output_20260717.txt`):

| check | expected |
|---|---|
| total rows | 102,790,688 |
| routed rows | 43,901,481 = 13 × 3,377,037, the routed table's segment count |
| balance rows | 58,889,207 = 13 × 4,529,939 |
| `sum(pick)` | 58,926,959 = 13 × 4,532,843 |
| fresh's subquery | 4,532,843 rows, `count(DISTINCT linear_feature_id)` equal to it |
| fresh's subquery by `source` | 3,152,838 routed, 1,380,005 balance |
| part files | about 20 routed (no 800, 945, 990, 999) and 23 balance |

**Watershed dataset:** 42,190,889 rows (`wb_output_20260717.txt:4`) in 24 parts, including 999.

**Other checks:**
- Every part file has an identical arrow schema, and the column order matches the crate YAML.
- After the m4 rerun of `segment_output.R`, the report diff touches only the wet-commit line.
- Pruning: at most 1–2 row groups per file per group, from footer statistics.
- A duckdb `read_parquet(hrefs, hive_partitioning = true)` over the local tree returns the three Hive keys with the counts above.
- Add `devtools::check()` with no new NOTE (see G14) to Validation, next to Phase 7's document, lint and check_pkgdown.

---

### Critical Files for Implementation
- /Users/airvine/Projects/repo/wet/scripts/segment_output.R
- /Users/airvine/Projects/repo/wet/tests/testthat/helper-fwapg.R
- /Users/airvine/Projects/repo/crate/R/crt_schema_apply.R
- /Users/airvine/Projects/repo/crate/tests/testthat/test-crt_registry_integrity.R
- /Users/airvine/Projects/repo/trap/R/trp_snapshot_push.R (prior art for the md5 read-back and a local test backend)
- /Users/airvine/Projects/repo/wet/DESCRIPTION
- /Users/airvine/Projects/repo/wet/scripts/wb_output.R
