# Daily flow on FWA segments, by day of a common year

Reads mean flow per day of the year on Freshwater Atlas stream segments,
by source, from wet's published `discharge/fwa/v1/segment_daily`
([`wet_catalog()`](https://newgraphenvironment.github.io/wet/reference/wet_catalog.md)):
`doy` 1-365 on a common year, 29 February folded into 28 February. Each
day is the mean flow on that day over the period, so
[`wet_flow_window()`](https://newgraphenvironment.github.io/wet/reference/wet_flow_window.md)
gives a window's flow from the days themselves (`basis = "daily"`)
rather than from monthly means.

## Usage

``` r
wet_segment_daily(
  conn,
  segments,
  source = c("pcic_routed", "wet_balance"),
  scenario = "historical",
  groups = NULL,
  catalog = NULL
)
```

## Arguments

- conn:

  `NULL`, or a
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html)
  to Postgres: the database
  [`wet_db_load()`](https://newgraphenvironment.github.io/wet/reference/wet_db_load.md)
  wrote to for `from = "published"`, fwapg for `from = "fwapg"`.

- segments:

  `linear_feature_id`s. Repeats are read once.

- source:

  Any of `"pcic_routed"` (PCIC's routed flow placed on the FWA) and
  `"wet_balance"` (wet's open water balance). Left out, every source
  `from` holds: both for `"published"`, `"pcic_routed"` for `"fwapg"`.

- scenario:

  Scenario of the published product, e.g. `"historical"`. fwapg's run is
  `"historical"` only.

- groups:

  Watershed group codes that hold the segments: required when reading
  the parts (no `conn`), optional with `conn`. A segment outside them
  reads as missing.

- catalog:

  For parts read without `conn`: the output of
  [`wet_catalog()`](https://newgraphenvironment.github.io/wet/reference/wet_catalog.md),
  which is read when `NULL`.

## Value

`data.frame(linear_feature_id, doy, q_m3s, source)`, ordered by source
as given, segment as given and day. A segment with no value for a source
has all 365 rows, with `q_m3s` `NA`.

## What the days are

For `wet_balance` the days are its published months laid out with a
within-month shape fitted at HYDAT gauges (`scripts/wb_shape_daily.R`),
so the mean of a calendar month's days is the month
[`wet_segment_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_segment_monthly.md)
reads. For `pcic_routed` they are PCIC's routed day-of-year climatology,
placed on the FWA by fwapg and routed and clamped at zero day by day, so
where a clamp applied the mean of a month's days can sit above the
published month. Neither has an annual row: month 0 is not the mean of
the 365 days.

## Where the values come from

From the Postgres table `discharge.fwa_v1_segment_daily` that
[`wet_db_load()`](https://newgraphenvironment.github.io/wet/reference/wet_db_load.md)
writes when `conn` is given, otherwise from the parquet parts the
manifest lists, through duckdb. Each part holds one watershed group, so
a read of the parts needs `groups` and opens only those groups' parts.

## See also

[`wet_flow_window()`](https://newgraphenvironment.github.io/wet/reference/wet_flow_window.md)
for flow over month-day windows;
[`wet_segment_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_segment_monthly.md)
for monthly and annual flow.

## Examples

``` r
if (FALSE) { # \dontrun{
# Buck Creek at its mouth, where gauge 08EE013 sits, from the published
# parts over HTTPS
q <- wet_segment_daily(NULL, 17094080, groups = "BULK")
wet_flow_window(q, wet_windows_calendar())
} # }
```
