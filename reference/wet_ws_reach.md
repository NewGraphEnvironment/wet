# The fundamental watersheds that FWA_Upstream reaches from some of them

Which rows of `ws` lie in the `FWA_Upstream` set of at least one of the
rows `from` (each counting itself), by the same ranges
[`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md)
sums over, with irregularly coded polygons from `irregular_pairs`. Over
an upstream-closed `ws` such as
[`wet_ws_closure()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_closure.md)'s,
those rows are the least set that gives the `from` rows their sums:
[`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md)
over them, with `irregular_pairs` cut to the `id_up` rows kept, gives
the `from` rows the same sums as over all of `ws`, up to the order the
doubles are added in.

## Usage

``` r
wet_ws_reach(ws, from, irregular_pairs = NULL)
```

## Arguments

- ws:

  `data.frame` with `watershed_feature_id`, `wscode` and `localcode`
  (FWA ltree codes as text).

- from:

  Logical, one per row of `ws`: the rows whose upstream sets to join.

- irregular_pairs:

  Optional `data.frame(watershed_feature_id, id_up)`, as
  [`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md)
  takes it. Without it, irregularly coded rows are left out with a
  warning, as
  [`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md)
  leaves them out.

## Value

Logical, one per row of `ws`.

## Examples

``` r
ws <- data.frame(watershed_feature_id = 1:5,
                 wscode = c("100", "100", "100.000300", "100.000300", "100.000700"),
                 localcode = c("100", "100.000500", "100.000300", "100.000300.000010",
                               "100.000700"))
# row 2 sits on the main stem above position 000500: it reaches itself
# and the tributary at 000700, not row 1 or the tributary at 000300
wet_ws_reach(ws, ws$watershed_feature_id == 2)
#> [1] FALSE  TRUE FALSE FALSE  TRUE
```
