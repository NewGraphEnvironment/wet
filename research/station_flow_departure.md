# Station flow departure: sources, what a departure rests on, and ungauged sites

**Verified:** 2026-11-27 (re-read: the tracked reports below; the HYDAT 20260717 ice and August figures, the water-temp-bc archive and the 2016–2025 changes, recomputed read-only; the reading, window, extension and carry code. Not re-run: any departure script. Not re-read: the real-time feed, GeoMet's approved end, cd's trend message and the literature cited, which keep their earlier dates) · **Issues:** #25 (from #6; knowledge#25, cd#92, cd#95, water-temp-bc#19), #27, #120, #121, #122, #147, #152 · **Produced by:** `scripts/station_departure.R` → `data/checks/station_departure_report.txt` (run 2026-09-28, HYDAT 2026-07-17); `vignettes/flow-departure-normal.Rmd` on `data-raw/station_vignette_data.R`'s bundle (retrieved 2026-10-01) and `data-raw/station_vignette_map.R`'s layers; `scripts/departure_interval_coverage.R` → `data/checks/departure_interval_coverage.txt`; the Maxan pilot's reports, `data/checks/departure_pilot_20260717.txt` and `data/checks/departure_snow_20260717.txt`

This file holds the method. Per-site results, Maxan's included, are in [`chinook_sites.md`](chinook_sites.md).

## Sources and where they meet

For a HYDAT station number, `wet_station_daily()` joins three sources, each continuing the one before, per station:

| source | reader | what it holds | lag |
|---|---|---|---|
| HYDAT `DLY_FLOWS` | `wet_hydat_daily()` | approved daily flow, `FLOW_SYMBOL` per day (B ice, E estimate, A partial, D dry) | release 2026-07-17 ends March 2025 for 08EE013 and 08EE003 |
| water-temp-bc `canonical/Parameter=6/` | `wet_provisional_daily()` (duckdb, keyless S3) | ECCC provisional daily means, a monthly archive; on 2026-11-27 it held 08EE013 from 2016-03-22 and 08EE003 from 2016-01-08, to 2026-11-01 | to the 1st of the month |
| ECCC real-time (`tidyhydat::realtime_ws`, parameter 6) | `wet_realtime_daily()` | provisional daily means, read from at most 540 days back | to yesterday |

A provisional value is never used inside HYDAT's approved record, because a hole there is a day ECCC chose not to publish. With the 2026-07-17 HYDAT, 08EE013 and 08EE003 join with no gap (HYDAT to 2025-03-02 and 2025-03-04, provisional from the next day). The archive holds every day of 2024 for both stations, so even a HYDAT that ends on 2023-12-31 now joins it; until water-temp-bc#19 closed (2026-09-30), an older HYDAT (2025-10-14: 08EE013 to 2023-12-31) left a hole. The archive has gaps of its own: of 2023 it holds only the last 75 days (from 18 October) for each station.

A station number that is not HYDAT's (the province's non-integrated network, the BC Water Tool's gauges, Hakai's watersheds) is read from those publishers' records instead: [`station_sources.md`](station_sources.md).

## What a departure rests on

- **Ice.** 43.5 % of Buck Creek's (08EE013) approved days are `B`, ice-affected estimates: 8,101 of 18,620 in HYDAT 20260717 (19.6 %, 2,465 of 12,557, at 08EE003, the Bulkley near Houston). Winter statistics are mostly estimates. `frac_ice` is carried per window-year.
- **Provisional winters are not usable.** Provisional ice days are not marked: the archive's `Symbol` was NA on every row for both stations on 2026-09-28, and on 2026-11-27 only 3 rows at 08EE013 and 8 at 08EE003 carried a code (PN, PX or SD), none an ice code and none in the 2025–26 winter. The values also change after they are archived. Buck Creek's provisional monthly means for December 2025, January and February 2026 were 6.6, 7.8 and 15 m³/s in the bundle retrieved on 2026-10-01 (approved monthly means for December, January and February from 1981 run 0.03 to 3.9 m³/s, median 0.55), and 0.68, 0.65 and 0.68 m³/s when read on 2026-11-27. Why they changed was not traced. `scripts/station_departure.R` drops any year with provisional days from windows touching November–April.
- **Seasonal gauges have no winter baseline.** 08EE003 ran April or May to October from 1981 to 1998 (with November days from 1985), logged a few spot values a year in 2000–2009 and none in 1999, and has run year-round from September 2010. It has 1 December–February year in 1981–2010, and its only complete years are 1971 and 2011–2024. The script refuses a departure for a window with fewer than 10 baseline years, and takes mean annual discharge (MAD) from the whole record's complete years when 1981–2010 has fewer than 5.
- **Mean-based normals are skewed by wet years.** Buck Creek's August 1981–2010 monthly means run 0.14 to 4.12 m³/s (29 years, median 0.75, mean 0.95), so a percentage of the mean overstates how low a typical dry year is. A ranking does not: August 2024 (0.212 m³/s) would be second-lowest of the 29. In the spawning window below, the median year at Buck Creek is 36 % under the mean normal, so a figure drawn against the daily median and a departure from the mean must be named apart.

