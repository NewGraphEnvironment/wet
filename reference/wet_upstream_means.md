# Area-weighted upstream means of several sampled layers

The multi-layer form of
[`wet_upstream_mean()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_mean.md)
with `denom = "covered"`: for watershed `a` and each column `x` of
`values`, `sum(x_u * area_u * cover_u) / sum(area_u * cover_u)` over the
`FWA_Upstream` set of `a`, in one pass of
[`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md).
All columns share one cover (as
[`wet_ws_sample()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_sample.md)
returns for several layers), so the upstream mean of a linear
combination of layers is exactly that combination of their upstream
means.

## Usage

``` r
wet_upstream_means(
  ws,
  values,
  cols = NULL,
  irregular_pairs = NULL,
  extra = NULL
)
```

## Arguments

- ws:

  `data.frame(watershed_feature_id, wscode, localcode, area_m2)` for a
  whole basin, e.g. from
  [`wet_ws_fetch()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_fetch.md).

- values:

  `data.frame(watershed_feature_id, <cols>, cover)`. Polygons absent
  from it count as uncovered. A polygon with `cover > 0` must have a
  value in every column.

- cols:

  Columns of `values` to average. Default: all but
  `watershed_feature_id` and `cover`.

- irregular_pairs:

  Passed to
  [`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md).

- extra:

  Optional columns of `ws` to average over the **whole** upstream area
  (not only the covered part), e.g. an in-BC indicator.

## Value

`data.frame(watershed_feature_id, <cols>, <extra>, coverage, upstream_area_m2)`,
one row per row of `ws`.
