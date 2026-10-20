# Findings — Publish segment_daily (#99)

## Issue context

**If we do it:** a segment's flow can be read for any week or month-day window from a published daily climatology for both sources, with the balance's days consistent with its published months. **If we never do:** the daily shape #70 fitted and scored stays in the fit directory, and every window read still spreads each month's mean over its days (up to 27 % off the gauge in the Chinook fry-migration window, #65).

## What exists

- **The balance's shape within the month (#70, shipped in the fit):** `fit_20260717/shape_daily.rds`, a donor fit (k = 5) chosen under a pre-registered rule (median per-gauge NSE 0.982 on observed months against 0.899 flat; `data/checks/wb_shape_daily_20260717.txt`), refitted on #102's donor months on 2026-10-19 with the same outcome. `wet_shape_daily(Q, wet_shape_predict(fit, d))` gives any watershed's 365 daily flows from its published monthly means, each calendar month averaging to its published value. `wet_flow_window()` already consumes a `doy` frame (`basis = "daily"`).
- **The stored form, decided (`research/discharge_publish.md`):** `discharge/fwa/v1/segment_daily`, one row per segment, source and day of a 365-day common year (`doy` 1–365, 29 February folded into 28), `q_m3s` and `runoff_mm` as the monthly rows; weeks and windows derived on read, never stored.
- **Routed PCIC's days, built by NewGraphEnvironment/fwapg#25 (closed, PR #32).** fwapg did not build a per-segment daily table (it would hold about 1.24 billion rows a run). It keeps sub-basin days and per-segment weights, from which any segment's flow over any set of days follows:
  - `pcic.subbasin_daily` (`model, scenario, period, subid, month, day, n_days, q_local, q_acc`): 366 calendar bins `(month, day)` per PCIC sub-basin (37,667), as `cdo ydaymean` makes them, Feb 29 a bin of its own. `n_days` is how many days of the period fall on that bin (30 for 1981–2010; 7 for Feb 29).
  - `pcic.segment_weights` (`linear_feature_id, watershed_group_code, subid, share, upstream_subids`), one row per FWA segment, shared by every run.
  - Flow on a segment over a set of days is `greatest(sum(q_acc of upstream_subids) + q_local(subid) * share, 0)`, with `q_acc` and `q_local` first averaged over the days, weighted by `n_days`. That reproduces `pcic.discharge_monthly` and `pcic.discharge_weekly` exactly.
  - `pcic.day_bins` (`month, day, week`) and `pcic.runs` (`daily_rows`, `daily_subbasins`, `daily_q_sum` = `sum(round(q_acc::numeric, 6))`, `weights_rows`, `weights_share_sum`).
  - Both PNWNAmet runs (1951–2012, 1981–2010) are published to `fresh-bc/fwapg/extras/` and loaded by fwapg's `load.sh`; the per-run file pipes into `load/pcic_run.sql -v table=subbasin_daily`.
  - Source: fwapg's `research/pcic_routed_flow_periods.md`.

## Routed days on the 365-day year

- **The fold.** Feb 29 folds into Feb 28 by the `n_days` weights, on `q_local` and `q_acc` alike, before routing:
  `q(2,28)' = (q(2,28) * n(2,28) + q(2,29) * n(2,29)) / (n(2,28) + n(2,29))`.
  The fold is linear, so it commutes with the weights.
- **The clamp, per day.** A day's value is the routed average over one bin, so the clamp applies to each day. fwapg measured 0.978 % of rows clamped monthly and 0.977 % weekly (0.049 % and 0.048 % mid-network), and did not measure a daily step. Measure it first: clamped rows per day, overall and mid-network.
- **What the clamp does to consistency.** Where it bites, a month's mean of clamped days is larger than the clamped month, so routed days need not average to the published routed month (the balance's do, by construction). Report how many segment-months differ and by how much, and say so in the dataset's description.
- **The value check.** `discharge_publish.R` checks routed days against the weights and `pcic.subbasin_daily` directly (exact), not against the months.

## Order

