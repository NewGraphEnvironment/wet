# Package index

## Published discharge

Read the per-segment and per-watershed discharge wet publishes.

- [`wet_catalog()`](https://newgraphenvironment.github.io/wet/reference/wet_catalog.md)
  : Published discharge: the parts a manifest lists
- [`wet_db_load()`](https://newgraphenvironment.github.io/wet/reference/wet_db_load.md)
  : Load one scenario of published discharge into Postgres
- [`wet_segment_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_segment_monthly.md)
  : Monthly and annual flow on FWA segments

## Station flow

Daily and monthly flow at hydrometric stations, and the gauges the water
balance is fitted at.

- [`wet_station_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_station_daily.md)
  : Daily flow at hydrometric stations, from HYDAT through to the
  present
- [`wet_station_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_station_monthly.md)
  : Observed monthly and annual flow climatology at HYDAT stations
- [`wet_station_doy()`](https://newgraphenvironment.github.io/wet/reference/wet_station_doy.md)
  : Observed day-of-year flow climatology at HYDAT stations
- [`wet_station_select()`](https://newgraphenvironment.github.io/wet/reference/wet_station_select.md)
  : Natural-flow HYDAT stations with a usable record in a period
- [`wet_station_snap()`](https://newgraphenvironment.github.io/wet/reference/wet_station_snap.md)
  : Snap HYDAT stations to FWA fundamental watersheds, checked by
  drainage area

## Water temperature

Daily water temperature at stations, gap filling and growing season
degree days.

- [`wet_temp_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_daily.md)
  : Daily water temperature at hydrometric stations
- [`wet_temp_fill()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_fill.md)
  : Daily water temperature with gaps filled from air temperature
- [`wet_temp_gsdd()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_gsdd.md)
  : Growing season degree days per station-year

## Date windows

Define month-day windows, and take mean flow or per-year statistics of
flow or temperature over them.

- [`wet_flow_window()`](https://newgraphenvironment.github.io/wet/reference/wet_flow_window.md)
  : Mean flow over date windows, from monthly or daily means
- [`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)
  : Statistics of a daily series over date windows, one value per year
- [`wet_windows_calendar()`](https://newgraphenvironment.github.io/wet/reference/wet_windows_calendar.md)
  : Calendar months and seasons as date windows

## PCIC gridded runoff

Fetch PCIC VIC-GL gridded variables and summarise them per year.

- [`wet_pcic_url()`](https://newgraphenvironment.github.io/wet/reference/wet_pcic_url.md)
  : OPeNDAP URL for one PCIC VIC-GL gridded variable
- [`wet_pcic_index()`](https://newgraphenvironment.github.io/wet/reference/wet_pcic_index.md)
  : OPeNDAP index ranges for a bounding box and date range on the PCIC
  grid
- [`wet_pcic_fetch()`](https://newgraphenvironment.github.io/wet/reference/wet_pcic_fetch.md)
  : Download a PCIC VIC-GL subset over OPeNDAP
- [`wet_pcic_annual()`](https://newgraphenvironment.github.io/wet/reference/wet_pcic_annual.md)
  : Mean annual total per cell, fetched one year at a time
- [`wet_runoff_annual()`](https://newgraphenvironment.github.io/wet/reference/wet_runoff_annual.md)
  : Mean annual total per cell from a daily raster

## Watersheds and upstream accumulation

Sample a grid to FWA fundamental watersheds, average it over each
upstream area, and convert the result to discharge.

- [`wet_ws_fetch()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_fetch.md)
  : Fundamental watersheds of one basin, with codes, area and centroid

- [`wet_ws_geom()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_geom.md)
  : Fundamental watershed polygons of one watershed group

- [`wet_ws_sample()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_sample.md)
  : Cell values for each fundamental watershed

- [`wet_upstream_mean()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_mean.md)
  : Area-weighted mean over each watershed's upstream area

- [`wet_upstream_means()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_means.md)
  : Area-weighted upstream means of several sampled layers

- [`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md)
  : Upstream sums of additive quantities for every fundamental watershed

- [`wet_upstream_irregular()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_irregular.md)
  :

  `FWA_Upstream` pairs for the irregularly coded polygons of one basin

- [`wet_upstream_pairs()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_pairs.md)
  : Watershed-to-upstream-polygon pairs for one watershed group, from
  fwapg

- [`wet_mm_to_m3s()`](https://newgraphenvironment.github.io/wet/reference/wet_mm_to_m3s.md)
  : Convert a depth over an area to discharge

- [`wet_month_days()`](https://newgraphenvironment.github.io/wet/reference/wet_month_days.md)
  : Days in each month, with February at 28.25

## Water balance inputs

Climate normals, evapotranspiration, terrain, land cover and snow, and
the evapotranspiration models applied to them.

- [`wet_climr_normals()`](https://newgraphenvironment.github.io/wet/reference/wet_climr_normals.md)
  : Monthly climate normals for an arbitrary period from climr
- [`wet_cgiar_aet()`](https://newgraphenvironment.github.io/wet/reference/wet_cgiar_aet.md)
  : Actual evapotranspiration from the CGIAR Global Soil-Water Balance
- [`wet_terraclimate_aet()`](https://newgraphenvironment.github.io/wet/reference/wet_terraclimate_aet.md)
  : Annual AET and precipitation from the TerraClimate 1981-2010
  climatology
- [`wet_mod16_aet()`](https://newgraphenvironment.github.io/wet/reference/wet_mod16_aet.md)
  : Annual AET on a grid from MODIS MOD16A3GF v061
- [`wet_aet_budyko()`](https://newgraphenvironment.github.io/wet/reference/wet_aet_budyko.md)
  : Actual evapotranspiration from Fu's Budyko curve
- [`wet_aet_landcover()`](https://newgraphenvironment.github.io/wet/reference/wet_aet_landcover.md)
  : Adjust modelled AET by land cover, as Chapman et al. (2018) did
- [`wet_chapman_table3()`](https://newgraphenvironment.github.io/wet/reference/wet_chapman_table3.md)
  : Measured AET by land-cover class (Chapman et al. 2018, Table 3)
- [`wet_pet_hargreaves()`](https://newgraphenvironment.github.io/wet/reference/wet_pet_hargreaves.md)
  : Monthly reference evapotranspiration by Hargreaves (FAO-56)
- [`wet_dem_glo90()`](https://newgraphenvironment.github.io/wet/reference/wet_dem_glo90.md)
  : Elevation on a template grid from the Copernicus GLO-90 DEM
- [`wet_landcover_nrcan()`](https://newgraphenvironment.github.io/wet/reference/wet_landcover_nrcan.md)
  : Land-cover fractions on a grid from the NRCan 2020 land cover
- [`wet_snow_normals()`](https://newgraphenvironment.github.io/wet/reference/wet_snow_normals.md)
  : Snow normals from cd's ERA5-Land annual snow layers

## Water balance fit and validation

Fit the balance at HYDAT gauges, split it into months and score it held
out.

- [`wet_wb_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_wb_fit.md)
  : Fit the gauge-residual adjustment of the annual water balance
- [`wet_wb_adjust()`](https://newgraphenvironment.github.io/wet/reference/wet_wb_adjust.md)
  : Apply a fitted water-balance adjustment
- [`wet_wb_pooled()`](https://newgraphenvironment.github.io/wet/reference/wet_wb_pooled.md)
  : Zones to pool in a water-balance fit
- [`wet_share_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_share_fit.md)
  : Fit the monthly share-of-annual-runoff model
- [`wet_share_predict()`](https://newgraphenvironment.github.io/wet/reference/wet_share_predict.md)
  : Predict monthly shares of annual runoff
- [`wet_shape_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_fit.md)
  : Fit a within-month daily shape at gauges
- [`wet_shape_predict()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_predict.md)
  [`wet_shape_flat()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_predict.md)
  [`wet_shape_spline()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_predict.md)
  [`wet_shape_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_predict.md)
  : Within-month weights for watersheds, and the daily flows they give
- [`wet_cv_folds()`](https://newgraphenvironment.github.io/wet/reference/wet_cv_folds.md)
  : Cross-validation folds for gauges on one stream network
- [`wet_flow_validate()`](https://newgraphenvironment.github.io/wet/reference/wet_flow_validate.md)
  : Skill of modelled runoff against observed runoff at gauges
