# Gap-filled water temperature at stations, and GSDD

**Verified:** 2026-10-07 (the fill and the Skeena parity), 2026-11-25 (stations with no record) · **Issues:** #40, #213 (from #36; air from cd#116's `cd_extract_daily()`; the method's model is NewGraphEnvironment/knowledge `research/stream_temperature.md`) · **Produced by:** `scripts/temp_fill_validate.R` → `data/checks/temp_fill_validate.txt`, `scripts/temp_fill_parity.R` → `data/checks/temp_fill_skeena_parity.txt`; water from `wet_temp_daily()` 2002–2025 (water-temp-bc `canonical/Parameter=5/` as read 2026-10-07), air from cd 0.6.1's daily cube; gsdd 0.3.0.9007; design spikes and the pre-registered rule in `planning/archive/2026-10-issue-40-*/findings.md`; the whole-station holdout from `scripts/temp_baseline_traits.R` → `data/checks/temp_baseline_frame.txt`, `scripts/temp_baseline_recover.R` → `data/checks/temp_baseline_recover.txt` and `scripts/temp_baseline.R` → `data/checks/temp_baseline.txt`, its rule in that script's header (registered at 914259d6) and its runs in `planning/archive/2026-11-issue-213-*/`

## The method

`wet_temp_fill()` writes daily mean water temperature as `W = S + u`.

- **`S` is air2stream run open-loop.** It uses the three-parameter form, ΔS = a1 + a2·A − a3·S, on daily air temperature, floored at 0 °C. It is fitted per station by least squares over the observed days, which is how air2stream is calibrated. On a long gap the fill falls back to `S`.
- **`u` is the departure from `S`.** It is an AR(1) process, u_t = ρ·u_{t−1} + b·ē_t + ε, run through a Kalman filter and RTS smoother.
  - Every observed day pins `u`, so the fill restarts from each observation.
  - The smoother also uses the observation at the far end of a gap, so the fill meets it without a jump.
  - The interval is the smoothed variance. It is narrow beside observations and widest mid-gap.
- **ē_t is the mean one-step departure error of the other stations in the same pool,** taken from a first fit with b = 0 and clipped at 4σ. `b` is fitted once at least 180 of the station's observed days have a peer error.
  - The recommended pool is the WSC sub-drainage (`substr(station_number, 1, 3)`).
  - The Skeena network model's shared weekly term was still correlated at about 0.9 over 300 km, so a basin-sized pool fits.

**Why `S + u` and not one recursion.** The first form, as planned, put the air2stream recursion itself in the Kalman state and fitted it by its one-step likelihood. That likelihood rewards persistence: a3 came out at 0.02–0.13, so the recursion drifted over a long gap. At the 18 08E stations with at least 1000 days, it only tied open-loop on a whole missing season (RMSE 1.28 vs 1.27 °C). Without peers it lost (1.69). Splitting `S`, fitted to the level, from `u`, fitted to persistence, gave 0.99 on the same holdouts. Both runs are in the archive's findings. The plan review had predicted this.

**Guards found on real data:**
- A station reading a constant 4.0 °C (08LG048, 2024–2025, likely a stuck sensor) fitted σ ≈ 10⁻²¹⁶, and the smoother divided 0 by 0. Now ρ ≤ 0.999 and σ ≥ 0.01 °C.
- An air series with a hole longer than 3 days that overlaps a station's calendar leaves the station unfilled, with a warning.
- cd's daily cube stops at 59.95 °N, not the 60 °N its message names: the build drops the 60.0 °N row. So 10DA001 (Petitot River, 59.989 °N) is "outside", and one such point aborts the whole call. The scripts drop the stations cd names and retry (NewGraphEnvironment/cd#123).

## Held-out skill at the stations

**Truth set:** 999 station-years at 257 stations in which 1 Mar – 30 Nov is observed, with no gap longer than 2 days. These are year-round ECCC gauges, mostly rivers, not seasonal creek loggers.

**Holdouts.** Each truth station-year was hidden in four shapes, one at a time, with its sub-drainage peers left in:
- the whole season;
- the shoulders (1 Mar – 15 May and 1 Oct – 30 Nov), which is what a seasonal logger misses;
- 30 days in July;
- 7 days in July.

The station was refitted without the hidden days. 3,763 holdouts were scored, with no errors. Daily RMSE is on observed hidden days only. GSDD is `wet_temp_gsdd()` on the year with the fill in place, against the observed year.

