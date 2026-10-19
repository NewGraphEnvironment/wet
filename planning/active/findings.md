# Findings — Monthly shares from donor gauges (#102)

## Issue context

**If we do it:** the balance's monthly shares at ungauged watersheds come from the most similar gauges' own day-of-year records instead of, or blended with, the twelve share regressions, and #70's measurement says that is worth about +0.065 median NSE at the monthly scale on the held-out gauges. **If we never do:** the shipped shares stay the #16 regression, which the monthly article already shows flattens the freshet (#16, #65), and the stronger shape sits in a report nobody acts on.

## What #70 measured

In `scripts/wb_shape_daily.R` (#70), the donor mean of the five nearest training gauges' day-of-year shares, with **no** within-month constraint, summed to months, scores a median per-gauge NSE of **0.939** against each gauge's observed monthly shares. The shipped held-out shares (`cv_share`, the #16 regression with the snow predictors) score **0.874** on the same 315 gauges. `research/water_balance_method.md`, "Daily shape within the month (#70)", records the numbers; `data/checks/wb_shape_daily_20260717.txt` is the report.

The comparison is like for like: both are held out in the shipped fit's blocked folds (94 WSC sub-sub-drainages, donors drawn from the training gauges only) and scored against the same observed shares, which the script asserts. Two things it did not do:

- **No leak test.** #70 tested its within-month donor with a pool that drops the gauges upstream and downstream of the held-out one (median 0.9824 with them, 0.9818 without). The free curve was not tested that way.
- **No breakdowns.** #70's within-month donor trailed the spline at gauges peaking outside May and June (0.927 against 0.933), at lake outlets (0.979 against 0.994), and most in hydrologic zones 11, 17 and 04.

#70 reported this and decided nothing: its rule scored the shape *within* the month, so every candidate there inherits the shipped months. This issue is the monthly question.

## Proposed

- **Fix the candidates now, before scoring them.** The donor's 0.939 is already known, so what guards against a lucky pick is fixing everything about the candidates in advance, not the margin:
  - donor: k = 5 in the five static share predictors (`elev`, `e_km`, `n_km`, `snowmelt_doy_50`, `swe_max`), each scaled by its spread across the training gauges, inverse-distance weights, as `wet_shape_fit(method = "donor")`;
  - blend: the equal-weight mean of donor and regression shares;
  - incumbent: the shipped regression.
  No k, predictor set or weight is tuned after scoring.
- **Register the rule in the script header before the run,** as #16 and #70 did: median per-gauge share NSE, held out under the shipped fit's blocked CV; a candidate ships if it beats the shipped shares by at least 0.01 (#16's margin) **and** still does with the leak-free pool. If both candidates pass, the higher one ships.
- **No "kept on both fits".** Since #81 current code refuses the 2025-10-14 fit, and the two fits share the 1981–2010 window and most of their gauges (#16 gained +0.014 and +0.018 on them), so the clause was close to one test run twice. Reported beside the rule, not gating it: headwater and nested gauges separately, and the short-record test stations wherever their record gives twelve months.
- **Breakdowns** as `scripts/wb_share_snow.R` gives them (month, zone, freshet gauges, the Liard), plus gauges peaking outside May and June, lake outlets, and zones 11, 17 and 04, where #70's donor was weaker.

## Decide before registering: months only, or the daily curve too

If the donor ships, either:

1. **Months only.** The donor's months replace `cv_share`; #70's within-month shape is refitted on the new months (`scripts/wb_shape_daily.R`, which hashes no scoring file, so nothing marks it stale: rerun it by hand).
2. **The daily curve.** The donor's 365-day curve is the balance's daily shape, and its monthly sums are the months. This replaces #70's within-month shape and changes what #99 publishes for the balance.

## Cost

A change to the shares changes `cv_share`, the fit's scores and the published months, so it stales the fit: rescore every AET variant (`scripts/wb_validate.R`), `scripts/wb_aet_compare.R`, then `scripts/wb_validate.R <winner>`, then `wb_share_snow.R`, `wb_shape_daily.R`, `wb_output.R`, `segment_output.R` and a publish. Annual flow does not change, so no `pick` moves. #103 published on its own on 2026-10-19 (routed PCIC now 1981–2010, live build wet 94deeb5), so this issue's publish is its own: one chain, one upload, one rewrite of the monthly article's balance scores.

Relates to #16, #65, #67, #70, #81, #99, #103.



## Exploration (2026-10-19, plan mode)

- Shares are produced in `predict_cv()` (`scripts/wb_cv_lib.R`, hashed) per static set (`share_static`: base/snow/doy); `wb_validate.R` applies #16's rule (`share_min_gain` 0.01) and writes `fits$share` (a `wet_share_fit`) and `share_spec`.
- `scripts/wb_output.R:63` predicts shares with `wet_share_predict(fits$share, up)`: a method stored inside the fit object keeps that line unchanged.
- Consumers of `share_spec`/`cv_shares`: `data-raw/monthly_vignette_data.R:57-59`, `vignettes/monthly-flow.Rmd:525`, `scripts/discharge_publish.R:306`, `scripts/wb_share_snow.R` (base/snow only), `scripts/wb_shape_daily.R:125,165`.
- #70 report: free curve months 0.9388 vs cv_share 0.8735 (315 gauges); within-month donor 0.9824 obs months; free curve daily 0.9091 vs within-month donor on held-out months 0.8489.
- m1 holds a reduced bundle; fits run on m4 (memory). m4 lacks `shape_daily.rds`.

## Errors Encountered

| Error | Resolution |
|-------|------------|
