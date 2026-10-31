# Routed PCIC flow on FWA segments, day by day and year by year

Gives each segment's routed PCIC flow (m3/s) for every day of the years
asked, from PCIC's per-year sub-basin flows, so a window statistic can
be taken in each year rather than from a climatology. A segment's flow
on a day is

## Usage

``` r
wet_routed_years(
  dir,
  weights,
  years = 1951:2012,
  series = "PNWNAmet_historical"
)
```

## Arguments

- dir:

  Directory holding the per-year files.

- weights:

  `data.frame(linear_feature_id, subid, share, upstream_subids)`, one
  row per segment, as fwapg's `pcic.segment_weights`: `upstream_subids`
  is a list of integer vectors.

- years:

  Years to route; each needs its file.

- series:

  The run's model and scenario, as the files name them.

## Value

`data.frame(linear_feature_id, date, q_m3s)`, one row per segment and
day, ordered by segment and date, in
[`wet_station_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_station_daily.md)'s
layout, so
[`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)
takes it with `by = "linear_feature_id"`.

## Details

`max(sum(q_acc of upstream_subids) + q_local(subid) * share, 0)`,

rounded to 5 decimals, the routing and rounding fwapg uses for the daily
climatology it publishes, applied to one day of one year instead of a
mean over years.

The sub-basin flows are read through duckdb from fwapg's per-year
parquet files in `dir`, `pcic.subbasin_days.<series>.<year>.parquet`,
one row per sub-basin and calendar day: `subid`, `date`, `q_local` and
`q_acc` (m3/s). Only the years asked and the sub-basins `weights` names
are read. Each sub-basin must hold every day of `years` once, with no
missing flow.

## Examples

``` r
if (requireNamespace("duckdb", quietly = TRUE)) {
  fx <- system.file("extdata", "pcic_years", package = "wet")
  w <- read.csv(file.path(fx, "weights.csv"), colClasses = c(upstream_subids = "character"))
  w$upstream_subids <- lapply(strsplit(w$upstream_subids, ";", fixed = TRUE), as.integer)
  q <- wet_routed_years(file.path(fx, "days"), w, years = 1981:1990, series = "synthetic_historical")
  head(q)
  # the Chinook migration window's mean flow on each segment, year by year
  win <- data.frame(window = "migration", start = "05-01", end = "08-01")
  s <- wet_window_stats(q, win, stats = "mean", by = "linear_feature_id")
  head(s[c("linear_feature_id", "year", "value")])
}
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/RtmpuRhcyZ/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#>   linear_feature_id year     value
#> 1                 1 1981 1.6200146
#> 2                 1 1982 1.0127477
#> 3                 1 1983 0.9530035
#> 4                 1 1984 1.5320172
#> 5                 1 1985 1.1444130
#> 6                 1 1986 1.5407401
```
