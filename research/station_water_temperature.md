# Water temperature at hydrometric stations: the archive, the daily rule and the baseline

**Verified:** 2026-10-06 · **Issues:** #36 (from #25; uses water-temp-bc#19's canonical store) · **Produced by:** `scripts/temp_coverage.R` → `data/checks/temp_coverage_report.txt` and `scripts/temp_day_boundary.R` → `data/checks/temp_day_boundary_report.txt`, archive as of its 2026-10-01 rewrite; design probes in `planning/archive/2026-10-issue-36-*/`

## The archive

water-temp-bc's `canonical/Parameter=5/` is ECCC water temperature. It is read by `wet_temp_daily()` with duckdb and a keyless S3 secret, the same way as the provisional flows. Since water-temp-bc#19 folded `historic/` into it, it is the only read path.

- 17,428,356 readings, 306 stations, 2002-04-30 to 2026-10-01. No duplicate (station, `Date`) keys.
- `Date` is a `TIMESTAMP WITH TIME ZONE` holding UTC. `Symbol` is NA on every row, so there is no ice flag.
- Cadence is mostly hourly, with some 15- and 30-minute records and some stamps at `:02`, `:03` or `:32:30`.
- The record is almost all from 2011 on. Before that, one station has data in 2002–2007, and 2009 and 2010 together hold fewer than 900 readings.
- `Approval` is ECCC's code `4` (2002–2010), code `1` (2009–2022), `Provisional/Provisoire` (2022 on) or empty (50,890 rows, 2023–2025). The codes' meanings were not published with the bulk dump (water-temp-bc `research/historic-archive.md`). No row is `Final/Finales`. `wet_temp_daily()` treats anything not final as provisional, which is the rule `wet_station_daily()` already uses, so every temperature day is `"provisional"` for now.

## Junk readings and the `valid` range

About 1.9 % of readings fall outside −1…35 °C: 120,500 below and 216,872 above. They are ECCC sentinels (`99999` 184,177, `99.9`, `999`, `-99999`, 193,092 together) and values like `-108` and `360`, plus a band of −5…−1 °C that is a logger reading air or ice in winter. `wet_temp_daily(valid = c(-1, 35))` drops them before it counts hours, so a day made of sentinels does not pass the hour rule. 12,662 readings in −1…−0.5 are kept; they are plausibly sensor offset at 0 °C. No range can remove a logger out of the water in summer, when air and water overlap.

## Days

- **Local standard time, per station.** UTC midnight is 16:00 PST, close to the diurnal maximum, so UTC days would split each afternoon's peak across two days. Offsets come from `tidyhydat::allstations$standard_offset`: UTC−8 for 276 stations and UTC−7 for 27 (the Peace and parts of the Kootenays). These agree with water-temp-bc's `stations_realtime.parquet` on all 291 stations both list. Three stations are in neither (08DA013, 08DB015, 08NHX18), and are taken as UTC−8 with a warning. Daylight saving is ignored.
- **Why midnight.** Measured by `scripts/temp_day_boundary.R` → `data/checks/temp_day_boundary_report.txt`, on 189,306 open-water days (May–September, diurnal range ≥ 1 °C). With the split at local midnight, 16.5 % of days have their maximum or minimum in the day's first or last hour. Splits at 03:00, 06:00, 12:00 and 18:00 give 18.6 %, 48.7 %, 17.1 % and 56.5 %. At midnight the maximum falls in hours 15–18 (15:00–18:59) on 60 % of days and the minimum in hours 6–8 on 62 %. The remaining edge cases cluster in hour 0 for the maximum (9.8 %) and hour 23 for the minimum (5.6 %). They may be days that cooled from start to finish, but that was not measured. No split tested gets below about 16 %, and noon is within 0.6 points of midnight, so the data rule out splits at 06:00 and 18:00 rather than choosing midnight over noon. Midnight wins on the other grounds: it is the calendar day, and ECCC's daily flow means are stamped at local standard midnight, so temperature and flow days cover the same hours.
- **The hour rule.** A day counts when at least 20 of its 24 hours have a valid reading. 630,001 station-days have one; 615,802 (97.75 %) pass. The median day has 24 hours and so does the 10th percentile. Short days are dropped, not filled, and `n_hours` is returned. (The issue's 643,440 station-days and 98 % counted UTC days and did not drop junk.)
- **The mean weights hours.** `t_mean_c` is the mean of hourly means, so four 15-minute readings in one hour count once. `t_min_c` and `t_max_c` are over the readings.

## Baseline

A station has a usable year when it has at least 300 kept days. It has a usable window-year when at least 80 % of the window's days are kept, as in `wet_window_stats(min_frac = 0.8)`. A decade is usable when at least 8 of its 10 years are. Stations by decade, from the 2026-10-06 run:

| decade | whole year | Chinook migration (05-01–08-01) | spawning (08-01–09-15) | fry migration (07-15–09-07) |
|---|---|---|---|---|
| 2003–2012 | 0 | 0 | 0 | 0 |
| 2011–2020 | 26 | 34 | 35 | 35 |
| 2014–2023 | 53 | 58 | 67 | 63 |
| 2016–2025 | 69 | 81 | 86 | 86 |

So **a temperature departure is taken against 2016–2025, never 1981–2010**. Wherever it sits beside a flow departure on 1981–2010, the output and the prose must state both baselines. Open-water windows clear the bar at more stations than whole years, because many loggers are seasonal. The issue's counts (32, 64 and 79 for the last three decades) were made before junk was dropped and on UTC days. They are 6 to 11 higher; they counted UTC days and kept the junk readings, and which of the two moves them was not separated.

The departure itself is cd's, in degrees C: `wet_window_stats(value = "t_mean_c", level_anomaly = "absolute", unit = "degC")`, then `cd_baseline(x, 2016:2025)` and `cd_anomaly()`.

## Not yet done

- No modelled yardstick. PCIC's VIC-GL-dynWat (coast only, per reach) is the next `wet_temp_*` member, then our own per-segment estimate, each in its own issue.
- No 7-day maximum metric (MWAT-style). `wet_window_stats()` takes one value column, so a window's highest daily maximum is a second call on `t_max_c`.

## duckdb note

In the R client, duckdb 1.5.2 and 1.5.6, `epoch()` on a `TIMESTAMPTZ` autoloads the icu extension, and the query that triggers that autoload binds its arithmetic unreliably. Measured 2026-10-06, `epoch(TIMESTAMPTZ '2020-01-01 00:00:00+00') + 1.5` in 15 fresh R processes on 1.5.6:

- 9 binder errors, `No function matches … '+(DOUBLE, DECIMAL(2,1))'` with an empty candidate list (once with the operator name missing);
- 3 silently wrong results, epoch − 1.5;
- 2 R aborts;
- 1 `INTERNAL Error`.

1.5.2 gave 14 errors and 1 wrong result in 15 runs. The same query succeeds once icu is loaded: run again on the same connection, or after an explicit `LOAD icu`, it was clean every time. The 1.5.6 command-line binary does not show it, because it loads icu at startup. `epoch_ms()` needs no extension, so `wet_temp_daily()` uses integer `epoch_ms()` arithmetic and never loads icu. Any other duckdb query on a `TIMESTAMPTZ` that needs icu (`year()`, casts to `DATE`, …) should `LOAD icu` first. An earlier reading, that this needed a prior database in the session to have shut down, was wrong: it fails on the first connection.

Reported upstream as duckdb/duckdb-r#2883 (2026-10-06).
