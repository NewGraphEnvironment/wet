# Findings — PCIC per-year routed flow: keep the years, weight donors by modelled covariance, and score donors, PCIC and a blend at held-out gauges (#122)

## Issue context

**If we do it:** where no gauge exists, wet knows which gauges move with the place from PCIC's modelled 1951–2012 years, and PCIC's own skill at carrying year-to-year change on small basins is a number rather than an assumption. **If we never do:** donor weights rest on distance and similarity alone, and PCIC's per-year run stays unused.

Component 3 of #118. Two halves, one in the fwapg fork and one here.

### Problem

PCIC's routed run (hydromosaic, Raven over VIC-GL, PNWNAmet daily 1950–2012) is daily and year by year, but fwapg's crosswalk reduces each batch with `cdo ymonmean` and deletes the daily file, so fwapg holds only climatologies: `pcic.discharge_monthly`, and `pcic.subbasin_daily` as 366 day-of-year bins. Change over time needs the years.

### Proposed approach

**fwapg half (NewGraphEnvironment/fwapg#42).** Keep the per-year series from the fetch. Options for the plan gate, after counting the outlets:
- (a) per-year window statistics for a fixed window set, which ties fwapg to wet's windows;
- (b) per-sub-basin per-year days as parquet, routed to segments on demand through `pcic.segment_weights` as the daily climatology is, so no window need be known in advance;
- (c) per-year monthly and weekly means per sub-basin in Postgres.
The days per segment are about a billion rows; per sub-basin they are the outlet count times 23,011, which is what to measure first.

**wet half.**
1. Per-year window statistics from routed PCIC at every gauge PCIC covers (290 of the shipped fit's 315 calibration gauges, and the short-record test gauges), 1951–2012, in `wet_window_stats()`'s shape.
2. **Donor weighting by modelled covariance.** For a target and its candidate donors, the covariance of modelled per-year departures over 1951–2012 enters the `wet_donor_mean()` weights beside similarity.
3. **The competition.** At held-out gauges over 1951–2012: donors alone (observed departures carried), PCIC's own departures at the segment, and a blend. The rule is registered before any candidate is coded, scored under blocked CV and in a leak-free pool (each held-out gauge's upstream and downstream gauges removed) as #102 did. After 2012 only donors carry values whatever wins.
4. **Outputs.** A report under `data/checks/`, scored under `WET_FWAPG_COMMIT` as `scripts/pcic_routed_compare.R` is, and the result in `research/pcic_hydrology.md`.

Depends on #120 for the rule's shape and the first estimator.

Relates to #118, #58, #102, NewGraphEnvironment/fwapg#42, NewGraphEnvironment/fwapg#25, NewGraphEnvironment/fwapg#28.

## Plan-mode exploration (2026-10-26)

- **This is the machine.** 137 GB RAM, 274 GB free. fwapg's crosswalk ran here (fwapg's `extras/pcic_crosswalk/data/series/` holds 1,061 batch lists); the fit bundle `data/wb/92b893c4da/fit_20260717/` and `data/wb/stations_20260717.rds` are here; the fwapg database is reachable through `WET_PG*`.
- **`pcic` schema (measured):** tables `day_bins, discharge_monthly, discharge_weekly, fwa_crosswalk, runs, segment_weights, subbasin_daily`. `pcic.runs` has two PNWNAmet historical rows, periods 1951-2012 and 1981-2010, each 40,524,444 monthly rows over 3,377,037 segments and 13,786,122 daily rows over 37,667 sub-basins; `segment_weights` 3,377,037 rows (bigint `linear_feature_id`, text `watershed_group_code`, int `subid`, double `share`, int[] `upstream_subids`). `subbasin_daily` columns: model, scenario, period, subid, month, day, n_days, q_local, q_acc (double).
- **`upstream_subids` names only the placed outlets directly above:** max cardinality 101, total 489,610 over 3.4 M segments. `q_acc` is accumulated on the FWA tree in `pcic_crosswalk06_subbasins.sql` (linear). So a segment's per-year days need at most 102 sub-basins' series; `wet:::wet_routed_raw()` already does the arithmetic for any number of columns.
- **The hydromosaic fetch is cheap:** `pcic_crosswalk.sh` uses the bulk NetCDF endpoint (500 outlets per request, `xargs -P 3`), 19 min for the whole network on 2026-10-17 (27 min with weekly). The per-year days exist in those NetCDFs before `cdo ydaymean`; fwapg#42 is to keep them and derive per-year `q_local`/`q_acc`. fwapg#42's body measured 867 M rows; 5.1–10.3 GB parquet depending on type.
- **Coverage:** 290 of 315 calibration gauges have routed flow on their segment (`data/checks/pcic_routed_compare_20260717.txt`); five route to about 0 (08JA015, 08JA016, 08JA014, 08JA028, 08DB013) and 11 carry under 20 % of observed.
- **08EE018 is in neither `$stations` (352 rows) nor `$test` (137 rows, `n_years` 1–9) of the stations rds:** `wb_stations.R` selects on complete years inside 1981–2010, and Maxan ran 1975–1979. The #120 box short-record set (13 gauges) is what carries it; the pilot snapped the box with `wet_station_snap()` for its leak-free lines.
- **`scripts/pcic_routed_lib.R` is fixed to the 1981-2010 run** through `routed_where` (from `wet:::wet_segment_sources()`), so `routed_daily_fingerprint()`, `routed_report_line()` and `routed_daily_inputs()` need a `period` argument for the 1951-2012 run; `routed_daily_inputs()` reads the whole fold (~1 GB) to get weights, which the competition does not need.
- **`wet_departure_carry()`** gets its donor weights from `wet_donor_mean()` on the identity matrix and renormalises per year; a donor needs ≥ 10 baseline years of the statistic carried, so the pool must be per (variable, period) as the pilot's `dep_pool_of()`. `wet_station_space()` scales predictors over the rows it is given, so one stations table must serve every run.
- **The pilot's committed report rests on bare `PG*`** reaching an fwapg server for its leak-free lines (a machine-local note); regenerating it byte-identical needs that environment.
- **Plan review** (`review-plan.md`): 3 blockers (common scoring years; parity tolerance vs float32; `doy` vs month-day bins), 9 gaps, 2 ordering points, 4 assumptions, 4 scope, 4 acceptance. All folded into `task_plan.md` and marked by their codes.

