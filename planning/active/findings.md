# Findings — Flow in date windows at hydrometric stations: daily series, window metrics, departure via cd (#25)

## Issue context

**If we do it:** at any real-time station we can say, year by year, whether flow in a window that matters (a month, a season, a species' migration or spawning period) was above or below normal, and whether that is trending. The record runs up to last month. **If we never do:** "is it drier than it used to be at spawning time" stays anecdotal, and departures stop at HYDAT's last approved year, currently one to two years back.

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

## Proposed Solution

wet owns everything up to one value per year per window. cd owns the statistics after that. The two meet on cd's long format (`variable`, `period`, `year`, `value`), so wet needs at most a Suggests on cd and holds no copy of its baseline, anomaly or trend code.

1. `wet_station_daily()`: one daily discharge series per station. Port `ngr::ngr_hyd_q_daily()` rather than writing a new one. That function already joins HYDAT (via tidyhydat) with about 18 months of real-time daily flow, keeps HYDAT on overlap and warns on missing dates. Hydrology data now belongs to wet (NewGraphEnvironment/sred#26). The ngr copy is deprecated with a shim once wet is public, because two report repos call it.
   - Its gap today: the real-time window reaches back to about 2025-02, while our HYDAT copy ends 08EE013 at 2023-12-31. That leaves a hole from 2024-01 to 2025-02, which water-temp-bc's archive fills. Real-time rows also carry no ice `Symbol` (`NA`).
   - Use approved HYDAT where it exists, and fill in after that from water-temp-bc provisional data (Parameter 6).
   - Each row carries `source`/`status` and the ice (`B`) or estimate (`E`) symbol, so a result can say what it rests on.
2. A window function: any daily `date, value` series plus a table of windows (`window`, `start`, `end` as month-day), returning one row per year per window in cd's long format.
   - Windows can be months, seasons or life-history periods (NewGraphEnvironment/knowledge, life-history timing table).
   - Keep it series-agnostic, so the water temperature from water-temp-bc can go through the same path.
   - A year counts for a window when enough of the window's days are present, not only when the whole year is complete, so seasonal records still contribute.
3. Flow metrics: mean, 7-day minimum, days below a fraction of MAD, and the centre-of-volume date. The MAD comes from the station's own record or from wet's modelled MAD at the snapped segment; the plan decides which.
4. Departure and trend: `cd_baseline()`, `cd_anomaly()`, `cd_trend()`, `cd_compare()`, once NewGraphEnvironment/cd#92 lets `cd_anomaly()` take series outside ERA5.

For the plan gate:
- A window that crosses 1 January (incubation, Sep–Apr) is assigned to the year it starts in (brood year) unless we decide otherwise.
- Winter windows rest largely on ice-affected estimates. Report the share of `B` days per window rather than dropping them.
- Temperature records are about 8–9 years long. That supports ranking years within the record, not departure from a 30-year normal.
- Reading the pre-2024-10 archive through one path depends on NewGraphEnvironment/water-temp-bc#19.

Relates to #6



## Plan-mode exploration (2026-09-28)

- **Helpers to reuse.** `R/wet_station_select.R` already has `wet_hydat_path()`, `wet_hydat_connect()` (read-only sqlite), `wet_complete_years()` and `wet_station_empty()`. `R/wet_mm_to_m3s.R` has `wet_month_days()`.
- **Station MAD already exists.** `wet_station_monthly()`'s `month == 0` row is the station's mean annual flow over complete years, which is the threshold source for "days below x% MAD". No new MAD function is needed.
- **HYDAT symbols.** `DLY_FLOWS` has `FLOW_SYMBOL1..31` next to `FLOW1..31`; the symbols are A partial day, B ice, D dry, E estimated, S sample. The installed HYDAT is version 2025-10-14, and a 2026-07-17 release is available.
- **Test fixture.** `tests/testthat/helper-hydat.R` (`local_hydat()`) builds a tiny HYDAT. It needs `FLOW_SYMBOL*` columns added. Existing tests select `FLOW%d` only, so they are unaffected.
- **Dependencies.**
  - wet imports curl, DBI, jsonlite and terra, with tidyhydat, RSQLite and withr in Suggests.
  - The water-temp-bc read needs **duckdb** (httpfs, anonymous S3; the bucket is public with ListBucket) as a Suggests. duckdb and cd are both installed here.
- **water-temp-bc layout.** `canonical/Parameter=6/` holds daily mean discharge. `Date` is a UTC timestamp at 08:00 (local midnight), so the day is `as.Date(Date, tz = "UTC")`. Measured coverage for both stations is 2024-10-10 → 2026-09-12. `historic/` (2016–2024) is not one read path until water-temp-bc#19, so this issue reads `canonical/` only. A fresh HYDAT reaches about 2025-03 and overlaps it.
- **cd's consumer functions group by `variable` and `period` only.** A multi-station table sent through `cd_baseline()` gets averaged across stations. See Decision 2.

## HYDAT reader check (2026-09-28)

`wet_station_daily(c("08EE013", "08EE003"), sources = "hydat")` against the local HYDAT (version 2025-10-14) matches `tidyhydat::hy_daily_flows()` exactly for 08EE013: 18,193 non-NA days in both, max abs difference 5e-14.

Ice dominates the winter record. Symbols by station:

| station | A | B (ice) | E | none |
|---|---|---|---|---|
| 08EE003 | 16 | 2,402 | 2,008 | 8,068 |
| 08EE013 | 142 | 7,885 | 605 | 9,561 |

43% of Buck Creek's daily flows are ice-affected estimates. Any winter window statistic there rests mostly on them, which is why `frac_ice` is carried per window-year.

## Sources joined (2026-09-28)

HYDAT 2026-07-17 (`data/hydat/20260717/`) ends March 2025 for both stations (`MAX(YEAR*100+MONTH)` = 202503). `wet_station_daily(c("08EE013", "08EE003"), <that path>)` joins with no seam gaps:

| station | hydat | provisional | realtime |
|---|---|---|---|
| 08EE003 | 1930-09-09 .. 2025-03-04 | 2025-03-05 .. 2026-09-12 | 2026-09-13 .. 2026-09-27 |
| 08EE013 | 1973-01-01 .. 2025-03-02 | 2025-03-03 .. 2026-09-12 | 2026-09-13 .. 2026-09-27 |

The water-temp-bc canonical `Symbol` is NA on every row for both stations, so provisional winters carry no ice flag. `frac_provisional` is what marks them.

The duckdb read uses an explicit keyless S3 secret (region us-west-2), so AWS credentials in the environment are never sent.

## Station run (2026-09-28)

`scripts/station_departure.R` (with cd from PR #94, installed to a scratch library) → `data/checks/station_departure_report.txt`. Verdicts are in `research/station_flow_departure.md`. In the order they came up:

- **Wrong turn.** The first run stopped on "no 1981-2010 MAD for 08EE003". The station was seasonal until 2010 (complete years 1971 and 2011-2024 only), so MAD now falls back to the whole record, and windows with fewer than 10 baseline years get no departure (08EE003 DJF: 1 year).
- **Real bug**, found by a spot check with `from = 2025-11-15`. When HYDAT rows are read for a year but none fall in `from`/`to`, `data.frame()` could not recycle the scalar `source` onto zero rows. `wet_eccc_daily()` had the same bug. Both are fixed, with tests; the mutation run gave FAIL 2.
- **Artifact.** Buck Creek DJF 2025 came out at +200% (cd's cap). The provisional Dec 2025 - Feb 2026 means are 6.5-15 m3/s against approved winters of 0.2-2: ice, not flow. Winter-touching windows now drop provisional years.
- **Cross-check.** August departures were checked against `tidyhydat::hy_monthly_flows()`: 2023 0.356 and 2024 0.212 m3/s against 1981-2010 August means of 0.14-4.12 (median 0.73). The −62% and −78% are correct. The mean-based normal is pulled up by two wet years (3.72, 4.12).

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `tidyhydat::download_hydat(dl_hy_path=)` "unused argument", yet the backgrounded call reported exit 0 through a pipe | The argument is `dl_hydat_here`; read the output, not the exit status |
| `data.frame(..., source = "hydat")` errored "differing number of rows: 0, 1" when a year's rows all fell outside from/to | Return `wet_daily_empty()` when nothing is kept (both readers) |
| `max(c(NULL, <Date>, ...))` returned a plain number (c dispatches on its first argument) | Put a Date first; regression test "real-time alone still gets Dates" |
