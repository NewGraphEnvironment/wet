# Fundamental watershed polygons of one watershed group

Geometry for area-weighted sampling
([`wet_ws_sample()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_sample.md)
with `method = "area"`), one watershed group at a time so a basin never
has to be held in memory at once.

## Usage

``` r
wet_ws_geom(conn, wsg)
```

## Arguments

- conn:

  A DBI connection to an fwapg database.

- wsg:

  Watershed group code, e.g. `"SALR"`.

## Value

[`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html)
(BC Albers) with `watershed_feature_id`.
