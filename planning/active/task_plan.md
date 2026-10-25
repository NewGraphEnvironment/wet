# PARKED: baseline only (2026-10-25)

Approved at the plan gate 2026-10-24 and parked by the user on 2026-10-25. The approval covered this baseline; the run-to-PR mandate starts at the resume instruction (`progress.md`, Resume).

# Task: Maxan Creek Chinook pilot: extend 08EE018's window flows from its neighbours and score donor-carried departures, HYDAT only (#120)

Component 1 of #118. Every flow wet publishes at a segment is a 1981–2010 normal, so a question about change over time can be answered only at a gauge, and Maxan Creek's gauge (08EE018, 363 km²) ran for five years, 1975–1979. The pilot (a) extends Maxan's Chinook-window flows across 1930–2025 from its long-record neighbours with an error per year, (b) carries donor gauges' year-to-year departures onto an ungauged target and scores that at every short-record gauge in the region, Maxan included, and (c) frames the before/after answer. Nothing is published; the result is a report, two functions, and a research section.

## What exploration found

- `wet_window_stats()` (`R/wet_window_stats.R`) already has `mean`, `min7` and `cov_day` (day by which half the window's volume has passed, complete window-years only); no new statistic is needed. Output is cd's long format.
- `wet_donor_mean(x, x_donor, y, k)` (`R/wet_donor_mean.R`) is the inverse-distance donor weighting shared by #70 and #102; reused as is.
- `cd` 0.5.0: `cd_baseline(x, baseline_years)`, `cd_anomaly(x, baseline, cap_pct = 200)` (pct_normal is clamped to ±200 by default; the pilot scores its own uncapped log departures and uses cd only for the reported % of normal), `cd_trend(x, trend_start)`.
- `scripts/station_departure.R` is the #25 path end to end (daily → windows → cd); `scripts/wb_shape_daily.R`'s header is the pre-registered-rule pattern to copy.
- `wet:::wet_nse()` (`R/wet_flow_validate.R:76`) is the score helper.
- HYDAT 20260717, measured 2026-10-24 (box lon −128.8…−125.0, lat 53.6…55.8: Bulkley, Morice, Babine, Kispiox, Zymoetz, Kitimat, Nechako headwaters): 94 BC gauges, 58 with ≥3 complete migration-window years (≥80 % of the 93 days), 53 of them natural (`REGULATED = 0`), 13 with ≤10 years (the short-record test set, 08EE018 among them). Long natural records with pre-1981 years: 08EE004 Quick (94 yrs, 50 pre-81), 08EF001 Usk (92, 48), 08JB002 Stellako (77, 32), 08ED002 Morice (63, 19), 08EE008 Goathorn (63, 19), 08EB004 Kispiox (60, 16), 08EE013 Buck (51, 8), 08EE020 Telkwa (49, 5), 08EE003 Houston (44, 12). Table saved in the session scratchpad; Phase 2 regenerates it into the report.
- 08EE013 is a shipped calibration gauge; 08EE003 and 08EE018 are not (`data/wb/stations_20260717.rds`), so nothing here touches the fit.

## Decided at the gate (user, 2026-10-24)

- **Statistics:** `mean`, `min7`, `cov_day` per window; `max` reported, not scored.
- **Periods:** 1981–2010 baseline (as #25); the before/after is the mean departure pre-1981 against 2011–2025; `cd_trend()` over the whole extended record.
- **Scale:** departures carried as log ratios, `log(value / baseline mean)`, reported as % of normal.
- **Sources:** HYDAT only, release 20260717 (`WET_HYDAT_RELEASE`); no provisional or real-time days.
- **Windows:** the `CH` rows of `inst/vignette-data/life_history_bulk.csv`: migration 05-01…08-01, spawning 08-01…09-15.

Mechanism, picked here (conventional defaults, not gate questions):

- **Pool:** natural (`REGULATED = 0`) BC HYDAT gauges in the box lon −128.8…−125.0, lat 53.6…55.8 (the issue's "Bulkley and neighbouring watershed groups"; every count below was measured on it; review item 7). Two pools from it, named in the header: the **extension pool** (≥30 complete years of the window and at least one run of 5 consecutive complete years) and the **departure pool** (≥10 complete window-years inside 1981–2010, so `cd_baseline()` is defined). A gauge with NA drainage area or coordinates is excluded and counted. **k = 5** nearest in predictor space (easting, northing in km from EPSG:3005, log drainage area; each scaled by the pool SD), as #70/#102; sensitivities k = 3 and 8, reported.
- **Donor availability per year** (review item 1): extension donors are chosen among pool gauges that cover the target's observed years; for carried departures, a donor absent in a year is dropped for that year and the remaining weights renormalised, a year with no donor present is NA. `wet_departure_carry()` does this itself; `wet_donor_mean()`'s contract, shared with #70 and #102, is unchanged.
- **Predictors come from a station table** in `wet_station_select()`'s shape (`station_number, lon, lat, drainage_area_gross_km2`), which both functions take beside the `wet_window_stats()` output (review item 10).
- **Nesting:** Houston and Quick contain Maxan. A leak-free sensitivity removes a held-out gauge's upstream and downstream pool gauges, using fwapg (`wet_station_snap()`, `wet:::wet_fwa_upstream()`) when `PG*` env vars reach a database; otherwise reported as not run. It decides nothing.

## The rule (registered in `scripts/departure_pilot.R`'s header, Phase 1, before any candidate is coded)

Two questions, one rule each, both scored on the migration-window `mean` in log space with `wet:::wet_nse()`; the other statistics and the spawning window are reported under the same rule but decide nothing. `cov_day` is scored as an absolute difference in days, not a log; a window-year whose value is ≤ 0 is dropped from a log score and counted; `cov_day` exists only for 100 %-complete window-years, so its pseudo-records are its own (review item 9). NSE 0 is climatology (no departure), the margin the issue asks about.

1. **Record extension.** Candidates: (a) OLS of the target's log window value on the nearest donor's log value (n − 2 df); (b) MOVE.1 (line of organic correlation) on the nearest donor in log space; (c) ratio of means on the nearest donor (the incumbent). Reported sensitivities, unable to ship: multi-donor OLS on min(k, n − 2) donors; (d) day-by-day OLS of log daily flow on the nearest donor's same-day log flow, the window statistic then taken from the extended days (the issue's "day by day"). Test: at every extension-pool gauge, the non-overlapping (tiled) runs of 5 consecutive complete years are pseudo-short records; a gauge with no such run is dropped and counted; each is extended from the other pool gauges and scored on its **held-out years only**, over the years every candidate has a value for. Per gauge, the median NSE over its pseudo-records; the median over gauges decides. The candidate with the highest median ships for Maxan if it beats (c) by ≥ 0.01 (1e-9 floating-point allowance, #16's margin); otherwise (c) ships. Intervals at one nominal level, 90 %: OLS's prediction interval; for (b) and (c), the 5th–95th percentiles of the **other** gauges' pseudo-record residuals (leave-gauge-out); coverage on held-out years reported for all three. At Maxan, leave-one-year-out over its five years is reported beside the pool result.
2. **Donor-carried departures.** Leave-one-gauge-out at every departure-pool gauge: the k-nearest donors' log departures (from each donor's own 1981–2010 baseline), `wet_donor_mean()`-weighted with the per-year availability rule, against the held-out gauge's observed series. Scored over the years both have, **both series centred on their overlap mean in log space**, so no target baseline is needed and a short-record gauge is scored the same way (review item 3). Per-gauge NSE; the median over gauges is the headline number, with the short-record gauges (≤10 years, 08EE018 among them) scored separately from the departure pool. No ship/no-ship: the pilot's question is "does this carry change", and the report states the median with its quartiles. The method is called **usable** for #122's competition if the departure-pool median NSE ≥ 0.5; that threshold is set here so #122 inherits it rather than picking it after seeing the number.

What the script refuses: a target or donor with fewer than 3 complete window years; a HYDAT release other than the one named; an extension pool with fewer than 15 gauges holding a pseudo-record (the box has 21 natural gauges with ≥30 migration years, so 20 was fragile; review item 5); a report that differs on rerun (no timestamp written).

## Phase 1: Register the rule

- [x] Write `scripts/departure_pilot.R` as header only: usage, the gate decisions, the two pools and k, the per-year donor availability rule, both candidate sets with their sensitivities, both rules as written above (held-out years, centred overlap, 90 % intervals from other gauges, cov_day in days, ≤ 0 dropped), what it refuses, outputs. No candidate code in the file. Review items 1–6 and 9 are all settled in this header, not after (item 13).
- [x] Commit it alone (`Register the departure pilot's rule before any candidate (#120)`), and record its SHA in `findings.md`.

## Phase 2: Window series and the pool

- [x] In the script: read the pool from HYDAT 20260717 (`wet_station_select()`-style regulation and province filters, distance to the target from `STATIONS` lat/lon), `wet_station_daily(sources = "hydat")`, `wet_window_stats()` on the two windows with `stats = c("mean", "min7", "max", "cov_day")`.
- [x] Report section 1: the pool table (station, name, km², complete years per window, first, last, pre-1981, 2011–2025), and the 13 short-record gauges flagged.
- [x] Assert the three pilot gauges' counts against the issue's table (5 / 43 or 44 / 51; the issue counted 43 for 08EE003 and this probe 44 — the report states which definition each count uses and fixes one).

## Phase 3: Record extension, `wet_window_extend()`

- [ ] `R/wet_window_extend.R`: takes `wet_window_stats()` output for a target and donors plus a station table, `method = c("ols", "move1", "ratio")`, `k`, `level = 0.9`; picks donors among those covering the target's observed years; returns the target's per-year value, lower and upper bound, `donor` and `source` (`observed` / `extended`) in the same long format. Exported, roxygen, runnable `@examples` on synthetic series.
- [ ] `tests/testthat/test-wet_window_extend.R`: recovers a known log-linear relation exactly; MOVE.1 preserves the target's variance where OLS shrinks it; ratio of means on a fixture where it differs from the mean of ratios; refuses < 3 overlapping years; a donor not covering the observed years is not chosen; an observed year is returned as observed, not extended; the OLS interval half-width doubles when the residual SD doubles.
- [ ] Script: the pseudo-short-record test over the pool, the rule applied, sensitivities (k = 3, 8; the spawning window; `min7`, `cov_day`), interval coverage. Report section 2.

## Phase 4: Donor-carried departures, `wet_departure_carry()`

- [ ] `R/wet_departure_carry.R`: per target, the log departures of the k nearest donors from their own 1981–2010 baselines, `wet_donor_mean()`'s weights renormalised per year over the donors present; returns per-year `anomaly` (log, and % of normal for cd), the donors and weights used that year, and `value` only where the target has its own baseline (≥10 baseline years). Exported, roxygen, `@examples`.
- [ ] `tests/testthat/test-wet_departure_carry.R`: a year where only some donors exist uses the present ones with renormalised weights; a year no donor has is NA; a target without a baseline gets `anomaly` and no `value`; refuses a donor with fewer than 10 baseline years; the % of normal equals `exp(anomaly) − 1` times 100.
- [ ] Script: leave-one-gauge-out at the departure pool, centred on the overlap; the short-record set scored from the full pool; the leak-free sensitivity when a database is reachable; medians and quartiles by window and statistic. Report section 3.

## Phase 5: The Maxan answer, report and research

- [ ] Script: Maxan's extended series from the nearest covering donor's first year (Houston or Quick, 1931) to 2025 for each statistic and window with intervals; the carried route as departure only, and the two routes compared as departures at 1975–1979 and over the record; pre-1981 against 2011–2025 mean departure with a difference and an interval that resamples years and, through the extension interval, each year's residual (the limit stated: pre-1981 rests on two donors); `cd_trend()` from the record start and from 1981. Report section 4, `data/checks/departure_pilot_20260717.txt`, tracked, byte-identical on rerun.
- [ ] `research/station_flow_departure.md`: a dated section "Departures at an ungauged site: the Maxan pilot (#120)" with the rule, the pool, the three medians, what shipped and the Maxan numbers; the README row updated.
- [ ] `_pkgdown.yml` reference index gains both functions; `pkgdown::check_pkgdown()` clean.
- [ ] Issue #120 body: an `## Outcome` section with the numbers, as #102's has.

## Owed at the end (reported, done after merge)

- [ ] Tick #120 in #118's component task list.

## Validation

- [ ] Tests pass (`devtools::test()`, grep for FAIL/ERROR in the same call)
- [ ] `lintr::lint_package()` clean on the new files
- [ ] `/code-check branch` clean before the PR
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion, with Measurement and Evidence sections

How each change is proved:

- **Rule precedes candidates:** `git log --format=%h --reverse -- scripts/departure_pilot.R | head -1` is Phase 1's commit, and `git show <sha>:scripts/departure_pilot.R | grep -c "<-"` is 0 beyond the header's usage lines.
- **Report reproduces:** run the script twice, `cmp` the two reports.
- **Guards fire:** restore each refusal's condition (a target with 2 window years; `WET_HYDAT_RELEASE=20251014`) and see the script stop with its message, recorded in `findings.md` as a mutation table.
- **Functions:** tests above; `R CMD check`-style `devtools::check()` for the two new exports before the PR.
- **Numbers in prose:** every figure quoted in the research section is read from the tracked report, not retyped from the console.
