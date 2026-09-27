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

## Errors Encountered

| Error | Resolution |
|-------|------------|
| climr `downscale(vars = "Eref")` / `"CMD"`: "calculation is not supported yet" | Use CGIAR AET; `calc_Eref()` is exported if a PET is ever needed |
| climr `obs_years` alone returned only the reference row | Pass `obs_ts_dataset = "climatena"` |
