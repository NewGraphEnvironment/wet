# Annual AET on a grid from MODIS MOD16A3GF v061

Downloads the MOD16A3GF v061 granules (Running, Mu and Zhao, NASA LP
DAAC, doi:10.5067/MODIS/MOD16A3GF.061; gap-filled annual ET, 500 m
sinusoidal) for every sinusoidal tile `grid` touches and every year in
`years`, averages the annual ET per pixel, and puts the mean on `grid`.
MOD16 is a Penman-Monteith model driven by MODIS land cover, LAI and
albedo and by GMAO meteorology, so unlike a soil bucket it is not capped
by a precipitation field.

## Usage

``` r
wet_mod16_aet(
  grid,
  years = 2001:2020,
  dir = "data/mod16",
  overwrite = FALSE,
  timeout = 600,
  fact = 4,
  min_years = 10
)
```

## Arguments

- grid:

  Target grid: a `SpatRaster` or a path to one, in lon/lat (EPSG:4326).

- years:

  Calendar years to average.

- dir:

  Cache directory for the granules and the result.

- overwrite:

  Logical. Rebuild the grid even when cached.

- timeout:

  Seconds allowed for each download (a granule is about 20 MB).

- fact:

  Subdivision of each `grid` cell for the nearest-neighbour step; 4
  makes a 30 arc-second cell about 230 x 130 m at 55 N, finer than 500
  m.

- min_years:

  Valid years a pixel needs for its mean to count.

## Value

Path to a GeoTIFF with layers `et_mod16` (mm per year) and `frac_mod16`.

## Details

The `ET_500m` layer (kg/m2/yr, i.e. mm/yr; stored as unsigned 16-bit
with a 0.1 scale that terra applies) has a valid range of 0-65500. Codes
65529-65535 mark pixels the product does not model (unclassified, urban,
permanent wetland, snow and ice, barren, water, fill), so every value
above the valid range is a gap. A pixel's mean is taken over its valid
years and kept only when it has at least `min_years` of them, since its
land-cover class can change between years.

The tiles are mosaicked in their sinusoidal CRS and put on `grid` in two
steps, as in
[`wet_landcover_nrcan()`](https://newgraphenvironment.github.io/wet/reference/wet_landcover_nrcan.md):
nearest onto a grid `fact` times finer than `grid` and aligned with it,
then block means. A single warp would take each target cell's footprint
as an axis-aligned box in the source CRS, and the sinusoidal grid is
strongly sheared at BC's longitudes. The result has two layers:
`et_mod16`, the mean over the valid part of each cell, and `frac_mod16`,
the share of the cell that is valid (0-1). Where the share is 0,
`et_mod16` is `NA`; filling the gaps is left to the caller, and
`frac_mod16` lets it weight the fill by area.

Granules are listed through NASA's CMR search (no login) and downloaded
from LP DAAC with an Earthdata login read from a netrc file: the option
`wet.earthdata_netrc`, otherwise the first of `$NETRC`, the file
`earthdatalogin` keeps (`tools::R_user_dir("earthdatalogin")/netrc`) and
`~/.netrc` that has a `machine urs.earthdata.nasa.gov` entry. Downloads
are written to `.part`, renamed on HTTP 200 and opened before they are
kept, since a failed login can end on a page served with 200. Granules
already in `dir` are used without a search, and the grid is cached under
a key that includes the md5 of every granule read.

## Examples

``` r
if (FALSE) { # interactive()
# needs an Earthdata login in a netrc; about 20 MB a granule on first use
g <- terra::rast(xmin = -120, xmax = -119, ymin = 50, ymax = 51, res = 1 / 120)
m <- terra::rast(wet_mod16_aet(g, years = 2010:2011, min_years = 1))
terra::global(m, "mean", na.rm = TRUE)
}
```
