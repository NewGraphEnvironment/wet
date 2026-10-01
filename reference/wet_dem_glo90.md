# Elevation on a template grid from the Copernicus GLO-90 DEM

Averages the Copernicus DEM GLO-90 (public cloud-optimised GeoTIFFs on
AWS open data) onto the grid of `template`, reading each 1-degree tile
over `/vsicurl/`. Ground covered by no tile (open ocean away from land)
is `NA`; sea inside a tile is 0 m, as GLO-90 records it, so `NA` is not
a land mask. Used to drive climr's lapse-rate downscaling on the same
grid as the CGIAR AET, so no input is resampled twice.

## Usage

``` r
wet_dem_glo90(template, dir = "data/dem", overwrite = FALSE)
```

## Arguments

- template:

  Path to a raster (or a `SpatRaster`) whose grid is the output grid, in
  EPSG:4326.

- dir:

  Cache directory.

- overwrite:

  Logical. Rebuild even when cached.

## Value

Path to a one-layer GeoTIFF of elevation (m), named `elev`.

## Details

Copernicus DEM (c) DLR e.V. 2010-2014 and (c) Airbus Defence and Space
GmbH 2014-2018, provided under COPERNICUS by the European Union and ESA.
