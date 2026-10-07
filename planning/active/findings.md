# Findings — Refit the open water balance on HYDAT 2026-07-17, and settle the pooled-zone adjustment (#43)

## Issue context

**If we do it:** the shipped water balance is fit on a HYDAT release anyone can download today. It gains the years and gauges added since 2025-10-14. Its pooled-zone adjustment is settled by a rule written before scoring, so the "mildly optimistic" caveat on every skill figure goes. It becomes the baseline the tuning experiments score against. **If we never do:** the fit stays pinned to a release ECCC no longer lists, so nobody can rebuild it from public data. The pooled-zone choice stays a decision made after seeing a result.

## Problem

- The open water balance (#11, #15) is fit on HYDAT 2025-10-14. ECCC no longer lists that release. The newest release is 2026-07-17, and tidyhydat's default copy on m1 already is that one.
- `wet_hydat_path()` resolves to tidyhydat's default directory. So a plain `scripts/wb_stations.R` run would quietly fit on whichever release that directory holds.
- Zones with fewer than 8 dominant gauges are pooled. The pre-set specification gave them one fitted level and failed the gate. The "none" variant that passes was offered after that result (`research/water_balance_method.md` §0, "Pooled zones, and an open decision"). Every skill figure since carries the caveat.

## Proposed Solution

One plan, five phases. The shared cost is a full province run plus blocked CV, paid once.

1. **Pin and pre-register.**
   - HYDAT 2026-07-17 goes to `data/hydat/20260717/`, passed explicitly; the run key carries the release.
   - Before any scoring, write and commit two rules:
     - **Acceptance:** the refit ships unless headwater blocked-CV MAE is more than *x* points worse than the 2025-10-14 fit on the gauges common to both.
     - **Pooled zones:** a choice among "one level", "none" and any third variant, with the variants named before scoring.
2. **Stations.** Run `scripts/wb_stations.R` on the new release under a new key. Report gauges added, dropped and changed (record length, area ratio).
3. **Province and CV.** Run `wb_province.R` and `wb_validate.R` for the shipped AET (cfu). AET selection (#15, #18) is not reopened. This needs the full `data/wb/` inputs: m4 holds them, or `wb_inputs.R` rebuilds them.
4. **Pooled zones.** Score the variants under the phase-1 rule and record the outcome, whichever way it goes.
5. **Ship.**
   - `wb_output.R`, then `data-raw/segment_vignette_data.R`, the vignette and `research/water_balance_method.md`.
   - Keep the 2025-10-14 fit and its key. `wb_aet_compare.R`'s reproduction of #15 stays tied to that key, so it does not gate the new fit.

Order: first. Blocks #44 and #45, which score against this fit.

Relates to #11, #15

## Pre-registered rules (2026-10-06, committed before any run)

Decided at the plan gate with the user. Written before Phase 3 runs anything.

**Window.** Station selection stays 1981–2010 (`scripts/wb_stations.R`). HYDAT 2026-07-17 changes the gauge set only through revisions inside that window: backfilled months, regulation flags, areas. No new years.

**AET.** cfu (CGIAR floored by Fu–Budyko, #15) is carried from the 2025-10-14 fit to the 2026-07-17 fit. AET is not re-picked: `wb_aet_compare.R` stays the reproduction check for the 2025-10-14 fit only.

**Acceptance (does the 2026-07-17 fit ship?).**
- Metric: blocked-CV MAE (%) on annual runoff with the pooled variant chosen inside each fold (`predict_cv(cal, cal$fold)`, as `wb_validate.R` computes `cv_v`).
- Gauges: calibration gauges common to both fits and headwater in both.
- Rule: the 2026-07-17 fit ships unless its MAE exceeds the 2025-10-14 fit's by more than 1.0 point. Otherwise the 2025-10-14 fit stays shipped and the outcome is reported.

**Pooled zones (settled on gauges the fit never sees).**
- **Test gauges:** natural BC stations with 1–9 complete years in 1981–2010, the same complete-year definition as `wet_station_select()`. Each must be snapped within ±10 % of its area, have a basin at least 95 % in BC and on the grid (`min_frac`), have an observed annual runoff above 0, and not be a calibration gauge. A zone the fit has not seen gets no adjustment, as in `wb_output.R`.
- **Fits:** `wet_wb_fit()` on all calibration gauges of the shipped fit, with `pooled_adjust = "other"` and `"none"`, AET cfu. Predictions via `wet_wb_adjust()`, floored at 0 as shipped.
- **Metric:** MAE (%) on annual runoff over all test gauges.
- **Rule:**
  - If the two MAEs are within 1.0 point, the variant `choose_variant(cal)` picks over all calibration gauges is fixed.
  - Otherwise the variant with the lower test MAE is fixed.
  - The fixed variant is written to the fit directory (`pooled_variant.txt`). From then on, every fold of the headline blocked CV and the shipped fit use that variant, with no further nested selection.
- **Caveat:** the "mildly optimistic" caveat is retired whichever way the rule falls. The variant is then chosen on gauges outside the calibration set, so the blocked CV on calibration gauges no longer contains a choice made after seeing them. The test-gauge MAE of the fixed variant is reported beside it.
- **Recorded either way:** both MAEs, the n of test gauges, the fixed variant, and the raw P − AET MAE on the test gauges for context.

## Errors Encountered

| Error | Resolution |
|-------|------------|
