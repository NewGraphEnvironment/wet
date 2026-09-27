# Follow-up issue drafts from #11 (NOT filed; shown for approval)

## 1. Transboundary upstream area for the open water balance

**If we do it:** every segment on a river that rises outside BC (Liard, Yukon, Alsek, Taku, the Kootenay loop through the US, the Columbia below the border) gets discharge from its whole basin. **If we never do:** those segments keep `bc_fraction < 1` and under-report discharge by the share of the basin outside BC. This is flagged in the output, but a user can still miss it.

## Problem

`wet`'s open water balance (#11) accumulates runoff over FWA fundamental watersheds, which stop at the BC boundary. In the output:
- 76,431 watersheds have `bc_fraction < 0.95`.
- The Columbia at Birchbank reads 0.86.

## Proposed

- Add the transboundary polygons fwapg builds in `extras/xborder` to the accumulation.
- Extend the climr, CGIAR and DEM grids to cover them. climr covers North America, CGIAR the globe, and GLO-90 the globe.
- Calibrate on transboundary gauges too (Alberta, Yukon, NWT, Washington, Idaho, Montana), as Chapman et al. (2018) did in the plains.

Relates to #11.

---

## 2. Evapotranspiration in the semi-arid interior (land-cover and alternative-AET experiments)

**If we do it:** the southern interior plateaus stop being overpredicted by 1.5–2.5×, and the open estimate becomes usable there. **If we never do:** runoff in hydrologic zones 15, 17, 23 and 24 (Fraser Plateau, Thompson Plateaus, Okanagan Highland) stays biased high by a factor of two or more, and small headwater basins there dominate the model's error.

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

---

## 3. Snow predictors for the monthly shares

**If we do it:** the monthly split may improve where timing is snowmelt-driven. The median blocked-CV NSE on the shares is 0.87; zones 27–29 are at about 0.5. **If we never do:** the monthly shares keep using monthly P, T and AET only.

## Proposed

Add `cd`'s ERA5-Land `snowmelt_doy_50` and `swe_max` (1981–2010 baseline via `cd_baseline()`) as upstream-mean predictors in `wet_share_fit()`. Keep them only if blocked-CV skill on the shares improves.

Relates to #11.

---

## 4. UPSTREAM (bcgov/climr): outward-facing, needs explicit approval before anything is posted

> **`input_obs_ts(dataset = "climatena")` is NA over coastal islands, so gridded `downscale_core()` with `obs_ts` leaves them empty**
>
> On the 1-degree ClimateNA observed time series, cells over Haida Gwaii and northern Vancouver Island are NA (e.g. lon -132.1, lat 53.3). Bilinear interpolation of the anomaly onto a DEM raster then returns NA for all land there, while `downscale()` on the same points through the database route returns values, and the MSWX blend (0.5 degree) covers them.
> Repro: `climr::input_obs_ts("climatena", bbox = c(-133, -131, 52, 54.2), years = 1981)[[1]]` and `terra::extract()` at (-132.1, 53.3) gives NA. climr 0.2.2 (bcgov/climr@36edf57).
