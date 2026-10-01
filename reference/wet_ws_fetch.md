# Fundamental watersheds of one basin, with codes, area and centroid

Everything
[`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md)
and centroid sampling need, with no geometry transfer: FWA codes as
text, `ST_Area(geom)` in m2 (as fwapg's upstream-area and discharge
builds use), and the centroid taken in BC Albers then reprojected to
lon/lat (as fwapg's `discharge02_load.sql` does).

## Usage

``` r
wet_ws_fetch(conn, wscode)
```

## Arguments

- conn:

  A DBI connection to an fwapg database.

- wscode:

  Character. FWA watershed code of the basin root.

## Value

`data.frame(watershed_feature_id, watershed_group_code, wscode, localcode, area_m2, lon, lat)`.

## Details

A basin is every polygon whose `wscode` lies under `wscode`, e.g.
`"100"` (Fraser), `"200"` (Peace), `"300"` (Columbia). Upstream sets
never leave the basin, because `FWA_Upstream` requires the upstream
`wscode` to lie under the downstream one.
