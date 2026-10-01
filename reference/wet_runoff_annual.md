# Mean annual total per cell from a daily raster

Sums each calendar year's daily layers, then averages the yearly totals:
the same as `cdo -timmean -yearsum`, which is how fwapg builds mean
annual discharge. Units follow the input (PCIC mm/day in, mm/yr out).

## Usage

``` r
wet_runoff_annual(r)
```

## Arguments

- r:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  of daily layers with a `Date` time axis.

## Value

A one-layer `SpatRaster`.

## Details

Only complete years are accepted, because a partial year's sum is not an
annual total and would bias the mean low without any warning.
