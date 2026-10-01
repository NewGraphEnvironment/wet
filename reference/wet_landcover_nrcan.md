# Land-cover fractions on a grid from the NRCan 2020 land cover

Downloads the Natural Resources Canada 2020 Land Cover of Canada (30 m,
Cloud-Optimized GeoTIFF, Open Government Licence - Canada) once, and
averages it onto `grid` as one fraction layer per land-cover class of
[`wet_chapman_table3()`](https://newgraphenvironment.github.io/wet/reference/wet_chapman_table3.md):
the share of each cell covered by the NRCan codes that map to that
class.

## Usage

``` r
wet_landcover_nrcan(
  grid,
  table = wet_chapman_table3(),
  dir = "data/landcover",
  overwrite = FALSE,
  timeout = 7200,
  fact = 30
)
```

## Arguments

- grid:

  Target grid: a `SpatRaster` or a path to one (EPSG:4326 here).

- table:

  Class table with `class` and `nrcan_2020_codes` (`;`-separated).

- dir:

  Cache directory for the source file and the fractions.

- overwrite:

  Logical. Rebuild the fractions even when cached.

- timeout:

  Seconds allowed for the download (about 2.1 GB).

- fact:

  Subdivision of each `grid` cell for the nearest-neighbour step; 30
  makes a 30 arc-second grid 1 arc-second, about the source's 30 m.

## Value

Path to a GeoTIFF with one fraction layer (0-1) per class.

## Details

It is done in two steps. First the codes are resampled (nearest) onto a
grid `fact` times finer than `grid` and aligned with it, in `grid`'s
CRS. Then a VRT carries one band per class, each a lookup table that
turns the class's codes into 1 and every other code into 0, and
[`terra::aggregate()`](https://rspatial.github.io/terra/reference/aggregate.html)
takes their block means onto `grid`. A single average warp from the
source CRS is not used: GDAL takes each target cell's footprint as an
axis-aligned rectangle in the source CRS, and NRCan's Lambert conformal
grid is rotated about 20 degrees against a lon/lat cell in western BC,
which put single cells off by up to 0.3 (measured 2026-09-27; the
two-step fractions match exact-overlap counts to a mean 0.002). Ground
outside Canada (the product's no-data 0) and codes no class claims count
as uncovered, so the fractions of a cell sum to less than 1 there and
[`wet_aet_landcover()`](https://newgraphenvironment.github.io/wet/reference/wet_aet_landcover.md)
leaves that part of the cell unadjusted.

NRCan publishes no checksum for the file (its ETag is a multipart hash),
so the download is written to `.part` and renamed only on HTTP 200, its
md5 belongs in the caller's input manifest, and the fractions are cached
under a key that includes the source file's md5 (hashing 2.1 GB takes a
few seconds on each call). The option `wet.nrcan_landcover_url` only
sets where a missing source file is fetched from; delete the cached file
to fetch another.

## Examples

``` r
if (FALSE) { # interactive()
# about 2.1 GB on first use
g <- terra::rast(xmin = -120, xmax = -119, ymin = 49, ymax = 50, res = 1 / 120)
fr <- terra::rast(wet_landcover_nrcan(g))
terra::global(fr, "mean")
}
```
