## Outcome

Backlog move 4: one report, `scripts/gauge_monthly_compare.R` → `data/checks/gauge_monthly_compare_20260717.txt`, answers #6, #67 and #162 at the calibration gauges. It rebuilds the segment-discharge article's gauge table from the fit and fwapg, refuses unless the table equals the bundle value by value, and scores both published sources by month, season, hydrologic zone, major basin and basin size. It also runs #67's three checks under rules registered before their numbers, and sets the Fraser gauges beside DFO's Table F1 as context. The Min columns are routed year by year from fwapg#42's per-year files, held to `pcic.series` and to the run's sub-basin days by a new `routed_years_check()`.

What was learned:
- Routed PCIC's spring-low, summer-high shape is in PCIC's own outflow.
- Its small-basin loss is mostly annual volume, not shape.
- Neither PCIC's resolution nor a late melt reached its rule as the cause of the shape loss that remains.

Two lessons about the method:
- **The plan review earned its cost.** It caught a check that compared a number with itself: every outlet segment carries its outlet's flow, with share 1. It also caught that monthly NSE at small basins mostly scores volume.
- **Code review found a recurring defect class.** Labels and bounds drifted from the registered rules, because each fix edited header, code and report together, and they were then checked against each other. It ended only when the header kept the 520b9ca text byte for byte and listed every later amendment apart. Findings: `research/monthly_error.md`.

## Measurement

On fwapg 5d50cc1's routed 1981–2010 run, the shipped fit (HYDAT 2026-07-17), 283 shared gauges (315 for the balance):

- **Routed PCIC, median error by season:** −16.7 % in March–May and +17.3 % in July–August (by month: March −11.1, April −12.2, July +19.7, August +12.3 %). The 7c30f58 numbers in #67 were −11, −12, +20 and +13 % at 279 gauges, so the Nechako rebuild did not move the shape. The balance's worst month is April (+10.4 %).
- **By basin:** routed's March–April is −23.2 % in the Fraser and its July–August +31.6 % in the Columbia. The balance's largest zone errors are Southern Thompson Plateau (+47 to +62 % by season) and Eastern Vancouver Island (+69 % in July–August).
- **Volume against shape, under 100 km²:** routed monthly NSE 0.44 against balance 0.64, but share NSE 0.80 against 0.91. Monthly NSE tracks the absolute annual error (Spearman −0.77; share NSE −0.19). This changed #67's reading that "its monthly shape is where it loses".
- **Check 1:**
  - The first version gave outlet and segment identical to 0.39 points: circular, retracted on the plan review's probe (share = 1 at all 245 outlet segments).
  - Redone by tree agreement: 242 gauges where the FWA and PCIC networks agree upstream show −12.6 % in March–April and +16.7 % in July–August → theirs.
- **Check 2:** the share-NSE gap is 0.02 where the gauge's months are its sub-basin's, against 0.12 at the rest. Unresolved, with the gap the other way. A first version on monthly NSE, with VIC-GL cells, was dropped: it was volume-dominated, and cells is area rescaled.
- **Check 3:** gap 0.10 at early-peaking against 0.09 → unresolved.
- **#162, 87 shared Fraser gauges:**
  - routed's August Mean R² 0.98, balance 0.91, DFO 0.95;
  - routed's lowest August and September R² 0.97 and 0.98, against DFO's 0.35 and 0.34; MAPE min 2.16 and 2.65, against 0.85 and 0.79;
  - per gauge, routed's lowest August is more than half again the observed at 37 % of gauges.
- **Parity:**
  - the per-year files' bins equal `pcic.subbasin_daily` at 261 sub-basins and 95,526 bins (worst 0.34 of the float32 bound);
  - the years average to the published months within 3.3 × 10⁻⁴ relative;
  - HYDAT's years average to the normals within 5.9 × 10⁻¹⁶;
  - DFO's 102 hard-coded Table F1 values equal the paper's text.

Review: a plan review, then 3 code-check rounds (12 findings, all fixed; rounds 2 and 3 found defects inside the previous round's fixes), ended by an enumeration against the 520b9ca header (`findings.md`). Four reviewer agents in all.

## Evidence

`data/logs/166/` in the main checkout:
- `report_run*` and `run*.log`: two runs at each of ba29835, 7a8a5ac, 613b296, 4293f2b and 2ef9254, each pair byte-identical. Run 2's first attempt and two at 7a8a5ac were refused by the clean-tree guard, as designed.
- `years_download.*`: the 30 per-year files from `fresh-bc` `fwapg/extras/`, into gitignored `data/pcic_years/PNWNAmet_historical/`.

## Owed

- The owner approves, or rewrites, #67's draft to PCIC before anything is posted. Nothing is sent by this work.
- Tick move 4 in `planning/backlog.md`.
- A follow-up issue: move `scripts/departure_pcic.R`'s per-year file check onto `routed_years_check()` at its next rerun, so the check exists once.

Closed by: PR (opened after this archive)
