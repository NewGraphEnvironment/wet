# Extend a short gauge record of window statistics from donor gauges

Extends a target gauge's per-year window statistics (from
[`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md))
into the years it has no record, from nearby gauges that have one, with
a prediction interval per year. The donors are the `k` gauges nearest
the target in predictor space (easting and northing in km in BC Albers,
EPSG:3005, and log drainage area, each divided by its standard deviation
over `stations`) that have a value in **every** year the target has. In
each year to be extended, the nearest of them with a value that year
supplies it; each donor's relation to the target is fitted on the
target's years. A year none of them has is not returned.

## Usage

``` r
wet_window_extend(
  x,
  stations,
  target,
  method = c("ols", "move1", "ratio"),
  k = 5,
  level = 0.9,
  resid = NULL
)
```

## Arguments

- x:

  Window statistics in
  [`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)'s
  long format (`station_number`, `variable`, `period`, `year`, `value`)
  for the target and its candidate donors. Each `variable` and `period`
  is extended on its own. The target's rows are its record: to hold
  years out, leave them out.

- stations:

  `data.frame(station_number, lon, lat, drainage_area_gross_km2)`, as
  from
  [`wet_station_select()`](https://newgraphenvironment.github.io/wet/reference/wet_station_select.md),
  with a row for the target and every station in `x`. The predictor
  scaling is taken over its rows.

- target:

  The target's station number.

- method:

  `"ols"`, `"move1"` or `"ratio"`.

- k:

  Number of nearest covering donors in the chain.

- level:

  Nominal coverage of the interval.

- resid:

  For `"move1"` and `"ratio"`: residuals whose `(1 - level) / 2` and
  `(1 + level) / 2` quantiles bound the interval.

## Value

A data frame: `station_number` (the target), `variable`, `period`,
`year`, `value`, `lower`, `upper`, `donor` (`NA` for an observed year)
and `source` (`"observed"` or `"extended"`), ordered by variable, period
and year. Attribute `"donors"`: the chain per variable and period,
nearest first.

## Details

A statistic named `*_cov_day` (a day of the window) is related in days;
every other statistic in logs, and a value of 0 or less is left out of
the fit (counted in the attribute `"dropped"`).

## Methods

With `x` the donor's value and `y` the target's (log or days) over the
target's `n` years:

- `"ols"`:

  Least-squares regression of `y` on `x`. The interval is the
  regression's prediction interval at `level`, with `n - 2` degrees of
  freedom.

- `"move1"`:

  The line of organic correlation (MOVE.1),
  `y = mean(y) + sign(r) sd(y) / sd(x) (x - mean(x))`, which keeps the
  target's variance where regression shrinks it.

- `"ratio"`:

  The donor's value times the ratio of the target's mean to the donor's
  mean over the same years, on the original scale.

For `"move1"` and `"ratio"` the interval comes from `resid`: residuals
(observed minus predicted, on the method's scale) measured elsewhere,
for example at other gauges held out; without them the bounds are `NA`.
A log-scale prediction is returned back-transformed, so it is a median.

## Examples

``` r
# Three gauges: a long-record donor, a farther one, and a target with five
# years whose flow is 0.4 times the donor's to the power 1.1
set.seed(1)
yrs <- 1961:2020
d1 <- exp(rnorm(60, 3, 0.3))
d2 <- exp(rnorm(60, 3, 0.3))
x <- data.frame(
  station_number = rep(c("D1", "D2", "T"), c(60, 60, 5)),
  variable = "q_mean", period = "migration",
  year = c(yrs, yrs, 1975:1979),
  value = c(d1, d2, 0.4 * d1[15:19]^1.1 * exp(rnorm(5, 0, 0.05))))
st <- data.frame(station_number = c("D1", "D2", "T"), lon = c(-126.6, -127.8, -126.5),
                 lat = c(54.4, 55.1, 54.3), drainage_area_gross_km2 = c(2300, 900, 360))
e <- wet_window_extend(x, st, "T", method = "ols")
head(e)
#>   station_number variable    period year     value     lower     upper donor
#> 1              T   q_mean migration 1961  9.320742  8.318057 10.444294    D1
#> 2              T   q_mean migration 1962 11.755876 10.795855 12.801267    D1
#> 3              T   q_mean migration 1963  8.778530  7.754761  9.937456    D1
#> 4              T   q_mean migration 1964 17.616199 15.836770 19.595567    D1
#> 5              T   q_mean migration 1965 12.257606 11.283639 13.315642    D1
#> 6              T   q_mean migration 1966  8.816745  7.794467  9.973099    D1
#>     source
#> 1 extended
#> 2 extended
#> 3 extended
#> 4 extended
#> 5 extended
#> 6 extended
table(e$source, e$donor, useNA = "ifany")
#>           
#>            D1 <NA>
#>   extended 55    0
#>   observed  0    5
```
