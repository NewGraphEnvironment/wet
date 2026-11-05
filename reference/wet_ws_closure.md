# An upstream-closed set of fundamental watersheds holding a watershed group

Every polygon whose `wscode` lies under one of the group's roots, its
distinct `wscode`s with no proper ancestor among them
([`wet_ws_roots()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_roots.md)).
`FWA_Upstream(a, b)` requires `b`'s `wscode` to lie under `a`'s, so
nothing upstream of a polygon in the set lies outside it, and
[`wet_upstream_sums()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_sums.md)
over the set gives the group's rows (or any row of the set) the sums a
whole basin gives them, up to the order the doubles are added in.

## Usage

``` r
wet_ws_closure(conn, wsg)
```

## Arguments

- conn:

  A DBI connection to an fwapg database.

- wsg:

  Watershed group code, e.g. `"BULK"`.

## Value

The polygons in
[`wet_ws_fetch()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_fetch.md)'s
shape, ordered by `watershed_feature_id`, with attributes `wsg`, `roots`
(the group's roots), `groups` (the watershed groups the set spans),
`codes` (the top-level drainage codes it spans) and `irregular` (the
[`wet_upstream_irregular()`](https://newgraphenvironment.github.io/wet/reference/wet_upstream_irregular.md)
pairs of its irregularly coded polygons, to pass as `irregular_pairs`).
Subsetting rows can drop the attributes, so take them first, and cut
`irregular` to the `id_up` rows kept.

## Details

The set is enough, not the least: it holds each root's whole subtree,
including the part of a root's stream below the group and its
tributaries there. A group holding a polygon whose `wscode` is a basin
root such as `100` gets that whole basin.
[`wet_ws_reach()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_reach.md)
trims it to the polygons the group's rows reach.

## Examples

``` r
if (FALSE) { # \dontrun{
conn <- DBI::dbConnect(RPostgres::Postgres(), dbname = "fwapg")
ws <- wet_ws_closure(conn, "SALR")
attr(ws, "groups")   # LSAL, MUSK and SALR: everything under the Salmon's code
irr <- attr(ws, "irregular")
ws <- ws[wet_ws_reach(ws, ws$watershed_group_code == "SALR", irr), ]
irr <- irr[irr$id_up %in% ws$watershed_feature_id, ]
table(ws$watershed_group_code)   # SALR and two of LSAL's polygons
s <- wet_upstream_sums(ws, "area_m2", irregular_pairs = irr)
s[ws$watershed_group_code == "SALR", ]
} # }
```
