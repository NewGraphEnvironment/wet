# Code-check round 5 (#40): validate/parity scripts, NaN guard, air split

Reviewer: subagent, 2026-10-07. Probes were run from the scratchpad against the cached
`data/temp_fill/*.rds` files. Nothing under the repo was written except this file.

## Findings

- **[bug] scripts/temp_fill_validate.R:103 — `gsdd_year()` does not use `wet_temp_gsdd()`'s rule, and that drops 45 % of the truth set.**
  `gsdd::gsdd()`, which `wet_temp_gsdd()` calls, passes `complete = TRUE` to `gsdd_vctr()` inside `.gss()`. `gsdd_year()` calls `gsdd_vctr(v, msgs = FALSE)`, whose default is `complete = FALSE`. With `complete = FALSE`, a season still above 4 °C on 30 Nov (or above 5 °C on 1 Mar) is NA. With `complete = TRUE` it is accepted.
  Measured on the cached water, over the 897 season-holdout truth station-years:
  - 403 truth GSDDs are NA under `complete = FALSE`, and 0 are NA under `complete = TRUE`.
  - Where both are defined, the two values are identical (max |diff| 0).
  So every GSDD number in `temp_fill_validate.txt` (gsdd_mae, gsdd_bias, gsdd_na of about 440, and criterion 3 of the pre-registered rule) comes from the roughly 55 % of station-years whose season ends inside the window. That subset leaves out the warm-autumn years, and it is not the statistic `wet_temp_gsdd()` produces.
  Fix: `gsdd_vctr(v, complete = TRUE, msgs = FALSE)` (`min_length` 274 already matches `gsdd()`'s own default for this window).

- **[bug] R/wet_temp_gsdd.R:16-21 (and man/wet_temp_gsdd.Rd) — the new paragraph is false.**
  It says that a season not ended by `end_date` gives NA, and it cites "403 of 897". Because `gsdd()` uses `complete = TRUE`, `wet_temp_gsdd()` returns a value there.
  Probe: a series at 6.5 °C over the last week of November gives `wet_temp_gsdd()` = 4029.44. `gsdd_vctr(complete = FALSE)` gives NA on the same series, and `gsdd_vctr(complete = TRUE)` gives 4029.44.
  The 403/897 figure is an artefact of the validate script's `gsdd_vctr()` default (finding above). The advice to pass `ignore_truncation = "end"` is also moot. Remove the paragraph, and keep the 403 number out of `research/station_temperature_fill.md`.

- **[bug] scripts/temp_fill_validate.R:201 (rule criterion 3, line 209) — the GSDD MAE in the paired table is not paired.**
  `gsdd_mae_full` and `gsdd_mae_open` each drop their own NAs, so they average different station-years. On the season holdout in the cached scores:
  - 23 station-years are NA for full only, and 30 for open only.
  - Unpaired: 115.39 vs 130.60. Paired on the common set: 114.17 vs 126.92.
  The verdict does not change, but the table is labelled "Paired … by station-year", and the rule's numbers are not computed on that pairing. Fix: restrict both means to `!is.na(f$gsdd_err) & !is.na(o$gsdd_err[k])`. After the `complete = TRUE` fix NAs become rare, but the pairing should still be enforced.

- **[bug] scripts/temp_fill_validate.R:215-217 — the "peer shares the sub-sub-drainage" split counts stations that are never peers.**
  `nb` counts every station in `water` with the same first 4 characters. It does not check whether that station is fitted (≥ 365 days, in `full_prep$fit_st`) or whether it has any observation in the held-out year. On the season holdout, 116 of the 796 station-years labelled `sub_sub_peer = TRUE` (15 %) have no fitted same-4-character station observed that year, so no such peer contributes to their fill. Of those 116, 11 have no fitted same-4-character station at all.
  The TRUE row therefore mixes in no-peer cases, which narrows the gap the table exists to show. Fix: test membership in `full_prep$fit_st`, minus the station itself, with an observation in that year.

- **[bug, small] scripts/temp_fill_validate.R:144 — the coverage is not of the interval `wet_temp_fill()` returns.**
  The script tests `|truth − pmax(est, 0)| <= 1.96·sd`. `wet_temp_fill()` returns `[pmax(est − half, 0), pmax(est + half, 0)]` with `est` unfloored. Two cases differ:
  - Where `est < 0`, the script's upper bound is `1.96·sd`, but the package's is `max(est + half, 0)`, which is lower.
  - Where `est − half < 0`, a truth in [−1, 0) is covered by the script and not by the package (`wet_temp_daily()` keeps readings down to −1 °C).
  So the reported coverage overstates the package interval's coverage on near-0 °C days (March, November). The size cannot be measured from the stored scores, which keep no per-day values. Fix: compute `lo`/`hi` exactly as `wet_temp_fill()` does, from the unfloored `full$s_open[k] + full$mean[k]`, with `qnorm(0.975)`.

- **[fragile] scripts/temp_fill_parity.R:75-76 — `n < 365` lets a leap year with one missing day through, and the day vanishes without trace.**
  B and C run on `d$t_mean_c`, the present rows only, so a missing day is dropped from the vector rather than passed as NA. A 2016, 2020 or 2024 station-year with 365 of 366 days passes the filter, and `gsdd_vctr()` then sees a sequence with the gap closed up.
  It has no effect on the current report: all 17 stations are fitted, so every calendar is complete, and every site shows 10 years. It would bite once a station is left unfilled.
  Fix: compare against the year's day count, `n < as.integer(as.Date(paste0(y, "-12-31")) - as.Date(paste0(y, "-01-01"))) + 1`, or build each year on a full calendar with NA.

- **[fragile] R/wet_temp_fill.R:403-404 with 275 and 304-306 — the guard caps the parameters used, not the parameters reported or reused.**
  For the stuck-sensor case, `attr(, "fit")` reports the optimiser's σ (≈ 1e-216) and ρ (possibly above 0.999). The smoother actually ran with σ = 0.01 and ρ = 0.999. The peer-error clip in `wet_fill_prepare()` likewise uses the uncapped σ: `lim = 4 * 1e-216`. It is harmless for a constant sensor, whose errors are about 0 anyway, but the fit table states parameters the fill did not use. Apply the same `min`/`max` in `par_of()`, or report the capped values.

## Checked and found correct

- Memo Tables 7 and 8: transcribed exactly. Checked against the live page fetched 2026-10-07 (all 68 and 40 numbers match).
- Parity step definitions match the header comment. A→B is the window (Mar–Nov vs calendar year), because both A and B run with `complete = TRUE`.
- Hidden-day construction, the swap (`wet_fill_swap` replaces exactly the held station's own entries), and the methods' days in GSDD. Days missing in the window are interpolated identically for truth and every method. The `linear` and `forward` constructions are correct.
- The air `split()` in `wet_fill_prepare()`: `[[` matches names exactly, empty levels give 0-row frames, and the duplicate check is per station. Equivalent to the old filter.
- The NaN guard: with q ≥ 1e-4, `pp[t+1] > 0`, so the gain is finite. The rewritten open-loop loop is equivalent to the old `max()` loop.
- PSOCK workers (no `mclapply`); exports cover every free variable `score_one` uses.
- The NaN in the committed `temp_fill_validate.txt` predates the guard; the file needs regenerating after the fixes above.
