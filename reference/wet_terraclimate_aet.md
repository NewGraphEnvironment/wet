# Annual AET and precipitation from the TerraClimate 1981-2010 climatology

Downloads the TerraClimate monthly climatology files (Abatzoglou et al.
2018, *Scientific Data* 5, 170191; CC0) for `period`, sums the 12 months
into annual totals, and resamples them bilinearly from TerraClimate's
1/24-degree lattice onto `grid`. GDAL's bilinear reweights around
missing neighbours, so only cells whose own TerraClimate cell is empty
(sea, and some large lakes) come out `NA`; they are left for the caller
to fill.

## Usage

``` r
wet_terraclimate_aet(
  grid,
  period = "19812010",
  vars = c("aet", "ppt"),
  dir = "data/terraclimate",
  overwrite = FALSE,
  timeout = 1800
)
```

## Arguments

- grid:

  Target grid: a `SpatRaster` or a path to one, in EPSG:4326.

- period:

  Climatology period as in the file names: `"19812010"`, `"19611990"` or
  `"19912020"`.

- vars:

  TerraClimate variables to return, as annual totals.

- dir:

  Cache directory.

- overwrite:

  Logical. Rebuild the resampled grid even when cached.

- timeout:

  Seconds allowed for each download.

## Value

Path to a GeoTIFF with one layer per variable, named `<var>_tc` (mm per
year).

## Details

TerraClimate's AET comes from a Thornthwaite-Mather soil-water balance
on its own precipitation, so it carries that precipitation's biases. Its
precipitation layer is returned alongside so they can be seen.

The whole global file is downloaded (about 95 MB for AET, 147 MB for
precipitation), because the server's subset service returned empty
bodies when this was written (2026-09-27). The option
`wet.terraclimate_url` only sets where missing files are fetched from;
the cache key is the md5 of the files actually read.

## Examples

``` r
if (FALSE) { # interactive()
g <- terra::rast(xmin = -120, xmax = -119, ymin = 49, ymax = 50, res = 1 / 120)
tc <- terra::rast(wet_terraclimate_aet(g))
terra::global(tc, "mean", na.rm = TRUE)
}
```
