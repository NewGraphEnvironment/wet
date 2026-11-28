# Daily air temperature on FWA segments

Reads daily air temperature for Freshwater Atlas stream segments from
wet's published `air_temperature/fwa/v1` tree: each segment's ERA5-Land
cell from `segment_cell`, then that cell's days from `cell_daily`. The
values are cd's daily cube
([`cd::cd_extract_daily()`](https://newgraphenvironment.github.io/cd/reference/cd_extract_daily.html))
copied unchanged, so a segment reads what `cd_extract_daily()` gives at
the segment's midpoint, without cd, raster tooling or a download of the
cube. The result has the columns
[`wet_temp_fill()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_fill.md)
reads as `air`.

## Usage

``` r
wet_air_daily(segments, from, to, variables = "tmean", groups, catalog = NULL)
```

## Arguments

- segments:

  FWA `linear_feature_id`s, whole numbers, none `NA`.

- from, to:

  First and last day, as `Date` or `"YYYY-MM-DD"`.

- variables:

  Any of `"tmean"`, `"tmax"`, `"tmin"` (°C).

- groups:

  Watershed group codes holding the segments (required): only their
  lookup parts are read. A segment outside them reads as missing.

- catalog:

  A
  [`wet_catalog()`](https://newgraphenvironment.github.io/wet/reference/wet_catalog.md)
  of the air tree. The default reads option `wet.air_catalog_url`, or
  else the published air manifest.

## Value

`data.frame(id, date, variable, value, cell_id, cell_x, cell_y, cell_moved, cell_status)`,
one row per segment, variable and day, ordered by segment as given,
variable as given and date. `id` is the `linear_feature_id`; `cell_id`
numbers the cell on the regular 0.1° grid ERA5-Land is distributed on
(not cd's cell number); `cell_moved` is `TRUE` for a `"moved"` segment.
A segment with no cell, or one the lookup does not hold (`cell_status`
`NA`), has its days with `value` `NA`.

## The cell

A segment takes the cell holding its midpoint along the line. Where that
cell has no data (the coast, large lakes) it takes the nearest of the
eight around it that has, as cd does (`cell_status` `"moved"`); where
none of the nine has, or the midpoint is outside cd's box, it has no
cell (`"no_data"`, `"outside"`) and its values are `NA`. Which cells
have data is read from one day of the cube, which the manifest names.
There is no elevation adjustment between the cell and the segment.

## The day

A day is BC's local standard day (UTC-8), as cd defines it, so `date` is
a calendar day, not an instant.

## See also

[`wet_temp_fill()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_fill.md),
which takes this as `air`.

## Examples

``` r
# a tiny made-up tree laid out as the published one, from cd's example cube
cat <- wet_catalog(system.file("air", "manifest.json", package = "wet"))
a <- wet_air_daily(c(1, 2, 4), "2002-07-01", "2002-07-03", groups = "AAAA", catalog = cat)
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmppyprdl/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
a
#>   id       date variable    value cell_id cell_x cell_y cell_moved cell_status
#> 1  1 2002-07-01    tmean 7.672913 1280338 -126.2   54.5      FALSE         own
#> 2  1 2002-07-02    tmean 8.277100 1280338 -126.2   54.5      FALSE         own
#> 3  1 2002-07-03    tmean 9.360413 1280338 -126.2   54.5      FALSE         own
#> 4  2 2002-07-01    tmean 7.672913 1280338 -126.2   54.5      FALSE         own
#> 5  2 2002-07-02    tmean 8.277100 1280338 -126.2   54.5      FALSE         own
#> 6  2 2002-07-03    tmean 9.360413 1280338 -126.2   54.5      FALSE         own
#> 7  4 2002-07-01    tmean       NA      NA     NA     NA      FALSE     no_data
#> 8  4 2002-07-02    tmean       NA      NA     NA     NA      FALSE     no_data
#> 9  4 2002-07-03    tmean       NA      NA     NA     NA      FALSE     no_data
```
