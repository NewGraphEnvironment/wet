# Task: Open province-wide runoff estimate: water balance after Chapman et al. 2018 (#11)

PCIC gridded hydrology covers only the Peace, Fraser and Columbia. The BC Water Tools (Foundry, now `bcgov/nr-bcwat`) will release per-watershed discharge, but their model code does not ship. Their published accuracy may be in-sample, and after an undocumented "adjustment to measured flows" step their values sit at about 0 % error at the gauges. Adopting any single product leaves us unable to tell whether it is right.

## Decisions (approved at the plan gate, 2026-09-26)

From the 23 open points in `research/water_balance_method.md` §7, with the reason for each:

1. **Grid:** CGIAR's native 30″ grid (EPSG:4326). A DEM is resampled onto it, climr downscales onto the same DEM, and all inputs are aligned there, so AET is never resampled.
2. **Gauge period:** the 1981–2010 window, with at least 10 complete years (research option b). This matches the climate normal.
3. **Residual sign:** fit obs − pred, and add it to the prediction (resolves the sign ambiguity between Eqs. 2 and 3).
4. **Residual regression** per BC hydrologic zone (`HYDZ_HYDROLOGICZONE_SP`, 29 zones):
   - Candidates are P, T, elevation, area, and BC Albers easting/northing; selection by blocked-CV skill.
   - Zones with too few gauges are pooled with a neighbour.
   - Applied cell-wise, so accumulation stays consistent.
5. **Monthly shares:**
   - One regression per month.
   - Predictors are upstream-mean values, so shares are computed per watershed, not per cell.
   - Predictions are floored at 0 and renormalised to sum to 1.
   - Region-specific fits are tested against a single pooled fit and kept only if blocked CV improves.
6. **Land-cover AET adjustment** is an experiment, not the baseline. It is kept only if it improves blocked-CV skill, because its published ratios do not exist.
7. **Calibration and output area:**
   - Calibrate on gauges with at least 95 % of their basin inside FWA coverage.
   - Segments with upstream area outside BC (Liard, Yukon, Alsek, Columbia headwaters) carry `coverage < 1` and are flagged.
   - Transboundary upstream area, via fwapg `extras/xborder`, goes to a follow-up issue.
8. **Station screening:**
   - HYDAT regulation flag never set; lake outlets flagged and reported separately rather than dropped.
   - Snaps accepted within ±10 % drainage area.
9. **Validation:**
   - Blocked cross-validation by WSC sub-sub-drainage (e.g. `08LB`), with a check that no nested pair spans folds.
   - Headline metrics: MAE %, % within ±20 %, log-ratio bias, and NSE on the monthly climatology and on the shares.
   - Plain leave-one-out is reported alongside, for comparability with Chapman.
   - Headwater, nested and incremental-area results reported separately.
10. **Output:** a `watershed_feature_id × month` table (month 0 = annual) with `runoff_mm`, `discharge_m3s` and `coverage`, as parquet under `data/wb/` (gitignored). Publishing is #7's job.

## Phase 1: Inputs on one grid
- [ ] `wet_cgiar_aet()`: fetch the CGIAR Soil-Water Balance v3 annual and monthly AET (figshare 7707605, CC0), extract with 7z, and crop to BC. Cached under `data/cgiar/`. Test on a small crop.
- [ ] Working DEM on CGIAR's 30″ grid over BC: source it (BC TRIM via bcdata, aggregated, or Copernicus GLO-90), record the choice, and cache it.
- [ ] `wet_climr_normals()`: climr ClimateNA observed series 1981–2010 averaged to monthly P and T normals on the working DEM, tiled and cached. Test against a point `downscale()`. Measure the BC-wide runtime on one tile before committing to the full build.
- [ ] Hydrologic zones: fetch `WHSE_WATER_MANAGEMENT.HYDZ_HYDROLOGICZONE_SP` and rasterise it to the grid.
- [ ] Pin every input snapshot (source URL, md5, date, dims) in a tracked manifest. Use `trap`'s snapshot/manifest if it fits a raster input on inspection; otherwise use `data/checks/wb_inputs.txt`.

