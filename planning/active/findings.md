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

## Errors Encountered

| Error | Resolution |
|-------|------------|
