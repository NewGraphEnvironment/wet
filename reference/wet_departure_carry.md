# Carry donor gauges' year-to-year departures onto an ungauged site

Gives a site with no record of its own (or a short one) the departure of
each year from normal, as the weighted mean of its donor gauges'
departures. Each donor's departure is taken from its own baseline mean,
so a donor's size does not matter, only how its years vary. The donors
are the `k` gauges nearest the target in predictor space (easting and
northing in km in BC Albers, EPSG:3005, and log drainage area, each
divided by its standard deviation over `stations`), weighted by inverse
distance as the monthly shares' and the daily shape's donors are. In a
year a donor has no value, it is dropped and the remaining weights
renormalised to sum to 1; a year no donor has is not returned.

## Usage

``` r
wet_departure_carry(
  x,
  stations,
  target,
  k = 5,
  baseline = 1981:2010,
  min_baseline = 10
)
```

## Arguments

- x:

  Window statistics in
  [`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)'s
  long format (`station_number`, `variable`, `period`, `year`, `value`)
  for the donors and, if it has any record, the target. Each `variable`
  and `period` is carried on its own. Every donor chosen must have at
  least `min_baseline` years in `baseline`.

- stations:

  `data.frame(station_number, lon, lat, drainage_area_gross_km2)`, as
  from
  [`wet_station_select()`](https://newgraphenvironment.github.io/wet/reference/wet_station_select.md),
  with a row for the target and every station in `x`.

- target:

  The target's station number, or any id with a row in `stations`.

- k:

  Number of donors.

- baseline:

  Baseline years.

- min_baseline:

  Fewest baseline years a donor needs, and the target needs for `value`.

## Value

A data frame: `station_number` (the target), `variable`, `period`,
`year`, `anomaly` (log, or days for `*_cov_day`), `pct_normal`,
`n_donors` (present that year), `donors` (`"station:weight"` pairs used
that year, separated by spaces) and `value`: the target's baseline mean
carried by the anomaly, only where the target has its own baseline in
`x`, else `NA`.

## Details

A departure is a log ratio, `log(value / baseline mean)`, reported also
as percent of normal, `100 * (exp(anomaly) - 1)`, the scale
[`cd::cd_anomaly()`](https://newgraphenvironment.github.io/cd/reference/cd_anomaly.html)
uses. A statistic named `*_cov_day` (a day of the window) departs in
days instead, and has no percent of normal.

## Examples

``` r
# Two donors share a wet year in 1990; the target, ungauged, gets it too
yrs <- 1975:2000
wet <- ifelse(yrs == 1990, 1.5, 1)
x <- data.frame(station_number = rep(c("D1", "D2"), each = length(yrs)),
                variable = "q_mean", period = "migration", year = rep(yrs, 2),
                value = c(20 * wet, 300 * wet))
st <- data.frame(station_number = c("D1", "D2", "T"), lon = c(-126.6, -127.8, -126.5),
                 lat = c(54.4, 55.1, 54.3), drainage_area_gross_km2 = c(2300, 900, 360))
a <- wet_departure_carry(x, st, "T", k = 2)
a[a$year %in% 1989:1991, c("year", "anomaly", "pct_normal", "donors")]
#>    year     anomaly pct_normal              donors
#> 15 1989 -0.02469261  -2.439024 D1:0.5770 D2:0.4230
#> 16 1990  0.38077250  46.341463 D1:0.5770 D2:0.4230
#> 17 1991 -0.02469261  -2.439024 D1:0.5770 D2:0.4230
```
