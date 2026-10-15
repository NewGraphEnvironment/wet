# Code-check round 1: #46 (pinned HYDAT releases), branch diff b4c9da2...HEAD

Reviewer: blind subagent, 2026-10-15. Read the whole bundle (checklist, diff, changed files).

## Findings

- **[severity: fragile, latent]** R/wet_hydat.R:47 (`wet_hydat_check()`):
  `PRAGMA page_count` and `PRAGMA page_size` both come back from RSQLite as **integer**
  (measured on the cached 20260717 file: `class()` is `"integer"` for both), so their product
  is integer arithmetic and overflows to `NA` (with a warning) once a file passes
  2,147,483,647 bytes. `isTRUE(NA == file.size(f))` is then FALSE, so every call to
  `wet_hydat()` on that release stops with "is not a whole HYDAT (its pages make NA bytes ...);
  copy it again". The cache would refuse a correct file, and copying it again changes nothing.
  It fails toward refusal, which is the loud direction. It is also far off: 20260717 is
  1,296,893,952 bytes (60 % of the limit), and the two backed-up releases grew 22.8 MB in 9
  months (1,274,108,928 to 1,296,893,952), so at that rate the limit is decades away. The fix is
  one coercion: `as.numeric(...) * as.numeric(...)`. Reproduced: `2200000L * 1024L` gives `NA`
  with "NAs produced by integer overflow".

## Checked and clean (no finding)

- `tests/testthat/test-wet_hydat.R`: all 12 blocks pass (0 failed, 0 error, 0 skipped), run
  with `testthat::test_file()` and `NOT_CRAN=true` from a scratch copy of the tree.
- The tidyhydat 1.0.1 bodies the code depends on: `hy_remote()` lets a transport failure raise
  after `req_retry`, which `wet_hydat()` turns into `wet_hydat_unavailable`, so an offline live
  test skips. `download_hydat(dl_hydat_here = <existing dir>, ask = FALSE)` does not recreate
  the directory and writes `Hydat.sqlite3` into it. Neither path is read from tidyhydat's own
  directory.
- `wet_hydat_check()`: `on.exit()` inside the `tryCatch` expression registers on
  `wet_hydat_check`'s own frame, so the connection closes before `wet_hydat_fetch()` renames
  the partial directory. The real HYDAT header has a valid in-header size (change counter at
  offset 24 equals version-valid-for at 92, both 2), so SQLite itself refuses a truncated
  copy, and the size check covers the rest.
- `wet_hydat_fetch()`: `file.rename()`'s FALSE return is checked. A failed rename onto a
  non-empty target falls back to the other run's copy, which `wet_hydat()` then checks again.
  The partial directory is removed on every exit path, and the stale sweep is scoped to this
  release's `.partial-` prefix.
- No leftover `WET_HYDAT=` run line or `data/hydat/` path in `R/`, `scripts/`, `data-raw/`,
  `tests/`, `vignettes/` or `research/`. The only mentions are in `planning/archive/` and
  `planning/active/`. `local_hydat_real()` has no remaining caller.
- The one binary in the diff, `inst/vignette-data/station_map.rds`, differs from the base only
  in the new `provenance` attribute and the row order of `lakes`. Sorted by area and name, the
  lakes are `all.equal` to the old layer: the lakes query has no `ORDER BY`. The vignettes and
  `test-vignette_data.R` read the layers by name, so neither the attribute nor the order
  matters to them.
- `tools::R_user_dir()` is not redirected by R 4.5.2's `R CMD check`, so the live tests see
  the same cache under check as under `devtools::test()`.

/Users/airvine/Projects/repo/wet/planning/active/review-round1.md
