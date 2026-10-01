# wet (development version)

* Package scaffold, PCIC VIC-GL OPeNDAP subsetting, annual/monthly runoff
  aggregation, upstream area weighting and an fwapg MAD parity check (#1).

* Join-free upstream accumulation over FWA codes (`wet_upstream_sums()`,
  `wet_upstream_irregular()`, `wet_ws_fetch()`): whole basins, no order-8
  skip. `wet_upstream_mean()` now takes `(ws, values, denom, irregular_pairs,
  upstream_area)` instead of a pairs table. `wet_pcic_annual()` fetches PCIC
  one year at a time; `scripts/mad_basin.R` builds the Fraser (#2).

* An open, province-wide water balance after Chapman et al. (2018), the
  BC Water Tools method, validated out of sample at 290 HYDAT stations (#11).
  - Inputs: CGIAR AET (`wet_cgiar_aet()`), a GLO-90 DEM (`wet_dem_glo90()`)
    and climr 1981-2010 normals (`wet_climr_normals()`).
  - Stations: `wet_station_select()`, `wet_station_monthly()`,
    `wet_station_snap()`, shared with #6.
  - Multi-layer sampling and accumulation: `wet_ws_sample()` now takes
    several layers; `wet_upstream_means()`.
  - The Chapman fit and monthly shares: `wet_wb_fit()`, `wet_wb_adjust()`,
    `wet_wb_pooled()`, `wet_share_fit()`, `wet_share_predict()`.
  - Blocked cross-validation: `wet_cv_folds()`, `wet_flow_validate()`.
  - Out of sample, the zone adjustment improves annual runoff only slightly
    (blocked-CV mean absolute error 33.1 % against 34.7 % raw), and passes its
    gate only under a variant added after the pre-set specification failed.
    The `scripts/wb_output.R` province output applies it, with the monthly
    shares. See `research/water_balance_method.md`.
  - `wet_mm_to_m3s()` gains `days`; `wet_month_days()` is new.

* The water balance's annual AET is now CGIAR floored by a Fu-Budyko AET,
  chosen from four candidates by a rule fixed before scoring (#15). Blocked-CV
  mean absolute error on annual runoff drops from 33.1 % to 27.7 % (headwater
  basins 38.1 % to 31.2 %; 32.3 % under a fully nested selection), mostly on
  the dry interior plateaus.
  - New: `wet_pet_hargreaves()`, `wet_aet_budyko()`, `wet_aet_landcover()`,
    `wet_chapman_table3()`, `wet_landcover_nrcan()`, `wet_terraclimate_aet()`.
  - Chapman's land-cover AET ratios, built from their published Table 3,
    make the interior worse; see `research/water_balance_method.md`.
  - `scripts/wb_validate.R` scores one AET variant per run, and
    `scripts/wb_aet_compare.R` applies the rule. Shipping is tied to the
    comparison and to the current scoring code.

* MOD16A3GF v061 annual ET (`wet_mod16_aet()`) was scored as a challenger to
  the shipped AET under a rule fixed before scoring (#18). It improves on CGIAR
  alone but not on CGIAR floored by Fu-Budyko, which stays: headwater MAE is
  36.3 % for MOD16 and 34.6 % for max(CGIAR, MOD16), against 31.2 %.
  `scripts/wb_aet_compare.R` now re-runs #15's comparison, which must
  reproduce, before the #18 one. See `research/water_balance_method.md`.

* The input builders `wet_cgiar_aet()`, `wet_dem_glo90()` and
  `wet_climr_normals()`, and the hydrologic-zones grid in
  `scripts/wb_inputs.R`, now key their caches on a method version (and the
  normals on climr's version too), so a builder change never reuses an old
  file (#19). Existing caches rebuild once under the new names; re-run under
  them, the water balance reproduces every shipped number.

* Flow departure at hydrometric stations (#25).
  - `wet_station_daily()` gives one daily flow series per station, from
    approved HYDAT through ECCC provisional daily means (the water-temp-bc
    archive) to real-time. Each source continues the one before it, from its
    whole record. Ported from `ngr::ngr_hyd_q_daily()`.
  - `wet_window_stats()` summarises any daily series over month-day windows
    once per year, in cd's long format, and `wet_windows_calendar()` supplies
    the calendar windows. Departure and trend come from cd.
  - `scripts/station_departure.R` runs it for real-time stations. At Buck
    Creek and Bulkley nr Houston, 2023-2026 summer and early-fall flow ran
    54-87 % below the 1981-2010 mean. Provisional winter flows are
    uncorrected ice readings; see `research/station_flow_departure.md`.

* A pkgdown site and the first vignette, *Flow in species windows at two
  stations* (#27). It runs the station path on Buck Creek and Bulkley nr
  Houston from bundled data (`data-raw/station_vignette_data.R`): the record
  by source, the hydrograph against its 1981-2010 median with the BULK species
  windows beneath, departure per window and year, and trends. Chinook spawning
  flow was 58-81 % below the 1981-2010 mean at both stations in every year
  2023-2026.
