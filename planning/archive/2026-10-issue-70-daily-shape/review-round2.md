# Code-check round 2 — branch 70-sub-monthly-flow-per-segment-a-daily-cli

Reviewed against merge-base 80ab129 (commits 18c94a6..a2a6c7b). Scope: `R/wet_doy_month.R`,
`R/wet_shape_within.R`, `R/wet_shape_fit.R`, `R/wet_shape_predict.R`, `R/wet_station_doy.R`,
`scripts/wb_shape_daily.R`, the two test files, `data/checks/wb_shape_daily_20260717.txt`,
the research and CLAUDE.md edits. Probes were run on copies under the scratchpad; nothing in
the repo was touched except this file.

## Verdict

No bug, security issue or data-loss path found. Three low-severity notes below, two of them
on prose and one on a report literal. None changes a number or the shipped decision.

## What was checked and cleared

**Registered rule vs body.** `git show 44ce054:scripts/wb_shape_daily.R` differs from HEAD's
header only by the removed placeholder `stop()` (112 identical lines). The body follows it:
observed months (`obs_sh / wet_month_days()`), `wet_nse(obs, mod)` called in that order with
each series scaled by its own mean, `cal$obs >= 10`, median over gauges every candidate
scores (`all_scored`), `which.max` over the four shippable names (tie -> flat first),
`gain >= 0.01 - 1e-9`. The spline header says "rescaled month by month until each month's
mean is preserved to 1e-9 (at most 100 passes)"; the body does one exact per-month
normalisation (`wet_shape_within()`), which satisfies that clause on pass 1, and
`shape_nse()` asserts the means are kept to 1e-12. Same candidate, no drift.

**Held-out construction.** Donor SDs (`fit$sd`), PCA centre and basis, the donor pool and the
free curve's `scale()` are all computed on the fold's training rows. `cal$fold` is the same
`wet_cv_folds()` assignment `predict_cv(cal, cal$fold, ...)` used in `wb_validate.R`, so the
`cv_share` fed to `basis` at a held-out gauge was itself held out in the same fold. The leak
sensitivity removes `related[i, ]` (symmetric, so direction of `wet_fwa_upstream()` is moot).
`obs_sh` at training / `cv_share` at test is declared in the header.

**Basis aliasing.** With 12 shares plus an intercept, `lm.fit` aliases exactly one share
column (probe: 1 of 16 rows zeroed, `which = 16`). Prediction then depends on the new
shares summing to 1; `wet_share_predict()` renormalises to 1 (`R/wet_share_predict.R:20`),
so `cv_share` and published shares satisfy it. Harmless; basis did not ship.

**Chinook table.** `from_months` and `shape_a` spread the same `om` (observed months pooled
over the window's years), so the shape's effect is isolated. `daily_record` is a mean of
per-year window means with `min_frac = 0.8`; the pooled-vs-mean-of-means difference is the
one the article already carried (the table reproduces its 26.8 %). `shape_b` unit chain:
`cv_ann` is mm/yr (compared with `obs_mm` in `wb_cv_lib.R:52`) x share / `wet_month_days()`
-> mm/day, x `upstream_area_m2 / 1000 / 86400` -> m3/s. Correct.

**Edge cases (probed on copies).** `wet_shape_spline()`: all-zero row -> every month flat and
flagged; constant row -> exactly 1/n; one positive month -> other months floor to 0 and are
flagged, sums stay 1; `Inf` -> refused as NA. The periodic `splinefun` gets `y[1] == y[n]` by
construction. `wet_shape_within()`: negative days in a month with positive total give
negative weights that still sum to 1 (not reachable from flows; `wet_shape_predict()` floors
first). Vector inputs become 1 x 365 with a 1 x 12 `flat`. `wet_shape_daily()` strips
dimnames and the `flat` attribute. Two donors at distance 0 average (weights 1, 1). k is
capped. `wet_shape_flat(0)` emits a harmless `matrix()` warning.

**`wet_station_doy()`.** Counts days as `wet_complete_years()` does (`FLOW%d IS NOT NULL`
per DLY_FLOWS row), and the script's recompute uses `wb_stations.R`'s `years`, `min_years = 10`
and default `min_days`. Invalid calendar days fall out through `as.Date(optional = TRUE)`
(first element is always a day 1, so the format is chosen correctly). 29 Feb is averaged
into 28 Feb within the year before years are averaged. The wrap-around `approx()` is right.
`aggregate()` formula interface: no NA rows reach it, grouping types are preserved, and
results are indexed by `doy` so ordering is irrelevant. `local_hydat()` is a per-test
`withr::local_tempfile()`, so the UPDATEs in the tests cannot contaminate each other.

**Report arithmetic vs research text.** Every number in `research/water_balance_method.md`
§"Daily shape within the month" and in CLAUDE.md matches `data/checks/wb_shape_daily_20260717.txt`
(medians, gains, leak, lake outlets, zones 14/15, 27-29, Chinook percentages, free curve).

## Findings

- **[fragile, prose]** `research/water_balance_method.md` §"Daily shape within the month (#70)",
  bullet "Where donor does not lead": lists lake outlets, zones 14 and 15, and peak-outside-
  May-June. The report's zone table has seven more zones where donor is not the leader:
  01 (spline 0.988, basis 0.981 > donor 0.977), 04 (0.914, 0.902 > 0.898), 11 (spline 0.933 >
  donor 0.807, the largest shortfall anywhere, 2 gauges), 13 (0.990 > 0.988), 16 (basis 0.985 >
  0.984), 17 (0.952, 0.951 > 0.924), 26 (0.954 > 0.940). An enumerated "where it does not
  lead" that omits the worst case misleads a later reader; either list all nine zones or
  phrase it as a count (donor leads in 20 of 29 zones) with the extremes named.

- **[fragile, report]** `scripts/wb_shape_daily.R` header clause for `spline`: "a month that
  ... is all 0, falls back to flat and is counted". The body counts fallbacks only for the
  fitted settings (`n_fallback` over `names(settings)`); `line_of()` prints `-` for spline and
  flat. On this fit the count is provably 0 (every observed monthly mean is positive, and a
  periodic cubic through a positive mid-month knot cannot be <= 0 over the whole month), so no
  number is wrong, but the report shows `-` where the registered text promises a count. One
  line: `n_fallback["spline"] <- sum(attr(held$spline, "flat"))` before the report.

- **[fragile, report]** `scripts/wb_shape_daily.R` ~line 384: the Chinook section heading
  hardcodes `"1981-2010"` while the record is read with `min(s$years)`/`max(s$years)`. True for
  this release; a stations rds with another window would make the tracked report lie about
  its own years. Use `sprintf("%d-%d", min(s$years), max(s$years))`.

Also noted, not a defect: in the "weights alone" column, spline is scored from the observed
months (`held$spline`) while donor/basis are held out, so spline's 0.752 there carries an
in-sample advantage the research text ("On the weights alone ... spline 0.752") does not
mention. The rule column uses observed months for every candidate, so the decision is
unaffected.
