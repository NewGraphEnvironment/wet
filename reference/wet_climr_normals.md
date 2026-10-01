# Monthly climate normals for an arbitrary period from climr

Downscales climr's reference climatology onto an elevation grid, shifted
to the mean of an observed time series over `years`. climr expresses
each observed year as an anomaly on its 1961-1990 reference period: a
ratio for precipitation and an offset for temperature. Both are linear,
so averaging the anomalies before downscaling gives the same normal as
downscaling each year and averaging, at a thirtieth of the cost.

## Usage

``` r
wet_climr_normals(
  dem,
  years = 1981:2010,
  dataset = "mswx.blend",
  vars = c(sprintf("PPT_%02d", 1:12), sprintf("Tave_%02d", 1:12)),
  dir = "data/climr",
  overwrite = FALSE
)
```

## Arguments

- dem:

  Path to a one-layer elevation raster (m, EPSG:4326), or a
  `SpatRaster`. Its grid is the output grid.

- years:

  Integer vector of years to average.

- dataset:

  climr observed time series: `"mswx.blend"` (default), `"climatena"` or
  `"cru.gpcc"`. The ClimateNA series is `NA` over coastal islands (Haida
  Gwaii, northern Vancouver Island) on its 1-degree grid, so averaging
  its anomalies leaves those islands without normals; the 0.5-degree
  MSWX blend covers them.

- vars:

  climr variable codes to return: monthly `PPT_MM`, `Tave_MM`,
  `Tmax_MM`, `Tmin_MM`, and `MAP`, `MAT`. Derived variables that are not
  linear in the anomalies (degree days, PAS, CMD) are refused, since
  averaging anomalies first would bias them.

- dir:

  Cache directory.

- overwrite:

  Logical. Rebuild even when cached.

## Value

Path to a GeoTIFF with one layer per variable in `vars`.
