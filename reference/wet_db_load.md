# Load one scenario of published discharge into Postgres

Fetches the parts of one dataset and scenario listed by
[`wet_catalog()`](https://newgraphenvironment.github.io/wet/reference/wet_catalog.md),
checks each against the manifest's size and md5, and writes them to the
Postgres table the dataset ID names: `discharge/fwa/v1/segment_monthly`
becomes `discharge.fwa_v1_segment_monthly`. The scenario's rows already
in the table are replaced, in one transaction, so a reload never
duplicates and a failed load leaves the table as it was.

## Usage

``` r
wet_db_load(
  conn,
  catalog,
  dataset = "discharge/fwa/v1/segment_monthly",
  scenario = "historical",
  months = 0:12,
  pick_only = FALSE,
  cache_dir = tools::R_user_dir("wet", "cache")
)
```

## Arguments

- conn:

  A
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html)
  to Postgres (RPostgres).

- catalog:

  The parts, from
  [`wet_catalog()`](https://newgraphenvironment.github.io/wet/reference/wet_catalog.md).

- dataset:

  Dataset ID, e.g. `"discharge/fwa/v1/segment_monthly"`.

- scenario:

  Scenario to load, e.g. `"historical"`.

- months:

  Months to keep, from `0` (annual) to `12`.

- pick_only:

  Keep only the default source's rows (`pick`), about half the segment
  table. Datasets without `pick` refuse it.

- cache_dir:

  Where fetched parts are kept between loads. A cached part is reused
  only while its md5 matches the manifest.

## Value

Invisibly, `data.frame(key, rows)`: the rows loaded from each part.

## Details

A load with `months` or `pick_only` set still replaces the whole
scenario, so it leaves only that subset for every reader of the table;
the table comment records it.

The table holds the files' columns plus `scenario`, `forcing` and
`source`. Where the dataset has `pick`, the load is refused unless each
feature and month has at most one picked row in the scenario. On the
first load it is created with a primary key on
`(scenario, forcing, source, <id>, month, period)`, an index on the
feature ID and, where the dataset has `pick`, a partial index on
`(scenario, <id>)` for the annual default, which fresh's join reads.
fresh then joins the default annual flow per segment with
`frs_col_join(from = "(select linear_feature_id, q_m3s as mad_m3s from discharge.fwa_v1_segment_monthly where scenario = 'historical' and month = 0 and pick)")`.

## See also

[`wet_catalog()`](https://newgraphenvironment.github.io/wet/reference/wet_catalog.md)

## Examples

``` r
if (FALSE) { # \dontrun{
conn <- DBI::dbConnect(RPostgres::Postgres(), dbname = "fwapg")
wet_db_load(conn, wet_catalog())
DBI::dbGetQuery(conn, "
  select linear_feature_id, q_m3s as mad_m3s
  from discharge.fwa_v1_segment_monthly
  where scenario = 'historical' and month = 0 and pick
  limit 5")
} # }
```
