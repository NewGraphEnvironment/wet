# Code-check round 1, branch 102 (git diff b8fe71c...HEAD, planning/ excluded)

## Checklist read

- code-check.md (329,057 bytes): every H3 under `## Mechanisms`, prose only with `|` rows skipped (all 14: guard fails toward pass, fixture, proxy, verification reads own output, guard scope/escape hatches/remedies, fix in one of two callers, restore the bug, shared working tree, wrapper's exit, zero-length/empty/unset, probe broken, written data outlives the fix, serialization, one fact derived twice). Of `## Rules that stand alone`, `## Security` and `## Spreadsheets and PDFs` I read the index lines only; none applies to this diff. 22 headings not read in full.
- code-check-r.md (175,296 bytes): read in full the sections "`$` on a list partial-matches", "`identical(-0, 0)` is TRUE", "`vapply(..., USE.NAMES = FALSE)`", "`expect_false(identical(x, y))`", "`tolerance` in testthat is RELATIVE", "`[[` on a named ATOMIC vector", "Rscript reads a script as it runs" and "`ifelse()` with an all-NA test". For "`paste()` with a zero-length argument", "`switch`/`sprintf` with NULL" (index: zero-length) and "A data-raw script must load the source tree" I used the index line and checked the code against it. About 115 headings not read in full, because nothing in the diff uses them (DBI, sf, duckdb, arrow, cli, pak and so on).
- code-check-shell.md (119,509 bytes): index only. The diff has no shell code. 0 headings read in full.
- code-check-spatial.md (154,440 bytes): index only. The only spatial logic is `wet_fwa_upstream()`, which is unchanged and only reused (FWA codes in C collation). 0 headings read in full.

## What I checked, with probes

- `wet_donor_mean()` against the old donor branch of `wet_shape_predict()`. The arithmetic is the same, and `wet_shape_static()` still refuses NA, so the new NA path cannot reach the shape code. The copied tests pass in a scratch copy: test-wet_shape.R 66 passed and test-wet_share_fit.R 36 passed, with 0 failed, 0 errors and 0 skipped under `NOT_CRAN=true`.
- The example in `wet_share_fit()` runs. Its stated claim holds: May to July shares are 0.128 for the low watershed against 0.202 for the high one.
- `$` partial matching. `cvr$share_method` sits beside `share_method_rule`, but both are always written together. Old files hold neither name or a prefix of it (`share_spec`, `share_rule`, `share`). `fit$method` on a pre-#102 fit (`coef`, `terms`, `static`, `n`) is NULL, as intended.
- The identity guard `identical(sm_cv$regression, cv$shares[[ship_share]])`. The two routes match:
  - Rows: `predict_cv()` asserts no NA in any share predictor, so both routes fit on the same rows.
  - Splits: both use `fold != f` for training and the same held-out rows in the same order.
  - Fills: both fill matrices that carry no dimnames.
  - The guard can fire only on a real divergence.
- Rule code against the header registered at a8ca570:
  - The header changed only by the disclosed "four details" paragraph.
  - The gain is tested at ≥ 0.01 − 1e-9 in both pools.
  - On a tie, `which.max` takes donor first.
  - Each held-out gauge's pool is `fold != fold[i] & !related[i, ]`, the same as #70's leak set.
  - `related` is built on `cal` after the merge, in the same row order.
- The headwater gate still reads only annual `mae_pct`, so the share method cannot move it. `cv_v`, `lo` and `plain` are all computed after `cv$share` is replaced.
- Consumers:
  - `wb_output.R`, `discharge_publish.R` and `monthly_vignette_data.R` refuse a pre-#102 fit or cv file. They do it through `code_md5`, through a `switch(NULL)` error, or through `identical(cv_share, NULL)`, and in every case they fail loudly.
  - A `"blend"` outcome stops the publish description, which is the intended guard.
  - The `wb_output` report line that changed is not parsed: `discharge_publish.R` parses only the `^[0-9]{3} ` basin rows.
- Hashes:
  - `R/wet_donor_mean.R` is in `score_files_for()` and in the `shape_files` of `wb_shape_daily.R`.
  - `wet_share_fit()` and `wet_share_predict()` call no other unhashed package file.
  - `wet_nse()` is in the hashed `R/wet_flow_validate.R`, and `wet_fwa_upstream()` is in the hashed `R/wet_cv_folds.R`.
  - DESCRIPTION has no `Collate` field to update.
- Cost: `wet_donor_mean()` takes about 7 s of CPU per 100k watersheds with 315 donors (22 s wall time on a busy machine). Across 3.25 M watersheds in `wb_output.R` that is minutes, not a problem.

## Findings

- **[fragile — wrong claim in a tracked report, in a hashed file]** scripts/wb_aet_compare.R:249. The report prints `"Monthly shares use CGIAR monthly AET for every variant; differences here are annual only."` The diff fixed the same claim in the sibling report header at scripts/wb_validate.R:255-257 (`switch(ship_method, donor = "monthly shares from the donor gauges' observed shares", ...)`) but left this one alone. That is the "fix lands in one of two callers" shape.
  - Under the outcome the m1 probe forecasts (donor ships; findings.md, 0.9389 against 0.8735), the shipped monthly shares use no AET at all. `data/checks/wb_aet_compare_<release>.txt` would then state something false about the fit it decides.
  - The second half of the sentence, that differences between variants are annual only, stays true.
  - Why it matters now: `scripts/wb_aet_compare.R` is in `score_files_for()`. Correcting it after the ten scoring runs stales every one of them, the winner and the fit, so it has to change before those runs.
  - It cannot read `ship_method` directly, because the comparison runs before any one fit is written. Two options: read `share_method` from the cv files it already loads, which every variant shares, or say that the shares do not depend on the annual AET variant.
  - No number is wrong; only the sentence is.

No other issues found. The guards fail loudly in the stale and pre-#102 cases, and the rule code matches its registered header.
