# Findings — Sub-monthly flow per segment: a daily climatology for both sources, with weeks and windows derived from it (#70)

## Issue context

**If we do it:** a segment's flow can be read for any date range, such as a week or a species window like Chinook fry migration (Jul 15 – Sep 7), without estimating it from monthly means. The monthly-flow article (#65) measured that estimate at up to 27 % off the gauge's daily record. **If we never do:** every weekly or window question rests on monthly means, and the balance's flattened freshet (#16) cannot be seen below the month.

## What exists

- **Routed PCIC is daily at source.** hydromosaic serves PNWNAmet streamflow daily for 1950–2012 on the sub-basins NewGraphEnvironment/fwapg#6 placed on the FWA. NewGraphEnvironment/fwapg#25 proposes reducing it with `cdo ydaymean` to a 366-day climatology and keeping that, so weeks and months come from one fetch. The routed side of this issue is fwapg#25. It also names the risk: over short steps, routing lag makes local runoff negative more often, and those values are clamped. Count the clamped rows before trusting short-step flow mid-network.
- **The balance is monthly by construction.** Its inputs are monthly normals: climr precipitation and temperature, and CGIAR AET. Its time split is twelve regressions, one per month (`wet_share_fit()`). There are no daily normals to regress on, so a daily balance needs a different method, not 365 more regressions.
- **HYDAT daily records at the calibration gauges** (`wet_station_daily()`). They give each gauge's day-of-year climatology to fit and score against.

## Proposed