**Methods compared:**
- `open`: S alone, the issue's baseline;
- `forward`: S plus the departure carried forward, b = 0;
- `smooth`: both ends of the gap, b = 0;
- `full`: `wet_temp_fill()`;
- `linear`: a straight line across the gap.

| holdout | open | forward | smooth | full | linear | full 95 % coverage | GSDD MAE open → full (°C-days) |
|---|---|---|---|---|---|---|---|
| season (897) | 1.29 | 1.30 | 1.29 | **1.12** | — | 0.93 | 129 → 130 |
| shoulders (912) | 1.14 | 1.11 | 1.00 | **0.84** | — | 0.94 | 82 → 64 |
| 30 days (977) | 1.43 | 1.09 | 0.90 | **0.76** | 1.19 | 0.91 | 33 → 13 |
| 7 days (977) | 1.31 | 0.72 | 0.55 | **0.48** | 0.64 | 0.89 | 8.2 → 2.2 |

Mean daily RMSE is in °C. Each step adds something: the smoother on short gaps, and the peers on every shape. Open-loop runs cold in July and August (−0.59 and −0.34 °C); the fill takes that to −0.20 and −0.09.

**The pre-registered rule fails on whole seasons.** The rule, fixed before the first run, needed three things on the season holdout:
1. the median paired RMSE difference below 0: it is −0.17 °C, a pass;
2. full better in at least 60 % of station-years: it is 83 %, a pass;
3. a lower GSDD mean absolute error: 130.4 against open's 128.7 °C-days, a **fail**.

So, as the rule says: **for a whole missing season, the fill is closer day by day but its GSDD is no better than open-loop air2stream.** It ships for the short gaps and shoulders, where it wins on every measure. The GSDD loss is concentrated in the Peace (07E, 07F) and in 08F, 08G, 08L and 09A; in nine of the other ten sub-drainages the fill's GSDD is better, and in 10A (one station, no peers) equal.

**The first run said PASS, and was wrong.** Its GSDD came from `gsdd_vctr()` with `complete = FALSE`, while `gsdd::gsdd()`, and so `wet_temp_gsdd()`, uses `complete = TRUE`. That made the truth NA at 403 of 897 station-years, all of them seasons still above 4 °C at the end of November. Its "paired" GSDD means also averaged different station-years. Code-check round 5 found both. The script now computes GSDD with `wet_temp_gsdd()` itself and pairs the means. Nothing else changed between the two runs except robustness fixes to the fit's starting values and the ρ/σ caps. Those moved the season RMSE of `full` from 1.09 to 1.12 °C.

**Intervals.** Coverage is 0.89–0.94 against a nominal 0.95. The interval is plug-in (no parameter uncertainty) and per day, so summing `t_lo_c` or `t_hi_c` does not bound GSDD.

**Peers.** A fitted peer in the same sub-sub-drainage observed that year is a proxy for one on the same stem. With one, 7-day RMSE is 0.48; without, 0.52. The gain from peers is not mainly from same-stem neighbours.

## GSDD against the Skeena network model

`hill_etal2025Spatialstream`: 17 stations, 2015–2024, a weekly Stan network model whose GSDD holds each day at its week's predicted mean and runs `gsdd_vctr(complete = TRUE)` on each calendar year. The comparison runs in steps that change one thing at a time:
- A: ours, `wet_temp_gsdd()` over Mar–Nov;
- B: ours under their rule;
- C: ours held at weekly means;
- D: theirs.

Of the days in the Mar–Nov windows, 36 % are filled.

- **By site:** all 17 of our site means (C) lie in their 95 % intervals. The correlation is 0.997 and the mean |C − D| is 23 °C-days.
  - The GSDD rule moves the values +10 (A → B) and the weekly step −0.3 (B → C).
  - Neither the window nor the time step explains a difference; what is left is the models.
- **By year:** within ±40 °C-days in 2016–2018 and 2020–2022. Larger in four years:
  - **2024: +191, above their interval.** 95 % of our 2024 days are observed. Their GSDD comes from model estimates on every week, observed ones included (`predict()` in `predict-air2stream-gsdd.R`), so the difference is between those estimates and the 2024 observations, not between the two fills.
  - **2023: −93, below their interval.** 79 % observed, so mostly the same comparison of estimates with observations, and **unresolved** for the filled fifth.
  - **2019: +80; 2015: −77.** Both are inside their intervals. 2015 is 86 % filled at these stations, so it compares our fill with their model: **unresolved**.
  - C → D also carries their air (ERA5-Land hourly to weekly) and their observation snapshot (`realtime_raw_20250521`), which this does not separate.

