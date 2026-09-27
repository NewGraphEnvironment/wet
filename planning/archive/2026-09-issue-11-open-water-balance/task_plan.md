# Task: Open province-wide runoff estimate: water balance after Chapman et al. 2018 (#11)

PCIC gridded hydrology covers only the Peace, Fraser and Columbia. The BC Water Tools (Foundry, now `bcgov/nr-bcwat`) will release per-watershed discharge, but their model code does not ship. Their published accuracy may be in-sample, and after an undocumented "adjustment to measured flows" step their values sit at about 0 % error at the gauges. Adopting any single product leaves us unable to tell whether it is right.

## Decisions (approved at the plan gate 2026-09-26; revised after the plan review, see `review-plan.md`)

1. **Grid:** CGIAR's native 30″ grid (EPSG:4326). The GLO-90 DEM is averaged onto it and climr downscales onto that DEM, so AET is never resampled.
2. **Gauge period:** 1981–2010.
   - A complete year has all 12 months, each with at least 20 days of flow; stations need at least 10 complete years.
   - The monthly climatology comes from the same years as the annual, and shares are computed from monthly volumes.
   - Seasonal-only gauges drop out, and are counted in the station report.
3. **Residual:** obs − pred (mm), added to the prediction.
4. **Residual regression, exactly consistent between fit and application:**
   - Every predictor is an upstream area-weighted mean of a cell layer: P, T, elevation, BC Albers easting and northing. There is no drainage-area term.
   - Zone effects enter as upstream means of `1[zone = z]` and `1[zone = z]·x` (built with `wet_upstream_sums()`), so a basin that straddles zones is fitted with exactly the mix of coefficients that the cell-wise surface applies.
   - Denominator: `"covered"` throughout.
   - Cells stay signed; only the watershed output is floored at 0.
5. **Fixed primary specification, set before seeing skill** (revised in the run; see `findings.md`, "Final run"). Under this specification the gate failed. A "no adjustment for pooled zones" candidate was then added, and chosen by nested CV. Which result ships is open for the maintainer:
   - Per zone: intercept + P, Chapman's form, with zones that have fewer than 8 training gauges pooled into one "other" level.
   - Pooling is decided from counts within the training fold.
   - Experiments (extra predictors, land cover, snow, per-zone monthly fits) are scored with selection **inside** the training fold.
   - CV needs no grid rebuilds: by linearity, a held-out prediction is the raw upstream mean plus the fold's coefficients times the held-out station's upstream predictor means.
6. **Monthly shares:**
   - One regression per month on upstream-mean predictors: monthly P, T and AET, elevation, easting and northing.
   - Shares are floored at 0 and renormalised to sum to 1.
   - Monthly m³/s uses calendar days (February 28.25); annual uses 365.25. The same convention applies to observed and modelled flows.
7. **Land-cover AET adjustment** is an experiment. The ratio for a class is Chapman's Table 3 class-midpoint AET ÷ the mean CGIAR AET over that class's cells. It is kept only if nested blocked CV improves.
8. **Area and flags:**
   - Calibrate on gauges whose accumulated FWA area lies at least 95 % inside BC.
   - Every output row carries `coverage` (raster cover) and a separate `bc_fraction` (share of upstream FWA area inside `fwa_bcboundary`).
   - Zones come from the extended 43-feature BC Hydrologic Zones layer, which reaches the FWA polygons outside BC.
   - Transboundary area with no FWA polygons goes to a follow-up issue.
9. **Stations:**
   - HYDAT regulation flag never set. Lake outlets are flagged, not dropped.
   - Snaps accepted within ±10 % drainage area.
   - Observed mm uses the accumulated FWA area of the snapped watershed; the area ratio is reported.
10. **Validation:**
    - Blocked CV by WSC sub-sub-drainage.
    - Each held-out station's leak exposure is measured (the share of its basin gauged in training), and **headwater-only skill is the headline**. Nested and incremental-area results are reported alongside, with plain leave-one-out for comparability with Chapman.
    - Metrics: MAE %, % within ±20 %, log-ratio bias, and NSE on the monthly climatology and on the shares. Stations with observed runoff under 10 mm are excluded from the % metrics and counted.
11. **Output:**
    - A `watershed_feature_id × month` table (month 0 = annual) with `runoff_mm`, `discharge_m3s`, `coverage` and `bc_fraction`, as parquet under `data/wb/` (gitignored).
    - Publishing is #7's job.

## Phase 1: Inputs on one grid
- [x] `wet_cgiar_aet()`: CGIAR Soil-Water Balance v3 annual and monthly AET (figshare 7707605, CC0), with the md5 checked and extraction by bsdtar, cropped to BC on its native grid.
- [x] `wet_dem_glo90()`: Copernicus GLO-90 averaged onto the CGIAR grid.
- [x] `wet_climr_normals()`: 1981–2010 monthly P and T normals on the DEM grid, averaging the anomalies before downscaling if the API allows. Measure the runtime on one tile first.
- [x] Check climr's 1981–2010 normals against ECCC 1981–2010 station normals (about 20 stations): P ratio and T difference, in a tracked report.
- [x] Hydrologic zones (the extended 43-feature layer) rasterised to the grid.
- [x] Input manifest (source URL, md5, date, dims). Use `trap` if it fits a raster input, otherwise `data/checks/wb_inputs.txt`.
- [x] DESCRIPTION: Imports curl and jsonlite; Suggests climr (with `Remotes: bcgov/climr`), RSQLite and tidyhydat. `fresh` turned out not to be needed (snapping calls fwapg directly); `arrow`, `sf`, `tmap` and `gq` are used only by `scripts/`, which is outside the built package.

