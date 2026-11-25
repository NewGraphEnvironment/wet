# Findings — Water temperature at stations with no record: a whole-station holdout of air2stream parameters predicted from catchment traits and the stream network (#213)

## Issue context

**If we do it:** we learn how well temperature and degree days can be predicted where there is no station, and how much the stream network adds beyond catchment traits. That sets the bar any network model has to beat, and tells us whether per-reach degree days can separate reaches above and below a species threshold. **If we never do:** a per-segment product gets built, or commissioned, without knowing whether it beats a simple trait model, or whether its error swamps the thresholds it is meant to test.

## Problem

`wet_temp_fill()` fits air2stream per station from that station's own record. A reach with no station has no record to fit, so its parameters have to come from something else. Nothing in wet predicts them yet, and the fill's validation hid days or seasons, never a whole station.

Even at a station, with a whole season hidden and the station refitted on the rest of its record, open-loop air2stream misses that season's GSDD by about 129 °C-days (mean absolute error, `research/station_temperature_fill.md`). An estimate without a station can only be worse, and how much worse is the question.

## Proposed approach

- **Truth set:** the 257 stations with complete growing seasons (999 station-years) from the fill's validation. Hide each station's whole record and predict it.
- **Traits per station:** the water balance's upstream means (elevation, easting, northing, `snowmelt_doy_50`, `swe_max`), plus upstream area, and new upstream glacier and lake cover from the Freshwater Atlas. `swe_max` is capped at 3,000 mm, so glaciers are not represented as they stand.
- **Candidates for a1–a3:**
  1. the population mean (the null, and what a model with no covariates gives a new site);
  2. a regression on traits;
  3. `wet_donor_mean()`, the k nearest stations in trait space;
  4. network kriging: traits as fixed effects plus tail-down covariance on the stream network (SSN2), once the province network is checked (the open network check on the fwapg fork). Candidates 1–3 do not wait on it.
- **Run:** open-loop air2stream with the predicted parameters on the station's own daily air from cd.
- **Scores:** daily RMSE and GSDD absolute error per station-year, against the same model with the station's own parameters (the benchmark).
- **Pools:** blocked CV, and a leak-free pool that removes each held-out station's upstream and downstream neighbours, as the water balance does. Kriging is scored in both; the gap between them is what neighbours on the same stream are worth.
- **Recovery first:** before any real score, simulate stations with known trait-to-parameter relationships plus a network-correlated part, and check that each candidate recovers them and that the leak-free pool removes what it claims to.
- **Rule fixed in the script header before any real score:** which candidate is reported as the baseline, and what gap to the own-parameter benchmark counts as close.

## Out of scope

- Small-stream logger series (#215; a second pool once they are in wet).
- Air temperature at every segment (#216).
- A joint network model of the weekly or daily series (this is the baseline one is scored against; what goes to it and comes back is #217).
- A review of the baseline against Bayesian practice (*Statistical Rethinking*, *Bayesian Data Analysis*): a follow-up once this has run, reading what was built (#218).

## Acceptance

- The recovery run logged, with bias and interval coverage per candidate, before the first real score.
- A check report under `data/checks/` and a section in `research/station_temperature_fill.md` with the scores by candidate and pool, broken down by sub-drainage and by lake and glacier influence.
- The rule's outcome stated as the rule wrote it.

Relates to #214

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `not in HYDAT 20260717: 07FA008` stopped the first traits run | A station newer than the pinned release has no gross area to snap against: dropped with that reason, not a stop |
| `tb_verdict()$text` carried names from `vapply()`, so `expect_equal()` failed | `USE.NAMES = FALSE` |

## The frame (2026-11-25)

- 257 truth stations, 999 station-years; kept 209 and 889 (frame `bd5db3bd6b`).
- Dropped 48: 18 with too little record to fit (under 365 observed days), 19 not snapped (14
  outside the 10 % area test, among them lake and reservoir level gauges, diversions and small
  creeks; 5 with no gross area in HYDAT), 9 with under 95 % of the basin inside BC, the stuck
  sensor (08LG048) and one station outside the pinned HYDAT (07FA008). The report lists each.
- Kept stations: 136 natural, 67 regulated, 6 unflagged; 135 headwater, 74 nested; 32 lake
  outlets; 96 with a glacier upstream.
- 640 related pairs, 461 of them across folds: blocked CV by sub-sub-drainage leaves those in
  training, and only the leak-free pool removes them. 97 stations have at least one.
- The lake query (386,025 lakes and 1,812 manmade waterbodies against the fundamental
  watersheds) took about 4 minutes on the local database; cached as `lake_ws_37795e2f7b.rds`.

## The recovery run (2026-11-25)

**First run (log `data/logs/213/recover_20261125T1903*`), part 1 sound, part 2 mis-simulated.**

- Part 1 (200 parameter sets, 43 s): bias under 0.04 of a unit everywhere; the regression's
  held-out RMSE sits on the floor (1.283 against 1.246 for eq0); every candidate's 90 %
  interval covers 0.895 to 0.903; the leak-free check passes (largest |z| 1.4), and in blocked
  CV the donor mean shows the leak (z −3.1, −2.3, −3.5), the mean and the regression none.
- Part 2 (5 end-to-end sets, 10 min) gave nonsense sizes: refitted eq0 RMSE 342 against a
  simulated spread of 1.76, and the regression's GSDD error 1,403 °C-days with a range to
  3,982. Cause, measured from the frame's fits: the simulated departure used each station's
  fitted `rho` and `sigma`, and at the 19 stations with `rho` at or above 0.99 that implies a
  stationary standard deviation up to 17.8 °C (median 1.2), where the real departure's is
  `rmse_open`, at most 3.1 °C. The refit of such a series sends `a3` toward 0 and `a1 / a3` to
  the hundreds, and one such station moves a mean or a regression. The real fits have no such
  station (eq0 from −2.2 to 7.5).
- Fix: the simulated departure keeps the station's `rho` and takes its observed spread
  (`rmse_open`). What stays true and is worth saying: theta = `a1 / a3` is fragile wherever
  `a3` is poorly identified, so a candidate's training set has to be checked for it; the real
  frame passes.
- Also seen: at the real fits eq0 and eq1 are correlated −0.49. The simulation draws the three
  components independently, so its GSDD errors overstate real ones; part 2 tests the path.

**Second run (log `data/logs/213/recover_20261125T1915*`), the one committed.** Part 1 is
unchanged (same seed, same code). Part 2: refitted theta is within 0.18 (eq0), 0.016 (eq1) and
0.07 (rate) of the simulated value at the median station, a tenth of the simulated spread; GSDD
mean absolute error 120 °C-days for the run on the simulated parameters (the departure alone),
93 for the refit, 413 for the regression, 471 to 481 for the donor mean and 598 for the
population mean, in the order the simulation built in. Pools differ by 1 for the regression and
10 for the donor mean.