## Phase 2: Stations (shared with #6)
- [ ] `wet_station_select()`: HYDAT BC stations never flagged regulated, with at least 10 complete years in 1981–2010, plus `DRAINAGE_AREA_GROSS` and lat/lon. Tests against the local sqlite (skip if absent).
- [ ] `wet_station_monthly()`: observed monthly and annual mean flow over the window, converted to mm with drainage area, plus monthly shares. Tested with synthetic daily flows, including missing months.
- [ ] `wet_station_snap()`: `fresh::frs_point_snap(num_features = n)` plus a candidate picker on the ratio of accumulated upstream area to `DRAINAGE_AREA_GROSS`. Returns `linear_feature_id`, `watershed_feature_id`, `wscode`, `localcode`, upstream area, area ratio and a lake-outlet flag. Tests on a confluence, a mainstem and a headwater station.
- [ ] Tracked report `data/checks/stations_wb.txt`: count by zone and sub-drainage, area-ratio distribution, and rejected snaps with reasons.

## Phase 3: Validation harness
- [ ] `wet_cv_folds()`: blocked folds by WSC sub-sub-drainage, with a nesting-leak test (no station and its upstream or downstream gauge in different folds), plus plain leave-one-out.
- [ ] `wet_flow_validate(modelled, observed)`: MAE %, % within ±20 %, log-ratio bias, and NSE on the monthly climatology and on the shares. Grouped by zone, drainage-area class and nesting class. Unit tests on synthetic inputs, including zero flow and missing months.

## Phase 4: Annual water balance
- [ ] Raw P − AET grid. Sample it per fundamental watershed (`wet_ws_sample(..., "area")`), accumulate with `wet_upstream_mean()`, and read the value at each station's watershed.
- [ ] `wet_wb_fit()` and `wet_wb_adjust()`: residual regression by zone (obs − pred), selected by blocked CV, then applied cell-wise to give the adjusted grid. Tests on a synthetic grid with a known residual surface.
- [ ] Blocked CV and plain leave-one-out on raw and adjusted, in `data/checks/wb_validation.txt` (tracked).
- [ ] Land-cover AET experiment: class ratios from Chapman's Table 3 on a current land-cover product. Kept only if blocked-CV skill improves; the result is recorded either way.

## Phase 5: Monthly shares
- [ ] `wet_share_fit()` and `wet_share_predict()`: one regression per month on upstream-mean predictors, floor at 0, renormalise. Tests: shares sum to 1, no negatives.
- [ ] Pooled vs per-zone (or per-regime) fits compared on blocked CV. Keep the better one.
- [ ] Snow-predictor experiment: `cd` ERA5-Land `snowmelt_doy_50` and `swe_max` as upstream means. Kept only if blocked CV improves.
- [ ] Monthly skill added to `data/checks/wb_validation.txt`.

## Phase 6: Province run
- [ ] `scripts/wb_province.R`: iterate the FWA top-level basins (batching small coastal ones) and write annual plus 12 months per fundamental watershed to `data/wb/` as parquet, with `coverage`.
- [ ] Tracked run log and report (`data/wb/*_report.txt`): counts, NA and low-coverage watersheds, timing. Check sums at the mouths of major rivers.
- [ ] Sanity map of annual runoff (tmap + gq), committed under `research/`, with the full self-review list.

## Phase 7: Record
- [ ] Revise `research/water_balance_method.md`: each choice as built, the validation numbers, and the skill of raw vs adjusted vs Chapman's published figures.
- [ ] Edit the #6 body to use the `wet_station_*` functions. File the transboundary follow-up issue.
- [ ] NEWS entry, and any README touch the exports need.

## Validation

- [ ] Tests pass (`devtools::test()`), lintr clean, `devtools::document()`
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
