# Fit the monthly share-of-annual-runoff model

Splits annual runoff into months. Three methods, each fitted on the same
complete stations:

## Usage

``` r
wet_share_fit(
  d,
  static = c("elev", "e_km", "n_km"),
  method = c("regression", "donor", "blend"),
  k = 5
)
```

## Arguments

- d:

  `data.frame` with observed shares `share_01` to `share_12`, the
  monthly predictors `ppt_MM`, `tave_MM`, `aet_MM`, and the `static`
  columns. A station missing any of them is left out, whatever the
  method.

- static:

  Predictors used in every month, one value per station, each with its
  own coefficient in each month (`"regression"`), or the space the
  donors are found in (`"donor"`). The snow predictors scored in \#16
  enter here:
  `static = c("elev", "e_km", "n_km", "snowmelt_doy_50", "swe_max")`,
  the upstream means of
  [`wet_snow_normals()`](https://newgraphenvironment.github.io/wet/reference/wet_snow_normals.md).

- method:

  `"regression"`, `"donor"` or `"blend"`.

- k:

  Donors per watershed (`"donor"` and `"blend"`), capped at the number
  of stations.

## Value

A `wet_share_fit` object. For `"regression"`,
`list(coef, terms, static, n, method)`, where `coef` is a 12-row matrix
of coefficients (intercept first) by month. For `"donor"`, the stations'
scaled predictors `x`, their standard deviations `sd` and observed
`shares`. For `"blend"`, both fits, as `regression` and `donor`.

## Details

- `"regression"`: Chapman et al. (2018) fit one regression per month of
  each month's share of the annual total. Here the response is the
  observed share (from monthly volumes,
  [`wet_station_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_station_monthly.md))
  and the predictors, fixed in advance, are upstream means: that month's
  precipitation, temperature and AET plus any `static` columns (by
  default elevation and BC Albers easting and northing).

- `"donor"` (#102): a watershed takes the inverse-distance mean of the
  observed shares of its `k` nearest stations in the space of the
  `static` predictors, each divided by the stations' standard deviation.
  Distance weights are `1 / (d + 1e-6 * median(d))`; a station at
  distance 0 takes the whole weight, so a station predicts its own
  shares.

- `"blend"`: the equal-weight mean of the two.

## Examples

``` r
set.seed(1)
d <- data.frame(elev = runif(30, 200, 2000), e_km = runif(30, 900, 1800), n_km = runif(30, 400, 1500))
for (m in 1:12) {
  d[[sprintf("ppt_%02d", m)]] <- runif(30, 20, 200)
  d[[sprintf("tave_%02d", m)]] <- runif(30, -15, 20)
  d[[sprintf("aet_%02d", m)]] <- runif(30, 0, 100)
  # a freshet that comes later and larger at higher elevation
  d[[sprintf("share_%02d", m)]] <- 1 + (m %in% 5:7) * d$elev / 500
}
tot <- rowSums(d[sprintf("share_%02d", 1:12)])
d[sprintf("share_%02d", 1:12)] <- d[sprintf("share_%02d", 1:12)] / tot
new <- d[1:2, ]
new$elev <- c(300, 1900)
# the low watershed gets less of its year in May-July than the high one
round(wet_share_predict(wet_share_fit(d, method = "donor"), new)[, 5:7], 3)
#>      share_05 share_06 share_07
#> [1,]    0.128    0.128    0.128
#> [2,]    0.202    0.202    0.202
```
