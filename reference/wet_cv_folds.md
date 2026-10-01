# Cross-validation folds for gauges on one stream network

Assigns each station a fold for blocked cross-validation and describes
how much a held-out station can still "see" of itself through the
stations left in training, which is what makes plain leave-one-out
optimistic on nested gauges.

## Usage

``` r
wet_cv_folds(stations, block = c("subsubdrainage", "station"))
```

## Arguments

- stations:

  `data.frame(station_number, wscode, localcode, upstream_area_km2)`,
  one row per station (e.g. accepted rows of
  [`wet_station_snap()`](https://newgraphenvironment.github.io/wet/reference/wet_station_snap.md)).

- block:

  `"subsubdrainage"` or `"station"`.

## Value

`stations[, "station_number"]` with `fold`, `nesting`, `leak_up`,
`leak_down`.

## Details

- `fold`: the block, by default the WSC sub-sub-drainage (the first four
  characters of the station number, e.g. `08MF`). All stations in a
  block are held out together. `block = "station"` gives plain
  leave-one-out.

- `nesting`: `"headwater"` when no other station is upstream on the FWA
  network, `"nested"` otherwise.

- `leak_up`: the largest share of the station's upstream area that a
  station in another fold gauges upstream of it (0 when none), so the
  training set already knows that much of the held-out basin.

- `leak_down`: `TRUE` when a station in another fold is downstream, so
  its training residual includes the held-out basin.

Upstream is fwapg's `FWA_Upstream()` between the stations' fundamental
watersheds (codes compared in C-locale order, as FWA codes require).
