# Task: Backlog move 4: Monthly error at the gauges: by region and season, routed PCIC's shape, and DFO's Fraser benchmark (#166)

Readers of the default source (routed PCIC, `pick`) get March–April about a tenth low and July–August about a sixth high, with only an article saying so; and we rebuild a monthly product DFO already built without knowing where ours is better. One tracked report scores the published months at the gauges by region, season and basin size (#6), attributes routed PCIC's seasonal shape with #67's checks, and benchmarks against DFO's Fraser threat-layer validation (#162), starting with August and September minimum flows.

## Decided at the gate (owner, 2026-11-17)

- **Output:** a tracked report, `scripts/gauge_monthly_compare.R` → `data/checks/gauge_monthly_compare_20260717.txt`,
  with findings in `research/monthly_error.md`. The segment-discharge article is not changed.
- **Region unit:** BC hydrologic zone (`cal$zone`, 29 zones with 2–23 gauges each; zones under 5 gauges
  marked), plus the routed report's six major basins (`routed_basin()`) as a roll-up.
- **#162:** both sources scored on Table F1's Mean columns. Routed PCIC is also scored on its Min columns, from
  fwapg#42's per-year sub-basin days for 1981–2010 (30 files from `fresh-bc` `fwapg/extras/`, about 4.3 GB,
  read from `WET_PCIC_YEARS`). The balance has no per-year values, so it has no Min score, and the report says
  so. #135's cache stays in move 5.
- **Already settled by the issue:** nothing goes to PCIC without the owner's approval of its exact text. fwapg
  work that places more outlets (fwapg#46) changes the gauge set, so the report names the fwapg commit and is
  rerun when that work lands.

## What exploration found (shapes the phases)

- `inst/vignette-data/monthly_values.rds$gauges` already holds, for 315 gauges × months 0–12: observed, the
  held-out balance (`wb_mm`) and routed PCIC (`routed_mm`), with zone, nesting, area class and lake. 290
  gauges have routed flow, and the bundle is on 5d50cc1 (#165). The new script rebuilds these values from
  the fit and fwapg, as `data-raw/monthly_vignette_data.R` does, and refuses to run unless they equal the
  bundle's. That one check ties the report and the article to the same numbers, with no refactor of
  `data-raw/`.
- **#67 check 1 (PCIC's own outlets, without the crosswalk's distribution):** `pcic.subbasin_daily.q_acc` is
  PCIC's accumulated routed flow at each outlet, in the published `pcic` schema and covered by
  `routed_daily_fingerprint()`. 245 of the 290 gauges have a placed outlet (`pcic.fwa_crosswalk`, flag NULL)
  on their own segment; 61 segments have several, and the one with the largest annual `q_acc` is taken (the
  downstream one). Each outlet's monthly flow is its days' `q_acc` weighted by `n_days`.
- **#67 check 2, reframed:** PCIC's network carries no drainage areas. Neither the `pcic` schema nor the
  hydromosaic `rivers` collection has them, and fwapg's `fwapg.pcic_subbasins` is a staging table wet does not
  read. "Gauge area against PCIC sub-basin area" therefore becomes two measures taken from published data.
  The first is how much of the gauge segment's routed flow is local runoff spread by FWA area,
  `q_local·share / q`, from `pcic.segment_weights` and the days, rather than flow routed from outlets above.
  The second is the gauge's catchment in VIC-GL cells (area over one 0.0625° cell at its latitude). Routed's
  per-gauge monthly NSE at gauges under 100 km² is set against both.
- **#67 check 3:** `cal$elev` (median upstream elevation, from the reduced bundle) and the observed peak month
  from `cal`'s shares, set against routed's per-gauge NSE by size class.
- **#162:** Table F1's gauge list is not published (only a map, Fig. F1), so the comparison uses our Fraser
  calibration gauges (08J/K/L/M, 92 gauges, 90 with routed flow), not DFO's 86. F1's statistics are taken
  across gauges in m³/s per month, season and year (R², MAE, MAPE as a fraction, NSE). "Min" is the lowest
  monthly mean over 1981–2010, so it needs per-year values. DFO's six dam corrections do not apply to us,
  because our gauges are natural-flow only.
- The per-year file check (each file held to its `pcic.series` row) lives inline in `scripts/departure_pcic.R`
  under #122's registered rule. It is written once more, as a function in `scripts/pcic_routed_lib.R`;
  `departure_pcic.R` is not changed (see Owed).
- `scripts/pcic_routed_lib.R` is not in `score_files_for()`, so adding to it stales no fit.

## Phase 1: Shared data and report frame

- [x] `scripts/gauge_monthly_compare.R`: header (usage, `WET_FWAPG_COMMIT`, `WET_PCIC_YEARS`, `WET_PG*`), and a
      refusal unless `R/` and `scripts/` are committed. It records the wet commit, fit, HYDAT release and
      province run.
- [x] Held-out months: from `shipped_heldout()` and `cvr$cv_share` under the shipped share spec and method,
      with `monthly_vignette_data.R`'s two refusals (stored observed values equal `cal`'s; the stored months,
      scored again, give the stored scores).
- [x] Routed months on the gauge segments from `routed_table`/`routed_where`, refused unless
      `routed_fingerprint()` and `routed_report_line()` match the tracked routed report (the
      `vd_routed_check()` pattern).
- [x] Parity guard: observed, balance and routed for months 0–12 at all 315 gauges `all.equal` the bundle's
      `gauges`, or the script stops.
- [x] Shared scorers in the script, each with a definition line in the report: per-gauge month ratio, median
      error, share within ±20 %, monthly NSE, and seasons (DJF, MAM, JJA, SON, plus #67's Mar–Apr and
      Jul–Aug).

## Phase 2: #6, bias by region and season

- [x] Report sections for both sources on the 290 shared gauges, with the balance alone on all 315. Each gives
      the median error by month × hydrologic zone (n per zone; zones under 5 gauges marked), by month × major
      basin, by season × size class (the four `area_class` bins), and by headwater against nested and lake
      against not.
- [x] Rescore #67's two tables on 5d50cc1: the Mar/Apr/Jul/Aug medians, gauge shares low and high, and the
      size table (monthly NSE, routed and balance). This replaces #67's "unmeasured on 5d50cc1".

## Phase 3: #67, routed PCIC's seasonal shape

- [x] Check 1: PCIC outlet months (`q_acc`) at the 245 gauges with an outlet on their segment, against
      observed and against routed segment months. It reports the Mar–Apr and Jul–Aug medians for outlet,
      segment and observed, and per-gauge outlet/segment agreement. If the outlet shows the same shape, the
      crosswalk is cleared and the attribution is PCIC's model.
- [x] Check 2: local-distributed fraction and VIC cells against routed NSE at the gauges under 100 km²
      (rank correlation, and the medians in tercile bins).
- [x] Check 3: routed NSE by size class against observed peak month and median elevation. The late-melt
      reading predicts that the small-basin losses are early-peaking, low-elevation gauges.
- [x] A verdict line per check in the report: theirs, ours or unresolved (CLAUDE.md, "attribute it").

## Phase 4: #162, DFO Fraser benchmark

- [x] Table F1's layout for the Fraser gauges with routed flow, in m³/s across gauges. Mean columns (R², MAE,
      MAPE, NSE by month, season and year) for routed and balance, with August and September first and DFO's
      published values beside them.
