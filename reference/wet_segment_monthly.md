# Monthly and annual flow on FWA segments

Reads mean flow per month on Freshwater Atlas stream segments, by
source, in the shape of
[`wet_station_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_station_monthly.md)
(`month` 1-12, and 0 for the mean annual flow), so a gauge comparison is
a join on `month` after
[`wet_station_snap()`](https://newgraphenvironment.github.io/wet/reference/wet_station_snap.md).

## Usage

``` r
wet_segment_monthly(
  conn,
  segments,
  source = c("pcic_routed", "wet_balance"),
  from = c("published", "fwapg"),
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

- from:

  `"published"` or `"fwapg"`, as described above.

- scenario:

  Scenario of the published product, e.g. `"historical"`. fwapg's run is
  `"historical"` only.

- groups:

  Optional watershed group codes that hold the segments. A segment
  outside them reads as missing.

- catalog:

  For parts read without `conn`: the output of
  [`wet_catalog()`](https://newgraphenvironment.github.io/wet/reference/wet_catalog.md),
  which is read when `NULL`.

## Value

`data.frame(linear_feature_id, month, q_m3s, source)`, ordered by source
as given, segment as given and month. A segment with no value for a
source has all 13 rows, with `q_m3s` `NA`, so missing coverage stays
visible after a join.

## Where the values come from

With `from = "published"` (the default) the values are wet's published
product, `discharge/fwa/v1/segment_monthly`
([`wet_catalog()`](https://newgraphenvironment.github.io/wet/reference/wet_catalog.md)):
from the Postgres table `discharge.fwa_v1_segment_monthly` that
[`wet_db_load()`](https://newgraphenvironment.github.io/wet/reference/wet_db_load.md)
writes when `conn` is given, otherwise straight from the parquet parts
the manifest lists, through duckdb. Its routed month 0 is the plain mean
of the twelve months, and fresh joins the same rows.

With `from = "fwapg"`, `pcic_routed` is read from fwapg's own routed
table (`pcic.discharge_monthly`), the run PCIC's hydromosaic made with
PNWNAmet forcing, `historical`, averaged over 1951-2012 (`model`,
`scenario` and `period` `PNWNAmet`, `historical`, `1951-2012`), with
month 0 computed by the same rule as the published one: the mean of the
twelve months, `NA` unless all twelve have flow. That table is loaded by
the NewGraphEnvironment fork of fwapg (`load/pcic_schema.sql`,
`load/pcic.sql`, then `load/pcic_run.sql` per run), not by upstream
fwapg; a table without the run's rows is an error. Scoring the table
before it is published (`scripts/pcic_routed_compare.R`) reads it this
way.

Reading parts with no `groups` reads the segment ID column of every part
(about half a minute for a few segments over HTTPS, and nearly the whole
1.8 GB for many). The parts are sorted by watershed group, so naming the
groups that hold the segments keeps a read to seconds. Parts are read in
place, unlike
[`wet_db_load()`](https://newgraphenvironment.github.io/wet/reference/wet_db_load.md),
which checks each one's size and md5 first: a read during a publish can
mix two builds, so retry once it completes.

## See also

[`wet_flow_window()`](https://newgraphenvironment.github.io/wet/reference/wet_flow_window.md)
for flow over a date window;
[`wet_station_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_station_monthly.md)
for the gauge's side of a comparison.

## Examples

``` r
if (FALSE) { # \dontrun{
# Buck Creek at its mouth, where gauge 08EE013 sits, from the published
# parts over HTTPS (about 3 s)
q <- wet_segment_monthly(NULL, 17094080, groups = "BULK")
reshape(q[q$month > 0, ], idvar = c("linear_feature_id", "month"),
        timevar = "source", direction = "wide")

# the same from Postgres, after wet_db_load()
conn <- DBI::dbConnect(RPostgres::Postgres(), dbname = "fwapg")
wet_segment_monthly(conn, 17094080)
} # }
```
