# Code-check round 3: the mechanism behind rounds 1 and 2, enumerated (branch 164, HEAD a4741ff)

## Checklist read

- code-check.md, `## Mechanisms`: I read the prose of every H3 (not the `|` rows). "One fact derived twice", "A guard's scope, escape hatches, and remedies", "Restore the bug and prove the guard fires" (the paragraph on a guard whose two operands are derived from each other), "Verification that reads its own output" and "A guard that fails toward pass" decided the findings below.
- code-check-r.md: "`$` on a list partial-matches", "`data.frame()` recycles a scalar against a zero-length column", "as.POSIXct on character infers ONE format", "A database driver's value is not a base R type", "`identical()` on two reader results tests the reader", "jsonlite writes an empty name", "`sort()` and `order()` collate by `LC_COLLATE`", "`paste()` with a zero-length argument", "Postgres row order is never fixed", "`vapply(..., USE.NAMES = FALSE)`".
- code-check-shell.md and code-check-spatial.md: I read the indexes. No heading names a tool or shape this diff uses beyond what the R file covers (`aws s3api` put/list was already there).

## Mechanism

Rounds 1 and 2 had the same cause: one fact was decided in two places by two separate expressions, and the code relied on the two agreeing. Nothing compared them, or the only comparison was between values that come from the same source and so can never differ. In round 1 the env var decided the mode while the catalog read decided the content. In round 2 the env var decided the report's path while the manifest read decided its label. In wet#171, two exclusion lists hold the same policy. The rounds-1/2 fix (`catalog_live`) was the right shape: decide the fact once, then have every consumer read that one value, and assert at the end that the catalogs actually read agree with it.

## Enumeration

Each place this diff reaches, with its two derivations, whether they can disagree, and what follows.

1. **Parts vs fit files.** The parts are chosen by `startsWith(keys, "fit/")` in three places: `wet_manifest_write` (R/wet_catalog.R:258), `wet_receipt_write` (`parts <- files[!startsWith(files, "fit/")]`) and `part_keys` in discharge_publish.R:470. The fit files are an explicit list, `fit_files`, written into both the manifest and the receipt. On read, `wet_manifest_files` checks fit keys with `^fit/[A-Za-z0-9][A-Za-z0-9._/-]*$`.
   - Can they disagree? Only loudly. A fit key that passes `startsWith` but fails the regex (a space, or `fit//x`) is refused by `wet_catalog(f_pending)` during BUILD, before anything is published. A part key under `fit/` would fail `wet_part_parse`. A stray parquet file under `fit/` that is missing from `fit_files` is left out of both the receipt and the manifest. Root is wiped at line 313, so no stale files remain.
   - Consequence: none.

2. **The receipt key `receipt.json`.** Four places spell it out: crate's default `file =`, the read-back and return in `wet_receipt_write`, the `^receipt\.json$` check in `wet_manifest_files`, and BUILD's unlink plus PUBLISH's `no-cache` test.
   - Can they disagree? Only if crate changes its default. The read-back of `file.path(root, "receipt.json")` would then find nothing and stop (BUILD unlinks the old file first).
   - Consequence: none silent. Passing `file = "receipt.json"` to `crt_receipt_write` would pin it, but this is not a defect.

3. **Fit roles `fits`/`sample` and the sample-key regex.** discharge_publish.R names the roles through `fit_files`. segment_group.R selects with `role == "fits"`, `role == "sample"`, and `sub("^fit/sample/part-([A-Z]{4})\\.parquet$")`.
   - Can they disagree? Yes, but loudly in every case:
     - With no `fits` row, `fetch_fit(integer(0))` errors on the column assignment.
     - With two `fits` rows, `&&` gets a length-2 condition and errors.
     - A sample key that does not match the regex leaves its group as the whole key, so `setdiff(groups, smp_pub$group)` stops the run.
   - `i_smp` indexes `which(role == "sample")`, the same population as `smp_pub`, so the two stay aligned.
   - Consequence: none.

