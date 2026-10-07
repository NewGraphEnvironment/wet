# Findings — Refit the open water balance on HYDAT 2026-07-17, and settle the pooled-zone adjustment (#43)

## Issue context

*As filed. Superseded where it says the fit gains new years, the run key carries the release, a new key, `wb_province.R` reruns, or a "third variant": see the pre-registered rules and amendments below.*

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

## Rule amendments (2026-10-06, after the plan review, before any scoring)

The plan review (`review-plan.md`) found the rules above underspecified in ways that would decide the outcome. Nothing has been scored. These amendments supersede the matching parts above.

**Pooled-zone test.**
1. **Independence.** Each test gauge is predicted from a fit that leaves out the calibration gauges in its WSC sub-sub-drainage, the same blocks as the headline CV. A fit on all calibration gauges would let co-located twins (08GE001/08GE002, 08MF003/08MF068 and others) vouch for test gauges. That leak favours "other", since "none" fits nothing in the pooled zones.
2. **Screen.** Test gauges whose HYDAT name contains CHANNEL, OVERFLOW or DIVERSION are excluded. These gauge part of a flow over the whole basin's area. Observed runoff must be at least 10 mm, the `min_obs` of `wet_flow_validate()`, the same floor as the headline.
3. **Decision gauges.** The decision is made on test gauges whose dominant zone (largest share) is pooled in the fit that predicts them, since that is the only place the variants differ beyond a slight shift in own-zone coefficients. MAE on all test gauges is reported as context.
4. **Power.** With fewer than 10 decision gauges the test is uninformative: the nested choice stays and the caveat stays, softened to name the test. Otherwise the 1.0-point tie band applies to the decision gauges. A paired bootstrap 95 % interval of the MAE difference (2,000 resamples, seed 43) is reported as context, not as part of the rule.
5. **Caveat.** It is retired only when the test is informative (≥ 10 decision gauges).
6. **A failed gate goes back to the user.** If the fixed variant turns the headwater gate to FAIL on the shipped fit (`keep_adjust` FALSE, so raw P − AET would ship), nothing ships until the user decides. #15 chose cfu with the pooled variant chosen inside each fold, so a gate flip also reopens the AET carry.
7. **#15 reproduction.** `wb_aet_compare.R` runs only for a fit without `pooled_variant.txt`, and refuses otherwise.

10. **Zones without calibration gauges in the fold** (added after code-check round 1, before any scoring). A zone whose calibration gauges all sit in the held-out sub-sub-drainage is treated the way the headline CV treats it: it counts as pooled in that fit, so "other" gives it the pooled level and "none" gives it nothing. Only zones no calibration gauge touches at all get no adjustment. This keeps the test consistent with `predict_cv()`.

**Acceptance.**
8. MAE is the mean |`err_pct`| from `cv_v$stations`, NAs dropped (observed < 10 mm). Each fit is scored against its own release's observed runoff, so a revised flow moves both target and training. The report says so.
9. The report also gives each fit's headwater gate (adjusted against raw). If the 2026-07-17 fit passes the 1.0-point rule but its gate flips to FAIL, nothing ships until the user decides.

**Phase 3 proof, restated.** `code_md5` changes by design, because the scoring scripts and the stations file changed. The proof therefore has two parts:
- **Code-only:** the new pipeline on the old `stations` and `monthly` gives `identical()` annual objects: `fits.rds` (`wb`, `keep_adjust`, `calibration`, `aet`) and each `cv_aet-*.rds` (`cv_ann`, `raw`, `ship_variant`). The monthly-share metrics (`share`, the `nse_*` columns of `cv_v` and `plain`) match within `all.equal(tolerance = 1e-12)`. Fields added for #43 and `code_md5` are ignored. The #15 reproduction also passes.
  - Measured locally before the m4 run (smoke test, cfu): `cv_ann`, `raw`, stations, `keep_adjust` and `ship_variant` identical. `cv_v` differs only in `nse_month`/`nse_share`, by at most 6e-14: floating-point reassociation in the monthly share path, not a change of method. The report text is identical apart from the added HYDAT line.
- **Rebuild:** `wb_stations.R` on 2025-10-14 gives `identical()` `stations` and `monthly`. If it does not, fwapg on m4 has moved since 2026-09-26, and that is reported, not hidden.

## Phase 3 outcome (m4, 2026-10-06; `data/logs/43/` on m4)

- **Rebuild proof:** `wb_stations.R` on HYDAT 2025-10-14 gives `identical()` `stations`, `monthly` and `years`, so fwapg has not moved for these snaps.
- **Code-only proof:**
  - `fits.rds` `wb`, `keep_adjust`, `calibration` and `aet` are identical, and `share` matches within 1e-12.
  - For all ten AETs, `cv_ann`, `raw` and `ship_variant` are identical, and `cv_v` and `plain` match within 1e-12.
  - #15 reproduced (cfu); `wb_aet_compare.txt` and `wb_output.txt` are byte-identical; 24 of 24 output parquets are equal.
  - Tracked reports change only by the added HYDAT release line, plus the test-set section in `stations_wb.txt`.

## Phase 4 outcome: the pre-registered stop fired (amendment 9)

- **HYDAT 2026-07-17 snaps 336 stations, against 309.** Revised gross drainage areas (rejected 43 → 16) give 315 calibration gauges: 29 new and 4 dropped (08GA065 08HA068 08KD001 08LF080).
- **Acceptance passes.** Headwater blocked-CV MAE on the 209 headwater gauges common to both: 30.90 against 31.18 (−0.28).
- **The headwater gate FAILS.** Adjusted 30.716 against raw 30.688, so `keep_adjust` is FALSE and raw P − AET would ship.

| | headwater adj | headwater raw | all adj | all raw | n |
|---|---|---|---|---|---|
| 2025-10-14 | 31.16 | 31.59 | 27.74 | 28.58 | 290 |
| 2026-07-17 | 30.72 | 30.69 | 27.51 | 28.45 | 315 |

- **The adjustment was marginal on headwater gauges in the old fit too.** On the 209 common headwater gauges, the old fit's raw (30.67) already beat its adjusted (31.18). The old gate passed through the headwater gauges this release drops.
- **Where the adjustment helps:** nested and larger rivers (all gauges, about 0.9 points). On the 29 new gauges: adjusted 29.8, raw 30.5.
- **Next:** the pooled-zone test waits. Under raw P − AET there are no pooled zones to settle. Decision to the user.

**Decision (user, 2026-10-06): ship the 2026-07-17 fit as raw P − AET (cfu), the zone adjustment dropped by #11's headwater gate as written.**
- Headwater error: 30.7 % (30.69 on the common gauges, against the old shipped 31.18).
- All gauges: 28.4 %, about 0.9 points worse than adjusted, on nested and larger rivers.
- With no adjustment there are no pooled zones, so the pooled-zone test is not run: moot, not skipped. The "mildly optimistic" caveat goes with the adjustment.
- #44 (zone-boundary blending) loses its premise while the adjustment is off.
- The vignette's skill now reads `raw_v` when `keep_adjust` is FALSE (`data-raw/segment_vignette_data.R`).

## Errors Encountered

| Error | Resolution |
|-------|------------|
