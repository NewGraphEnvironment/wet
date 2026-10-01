# Watershed-to-upstream-polygon pairs for one watershed group, from fwapg

The slow oracle: the pairwise `FWA_Upstream()` join fwapg's own builds
use, with fwapg's stored `fwa_watersheds_upstream_area`. It materialises
every (watershed, upstream polygon) pair (722 k for SALR), so use it
only to spot check
[`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md)
/
[`wet_upstream_mean()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_mean.md)
on small headwater groups. Upstream polygons are not restricted to the
group.

## Usage

``` r
wet_upstream_pairs(conn, wsg)
```

## Arguments

- conn:

  A DBI connection to an fwapg database.

- wsg:

  Watershed group code, e.g. `"SALR"`.

## Value

`data.frame(watershed_feature_id, id_up, area_up_m2, upstream_area_m2)`.
