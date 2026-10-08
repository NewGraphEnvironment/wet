# Task: Daily water temperature with gaps filled at stations: wet_temp_fill() (#40)

`wet_temp_daily()` drops days that are short of readings and fills nothing. Station records have outages and seasonal deployments, so many station-years have no complete growing season. `gsdd::gsdd()` works on the longest run of days with no missing value. When a gap cuts a growing season, it returns NA by default, and with `ignore_truncation` it returns a value that is likely too low. Without a fill, those station-years have no usable GSDD.

## Context

`wet_temp_daily()` drops short days and fills nothing. Outages and seasonal loggers leave many station-years without a complete growing season, so `gsdd::gsdd()` returns NA, or a value that is too low when truncation is ignored. #40 adds a per-station air2stream fill that uses the station's own observations and the anomaly its peers observed that day, plus GSDD per station-year in wet's long format.

What exploration changed relative to the issue body:
- **cd#116 is closed.** `cd_extract_daily()` ships in cd 0.6.1 (this machine has 0.5.8). It returns `id, date, variable (tmean/tmax/tmin), value, cell, …` on local days at a fixed UTC−8. `wet_temp_daily()` uses per-station offsets, so the 27 UTC−7 stations are an hour apart. That offset gets documented, not corrected (cd#37 Option A).
- **`wet_cv_folds()` blocks by station on the FWA network. It cannot hold out seasons.** Validation gets its own station-season holdout instead, and the issue body is edited to say so.
- **gsdd** (poissonconsulting, MIT, 0.3.0.9007) is not on CRAN, so it goes in `Suggests` + `Remotes:`. Input is `data.frame(date, temperature)`. Its defaults are a Mar 1 – Nov 30 window, 5/4 °C and a 7-day rolling mean, and it uses the longest run with no missing value.
- **Parity numbers exist as tables** in the rendered Skeena memo: Table 8 has the mean GSDD by site for 17 sites (08EE020 1029 … 08EC004 2639), and Table 7 the mean by year for 2015–2024 (1815–2233). Their GSDD holds each day at its weekly mean and uses `gsdd_vctr(complete = TRUE)` (`skeena-stream-temp-25/predict-air2stream-gsdd.R`).

Decisions taken at the gate (user): **Kalman smoother** as the gap engine, and the **anomaly pool = the other stations in the call**, each station scaled by its own fitted coefficient.

## Method (what `wet_temp_fill()` does)

> **Revised 2026-10-07 after the 08E spike (findings.md):** the single Kalman state on the air2stream recursion tied open-loop on whole seasons. Shipped form is `W = S + u`: open-loop air2stream `S` fitted by least squares, plus an AR(1) departure `u` (ρ, b, σ) in the Kalman smoother. The bullets below describe the original form; peers, pool, smoother, interval and floor carry over.

- State-space form of the 3-parameter air2stream: `W_t = W_{t-1} + a1 + a2·A_t − a3·W_{t-1} + b·ē_t + ε_t`, where `ε ~ N(0, σ²)`. A day with an observation sets the state to that value, with a small observation noise. `ē_t` is the leave-self-out mean one-step innovation of the other stations observed on days t−1 and t. `b` is fitted per station (0 means it does not track its peers).
- Fit per station with base `optim()` on the Kalman likelihood (a1, a2, a3, b, log σ). Then a forward filter and an RTS backward smoother over the fill range. The smoother uses both edges of a gap, so there is no jump where the gap ends. The interval is `t_mean_c ± 1.96·sd` from the smoothed variance.
- Prediction is floored at 0 °C (ice), in the predict step and on the output.
- The minimum-data rule: a station needs `min_days` (default 365) observed days that also have air temperature. Below that, its days are returned unfilled with a warning.
- Fill range per station: from its first to its last observed day by default. `from`/`to` can extend it where air temperature exists.
- Output: the columns of `wet_temp_daily()` plus `filled` (logical), `t_lo_c` and `t_hi_c`. Filled days have NA `t_min_c`/`t_max_c`, `n_hours = 0L` and `source = "air2stream"`. Observed days pass through unchanged, with the interval equal to the value. The fitted parameters per station go in `attr(, "fit")`.
- `air`: `cd_extract_daily()`'s output as is, using the `tmean` rows, with `id` matched to `station_number`.

## Phase 1: Dependencies and fixture
- [x] `gsdd` in Suggests, `poissonconsulting/gsdd` in `Remotes:`. Install cd 0.6.1 and gsdd locally
- [x] Test helper `helper-temp-fill.R`: synthetic stations, with seasonal air plus a shared daily weather anomaly, water simulated from known air2stream parameters, and a peer that does not track (b = 0)

