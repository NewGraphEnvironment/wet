# Mean monthly total per cell from a daily raster

For each calendar month, sums the month's daily layers in each year,
then averages those totals over the years. The twelve layers sum to
[`wet_runoff_annual()`](https://newgraphenvironment.github.io/wet/reference/wet_runoff_annual.md)'s
annual mean, so a monthly share is a layer over their sum. Units follow
the input (PCIC mm/day in, mm/month out).

## Usage

``` r
wet_runoff_monthly(r)
```

## Arguments

- r:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  of daily layers with a `Date` time axis.

## Value

A 12-layer `SpatRaster`, layers `m01` to `m12`.

## Details

Only complete years are accepted, as in
[`wet_runoff_annual()`](https://newgraphenvironment.github.io/wet/reference/wet_runoff_annual.md),
so every month is averaged over the same years.

## Examples

``` r
d <- seq(as.Date("1983-01-01"), as.Date("1984-12-31"), by = "day")
r <- terra::rast(nrows = 1, ncols = 2, nlyrs = length(d), vals = 1)
terra::time(r) <- d
# one mm a day: each month's mean total is its mean number of days
m <- wet_runoff_monthly(r)
terra::values(m)[1, ]
#>  m01  m02  m03  m04  m05  m06  m07  m08  m09  m10  m11  m12 
#> 31.0 28.5 31.0 30.0 31.0 30.0 31.0 31.0 30.0 31.0 30.0 31.0 
# and the months add up to the annual mean, (365 + 366) / 2
terra::values(sum(m))[1, ]
#>   sum 
#> 365.5 
```
