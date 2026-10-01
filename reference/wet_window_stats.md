# Statistics of a daily series over date windows, one value per year

Summarises any daily series (flow from
[`wet_station_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_station_daily.md),
water temperature, ...) over named month-day windows, once per year per
window. The result is in the long format `cd`'s consumer functions take
(`variable`, `period`, `year`, `value`, `anomaly_type`, `unit`), so
[`cd::cd_baseline()`](https://rdrr.io/pkg/cd/man/cd_baseline.html),
[`cd::cd_anomaly()`](https://rdrr.io/pkg/cd/man/cd_anomaly.html) and
[`cd::cd_trend()`](https://rdrr.io/pkg/cd/man/cd_trend.html) give the
departure and the trend. cd takes one series per call, so split by id
first.

## Usage

``` r
wet_window_stats(
  x,
  windows = wet_windows_calendar(),
  stats = c("mean", "min", "max", "min7", "frac_below", "cov_day"),
  by = "station_number",
  value = "q_m3s",
  threshold = NULL,
  min_frac = 0.8,
  prefix = "q",
  level_anomaly = "pct_normal",
  unit = NULL
)
```

## Arguments

- x:

  A data frame with a `Date` column `date`, a numeric value column and
  the `by` id columns. Optional `symbol` (HYDAT `"B"` = ice) and
  `status` (`"provisional"`) columns give `frac_ice` and
  `frac_provisional`.

- windows:

  `data.frame(window, start, end)`, with `start` and `end` as `"MM-DD"`,
  both inclusive. An `end` of `"02-29"` is the last day of February; a
  `start` of `"02-29"` is refused. See
  [`wet_windows_calendar()`](https://newgraphenvironment.github.io/wet/reference/wet_windows_calendar.md).

- stats:

  Any of `"mean"`, `"min"`, `"max"`, `"min7"`, `"frac_below"`,
  `"cov_day"`.

- by:

  Id columns that separate series;
  [`character()`](https://rdrr.io/r/base/character.html) for one series.

- value:

  Name of the value column.

- threshold:

  For `frac_below`: one number, or a vector named by the values of a
  single `by` column.

- min_frac:

  Minimum share of a window's days that must have a value.

- prefix:

  Prefix for `variable`, e.g. `"q"` gives `q_mean`.

- level_anomaly:

  The cd anomaly type for `mean`, `min`, `max` and `min7`:
  `"pct_normal"` (percent of normal, unit `"%"`) for flow, `"absolute"`
  for temperature. `frac_below` and `cov_day` are always `"absolute"`.

- unit:

  Unit of an `"absolute"` level anomaly, e.g. `"degC"`.

## Value

A data frame: the `by` columns, `variable`, `period` (the window name),
`year`, `value`, `anomaly_type`, `unit` (of the anomaly, as cd defines
it), `n_days` present, `frac_ice` and `frac_provisional` (`NA` when `x`
has no `symbol` or `status` column).

## Details

A window whose `end` falls before its `start` crosses 1 January and
takes the year it starts in, so the incubation window September to April
2020 runs into 2021. A window-year is kept only when it lies inside the
series' first and last day and at least `min_frac` of its days have a
value.

## Statistics

- `mean`, `min`, `max`:

  Over the days present.

- `min7`:

  Lowest mean over seven consecutive calendar days, all present and all
  inside the window. Absent when there is no such run.

- `frac_below`:

  Share of the days present below `threshold`, for example 0.2 times a
  station's mean annual flow from
  [`wet_station_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_station_monthly.md).

- `cov_day`:

  Day of the window (1 = `start`) by which half the window's total has
  passed. Only for window-years with every day present, since a missing
  day moves it.

## Examples

``` r
# A synthetic flow: low in winter, a freshet in June
date <- seq(as.Date("2001-01-01"), as.Date("2005-12-31"), by = "day")
doy <- as.numeric(format(date, "%j"))
x <- data.frame(station_number = "08XX001", date = date,
                q_m3s = 2 + 40 * exp(-((doy - 165) / 25)^2))
w <- data.frame(window = c("spawning", "incubation"), start = c("08-01", "09-01"),
                end = c("09-15", "04-30"))
s <- wet_window_stats(x, w, threshold = 0.2 * mean(x$q_m3s))
head(s)
#>   station_number variable     period year    value anomaly_type unit n_days
#> 1        08XX001   q_mean   spawning 2001 2.138747   pct_normal    %     46
#> 2        08XX001   q_mean   spawning 2002 2.138747   pct_normal    %     46
#> 3        08XX001   q_mean   spawning 2003 2.138747   pct_normal    %     46
#> 4        08XX001   q_mean   spawning 2004 2.116954   pct_normal    %     46
#> 5        08XX001   q_mean   spawning 2005 2.138747   pct_normal    %     46
#> 6        08XX001   q_mean incubation 2001 2.043299   pct_normal    %    242
#>   frac_ice frac_provisional
#> 1       NA               NA
#> 2       NA               NA
#> 3       NA               NA
#> 4       NA               NA
#> 5       NA               NA
#> 6       NA               NA

# The freshet's timing: day of June by which half of June's flow has passed
june <- wet_window_stats(x, wet_windows_calendar()[6, ], stats = "cov_day")
june[c("year", "value")]
#>   year value
#> 1 2001    15
#> 2 2002    15
#> 3 2003    15
#> 4 2004    15
#> 5 2005    15
```
