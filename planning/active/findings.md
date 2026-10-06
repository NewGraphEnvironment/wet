# Findings — Water temperature at hydrometric stations from water-temp-bc (#36)

## Issue context

**If we do it:** water temperature at ~300 BC hydrometric stations comes through the same path as flow, so `wet_window_stats()` and cd give per-window departure and trend for temperature in the same Chinook windows. **If we never do:** each report pulls temperature with water-temp-bc's sourced `query_canonical()` helper and computes its own statistics, and flow and temperature for the same window cannot be compared side by side.

## Problem

wet reads only discharge from water-temp-bc (`Parameter=6`, in `wet_station_daily()`). Water temperature (`Parameter=5`, 306 stations, sub-daily readings from 2002) is in the same public archive and nothing in the package reads it. The downstream half already exists: `wet_window_stats()` has an absolute-anomaly mode meant for temperature, and its output is in cd's long format.

## Proposed Solution

Start a `wet_temp_*` family with one function:

- `wet_temp_daily(stations, from, to)`: reads `Parameter=5` from water-temp-bc and reduces the sub-daily readings to daily mean, min and max (°C), with the reading count per day and the approval status. It returns the same shape as `wet_station_daily()`, so it feeds `wet_window_stats(value = "t_mean_c", level_anomaly = "absolute")` and then `cd_baseline()`, `cd_anomaly()` and `cd_trend()` unchanged.

Decisions, from the archive as measured 2026-10-03 (`canonical/Parameter=5/`: 17.4 M readings, 306 stations, 2002-04-30 to 2026-10-01):

- **One read path.** `canonical/Parameter=5/` alone reaches 2002, so `historic/` is not needed (water-temp-bc#19 is closed). Same duckdb read as the provisional flows. The CLAUDE.md line describing the split is updated with this work.
- **A day counts when readings fall in at least 20 of its 24 hours.** Cadence is hourly (median 24 readings a day, 10th percentile 24), and 98 % of the 643,440 station-days pass. Short days are dropped, not filled, and `n_hours` is returned so a caller can be stricter.
- **Baseline 2016–2025 by default, stated, never 1981–2010.** Stations with at least 300 days in at least 8 of 10 years: 0 for 2003–2012, 32 for 2011–2020, 64 for 2014–2023, 79 for 2016–2025. Year-round coverage is thin before 2011 (27 stations that year, 269 in 2025), so a temperature departure is against the recent decade, and output and prose must say so beside any flow departure on 1981–2010. Open-water windows clear the bar at more stations than whole years do, because many loggers are seasonal.
- **Absolute departure in °C** (`level_anomaly = "absolute"`), not percent of normal.

Later members, each its own issue: modelled stream temperature as a yardstick (PCIC VIC-GL-dynWat, coast only, per reach), then our own per-segment estimate.

Relates to #25

## Probe 2026-10-06 (read-only duckdb on S3)

See task_plan.md, "What the probe found". Probe scripts were scratch; `scripts/temp_coverage.R` (Phase 2) is the reproducible version.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| duckdb parser error on alias `day` | reserved word; alias `dd` |
| `Binder Error: No function matches '+(DOUBLE, DOUBLE)'` (empty candidates), then segfaults, intermittent | duckdb 1.5.2 across instances in one session; integer `epoch_ms()` arithmetic |
| An edit slice dropped the `sprintf()` arguments ("too few arguments") | restored the argument lines |
