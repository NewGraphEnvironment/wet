# Code-check round 2 (#25)

Scope: whole branch diff vs main, with the round-1 fixes read most closely.

## Round-1 fixes: verified

- **Cutoffs from each source's true last day.** `wet_hydat_last()` finds the last month with any non-NULL FLOW per station and unpivots it. `wet_eccc_daily()` sets `attr(, "last")` from every row read before the from/to trim. The provisional query has no date filter, so that value is the archive's real last day. `wet_daily_after()` and `wet_last_max()` combine them correctly: I probed `wet_last_max(c(A=1,B=5), c(B=3,C=9))` and got `A=1 B=5 C=9`. Both new tests fail against the old logic, because the old in-window `have` would have let 1984-07-25 through and started real-time on the day 19 days back. Both pass now.
- **Live test.** It now skips cleanly when there is no `data/hydat/20260717`.
- **Script guards.** The `aggregate()` call on zero rows is guarded (and `year`, `variable` and `period` are never NA, so na.omit cannot bite). The `!nrow(s)` case now exits before any cd call. The `no_mad` branch leaves out `frac_below`, so it needs no threshold. `rbind(NULL, df)` is safe.
- In a copy: `NOT_CRAN=true devtools::test(filter = "station_daily|window_stats")` gave `[ FAIL 0 | WARN 0 | SKIP 2 | PASS 98 ]`.

## Findings

- **[fragile]** R/wet_station_daily.R:52-53, 77, 170: `as.Date()` is called on a numeric without `origin`, in `as.Date(-Inf)`, `as.Date(Inf)` and `as.Date(last[[st]])`. R only defaults `origin` to 1970-01-01 from 4.3.0. On R 4.1 and 4.2 each call errors with "'origin' must be supplied". `DESCRIPTION` declares `Depends: R (>= 4.1)`, so every call to `wet_station_daily()` would fail on an R version the package says it supports. Line 77 sits outside `wet_daily_try()`, so the error is not caught as a skipped source. There is no R-CMD-check workflow, so CI will not catch it. Fix: either `as.Date(x, origin = "1970-01-01")` / `structure(x, class = "Date")`, or raise the Depends floor to R (>= 4.3).

- **[fragile, low]** R/wet_station_daily.R:85 with 237: the internal `"last"` attribute can leak onto the exported return value. `rbind.data.frame` takes its attributes from the first data frame that has rows. So when `hy` is empty (sources without `"hydat"`, or no HYDAT rows in the window), `out` carries `attr(out, "last")`. That value is provisional's (or real-time's) own last day, not the combined cutoff. When HYDAT has rows, the attribute is absent. The attribute is undocumented, and whether it appears depends on the sources. Nothing reads it downstream today, but `identical()` or `expect_equal()` comparisons of two results will disagree for no visible reason. I confirmed it with `rbind(wet_daily_empty(), <eccc frame>)`: the attributes include `last`, and it survives `out[order(...), ]`. Fix: `attr(out, "last") <- NULL` before returning.

- **[fragile, low]** scripts/station_departure.R:1017-1018 and 1075: `no_mad` catches every station missing from `wet_station_select()`, and that function also drops regulated stations, stations with no STN_REGULATION row, and non-BC stations (`prov = "BC"`). The report still prints "MAD: none (fewer than 5 complete years in the record)" for all of them. For a regulated or out-of-province station passed on the command line, that line is false. The run itself completes correctly. The message should say "no MAD (fewer than 5 complete natural-flow BC years)", or give the actual reason.

No other issues found. I checked all of these and found nothing:
- the duplicate "hydat skipped" warning when the file is missing (cosmetic);
- NA dates in the ECCC feeds (duckdb and tidyhydat return non-NULL timestamps);
- the `q_mean`-absent case in the recent-departures table (`min7` and `frac_below` counts never exceed `mean`'s, so `q_mean` is always present when the others are);
- `wet_window_stats()` ordering with `by = character()`.