## A station with no record: a whole station held out

**Verified:** 2026-11-25 · **Issue:** #213 · HYDAT 2026-07-17, province run `768876badf`, frame `1c62e46b83`

**The answer.** Hide a station's whole record, predict its three air2stream parameters from its catchment, and run the model on its own air temperature. The best of three predictions misses a growing season's degree days by about 295 °C-days. With the station's own parameters the miss is 97, and with every station given the population's mean parameters it is 413. Each figure is the mean, over 209 held-out stations, of the station's mean absolute GSDD error over its complete seasons. Catchment traits recover about a third of what a record gives, and the gap that is left, about 200 °C-days, is twice the width of the band the cutthroat thresholds turn on (800 to 900 degree days). A per-reach estimate from traits alone cannot place a reach on one side of that band.

**What was held out.** The 257 stations and 999 station-years of the fill's validation, less 48 stations:
- 18 with fewer than 365 observed days, which `wet_temp_fill()` does not fit;
- 19 that do not snap to the Freshwater Atlas within 10 % of their gross drainage area, or have none (lake and reservoir level gauges, diversions, small creeks);
- 9 with less than 95 % of the basin inside BC, where the trait grids end;
- 08LG048, whose sensor reads 4.0 °C on all 586 days;
- 07FA008, a 2024 station not in the pinned HYDAT release.

That leaves 209 stations and 889 station-years: 136 natural, 67 regulated and 6 unflagged in HYDAT; 135 headwater and 74 nested; 32 lake outlets; 96 with a glacier upstream.

**What is predicted.** Not `a1`, `a2`, `a3` themselves but the equilibrium intercept `a1 / a3`, the equilibrium slope `a2 / a3` and the response rate `a3` on the logit scale, turned back before the run. Three candidates:
- the population mean, which is what a model with no covariates gives a new site;
- a least-squares regression on eight traits: upstream means of elevation, easting, northing, the date half the snow has melted and peak snow water equivalent; log upstream area; and glacier cover and lake and reservoir cover as shares of upstream area;
- the inverse-distance mean of the 5 nearest stations in trait space (`wet_donor_mean()`), called the nearest-stations mean below.

**Two pools.** In blocked cross-validation the stations of one WSC sub-sub-drainage are held out together. The leak-free pool also removes every station upstream or downstream of the held-out one, 461 pairs that blocked cross-validation leaves in training, at 97 of the stations.

