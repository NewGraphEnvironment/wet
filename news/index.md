# Changelog

## wet (development version)

- Package scaffold, PCIC VIC-GL OPeNDAP subsetting, annual/monthly
  runoff aggregation, upstream area weighting and an fwapg MAD parity
  check ([\#1](https://github.com/NewGraphEnvironment/wet/issues/1)).

- Join-free upstream accumulation over FWA codes
  ([`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md),
  [`wet_upstream_irregular()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_irregular.md),
  [`wet_ws_fetch()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_fetch.md)):
  whole basins, no order-8 skip.
  [`wet_upstream_mean()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_mean.md)
  now takes `(ws, values, denom, irregular_pairs, upstream_area)`
  instead of a pairs table.
  [`wet_pcic_annual()`](https://newgraphenvironment.github.io/wet/reference/wet_pcic_annual.md)
  fetches PCIC one year at a time; `scripts/mad_basin.R` builds the
  Fraser ([\#2](https://github.com/NewGraphEnvironment/wet/issues/2)).

- An open, province-wide water balance after Chapman et al. (2018), the
  BC Water Tools method, validated out of sample at 290 HYDAT stations
  ([\#11](https://github.com/NewGraphEnvironment/wet/issues/11)).

  - Inputs: CGIAR AET
    ([`wet_cgiar_aet()`](https://newgraphenvironment.github.io/wet/reference/wet_cgiar_aet.md)),
    a GLO-90 DEM
    ([`wet_dem_glo90()`](https://newgraphenvironment.github.io/wet/reference/wet_dem_glo90.md))
    and climr 1981-2010 normals
    ([`wet_climr_normals()`](https://newgraphenvironment.github.io/wet/reference/wet_climr_normals.md)).
  - Stations:
    [`wet_station_select()`](https://newgraphenvironment.github.io/wet/reference/wet_station_select.md),
    [`wet_station_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_station_monthly.md),
    [`wet_station_snap()`](https://newgraphenvironment.github.io/wet/reference/wet_station_snap.md),
    shared with
    [\#6](https://github.com/NewGraphEnvironment/wet/issues/6).
  - Multi-layer sampling and accumulation:
    [`wet_ws_sample()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_sample.md)
    now takes several layers;
    [`wet_upstream_means()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_means.md).
  - The Chapman fit and monthly shares:
    [`wet_wb_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_wb_fit.md),
    [`wet_wb_adjust()`](https://newgraphenvironment.github.io/wet/reference/wet_wb_adjust.md),
    [`wet_wb_pooled()`](https://newgraphenvironment.github.io/wet/reference/wet_wb_pooled.md),
    [`wet_share_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_share_fit.md),
    [`wet_share_predict()`](https://newgraphenvironment.github.io/wet/reference/wet_share_predict.md).
  - Blocked cross-validation:
    [`wet_cv_folds()`](https://newgraphenvironment.github.io/wet/reference/wet_cv_folds.md),
    [`wet_flow_validate()`](https://newgraphenvironment.github.io/wet/reference/wet_flow_validate.md).
  - Out of sample, the zone adjustment improves annual runoff only
    slightly (blocked-CV mean absolute error 33.1 % against 34.7 % raw),
    and passes its gate only under a variant added after the pre-set
    specification failed. The `scripts/wb_output.R` province output
    applies it, with the monthly shares. See
    `research/water_balance_method.md`.
  - [`wet_mm_to_m3s()`](https://newgraphenvironment.github.io/wet/reference/wet_mm_to_m3s.md)
    gains `days`;
    [`wet_month_days()`](https://newgraphenvironment.github.io/wet/reference/wet_month_days.md)
    is new.

- The water balance’s annual AET is now CGIAR floored by a Fu-Budyko
  AET, chosen from four candidates by a rule fixed before scoring
  ([\#15](https://github.com/NewGraphEnvironment/wet/issues/15)).
  Blocked-CV mean absolute error on annual runoff drops from 33.1 % to
  27.7 % (headwater basins 38.1 % to 31.2 %; 32.3 % under a fully nested
  selection), mostly on the dry interior plateaus.

  - New:
    [`wet_pet_hargreaves()`](https://newgraphenvironment.github.io/wet/reference/wet_pet_hargreaves.md),
    [`wet_aet_budyko()`](https://newgraphenvironment.github.io/wet/reference/wet_aet_budyko.md),
    [`wet_aet_landcover()`](https://newgraphenvironment.github.io/wet/reference/wet_aet_landcover.md),
    [`wet_chapman_table3()`](https://newgraphenvironment.github.io/wet/reference/wet_chapman_table3.md),
    [`wet_landcover_nrcan()`](https://newgraphenvironment.github.io/wet/reference/wet_landcover_nrcan.md),
    [`wet_terraclimate_aet()`](https://newgraphenvironment.github.io/wet/reference/wet_terraclimate_aet.md).
  - Chapman’s land-cover AET ratios, built from their published Table 3,
    make the interior worse; see `research/water_balance_method.md`.
  - `scripts/wb_validate.R` scores one AET variant per run, and
    `scripts/wb_aet_compare.R` applies the rule. Shipping is tied to the
    comparison and to the current scoring code.

- MOD16A3GF v061 annual ET
  ([`wet_mod16_aet()`](https://newgraphenvironment.github.io/wet/reference/wet_mod16_aet.md))
  was scored as a challenger to the shipped AET under a rule fixed
  before scoring
  ([\#18](https://github.com/NewGraphEnvironment/wet/issues/18)). It
  improves on CGIAR alone but not on CGIAR floored by Fu-Budyko, which
  stays: headwater MAE is 36.3 % for MOD16 and 34.6 % for max(CGIAR,
  MOD16), against 31.2 %. `scripts/wb_aet_compare.R` now re-runs
  [\#15](https://github.com/NewGraphEnvironment/wet/issues/15)’s
  comparison, which must reproduce, before the
  [\#18](https://github.com/NewGraphEnvironment/wet/issues/18) one. See
  `research/water_balance_method.md`.

- The input builders
  [`wet_cgiar_aet()`](https://newgraphenvironment.github.io/wet/reference/wet_cgiar_aet.md),
  [`wet_dem_glo90()`](https://newgraphenvironment.github.io/wet/reference/wet_dem_glo90.md)
  and
  [`wet_climr_normals()`](https://newgraphenvironment.github.io/wet/reference/wet_climr_normals.md),
  and the hydrologic-zones grid in `scripts/wb_inputs.R`, now key their
  caches on a method version (and the normals on climr’s version too),
  so a builder change never reuses an old file
  ([\#19](https://github.com/NewGraphEnvironment/wet/issues/19)).
  Existing caches rebuild once under the new names; re-run under them,
  the water balance reproduces every shipped number.

- Flow departure at hydrometric stations
  ([\#25](https://github.com/NewGraphEnvironment/wet/issues/25)).

  - [`wet_station_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_station_daily.md)
    gives one daily flow series per station, from approved HYDAT through
    ECCC provisional daily means (the water-temp-bc archive) to
    real-time. Each source continues the one before it, from its whole
    record. Ported from `ngr::ngr_hyd_q_daily()`.
  - [`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)
    summarises any daily series over month-day windows once per year, in
    cd’s long format, and
    [`wet_windows_calendar()`](https://newgraphenvironment.github.io/wet/reference/wet_windows_calendar.md)
    supplies the calendar windows. Departure and trend come from cd.
  - `scripts/station_departure.R` runs it for real-time stations. At
    Buck Creek and Bulkley nr Houston, 2023-2026 summer and early-fall
    flow ran 54-87 % below the 1981-2010 mean. Provisional winter flows
    are uncorrected ice readings; see
    `research/station_flow_departure.md`.

- A pkgdown site and the first vignette, *Flow in species windows at two
  stations*
  ([\#27](https://github.com/NewGraphEnvironment/wet/issues/27)). It
  runs the station path on Buck Creek and Bulkley nr Houston from
  bundled data (`data-raw/station_vignette_data.R`): the record by
  source, the hydrograph against its 1981-2010 median with the BULK
  species windows beneath, departure per window and year, and trends.
  Chinook spawning flow was 58-81 % below the 1981-2010 mean at both
  stations in every year 2023-2026.
