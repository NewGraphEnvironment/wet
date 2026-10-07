# wet 0.2.3

* The open water balance's overshoot in the dry interior (hydrologic zones 15, 17, 23 and 24) is diagnosed against PCIC VIC-GL's split of precipitation and evapotranspiration, under a rule fixed before any PCIC value was computed (#45). Neither term is named: our precipitation runs 1.4–1.6 times PCIC's there, and our AET offsets most of the difference. The dry zones differ from the rest in precipitation, not AET, so the next check is precipitation observed at plateau elevation. The shipped estimate does not change.

* The README and package description now cover the water-temperature path, and no longer claim seasonal or climate-scenario output, which no script builds.

# wet 0.2.2

* The open water balance is refit on HYDAT 2026-07-17 (#43). The pipeline now keeps one fit per HYDAT release (`WET_HYDAT` names the file), and the 2025-10-14 fit is reproduced exactly beside it. The new fit has 315 calibration gauges and a held-out mean absolute error of 27.5 % (headwater 30.7 %, nested 17.6 %). Pooled zones get no adjustment, settled on short-record gauges no fit uses, which retires the "mildly optimistic" caveat. The zone adjustment ties raw P − AET on headwater gauges and is kept by a recorded decision because it corrects the major rivers (#47 revisits the gate).

* The segment discharge article compares the two estimates in a table of each one's strengths and limits, with guidance on which suits which job, in place of a single recommendation. PCIC's model fits gauges more closely where fwapg has a value; the open water balance covers all of BC and ships its code.

# wet 0.2.1

* The segment discharge article is reordered for readers: what mean annual discharge is, which estimate to use and why, how close the open water balance comes at 290 gauges, the Salmon River and Bulkley River as maps that hold every gauge they name, and limits in order of what affects a user. fwapg (PCIC) is now scored at the 168 gauges it covers: it is closer there (25.5 % against 30.5 % mean absolute error), and the article recommends the balance everywhere on the strength of its coverage and open code, stating that gap (#39).

# wet 0.2.0

* `wet_temp_daily()` starts a `wet_temp_*` family: daily mean, minimum and maximum water temperature at about 300 hydrometric stations from the water-temp-bc archive, in each station's local standard time, in the shape `wet_window_stats()` takes. Departures are against 2016-2025, since few stations have year-round records before the 2010s (#36).

# wet 0.1.1

* Hex sticker, and a README that follows fresh, link and drift: install, prerequisites, a station example, vignettes and the package ecosystem.

# wet 0.1.0

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

* A pkgdown site and the first vignette, *Chinook flow at two stations* (#27).
  It maps Buck Creek and Bulkley nr Houston and their nested catchments, then
  compares the last five years with 1981-2010 in the three open-water Chinook
  windows (migration, spawning, fry migration), from bundled data
  (`data-raw/station_vignette_data.R`, `data-raw/station_vignette_map.R`).
  Every window at both stations was below its 1981-2010 mean in 2023-2026, and
  21 of the 24 station-window values from those years were drier than nine
  baseline years in ten.

* A second vignette, *Mean annual discharge per segment* (#28). It reproduces
  fwapg's discharge on the 9,000 Salmon River (SALR) segments it gives a value, and shows how
  area-weighted sampling moves small watersheds. It maps discharge per segment
  for SALR and for the Bulkley (BULK), where fwapg has none and the open water
  balance is the only estimate, and plots the balance's blocked-CV skill at
  290 HYDAT gauges by zone. On SALR the balance runs a median 1.47 times PCIC.
  At the four gauges within 30 km of SALR and its outlet gauge, the balance is
  high at all five. PCIC is within 5 % at the two small basins and low at the
  three large ones. Data from `data-raw/segment_vignette_data.R` and
  `data-raw/segment_vignette_map.R`.