- **After #101,** which reads routed flow through the `pcic` schema with the run named once; the daily read uses the same run definition.
- **After #103,** if routed is switched to 1981–2010: the daily's run must be the published monthly's.
- **After #102 (done 2026-10-19, PR #106):** the donor gauges' monthly shares ship (published in build 8ca2dee), and the balance's daily shape stays #70's within-month donor, refitted on the new months (`scripts/wb_shape_daily.R`, on m1 and m4). Held out, that shape now scores a median NSE of 0.909 against the gauges' daily records (0.849 on the regression's months), equal to the donor's free 365-day curve (0.9091), so the curve would add nothing. The decision is closed: publish `shape_daily.rds` laid on the published months.

## To do

1. `scripts/pcic_routed_lib.R`: the routed daily read (weights × `pcic.subbasin_daily`, folded, clamped) under #101's run definition, with its fingerprint computed and asserted against `pcic.runs`, as #101 does for the months. Measure the per-day clamp.
2. crate: `inst/extdata/schemas/nge/discharge/fwa/v1/segment_daily.yaml`, released, and `discharge_publish.R`'s crate release check extended to it.
3. Readers over `doy`: `wet_segment_monthly()`'s two read paths hard-code `month` (in `wet_segment_pg()` and `wet_segment_parts()`, `R/wet_segment_monthly.R`); `wet_timebase()` gains `daily = list(col = "doy", values = 1:365)`; a `wet_segment_daily()` wrapper; `wet_db_load()`'s `months` and its partial index; `wet_values_compare()`'s `id * 16 + month` key (a `doy` key, still exact).
4. `scripts/segment_output.R` per-basin daily tables from `output/` months and the fit's daily shape (the balance) and the routed daily read, with `pick` carried from the monthly table; `scripts/discharge_publish.R` building, checking value by value and uploading the new dataset beside `segment_monthly`.
5. Size: about 2.9 billion rows (4.9 M segments × 365 × sources), roughly 28× the monthly parts' 1.84 GB; S3 holds every segment, the Postgres load is partial and on request (#70's storage section).
6. The monthly-flow article's limits line (`vignettes/monthly-flow.Rmd`) points here; the segment-discharge article gains the daily read once published.

Relates to #59, #65, #70, #101, #102, #103, NewGraphEnvironment/fwapg#25.



## Routed days reproduce fwapg's months and weeks (Phase 1 probe, 2026-10-20)

Produced by a probe run on m1 against m4's fwapg over the LAN (m1's `pcic.subbasin_daily` is empty);
log `data/logs/99/probe_routed_days.log`, results `data/logs/99/probe_routed_days.rds`. 19.8 min.

- Inputs: `pcic.subbasin_daily` PNWNAmet historical 1981-2010, 13,786,122 rows, 37,667 sub-basins,
  total q_acc 636,284,197.301372 m3/s; `pcic.segment_weights` 3,377,037 rows, shares 558,010.174364980,
  both equal to the run's `pcic.runs` row.
- Months: routing the n_days-weighted mean of the raw days, clamping and rounding with
  `wet_routed_round()`, gives `pcic.discharge_monthly` on all 40,524,444 rows (199 groups), 0 differing,
  not even by one 1e-5 step. Routing the period mean and averaging the routed days agree to relative
  1.2e-12 (linearity).
- Weeks: BULK, LFRA, SQAM, FRAN, SETN, 8,467,940 rows of `pcic.discharge_weekly`, 0 differing.
- Rounding: `wet_routed_round()` equals Postgres's `round(x::numeric, 5)::float8` on 200,006 values
  (200,000 real flows and six constructed 15-digit ties); R's `round()` alone differs on 4 of the ties.
- Weights: `upstream_subids` are the immediately upstream sub-basins (whose q_acc is accumulated), at
  most 101 per segment, 489,610 in all, 35,023 distinct sets. No NA subid, share or upstream set; shares
  0 to 1.
- Per-day clamp (rule set before measuring: published whatever it is; above 0.1 % mid-network it is a
  stated weakness): 1,232,618,505 segment-days, 13,456,319 clamped (1.092 %, against fwapg's 0.978 %
  monthly and 0.977 % weekly), 10,581,629 more than 1 L/s below zero; mid-network 97,680,205 rows,
  48,440 clamped (0.050 %, against 0.049 % monthly and 0.048 % weekly). Under the 0.1 % line. Worst
  days mid-network: 16 May 874, 25 May 869, 11 May 867, 12 May 864, 15 May 860 (worst month May 774,
  worst week 22 805). A daily step adds a little clamping overall and almost none mid-network.

## Errors Encountered

| Error | Resolution |
|-------|------------|
