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