## Known residuals

- **HYDAT's approved end is taken as its last day with a value.** `DLY_FLOWS` has no column that states where approval ends. The March 2025 row for 08EE013 has `NO_DAYS` 31 but values only on the 1st and 2nd. A station whose last approved month ends in NULL days would get those days filled with provisional flows. For 08EE013 and 08EE003 the proxy matched GeoMet's approved end (2025-03-02, 2025-03-04; read 2026-09-28).
- **Two definitions of a day with flow.** `wet_station_select()` and `wet_station_monthly()` count the 31 `FLOW` columns, so an impossible day counts. `wet_station_daily()` drops impossible days. They agree on real HYDAT, which leaves impossible days NULL.

## Method choices

- Windows are month-day pairs. One that crosses 1 January takes the year it starts in. An end of `02-29` is the end of February.
- A window-year needs at least 80 % of its days and must lie inside the record.
- `min7` uses seven consecutive calendar days inside the window. `cov_day` needs a complete window-year.
- Departure and trend are cd's (baseline mean; percent of normal for levels, absolute for shares and timing; Theil-Sen and Mann-Kendall), one station per call (cd#95, open, would lift that).
- Mann-Kendall on a constant series (a share that is 0 every year) prints a Kendall Fortran message. cd still returns slope 0, p 1.

## Windows and periods: 2016–2025 against 1981–2010

The measured article (`vignettes/flow-departure-normal.Rmd`) compares 2016–2025 with 1981–2010 at 08EE013 and 08EE003, in the Bulkley's chinook salmon life history timing windows for migration (05-01 to 08-01) and spawning (08-01 to 09-15). The fry migration window (07-15 to 09-07) falls within them. Incubation (08-01 to 03-31) and emergence (04-15 to 07-07) touch November–April, so they are left out rather than corrected. 1981–2010 is cited as a WMO standard normal (Arguez and Vose 2011, p. 699; WMO-No. 1203) and is the period wet's published flows are normals of. It already holds part of the warming (Hansen et al. 2012), which is why the comparison article measures from 1951–1980.

| gauge | change in window mean, migration | spawning | baseline years |
|---|---|---|---|
| 08EE003, Bulkley near Houston | −7 % | −8 % | 18 (1981–1998) |
| 08EE013, Buck Creek | −5 % | −48 % | 30 migration, 29 spawning |

- Every window at both gauges was below normal in each year from 2023, and 11 of those 12 window means were drier than nine baseline years in ten. Before 2023 the decade swings both ways. The two gauges fall on the same side of normal in 17 of the 18 window-years both recorded; 2019's spawning window splits them.
- Buck Creek has no 2016 in either window (no days in the bundle), so it has 9 recent years.
- **The catchments are nested.** Buck Creek's Freshwater Atlas catchment (567 km²) lies inside 08EE003's (2,315 km²): 24 % of its area. Atlas area against HYDAT gross area is 0.997 and 0.998. So agreement between the two is partly by construction.
- 08EE003's 2025 record has two provisional gaps, 1–8 July and 3–11 August. Its 2025 migration and spawning windows rest on 85 of 93 and 37 of 46 days, which `wet_window_stats()` accepts at `min_frac = 0.8`.
- The median baseline year is 96 % and 71 % of the mean at 08EE003 (migration, spawning), and 86 % and 64 % at 08EE013. The interpretation rests on rank, not on sign.
- **The resampled range is not a 90 % interval.** At these years it covers 0.834–0.867 of simulated no-change records, under the 0.87 bar (`data/checks/departure_interval_coverage.txt`). The article calls it "the middle 90 % of changes from resampling" and rests no count on it.

## At an ungauged or short-record site

The method was set by a pilot on Maxan Creek (08EE018, 363 km²), gauged for five complete migration windows, 1975–1979. It answers two questions: can a short record be extended across the long record from its neighbours, with an error per year; and do donor gauges' year-to-year departures carry onto a site with no record of its own? The rules were registered in `scripts/departure_pilot.R`'s header at 6894c27, before any candidate existed, and used approved daily flows only. The script is retired; `git show d4fae1f:scripts/departure_pilot.R` recovers it, and `scripts/departure_site.R maxan` reproduces its report.

**The pool.** Natural HYDAT gauges in a box over the Bulkley and its neighbours (lon −128.8 to −125.0, lat 53.6 to 55.8): 53 with at least 3 complete migration windows. Donors are the k = 5 nearest in easting, northing and log drainage area. Counts and scores below are for the migration-window mean, the statistic the rules decide on, unless another is named.

- 21 have at least 30 complete migration windows; they are the extension donors and test gauges.
- 31 have at least 10 complete migration windows in 1981–2010; they are the departure donors. Each other statistic and window has its own set.
- 13 have 3–10 complete migration windows: the short-record test set, Maxan among them.

### Extending a record (`wet_window_extend()`)

Each long gauge's record was cut into 5-year blocks, 220 in all, of which 218 had a donor covering them. Each block was extended from the other long gauges and scored only on the years it held out (log NSE of the migration-window mean).