- [x] Per-year routed PCIC: `routed_years_check(conn, dir, years)` in `pcic_routed_lib.R` (each of the 30 files
      held to `pcic.series` in bytes, rows, sub-basins and both sums, on the run's `crosswalk_md5`, one fwapg
      commit), then `wet_routed_years()` on the Fraser gauge segments' weights for 1981–2010.
- [x] Parity: the mean over 1981–2010 of each routed per-year month equals the published 1981–2010 month,
      within a stated tolerance (daily clamping and rounding make it inexact), with the largest difference
      reported.
- [x] Min columns: per gauge, the lowest monthly mean of each month over the gauge's complete years in
      1981–2010 (HYDAT, years from `wet_station_select()`), against routed per-year over the same years.
      Scored like F1's Min, August and September first. The balance's Min line reads "not available".

## Phase 4b: Plan review folded in (findings.md, "Plan review")

- [x] Register the corrected rules in the script header before rerunning (check 1 by tree agreement; checks 2–3 on the share-NSE gap, margin 0.05; per-year bin parity and segment tolerance)
- [x] Check 1 by tree agreement; checks 2–3 on share NSE; drop VIC-GL cells; size table gains share NSE
- [x] Parity strict (identical, month 0 1e-12, fit md5s); `vd_commit()` guard; `elev` named the upstream mean
- [x] `routed_years_check()` adds bin parity against the run's `pcic.subbasin_daily`
- [x] #162: DFO's per-cell Min caveat, log R² and per-gauge median APE, DFO as context
- [x] Lint the new script to the repo's level

## Phase 5: Record

- [x] Run the script twice from a frozen copy (`data/logs/166/`), check the two reports are byte-identical, and
      commit the report.
- [x] `research/monthly_error.md` (topic file, provenance header) with one finding per issue, and a row in
      `research/README.md`. Add a line in CLAUDE.md's Architecture for the script. Add Iacarella et al. to the
      research file's citation (it is already in Zotero).
- [x] Issue bodies: #6 (results, ticked), #67 (tables updated to 5d50cc1, the three boxes ticked with verdicts,
      the draft to PCIC revised and marked **not sent**), #162 (results and the Min finding), #166.

## Owed at the end (reported, done after merge)

- [ ] The owner approves, or rewrites, #67's draft to PCIC before anything is posted. Nothing is sent by this work.
- [ ] Tick move 4 in `planning/backlog.md`.
- [ ] A follow-up issue: move `scripts/departure_pcic.R`'s per-year file check onto `routed_years_check()` at
      its next rerun, so the check exists once.

## Validation

- [ ] Tests pass (`devtools::test()`; no `R/` change is planned)
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

Verification: the parity guard against the bundle (Phase 1); fingerprints held to the tracked routed and daily
reports; each per-year file held to `pcic.series`, with the per-year mean against the published month (Phase
4); a byte-identical report on a second run; `lintr` on the new script and lib.
