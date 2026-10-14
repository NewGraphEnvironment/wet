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

## Phase 1: the snow inputs in cd (2026-10-14)

Read from cd `origin/main` at 5611c59, and the published catalog (`cd::cd_catalog()`, default `https://stac-era5-land.s3.us-west-2.amazonaws.com/catalog.json`).

- **Files.** `snowmelt_doy_50_annual.tif` (2.07 MB) and `swe_max_annual.tif` (5.68 MB), cd_sha 349f9d7, run 2026-10-10T22:36:36Z. 76 bands named 1950–2025, 0.1°, extent −140.05…−113.95, 47.95…60.05 (121 × 261, the full grid after cd#123's 60 N fix, cd d7542e3).
- **Completeness, 1981–2010.** Counted per cell: non-NA years are 0 or 30, never between. doy: 20,739 cells at 30 and 10,842 at 0. swe_max: 20,746 at 30 and 10,835 at 0. The zero-year cells are sea. 7 cells carry swe_max but no melt year (`annual_sum > 0` fails); they get the nearest fill like any other cell with no value.
- **cd#139 cannot reach a baseline.** `cd_baseline()` (R/cd_baseline.R) is `mean(value, na.rm = TRUE)` over `baseline_years` by `variable, period`. It never reads `cd_variables()$anomaly_type`, which only `cd_anomaly()` uses. wet's per-cell baseline uses the same definition: the mean over the 30 year bands per cell (with no NA inside the 30 on land, `na.rm` changes nothing).
- **cd#88 does not reach 1981–2010.**
  - `swe_max` is `max(sde * rsn)` over daily means of *state* variables, sliced `{year}-01-01T00:00` to `{year}-12-31T23:00` (`scripts/backfill_edh_snow.py`), so it is untouched by #88, which concerns the accumulated variables only.
  - `snowmelt_doy_50` comes from accumulated `smlt`, sliced `{year}-01-02T00:00` to `{year+1}-01-01T00:00`. A 364-day year arises only when the hourly store ends at `{year}-12-31T23:00`, which is the state at a January run of year+1.
  - Every 1981–2010 year was written by a bulk backfill: the cd#48 run of 2026-05 (`planning/archive/2026-05-issue-48-snow-vars/progress.md`: "2h52min for 75 years", 1950–2025 in one pass), then the rebuild after cd#123's grid fix (2026-10-08). At both, the store ran into 2026, so `{year+1}-01-01T00:00` existed for every baseline year. The January-run path is the only way #88 bites, and it was never the path for these years.
  - Even where it bites, it drops Dec 31's melt from the annual sum, which moves the 50 % crossing by at most the share of the annual melt that falls on Dec 31.

## Phase 3: wet_snow_normals() against cd_baseline() (2026-10-14)

`wet_snow_normals()` onto a 30″ grid over a box, area mean, against `cd::cd_baseline(cd::cd_extract(cat, box, years = 1981:2010))` over the same box (cd 0.5.0, the published catalog):

| box | variable | wet | cd_baseline | diff |
|---|---|---|---|---|
| Bulkley −127.4…−126.4, 54.4…55.0 | snowmelt_doy_50 | 141.26 | 141.59 | −0.23 % |
| Bulkley | swe_max | 417.12 | 423.79 | −1.57 % |
| Quesnel −123.0…−121.8, 52.6…53.3 | snowmelt_doy_50 | 98.74 | 99.49 | −0.76 % |
| Quesnel | swe_max | 162.87 | 165.69 | −1.70 % |

The definitions agree; the differences come from the area each one averages: `cd_crop()` snaps out, so it takes the 0.1° cells straddling the box edge whole, while the bilinear grid weights them by position. The test suite pins the definition exactly (the mean over exactly `years`, `test-wet_snow_normals.R`); a mutation that averages every band fails 6 of its 20 expectations once the fixture's years are asymmetric about the baseline (the first fixture, 1979–2012, had the same mean as 1981–2010 and let it through).
