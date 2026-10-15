# Snow normals from cd's ERA5-Land annual snow layers

Reads cd's annual snow layers (one band per year, ERA5-Land at 0.1
degree, built by cd from the Earth Data Hub hourly store), takes the
per-cell mean over `years`, and resamples it bilinearly onto `grid`. The
mean is
[`cd::cd_baseline()`](https://newgraphenvironment.github.io/cd/reference/cd_baseline.html)'s
definition (the mean of the year values, `NA` removed), taken per cell
instead of over an area. Every year in `years` must be a band of the
file read.

## Usage

``` r
wet_snow_normals(
  grid,
  vars = c("snowmelt_doy_50", "swe_max"),
  years = 1981:2010,
  dir = "data/snow",
  catalog = NULL,
  cap = c(swe_max = 3000),
  overwrite = FALSE
)
```

## Arguments

- grid:

  Target grid: a `SpatRaster` or a path to one, in EPSG:4326.

- vars:

  cd variable names, each with an `"annual"` row in `catalog`.

- years:

  Years to average.

- dir:

  Cache directory.

- catalog:

  A `data.frame` with columns `variable`, `period` and `href`, as from
  [`cd::cd_catalog()`](https://newgraphenvironment.github.io/cd/reference/cd_catalog.html);
  `NULL` reads cd's default catalog. A remote `href` is read through
  [`cd::cd_cache_fetch()`](https://newgraphenvironment.github.io/cd/reference/cd_cache_fetch.html).

- cap:

  Named numeric: an upper limit for the per-cell mean of each named
  variable, applied before resampling. Variables not named are not
  capped.

- overwrite:

  Logical. Rebuild the resampled grid even when cached.

## Value

Path to a GeoTIFF with one layer per variable, named as in `vars`. The
cache key is the grid, `vars`, `years`, `cap`, the method version and
the values of the bands read (not their files, which cd rebuilds with a
new run time whenever it appends a year).

## Details

The defaults are the two predictors the monthly shares were scored with
(#16): `snowmelt_doy_50`, the calendar day of the year by which half the
year's snowmelt has happened, and `swe_max`, the year's peak snow water
equivalent (mm).

ERA5-Land has no cell over the sea, so cells of `grid` whose own
ERA5-Land cell is empty come out `NA` (GDAL's bilinear reweights around
missing neighbours); they are left for the caller to fill.

ERA5-Land's glacier points carry perennial snow: over 1981-2010, 513 BC
land cells have a mean `swe_max` of 5,000 to 10,000 mm, against a
seasonal maximum of about 3,000 mm elsewhere. `cap` limits each cell's
mean before resampling, so a glacier cell still reads as deep snow
without dominating an upstream mean (decided for \#16 before any score
was seen).

## Examples

``` r
if (FALSE) { # interactive()
g <- terra::rast(xmin = -127, xmax = -126, ymin = 54, ymax = 55, res = 1 / 120)
sn <- terra::rast(wet_snow_normals(g, dir = tempdir()))
terra::global(sn, "mean", na.rm = TRUE)
}
```
