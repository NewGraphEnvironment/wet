# Station flow departure: sources, seams and what a departure rests on

**Verified:** 2026-09-28 (species windows and Chinook open-water 2026-10-01) · **Issues:** #25 (from #6; feeds knowledge#25, cd#92, cd#95, water-temp-bc#19), #27 (vignette) · **Produced by:** `scripts/station_departure.R` → `data/checks/station_departure_report.txt`, HYDAT 2026-07-17; species windows by `vignettes/station-flow.Rmd` on `data-raw/station_vignette_data.R`'s bundle (retrieved 2026-10-01) and `data-raw/station_vignette_map.R`'s map layers

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

## Known residuals

- **HYDAT's approved end is taken as its last day with a value.** `DLY_FLOWS` has no column that states where approval ends. The March 2025 row for 08EE013 has `NO_DAYS` 31 but values only on the 1st and 2nd. A station whose last approved month ends in NULL days would get those days filled with provisional flows. For 08EE013 and 08EE003 the proxy matches GeoMet's approved end (2025-03-02, 2025-03-04).
- **Two definitions of a day with flow.** `wet_station_select()` and `wet_station_monthly()` count the 31 FLOW columns, so an impossible day counts. `wet_station_daily()` drops impossible days. They agree on real HYDAT, which leaves impossible days NULL.

## Method choices

- Windows are month-day pairs. One that crosses 1 January takes the year it starts in. An end of `02-29` is the end of February.
- A window-year needs ≥80% of its days and must lie inside the record.
- `min7` uses seven consecutive calendar days inside the window. `cov_day` needs a complete window-year.
- Departure and trend are cd's (baseline mean; % of normal for levels, absolute for shares and timing; Theil-Sen and Mann-Kendall), one station per call (cd#95 would lift that).
- Mann-Kendall on a constant series (a share that is 0 every year) prints a Kendall Fortran message. cd still returns slope 0, p 1.

## Species windows (#27, first pass)

The first version of `vignettes/station-flow.Rmd` (#29) ran the same path over the 11 complete BULK windows in knowledge's `life_history_timing.csv` at c97c4d0. The 12th, CO migration, has no end date. Seven of the 11 have no source yet.

- **The provisional-winter rule reaches spring windows.** Five of the 11 touch November–April: CH and BT incubation, CH emergence, CO spawning and ST spawning. CH emergence and ST spawning lose 2025–2026 only because they start on 15 April. That was the rule as decided at #27's first plan gate, and that version listed every window-year it dropped.
- **08EE003 is gauged through the winter only in 1971 and 2011–2026**, taking at least 80% of January–February days as the test. So CH incubation, BT incubation and ST spawning have under 10 baseline years and get no departure. Its "from 2000" trends start in 2010 or 2011.
- **Median against mean.** The CH spawning window's 1981–2010 mean at Buck Creek is 0.91 m³/s; the median year is 0.59. A typical year therefore reads 36% below the mean normal, so a figure drawn against the daily median and a departure from the mean must be named apart.
- **Trends, from 1981 and from 2000, for window mean and 7-day minimum.**
  - There are 68 distinct slopes; CH and SK spawning share their dates, so they count once.
  - 5 are significant at p < 0.05, where chance alone would give about 3.
  - All 5 are negative: at Buck Creek, CH/SK spawning mean, CO spawning and BT spawning 7-day minimum since 2000; at 08EE003, CH migration and CH emergence mean since 2000.

## Chinook open-water windows, 2022–2026 (#27 revision)

The revised vignette keeps only the Chinook windows that stay in open water: migration (05-01–08-01), spawning (08-01–09-15) and fry migration (07-15–09-07). Incubation (08-01–03-31) and emergence (04-15–07-07) touch November–April, so they are left out rather than corrected. That removes the provisional-winter drop rule from the vignette (it was a no-op for these three windows) and the ice discussion, leaving one sentence on why the winter-touching windows are out.

- **Every window at both stations was below its 1981–2010 mean in 2023–2026.** That is 24 station-window values (2 stations × 3 windows × 4 years): 21 of them fall below the baseline's 10th percentile, and 6 below its minimum (08EE003 migration 2023–2026, 08EE013 migration 2024–2025). The lowest is 08EE003 spawning 2024, at 19% of the mean. 2022 was wet in migration and fry migration, above the mean at both stations (126–206%); its spawning window was below (71% and 99%).
- **A median baseline year is 64–96% of the mean** across the six station-windows. The key figure therefore draws the median year as a second reference line, and the interpretation is anchored on rank, not on sign.
- **08EE003's 1981–2010 baseline is 1981–1998** (18 years) in all three windows. It has no window with 80% of its days in 1999–2010: only a few spot values a year in 2000–2009, and a record from September 2010 that is continuous except for two provisional gaps in 2025 (1–8 July and 3–11 August). Its three 2025 windows rest on 80–91% of their days (37 of 46, 85 of 93 and 46 of 55), which `wet_window_stats()` accepts at `min_frac = 0.8`.
- **The catchments are nested.** Buck Creek's FWA catchment (567 km²) lies inside 08EE003's (2,315 km²): 24% of its area. FWA area against HYDAT gross area is 0.997 and 0.998. For each window and recent year (15 pairs), the two stations fall on the same side of the mean, partly by construction.
- **Trends** use the three windows, 2 variables, 2 starts and 2 stations: 24 slopes, 2 significant at p < 0.05, both negative. These are 08EE013 spawning mean and 08EE003 migration mean, both since 2000. Fry migration shares 38 of its 55 days with spawning, so the tests are not independent.
