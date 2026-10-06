# Code-check round 2: wet_temp_daily() (#36)

Reviewer: subagent, 2026-10-06. Diff: diff2.patch (NAMESPACE, R/wet_station_daily.R,
R/wet_temp_daily.R, man/wet_temp_daily.Rd, tests/testthat/test-wet_temp_daily.R). Consumer read:
R/wet_window_stats.R. Checklist sections on SQL interpolation, numeric grammar, DBI types,
match/NA, zero-length and testthat conditions checked against the diff.

## Clean

No issues found.

## Checked and found sound (no finding)

The round-1 fix (`valid` guard plus `sprintf("%.15g")`):
- Guard order is safe: `||` short-circuits, so `valid[1] >= valid[2]` runs only after
  `all(is.finite(valid))`. NA, NaN, +/-Inf, length != 2, non-numeric (character, logical, Date,
  and a yaml-style `list(-1, 35)`) are all refused before any SQL is built.
- Integer `valid` (`c(-1L, 35L)`) passes the guard, and `sprintf("%.15g", -1L)` gives `"-1"`
  (probed), so it does not error.
- Every string `%.15g` can produce for a finite double parses in duckdb 1.5.2 (probed):
  `1e+15` and `1e-10` are DOUBLE, `-0` INTEGER, `123456789012346` BIGINT,
  `0.333333333333333` DECIMAL(16,15), `35.0000000000000` DECIMAL(15,13). DOUBLE BETWEEN these
  binds and compares correctly. `.Machine$double.xmax` rounds up to `1.79769313486232e+308`,
  which duckdb reads as `Inf`, so `c(-1, .Machine$double.xmax)` still behaves as "no upper bound".
- `sprintf()` ignores `options(OutDec = ",")` (probed `"35.5"`). The OutDec test runs the real
  SQL path (archive present in that test), so it discriminates, as round 1 showed.
- The 15-significant-digit rounding can move a bound only in the 16th digit. That matters only for
  absurd inputs such as `c(35, 35 + 1e-14)`, so it is not a finding.

The same mechanism elsewhere in the SQL:
- `bound`: `%d` of `as.integer(<Date>)` takes no locale and no `scipen`. `-Inf`/`Inf` Dates
  (the NULL defaults) are left out by `is.finite()`, which works on Date (probed). A fractional
  Date truncates to the day R prints. Only a Date past year ~5.8 million would give `NA` and then
  `dd >= NA`; no real input does that.
- `min_hours`: whole number 1..24, then `%d` of `as.integer()`; `Inf`, `NA`, 20.5 and logicals are
  refused.
- Offsets are not interpolated: they go through `duckdb_register` as an integer column, and a
  half-hour offset (-3.5 h) is exact in seconds.
- Stations, root glob and the approval regex go through `dbQuoteString`.
- Precedence: `epoch_ms(p.Date) // 1000 + o.offset_s` parses as `(.. // 1000) + offset`; the
  local-day tests would fail if it did not.

Other:
- DBI types: `dd` and `n_hours` are CAST to INTEGER, so no integer64 reaches R; `final` is
  logical, never NA; zero rows index to `character(0)`.
- `wet_approval_final` moved to a plain constant with a `#` comment after a function, so no
  roxygen block is rebound; `grepl()` on NA approval is FALSE, the same as before.
- Tests: the `expect_warning(e <- ...)` assignments are inside the call; each warning test emits
  only the warning it matches; the mock returns NA for unlisted stations by single-bracket
  indexing, not `[[`.
