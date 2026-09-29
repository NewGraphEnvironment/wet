# Task: Flow in date windows at hydrometric stations: daily series, window metrics, departure via cd (#25)

## Problem

wet reads HYDAT only as long-term averages (`wet_station_select()`, `wet_station_monthly()`: complete years, long-term means). Nothing produces a per-year series at a station, and HYDAT lags. Measured 2026-09-28:

| source | 08EE013 Buck Creek at the mouth | 08EE003 Bulkley River nr Houston |
|---|---|---|
| local HYDAT (downloaded 2025-12-04) | 1973–2023; 30 of 1981–2010 | 1931–2024 with gaps; 18 of 1981–2010 |
| GeoMet approved daily mean | to 2025-03-02 | to 2025-03-04 |
| GeoMet real-time | 2026-08-29 onward (30 days) | same |
| water-temp-bc `canonical/`, daily discharge (Parameter 6) | 2024-10-10 → 2026-09-12 | same |
| water-temp-bc `historic/`, daily discharge | 2016-03 → 2025-07 | 2016-01 → 2025-07 |

water-temp-bc archives ECCC's provisional data every month, so it covers the period between approved HYDAT and the 30-day real-time feed. It also holds water temperature for both stations from 2017–2018.

## Phase 1: HYDAT daily series
- [ ] Extend `local_hydat()` with `FLOW_SYMBOL1..31` (a `B` stretch in winter and an `E` day), keeping existing tests green
- [ ] Tests first: `wet_station_daily(stations, hydat, sources = "hydat")` returns one row per station-day. Covers: days not in the month dropped (Feb 30), missing days absent rather than `NA`-padded, `symbol` carried, `source = "hydat"`, `status = "approved"`
- [ ] Implement the HYDAT reader, one SQL query over `DLY_FLOWS`, unpivoted in R, using `wet_hydat_connect()`
- [ ] Signature settled here: `wet_station_daily(stations, hydat = wet_hydat_path(), from = NULL, to = Sys.Date(), sources = c("hydat", "provisional", "realtime"))`, where `stations` is a character vector of station numbers

## Phase 2: provisional and real-time sources, joined
- [ ] Internal readers:
  - `wet_provisional_daily()`: duckdb over `s3://water-temp-bc/data/canonical/Parameter=6/`, filtered by station and date, with `Symbol` kept
  - `wet_realtime_daily()`: `tidyhydat::realtime_ws(parameters = 6)` for days after the archive's last date
- [ ] Tests with both readers mocked to `stop()` by default and re-mocked per test (code-check-r, "A fetcher's test helper must make the network fail"). They cover:
  - precedence on overlap: HYDAT > provisional > real-time
  - the UTC 08:00 → date conversion
  - a gap between sources reported with a `warning()` naming station and date range, not filled
  - a source that errors is skipped with a warning, and the rest returned
- [ ] A live test for 08EE013 with `skip_on_ci()` and `skip_if_not_installed("duckdb")`
- [ ] DESCRIPTION: duckdb to Suggests, with an `rlang`-free `requireNamespace` check and a clear message
- [ ] Output columns: `station_number, date, q_m3s, symbol, source, status`

## Phase 3: window statistics
- [ ] `wet_windows_calendar()`: months and seasons as a windows table (`window, start, end`, month-day strings), mirroring `cd_seasons()`
- [ ] Tests first for `wet_window_stats(x, windows, stats, min_frac = 0.8, threshold = NULL)`. `x` is any daily `date, value` series with optional id columns carried through. Covers:
  - a window crossing 1 January is assigned to the year it starts in, with year boundaries hand-checked
  - a window-year below `min_frac` of its days is dropped
  - `frac_ice` is the share of `B` days when `symbol` is present
  - each statistic on a hand-computed series: `mean`, `min`, `max`, `min7` (rolling 7-day mean minimum within the window), `days_below` (value < threshold), `cov_doy` (day of window by which half the window's volume has passed)
  - 29 February handled for both window membership and the day count
- [ ] Output in cd's long format: `variable` (e.g. `q_mean`), `period` (= window), `year`, `value`, plus `anomaly_type` and `unit` columns per the cd#92 contract, id columns, `n_days` and `frac_ice`
- [ ] A threshold per id through a named vector or a column, documented with station MAD from `wet_station_monthly()`

## Phase 4: departure through cd, and the station run
- [ ] cd to Suggests with `Remotes: NewGraphEnvironment/cd`. A test that `wet_window_stats()` output passes `cd_baseline()` → `cd_anomaly()` → `cd_trend()` without `NA`, with `skip_if_not()` on cd having the #92 behaviour, so it activates once #92 is installed
- [ ] Download the 2026-07-17 HYDAT to its own path under `data/hydat/<version>/`; the water-balance HYDAT is left in place (CLAUDE.md)
- [ ] `scripts/station_departure.R 08EE013 08EE003`:
  - daily series → calendar windows plus two example life-history windows, labelled as examples until knowledge#25 lands
  - per station: cd baseline, anomaly and trend, with baseline 1981–2010 and the per-station years used stated
  - output: a report at `data/checks/station_departure_report.txt` (tracked, per the gitignore exception)
- [ ] Record coverage, the gaps found and the headline departures in `findings.md`, and in `research/station_flow_departure.md` if a durable method verdict comes out of it (plus its `research/README.md` row)

## Phase 5: docs and wrap-up
- [ ] Roxygen with runnable examples on the fixture-free parts (`wet_windows_calendar()`, `wet_window_stats()` on a synthetic series); HYDAT and network examples in `\dontrun{}`
- [ ] `_pkgdown.yml` reference index if present, `devtools::document()`, `lintr`, full `devtools::test()`
- [ ] CLAUDE.md Architecture: a line for the station-departure path
- [ ] `/planning-archive`, `/gh-pr-push`

## Decisions (approved at the plan gate, 2026-09-28)

1. **Function names.** `wet_station_daily()` (matches `wet_station_monthly()`), `wet_window_stats()` (series-agnostic, so it can take temperature), `wet_windows_calendar()`. The alternative is `wet_flow_windows()`, which reads flow-only.
2. **Multi-station through cd.** Recommended: add one line to cd#92 now, while it is in flight, asking cd's consumer functions to carry extra id columns (e.g. `station_number`) into their `.by`. It costs one line there and removes a split/rebind step in every caller. Fallback if cd#92 has already merged: the script splits per station.
3. **historic/ (2016–2024) is out of scope.** A fresh HYDAT covers flow through the provisional archive's start. Pre-2024-10 provisional data waits for water-temp-bc#19.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
