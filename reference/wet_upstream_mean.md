# Area-weighted mean over each watershed's upstream area

Weights each polygon's value by its area and cover, and accumulates over
the `FWA_Upstream` set of every watershed with
[`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md),
so it runs on a whole basin without materialising upstream pairs.

## Usage

``` r
wet_upstream_mean(
  ws,
  values,
  denom = c("total", "covered"),
  irregular_pairs = NULL,
  upstream_area = NULL
)
```

## Arguments

- ws:

  `data.frame(watershed_feature_id, wscode, localcode, area_m2)`, e.g.
  from
  [`wet_ws_fetch()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_fetch.md):
  every polygon of the basin.

- values:

  `data.frame(watershed_feature_id, value, cover)` from
  [`wet_ws_sample()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_sample.md).
  Polygons absent from it count as uncovered.

- denom:

  `"total"` or `"covered"`.

- irregular_pairs:

  Passed to
  [`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md);
  from
  [`wet_upstream_irregular()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_irregular.md).
  Without it, irregularly coded polygons drop out of every upstream sum
  (a warning says how many), and the result no longer matches
  `FWA_Upstream`.

- upstream_area:

  Optional `data.frame(watershed_feature_id, upstream_area_m2)`
  overriding the accumulated upstream area.

## Value

`data.frame(watershed_feature_id, value, coverage, upstream_area_m2)`,
one row per row of `ws`, with attribute `"irregular"` (ids of
irregularly coded polygons).

## Details

For watershed `a` with upstream polygons `u` (including `a` itself):

- `denom = "total"`:
  `sum(value_u * area_u * cover_u) / upstream_area_a`. Ground without a
  value (a polygon's uncovered share, or a polygon with no value) adds
  nothing to the numerator but still counts in the denominator, so
  partial coverage biases the mean low. This reproduces fwapg, including
  `NA` where no upstream ground is covered.

- `denom = "covered"`:
  `sum(value_u * area_u * cover_u) / sum(area_u * cover_u)`: the mean
  over the area that has data. `coverage` says how much of the upstream
  area that is.

`upstream_area_a` is the accumulated polygon area, unless
`upstream_area` supplies it. fwapg's discharge build divides by its
stored `fwa_watersheds_upstream_area`, a snapshot that can differ from
the live polygons, so pass that table to reproduce fwapg exactly. The
override applies to the `"total"` value and to the returned
`upstream_area_m2`; `coverage` is always covered area over accumulated
area.
