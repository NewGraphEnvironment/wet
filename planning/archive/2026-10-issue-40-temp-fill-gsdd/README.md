## Outcome

Added `wet_temp_fill()` and `wet_temp_gsdd()` (#40). `wet_temp_fill()` fills gaps in daily water temperature at stations. It writes the series as open-loop air2stream (S, fitted by least squares on `cd::cd_extract_daily()` air temperature) plus an AR(1) departure in a Kalman filter and smoother. The smoother carries each station's observations across a gap from both ends, and adds the departure error its pool's peers saw that day. `wet_temp_gsdd()` wraps `gsdd::gsdd()` into `wet_window_stats()`'s long format, with `frac_filled`.

The planned design, the air2stream recursion itself as the Kalman state, was dropped after a real-data spike: its one-step likelihood picks too little a3, so it drifts over a long gap (the plan review predicted this). Code-check took five rounds:
- Round 3 named the mechanism behind rounds 1–2: each station assumed one complete calendar of observed rows. It enumerated where that assumption reaches.
- Round 4 found a defect inside round 3's air-hole fix.
- Round 5 found that the validation script re-derived the package's GSDD rule and interval instead of calling them. The first run's PASS rested on that error.

Settled findings: `research/station_temperature_fill.md`.

## Measurement

**08E spike** (18 stations; mean daily RMSE, °C):

| form | 30-day gap | whole season |
|---|---|---|
| one Kalman state on the recursion | 0.80 | 1.28 |
| open-loop | 1.45 | 1.27 |
| shipped `S + u` | 0.77 | 0.99 |

**Province validation:** 999 truth station-years at 257 stations, 3,763 holdouts. Fill against open-loop, daily RMSE in °C:

| holdout | fill | open-loop |
|---|---|---|
| 7 days | 0.48 | 1.31 |
| 30 days | 0.76 | 1.43 |
| shoulders | 0.84 | 1.14 |
| whole season | 1.12 | 1.29 |

95 % coverage was 0.89–0.94.

The pre-registered rule (`findings.md`) **failed on criterion 3**: whole-season GSDD mean absolute error was 130.4 against 128.7 °C-days. Criteria 1 and 2 passed (median −0.17 °C, better in 83 % of station-years). The fill ships with that limit documented, untuned.

The first run reported PASS. Its GSDD came from `gsdd_vctr(complete = FALSE)`, which made the truth NA at 403 of 897 station-years, and its means were unpaired. Kept here as the wrong turn.

**Skeena parity:** all 17 site means fall inside `hill_etal2025Spatialstream`'s 95 % intervals (r = 0.997, mean |difference| 23 °C-days). The GSDD rule moves values by +10 °C-days and the weekly step by −0.3. Of the year means, 2024 is +191 and attributed to theirs: 95 % of our 2024 days are observed.

**Runtime:** each held-out preparation took 17 s because it re-filtered the 2.6M-row air table. Splitting air per station made it 1.3 s, and the province validation runs in 16 min on 8 workers.

## Evidence

- `data/checks/temp_fill_validate.txt`
- `data/checks/temp_fill_skeena_parity.txt`
- `data/temp_fill/*_run.log` (local, gitignored)

Closed by: PR for branch `40-daily-water-temperature-with-gaps-filled`
