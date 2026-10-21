# Code-check round 1: #99 segment_daily (diff 40560dc...HEAD)

## Checklist read

- code-check.md: the prose of all 14 H3s under `## Mechanisms`, in full (table rows and evidence blocks skipped). Rules that stand alone: index only.
- code-check-r.md: 11 of 112 sections in full: "A database driver's value is not a base R type", "`identical(-0, 0)`", "`stats::aggregate()` has three separate silent behaviours", "`match()` treats NA", "`tolerance` in testthat is RELATIVE", "Postgres row order is never fixed", "`sprintf(\"%g\", x)`", "Rscript reads a script as it runs", "A range total taken as the difference", "`system2(stdout = TRUE)`", "`ifelse()` with an all-NA test". The other 101: index only.
- code-check-shell.md: index only (the diff has no shell code; git runs through `system2()` with `shQuote()`).
- code-check-spatial.md: index only (no spatial operations in the diff).

## Findings

- **[severity: fragile]** scripts/segment_daily_output.R:225-226 and 256-258. The guard that holds the routed months rebuilt from the days to fwapg's months accepts any difference of one 1e-5 step (`d > 0 & d <= 1.000001e-5`). It never checks that the raw value sits on a rounding tie. The report then labels every such row "by one step at a rounding tie" (line 312), and CLAUDE.md says the script refuses unless the months are fwapg's "(a rounding tie aside)". The publish check (discharge_publish.R, `tie <- ... abs(f - floor(f) - 0.5) < 1e-6`) does test the tie, so the two sides of one stated rule differ. This build check is the only comparison of routed days against fwapg itself, since publish only routes the same inputs again. So a real defect of one step, not at a tie, would pass and be reported as a tie. For example, a slightly wrong `n_days` weight on a low-flow segment, where any relative error under about 1e-5/q shows as at most one step. Fix: compute `f <- abs(wm) * 1e5`, count as tolerated only the one-step rows with `abs(f - floor(f) - 0.5) < 1e-6`, and count every other non-zero `d` as differing.

- **[severity: fragile]** R/wet_routed_days.R:263 (`wet_routed_round()`). The near-tie window `1e-6 + 8 * eps * f` is narrower than Postgres's 15-significant-digit tie interval for flows from 10,000 to about 22,500 m3/s. In that range a double whose `%.15g` form is an exact tie (e.g. `12213.315444999958` -> `"12213.315445"`) is up to 5e-6 (in 1e-5 units) from the half point, outside the window. So R's `round()` takes it down, while fwapg's `round(q::numeric, 5)` takes it up. Probe, in a copy, against an emulation of the cast plus half-away rounding: 0 mismatches in 500,000 values below 10,000, and on values built inside the tie interval 8,542/50,000 at 10,000-15,000, 2,935/50,000 at 15,000-20,000, 162/50,000 at 20,000-30,000 and 0 at 30,000 and up. Below 10,000, which the published Fraser part's routed monthly maximum (8,517.5 m3/s) sits in, it is exact. Whether it bites depends on whether any daily or monthly routed value reaches 10,000 m3/s (lower-Fraser freshet days may). The effects: such a day is published one step away from fwapg's convention. And because the window's edge is a second rounding boundary, two summation orders that straddle it round apart without falling inside the publish tie test's `< 1e-6`, so "daily routed = routed again" would FAIL on a correct build. Fix: size the window from the 15th significant digit, e.g. `half <- 0.5 * 10^(floor(log10(abs(x))) - 14) * 1e5; near <- abs(f - floor(f) - 0.5) <= half + 8 * eps * f`.

- **[severity: fragile]** R/wet_segment_monthly.R:230-ish (`wet_segment_pg()` via `wet_segment_daily(conn, ...)`) together with R/wet_db_load.R `groups`. `wet_db_load(groups =)` keeps only the named groups' daily parts. For groups with no routed part (Liard, Yukon and Alsek headwaters, Hay), the loaded table then holds no `pcic_routed` rows for the scenario. A default `wet_segment_daily(conn, ids, groups = <those>)` then stops with "has no rows for scenario historical, source pcic_routed: load it with wet_db_load(...)". The parts reader returns NA rows in the same case ("a source whose groups hold no part has no rows there"). So the same call fails on one store and succeeds on the other, and the remedy in the error does not help unless the user reloads groups that do have routed parts. This is a failure of the default call, not a wrong value.

No other real issues found. Checked and clean:
- Fold, raw routing and rounding: column-major `rep(n366[1, ], each = n)`, `rowsum(reorder = FALSE)` row order, recycling of `share`, `area_mm` and `to_mm` against matrix rows, and the 29 February fold commuting with the month weights.
- `vs_month` accumulation and its per-code stop.
- Pieces assembly, and that a refused run leaves no top-level parquet (publish refuses on mtime).
- `publish_part_write(rows_per_group =)` boundaries (multiples of 365 on a segment-then-doy sort).
- `wet_values_compare(time = "doy")` keys: `id * 512 + doy` is below 2^40.
- Every `n_vc()` and `vapply` over a missing check errors rather than passing.
- The daily row, pick and segment counts against the monthly report.
- PUBLISH skip-by-ETag (a 403 or 404 reads as not ok, so the part is uploaded).
- The vignette report parsers (`re_seen` is anchored at `^historical`, so the new `segment_daily ...` lines do not match it; every data-raw read filters to `segment_monthly`).
- `routed_daily_inputs()`: `strsplit("")` gives `character(0)`, and a NULL array stops.
- New tests, run in a copy (`NOT_CRAN=true`, `testthat::test_file`): routed_days 35 pass, segment_daily 25, values_compare 24, catalog 37, with 0 failures and 0 errors. test-wet_segment_daily.R creates and drops its own `wet_test_*` schema in the local fwapg. That is the test's own fixture, and nothing else was written.
