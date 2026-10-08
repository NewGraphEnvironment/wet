# Gap-filled water temperature at stations, and GSDD

**Verified:** 2026-10-07 · **Issues:** #40 (from #36; air from cd#116's `cd_extract_daily()`; the method's model is NewGraphEnvironment/knowledge `research/stream_temperature.md`) · **Produced by:** `scripts/temp_fill_validate.R` → `data/checks/temp_fill_validate.txt`, `scripts/temp_fill_parity.R` → `data/checks/temp_fill_skeena_parity.txt`; water from `wet_temp_daily()` 2002–2025 (water-temp-bc `canonical/Parameter=5/` as read 2026-10-07), air from cd 0.6.1's daily cube; gsdd 0.3.0.9007; design spikes and the pre-registered rule in `planning/archive/2026-10-issue-40-*/findings.md`

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
- cd's daily cube does not reach the 60 °N its message names: 10DA001, at 59.989 °N, is "outside". The scripts drop the stations cd names.

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
  - **2024: +191, above their interval.** 95 % of our 2024 days are observed. Their GSDD comes from model estimates even on observed weeks (`predict()` in `predict-air2stream-gsdd.R`), so this one is **theirs**: their model runs below the 2024 observations.
  - **2023: −93, below their interval.** 79 % observed, so mostly theirs again, but **unresolved** for the filled fifth.
  - **2019: +80; 2015: −77.** Both are inside their intervals. 2015 is 86 % filled at these stations, so it compares our fill with their model: **unresolved**.
  - C → D also carries their air (ERA5-Land hourly to weekly) and their observation snapshot (`realtime_raw_20250521`), which this does not separate.

## Using it

- **Seasonal loggers** need `from` and `to` over the growing season, such as `from = "YYYY-03-01"`, `to = "YYYY-11-30"`. Shoulder fills are anchored on one side only. That is the `shoulders` holdout: 0.84 °C, with GSDD within 64 °C-days on average.
- **A whole missing season** is better left to open-loop for GSDD: the fill is no better there.
- `wet_temp_gsdd()` uses gsdd's defaults: Mar–Nov, 5/4 °C, a 7-day mean, and `complete = TRUE` inside `gsdd::gsdd()`. A season cut by a missing day is NA.

## Not done

- No hierarchical fit: each station is alone, and a sparse one is fitted only from 365 observed days.
- No seasonal hysteresis term. The monthly bias above is small enough not to need one at the gauges.
- Validation is at ECCC gauges only; no logger series was held out.
- The interval has no parameter uncertainty.
