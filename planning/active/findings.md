# Findings — Snow predictors for the monthly shares (#16)

## Issue context

**If we do it:** the monthly split may improve where timing is snowmelt-driven. The median blocked-CV NSE on the shares is 0.87; zones 27–29 are at about 0.5. **If we never do:** the monthly shares keep using monthly P, T and AET only.

## Evidence (#65, 2026-10-14)

The monthly-flow article scores the held-out balance month by month at all 315 calibration gauges (3,780 gauge-months). Its median error is +8 % to +16 % from January to May and within ±5 % from June to December. Fewer than half the gauges are within ±20 % in any month. At the 25 gauges routed PCIC does not reach (19 in WSC area 10, the Liard), it reads low instead, by −67 % to −96 % in January–March. In 123 gauge-months, 36 of them in January, the held-out share is zero, so the balance predicts no flow at all. It flattens the freshet: at the 243 gauges whose flow peaks in May or June, it is below the gauge in the peak month at 69 % of them, by a median of −15 %. At Buck Creek (08EE013), the gauge's May mean is 22 m³/s, and the balance's highest month is June, at 9.6 m³/s. Its median held-out monthly NSE is 0.71, and on the 279 gauges shared with routed PCIC it is weakest at lake outlets (0.52). Score any change on those same held-out gauge-months.

## Proposed

Add `cd`'s ERA5-Land `snowmelt_doy_50` and `swe_max` (1981–2010 baseline via `cd_baseline()`) as upstream-mean predictors in `wet_share_fit()`. Keep them only if blocked-CV skill on the shares improves.

Prefer predictors that are dates over amounts per month where both would serve. `snowmelt_doy_50` is the day of the year by which half the snowpack has melted, and a date carries over unchanged to sub-monthly flow (#70), where it would predict the freshet's timing in a day-of-year hydrograph. A monthly amount such as April SWE does not.

## Done with #68 (decided 2026-10-14)

Adding predictors changes `R/wet_share_fit.R`, which `score_files_for()` hashes (`scripts/wb_score_md5.R`), so every fit goes stale and the chains are rerun on the machine holding both releases: the `fit_20251014` chain first, then the shipped fit (`CLAUDE.md`, "Any scoring-code change stales every fit"). #68 stores the held-out monthly balance (`cv_share`) in `cv_aet-<AET>.rds`. It changes `scripts/wb_validate.R`, which is hashed too, so it lands in the same rerun. Land #68's storage first in the branch, so that this issue's before-and-after share scores read stored held-out months rather than recomputing `predict_cv()`.

## Before starting: check the snow inputs in cd

- **NewGraphEnvironment/cd#88.** The annual snow variables, `snowmelt_doy_50` and `swe_max` among them, can be written from a 364-day year at a January run, and once written they are never recomputed. Confirm that none of the 1981–2010 baseline years was written that way before using them as predictors.
- **NewGraphEnvironment/cd#139** (`swe_max` anomaly type: absolute or percent of normal) affects `cd_anomaly()`, not baseline values. This issue uses baselines, so it should not matter. Confirm that the baseline call does not route through the anomaly type.

## Order

1. Check cd#88 and cd#139, as above.
2. Land #68's storage of held-out monthly values.
3. Add the snow predictors to `wet_share_fit()` and its predictors' upstream means.
4. Rerun both chains. Keep the predictors only if blocked-CV share skill improves on the same held-out gauge-months, reported by zone (zones 27–29) and for the freshet-peak gauges named above.
5. Then #6 reports where it helped by region and season, and #70's balance side can use `snowmelt_doy_50` for freshet timing.

Relates to #11, #65, #70, #68, #6, NewGraphEnvironment/cd#88, NewGraphEnvironment/cd#139.

## Errors Encountered

| Error | Resolution |
|-------|------------|
