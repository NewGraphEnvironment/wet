# Task: Evapotranspiration in the semi-arid interior (land-cover and alternative-AET experiments) (#15)

- CGIAR Soil-Water Balance AET is computed from its own soil bucket on WorldClim precipitation, so it is capped by that precipitation. Next to climr's precipitation it is far too low in dry country.
- Example: Greata Creek (08NM173) has P 746 mm and CGIAR AET 281 mm, so raw P − AET is 466 mm, against 50 mm observed. The implied ET is about 700 mm.
- The zone-wise linear adjustment of Chapman et al. (2018) cannot repair an error of this size (`data/checks/wb_validation.txt`).

## Pre-set decision rule (fixed before any variant is scored; revised 2026-09-27 after the plan review, before Phase 3)

Candidates (each an annual AET layer; raw_v = upstream mean p_yr − upstream mean aet_v):
1. `cgiar` — status quo (layer `aet_yr`; raw is the stored `ro_raw`, so the baseline reproduces byte for byte).
2. `lc` — CGIAR × Table 3 land-cover ratio (`wet_aet_landcover()`): Liu et al. (2003) Canada values, wetland and water range midpoints (`inst/extdata/chapman_table3.csv`); denominators over analysis-mask cells with in_bc ≥ 0.5; ≥ 100 majority cells per class, else ratio 1; ratios clamped to [0.25, 4]; nothing fitted.
3. `tc` — TerraClimate 1981–2010 AET, bilinear to the 30″ grid, gaps filled by nearest, then by CGIAR.
4. `fu` — Fu–Budyko AET from climr P and Hargreaves PET (climr Tmax/Tmin), ω = 2.6 (Zhang et al. 2004).
5. `cfu` — max(CGIAR, Fu ω = 2.6).
Transparency only, never eligible: `fu` at ω ∈ {1.5, 2.0, 3.5}.

Each variant is scored **as shipped**: adjusted if it passes the existing headwater gate under blocked CV (pooled variant chosen inside each fold, as now), raw otherwise. Raw is eligible only through that gate.

A variant replaces `cgiar` only if **all** of these hold (blocked CV unless stated):
- (a) headwater MAE at least **2.0 points** below cgiar's;
- (b) all-290 MAE ≤ cgiar's;
- (c) nested-station MAE no more than 1.0 point above cgiar's, and nested within ±20 % no more than 3 points below;
- (d) under a **fully nested selection** (each outer blocked fold chooses the AET variant, and the gate, by an inner blocked CV on its training stations), headwater MAE is below cgiar's. This number is reported beside the winner as the unbiased estimate of the selection.
Several passing: the lowest headwater MAE wins. None: `cgiar` stays.

Disclosed up front: the candidates were motivated by the zone 15/17/23/24 residuals on these same stations; TerraClimate's AET is itself capped by its own P (Greata mouth cell: TC P 428 mm, AET 392 mm; climr P 614 mm); Budyko ignores the P/PET phase lag of snow climates, so `fu`/`cfu` likely over-evaporate the mountains; `lc` is expected to lower interior AET (conifer 276 mm) and is scored as Chapman-faithful, not as a fix.

## Phase 1: Pure AET/PET functions (tests first)
- [x] `wet_pet_hargreaves(tmax, tmin, lat, month)`: FAO-56 Hargreaves monthly ET0 (mm), with extraterrestrial radiation from latitude and mid-month day. Tests: the FAO-56 Ra table value, zero when Tmax = Tmin, and it works on SpatRasters.
- [x] `wet_aet_budyko(p, pet, omega = 2.6)`: Fu's equation. Tests: 0 ≤ AET ≤ min(P, PET), the limits PET→0 and P→∞, monotone in ω, and SpatRaster input.
- [x] `wet_aet_landcover(aet, frac, et_class)`: per-class ratio = the class's Table 3 midpoint divided by the mean `aet` over that class's majority cells. The per-cell multiplier is Σ frac_c · ratio_c, and a cell with no cover gets ratio 1. Tests on synthetic rasters.
- [x] `inst/extdata/chapman_table3.csv`: Table 3 transcribed from the PDF (p. 8), with a crosswalk from NRCan 2020 classes. The source page goes in the roxygen.
- [x] roxygen, runnable `@examples`, and `devtools::document()`.

