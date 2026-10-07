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

## Errors Encountered

| Error | Resolution |
|-------|------------|
