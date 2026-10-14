# Mean flow over date windows, from monthly or daily means

Turns a flow climatology into mean flow over named month-day windows,
such as a species' life stage or a week, and says what it rests on. From
monthly means
([`wet_segment_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_segment_monthly.md),
[`wet_station_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_station_monthly.md))
each day of the window takes its month's mean and the window's flow is
the mean over its days: `basis = "monthly"`. That is an approximation
where a window takes part of a month whose flow rises or falls fast.
From daily means (a `doy` column) the window's flow is the mean of its
days: `basis = "daily"`. A caller that swaps monthly input for daily
gets the same call and a `basis` that says so.

## Usage

``` r
wet_flow_window(x, windows, by = c("linear_feature_id", "source"))
```

## Arguments

- x:

  A data frame with the `by` columns, `q_m3s`, and either `month` (1-12;
  month 0, the annual value, is ignored) or `doy` (day of a common year,
  1-365).

- windows:

  `data.frame(window, start, end)`, with `start` and `end` as `"MM-DD"`,
  both inclusive. See
  [`wet_windows_calendar()`](https://newgraphenvironment.github.io/wet/reference/wet_windows_calendar.md).

- by:

  Columns that separate series: `c("linear_feature_id", "source")` for
  segments, `"station_number"` for gauges,
  [`character()`](https://rdrr.io/r/base/character.html) for one series.

## Value

One row per series and window: the `by` columns, `window`, `q_m3s` and
`basis` (`"monthly"` or `"daily"`).

## Details

Days are laid on a common year: February has 28 days, and an `end` of
`"02-29"` means its last day. A window whose `end` falls before its
`start` runs across 1 January. A window is `NA` when any of its days has
no value. The common year differs slightly from
[`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md),
which counts 29 February in leap years, and from month 0, which weights
months by
[`wet_month_days()`](https://newgraphenvironment.github.io/wet/reference/wet_month_days.md)
(28.25 days in February), so a window over the whole year is close to
month 0 but not equal to it.

## See also

[`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)
for per-year statistics of a daily series.

## Examples

``` r
# a segment's twelve monthly means, with a June freshet
x <- data.frame(linear_feature_id = 17094080L, month = 0:12, source = "pcic_routed",
                q_m3s = c(5.9, 1.4, 1.2, 1.5, 4.6, 15.8, 19.1, 9.6, 4.4, 3.5, 3.6, 2.6, 1.7))
w <- rbind(wet_windows_calendar()[6:7, ],
           data.frame(window = "ch_spawning", start = "08-20", end = "09-30"))
wet_flow_window(x, w)
#>   linear_feature_id      source      window     q_m3s   basis
#> 1          17094080 pcic_routed         jun 19.100000 monthly
#> 2          17094080 pcic_routed         jul  9.600000 monthly
#> 3          17094080 pcic_routed ch_spawning  3.757143 monthly
```