| method | median NSE over 21 gauges | 90 % interval coverage |
|---|---|---|
| OLS on the nearest covering donor | 0.50 | 85 % |
| line of organic correlation (MOVE.1) | 0.47 | 90 % |
| ratio of means (incumbent) | 0.42 | 89 % |

OLS beats the ratio by more than the 0.01 margin, so it is what extends a record. It stays first with k = 3 and 8, and with nested gauges removed as donors (leak-free, 0.48). Its own prediction interval is a little narrow. A regression on up to three donors scores 0.30 against OLS's 0.56 on the same years, and regressing day by day 0.36 against 0.52. The migration-window 7-day minimum extends badly: every method's median is below 0. A target needs at least 3 years of its own; the pilot's Maxan had 5.

The sites run since the pilot keep OLS (fixed before those runs), although the same race picks the ratio at two of the other boxes ([`chinook_sites.md`](chinook_sites.md)).

### Carrying departures (`wet_departure_carry()`)

Each departure-pool gauge was held out in turn and given its five nearest donors' log departures, each from that donor's own 1981–2010 mean. The score is NSE on the years both series have, each centred on its own mean there, so 0 means "no better than no departure".

- **Median NSE 0.63** over the 31 gauges, quartiles 0.34 to 0.75. That clears the 0.5 set in advance, so the method was taken as usable.
- The short-record gauges score a median of 0.69, over 12 of the 13: 08JB006 shares only two years with its carried series, and a score needs three. Maxan scores 0.92 over its five years.
- Removing donors upstream or downstream of the held-out gauge lowers the median to 0.57.
- The spawning-window mean carries less well (0.49). The migration-window 7-day minimum carries worst (0.23).

**Which donors, as shipped now.** Held out at the 290 calibration gauges PCIC covers, 1951–2012, donors chosen by how well PCIC's modelled flow at the two sites moves together (`covariance_pick`: of the 15 nearest, the 5 that correlate best) carry departures better than the nearest 5 (median NSE 0.72 against 0.67) and better than PCIC's own routed departures (0.48). A blend of the two (0.71) does not beat donors by the 0.01 it needed ([`pcic_hydrology.md`](pcic_hydrology.md), "Per-year routed flow and the departure competition"). At a site, `covariance_pick` replaces distance only where it also wins at that box's gauges ([`chinook_sites.md`](chinook_sites.md)). The article [Chinook Flow at a Short-Record Stream](https://newgraphenvironment.github.io/wet/articles/short-record-flow.html) publishes the Maxan answer on inverse distance; its numbers are in [`chinook_sites.md`](chinook_sites.md), "Maxan by inverse distance: the pilot's record".

### Snow and the window flows

Each year's peak snow water equivalent (`swe_max`) and 50 % melt date (`snowmelt_doy_50`) are averaged over the gauge's whole upstream watershed (`wet_snow_annual()`, cd's annual ERA5-Land layers, run of 2026-10-10), and the window's mean flow, as a log departure, is regressed on both over every year from 1950 with a value (1950–2025 in the site runs, 1950–2024 in the pilot). For the observed and extended series the departure is from the series' own 1981–2010 mean; the donor-carried series is the donors' departures from theirs. The specification was registered in `scripts/departure_snow.R`'s header at 81580b5, before any body code; nothing was chosen, and all 24 of the pilot's fits are reported. That script is retired too (`git show d4fae1f:scripts/departure_snow.R`; `scripts/departure_site_snow.R maxan` reproduces its report).

**More peak snow and a later melt mean more flow in the migration window, at every gauge and both Maxan series of the pilot. In the spawning window, snow explains almost nothing** (R² at most 0.07 in the pilot). The pilot's slopes are in [`chinook_sites.md`](chinook_sites.md), "Maxan by inverse distance: the pilot's record".

**Parity.** Averaged over 1981–2010, the per-year values match the snow normals behind the monthly shares over each of the pilot's watersheds within 0.9 mm of peak snow and 0.5 days of melt date. The normals' cache key reproduces from the bands read here, so the two rest on the same ERA5-Land values; the difference is the normals' bilinear resampling onto the 30-arcsecond grid. The 3,000 mm glacier cap bound in none of the three watersheds in any year.

**Limits.**

- A site's extended series is its donors' flow passed through a line fitted on a few years. Its snow slopes restate the donors' response and are not independent evidence about the site.
- ERA5-Land's cells are 0.1° across, about 70 km² here, so a 364 km² watershed is about five cells' worth.
- In the pilot's spawning window the intercepts, over all three models, sit at −0.31 to −0.46 log for the observed and extended series and at about −0.12 (−0.11 to −0.13) for the carried one. The departures are from the log of the arithmetic baseline mean, and for a skewed series a typical year falls below that.

## Open

- cd's baseline, anomaly and trend take one station per call (cd#95).
- HYDAT's approved end is a proxy (above).
- Joining a provincial station's recent days to the HYDAT gauge at its site, which would give two natural HYDAT gauges with a baseline their recent years, is #227.
