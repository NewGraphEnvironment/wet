# Code-check round 1 — wet_temp_daily() (#36)

Reviewer: subagent, 2026-10-06. Diff: NAMESPACE, R/wet_station_daily.R, R/wet_temp_daily.R,
man/wet_temp_daily.Rd, tests/testthat/test-wet_temp_daily.R. Consumer read: R/wet_window_stats.R.

## Findings

- **[severity: fragile]** R/wet_temp_daily.R:144 (`format(valid[1], digits = 15), format(valid[2], digits = 15)`)
  — the `valid` check accepts any two increasing non-NA numbers, so `valid = c(-Inf, Inf)` (the
  natural way to switch the range filter off) or `c(-Inf, 35)` passes validation and is written into
  the SQL as `p.Value BETWEEN -Inf AND Inf`. duckdb reads `Inf` as a column name and fails with
  `Binder Error: Referenced column "Inf" was not found` (probed, duckdb 1.5.2). Same mechanism as the
  checklist's "`sprintf("%g", x)` writes `Inf` and `NA` into SQL as bare words". Second path through
  the same line: `format()` honours `options(OutDec = ",")` (probed: `format(-0.5, digits = 15)` gives
  `"-0,5"`), so a session with a comma decimal mark writes `BETWEEN -0,5 AND 35` for a non-integer
  bound. Both fail loudly rather than silently, hence fragile, not bug. Fix: refuse non-finite `valid`
  in the guard (`all(is.finite(valid))`), or drop a non-finite end from the `WHERE`; and format with
  `sprintf("%.15g", valid)`, which ignores `OutDec`.

## Checked and found sound (no finding)

- `epoch_ms(TIMESTAMPTZ)` is independent of the session zone: identical result with ICU unloaded,
  ICU loaded + `TimeZone = 'America/Vancouver'`, and `Asia/Tokyo` (probed). Offset sign is right
  (local = UTC + offset_s, offset -8 h).
- Real archive (probed on S3): 12 flat `part-N.parquet` files, so the non-recursive `*.parquet` glob
  sees everything; schema identical across files (`Date` TIMESTAMPTZ, `Value` DOUBLE, `Approval`
  VARCHAR, so `regexp_matches` binds); 17,428,356 rows and as many distinct (station, Date) keys, so
  no duplicate readings; earliest 2002-04-30, so `//` never sees a negative. 9 readings have
  sub-second stamps; `// 1000` truncates them into the right second, harmless. The hive `Parameter`
  column auto-detected from the path is unused and harmless.
- Each hour bucket maps to exactly one day bucket (both derive from the same `sec`), so `n_hours`
  is at most 24 and `HAVING count(*) >= min_hours` counts hours.
- SQL injection: stations, root and the regex go through `dbQuoteString`; `from`/`to` through
  `as.integer`; `min_hours` validated whole and cast.
- Zero rows: `d$final + 1` on `logical(0)` indexes to `character(0)`; `source` is pre-built with
  `rep()`; the shape test covers it. `bool_and` over `coalesce(..., false)` cannot be NA.
- `wet_approval_final` is a plain `#` comment plus constant after a function, so no roxygen block is
  rebound; R's TRE and duckdb's RE2 agree on `^(Final|Approved)`.
- Dependencies: DBI in Imports; duckdb and tidyhydat in Suggests behind `requireNamespace`; withr in
  Suggests; testthat pinned >= 3.2.0 for `local_mocked_bindings`; `skip_if_offline()`'s curl is in
  Imports. `pkgdown::check_pkgdown()` reports no problems (no reference index).
- Tests reach their failure modes: ignoring the offset (UTC days) splits the -8 test day into 16 + 8
  hours, so the local-time test would go red; per-station offsets, local-day `from`/`to`,
  hour-weighted mean and per-reading approval each have a case that discriminates.
- Consumer: `wet_window_stats()` gets one row per station-day (no duplicate-date stop), a Date
  `date`, numeric value columns, `status` read as provisional, and no `symbol` so `frac_ice` is NA,
  as documented.

## Verdict

One fragile finding (non-finite or comma-decimal `valid` breaks the SQL with a cryptic error). No bugs
or security issues.