## Phase 2: `wet_temp_fill()` (tests first)
- [x] `tests/testthat/test-wet_temp_fill.R`:
  - observed days unchanged
  - known parameters recovered on synthetic data
  - no jump at a gap's far edge
  - the 95 % interval covers about 95 % of the hidden truth and is widest mid-gap
  - the shared anomaly lowers gap RMSE against the same fit with b = 0
  - a non-tracking peer gets b ≈ 0
  - the min-data rule warns and leaves days unfilled
  - air missing on some days
  - floor at 0
  - input validation
  - takes `cd_extract_daily()`-shaped `air` directly
  - a single station (no peers) still fills
- [x] `R/wet_temp_fill.R` with roxygen: method, day-boundary note (UTC−8 air vs per-station water) and a runnable example on a small simulated series
- [x] `devtools::document()`, `lintr`, tests green; `/code-check`; commit

## Phase 3: `wet_temp_gsdd()`
- [x] Tests: wraps `gsdd::gsdd()` per station-year into cd's long format (`station_number, variable = "gsdd", period = "growing_season", year, value, anomaly_type = "absolute", unit = "degC"`, matching `wet_window_stats()`). A station-year whose season is cut by a gap gives NA, not a low value. Extra arguments pass through to `gsdd::gsdd()`
- [x] `R/wet_temp_gsdd.R` with a runnable example. Tests green; `/code-check`; commit

## Phase 4: Validation, `scripts/temp_fill_validate.R`
- [x] Truth set: station-years whose Mar 1 – Nov 30 is fully observed, with gaps of ≤ 2 days interpolated for the truth GSDD only
- [x] Holdouts, each with the station refitted without the held days and its peers left in (pool = WSC sub-drainage, the first 3 characters of the station number):
  - (a) the whole Mar–Nov season
  - (b) a 30-day mid-summer gap, Jul 1–30
- [x] Methods scored: the full fill; the smoother with b = 0; and open-loop air2stream (parameters fitted by open-loop RMSE, run on air alone), the issue's baseline
- [x] Report `data/checks/temp_fill_validate.txt`: daily RMSE (°C) and GSDD error (median, MAE, bias) per method and holdout, and station counts. Parallel on socket workers (`parLapply`, not `mclapply`). Commit the script and report

## Phase 5: Skeena parity, `scripts/temp_fill_parity.R`
- [x] The 17 memo stations, 2015–2024. Water from `wet_temp_daily()`, air from `cd_extract_daily()` at the `tidyhydat::allstations` coordinates
- [x] Memo Tables 7 and 8 transcribed into the script, with URL and access date
- [x] Attribution in steps:
  - our daily GSDD
  - our fill, held at its weekly mean, through `gsdd_vctr(complete = TRUE)`: their GSDD rule applied to our fill
  - theirs

  The difference between the first two is the daily-vs-weekly step. The difference between the last two is the model: a per-station fit that uses observations, against a weekly Stan network with an open-loop fill. Each is attributed ours / theirs / unresolved.
- [x] Report `data/checks/temp_fill_skeena_parity.txt`; commit

## Phase 6: Documentation and close-out
- [x] `research/station_temperature_fill.md` (method, validation and parity numbers, limits), with a row in `research/README.md`. Update the "Not yet done" list in `station_water_temperature.md`
- [x] CLAUDE.md architecture: a line on the fill → GSDD path; NEWS.md entry (NEWS is written by `/gh-pr-merge` at release, as for every release since v0.2.2)
- [ ] Edit the #40 body: cd#116 is done, season holdout replaces `wet_cv_folds()`, Kalman smoother engine, outcomes
- [ ] `pkgdown::check_pkgdown()`, `devtools::check()`

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Verification

- `Rscript -e 'devtools::test()'`: the synthetic tests pin parameter recovery, interval coverage, bridging, and the gain from the anomaly.
- `Rscript scripts/temp_fill_validate.R`: the full fill should beat open-loop on both holdouts. If it does not, that is reported, not tuned away.
- `Rscript scripts/temp_fill_parity.R`: every difference from the memo is attributed.
- Both scripts need S3 access (water-temp-bc, the cd daily cube) and cd ≥ 0.6.1.

Critical files: `R/wet_temp_fill.R`, `R/wet_temp_gsdd.R` (new); `R/wet_temp_daily.R` (shape reference only); `DESCRIPTION`; `scripts/temp_fill_validate.R`, `scripts/temp_fill_parity.R` (new); `research/`.
