## Outcome

Added `wet_temp_daily()`, the first `wet_temp_*` member: ECCC water temperature at about 300 hydrometric stations from water-temp-bc's `canonical/Parameter=5/`, reduced to daily mean (of hourly means), minimum and maximum in each station's local standard time, in the station-day shape `wet_window_stats()` and cd take. Two decisions were added at the plan gate after probing the archive: readings outside −1…35 °C are dropped first (about 1.9 % are ECCC sentinels or a logger in air or ice), and days are local standard time per station (UTC midnight is 16:00 PST, near the daily maximum). A plan review (18 findings) and three code-check rounds shaped it; round 3 found round 1's SQL-formatting defect in the second caller, so both now share `wet_sql_num()`, and an enumeration of all 10 SQL-text sites closed the loop. The durable verdict is `research/station_water_temperature.md`.

## Measurement

- Archive, 2026-10-06: 17,428,356 readings, 306 stations, 2002-04-30 to 2026-10-01; 337,372 (1.94 %) outside −1…35 °C, 193,092 of them sentinels. Almost nothing before 2011 (one station 2002–2007; 875 readings in 2009–2010).
- 630,001 local station-days have a valid reading and 615,802 (97.75 %) pass the 20-hour rule. The issue's 643,440 / 98 % were UTC days with junk kept.
- Stations with ≥ 300 kept days in ≥ 8 of 10 years: 0 (2003–2012), 26, 53, 69 (2016–2025), against the issue's 0/32/64/79. Chinook open-water windows: 81–86 stations for 2016–2025. This kept the 2016–2025 baseline and lowered its station counts.
- Offsets from `tidyhydat::allstations`: 276 at UTC−8, 27 at UTC−7, 3 unlisted; they agree with water-temp-bc's own station table on all 291 shared.
- duckdb 1.5.2: `epoch(TIMESTAMPTZ) + DOUBLE` failed to bind 30 of 40 fresh connections in one R session and segfaulted in others; `epoch_ms()` with integers ran 40 of 40. The first diagnosis, implicit column aliases, was wrong: adding `AS` changed nothing.
- Mutation check: ignoring the offset, a reading-weighted mean, an any-final day status and the old `format()` bounds each turned the tests red.

## Evidence

`data/checks/temp_coverage_report.txt` (from `scripts/temp_coverage.R`); reviews in this directory, `review-*.md`.

Closed by: PR (this branch, `36-water-temperature-at-hydrometric-station`)