## Phase 2: Stations (shared with #6)
- [x] `wet_station_select()`: HYDAT BC stations never flagged regulated, with at least 10 complete years in 1981–2010 (complete as in decision 2). Tests against the local sqlite (skip if absent). Count inside the window per zone.
- [x] `wet_station_monthly()`: monthly and annual mean flow from the same years, as volumes and shares, converted with the chosen day convention. Tested with synthetic daily flows, including missing days and months.
- [x] `wet_station_snap()`: `fresh::frs_point_snap(num_features = n)` plus a picker on the ratio of accumulated upstream FWA area to `DRAINAGE_AREA_GROSS`. Returns the snapped watershed ids, codes, FWA area, area ratio and a lake-outlet flag. Tests on a confluence, a mainstem and a headwater station.
- [x] Tracked report `data/checks/stations_wb.txt`: counts by sub-sub-drainage (by zone moves to Phase 3, which samples the basins), seasonal gauges dropped, area-ratio distribution, and rejected snaps with reasons.

## Phase 3: Province topology and sampling
- [x] Generalise `wet_ws_sample()` to multi-layer rasters, with `cover` per layer, keeping the one-layer output unchanged (existing tests stay green).
- [x] Runner `scripts/wb_province.R`, part 1: over the 24 top-level FWA codes, fetch topology once, sample each watershed group once (not once per basin), and cache the per-watershed layer means and cover.
- [x] Accumulation of any set of layers to every watershed (upstream means and indicator sums), plus `bc_fraction`. Station values read from their snapped watershed.

## Phase 4: Validation harness
- [x] `wet_cv_folds()`: blocked folds by WSC sub-sub-drainage, the leak exposure of each held-out station, the nesting class, and plain leave-one-out.
- [x] `wet_flow_validate(modelled, observed)`: the decision 10 metrics grouped by zone, drainage-area class and nesting class. Unit tests on synthetic inputs, including zero and near-zero flow and missing months.

## Phase 5: Annual water balance
- [x] Raw P − AET: upstream means at the stations and skill (blocked CV and leave-one-out).
- [x] `wet_wb_fit()` and `wet_wb_adjust()`: the zone-interacted residual regression on upstream-mean predictors, with in-fold pooling and fallback, applied cell-wise. Tests: on a synthetic grid with a known residual surface, the fitted surface accumulated at the stations reproduces the fitted values exactly.
- [x] Gate: the adjusted model must beat raw P − AET on headwater blocked CV, or the adjustment is dropped. Report in `data/checks/wb_validation.txt` (tracked).
- [ ] Land-cover AET experiment under nested CV — **moved to a follow-up (drafted in `issue_drafts_followup.md` #2, awaiting approval to file)**. The run found CGIAR AET far too low in the semi-arid interior, so the experiment is widened to alternative AET and a Budyko constraint.

## Phase 6: Monthly shares
- [x] `wet_share_fit()` and `wet_share_predict()`: one regression per month on upstream-mean predictors, floored at 0 and renormalised. Tests: shares sum to 1, no negatives.
- [ ] Per-zone monthly fits and the `cd` ERA5-Land snow predictors as experiments — **moved to a follow-up (drafted #3)**. Pooled monthly shares reach a median blocked-CV NSE of 0.87.
- [x] Monthly skill added to `data/checks/wb_validation.txt`.

## Phase 7: Province output
- [x] `scripts/wb_output.R` (split from the province runner): annual plus 12 months per fundamental watershed to `data/wb/` as parquet, with `coverage` and `bc_fraction`.
- [x] Tracked run log and report: counts, NA and low-coverage watersheds, timing. Mouth sums against HYDAT gauges near major river mouths, and a comparison with PCIC-`wet` at gauges in 100/200/300.
- [x] Sanity map of annual runoff (tmap + gq), committed under `research/`, with the full self-review list.

## Phase 8: Record
- [x] Revise `research/water_balance_method.md`: each choice as built, the validation numbers, and raw vs adjusted vs Chapman's published figures.
- [x] Edit the #6 body to use the `wet_station_*` functions. The transboundary follow-up is drafted (`issue_drafts_followup.md` #1) and awaits approval to file.
- [x] NEWS entry, and any README touch the exports need.

## Validation

- [x] Tests pass (`devtools::test()`), lintr clean, `devtools::document()`
- [x] `/code-check` clean on each commit
- [x] PWF checkboxes match landed work
- [x] `/planning-archive` on completion
