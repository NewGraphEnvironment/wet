# Upstream sums of additive quantities for every fundamental watershed

Sums each column in `cols` over the set of polygons that fwapg's
`FWA_Upstream(wscode_a, localcode_a, wscode_b, localcode_b)` counts as
upstream of each watershed `a` (including `a` itself), without
materialising (watershed, upstream polygon) pairs.

## Usage

``` r
wet_upstream_sums(ws, cols, irregular_pairs = NULL)
```

## Arguments

- ws:

  `data.frame` with `watershed_feature_id`, `wscode`, `localcode` (FWA
  ltree codes as text) and the numeric columns named in `cols`.

- cols:

  Character. Additive columns to sum (no `NA`).

- irregular_pairs:

  Optional `data.frame(watershed_feature_id, id_up)`: `FWA_Upstream`
  pairs whose upstream polygon `id_up` is irregular.

## Value

`data.frame(watershed_feature_id, <cols>)` of upstream sums, one row per
input row, with attribute `"irregular"` (ids of irregular polygons).

## Details

FWA codes are dotted labels of fixed width per level (3 digits at the
root, 6 below), so ltree order equals C-locale byte order of the
strings, and the `FWA_Upstream` set of `a = (W, L)` is at most two
contiguous ranges of the polygons sorted by `(wscode, localcode)`:

- `W == L`: the subtree of `W`, i.e. `wscode` in `[W, W/)`;

- `W != L`: `wscode == W & localcode >= L`, union `wscode` in `[L/, W/)`
  (the tributaries above position `L`, with their subtrees).

This holds for every upstream polygon `b` whose `localcode` equals or
lies under its `wscode`. `FWA_Upstream` treats polygons that break that
rule differently (its localcode guards), so they are left out of the
ranges and added back from `irregular_pairs`, the exact `FWA_Upstream`
pairs for them (see
[`wet_upstream_irregular()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_irregular.md)).
Without `irregular_pairs` they are excluded with a warning, and their
ids are returned in the `"irregular"` attribute. Pairs that name no row
at all for some irregular polygon (pairs from another basin, an empty
table) or repeat a row are an error. That check cannot see a table that
keeps each polygon's self pair but loses others, so pass
[`wet_upstream_irregular()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_irregular.md)
output whole, not filtered.

`ws` must be a whole basin: every polygon upstream of any row must be in
it (e.g.
[`wet_ws_fetch()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_fetch.md)
for a basin root such as `"100"`). A single watershed group is not
enough; missing upstream polygons simply drop out of the sums.

Range sums use a segment tree rather than differences of prefix sums, so
a 1,000 m2 headwater is not the small difference of two 1e11 m2 totals.
