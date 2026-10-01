# Snap HYDAT stations to FWA fundamental watersheds, checked by drainage area

Finds the `num_features` nearest stream segments to each station with
fwapg's `fwa_indexpoint()` (the function `fresh::frs_point_snap()`
wraps), in one query for all stations, and keeps the candidate whose
upstream area is closest to HYDAT's gross drainage area on a log scale.
The nearest segment at a confluence is often the wrong stream, and the
area is what tells them apart. A snap is accepted when that area is
within `max_dev` of the gross drainage area.

## Usage

``` r
wet_station_snap(
  conn,
  stations,
  tolerance = 1000,
  num_features = 5,
  max_dev = 0.1,
  lake_dist = 3000,
  lake_min_ha = 100,
  lake_min_share = 0.5
)
```

## Arguments

- conn:

  A DBI connection to an fwapg database.

- stations:

  `data.frame(station_number, lon, lat, drainage_area_gross_km2)`, e.g.
  from
  [`wet_station_select()`](https://newgraphenvironment.github.io/wet/reference/wet_station_select.md).

- tolerance:

  Search distance, m.

- num_features:

  Candidates per station.

- max_dev:

  Accepted relative deviation of the snapped area from the gross
  drainage area.

- lake_dist, lake_min_ha, lake_min_share:

  A station is flagged as a lake outlet when a lake of at least
  `lake_min_ha` hectares lies within `lake_dist` metres of the gauge,
  has stream segments upstream of the snapped point on the FWA network
  (`fwa_upstream()`), **and** drains between `lake_min_share` and
  `1 + max_dev` of the gauge's upstream area. So an inlet, an
  off-network pond, or a lake on a tributary is not one; the upper bound
  also catches an inlet that an FWA coding fault places upstream.

## Value

`data.frame(station_number, linear_feature_id, watershed_feature_id, wscode, localcode, distance_m, upstream_area_km2, area_ratio, accepted, reason, lake)`,
one row per station. Stations with no candidate keep a row with
`accepted = FALSE`.

## Details

Upstream area here is fwapg's stored `fwa_watersheds_upstream_area`,
which is good enough to choose between candidates. The area the water
balance compares against is accumulated later from the live polygons.