**The rule, fixed before any score** (header of `scripts/temp_baseline.R`; thresholds the owner's). The population mean is the baseline unless a trait candidate beats it by at least 10 °C-days in both pools. The baseline is close to the own-parameter benchmark when within 50 °C-days of it in both pools, half the width of the cutthroat band.

| | GSDD error, blocked | GSDD error, leak-free | daily RMSE, blocked | daily RMSE, leak-free |
|---|---|---|---|---|
| own parameters (the benchmark) | 97.5 | | 1.25 | |
| population mean | 412.8 | 414.1 | 2.38 | 2.39 |
| regression on traits | **293.9** | **298.0** | 1.94 | 1.96 |
| nearest-stations mean | 308.2 | 319.7 | 1.94 | 2.07 |

GSDD error is the mean over stations of each station's mean absolute error, in °C-days; daily RMSE is the mean over station-years, in °C, on the observed days of 1 March to 30 November.

**The rule's outcome, as it wrote it.** Baseline: regression. It beats the population mean by 118.9 °C-days in blocked cross-validation and 116.2 leak-free, and the nearest-stations mean beats it by 104.6 and 94.4, so both displace it; the regression has the lower leak-free score. The gap from the regression to the benchmark is 196.4 °C-days blocked and 200.5 leak-free, about twice the benchmark's own error: **not close**.

**What the scores show.**
- **The traits carry about a third of the signal.** Held out, the regression explains 30 % of the variance in the equilibrium intercept, 33 % in the slope and 19 % in the response rate (leak-free). The population mean also runs cold, by 118 to 122 °C-days on average; the regression's mean error is within 8.
- **Neighbours on the same stream help the nearest-stations mean more than the regression.** Removing them costs the nearest-stations mean 11.5 °C-days and the regression 4.1. That is what neighbours are worth to these two candidates. What a model built to use the network adds is #223's question.
- **Lake outlets are where traits fail.** At the 32 lake outlets the regression misses by 408 °C-days leak-free, against 278 elsewhere; the benchmark is the same at both (102 and 97). Lake cover as a share of the basin does not capture a lake at the gauge.
- **Regulated stations are worse** (376 against 260 at natural ones), with the same benchmark at both (96 and 99).
- **Glacier-fed stations are not worse.** With a glacier upstream the regression misses by 267, and by 324 without. The benchmark is worse there (111 against 86).
- **By sub-drainage** the regression's leak-free error runs from 159 (08O, 3 stations) to 398 (08J, 9). In 07F (7 stations) and 08G (16) it loses to the population mean: 344 against 145, and 326 against 291.

**Beside the hidden-season score above.** On the 822 station-years both score, the station's own parameters miss GSDD by 119 °C-days when fitted to the whole record and by 130 when that season is hidden (means over station-years). So the benchmark here is in-sample by about 11 °C-days.

**Recovery, run first** (`data/checks/temp_baseline_recover.txt`). On the real traits, folds and network, parameters were simulated from known trait relationships plus a part shared between flow-connected stations plus noise, 1,600 times.
- The regression is unbiased and its error reaches the floor the simulation set (1.286 against 1.246 for the intercept, leak-free). In the leak-free pool the nearest-stations mean is biased by 2 to 5 % of each parameter's spread (0.5 to 4 % in blocked cross-validation), and the population mean by under 1 % in both. Each candidate's 90 % interval holds the simulated value 89.6 to 90.2 % of the time.
- Replacing only the held-out station's network part changes no candidate's leak-free error (largest |z| 1.0, in Monte Carlo standard errors). The same test on three pools known to leak shows the nearest-stations mean using its neighbours: blocked cross-validation, where the related stations of other folds stay in training (z −7.8 to −8.5), a pool that removes only upstream neighbours (−4.1 to −4.7) and one that removes only downstream ones (−5.0 to −5.8). So the check can fail, on a half-broken pool too, and in the leak-free pool it does not. It rests on the nearest-stations mean: the regression shows the blocked leak only faintly (−1.5 to −3.0) and the population mean not at all.
- End to end on five simulated sets, through the fit and the GSDD scoring, the refit returns the simulated parameters to about a tenth of their spread at the median station.
- The first end-to-end run was wrong, and instructive. It drew each station's departure from its fitted `rho` and `sigma`, which at the 19 stations with `rho` at or above 0.99 implies a departure of up to 17.8 °C where the observed one is at most 3.1. Refitting such a series sends `a3` toward 0 and `a1 / a3` into the hundreds, and one such station ruins a mean or a regression. The simulation now gives the departure its observed spread. The real fits hold no such station (intercepts from −2.2 to 7.5 °C), but the ratio is fragile wherever `a3` is poorly identified, and any wider pool has to be checked for it.

**On the real fits each candidate's interval holds the station's own parameters** 87 to 94 % of the time at a nominal 90 %. The intervals stop at the parameters: none is carried to daily temperature or GSDD.

**Limits.**
- The stations are gauges, mostly rivers, and the 48 dropped are not a random draw: lake-level gauges, small creeks and transboundary rivers are under-represented.
- The simulation tests the path, not the size: it draws the three parameters independently, though at the real fits the intercept and slope offset each other (correlation −0.49).
- Kriging on the stream network, the candidate that would use neighbours on purpose, is scored on this frame under this rule in #223. The scores it is set beside are in `data/temp_baseline/scores_1c62e46b83.rds`.

## Using it

- **Seasonal loggers** need `from` and `to` over the growing season, such as `from = "YYYY-03-01"`, `to = "YYYY-11-30"`. Shoulder fills are anchored on one side only. That is the `shoulders` holdout: 0.84 °C, with GSDD within 64 °C-days on average.
- **A whole missing season** is better left to open-loop for GSDD: the fill is no better there.
- `wet_temp_gsdd()` uses gsdd's defaults: Mar–Nov, 5/4 °C, a 7-day mean, and `complete = TRUE` inside `gsdd::gsdd()`. A season cut by a missing day is NA.

## Not done

- No hierarchical fit: each station is alone, and a sparse one is fitted only from 365 observed days.
- No seasonal hysteresis term. The monthly bias above is small enough not to need one at the gauges.
- Validation is at ECCC gauges only; no logger series was held out.
- The interval has no parameter uncertainty.
- At a station with no record: no network model (#223), no interval on GSDD, and no small-stream loggers in the holdout (#215).
