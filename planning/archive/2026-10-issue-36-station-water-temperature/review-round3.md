# /code-check round 3 — #36 (wet_temp_daily, temp_coverage, docs)

## Findings

- **[severity: fragile]** scripts/temp_coverage.R:34-36, 40-41: this is round 1's mechanism coming back in the second caller. `valid[1]`/`valid[2]` go into the SQL through `sprintf("%1$s")`/`"%s"`, which converts a double with `as.character()`. **`as.character()` follows `options(OutDec)`**, measured here (R in this repo): with `OutDec = ","`, `as.character(-0.5)`, `sprintf("%s", -0.5)` and `sprintf("%1$s", 35.5)` give `-0,5`, `-0,5` and `35,5`. The fix landed in `R/wet_temp_daily.R:145` (`sprintf("%.15g")`, whose numeric conversions ignore OutDec, as test-wet_temp_daily.R:101-102 shows) and not in the script. **It cannot fire at today's defaults**: `-1` and `35` are whole numbers, so they print the same under either mark, and the report at `data/checks/temp_coverage_report.txt` is correct. It fires once the default `valid` becomes fractional (e.g. `c(-0.5, 35)`) in a session that sets OutDec. `WHERE Value < -0,5 OR ...` is then a parse error, so it fails loudly, not silently. There is also a second, quieter drift: the script's "dropped" counts and the function's filter render the same value with two different formatters, and nothing ties them together. Remedy: use the same `sprintf("%.15g", ...)` in the script, or better, one internal helper that renders a finite number as a SQL literal, called from both. Two callers each picking their own formatter is what let the fix land in only one of them.

## The mechanism, and every place it reaches

**Mechanism.** An R value is turned into SQL **text** by a formatter that was chosen at each call site, not by the driver. A formatter can be wrong in two ways. It may have no SQL form for a value (Inf, NA or NaN come out as bare words). Or its output may depend on session state (`OutDec` for `format()`/`as.character()`/`%s`). Nothing is shared between the sites, so a fix at one site does not reach the others. Round 1 was the first kind (`Inf`) and the second kind (`format()`) at one site. This round is the second kind at the sibling site.

Every place in these changes where an R value becomes SQL text:

| file:line | value | rendering | status |
|---|---|---|---|
| R/wet_temp_daily.R:113 | secret | literal, no R value | safe |
| R/wet_temp_daily.R:116 | station offsets | `duckdb_register()` table, not text | safe |
| R/wet_temp_daily.R:123-124 | `from`, `to` | `sprintf("%d", as.integer(Date))` under `is.finite()` | safe (integers do not use OutDec; ±Inf excluded) |
| R/wet_temp_daily.R:141 | `wet_approval_final` regex | `dbQuoteString` | safe (`^(Final|Approved)` means the same in RE2 and in R) |
| R/wet_temp_daily.R:142 | parquet glob | `dbQuoteString` | safe |
| R/wet_temp_daily.R:143 | stations | `dbQuoteString` each | safe |
| R/wet_temp_daily.R:145 | `valid` | `sprintf("%.15g")` under `is.finite()` guard | safe (round 1 fix) |
| R/wet_temp_daily.R:147 | `min_hours` | `%d` of `as.integer()`, validated 1-24 whole | safe |
| scripts/temp_coverage.R:30 (used at 38, 40, 45, 46) | parquet glob | `dbQuoteString` | safe |
| scripts/temp_coverage.R:34-36, 40-41 | `valid` | `%s` = `as.character()` | **OutDec-dependent: finding above** |
| scripts/temp_coverage.R:37 | sentinels | literal `IN (99999, -99999, 999, 99.9)` | safe: `Value` is DOUBLE (probed), and `= 99.9` matches 5,148 rows, the same as the report |
| tests/testthat/test-wet_temp_daily.R:12-14 | output path | `dbQuoteString` | safe |

## Checked and clean

- **Report against the research file, NEWS and CLAUDE.md.** Every number in `research/station_water_temperature.md` matches `data/checks/temp_coverage_report.txt`:
  - 17,428,356 readings, 306 stations, 2002-04-30 to 2026-10-01.
  - 120,500 below and 216,872 above, 1.93 % of 17,422,356 valued readings, which the file gives as "about 1.9 %".
  - Sentinels: 99999 is 184,177, and the four together are 193,092 (= 184,177 + 5,148 + 2,928 + 839).
  - 12,662 kept between −1 and −0.5.
  - Approval spans and the 50,890 empty rows.
  - 276/27/3 offsets.
  - 630,001 and 615,802 (97.75 %) station-days.
  - The decade table (0/0/0/0, 26/34/35/35, 53/58/67/63, 69/81/86/86).
  - "6 to 11 higher" against the issue's 32/64/79 (+6, +11, +10).
  - The issue's 643,440 and 98 % match the #36 body.
- **Probed against the live archive:**
  - Readings before 2011: one station a year in 2002-2007, none in 2008, 788 readings in 2009 (2 stations), 87 in 2010. So "fewer than 900" (875) holds.
  - `Symbol` is null on all 17,428,356 rows.
  - There are 0 duplicate (station, Date) keys.
  - 46,331 readings fall in [−5, −1), so the band is real.
  - `stations_realtime.parquet` gives 291 stations in common with the archive. Its zone names agree with `standard_offset` on every one (Vancouver = −8; Dawson Creek, Edmonton and Fort Nelson = −7). The three listed in neither table are 08DA013, 08DB015 and 08NHX18, as stated.
- **The script's window bar matches the function.** `wet_window_stats()` drops a window-year below `min_frac = 0.8` (wet_window_stats.R:183) and outside the series span, so counting rows per station is counting window-years that pass. The script's window dates match `vignettes/station-flow.Rmd:80-81,319`. The `win` matrix is decades × windows and is printed by row.
- **The docs are current.** `man/` and `NAMESPACE` regenerated in a copy match the staged ones byte for byte. The CLAUDE.md line sits in the project section, above the conventions.
- **Dependencies are declared.** `withr`, `duckdb` and `tidyhydat` are in Suggests and `curl` is in Imports, so the test-time `::` calls and `skip_if_offline()` are covered.