## Phase 1: the header (2026-10-26)

- **`pcic.subbasin_daily` holds full float64 means** (measured 2026-10-26 on the 1951-2012 run): over 73,200 `q_local` values, 1 in 73,200 is float32-representable (chance), and no `q_local` or `q_acc` value is 5-decimal rounded; `q_acc` at the largest sub-basin (4009421) is `1197.5002032...`. `n_days` runs 16 (29 February) to 62. So a float64 per-year product can meet 1e-9 relative parity. The header also fixes the float32 alternative (2^-23 relative, which bounds the mean of round-to-nearest float32 values), so fwapg#42 choosing float32 needs no amendment.
- **Decisions the plan left open, fixed in the header:** one challenger per stage, chosen by the leave-one-gauge-out median (a tie to the first listed), which must then clear the incumbent under both pools; a year in which every present donor weighs 0 is missing for that candidate; `covariance_pick` ties on r go to the nearer donor; a test gauge in the migration-mean pool is dropped from the test set.
- **Header amended before any candidate (second commit):** the first header said the distance weight's m is "the median of the k distances"; `wet_donor_mean()` takes the median over the target's distances to every donor, and a donor at distance 0 takes the whole weight. The pool also now says a baseline year needs a value > 0, since `wet_departure_carry()` drops values <= 0 from a log statistic. Caught by reading the carry code at the start of Phase 2.
- **Limit stated in the header:** PCIC publishes no calibration gauges, so `pcic`'s score at a calibration gauge may be partly in sample (`research/water_balance_method.md`, #58).

## Phase 2: covariance weighting (2026-10-26)

- **The default path is byte-identical:** `wet_departure_carry()` on a 12-gauge synthetic case (two statistics, three targets, missing years) serialises to the same bytes before and after the change (`identical(serialize(a), serialize(b))`).
- **Mutation table, `wet_donor_weights()`** (each restored in a copy of the tree; failed test blocks across its test file and the carry's):

| restored defect | failed blocks |
|---|---|
| covariance weight `wt * r` instead of `wt * max(r, 0)` | 2 |
| covariance_pick chooses by distance, not r | 1 |
| r needs 3 common years, not 30 | 1 |

## fwapg#42 was gated in parallel (2026-10-26 23:47 UTC)

- A parallel session ran `/planning-init fwapg#42` and parked it (fwapg e7ec7ef, d43eaaf) about ten minutes after this session resumed #122. Its gate decided float32, a `date` column, one file per year, and the catalogue `pcic.series` with no commit; its plan never mentions wet's item 6. Re-running `/planning-init` would overwrite that parked baseline, so the interface section of this header was amended to consume what fwapg decided instead (own commit), and fwapg#42's resume is left to the user.
- **The first float32 tolerance was wrong:** 2^-23 relative to the bin mean fails wherever a bin's values change sign (a losing reach), because float32 rounding bounds the error relative to each value, so the mean's error is bounded by 2^-24 × mean |v|, not by the mean. The amendment uses 2^-23 × mean |v| + 1e-9 m³/s. fwapg#42's own QA (`1e-6 * greatest(abs(clim), 1e-3)`) has an absolute floor of 1e-9 m³/s where the climatology is 0, which the same sign change could break; worth raising when fwapg#42 resumes.
- **AC1 held:** `departure_pilot.R` rewrote `data/checks/departure_pilot_20260717.txt` byte-identical (23:50 to 23:53 UTC, R's environment as is); `pcic_routed_compare.R` rewrote its report identical but for the line recording the wet commit, which was restored. Logs: `data/logs/122/*_phase2.log`.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| Probing the `pcic` schema inline with `Rscript -e` and a `sed` quote swap broke the SQL (`zero-length delimited identifier`) | Put the probe in a script file in the scratchpad and run it with `Rscript <file>` |
