# Findings — Open province-wide runoff estimate: water balance after Chapman et al. 2018 (#11)

## Issue context

**If we do it:** `wet` gets mean annual and monthly runoff for every FWA fundamental watershed in BC, from open code, validated out-of-sample on HYDAT. The north and interior gap is filled, and there is a yardstick for PCIC and the BC Water Tools. **If we never do:** the north and interior stay without estimates, or depend on a product whose model code does not ship and whose accuracy cannot be checked independently.

## Problem

PCIC gridded hydrology covers only the Peace, Fraser and Columbia. The BC Water Tools (Foundry, now `bcgov/nr-bcwat`) will release per-watershed discharge, but their model code does not ship. Their published accuracy may be in-sample, and after an undocumented "adjustment to measured flows" step their values sit at about 0 % error at the gauges. Adopting any single product leaves us unable to tell whether it is right.

## Proposed

Build our own estimate, in the open, with the method the BC Water Tools use (Chapman, Kerr & Wilford 2018, JAWRA 54:676). Because the method is the same, a disagreement with their release points at a specific step.

- **Annual:** gridded P − AET per fundamental watershed, accumulated upstream with `wet_upstream_mean()`. A gauge-residual regression by hydrologic zone (`WHSE_WATER_MANAGEMENT.HYDZ_HYDROLOGICZONE_SP`, or the extended BC Hydrologic Zones layer, which reaches the Alberta, Yukon and NWT gauges).
- **Monthly:** share-of-annual regressions per month, fitted to unregulated HYDAT stations, with the shares constrained to sum to 1.
- **Stations:** `wet_station_select()`, `wet_station_snap()` (fresh snapping plus a drainage-area check) and `wet_station_monthly()`, shared with #6.
- **Validation:** blocked cross-validation by watershed group or WSC sub-drainage, with headwater and nested gauges reported separately and an incremental-area check on nested pairs. Plain leave-one-out is reported alongside, for comparability with Chapman.
- **Decisions (approved 2026-09-26):**
  1. Climate normal **1981–2010**, matching PCIC's baseline and the HYDAT overlap. climr labels its reference map 1961–1990, so building 1981–2010 from its observed series is the first probe. ClimateNA 1 km grids or `cd` ERA5-Land are the fallbacks.
  2. ET from the **CGIAR Global Soil-Water Balance v3 AET** (CC0, annual and monthly), adjusted by land cover as in Chapman. climr cannot compute Eref or CMD yet.
  3. **No final adjustment to gauges.** Values are pure predictions, so skill is measured honestly.
  4. climr 0.2.2 installed from `bcgov/climr`.
