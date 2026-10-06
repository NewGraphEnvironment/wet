# Task: Water temperature at hydrometric stations from water-temp-bc: start the wet_temp_* family (#36)

wet reads only discharge from water-temp-bc (`Parameter=6`, in `wet_station_daily()`). Water temperature (`Parameter=5`, 306 stations, sub-daily readings from 2002) is in the same public archive and nothing in the package reads it. The downstream half already exists: `wet_window_stats()` has an absolute-anomaly mode meant for temperature, and its output is in cd's long format.

## What the probe found (2026-10-06, read-only duckdb on S3) — shapes the design

- Schema: `STATION_NUMBER, Date (TIMESTAMPTZ, UTC), Value, Unit (°C), Grade, Symbol,
  Approval, …`. No duplicate (station, Date) keys. `Symbol` NA on every row.
- **Sentinels and junk, ~2 % of readings:** `99999` (184 k), `99.9`, `999`, `-108`,
  `360`, `-99999`, plus 58 k in −5…−0.5 and 13 k in 35…100 (sensor in air or ice).
  The issue's 643,440 station-days counted these; with a −5…40 filter it is 631,718,
  still 97.8 % passing the 20-hour rule (median 24 h, p10 24).
- **Approval:** `1` (2009–2022), `4` (2002–2010), NA (2023–25), `Provisional/Provisoire`
  (2022→). No `Final` row exists, so every day is `"provisional"` under the existing
  rule in `wet_eccc_daily()` (`R/wet_station_daily.R:200`).
- **Cadence** mixes hourly with 15/30-min and `:02`/`:03` stamps.
- **Day boundary matters:** UTC midnight is 16:00 PST, near the diurnal maximum, so
  UTC days would split the afternoon peak. `tidyhydat::allstations$standard_offset`
  gives −8 for 276 and −7 for 27 of the 306 stations (it matches water-temp-bc's
  `stations_realtime.parquet` on all 291 shared); 3 are in neither.

## Decisions taken at this gate (recommended defaults; edit before approving to change)

1. **Plausible range `valid = c(-1, 35)` °C, applied to readings before reducing**,
   an argument with that default. Drops the sentinels and most air/ice readings;
   a day then needs ≥ 20 hours of *valid* readings.
2. **Days are local standard time per station** (no DST), offset from
   `tidyhydat::allstations`; a station with no offset falls back to −8 (Pacific) with
   a warning naming it.
3. `t_mean_c` is the mean of **hourly means** (so a 15-min hour does not outweigh an
   hourly one); `t_min_c`/`t_max_c` are over the valid readings.

## Phase 1: `wet_temp_daily()` with tests

- [x] Tests first, `tests/testthat/test-wet_temp_daily.R`: write a tiny parquet with a
  real `TIMESTAMPTZ` column via duckdb into a temp dir, point `wet.temp_root` at it
  (exercises the real SQL, no network). Cases: hourly day → mean/min/max/n_hours;
  19-hour day dropped, 20-hour kept; sentinels (99999, −99999, 999) dropped before
  the hour count; mixed 15-min/hourly hour weighting; local-day boundary (−8 vs −7
  station, a 07:00 UTC reading lands on the previous local day); `from`/`to`; status
  mapping (`1`, `4`, NA, Provisional → `"provisional"`; `Final/Finales` → `"approved"`);
  unknown-offset warning; no-data station warning and zero-row shape; bad inputs
  (`stations`, `from > to`, `valid`). Plus a `skip_on_ci()` live test on 08EE013 and a
  round-trip through `wet_window_stats(value = "t_mean_c", level_anomaly = "absolute",
  unit = "degC", prefix = "t")`.
- [x] `R/wet_temp_daily.R`: `wet_temp_daily(stations, from = NULL, to = Sys.Date(),
  valid = c(-1, 35), min_hours = 20)`. Reads option `wet.temp_root` (default
  `s3://water-temp-bc/data/canonical/Parameter=5/`) with the same keyless-secret duckdb
  connection as `wet_provisional_daily()`. *(Changed in build: no icu and no session zone;
  local hour and day come from `epoch_ms()` integer arithmetic, because `epoch()` plus a
  double fails to bind or segfaults across duckdb instances in 1.5.2.)* The
  station offsets go in as a small table, and SQL shifts `Date` by the offset, buckets
  by local date and hour, and returns one row per station-day. Returns
  `data.frame(station_number, date, t_mean_c, t_min_c, t_max_c, n_hours, source, status)`,
  `source = "provisional"`, sorted by station and date, `from`/`to` trimmed in SQL.
  Reuses `wet_eccc_daily()`'s approval rule (factor out a one-line helper rather
  than duplicate the regex).
- [x] roxygen: documents the filter, the day boundary, the 20-hour rule and
  `n_hours`, that there is no ice flag, and that the departure baseline is
  **2016–2025, never 1981–2010** (with the coverage counts from the issue).
  `@examples` in `\dontrun{}` (network), ending in `wet_window_stats()`.
- [x] `devtools::document()`, `lintr`, `devtools::test()`; `pkgdown::check_pkgdown()`
  (no `reference:` index, so it should pass as is).

## Phase 2: Measurement record and docs

- [ ] `scripts/temp_coverage.R` → `data/checks/temp_coverage_report.txt` (tracked):
  readings, sentinel/out-of-range counts, station-days passing at 20 h, stations per
  year, and stations meeting ≥ 300 days in ≥ 8 of 10 years for 2003–2012, 2011–2020,
  2014–2023, 2016–2025, all after the `valid` filter. Re-derives the issue's numbers
  with the filter applied (they will move slightly).
- [ ] `research/station_water_temperature.md` (new topic file, provenance header):
  the archive's shape, sentinels, approval codes, cadence, day boundary, the
  coverage table and the 2016–2025 baseline rule; row in `research/README.md`.
- [ ] Edit issue #36's body with the corrected station-day count and the two
  decisions above; CLAUDE.md architecture line for `wet_temp_daily()` → `wet_window_stats()`.
- [ ] NEWS.md entry (under the dev heading; no version bump on the branch).

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
