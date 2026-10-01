# Cell values for each fundamental watershed

Two methods:

## Usage

``` r
wet_ws_sample(r, ws, method = c("centroid", "area"))
```

## Arguments

- r:

  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html),
  one or more layers.

- ws:

  [`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html)
  of polygons with a `watershed_feature_id` attribute; or, for
  `"centroid"` only, a `data.frame(watershed_feature_id, lon, lat)` of
  centroids already computed (e.g. by
  [`wet_ws_fetch()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_fetch.md)),
  which avoids transferring geometry for a whole basin.

- method:

  `"centroid"` or `"area"`.

## Value

For one layer, `data.frame(watershed_feature_id, value, cover)`. For
several, `data.frame(watershed_feature_id, <layer names>, cover)`.

## Details

- `"centroid"`: the value of the cell containing each polygon's centroid
  (centroid taken in the polygons' own CRS, then reprojected). This is
  what fwapg does with `ST_Value()`, and the method to use for a parity
  check. `cover` is 1 where the value is present and 0 where it is `NA`.

- `"area"`: the mean of every cell the polygon overlaps, weighted by the
  overlapping fraction, over cells that have a value. `cover` is the
  share of the polygon's overlap that falls on cells with a value, so a
  polygon half off the model domain reports `cover = 0.5` rather than a
  silently halved value downstream.

With several layers, a cell counts only where **every** layer has a
value, and all layers are averaged over those same cells. There is then
one `cover` per polygon, so upstream means of every layer share one
denominator and a linear combination of layers is exactly the same
combination of their means.
