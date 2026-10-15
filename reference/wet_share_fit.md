# Fit the monthly share-of-annual-runoff regressions

Chapman et al. (2018) split annual runoff into months with one
regression per month of each month's share of the annual total. Here the
response is the observed share (from monthly volumes,
[`wet_station_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_station_monthly.md))
and the predictors, fixed in advance, are upstream means: that month's
precipitation, temperature and AET plus any `static` columns (by default
elevation and BC Albers easting and northing).

## Usage

``` r
wet_share_fit(d, static = c("elev", "e_km", "n_km"))
```

## Arguments

- d:

  `data.frame` with observed shares `share_01` to `share_12`, the
  monthly predictors `ppt_MM`, `tave_MM`, `aet_MM`, and the `static`
  columns.

- static:

  Predictors used in every month, one value per station, each with its
  own coefficient in each month. The snow predictors scored in \#16
  enter here:
  `static = c("elev", "e_km", "n_km", "snowmelt_doy_50", "swe_max")`,
  the upstream means of
  [`wet_snow_normals()`](https://newgraphenvironment.github.io/wet/reference/wet_snow_normals.md).

## Value

A `wet_share_fit` object: `list(coef, terms, n)`, where `coef` is a
12-row matrix of coefficients (intercept first) by month.
