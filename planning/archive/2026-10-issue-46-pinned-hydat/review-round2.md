# Code-check round 2 (#46)

## Clean

No issues found.

What was checked, against the diff b4c9da2...HEAD (b1d9058):

- `wet_hydat_check()`: the page-count fix (`as.numeric()` on each PRAGMA) is correct; run read-only on the real cache, `~/Library/Caches/org.R-project.R/R/wet/hydat/20260717/Hydat.sqlite3` (1,296,893,952 bytes) passes the size check and returns "20260717" in 0.14 s. The `on.exit()` inside the `tryCatch()` expression registers on `wet_hydat_check()`'s own frame, so the connection closes when the function returns, before `wet_hydat_fetch()` renames the partial.
- `wet_hydat()` guards: a non-character, length != 1, NA or non-YYYYMMDD `release` is refused; an NA, NULL or HTML answer from `hy_remote()` is refused unclassed (fails toward refusal, not skip).
- tidyhydat 1.0.1 source read: `hy_remote()` raises when offline (`tidyhydat_perform()` -> `req_perform()`), so an unreachable ECCC becomes the classed `wet_hydat_unavailable` and a live test skips rather than fails. `download_hydat(dl_hydat_here = dir, ask = FALSE)` writes only into `dir` (zip and extraction in the session tempdir), never into `hy_dir()`, and creates `dir` without parents, which wet pre-creates.
- `wet_hydat_fetch()`: `file.rename()` (not `fs::file_move()`), so a target another run has filled makes the rename fail and that copy is used; a raced `file.mtime()` NA in the stale sweep only gives `unlink(NA)`, which returns 1 and deletes nothing.
- Scripts and data scripts: every HYDAT read in `scripts/` and `data-raw/` goes through `wb_hydat()`; `source("scripts/wb_fit_lib.R")` inside mad_basin.R's `tryCatch()` sources into the global env and defines only `wb_*` names, none of which collide with mad_basin.R's. `as.Date(<YYYYMMDD>, "%Y%m%d")` in the station scripts is right.
- Tests: `test-wet_hydat.R` run from a `git archive` copy with `NOT_CRAN=true`: 12 tests, 0 failed, 0 errors, 0 skipped. The Buck Creek live test keeps `skip_on_ci()` and the snap test skips on `local_fwapg()` first, so neither downloads HYDAT on CI. testthat (>= 3.2.0), withr, RSQLite and tidyhydat are declared.