- **Data handling, using our own packages where they fit:**
  - `trap` pins snapshots of external inputs: the CGIAR AET, climr extracts, the hydrologic zones and HYDAT station tables, each with its source, md5 and row count.
  - `crate` declares schemas for shape-shifting sources: the BC Water Tool release (in #5) and HYDAT reductions.
  - `cd` supplies ERA5-Land snow variables (snowmelt timing, peak SWE) as candidate monthly-share predictors. It is also the place to add ERA5-Land evaporation and runoff if needed.
- **Every choice where the paper is silent** (23 are listed in `research/water_balance_method.md` §7) is recorded with its reason.

Research: [`research/water_balance_method.md`](https://github.com/NewGraphEnvironment/wet/blob/main/research/water_balance_method.md), [`research/runoff_prior_art.md`](https://github.com/NewGraphEnvironment/wet/blob/main/research/runoff_prior_art.md).

## Done when

- Annual and monthly runoff exist for every fundamental watershed in BC.
- Blocked-CV skill is reported by region, drainage-area class and nesting class, with the MAE % and within-±20 % metrics.

Relates to #5, #6.

## Plan-mode probes (2026-09-26)

- **climr can produce a 1981–2010 normal.** `downscale(which_refmap = "refmap_climr", obs_ts_dataset = "climatena", obs_years = 1981:2010, vars = ...)` returns 30 annual rows to average.
  - Test point (−127.2, 54.8, 600 m): MAP 578 mm, against 560 on the reference map, which is a 1961–1990 base.
  - Valid datasets: `mswx.blend`, `cru.gpcc`, `climatena`.
  - Eref and CMD are unsupported in `downscale()`, but `calc_Eref()` and `calc_PET()` are exported.
- **CGIAR AET** ships as `.rar` files; `/opt/homebrew/bin/7z` extracts them.
- **Existing pipeline to reuse:**
  - `wet_ws_fetch(conn, wscode)` and `wet_upstream_irregular()` for topology.
  - `wet_ws_geom(conn, wsg)` plus `wet_ws_sample(r, ws, "area")` for area-weighted sampling per group.
  - `wet_upstream_mean(ws, values, denom, irregular_pairs)` for the upstream area-weighted mean, with a `coverage` output.
  - `wet_mm_to_m3s()` for unit conversion.
  - `scripts/mad_basin.R` is the per-basin runner pattern: the Fraser builds in 3.4 min.

## Phase 1 results (2026-09-26)

- **Grid:** the CGIAR 30″ crop over BC, 1429 × 3013 cells. The AET monthly layers sum exactly to the annual layer (437 mm at the Smithers probe point).
- **DEM:** GLO-90 averaged onto the grid in 5.4 min.
  - The first build had 0 m, not NA, where there is no tile. The VRT now sets nodata.
- **climr normals:**
  - Averaging the 30 ClimateNA anomaly years before downscaling matches climr's per-year point average within 0.1 % (MAP 591.2 vs 590.6 mm).
  - BC-wide build: 3.9 min, 14.5 GB peak.
  - Against ECCC 1981–2010 normals at 49 WMO "A" stations: MAP ratio p10 / median / p90 = 0.96 / 1.06 / 1.20, and MAT difference −0.55 / +0.02 / +0.40 °C.
  - A double-counted 1961–1990 → 1981–2010 shift would show as roughly +0.5 °C, so the period is right. The 6 % wet bias is for the residual regression to absorb.
  - 8 stations have no climr value. Before code-check round 1 they were mixed silently into the statistics.
- **climr quirks:**
  - `downscale_core()` rejects an in-memory anomaly raster ("raster has no values") and accepts it file-backed.
  - It labels observed layers `OBS_<var>_2001_2020` whatever the period.
  - `input_obs_ts()` needs `obs_ts_dataset`.
- **`trap` does not fit raster inputs.** Its manifest is a Postgres table → parquet snapshot. The input manifest is `data/checks/wb_inputs.txt` instead.
- **Snapping:**
  - A single `fwa_indexpoint()` LATERAL query for all stations, not `fresh::frs_point_snap()` per station. It wraps the same fwapg function, without ~350 round trips or a new dependency.
  - Trial run: 352 stations selected, 309 snapped within ±10 % (median area ratio 0.9997) in 8 s.

## Upstream defect: terra `rasterize(filename = , wopt = list(datatype = "INT1U"))` writes NA as 0 (filed as rspatial/terra#2195)

Filed 2026-09-26 after approval. It was re-tested first on CRAN terra 1.9.50: still present, and it covers any integer datatype (INT2S too), not only unsigned ones. The filed text supersedes the draft below.

Reproduced minimally on terra 1.9.46 / GDAL 3.8.5. No existing issue was found (searched rspatial/terra, 2026-09-26). The draft for `rspatial/terra` awaits approval:

> **`rasterize()` with `filename` and an unsigned `datatype` writes background NA as 0**
>
> ```r
> v <- terra::vect("POLYGON((0 0,1 0,1 1,0 1,0 0))", crs = "EPSG:4326"); v$z <- 5L
> r <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 2, ymin = 0, ymax = 2, crs = "EPSG:4326")
> f1 <- tempfile(fileext = ".tif")
> terra::rasterize(v, r, field = "z", filename = f1, wopt = list(datatype = "INT1U"))
> sum(is.na(terra::values(terra::rast(f1))))   # 0  (12 cells are 0)
> f2 <- tempfile(fileext = ".tif")
> terra::writeRaster(terra::rasterize(v, r, field = "z"), f2, datatype = "INT1U")
> sum(is.na(terra::values(terra::rast(f2))))   # 12
> ```
> The same background is NA when rasterised in memory and then written, but 0 when written directly. The file reports NoData = 255, yet no cell holds it. terra 1.9.46, GDAL 3.8.5, macOS.

Workaround in `scripts/wb_inputs.R`: rasterise in memory, then `writeRaster()`.

## Phases 3–6: first province run and validation (2026-09-26, ClimateNA anomalies; superseded by "Final run" below)

- **Province run:**
  - 246 groups sampled in 6.4 min (4 PSOCK workers). The multi-layer `rowsum()` sampler does BULK (20,970 polygons, 55 layers) in 9 s.
  - Upstream means for 3,245,453 watersheds in 24 top-level basins in 4.5 min.
- **Validation:** 280 calibration stations (basin ≥ 95 % in BC and on the grid), 90 blocked folds.
  - Mean absolute error: raw P − AET 37.8 %; adjusted, blocked CV 33.6 %; leave-one-out 33.0 %; in-sample 22.7 %.
  - Gate passed on headwater stations: 39.2 % vs 43.8 %.
  - Monthly NSE, median under blocked CV: 0.75 on mm, 0.87 on shares.
- **Major rivers (mean annual flow, modelled vs HYDAT 1981–2010):** Peace 0.95, Stikine 1.13, Nass 0.84, Skeena 0.92, Thompson 1.21, Fraser at Hope 1.08 (partly the Nechako diversion out of the basin), Columbia 1.04. PCIC through `wet` at Hope: 2,477 m³/s, a ratio of 0.93.

### Inconsistency found in another group's product: CGIAR AET in the semi-arid interior

- Raw P − AET overpredicts badly in hydrologic zones 15 (Fraser Plateau), 17 (N. Thompson Plateau), 23 (Okanagan Highland) and 24 (S. Thompson Plateau): median error +109 % to +150 %.
- Example, Greata Creek 08NM173: climr P 746 mm, CGIAR AET 281 mm, so P − AET is 466 mm against 50 mm observed. The water balance implies about 700 mm of ET.
- CGIAR's AET is computed from its own soil bucket on WorldClim P, and it cannot exceed that P. Next to climr's P it is far too low in dry country.
- The zone-wise linear adjustment cannot repair an error of this size. That is where the land-cover / ET experiment should look (follow-up issue).

### A climr gap: ClimateNA anomalies do not cover the coastal islands

- `input_obs_ts(dataset = "climatena")` is `NA` on its 1° grid over Haida Gwaii and northern Vancouver Island.
- Averaging its anomalies for the raster route left 159,747 land cells without normals. That is the "Empty tile - not enough data" warning in the first build.
- In the output: 247,249 watersheds with no annual value; basins 940–955 empty.
- climr's point (database) route does return values there, so this is specific to the raster route with gridded anomalies.
- Switched to `mswx.blend` (0.5°), which covers the islands. climr's own guidance rates it as generally credible and notes artefacts in the ClimateNA series in station-sparse western Canada.
- An upstream issue for bcgov/climr could be drafted; nothing has been posted.

## Final run (2026-09-26, MSWX anomalies, run 5c2feaefad)

- **Inputs:** climr + MSWX blend. ECCC check: 57 stations, MAP ratio median 1.034. Raw P − AET MAE 34.7 % (37.8 % with ClimateNA).
- **Wrong turns, kept as evidence:**
  1. Per-fold pooling with one fitted "other" level: gate PASS (ClimateNA run).
  2. Pooling fixed once from locations (review round 1): zone 07 collapsed in one fold to a = −3874 (review round 2). Reverted to per-fold pooling.
  3. With MSWX, the gate FAILED: 46.4 % vs 39.8 % on headwater stations.
  4. Review round 3 traced the failure to the pooled "other" level, whose ~+170 mm intercept lands on dry zones. "No adjustment for pooled zones" passes, but was found by looking at CV.
- **Resolution:** each fold chooses the variant by an inner blocked CV on its training stations. All 93 folds, and the all-station fit, chose "none".
- **Headline:** blocked CV 33.1 % (headwater 38.1 %), LOO 32.3 %, in-sample 22.6 %. The gate passes narrowly and the adjustment ships.
- **Major rivers:** 0.86–1.17. Fraser at Hope 1.05; PCIC through `wet` 0.93.
- **Output:** 3,245,453 watersheds × 13 rows. 22,041 (0.7 %, small coastal islands) have no value.
- **Map:** zone-boundary steps are visible where the zone-wise adjustment changes. They come from the method (§7 item 9).

## Errors Encountered

| Error | Resolution |
|-------|------------|
| climr `downscale(vars = "Eref")` / `"CMD"`: "calculation is not supported yet" | Use CGIAR AET; `calc_Eref()` is exported if a PET is ever needed |
| climr `obs_years` alone returned only the reference row | Pass `obs_ts_dataset = "climatena"` |
| Homebrew `7z` "Unsupported Method" on the CGIAR RARs | `bsdtar` (libarchive reads RAR4) |
| climr `downscale_core()` "raster has no values" | Two causes. `terra::rast(SpatRaster)` returns an empty template (only paths go through `rast()` now), and the anomaly must be file-backed |
| `terra::setGDALconfig("KEY=")` stores "NA" | Two-argument form, `wet_gdal_config_set()` |
| Validation: `rbind` across basins failed | Basins carry only their own zone columns; fill with 0, and skip basins with no stations (zero-row frame) |
| Output: `wet_wb_adjust()` "no zone columns" in basin 940 | No fitted zone means no adjustment |
