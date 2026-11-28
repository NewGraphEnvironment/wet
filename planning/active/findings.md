# Findings — Backlog move 15: Re-run the segment chain and a publish BUILD after 0.4.40 (#208)

## Issue context

Batch 17 of move 15: re-run the segment chain and a publish BUILD after 0.4.40 (#186, PR #197), expecting every part byte-identical to the live manifest and no upload. The live build is a0318b7 (5d50cc1 routed run, 512 parts, receipt and fit beside them).

## Measured 2026-11-25

- A reduced bundle's `data/wb/768876badf` is 31 MB: `fit_20260717/` (output, shape files) and `upstream/`; no `segment/` or `segment_daily/`. The chain needs the full province run.
- `scripts/discharge_publish_own.R` is the one list of non-inputs both code guards read (#171); #186 moved `R/wet_segment_daily.R`, `R/wet_segment_monthly.R` and the departure/pilot scripts onto it.

## Measured 2026-11-27 to 11-28 (UTC)

**Probes before the runs.** The database answered within a 10 s connect timeout. arrow 25.0.1 and duckdb 1.5.6, as in the live report. crate was **0.21.0**, not the plan's 0.16.0, and was left installed: between the two tags the discharge schemas, `crt_schema_conform()` and the receipt writer are unchanged, and wet reads schema YAML directly (`publish_schema_cols()`). Routed monthly fingerprint 179854603.510890 at 5d50cc1; daily fingerprint equal to the tracked report's; fit `cfu`, scoring md5 df3280b5 unchanged.

| run | time | result |
|---|---|---|
| `segment_output.R` at 6a1d7316 | 8.5 min | 23 of 23 parquet files md5-identical to the set-aside table; the report differs in its commit line |
| `segment_daily_output.R` at 40e25e56 | 2 h 10 min | 246 of 246 md5-identical; the report differs in its commit line and `elapsed` |
| `discharge_publish.R` BUILD at 2ee50dc4 (`WET_PUBLISH` removed) | 3 h 18 min | 512 of 512 parts identical to live build a0318b7; tree parts md5 d554e3aad481d86bffa4baef687287ed; 16 of 16 cross-checks `ok`, no `FAIL`; 15,040,448,264 values compared, 0 differing; nothing uploaded |

**The two other digest lines that moved** (`tree fit and receipt md5`, `receipt recipe_id`), which the plan did not list: the new manifest and the live one each list 760 files, and of those only `receipt.json` differs, so all 512 parts and 247 `fit/` files are identical. The manifests themselves differ too, since the new one names the new build; they are not among the 760. Its five differing fields are `context.time`, `recipe.code.wet.commit`, `recipe.code.wet.version` (0.4.35 to 0.7.0), `recipe.config.settings.crate_version` (0.16.0 to 0.21.0) and `recipe_id`, which follows from the recipe.

**The live objects themselves** (2026-11-28 04:53 UTC). The BUILD's per-part line compares local md5s with the md5 fields of the downloaded live manifest (`publish_live_line()`); it reads no live part, and the branch of the script that does is PUBLISH's. So after it, `wet_catalog_verify(wet_catalog_files(wet_catalog()))` sent an anonymous HEAD for each file: 760 of 760 (512 parts, 247 fit files, the receipt; 34,805,125,351 bytes) match the manifest's size and md5 (the ETag of a single PUT), parts digest d554e3aad481d86bffa4baef687287ed. Given a wrong md5 for one real object and a key that does not exist, it reported both as failing (`etag ... is not the md5`; `HTTP 403`). With the BUILD's line, the live parts are the rebuilt parts byte for byte.

**Guards after the runs.** `vd_published()` and `vd_segment_report()` pass on the new reports against live. `test-publish_own.R` (13 expectations) and `test-publish_report_live.R` (33) pass.

**`main` moved during the runs** (v0.7.1: moves 19, 22 and 26; merged at c64f84bf). With it merged, the monthly guard's own diff from 6a1d7316 lists 12 files: `R/wet_hakai.R`, `R/wet_logger_daily.R`, `R/wet_station_daily.R`, `R/wet_station_list.R`, `R/wet_temp_daily.R`, `R/wet_temp_fill.R`, `scripts/station_regulation.R`, `scripts/station_regulation_rule.R`, `scripts/station_sources_hakai.R`, `scripts/temp_logger_thresholds.R`, `scripts/temp_loggers.R`, `scripts/temperature_bayesian_alignment_check.R`. None is on `publish_own`, so a BUILD at this head would refuse the tables until they are rerun or those files are checked and listed. No code change here (the plan's scope is three reports).

## Errors Encountered

| Error | Resolution |
|-------|------------|
| A push of the resume notes was refused by the session's permission check: the added lines described machine setup, in a public repo | Rewrote them without it, checked the commit's added lines, then pushed |
| A waiter returned at once, having measured nothing: the tool its liveness test called was not found, which the test read as the run having ended | Check that the tool resolves before the loop |
