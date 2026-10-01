# Actual evapotranspiration from the CGIAR Global Soil-Water Balance

Downloads the CGIAR-CSI Global High-Resolution Soil-Water Balance v3 AET
(Trabucco & Zomer; figshare article 7707605, CC0), checks each archive
against the md5 figshare reports, extracts it, and crops the annual and
12 monthly grids to `bbox`. This is the ET family Chapman et al. (2018)
used, on its native 30 arc-second grid, so it is cropped but never
resampled.

## Usage

``` r
wet_cgiar_aet(bbox, dir = "data/cgiar", overwrite = FALSE, timeout = 3600)
```

## Arguments

- bbox:

  Numeric `c(xmin, ymin, xmax, ymax)` in degrees (EPSG:4326), snapped
  outward to the 30 arc-second cell lattice.

- dir:

  Cache directory for the archives, extracted grids and the crop.

- overwrite:

  Logical. Rebuild the crop even when it is cached.

- timeout:

  Seconds allowed for each download.

## Value

Path to a GeoTIFF with 13 layers, `aet_01` to `aet_12` and `aet_yr`, in
mm.

## Details

The archives are RAR4 and ship ArcInfo grids. They are extracted with
`bsdtar` (libarchive), which reads RAR4; the Homebrew `7z` build does
not.