- **Balance:** annual volume from the water balance as now. The shape within the year comes from a day-of-year hydrograph fitted at the gauges and carried to ungauged watersheds. Two candidates, both scored held out under the same blocked CV:
  1. a parametric curve whose freshet timing and spread are predicted from snow timing (#16's `snowmelt_doy_50`) and the monthly predictors;
  2. donor gauges: the shape of the most similar gauged catchments.

  Score them on the held-out gauges' daily climatology, and on flow in the Chinook windows at the Bulkley gauges the monthly article uses (08EE013, 08EE003, 08EE004).
- **Stored form:** a day-of-year climatology (366 values) for both sources. A week is a fixed day-of-year bin, as fwapg#25 defines it, and a window is a sum over its days. Both are derived on read, not stored separately.
- **Published** as a new dataset beside `segment_monthly`: `discharge/fwa/v1/segment_daily` (`research/discharge_publish.md`).

## Storage

Daily values on every segment come to about 1.2 billion rows per source (3.37 M segments × 366), against about 44 M monthly. Recommended:

- **S3 holds daily for every segment**, partitioned by basin as now, so a reader of one watershed reads a small part. The Bulkley's 32,472 segments are about 12 M rows. The size is unmeasured; parquet should compress it to a few GB per source.
- **The Postgres load is optional and partial.** `wet_db_load()` loads one basin, or a derived period such as weeks or a window, on request, not the whole daily table. The monthly segment table took 20 GB with indexes, so a full daily load would be roughly 28 times that.

Alternatives considered:
- Daily only at watershed or gauge scale. Smaller, but gives no daily flow on a segment.
- A few curve parameters per segment, expanded on read. Smallest, but it ties the stored form to one method, and routed PCIC has no such curve.

## Order

1. NewGraphEnvironment/fwapg#25 keeps the daily climatology. This is the routed side, and it needs no new method.
2. #16 adds snow-timing predictors to the monthly shares. They become this issue's shape predictors.
3. The balance's daily shape, scored as above.

Relates to #3, #16, #59, #65, NewGraphEnvironment/fwapg#25.


## Plan-gate decisions (2026-10-17)

- **Scope:** method + held-out scoring + the fit artifact. Publishing `segment_daily` is a follow-up issue (fwapg#25 open; crate schema; m4 run of ~2.9 billion rows). A `wet_segment_daily()` reader was dropped on plan review: both read paths hard-code `month` (R/wet_segment_monthly.R:197, :228) and it would export a reader for a dataset with no parts.
- **Consistency:** within-month shape; each calendar month of days averages to the published monthly mean flow. The issue's free day-of-year curve is measured and reported, deciding nothing.
- **Day count:** 365, common year, 29 Feb folded into 28 Feb (`wet_flow_window()`'s convention).

## Exploration

- `attr(s$stations, "years")` is `NULL` in `data/wb/stations_20260717.rds`: `wb_stations.R`'s `merge()` drops it. `s$years` is the scalar `1981:2010`. The script recomputes complete years with `wet_station_select()` on the same release and asserts `n_years`.
- `cv_aet-cfu.rds`: 315 gauges sorted by station; `obs` min 19.9 mm (the `>= 10 mm` filter is vacuous); `obs_share` has no zero months; `cv_share` has 70.
- Monthly shares use `wet_month_days()` (Feb 28.25, sum 365.25), so a 365-day share is a different quantity (Feb off by 0.8 %). The daily product is defined in flow units: `q[d] = Q[m] * n[m] * w[d]`, `sum_{d in m} w = 1`.
- `score_files_for()` (scripts/wb_score_md5.R:14-17) names what stales the shipped fit; this branch edits none of it. Fit-directory globs are `^cv_aet-.*\.rds$`, `output/`, `segment/` only, so `shape_daily.rds` and `cv_shape_daily.rds` disturb nothing.
- Plan review (Plan agent, 2026-10-17 16:44-16:51 UTC): B1 lost years attribute, B2 month hard-coded in readers, G1 unit mismatch, G2 donor leakage across blocks, G3-G8 edge rules, O1 commit the rule first, O3 basis predictors include the 12 monthly shares, A4 decide on observed months. All folded into the plan.

## Errors Encountered

| Error | Resolution |
|-------|------------|

## Rule registration

The daily-shape rule, candidates and fixed settings are the header of `scripts/wb_shape_daily.R` at commit 44ce054 (2026-10-17), before any candidate code or score existed.

## Outcome of the run (2026-10-17, m1, `data/checks/wb_shape_daily_20260717.txt`)

Rule (observed months, median per-gauge NSE of the 365-day shape, 315 gauges, 94 folds): flat 0.8994, spline 0.9768, **donor 0.9824**, basis 0.9708. Donor beats flat by +0.083, far over the 0.01 margin: **donor ships** (`fit_20260717/shape_daily.rds`, method donor, k = 5, the five static share predictors).

- With the held-out months (the product's skill): flat 0.777, spline 0.832, donor 0.849, basis 0.836. On the weights alone (flat = 0): donor 0.795, spline 0.752, basis 0.680.
- Sensitivities (unable to ship): donor k = 8 is 0.9829 (k = 3: 0.9812); basis 4/8 components 0.9715/0.9700; basis on static + p_yr + t_yr 0.9736. A rule in a new issue could move k; the gain over k = 5 is 0.0005.
- Leak: removing a held-out gauge's upstream and downstream training gauges moves donor from 0.9824 to 0.9818, basis not at all. The donor gain is not nested gauges copying their river.
- Groups: donor has the highest median in 20 of 29 zones; spline leads in zones 01, 04, 11 (0.933 vs 0.807, 2 gauges, the largest shortfall), 13, 14, 15 and 26, basis in zones 16 and 17. Spline also leads at lake outlets (0.994 vs 0.979, 19 gauges) and at gauges peaking outside May–June (0.933 vs 0.927, 74 gauges). Zones 27–29 gain most from donor (0.716→0.842, 0.761→0.923, 0.644→0.855 over flat).
- **The issue's free day-of-year curve** (donor mean of doy shares, no month constraint): median daily NSE 0.909 against the record. Aggregated to months its NSE against the observed shares is **0.939, against 0.874 for the shipped held-out shares (cv_share)**. The free donor curve beats the #16 share regression at the monthly scale. Reported, deciding nothing here; a candidate for a later issue on the monthly shares themselves.
- Chinook windows, Buck Creek 08EE013: fry migration from months 26.8 % over the record, with the held-out donor weights on the same months 16.8 %; spawning 3.0 % → 5.5 %; migration −0.1 → −0.0. Bulkley at Quick 08EE004: fry migration 5.6 % → −2.9 %, spawning −0.5 → −2.3. With the held-out balance's own months (shape_b) the errors are the balance's annual and monthly errors (Buck Creek +150–178 % in the low-flow windows, Quick −13 to −22 %), not the shape's.
- 0 gauge-days needed interpolation; 0 observed gauge-months with no flow; 0 basis fallbacks to flat.
- The report reproduces byte for byte across runs (md5 6700588f… twice before the lint-only edits; the shape-code md5 line is the only line a code edit moves).
