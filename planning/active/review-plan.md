# Plan review — #11 (Plan agent, 2026-09-26)

Findings as returned, most severe first. Each carries its disposition at the end.

1. **Blocker: fitting on catchment means but applying cell-wise.**
   - Cell-wise application only reproduces the catchment fit when every predictor is an upstream area-weighted mean of a cell layer.
   - Drainage area cannot be applied cell-wise.
   - Catchments that straddle zones mix coefficients.
   - Fix: a zone-interacted design built from `wet_upstream_sums()`, one denominator throughout, and a floor only at the output.
   - → **Adopted.**
2. **Blocker: the nesting-leak test cannot pass with folds by sub-sub-drainage.** 08MF005 has upstream gauges in almost every 08x block.
   - → **Adopted as "measure and report"**: leak exposure per held-out station (share of its basin gauged in training), with headwater-only skill as the headline.
3. **Blocker: model selection runs on the same CV it reports.**
   - Fix: nested CV or a fixed specification, plus an in-fold fallback for a zone with no gauges.
   - Note that CV needs no grid rebuilds, because of linearity.
   - → **Adopted**: fixed primary specification; every experiment scored with selection inside the training fold.
4. **Gap: `coverage` does not flag transboundary area.** FWA polygons under `200` extend north of 60°N; `HYDZ_HYDROLOGICZONE_SP` is BC-only.
   - → **Adopted**: a separate `bc_fraction` flag, and the extended 43-feature zones layer.
5. **Gap: observed mm computed with `DRAINAGE_AREA_GROSS`.**
   - → **Adopted**: convert observed flow to mm with the accumulated FWA area; area ratio reported as a covariate.
6. **Ordering: Phase 4 needs the province runner.**
   - `wet_ws_sample()` is single-layer.
   - 54 groups span basins.
   - There are only 24 top-level codes, so no batching is needed.
   - → **Adopted, verified**: 24 top-level codes and 54 spanning groups (psql, 2026-09-26).
7. **Assumption: climr period label.**
   - Concern: a 1961–1990 label on a 1981–2010 mosaic could double-count the shift.
   - Size: about 28 GB if every year is downscaled.
   - → **Checked**: climr's time-series vignette says the anomalies are "relative to the 1961-1990 baseline used in climr", and the refmap reports 1961_1990, so the design is consistent. An independent check against ECCC 1981–2010 station normals was still added. Averaging the anomalies before downscaling was adopted, if the API allows it.
8. **Gap: negative and near-zero runoff; the CGIAR scale.**
   - → **Adopted**: signed cells, output floored, minimum-denominator rule for the % metrics.
   - The CGIAR monthly layers sum to the annual layer at the probe point (437 mm), which was already checked.
9. **Gap: HYDAT aggregation rules.** Complete-year definition, the same years for the monthly and annual values, shares from volumes, seasonal gauges, and counts inside the 1981–2010 window.
   - → **Adopted.**
10. **Units:** `wet_mm_to_m3s()` uses 365 days and observed flows include leap days.
    - → **Adopted**: 365.25 for annual, calendar days (February 28.25) for monthly, the same convention for observed and output.
11. **Scope:**
    - Monthly AET had no use; it becomes a candidate monthly predictor.
    - "Table 3 ratios" were undefined; they are now defined as class AET midpoint ÷ mean CGIAR AET over that class's cells.
    - DESCRIPTION deps were missing.
    - → **Adopted.**
12. **Acceptance: no numeric gate.**
    - → **Adopted**: the adjusted model must beat raw P − AET on headwater blocked CV. Also added: a mouth-sums check and a PCIC-`wet` comparison at gauges in 100/200/300.
