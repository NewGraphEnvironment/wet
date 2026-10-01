# OPeNDAP index ranges for a bounding box and date range on the PCIC grid

The PCIC VIC-GL grid is 0.0625 degrees, with cell centres at
`lon0 + 0.0625 * i` and `lat0 + 0.0625 * j` (both ascending). Time is
daily, `days since 1945-01-01`, standard calendar, so the time index of
a date is its day offset from the origin.

## Usage

``` r
wet_pcic_index(
  bbox,
  start,
  end,
  origin = "1945-01-01",
  lon0 = -139.96875,
  lat0 = 41.09375,
  res = 0.0625,
  nlon = 496L,
  nlat = 367L
)
```

## Arguments

- bbox:

  Numeric `c(xmin, ymin, xmax, ymax)` in longitude/latitude.

- start, end:

  Dates (or strings coercible by
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html)), inclusive.

- origin:

  Time origin of the dataset.

- lon0, lat0:

  Centre of the first cell.

- res:

  Cell size in degrees.

- nlon, nlat:

  Grid dimensions.

## Value

Named list of zero-based inclusive integer pairs: `time`, `lat`, `lon`.

## Details

A cell is included when any part of it intersects `bbox`.

## Examples

``` r
# 1981-2010, the slice fwapg uses: time indices 13149 to 24105
wet_pcic_index(c(-122.5, 54, -122, 54.5), "1981-01-01", "2010-12-31")
#> $time
#> [1] 13149 24105
#> 
#> $lat
#> [1] 207 215
#> 
#> $lon
#> [1] 280 288
#> 
```
