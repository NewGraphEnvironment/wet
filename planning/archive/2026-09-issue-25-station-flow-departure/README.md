## Outcome

wet now builds a per-station daily flow series from approved HYDAT through to yesterday, and summarises any daily series over month-day windows once per year in cd's long format, so departure and trend come from cd (#25).
- `wet_station_daily()` ports `ngr::ngr_hyd_q_daily()`. It joins HYDAT, then the water-temp-bc archive of ECCC provisional daily means, then real-time.
- `wet_window_stats()` and `wet_windows_calendar()` do the window summaries.
- `scripts/station_departure.R` runs the chain for Buck Creek (08EE013) and Bulkley nr Houston (08EE003).

Things learned along the way:
- Provisional winter flows are uncorrected ice readings.
- 08EE003 was a seasonal gauge until 2010.
- cd PR #94 takes one series per call, so the id-columns request became cd#95.

Four /code-check rounds kept finding one mechanism: the from/to window standing in for a source's whole record. They ended in a restructure (whole records in, one derivation, window applied last) and an enumeration of every set and extent in the diff. Verdicts: [`research/station_flow_departure.md`](../../../research/station_flow_departure.md).

## Measurement

- **Joined series, HYDAT 2026-07-17.** 08EE013 runs HYDAT 1973-01-01..2025-03-02, provisional ..2026-09-12, real-time ..yesterday; 08EE003 runs from 1930-09-09 with the same seams. There is no gap at either seam. With the previous HYDAT (2025-10-14), 08EE013 ended 2023-12-31 and left a 14-month hole.
- **HYDAT reader check.** It matches `tidyhydat::hy_daily_flows()` exactly on 08EE013 (18,193 days, max diff 5e-14). 43% of those days are ice-flagged (`B`), which is why `frac_ice` is carried.
- **Departures, 2023–2026.** In August, September, JJA and the example Chinook spawning window, both stations are 54–87% below the 1981–2010 mean every year. The Buck Creek trends since 2000 are:
  - JJA mean −2.1 %/yr (p 0.03);
  - September mean −2.6 %/yr (p 0.006);
  - spawning-window mean −1.8 %/yr (p 0.03).

  Cross-checked against HYDAT monthly means: August 2024 (0.212 m3/s) would rank second-lowest of the 29 baseline Augusts.
- **Wrong turns.**
  - The first run stopped because 08EE003 has no 1981–2010 complete years (seasonal gauge).
  - Buck Creek DJF 2025 read +200% until provisional winters were found to be ice artifacts (6.5–15 m3/s against approved winters of 0.2–2).
  - A HYDAT download reported exit 0 through a pipe while failing on a wrong argument name.

## Evidence

`data/checks/station_departure_report.txt`; plan and code reviews in `review-*.md` here.

Closed by: PR (see branch `25-flow-in-date-windows-at-hydrometric-stat`)
