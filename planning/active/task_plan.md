# Task: Evapotranspiration in the semi-arid interior (land-cover and alternative-AET experiments) (#15)

- CGIAR Soil-Water Balance AET is computed from its own soil bucket on WorldClim precipitation, so it is capped by that precipitation. Next to climr's precipitation it is far too low in dry country.
- Example: Greata Creek (08NM173) has P 746 mm and CGIAR AET 281 mm, so raw P − AET is 466 mm, against 50 mm observed. The implied ET is about 700 mm.
- The zone-wise linear adjustment of Chapman et al. (2018) cannot repair an error of this size (`data/checks/wb_validation.txt`).

## Pre-set decision rule (fixed before any numbers exist)

- **Candidates:**
  1. `cgiar` (status quo)
  2. `lc`: CGIAR × Table 3 land-cover ratio. The class midpoint is divided by the mean CGIAR AET over the cells where that class is the majority. Nothing is fitted.
  3. `tc`: TerraClimate 1981–2010 AET
  4. `fu`: Fu–Budyko AET from climr P and Hargreaves PET, ω = 2.6
  5. `cfu`: max(CGIAR, Fu), i.e. CGIAR constrained from below by Budyko demand
- **Scored model:** each variant is scored as shipped. That means the adjusted model if it passes the existing headwater gate, raw otherwise, with the pooled variant chosen inside each fold as now.
- **Winner:** the lowest headwater blocked-CV MAE among variants whose all-290 blocked-CV MAE is ≤ cgiar's. A tie or no improvement keeps `cgiar`.
- **Transparency only, not eligible:** ω ∈ {1.5, 2.0, 3.5}, and raw scores per variant.

## Phase 1: Pure AET/PET functions (tests first)
- [ ] `wet_pet_hargreaves(tmax, tmin, lat, month)`: FAO-56 Hargreaves monthly ET0 (mm), with extraterrestrial radiation from latitude and mid-month day. Tests: the FAO-56 Ra table value, zero when Tmax = Tmin, and it works on SpatRasters.
- [ ] `wet_aet_budyko(p, pet, omega = 2.6)`: Fu's equation. Tests: 0 ≤ AET ≤ min(P, PET), the limits PET→0 and P→∞, monotone in ω, and SpatRaster input.
- [ ] `wet_aet_landcover(aet, frac, et_class)`: per-class ratio = the class's Table 3 midpoint divided by the mean `aet` over that class's majority cells. The per-cell multiplier is Σ frac_c · ratio_c, and a cell with no cover gets ratio 1. Tests on synthetic rasters.
- [ ] `inst/extdata/chapman_table3.csv`: Table 3 transcribed from the PDF (p. 8), with a crosswalk from NRCan 2020 classes. The source page goes in the roxygen.
- [ ] roxygen, runnable `@examples`, and `devtools::document()`.

## Phase 2: Fetchers and inputs
- [ ] `wet_terraclimate_aet(grid)`: an NCSS/OPeNDAP bbox subset of the TerraClimate 1981–2010 summary AET (and PPT, for diagnosis only). It follows `wet_cgiar_aet()`: cached by content key, written to `.part` and renamed, then bilinear-resampled onto the 30″ grid. Tests use synthetic sources, plus a test that a cached file is returned without a download.
- [ ] `wet_landcover_nrcan(grid)`: NRCan 2020 30 m land cover (OGL-Canada), md5-checked, turned into per-class cover fractions on the 30″ grid. Outside Canada there is no cover, so the ratio defaults to 1; this is stated in the docs. Tests use synthetic sources.
- [ ] `scripts/wb_inputs.R`: build the climr `Tmax`/`Tmin` normals, TerraClimate and NRCan, and add their manifest rows to `data/checks/wb_inputs.txt`.

## Phase 3: Province layers
- [ ] `scripts/wb_province.R`: add the layers `pet_yr`, `aet_lc`, `aet_tc`, `aet_fu`, `aet_cfu` and the transparency ω layers. Add the new R files to the run key, and fix the `one("data/climr")` lookup now that there are two climr files.
- [ ] Smoke test with `WET_WB_GROUPS=SALR,OKAN`. Then run the full province under `caffeinate -i` and commit the run log as evidence.

## Phase 4: Scoring
- [ ] `scripts/wb_validate.R`: take an AET argument (default `cgiar`), set `raw = p_yr − aet_<v>`, record `aet` in `fits.rds`, and write `data/checks/wb_validation_aet-<v>.txt` for each variant.
- [ ] `scripts/wb_aet_compare.R`: collate the per-variant reports into `data/checks/wb_aet_compare.txt`. Per variant it lists raw and as-shipped MAE (all 290 and headwater), mean % in zones 15/17/23/24, MAE for basins under 100 km², Greata Creek (P, AET, raw, obs), and the ω transparency rows. It then applies the pre-set rule and names the winner.

## Phase 5: Adopt and ship
- [ ] Make the winner the default AET in `wb_validate.R`. `wb_output.R` reads `fits$aet` and rebuilds the per-basin parquet and `data/checks/wb_output.txt`. If the winner is `cgiar`, this phase records no change.
- [ ] Re-render `scripts/wb_map.R` to `research/wb_runoff_annual.png`, then run the cartography self-review.

## Phase 6: Write-up
- [ ] Revise `research/water_balance_method.md` §0 with the results and the header line. Attribute each disagreement as ours, theirs or unresolved (CGIAR's P-cap versus climr P). Record MOD16 as deferred and why.
- [ ] Update the `research/README.md` row and the CLAUDE.md water-balance blurb.
- [ ] Edit the issue #15 body with the outcome.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] Each `wb_validation_aet-cgiar.txt` reproduces the #11 cgiar numbers (MAE 33.1 % / 38.1 %)
- [ ] `/planning-archive` on completion