## Phase 2: Fetchers and inputs
- [x] `wet_terraclimate_aet(grid)`: an NCSS/OPeNDAP bbox subset of the TerraClimate 1981–2010 summary AET (and PPT, for diagnosis only). It follows `wet_cgiar_aet()`: cached by content key, written to `.part` and renamed, then bilinear-resampled onto the 30″ grid. Tests use synthetic sources, plus a test that a cached file is returned without a download.
- [x] `wet_landcover_nrcan(grid)`: NRCan 2020 30 m land cover (OGL-Canada; no published md5, so the download is size-checked and its md5 pinned in the manifest), turned into per-class cover fractions on the 30″ grid in one GDAL warp: a VRT with one LUT band per Table 3 class, averaged by `terra::project(method = "average")`. *(Revised: nearest to an aligned 1″ grid, then `aggregate(30)`. A single average warp from the Lambert CRS was off by up to 0.3 per cell; see findings.)* Outside Canada there is no cover, so the ratio defaults to 1; this is stated in the docs. Tests use synthetic sources.
- [x] `scripts/wb_inputs.R`: build the climr `Tmax`/`Tmin` normals, TerraClimate and NRCan, and add their manifest rows to `data/checks/wb_inputs.txt`.

## Phase 3: Province layers
- [x] `scripts/wb_province.R`: add the layers `pet_yr`, `aet_lc`, `aet_tc`, `aet_fu`, `aet_cfu`, `aet_fu15`, `aet_fu20`, `aet_fu35`. Build the analysis mask from the original layers only, fill every new layer onto it, and assert the mask is unchanged. Add the new R files **and `inst/extdata/chapman_table3.csv`** to the run key, and the new inputs to `f_in` and `compareGeom`. Pick the climr files by their layer names, since their file names differ only by a hash.
- [x] Smoke test with `WET_WB_GROUPS=SALR,OKAN`. Then run the full province under `caffeinate -i` and commit the run log as evidence.
- [x] Move `data/wb/5c2feaefad` to `data/wb_old/`, because the downstream scripts need exactly one complete run. Check that the new run's `p_yr`, `aet_yr`, `ro_raw`, `coverage` and `bc_fraction` match the old run exactly, and that the 290 calibration stations are the same.

## Phase 4: Scoring
- [x] `scripts/wb_validate.R`: take an AET argument (default: the shipped variant; checked against the allowed set) and set `raw` from `ro_raw` for cgiar or `p_yr − aet_<v>` otherwise. Save `cv_aet-<v>.rds` under the run directory (per-station errors and summaries). Write `data/checks/wb_validation_aet-<v>.txt`, plus `fits.rds` and `data/checks/wb_validation.txt` only for the shipped variant, and record `aet` in `fits.rds`. Label the report header with the note that monthly shares stay on CGIAR's monthly AET.
- [x] `scripts/wb_aet_compare.R`: read the `cv_aet-*.rds` files (not the text reports), run the fully nested selection CV, and collate into `data/checks/wb_aet_compare.txt`. Per variant it lists raw and as-shipped MAE (all 290 and headwater), mean % in zones 15/17/23/24, MAE for basins under 100 km², Greata Creek (P, AET, raw, obs), and the ω transparency rows. It then applies the pre-set rule and names the winner.

## Phase 5: Adopt and ship
- [x] Make the winner the default AET in `wb_validate.R`. `wb_output.R` reads `fits$aet` (missing means cgiar) for both the per-basin raw (`up$raw`) and the `runoff_annual.tif` grid (`ro`). Always re-run `wb_validate.R`, `wb_output.R` and `wb_map.R` on the new run key, even if cgiar wins.
- [x] Re-render `scripts/wb_map.R` to `research/wb_runoff_annual.png`, then run the cartography self-review.

## Phase 6: Write-up
- [x] Revise `research/water_balance_method.md` §0 with the results and the header line. Attribute each disagreement as ours, theirs or unresolved (CGIAR's P-cap versus climr P). Record MOD16 as deferred and why.
- [x] Update the `research/README.md` row and the CLAUDE.md water-balance blurb.
- [ ] Edit the issue #15 body with the outcome.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [x] `wb_validation_aet-cgiar.txt` matches today's `wb_validation.txt` byte for byte, apart from the run-key line
- [ ] `/planning-archive` on completion
