# Findings — Evapotranspiration in the semi-arid interior (#15)

## Issue context

**If we do it:** the southern interior plateaus stop being overpredicted, and the open estimate becomes usable there. **If we never do:** raw runoff in hydrologic zones 15, 17, 23 and 24 (Fraser Plateau, Thompson Plateaus, Okanagan Highland) stays biased high, by a mean of +56 % to +234 % per zone (`data/checks/wb_validation.txt`), and small headwater basins there dominate the model's error.

## Problem

- CGIAR Soil-Water Balance AET is computed from its own soil bucket on WorldClim precipitation, so it is capped by that precipitation. Next to climr's precipitation it is far too low in dry country.
- Example: Greata Creek (08NM173) has P 746 mm and CGIAR AET 281 mm, so raw P − AET is 466 mm, against 50 mm observed. The implied ET is about 700 mm.
- The zone-wise linear adjustment of Chapman et al. (2018) cannot repair an error of this size (`data/checks/wb_validation.txt`).

## Proposed

Score each option under the same blocked cross-validation (`scripts/wb_validate.R`):
1. Chapman's land-cover AET ratios. The class midpoint AET from their Table 3, divided by the mean CGIAR AET over that class's cells, on a current land-cover product (drift's ESA WorldCover or NRCan 2020).
2. An alternative AET: TerraClimate AET (CC0, 4 km, monthly), or MODIS MOD16.
3. A Budyko/Zhang-type constraint, so AET cannot fall far below the demand implied by P and PET.

Relates to #11.

## Plan-mode exploration (2026-09-27)

What exploration found, and how it shaped the plan:
- Every predictor is an upstream area-weighted mean of a per-cell layer (`scripts/wb_province.R`), so raw runoff is linear: raw_v = p_yr − aet_v. Each variant is one more sampled layer, and the whole CV harness (`scripts/wb_validate.R`, `wet_wb_fit()`, `wet_wb_adjust()`, `wet_cv_folds()`, `wet_flow_validate()`) is reused unchanged apart from which AET layer it reads.
- `wet_climr_normals()` already supports monthly `Tmax`/`Tmin`, which is all Hargreaves PET needs. That keeps PET on the same climr climate as P. The CGIAR ET0 license is unresolved (`research/runoff_prior_art.md`).
- Chapman's mechanism (2012 paper, p. 83) is AET_adj = AET_CGIAR × ratio(class). Their Table 3 gives measured AET by cover class, but the ratios they actually used were never published (`research/water_balance_method.md` §2, §7 item 4).
- Land cover: I'm using **NRCan 2020 30 m**, not ESA WorldCover. WorldCover has one tree class, which erases the conifer (276 mm) versus deciduous (492 mm) split in Table 3. That split is the part of the table that matters. drift's `dft_stac_fetch()` works at 10 m and cannot reach BC-wide at 30″.
- MOD16 is **deferred**: it needs an Earthdata login, which breaks unattended runs, and it has gaps in alpine and non-vegetated cells. The issue lists it as an "or" alongside TerraClimate (CC0, 4 km).
- `wb_output.R` reads `up$ro_raw`. The shipped AET choice will travel in `fits.rds`, so output follows validation without a second constant to keep in sync.
- The monthly shares (`wet_share_fit()`) stay on CGIAR's monthly AET. This experiment is annual only.

## Plan review (Plan agent, 2026-09-27)

The rule and the phases were revised on these points before Phase 3; the full review is in the session record.
- **Blockers:**
  - B1: new layers must not move the analysis mask. Fill them onto the old mask and assert it is unchanged.
  - B2: a second complete run directory stops `wb_validate`, `wb_output` and `wb_map`. Move the old run to `data/wb_old/`.
  - B3: `fits.rds` would be overwritten per variant, and `wb_output.R` uses `ro_raw` in two places (the parquet and `runoff_annual.tif`).
  - B4: the two climr files differ only by a hash. Select them by layer names, and add `chapman_table3.csv` to the run key.
- **Rule:**
  - R1: add a noise margin (2.0 headwater points).
  - R2: nested selection CV reported, and required.
  - R3: guards on nested stations.
  - R4: raw is eligible only through the gate.
  - R5: pre-register before layers exist (done here, before Phase 3).
- **Physical:**
  - Hargreaves and Fu are clamped at 0 (Phase 1).
  - Fu per cell ignores the P/PET phase lag of snow climates and the scale of ω (disclosed).
  - lc denominators come from in-BC cells, need ≥ 100 majority cells, and are clamped to [0.25, 4].
  - Partial cover keeps ratio 1 on its uncovered part (Phase 1).
- **Scope:** TerraClimate is P-capped too. Greata mouth cell: TC P 428 mm, AET 392 mm; climr P 614 mm; CGIAR AET 269 mm.
- **Accepted as churn:** re-running `wb_inputs.R` also rewrites `climr_eccc.txt` (unchanged content apart from the date).

## Sources probed (2026-09-27)

- NRCan 2020 land cover: `https://datacube-prod-data-public.s3.ca-central-1.amazonaws.com/store/land/landcover/landcover-2020-classification.tif`, COG, EPSG:3979, 30 m, 2,107,707,760 bytes, NoData 0. The ETag is multipart, not an md5. Codes in the BC bbox: 1, 2, 5, 6, 8, 10, 11, 12, 14, 15, 16, 17, 18, 19 (the NALCMS scheme).
- TerraClimate 1981–2010 climatology: `http://thredds.northwestknowledge.net:8080/thredds/fileServer/TERRACLIMATE_ALL/climatology/TerraClimate_19812010_{aet,ppt}.nc`, 1/24°, 12 monthly layers, Int16 × 0.1 mm. The NCSS subset endpoint returned 200 with 0 bytes, so the whole file is downloaded (95 MB AET, 147 MB PPT).
- Chapman et al. (2018) Table 3 (p. 8), transcribed into `inst/extdata/chapman_table3.csv`. The Liu et al. (2003) Canada rows cover every class; wetland and water use range midpoints.

## Land-cover fractions: a one-step average warp is wrong in western BC (2026-09-27)

- **The first build.** A LUT VRT over the 30 m EPSG:3979 source, warped with `terra::project(method = "average")` straight onto the 30″ grid, took 14.1 min (`data/logs/20260927_landcover_build.log`). Its fractions differed from exact-overlap pixel counts by a median max-class 0.07 and a max of 0.30 over 40 random covered cells.
- **Ruled out: overviews.** Opening the source with `OVERVIEW_LEVEL=NONE` gave identical values.
- **Cause: rotated footprints.** GDAL's average treats each target cell's footprint as an axis-aligned box in the source CRS. NRCan's Lambert conformal, centred on −95°, is rotated about 20° against a lon/lat cell at −125°.
- **The fix, tested on one window** (−125.1 to −124.5, 58.3 to 58.8), 25 cells against exact overlap:

  | Method | Mean abs diff | Max abs diff |
  |---|---|---|
  | One step | 0.026 | 0.11 |
  | Two steps: nearest to an aligned 1″ grid, then `aggregate(30)` | 0.002 | 0.015 |

- **Test.** A test with diagonal stripes in EPSG:3979 at −125 fails on the one-step method (restore-the-bug check done) and passes on the two-step one.
- **Why round 2 missed it.** Its "VRT holds up across CRSs" check compared the VRT against a plain average warp of a 0/1 raster, which has the same defect, so it could not disagree. A same-method oracle, not an independent one.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| One-step average warp of land cover off by up to 0.3 per cell in western BC | Nearest to an aligned 1″ grid, then `aggregate(30)`; rotated-CRS test |
| `terra` `%in%` on a SpatRaster: `'match' requires vector arguments` (terra imported, not attached) | `x == a | x == b` |
| TerraClimate NCSS subset `.../ncss/grid/...?var=aet&north=..` returned HTTP 200 and 0 bytes | Download the whole climatology file from `fileServer/` (95 MB) |

## Refactor check (2026-09-27)

`scripts/wb_validate.R cgiar`, run on the #11 province run `5c2feaefad` after `wb_cv_lib.R` was factored out, reproduces `data/checks/wb_validation.txt` byte for byte apart from the run-key line, which now names the AET (`data/logs/20260927_wb_validate_refactor_check.log`).
