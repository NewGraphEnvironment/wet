# Growing season degree days per station-year

Growing season degree days (GSDD) from daily mean water temperature, one
value per station and year, computed by
[`gsdd::gsdd()`](https://poissonconsulting.github.io/gsdd/reference/gsdd.html)
(Coleman & Fausch 2007): the season starts in the first week whose 7-day
mean rises above 5 °C and stays there, and ends in the first week whose
7-day mean falls below 4 °C, and GSDD is the sum of the daily means over
it. The result is in the long format of
[`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md),
so it goes to
[`cd::cd_baseline()`](https://newgraphenvironment.github.io/cd/reference/cd_baseline.html),
[`cd::cd_anomaly()`](https://newgraphenvironment.github.io/cd/reference/cd_anomaly.html)
and
[`cd::cd_trend()`](https://newgraphenvironment.github.io/cd/reference/cd_trend.html)
as is.

## Usage

``` r
wet_temp_gsdd(
  x,
  value = "t_mean_c",
  by = "station_number",
  start_date = as.Date("1972-03-01"),
  end_date = as.Date("1972-11-30"),
  ...
)
```

## Arguments

- x:

  Daily water temperature, as from
  [`wet_temp_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_daily.md)
  or
  [`wet_temp_fill()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_fill.md):
  `date`, the `value` column and the `by` columns, and optionally
  `filled`.

- value:

  Name of the daily mean column.

- by:

  Id columns that separate series.

- start_date, end_date:

  The part of each year to consider, as in
  [`gsdd::gsdd()`](https://poissonconsulting.github.io/gsdd/reference/gsdd.html)
  (the year is ignored).

- ...:

  Passed to
  [`gsdd::gsdd()`](https://poissonconsulting.github.io/gsdd/reference/gsdd.html),
  e.g. `start_temp`, `end_temp`, `pick` or `ignore_truncation`.

## Value

A data frame: the `by` columns, `variable` (`"gsdd"`), `period`
(`"growing_season"`), `year`, `value` (°C-days, `NA` where the season is
cut), `anomaly_type` (`"absolute"`), `unit` (`"degC_day"`), and over the
days from `start_date` to `end_date` that have a value: `n_days` (how
many), `frac_ice` (`NA`: there is no ice flag), `frac_provisional`
(share whose `status` is `"provisional"`, `NA` without a `status`
column) and `frac_filled` (share that were filled, `NA` without a
`filled` column). The columns are those of
[`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)
plus `frac_filled`. One row per series and year that
[`gsdd::gsdd()`](https://poissonconsulting.github.io/gsdd/reference/gsdd.html)
returns. The interval of a
[`wet_temp_fill()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_fill.md)
result does not carry into GSDD: daily bounds do not add up to bounds on
a sum.

## Details

A season cut by a missing day gives `NA`, not a value that is too low:
days absent from `x` are missing, and
[`gsdd::gsdd()`](https://poissonconsulting.github.io/gsdd/reference/gsdd.html)
uses the longest run with no missing day. Fill the gaps first with
[`wet_temp_fill()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_fill.md).
`frac_filled` then says how much of each value is modelled.

## References

Coleman, M.A., and Fausch, K.D. 2007. Cold summer temperature limits
recruitment of age-0 cutthroat trout in high-elevation Colorado streams.
Transactions of the American Fisheries Society 136(5): 1231-1244.
doi:10.1577/T05-244.1.

## Examples

``` r
if (requireNamespace("gsdd", quietly = TRUE)) {
  date <- seq(as.Date("2019-01-01"), as.Date("2020-12-31"), by = "day")
  doy <- as.integer(format(date, "%j"))
  x <- data.frame(station_number = "08AA001", date = date,
                  t_mean_c = pmax(0, 6 + 9 * sin(2 * pi * (doy - 110) / 365)))
  wet_temp_gsdd(x)

  # A week missing in July 2020 leaves that season unknown
  gap <- date >= as.Date("2020-07-01") & date <= as.Date("2020-07-07")
  wet_temp_gsdd(x[!gap, ])
}
#>   station_number variable         period year    value anomaly_type     unit
#> 1        08AA001     gsdd growing_season 2019 2270.457     absolute degC_day
#> 2        08AA001     gsdd growing_season 2020       NA     absolute degC_day
#>   n_days frac_ice frac_provisional frac_filled
#> 1    275       NA               NA          NA
#> 2    268       NA               NA          NA
```
