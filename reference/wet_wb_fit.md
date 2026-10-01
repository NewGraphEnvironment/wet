# Fit the gauge-residual adjustment of the annual water balance

Chapman et al. (2018) adjust the raw water balance (P - AET) with a
regression of the gauge residuals within hydrologic zones. Here the
residual `obs - raw` (mm) is regressed, with no global intercept, on
each zone's upstream share `z_k` and the upstream mean of zone-masked
precipitation `zp_k`, so each zone gets its own intercept and slope on
P.

## Usage

``` r
wet_wb_fit(
  d,
  min_gauges = 8,
  pooled = NULL,
  pooled_adjust = c("other", "none")
)
```

## Arguments

- d:

  `data.frame` with `obs` and `raw` (mm) and, per zone `k`, columns
  `z<k>` (upstream zone share) and `zp<k>` (upstream mean of zone-masked
  annual P), e.g. `z08`, `zp08`.

- min_gauges:

  Minimum stations per zone before it is fitted on its own.

- pooled:

  Optional character vector of zones to pool, overriding `min_gauges`.

- pooled_adjust:

  `"other"` (one fitted level for the pooled zones) or `"none"` (no
  adjustment for them).

## Value

A `wet_wb_fit` object: `list(coef, pooled, pooled_adjust, n)`, where
`coef` is a `data.frame(zone, a, b)` for every zone in `d`. Pooled zones
repeat the `"other"` coefficients, or are 0 under
`pooled_adjust = "none"`.

## Details

Every predictor is an upstream area-weighted mean of a cell layer on one
analysis mask (see
[`wet_ws_sample()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_sample.md)
and
[`wet_upstream_means()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_means.md)).
The fitted adjustment is therefore linear in cell values: applying it to
the upstream means of any watershed
([`wet_wb_adjust()`](https://newgraphenvironment.github.io/wet/reference/wet_wb_adjust.md))
gives exactly what applying it cell by cell and then averaging upstream
would, and a basin that straddles zones gets the same mix of
coefficients in the fit and in the application.

Zones where fewer than `min_gauges` stations have their largest share
are pooled, decided from the stations passed in (so a cross-validation
fold decides its own pooling from its training stations) unless `pooled`
fixes it. With `pooled_adjust = "other"` the pooled zones share one
fitted `"other"` level; with `"none"` they get no adjustment. A fitted
level whose columns carry no information in the data gets coefficient 0.
