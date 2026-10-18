# Fit a within-month daily shape at gauges

The water balance's daily shape within the month (#70): where a month's
water falls among its days, carried from gauges to ungauged watersheds.
A gauge's within-month weights `w` are its day-of-year flow divided by
its month's total
([`wet_station_doy()`](https://newgraphenvironment.github.io/wet/reference/wet_station_doy.md),
then the internal `wet_shape_within()`), so each month's weights sum
to 1. Two methods:

## Usage

``` r
wet_shape_fit(
  d,
  w,
  method = c("donor", "basis"),
  static = c("elev", "e_km", "n_km"),
  k = 5,
  n_comp = 6,
  shares = NULL
)
```

## Arguments

- d:

  `data.frame` of the gauges, with the `static` columns.

- w:

  Matrix of within-month weights, one row per row of `d` and 365 columns
  (a common year).

- method:

  `"donor"` or `"basis"`.

- static:

  Names of the predictor columns in `d`.

- k:

  Donors per watershed (`"donor"`), capped at the number of gauges.

- n_comp:

  Principal components kept (`"basis"`), capped at the rank.

- shares:

  Optional matrix of the gauges' 12 monthly shares (`"basis"` only); a
  fit made with them needs them at prediction too.

## Value

An object of class `wet_shape_fit`.

## Details

- `"donor"`: a new watershed takes the inverse-distance mean of the
  weights of its `k` nearest gauges in the space of the `static`
  predictors, each divided by the gauges' standard deviation. Distance
  weights are `1 / (d + 1e-6 * median(d))`; a gauge at distance 0 takes
  the whole weight.

- `"basis"`: principal components of the gauges' centred ratio to flat
  (`w * days`), the first `n_comp`, whose scores are regressed by
  ordinary least squares on the `static` predictors and, when given, the
  12 monthly `shares`. A prediction is reconstructed, floored at 0 and
  renormalised per month; a month whose reconstruction is all 0 or less
  falls back to flat.

Both apply through
[`wet_shape_predict()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_predict.md),
and
[`wet_shape_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_shape_predict.md)
turns monthly means and weights into daily flows that keep every monthly
mean.

## Examples

``` r
set.seed(1)
m <- wet:::wet_doy_month()
# eight gauges: a freshet whose timing within May moves with elevation
d <- data.frame(elev = seq(300, 2000, length.out = 8), e_km = 1:8, n_km = 8:1)
q <- t(sapply(d$elev, function(e) dnorm(1:365, 120 + e / 50, 30) + 1e-3))
w <- wet:::wet_shape_within(q)
fit <- wet_shape_fit(d, w, "donor", static = c("elev", "e_km", "n_km"), k = 3)
w_new <- wet_shape_predict(fit, data.frame(elev = 1000, e_km = 4.5, n_km = 4.5))
tapply(w_new[1, ], m, sum)  # each month sums to 1
#>  1  2  3  4  5  6  7  8  9 10 11 12 
#>  1  1  1  1  1  1  1  1  1  1  1  1 
```
