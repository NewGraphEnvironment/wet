# Code-check round 5 (#235)

## Checklist read

- code-check.md: the prose of all 14 H3s under `## Mechanisms` (table rows skipped). The 24 H3s under "Rules that stand alone", "Security" and "Spreadsheets and PDFs" were not read.
- code-check-r.md, read in full (4): "Under `R CMD check`, tests run from a temp dir against the INSTALLED package"; "A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check` if `pkg` is undeclared"; "A fetcher's test helper must make the network fail, not just mock the reader"; "Tests that silently do not run". Read by index line only, to match the diff's calls (as.Date/as.POSIXct, `order(method = "radix")`, `read.delim`, `system2`, `tempfile`, `on.exit`, `data-raw/` load): rounds 1-4 read those in full. 128 not read in full.
- code-check-shell.md: none read in full (only `aws s3api put-object` single-PUT ETag, settled in round 4). 75 not read.
- code-check-spatial.md: none read in full (FWA placement rules read in round 4). 98 not read.

Index, diff and changed files read from file.

## Round-4 fixes checked

- `R/wet_logger_daily.R:287-288`: both defaults now `as.Date(±Inf, origin = "1970-01-01")`. Every other numeric `as.Date()` in `R/` and `tests/` carries an origin (`R/wet_logger_daily.R:230, 243, 265, 272`; tests pass character dates only). Holds.
- `research/station_water_temperature.md` "How the thresholds were measured": now says the air thresholds "may sit below what a small-stream reference would give, and drop some of a small stream's real wide-range days; the direction was not measured". The stated direction is the correct one for the air rule, hedged, and says nothing about the stuck threshold. Holds.
- `planning/active/task_plan.md`: `utc_offset`/`dst`/`tz` now recorded as not built (59-60), "else from the earlier" carries the as-built note (40-42), the logger-only scope is restricted to stuck, deployment and air (62). Holds.

## Enumeration

| item | artifact checked | verdict |
|---|---|---|
| (a) `as.Date(numeric)` without origin, R < 4.3 | every call in `R/`, `tests/` | none left |
| (a) `tools::R_user_dir()` | needs R >= 4.0; DESCRIPTION R >= 4.1 | ok |
| (a) `order(..., method = "radix")`, multiple keys | R >= 3.3 | ok |
| (a) named `colClasses` incl. `"Date"`, `"logical"` in `read.csv` | base read.table, all supported R | ok |
| (a) `rowsum(reorder = FALSE)`, `tabulate`, `startsWith`, `°` escape | base, R >= 4.1 | ok |
| (a) `read.csv(encoding = "UTF-8")` header with degree sign vs `"°"` | marks the header UTF-8; `identical()` compares translated strings; CI is one ubuntu runner (flows `r-cmd-check.yaml`) | ok |
| (a) `curl::curl_download(handle =)`, `curl::new_handle(useragent =)` | curl in Imports, no floor; both long-standing | ok |
| (a) `local_mocked_bindings()`, incl. `.package = "curl"` and a non-function value (`wet_logger_versions`) | DESCRIPTION `testthat (>= 3.2.0)`; `check_bindings()` only requires names | ok |
| (a) `withr::local_tempdir(.local_envir =)`, `withr::with_dir`, `withr::local_tempfile` | `local_tempdir` from withr 2.3.0; testthat >= 3.2.0 pulls a later withr | ok |
| (a) `utils::zip()` in `helper-temp-loggers.R` | needs a `zip` binary (`R_ZIPCMD`); flows R-CMD-check runs one ubuntu runner, which has zip; a missing binary would fail loudly at `file.size`/`md5sum`, not pass | ok |
| (a) `cbind(series = k, <data.frame>)` in `wet_logger_registry()` | stringsAsFactors FALSE from R 4.0 | ok |
| (a) Suggests packages reached by the new tests | `wet_temp_gsdd()` stops without gsdd; gsdd is Suggests, Remotes-only | **unguarded at test-wet_logger_daily.R:347** (finding 1) |
| (b) threshold-report test (`test_path("..","..","data","checks",...)`) | `skip_if_not(file.exists(report))`; under R CMD check `pkg.Rcheck/data` does not exist | skips |
| (b) shipped manifests/registry test | `system.file()` via `wet_logger_path()`; `inst/extdata/temp_loggers/` not in `.Rbuildignore` | installed copy, ok |
| (b) all fixture tests | `withr::local_tempdir`, cache mocked, curl mocked to fail | ok |
| (c) `data-raw/temp_loggers_nhg.R` | run from package root (relative `source()`s, `inst/` out_dir); cache `tools::R_user_dir()` = `wet_logger_cache()`; HYDAT through `wb_hydat("20260717")`; `WET_BACKUP=1` + `aws`; S3 archive read anonymously | ok |
| (c) `scripts/temp_logger_thresholds.R` | `WET_DATA_ROOT` (default `data`) for the hours cache; report always `data/checks/` in the checkout; `WET_HYDAT_RELEASE` via `wb_shipped_release` | ok |
| (c) `scripts/temp_loggers.R` | `WET_PG*` with the same defaults as `scripts/station_regulation.R`, `connect_timeout = 10`; refuses without the tree table; report reads the tracked placement file and the cache only | ok |
| claims: CLAUDE.md, NEWS, roxygen, research numbers | rounds 3-4 tables; thresholds report (all months "under 1,000 km2", 135 days, 6 station-years, 154 h); registry (29 x 08J, 3 x 08K) | hold |
| issue numbers the branch adds | `gh issue view` 215, 224, 235, 236, 251, 252, 253, 192, 187, 19 | each exists and is about the work cited |

## Findings

- **[severity: fragile]** `tests/testthat/test-wet_logger_daily.R:330-349` — "a logger series pools with its sub-drainage's stations in the fill and gives GSDD" calls `wet_temp_gsdd()` (line 347) with no `skip_if_not_installed("gsdd")`. `wet_temp_gsdd()` stops ("install gsdd ...") when gsdd is absent (`R/wet_temp_gsdd.R:56`), and gsdd is a Suggests package available only through `Remotes:` (poissonconsulting/gsdd), so any check or `devtools::test()` without it errors here. Every other test that reaches `wet_temp_gsdd()` guards it (`test-wet_temp_gsdd.R:9, 31`). CI installs Suggests, so it is green there; the failure is on a machine or check without the GitHub remote. Fix: add `skip_if_not_installed("gsdd")` at the top of the block (the fill half needs nothing from Suggests, so alternatively split the GSDD assertions into their own guarded block).
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

## Closing enumeration (the parent session, after fixing the finding)

The set round 5's mechanism reaches in the tests: every dependency outside Imports (curl, DBI, jsonlite, terra) that the new test files reach, 5 in all, each checked in DESCRIPTION and the test code:
- withr (`local_tempdir`, `with_dir`, `local_tempfile`): imported by testthat, so present wherever the tests run.
- gsdd (`wet_temp_gsdd()` in the pooling test): now behind `skip_if_not_installed("gsdd")`, after the fill assertions.
- duckdb and tidyhydat (`wet_temp_eccc()`, `wet_temp_offsets()`): never reached; every routing test mocks `wet_temp_eccc()`.
- testthat's `local_mocked_bindings()`, including a non-function binding and `.package = "curl"`: needs testthat >= 3.2.0, which DESCRIPTION declares.
- the zip program `utils::zip()` runs in `logger_fixture()`: now a `skip_if()` when neither `R_ZIPCMD` nor `zip` is found.
Nothing in the set is left above its guard.