4. **PUBLISH: the keep set, the files uploaded and the files verified.** All three come from one value, `files_local <- wet_catalog_files(cat_local)`:
   - parts are uploaded from `cat_local`;
   - the extra files are `files_local` minus the part keys;
   - the keep set is `files_local$key` plus the manifest;
   - the verify after the upload reads `files_pub` and holds it `identical()` in key and md5 to `files_local`.
   - Can they disagree? No.

5. **The files the receipt hashes vs the files the manifest lists.** The receipt hashes `c(part_keys, fit_files)`: a listing of root at line 470, plus the list. The manifest lists its own listing of root (taken inside `wet_manifest_write`), plus the same list. Nothing writes to root between the two calls, so they cannot disagree today. Nothing checks it, though: the only receipt-vs-manifest guard (discharge_publish.R:506) compares the manifest's `recipe_id` with `receipt$recipe_id`, which is the value that was written into the manifest. It is also a recipe hash, which says nothing about the files. See Finding 1.

6. **`publish_fit_lines()` as BUILD writes them vs as `publish_report_check()` requires them.** BUILD computes the lines from `wet_catalog(manifest.pending.json)`, PUBLISH from `wet_catalog(manifest.json)`: the same file, renamed. The digest uses only key and md5, and `%.2f GB` is deterministic, so they agree.
   - The gate, though, is keyed on `attr(cat_local, "fit")` while the lines cover the fit and the receipt. A manifest that lists a receipt but no fit skips the check, and its receipt is uploaded without the report naming it. See Finding 3.
   - A manifest with a fit but no receipt stops inside `publish_fit_lines`, which is loud.

7. **`catalog_live` vs the catalogs actually read** (`cat_fit` at segment_group.R:99, `cat_pub` at :162). Both calls to `wet_catalog()` use the same default expression as `catalog_live`, and line 490 asserts they agree, so they cannot disagree.
   - The comparison is by manifest string, though, and `cat_fit` and `cat_pub` are two reads of one URL taken minutes apart. A PUBLISH in between would pass the string check with two different builds.
   - It is benign, because the fit files actually used are verified against the live URL after the build (`n_fit_ok`), and the parts are verified before and after their own read. If the fit changed, the run stops. If only parts changed, the fit used is byte-identical to the new build's fit.
   - Consequence: none. `identical(attr(cat_fit, "built"), attr(cat_pub, "built"))` would make the "one build" claim literal; this is not a defect.

8. **The subset text in the table comment vs in `wet_load`.** Both now read one variable, `subset`, set once inside the transaction (R/wet_db_load.R:141). They cannot disagree, and the `wet_load` DELETE has the same key (one dataset per table, per scenario) as the data DELETE.

9. **BUILD's dirty-path list vs the files that affect the tree.**
   - The receipt hard-codes `dirty = FALSE`. BUILD checks `R scripts data/checks DESCRIPTION inst/receipt`. The only file under `inst/` that the build path reads is `inst/receipt` (`system.file` grep: chapman_table3.csv is not on this path).
   - `NAMESPACE` is outside the list. A dirty NAMESPACE could change what `load_all` imports while the receipt says the tree was clean. That is pre-existing for the manifest's commit, now restated in the receipt, and marginal.
   - PUBLISH's `changed` check covers only `R scripts`. That is correct, because the tree is pinned by the manifest's md5s and `built_at` rebuilds it.
   - Consequence: none actionable.

10. **The receipt's inputs vs the manifest's provenance.**
    - `province_run`, `release`, `score_code_md5`, `built_time` and the wet version are each one variable, written into both. They agree.
    - The `fwapg` input is a second derivation of the routed line, and fails toward pass. See Finding 4.

11. **`publish_own` vs `segment_daily_output.R`'s `own`.** This is wet#171, accepted; I do not re-flag it. I checked that no table-feeding script (`segment_output.R`, `segment_daily_output.R`, `wb_output.R` and their libraries) calls anything defined in the newly excluded `R/wet_segment_daily.R` or `scripts/segment_group.R`, so the new exclusions do not hide a dependency.

12. **The fit's `province_run` as manifest data vs as a filesystem path.** Fit keys are checked for traversal (`(^|/)\.\.(/|$)`). `province_run`, from the same manifest entry, becomes a write path in segment_group.R with no check. See Finding 2.

