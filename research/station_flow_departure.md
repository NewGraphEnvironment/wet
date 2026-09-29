# Station flow departure: sources, seams and what a departure rests on

**Verified:** 2026-09-28 · **Issues:** #25 (from #6; feeds knowledge#25, cd#92, cd#95, water-temp-bc#19) · **Produced by:** `scripts/station_departure.R` → `data/checks/station_departure_report.txt`, HYDAT 2026-07-17

## Sources and where they meet

| source | reader | what it holds | lag |
|---|---|---|---|
| HYDAT `DLY_FLOWS` | `wet_hydat_daily()` | approved daily flow, `FLOW_SYMBOL` per day (B ice, E estimate, A partial, D dry) | release 2026-07-17 ends March 2025 for 08EE013/08EE003 |
| water-temp-bc `canonical/Parameter=6/` | `wet_provisional_daily()` (duckdb, keyless S3) | ECCC provisional daily means archived monthly since 2024-10 | to the 1st of the month |
| ECCC real-time (`tidyhydat::realtime_ws`, parameter 6) | `wet_realtime_daily()` | provisional daily means, about 18 months back | to yesterday |

Each source continues the one before it, per station. A provisional value is never used inside HYDAT's approved record, because a hole there is a day ECCC chose not to publish. With the 2026-07-17 HYDAT, 08EE013 and 08EE003 join with no gap: HYDAT to 2025-03-02/04, provisional to 2026-09-12, real-time to yesterday. An older HYDAT (2025-10-14: 08EE013 to 2023-12-31) leaves a hole that the provisional archive only fills once water-temp-bc#19 unifies `historic/`.

## What a departure rests on

- **Ice.** 43% of Buck Creek's approved days are `B`: ice-affected estimates (7,885 of 18,193). Winter statistics are mostly estimates. `frac_ice` is carried per window-year.
- **Provisional winters are not usable.** The canonical archive's `Symbol` is NA on every row for both stations, so nothing marks provisional ice days. Buck Creek's provisional means were 6.5–15 m3/s for Dec 2025 – Feb 2026, against approved winters of 0.2–2 m3/s; this is uncorrected stage under ice. The script drops any year with provisional days from windows touching November–April.
- **Seasonal gauges have no winter baseline.** 08EE003 (Bulkley nr Houston) was run April/May–October until 2010 and year-round from 2011, so it has 1 DJF year in 1981–2010 and its only complete years are 1971 and 2011–2024. The script refuses departure for a window with fewer than 10 baseline years, and takes MAD from the whole record's complete years when 1981–2010 has fewer than 5.
- **Mean-based normals are skewed by wet years.** Buck Creek's August 1981–2010 monthly means run 0.14–4.12 m3/s (median 0.73), so % of mean normal overstates how low a typical dry year is. The ranking is still unambiguous: August 2024 (0.212) would be second-lowest of the 29 baseline years.

## Result, 2023–2026 (open-water windows, departure from 1981–2010 mean)

- Both stations are 54–87% below the 1981–2010 mean for August, September and summer (JJA) in every year 2023–2026.
- In the example Chinook spawning window (1 Aug – 15 Sep), both are 58–82% below in every year.
- 7-day minima are 51–88% below in the same windows.
- Buck Creek: every August day in 2023–2026 fell below 20% of MAD (share up 0.33 on the baseline).
- Trends in the Buck Creek anomaly since 2000 are negative for summer and early fall:
  - JJA mean −2.1 %/yr (Mann-Kendall p 0.03);
  - September mean −2.6 %/yr (p 0.006);
  - September 7-day minimum −1.9 %/yr (p 0.02);
  - Chinook spawning-window mean −1.8 %/yr (p 0.03).
- At 08EE003 the same windows' slopes are negative but not significant (p 0.07–0.32, 15–16 years since 2000).

## Method choices

- Windows are month-day pairs. One that crosses 1 January takes the year it starts in. An end of `02-29` is the end of February.
- A window-year needs ≥80% of its days and must lie inside the record.
- `min7` uses seven consecutive calendar days inside the window. `cov_day` needs a complete window-year.
- Departure and trend are cd's (baseline mean; % of normal for levels, absolute for shares and timing; Theil-Sen and Mann-Kendall), one station per call (cd#95 would lift that).
- Mann-Kendall on a constant series (a share that is 0 every year) prints a Kendall Fortran message. cd still returns slope 0, p 1.
