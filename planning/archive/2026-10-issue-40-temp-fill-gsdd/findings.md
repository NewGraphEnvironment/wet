# Findings — Daily water temperature with gaps filled at stations: wet_temp_fill() (#40)

## Issue context

**If we do it:** a station's growing season becomes complete, so GSDD and window statistics work on records with gaps, seasonal loggers included. **If we never do:** a gap inside a growing season leaves that year's GSDD unknown, and each report fills gaps its own way.

## Problem

`wet_temp_daily()` drops days that are short of readings and fills nothing. Station records have outages and seasonal deployments, so many station-years have no complete growing season. `gsdd::gsdd()` works on the longest run of days with no missing value. When a gap cuts a growing season, it returns NA by default, and with `ignore_truncation` it returns a value that is likely too low. Without a fill, those station-years have no usable GSDD.

## Proposed solution

`wet_temp_fill(temp, air)`:

- **Input:** daily water temperature in the shape of `wet_temp_daily()`, from any source (loggers included), and daily air temperature at the same stations (NewGraphEnvironment/cd#116).
- **Model:** air2stream fitted per station at a **daily** step, in its three-parameter form: ΔW = a1 + a2·A − a3·W (Toffolon & Piccolroaz 2015). It uses base `optim()` and no Stan.
- **Using the data a station has:** the recursion restarts from each observed day instead of running from day 1 on air temperature alone. Each filled day also adds the anomaly that the stations observed that day share.
- **Output:** a daily series with a `filled` flag and an interval, in the shape of `wet_temp_daily()`.
- **GSDD** comes from [`gsdd`](https://github.com/poissonconsulting/gsdd) (MIT, Coleman & Fausch 2007 growing season): `gsdd::gsdd()` per station-year, plus a thin wrapper into wet's long format if needed. It goes under `Remotes:` because it is not on CRAN.

## Checks

- **Validation:** blocked CV with `wet_cv_folds()`, holding out whole seasons per station. Report daily RMSE (°C) and the GSDD error, against the open-loop fill (air temperature only) as the baseline.
- **Parity:** GSDD per station for the 17 Skeena stations, 2015–2024, against `hill_etal2025Spatialstream`. That model is weekly and network-based, so attribute any difference rather than expecting a match.

## Open choices

- Fit each station alone, or hierarchically so that sparse stations borrow strength. Start with each station alone, with a minimum-data rule.
- A daily step needs the hours-to-days convention to be the same as `wet_temp_daily()` and cd#116: local standard time.

Blocked on cd#116 for production. It can start with a fixture of air temperature.

Background: `knowledge/research/stream_temperature.md`.

Relates to #36


## Errors Encountered

| Error | Resolution |
|-------|------------|
| Validation stopped at the 2 h background limit with no output | Each held-out job re-filtered and de-duplicated the 2.6M-row air table (17 s of an 18 s prepare). Air is split per station in `wet_fill_prepare()` and each job gets its own station's rows: 1.3 s; the run takes 12 min |
| `cd_extract_daily()`: "Outside the daily cube's extent (BC, 48-60 N, …)" for 10DA001 at 59.989 N | The cube stops short of the 60 N its message names; the scripts drop the stations cd names and retry |
| Smoother NaN at 08LG048 | A constant 4.0 °C record fits σ ≈ 1e-216; ρ capped at 0.999 and σ floored at 0.01 °C, in the fit as reported and in the run |
| Truth GSDD NA at 403 of 897 station-years in the first run | The script called `gsdd_vctr()` with its default `complete = FALSE`; `gsdd::gsdd()` (and so `wet_temp_gsdd()`) passes `complete = TRUE`. The script now computes GSDD with `wet_temp_gsdd()` itself (code-check round 5) |

## Real-data spike, 08E (Skeena), 2026-10-07

Data: `wet_temp_daily()` for the 25 08E stations in `canonical/Parameter=5/`, 2011–2025 (3 s), and `cd_extract_daily()` tmean at the `tidyhydat::allstations` coordinates (36 s). The 18 stations with ≥ 1000 days were used. Holdouts: the most recent 30-day July gap and the most recent Mar–Nov season that was ≥ 98 % observed, one station at a time, with its peers left in. Cached as `data/temp_fill/spike_08E_{water,air}.rds`; scripts in the session scratchpad (method below is enough to redo it).

**Form 1, as planned:** one Kalman state on the air2stream recursion, fitted by its one-step likelihood.

| holdout | full | smoother, b = 0 | open-loop | 95 % coverage |
|---|---|---|---|---|
| 30-day July | 0.80 | 1.04 | 1.45 | 0.88 |
| Mar–Nov season | 1.28 | 1.69 | 1.27 | 0.84 |

(Mean daily RMSE over 18 stations, °C.) The one-step likelihood picks a3 = 0.02–0.13, so its own recursion drifts over a season: the full form only ties open-loop there, and without peers it loses to it. This is the plan review's G1, confirmed.

**Form 2, adopted:** `W = S + u`. `S` is open-loop air2stream fitted by least squares (as air2stream is calibrated); `u` is an AR(1) departure with the peer term, in the Kalman smoother.

| holdout | full | smoother, b = 0 | forward only, b = 0 | open-loop | 95 % coverage |
|---|---|---|---|---|---|
| 30-day July | 0.77 | 0.95 | 1.33 | 1.46 | 0.88 |
| Mar–Nov season | 0.99 | 1.25 | 1.26 | 1.28 | 0.93 |

The full fill is 23 % below open-loop on whole seasons and 47 % below on 30-day gaps. Each ingredient adds: the bridge (smoother over forward-only) on short gaps, the peers on both. ρ fits 0.84–0.99; b 0.13–1.64, lowest at the lake-outlet and coastal stations (08EG016, 08EG019, 08ED00x). Coverage is under nominal on the 30-day gaps (0.88): the interval is plug-in.

## Pre-registered validation rule (written before `scripts/temp_fill_validate.R` was first run)

Truth set, counted 2026-10-07 from `wet_temp_daily()` 2002–2025: **1006 station-years at 259 stations** whose 1 Mar – 30 Nov is observed with no gap over 2 days. Largest pools: 08N 177, 08H 153, 08L 123, 08M 84, 08E 77 station-years. These are year-round ECCC gauges, mostly rivers, not seasonal creek loggers; the report says so.

Holdouts per truth station-year, one at a time, peers (same WSC sub-drainage) left in: `season` (Mar 1–Nov 30), `shoulders` (Mar 1–May 15 and Oct 1–Nov 30), `gap30` (Jul 1–30), `gap7` (Jul 10–16). Methods: `open`, `forward` (b = 0), `smooth` (b = 0), `full`, and `linear` on the two July gaps. Daily RMSE on observed hidden days only; truth GSDD with 1–2 day gaps interpolated.

**Primary rule (season holdout, full vs open, paired by station-year):** `wet_temp_fill()` ships as the gap fill if
1. the median paired difference in daily RMSE (full − open) is below 0, and
2. full has the lower RMSE in at least 60 % of station-years, and
3. full's GSDD mean absolute error is below open's.

**On a fail:** it still ships, because the short-gap result is the main use; but the documentation and research file state that for a whole missing season the fill is no better than open-loop air2stream, and nothing is tuned after the result is seen.

**Reported, not ruled on:** the other three holdouts and the ladder; 95 % coverage of `full` by holdout (nominal 0.95; plug-in); monthly bias (seasonal hysteresis, G2); results split by whether a peer shares the sub-sub-drainage (a proxy for one on the same stem, V1); per-pool numbers.

Reviewed by: the plan review's O2 asked for this rule; no separate blind review was run (spend held to the code-check rounds).