## Findings

- **[severity: fragile]** scripts/discharge_publish.R:506. The guard `identical(attr(cat_local, "receipt")$recipe_id, receipt$recipe_id)` cannot fail. `attr(cat_local, "receipt")$recipe_id` is `receipt$recipe_id` read back through the manifest it was just written into (wet_catalog.R:313, then :128). It is also a recipe hash, which is independent of the files.
  - Nothing in BUILD or PUBLISH compares the receipt's `result$parts` (the files crate hashed, from `part_keys` at line 470) with the files the manifest lists (from `wet_manifest_write`'s own `list.files`).
  - The two listings agree today only because nothing writes to root between them. A later edit that adds a file to one list but not the other would publish a receipt naming a different file set from the manifest, and every guard would pass.
  - Fix: `setequal(names(crate::crt_receipt_read(file.path(root, "receipt.json"))$result$parts), setdiff(wet_catalog_files(cat_local)$key, "receipt.json"))`, in place of, or beside, the tautology.
  - **Rule:** code-check.md "Restore the bug and prove the guard fires" (a guard whose two operands are derived from each other has no true branch); "One fact derived twice".

- **[severity: security (low)]** scripts/segment_group.R:111, with R/wet_catalog.R:139-143. `key_dir <- file.path("data", "group_published", pfit$province_run)` takes `province_run` straight from the manifest. `wet_catalog()` checks only that it is one string.
  - The same manifest's fit keys are refused for `..` (wet_catalog.R:175), so the code treats manifests as untrusted for keys but not for this field.
  - A manifest with `province_run = "../../x"` sends the published-mode writes (`out_dir` parquet, `wb_fit_dir`) outside `data/group_published/`.
  - Reachable through `WET_CATALOG_URL`, or through a tampered live manifest. The later `prov_bal$province_run == basename(key_dir)` check compares two fields of the same manifest, so it does not stop this.
  - Fix: check `province_run` (and `release`) in `wet_catalog()` against a safe pattern such as `^[A-Za-z0-9][A-Za-z0-9._-]*$`.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (the guard covers one field of an entry and not its sibling).

- **[severity: fragile]** scripts/discharge_publish_lib.R:68. The PUBLISH gate requires the report's fit-and-receipt lines only when `attr(cat_local, "fit")` is non-NULL, but those lines certify the receipt too: its md5 is in the "tree fit and receipt md5" digest, and its `recipe_id` is a line of its own.
  - `wet_catalog()` accepts a manifest with a receipt and no fit. Such a tree skips the check, and PUBLISH uploads its `receipt.json` (it is in `files_local`) under a report that names no receipt.
  - Unreachable from this BUILD, which always writes both. The condition reads the wrong fact: it should test for any non-part file (`nrow(wet_catalog_files(cat_local)) > nrow(cat_local)`), or for the receipt as well, not the fit alone.
  - **Rule:** code-check.md "One fact derived twice"; "A guard's scope, escape hatches, and remedies" (key the guard to the outcome, not to the flag).

- **[severity: fragile]** scripts/discharge_publish.R:477. `fwapg = sub("^.* at ([0-9a-f]+)$", "\\1", routed_line)` returns the whole routed line when the pattern does not match.
  - The pattern fails if the commit is missing, the line has trailing text, or the commit is in upper case. The published receipt's `fwapg` input then silently becomes "pcic.discharge_monthly (...)". It also repeats the commit that `WET_FWAPG_COMMIT` and the routed report already hold, as a second derivation.
  - The line matches today ("... built by NewGraphEnvironment/fwapg at 5d50cc1" in data/checks/segment_output_20260717.txt).
  - Fix: assert the match, e.g. `stopifnot(grepl("^.* at [0-9a-f]{7,40}$", routed_line))`, before taking the commit.
  - **Rule:** code-check.md "A guard that fails toward pass" (a fallback that fires on a missing input proceeds on a choice no rule made).

No bug found that fails a run or loses data on the current inputs. The four findings above are guards that cannot fire, or that read a narrower fact than the one they protect.
