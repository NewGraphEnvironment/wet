# Changelog

## wet 0.2.1

- The segment discharge article is reordered for readers: what mean
  annual discharge is, which estimate to use and why, how close the open
  water balance comes at 290 gauges, the Salmon River and Bulkley River
  as maps that hold every gauge they name, and limits in order of what
  affects a user. fwapg (PCIC) is now scored at the 168 gauges it
  covers: it is closer there (25.5 % against 30.5 % mean absolute
  error), and the article recommends the balance everywhere on the
  strength of its coverage and open code, stating that gap
  ([\#39](https://github.com/NewGraphEnvironment/wet/issues/39)).

## wet 0.2.0

- [`wet_temp_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_daily.md)
  starts a `wet_temp_*` family: daily mean, minimum and maximum water
  temperature at about 300 hydrometric stations from the water-temp-bc
  archive, in each station’s local standard time, in the shape
  [`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)
  takes. Departures are against 2016-2025, since few stations have
  year-round records before the 2010s
  ([\#36](https://github.com/NewGraphEnvironment/wet/issues/36)).

## wet 0.1.1

- Hex sticker, and a README that follows fresh, link and drift: install,
  prerequisites, a station example, vignettes and the package ecosystem.

## wet 0.1.0

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

- A pkgdown site and the first vignette, *Chinook flow at two stations*
  ([\#27](https://github.com/NewGraphEnvironment/wet/issues/27)). It
  maps Buck Creek and Bulkley nr Houston and their nested catchments,
  then compares the last five years with 1981-2010 in the three
  open-water Chinook windows (migration, spawning, fry migration), from
  bundled data (`data-raw/station_vignette_data.R`,
  `data-raw/station_vignette_map.R`). Every window at both stations was
  below its 1981-2010 mean in 2023-2026, and 21 of the 24 station-window
  values from those years were drier than nine baseline years in ten.

- A second vignette, *Mean annual discharge per segment*
  ([\#28](https://github.com/NewGraphEnvironment/wet/issues/28)). It
  reproduces fwapg’s discharge on the 9,000 Salmon River (SALR) segments
  it gives a value, and shows how area-weighted sampling moves small
  watersheds. It maps discharge per segment for SALR and for the Bulkley
  (BULK), where fwapg has none and the open water balance is the only
  estimate, and plots the balance’s blocked-CV skill at 290 HYDAT gauges
  by zone. On SALR the balance runs a median 1.47 times PCIC. At the
  four gauges within 30 km of SALR and its outlet gauge, the balance is
  high at all five. PCIC is within 5 % at the two small basins and low
  at the three large ones. Data from `data-raw/segment_vignette_data.R`
  and `data-raw/segment_vignette_map.R`.
