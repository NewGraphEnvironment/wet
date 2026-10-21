# Changelog

## wet 0.4.16

- Per-segment daily flow is published as
  `discharge/fwa/v1/segment_daily`
  ([\#99](https://github.com/NewGraphEnvironment/wet/issues/99)): every
  FWA segment’s mean flow on each day of a 365-day year (29 February
  folded into 28), for both sources, one parquet part per source and
  watershed group (2,886,046,240 rows in build 77585a8). The balance’s
  days are its published months laid on the fit’s daily shape
  ([\#70](https://github.com/NewGraphEnvironment/wet/issues/70)), so
  each month’s days average to it. Routed PCIC’s days are routed from
  fwapg’s sub-basin climatology and segment weights, clamped at zero and
  rounded as fwapg makes its months; the months rebuilt from them equal
  fwapg’s on every segment, and their plain mean need not equal the
  published month (the clamp, and February’s fold).
  [`wet_segment_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_segment_daily.md)
  reads them for named groups, `wet_db_load(doys =, groups =)` loads a
  subset, and `wet_values_compare(time = "doy")` compares them. The
  segment-discharge article shows the read.
- The package is cited by its Zenodo concept DOI (`Config/DOI`, read by
  `citation("wet")`).

## wet 0.4.15

- The water balance’s monthly shares come from donor gauges
  ([\#102](https://github.com/NewGraphEnvironment/wet/issues/102)): each
  watershed takes the inverse-distance mean of the observed monthly
  shares of the five calibration gauges most like it in elevation,
  location, snowmelt timing and peak snow water equivalent
  (`wet_share_fit(method = "donor")`; `"blend"` and the twelve
  regressions remain as methods). A rule registered in
  `scripts/wb_validate.R` before any candidate was coded chose it: held
  out, the median per-gauge share NSE rises from 0.874 to 0.939 (0.935
  with each gauge’s upstream and downstream neighbours removed), and on
  110 short-record gauges no fit uses from 0.772 to 0.837. The freshet,
  the Liard’s winter and non-snowmelt regimes gain most; four zones (17,
  06, 16 and 26) score lower under the donor. The annual flow and every
  segment’s default source are unchanged. The published product at
  `s3://fresh-bc/discharge/fwa/v1/` was rebuilt and republished with the
  new months (build 8ca2dee), and on a calibration gauge’s segment the
  balance now carries that gauge’s own monthly pattern. The monthly-flow
  article is rewritten on it, including the balance’s late-summer
  overshoot at 08EE003.
  [`wet_shape_predict()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_predict.md)’s
  donor shares its weighting with the shares (`wet_donor_mean()`); its
  output is unchanged.

## wet 0.4.14

- Routed PCIC is read from fwapg’s PNWNAmet historical 1981–2010 run
  instead of 1951–2012
  ([\#103](https://github.com/NewGraphEnvironment/wet/issues/103)), so
  both sources on every segment, and the gauge scores, describe the same
  period. The published product at `s3://fresh-bc/discharge/fwa/v1/` was
  rebuilt and republished from it: 4,733 segments changed their default
  source (3,013 to routed, 1,720 to the balance), and annual skill at
  the gauges barely moved (routed mean absolute error 24.2 %, 24.1 %
  before). Routed’s spring-low, summer-high shape survives on matching
  periods (March–April −11.5 %, July–August +15.8 %), so the period
  explains part of it and PCIC’s model the rest
  ([\#67](https://github.com/NewGraphEnvironment/wet/issues/67)). The
  monthly-flow article’s period section is gone, and both articles,
  their data and the README map are rebuilt on the new build.

## wet 0.4.13

- `wet_segment_monthly(from = "fwapg")` and the routed scripts read
  PCIC’s routed flow from fwapg’s `pcic.discharge_monthly`, for the
  PNWNAmet historical 1951-2012 run, instead of the frozen
  `whse_basemapping.fwa_stream_networks_discharge_monthly`
  ([\#101](https://github.com/NewGraphEnvironment/wet/issues/101)). The
  run equals the frozen table row for row. The table and run are named
  once, in the internal `wet_segment_sources()`. A table without the
  run’s rows is an error that names fwapg’s load files, and the routed
  fingerprint must equal the run’s row in `pcic.runs`. A segment’s
  routed month 0 is now the mean of its months summed in month order,
  which moves its last bits in 11.4 % of routed segments; the published
  product is unchanged until
  [\#103](https://github.com/NewGraphEnvironment/wet/issues/103)
  republishes it.

## wet 0.4.12

- The water balance has a daily shape within the month
  ([\#70](https://github.com/NewGraphEnvironment/wet/issues/70)).
  [`wet_station_doy()`](https://newgraphenvironment.github.io/wet/reference/wet_station_doy.md)
  gives each calibration gauge’s day-of-year record on a 365-day common
  year (29 February folded into 28);
  [`wet_shape_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_fit.md)
  and
  [`wet_shape_predict()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_predict.md)
  (`donor`, `basis`),
  [`wet_shape_flat()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_predict.md)
  and
  [`wet_shape_spline()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_predict.md)
  give within-month weights that sum to 1 per month;
  [`wet_shape_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_predict.md)
  lays monthly means on them, so every calendar month’s mean stays the
  published one and `segment_monthly` is untouched.
  `scripts/wb_shape_daily.R` scores the candidates held out on the
  shipped fit under a rule registered before any candidate existed, and
  donor gauges (k = 5) ship to `fit_20260717/shape_daily.rds`: median
  per-gauge NSE 0.982 against 0.899 for flat months
  (`data/checks/wb_shape_daily_20260717.txt`). Nothing is published yet;
  `segment_daily` for both sources is
  [\#99](https://github.com/NewGraphEnvironment/wet/issues/99), blocked
  on NewGraphEnvironment/fwapg#25.

## wet 0.4.11

- The README is rewritten in plain language
  ([\#75](https://github.com/NewGraphEnvironment/wet/issues/75)). It
  says what wet gives: modelled monthly flow on almost every BC stream,
  published openly, and flow and water temperature at stations in the
  seasons that matter to fish. It shows a province map of where each
  river’s default flow comes from, drawn by `data-raw/readme_figure.R`,
  and a read of the published flow that needs no credentials. It lists
  all three articles. link can now read wet’s published discharge
  (NewGraphEnvironment/link#331). The function reference is grouped by
  purpose, and DESCRIPTION names the two published sources.

## wet 0.4.10

- `data-raw/segment_vignette_data.R` accepts the segment report that the
  tracked publish build read, so a rerun that leaves every published
  part identical needs only a passing BUILD, not a republish
  ([\#93](https://github.com/NewGraphEnvironment/wet/issues/93)). It
  requires that report to be identical to its copy at the build’s
  commit, and the segment article’s data now record its commit
  (`segment_report_commit`). The values are unchanged.

- `citation("wet")` has the key `wet` and a note
  [`knitr::write_bib()`](https://rdrr.io/pkg/knitr/man/write_bib.html)
  keeps, so a report can cite `@wet` and get the publisher and the
  installed version.

## wet 0.4.9

- The monthly-flow article’s data are rebuilt from the shipped fit after
  its rescore under the AET rule that keeps cfu on a near-tie
  ([\#91](https://github.com/NewGraphEnvironment/wet/issues/91)). The
  values are unchanged.

## wet 0.4.8

- The citation names New Graph Environment Ltd. as publisher and funder:
  `citation("wet")` now reads from `inst/CITATION`, and `Authors@R`
  gives the author’s affiliation. The small logo keeps its name clear of
  the icon.

## wet 0.4.7

- Scripts, data scripts and live tests now read a named HYDAT release,
  from one per-user cache
  (`tools::R_user_dir("wet", "cache")/hydat/<release>/`), instead of
  whichever release a machine last downloaded
  ([\#46](https://github.com/NewGraphEnvironment/wet/issues/46)). The
  internal `wet_hydat()` downloads ECCC’s current release into the
  cache, and checks every file is whole and holds the release it is
  named for. `WET_HYDAT_RELEASE` names the release, by default the
  shipped one; `WET_HYDAT` is retired and refused. Station-flow outputs
  record their release. `wet_station_*()` still default to tidyhydat’s
  own directory for interactive use.

## wet 0.4.6

- The published discharge at `s3://fresh-bc/discharge/fwa/v1/` now
  carries the snow-informed monthly balance (build acb820f,
  [\#77](https://github.com/NewGraphEnvironment/wet/issues/77)). Annual
  flow and each segment’s `pick` are unchanged. The monthly-flow
  article’s data were rebuilt from it, and the article now describes the
  snow terms. The balance reads high only in April and May, by a median
  of 7 % to 11 %, and is within 5 % in the other months. The freshet is
  still flattened. `data-raw/monthly_vignette_data.R` reads the held-out
  months each fit stores, instead of recomputing them
  ([\#68](https://github.com/NewGraphEnvironment/wet/issues/68)).

## wet 0.4.5

- The water balance’s monthly shares now also use snow: ERA5-Land’s
  1981-2010 day by which half the snowpack has melted and its peak snow
  water equivalent (capped at 3,000 mm for glacier points), from cd
  through the new
  [`wet_snow_normals()`](https://newgraphenvironment.github.io/wet/reference/wet_snow_normals.md),
  averaged upstream like the other predictors. A rule fixed before
  scoring kept them: the held-out median share NSE rose from 0.856 to
  0.874 on the shipped fit. Winter and early-spring flow is much less
  overpredicted, the spring peak is a little less flattened, and zone 27
  is worse. The annual balance is unchanged
  ([\#16](https://github.com/NewGraphEnvironment/wet/issues/16)). Each
  fit now stores its held-out monthly balance
  ([\#68](https://github.com/NewGraphEnvironment/wet/issues/68)). The
  published discharge still carries the earlier monthly values until
  [\#77](https://github.com/NewGraphEnvironment/wet/issues/77).

## wet 0.4.4

- [`wet_segment_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_segment_monthly.md)
  reads flow per FWA segment and source in the shape of
  [`wet_station_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_station_monthly.md)
  (`linear_feature_id, month, q_m3s, source`), so a gauge comparison is
  a join on `month`
  ([\#59](https://github.com/NewGraphEnvironment/wet/issues/59)). It
  reads the published product, from Postgres after
  [`wet_db_load()`](https://newgraphenvironment.github.io/wet/reference/wet_db_load.md)
  or from the parquet parts through duckdb, or with `from = "fwapg"`
  fwapg’s routed table, which `scripts/pcic_routed_compare.R` scores
  before a publish. A segment with no value comes back as 13 `NA` rows.
  [`wet_flow_window()`](https://newgraphenvironment.github.io/wet/reference/wet_flow_window.md)
  turns monthly means into mean flow over month-day windows, labelled
  `basis = "monthly"`; the monthly article’s read and its Chinook
  windows now go through both, with its numbers unchanged.

## wet 0.4.3

- The segment-discharge article is simpler
  ([\#71](https://github.com/NewGraphEnvironment/wet/issues/71)). It now
  says what the published product is, which value to use, how to read it
  and how good it is, in that order. `pick` has its own early section
  with its rule and the province counts: routed PCIC on 3,152,838
  segments, the balance on 1,380,005, neither on 374,598. One province
  map of the source `pick` takes on main rivers replaces the Salmon
  River maps and the scatter. The map’s picks are read from the live
  published parts by `data-raw/segment_vignette_map.R`, under the guards
  the values script uses. The rename of `pick` to `is_default` at v2 is
  recorded in `research/discharge_publish.md`.

## wet 0.4.2

- A new article covers months 1–12 of the published product
  ([\#65](https://github.com/NewGraphEnvironment/wet/issues/65)): how to
  read one stream’s twelve months, both sources’ hydrographs at three
  Bulkley gauges with the Chinook windows, the flow in each window
  beside the gauge’s daily record, and month-by-month scores at the
  calibration gauges. Held out at all 315, the water balance reads 8–16
  % high from January to May and within ±5 % from June to December, and
  67–96 % low in January–March at the 25 northern gauges routed flow
  does not reach
  ([\#16](https://github.com/NewGraphEnvironment/wet/issues/16)). Routed
  PCIC, at 279 gauges, reads 20 % low in March–April and 19 % high in
  July–August, and its 1951–2012 period explains only part of that
  ([\#67](https://github.com/NewGraphEnvironment/wet/issues/67)). The
  values are read from the published parts and checked against their
  sources before they are bundled (`data-raw/monthly_vignette_data.R`),
  under guards now shared with the segment article
  (`scripts/vignette_data_lib.R`).

## wet 0.4.1

- The segment-discharge article now introduces the published product
  ([\#64](https://github.com/NewGraphEnvironment/wet/issues/64)): where
  it is, what a row holds, how to read it with
  [`wet_catalog()`](https://newgraphenvironment.github.io/wet/reference/wet_catalog.md),
  [`wet_db_load()`](https://newgraphenvironment.github.io/wet/reference/wet_db_load.md)
  or duckdb, what `pick` selects, how each source was made, and how both
  score at the 315 calibration gauges, with the Salmon River as the one
  worked group. The values it shows are read from the published parts
  and checked against their sources before they are bundled.
  `scripts/discharge_publish.R` now reads each part it writes back and
  compares the flows, and the segment rows’ runoff, coverage and `pick`,
  value by value with what they were built from: on build 7c62b9e,
  555,857,796 values with none differing, and all 67 parts identical to
  the live upload. The fwapg parity and sampling results moved to
  `research/fwapg_mad_method.md`.

## wet 0.4.0

- Per-segment and per-watershed discharge have a published layout at
  `s3://fresh-bc/discharge/fwa/v1/`
  ([\#7](https://github.com/NewGraphEnvironment/wet/issues/7)):
  Hive-partitioned parquet keyed `scenario` / `forcing` / `source`, one
  part per FWA top-level drainage with one row group per watershed
  group, and a `manifest.json` describing every part, because the bucket
  allows reads but no listing.
  [`wet_catalog()`](https://newgraphenvironment.github.io/wet/reference/wet_catalog.md)
  reads the manifest.
  [`wet_db_load()`](https://newgraphenvironment.github.io/wet/reference/wet_db_load.md)
  loads one scenario of a dataset into Postgres
  (`discharge.fwa_v1_segment_monthly` or
  `discharge.fwa_v1_watershed_monthly`), checking each part’s size and
  md5 first, so fresh can join `month = 0 AND pick`.
  `scripts/discharge_publish.R` conforms each part to its crate schema
  (crate 0.7.0), builds the tree and writes a tracked report. Uploading
  is a separate, explicit step and has not been run yet. One dataset ID,
  `<variable>/<network>/<version>/<unit>_<timebase>`, names the S3
  prefix, the crate schema and the table
  (`research/discharge_publish.md`).

## wet 0.3.2

- FWA segments now carry both estimates where each exists, PCIC’s routed
  flow (NewGraphEnvironment/fwapg#6) and the open water balance,
  labelled by `source` and `period`, with a logical `pick` marking the
  default
  ([\#57](https://github.com/NewGraphEnvironment/wet/issues/57)).
  `scripts/segment_output.R` writes them per basin as
  `linear_feature_id, month, runoff_mm, q_m3s, coverage, source, period, pick`.
  The default is routed unless its mean annual flow is under 0.2 of the
  balance’s, and only a segment on its watershed’s own line can fall to
  the balance, because the balance reaches a segment through
  `fwa_streams_watersheds_lut` and off that line it is another line’s
  flow. 224,199 of 3,374,133 segments with both sources fall to the
  balance, 26.7 % of them in the Nechako Reservoir groups, where PCIC’s
  outlets are almost all unplaced (NewGraphEnvironment/fwapg#24). At the
  290 calibration gauges routed flow covers, the pick’s mean absolute
  error is 22.9 % against routed’s 24.1 % and the balance’s 27.6 %. The
  369,217 segments with no lut row get neither. The balance stays the
  independent estimate both are scored against.

## wet 0.3.1

- The segment vignette compares the open water balance with PCIC’s
  routed flow (NewGraphEnvironment/fwapg#6) instead of fwapg’s older
  annual table
  ([\#58](https://github.com/NewGraphEnvironment/wet/issues/58)): the
  table of strengths and limits, the scatter, the province coverage
  outline, the Salmon River pair and the Bulkley gauges. At the 290 of
  315 calibration gauges routed flow covers, its mean absolute error is
  24.1 % against the held-out balance’s 27.6 % (median 13.0 against
  18.0); by mean error the balance is closer in the Peace and the
  Fraser. Where the older annual table also had values, the two PCIC
  products tie once 7 far-low gauges are set aside, so what routed flow
  adds is coverage: the coast and the largest rivers. The scores come
  from `scripts/pcic_routed_compare.R`, whose report records the fwapg
  commit and the table’s fingerprint, and the vignette’s data script
  refuses any other build.

## wet 0.3.0

- [`wet_temp_fill()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_fill.md)
  fills gaps in daily water temperature at stations, loggers included
  ([\#40](https://github.com/NewGraphEnvironment/wet/issues/40)).
  Air2stream is run open-loop on daily air temperature from
  [`cd::cd_extract_daily()`](https://newgraphenvironment.github.io/cd/reference/cd_extract_daily.html),
  and a Kalman smoother carries each station’s departure from it across
  a gap, from both ends, adding the error its peers in the same `pool`
  saw that day. Held out at 999 station-years, it beats air2stream alone
  on every gap: 0.48 against 1.31 °C on 7 days, 0.76 against 1.43 °C on
  30 days, 0.84 against 1.14 °C on a seasonal logger’s spring and
  autumn. Over a whole missing season its GSDD is no better than
  air2stream alone (130 against 129 °C-days), the one criterion of a
  rule fixed beforehand that it fails.
  [`wet_temp_gsdd()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_gsdd.md)
  gives growing season degree days per station-year in
  [`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)’s
  long format, with the share of each season that was filled. At the 17
  Skeena stations, every site’s GSDD lies inside the network model’s 95
  % interval (`hill_etal2025Spatialstream`).

## wet 0.2.5

- The dry-interior gauges are scored against licensed water use above
  them, under a rule fixed before any licence was matched to a gauge
  ([\#53](https://github.com/NewGraphEnvironment/wet/issues/53)). BC
  water rights licences, placed upstream of each calibration gauge on
  the FWA network, account for 0–2 mm/yr above the zone-24 gauges
  against overshoots of 26–245 mm; returning all of it moves zone 24’s
  held-out error by half a point. Diversions above the gauges do not
  explain the overshoot. The shipped estimate does not change.

## wet 0.2.4

- Climr precipitation is scored against the River Forecast Centre’s
  plateau-elevation precipitation gauges and snow courses, under a rule
  fixed before any product value was computed
  ([\#50](https://github.com/NewGraphEnvironment/wet/issues/50)). climr
  is at most modestly high on the dry plateaus relative to the rest of
  the interior (dry over contrast 1.09, not decided), and part of
  [\#45](https://github.com/NewGraphEnvironment/wet/issues/45)’s gap
  between climr and PNWNAmet is PNWNAmet’s. Precipitation alone does not
  explain zone 24’s overshoot; the next check is gauges with water taken
  out upstream
  ([\#53](https://github.com/NewGraphEnvironment/wet/issues/53)). The
  shipped estimate does not change.

## wet 0.2.3

- The open water balance’s overshoot in the dry interior (hydrologic
  zones 15, 17, 23 and 24) is diagnosed against PCIC VIC-GL’s split of
  precipitation and evapotranspiration, under a rule fixed before any
  PCIC value was computed
  ([\#45](https://github.com/NewGraphEnvironment/wet/issues/45)).
  Neither term is named: our precipitation runs 1.4–1.6 times PCIC’s
  there, and our AET offsets most of the difference. The dry zones
  differ from the rest in precipitation, not AET, so the next check is
  precipitation observed at plateau elevation. The shipped estimate does
  not change.

- The README and package description now cover the water-temperature
  path, and no longer claim seasonal or climate-scenario output, which
  no script builds.

## wet 0.2.2

- The open water balance is refit on HYDAT 2026-07-17
  ([\#43](https://github.com/NewGraphEnvironment/wet/issues/43)). The
  pipeline now keeps one fit per HYDAT release (`WET_HYDAT` names the
  file), and the 2025-10-14 fit is reproduced exactly beside it. The new
  fit has 315 calibration gauges and a held-out mean absolute error of
  27.5 % (headwater 30.7 %, nested 17.6 %). Pooled zones get no
  adjustment, settled on short-record gauges no fit uses, which retires
  the “mildly optimistic” caveat. The zone adjustment ties raw P − AET
  on headwater gauges and is kept by a recorded decision because it
  corrects the major rivers
  ([\#47](https://github.com/NewGraphEnvironment/wet/issues/47) revisits
  the gate).

- The segment discharge article compares the two estimates in a table of
  each one’s strengths and limits, with guidance on which suits which
  job, in place of a single recommendation. PCIC’s model fits gauges
  more closely where fwapg has a value; the open water balance covers
  all of BC and ships its code.

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
