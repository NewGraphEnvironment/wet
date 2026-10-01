# Adjust modelled AET by land cover, as Chapman et al. (2018) did

Chapman, Kerr & Wilford (2012, p. 83) multiply the CGIAR AET by a
per-class ratio of measured AET for the cover to the modelled
(agronomic-crop) AET, drawing the measured values from the table
published as Table 3 of Chapman et al. (2018, p. 8). The ratios they
used were tuned in calibration and never published, so here each class's
ratio is fixed without fitting:

## Usage

``` r
wet_aet_landcover(
  aet,
  frac,
  et_class = NULL,
  domain = NULL,
  min_cells = 1,
  clamp = c(0.25, 4)
)
```

## Arguments

- aet:

  One-layer `SpatRaster` of modelled annual AET (mm). The ratio
  denominators are taken over its non-`NA` cells.

- frac:

  `SpatRaster` of cover fractions (0-1), one layer per class, named by
  class, on the grid of `aet`; e.g.
  [`wet_landcover_nrcan()`](https://newgraphenvironment.github.io/wet/reference/wet_landcover_nrcan.md).

- et_class:

  Named numeric: measured AET (mm) per class, with a value for every
  layer of `frac`. Defaults to
  [`wet_chapman_table3()`](https://newgraphenvironment.github.io/wet/reference/wet_chapman_table3.md).

- domain:

  Optional one-layer `SpatRaster` on the grid of `aet`: only cells where
  it is `TRUE` (non-zero) count towards the ratio denominators. The
  adjustment is still applied everywhere.

- min_cells:

  Minimum majority cells for a class to get its own ratio.

- clamp:

  Lower and upper limits of a class ratio.

## Value

`list(aet, ratio)`: the adjusted AET (`SpatRaster`, mm) and a
`data.frame(class, et_mm, aet_mean, n_cells, ratio)`.

## Details

`ratio_c = et_class[c] / mean(aet over the cells where c is the majority)`

and the multiplier of each cell is
`sum_c frac_c * ratio_c + (1 - sum_c frac_c)`. Ground no class covers
(outside the land-cover product) keeps ratio 1, i.e. the input AET. A
cell votes for a majority class only when more than half of it is
covered and it lies in `domain`. A class with fewer than `min_cells`
majority cells gets ratio 1, and every ratio is clamped to `clamp`, so a
class whose modelled AET is near 0 (snow and ice) cannot scale its cells
without limit.

## Examples

``` r
r <- terra::rast(nrows = 1, ncols = 3, xmin = 0, xmax = 3, ymin = 0, ymax = 1)
aet <- terra::setValues(r, c(350, 330, 240))
frac <- c(terra::setValues(r, c(1, 1, 0)), terra::setValues(r, c(0, 0, 1)))
names(frac) <- c("coniferous", "grass")
out <- wet_aet_landcover(aet, frac)
out$ratio
#>        class et_mm aet_mean n_cells     ratio
#> 1 coniferous   276      340       2 0.8117647
#> 2      grass   275      240       1 1.1458333
terra::values(out$aet, mat = FALSE)
#> [1] 284.1176 267.8824 275.0000
```
