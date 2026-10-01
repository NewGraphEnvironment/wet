# `FWA_Upstream` pairs for the irregularly coded polygons of one basin

A polygon whose `localcode` neither equals nor lies under its `wscode`
is irregular: `FWA_Upstream`'s localcode guards treat it differently
from the range structure
[`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md)
relies on. This returns, for each such polygon `b`, every watershed `a`
that `FWA_Upstream(a, b)` counts it upstream of (including itself). The
join is small: `a.wscode_ltree @> b.wscode_ltree` restricts candidates
to the few streams whose code is a prefix of `b`'s, via the gist index.

## Usage

``` r
wet_upstream_irregular(conn, wscode)
```

## Arguments

- conn:

  A DBI connection to an fwapg database.

- wscode:

  Character. FWA watershed code of the basin root.

## Value

`data.frame(watershed_feature_id, id_up)`.
