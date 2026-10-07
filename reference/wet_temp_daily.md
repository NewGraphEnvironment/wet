# Daily water temperature at hydrometric stations

One daily water-temperature series per station, from the ECCC readings
that water-temp-bc archives (about 300 BC stations, mostly hourly, from
2002). Readings are reduced to a daily mean, minimum and maximum in the
station's local standard time. The result has the shape of
[`wet_station_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_station_daily.md),
so it feeds
[`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)
with `value = "t_mean_c"` (or `t_min_c`, `t_max_c`),
`level_anomaly = "absolute"` and `unit = "degC"`, and from there
[`cd::cd_baseline()`](https://newgraphenvironment.github.io/cd/reference/cd_baseline.html),
[`cd::cd_anomaly()`](https://newgraphenvironment.github.io/cd/reference/cd_anomaly.html)
and
[`cd::cd_trend()`](https://newgraphenvironment.github.io/cd/reference/cd_trend.html).

## Usage

``` r
wet_temp_daily(
  stations,
  from = NULL,
  to = Sys.Date(),
  valid = c(-1, 35),
  min_hours = 20
)
```

## Arguments

- stations:

  Character vector of station numbers.

- from, to:

  Optional first and last date (a `Date` or a string
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) reads). `NULL`
  means no bound.

- valid:

  Plausible range of a reading, in degrees C, both ends kept.

- min_hours:

  Hours of the day (1 to 24) that must have a valid reading for the day
  to count.

## Value

`data.frame(station_number, date, t_mean_c, t_min_c, t_max_c, n_hours, source, status)`,
one row per station-day kept, ordered by station and date: the shape of
[`wet_station_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_station_daily.md)
with temperature columns in place of `q_m3s`, and no `symbol`. There is
no ice flag, so
[`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)
reports `frac_ice` as `NA`, unknown, not zero. `source` is
`"provisional"`, the water-temp-bc archive, as in
[`wet_station_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_station_daily.md).
`status` is `"approved"` only when every reading that day is final. No
reading in the archive was final on 2026-10-06: its approvals are ECCC's
codes `1` and `4`, whose meanings were never published with the dump and
are treated as provisional, none, or `Provisional/Provisoire`. The
archive is read from option `wet.temp_root` (default
`s3://water-temp-bc/data/canonical/Parameter=5/`) with duckdb.

## How readings become days

1.  Readings outside `valid` are dropped: ECCC's sentinels (`99999`,
    `999`, `99.9`, `-99999`) and readings of a sensor in air or ice. A
    range cannot catch a logger out of the water in summer, when air and
    water temperatures overlap.

2.  Each reading is placed in its hour and day of local standard time
    (no daylight saving), from the station's offset in
    [`tidyhydat::allstations`](https://docs.ropensci.org/tidyhydat/reference/allstations.html)
    (UTC-8 for most BC stations, UTC-7 for the Peace and parts of the
    Kootenays). A station that table does not list is taken as UTC-8,
    with a warning. UTC days would split the afternoon maximum, which
    falls near 00:00 UTC.

3.  Readings are averaged within each hour, and `t_mean_c` is the mean
    of those hourly means, so a 15-minute hour does not outweigh an
    hourly one. `t_min_c` and `t_max_c` are over the readings
    themselves.

4.  A day is kept only when it has readings in at least `min_hours` of
    its 24 hours. Short days are dropped, not filled; `n_hours` is
    returned so a caller can be stricter.

## Baseline

Year-round records are short: few stations have most of their days in
most years of any decade before the 2010s. A temperature departure is
therefore taken against the recent decade, 2016-2025, never 1981-2010,
and has to say so beside any flow departure on 1981-2010. The station
counts behind that are in `research/station_water_temperature.md`.

## With wet_window_stats()

Pass `stats` explicitly. `frac_below` needs a threshold in degrees C,
and `cov_day` (when half a window's total has passed) means nothing for
a temperature. One call takes one value column, so a window's highest
daily maximum is a second call on `t_max_c`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Buck Creek at the mouth, since 2016
t <- wet_temp_daily("08EE013", from = "2016-01-01")
summary(t$t_max_c)

# Over the Chinook spawning window, one value per year: the mean of daily
# means, and the highest daily maximum
w <- data.frame(window = "ch_spawning", start = "08-01", end = "09-15")
s <- rbind(
  wet_window_stats(t, w, stats = "mean", value = "t_mean_c", prefix = "t",
                   level_anomaly = "absolute", unit = "degC"),
  wet_window_stats(t, w, stats = "max", value = "t_max_c", prefix = "tmax",
                   level_anomaly = "absolute", unit = "degC"))

# Departure in degrees C from 2016-2025, one series per cd call
m <- s[s$variable == "t_mean", ]
cd::cd_anomaly(m, cd::cd_baseline(m, 2016:2025))
} # }
```
