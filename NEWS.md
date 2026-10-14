# wet 0.4.1

* The segment-discharge article now introduces the published product (#64): where it is, what a row holds, how to read it with `wet_catalog()`, `wet_db_load()` or duckdb, what `pick` selects, how each source was made, and how both score at the 315 calibration gauges, with the Salmon River as the one worked group. The values it shows are read from the published parts and checked against their sources before they are bundled. `scripts/discharge_publish.R` now reads each part it writes back and compares the flows, and the segment rows' runoff, coverage and `pick`, value by value with what they were built from: on build 7c62b9e, 555,857,796 values with none differing, and all 67 parts identical to the live upload. The fwapg parity and sampling results moved to `research/fwapg_mad_method.md`.

# wet 0.4.0

* Per-segment and per-watershed discharge have a published layout at `s3://fresh-bc/discharge/fwa/v1/` (#7): Hive-partitioned parquet keyed `scenario` / `forcing` / `source`, one part per FWA top-level drainage with one row group per watershed group, and a `manifest.json` describing every part, because the bucket allows reads but no listing. `wet_catalog()` reads the manifest. `wet_db_load()` loads one scenario of a dataset into Postgres (`discharge.fwa_v1_segment_monthly` or `discharge.fwa_v1_watershed_monthly`), checking each part's size and md5 first, so fresh can join `month = 0 AND pick`. `scripts/discharge_publish.R` conforms each part to its crate schema (crate 0.7.0), builds the tree and writes a tracked report. Uploading is a separate, explicit step and has not been run yet. One dataset ID, `<variable>/<network>/<version>/<unit>_<timebase>`, names the S3 prefix, the crate schema and the table (`research/discharge_publish.md`).

# wet 0.3.2

* FWA segments now carry both estimates where each exists, PCIC's routed flow (NewGraphEnvironment/fwapg#6) and the open water balance, labelled by `source` and `period`, with a logical `pick` marking the default (#57). `scripts/segment_output.R` writes them per basin as `linear_feature_id, month, runoff_mm, q_m3s, coverage, source, period, pick`. The default is routed unless its mean annual flow is under 0.2 of the balance's, and only a segment on its watershed's own line can fall to the balance, because the balance reaches a segment through `fwa_streams_watersheds_lut` and off that line it is another line's flow. 224,199 of 3,374,133 segments with both sources fall to the balance, 26.7 % of them in the Nechako Reservoir groups, where PCIC's outlets are almost all unplaced (NewGraphEnvironment/fwapg#24). At the 290 calibration gauges routed flow covers, the pick's mean absolute error is 22.9 % against routed's 24.1 % and the balance's 27.6 %. The 369,217 segments with no lut row get neither. The balance stays the independent estimate both are scored against.

# wet 0.3.1

* The segment vignette compares the open water balance with PCIC's routed flow (NewGraphEnvironment/fwapg#6) instead of fwapg's older annual table (#58): the table of strengths and limits, the scatter, the province coverage outline, the Salmon River pair and the Bulkley gauges. At the 290 of 315 calibration gauges routed flow covers, its mean absolute error is 24.1 % against the held-out balance's 27.6 % (median 13.0 against 18.0); by mean error the balance is closer in the Peace and the Fraser. Where the older annual table also had values, the two PCIC products tie once 7 far-low gauges are set aside, so what routed flow adds is coverage: the coast and the largest rivers. The scores come from `scripts/pcic_routed_compare.R`, whose report records the fwapg commit and the table's fingerprint, and the vignette's data script refuses any other build.

# wet 0.3.0

* `wet_temp_fill()` fills gaps in daily water temperature at stations, loggers included (#40). Air2stream is run open-loop on daily air temperature from `cd::cd_extract_daily()`, and a Kalman smoother carries each station's departure from it across a gap, from both ends, adding the error its peers in the same `pool` saw that day. Held out at 999 station-years, it beats air2stream alone on every gap: 0.48 against 1.31 °C on 7 days, 0.76 against 1.43 °C on 30 days, 0.84 against 1.14 °C on a seasonal logger's spring and autumn. Over a whole missing season its GSDD is no better than air2stream alone (130 against 129 °C-days), the one criterion of a rule fixed beforehand that it fails. `wet_temp_gsdd()` gives growing season degree days per station-year in `wet_window_stats()`'s long format, with the share of each season that was filled. At the 17 Skeena stations, every site's GSDD lies inside the network model's 95 % interval (`hill_etal2025Spatialstream`).

# wet 0.2.5

* The dry-interior gauges are scored against licensed water use above them, under a rule fixed before any licence was matched to a gauge (#53). BC water rights licences, placed upstream of each calibration gauge on the FWA network, account for 0–2 mm/yr above the zone-24 gauges against overshoots of 26–245 mm; returning all of it moves zone 24's held-out error by half a point. Diversions above the gauges do not explain the overshoot. The shipped estimate does not change.

# wet 0.2.4

* Climr precipitation is scored against the River Forecast Centre's plateau-elevation precipitation gauges and snow courses, under a rule fixed before any product value was computed (#50). climr is at most modestly high on the dry plateaus relative to the rest of the interior (dry over contrast 1.09, not decided), and part of #45's gap between climr and PNWNAmet is PNWNAmet's. Precipitation alone does not explain zone 24's overshoot; the next check is gauges with water taken out upstream (#53). The shipped estimate does not change.

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
