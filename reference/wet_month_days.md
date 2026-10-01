# Days in each month, with February at 28.25

The monthly convention for the water balance: the twelve values sum to
365.25, the year
[`wet_mm_to_m3s()`](https://newgraphenvironment.github.io/wet/reference/wet_mm_to_m3s.md)
is given for annual flow, so monthly volumes add up to the annual
volume.

## Usage

``` r
wet_month_days()
```

## Value

Named numeric vector of length 12.

## Examples

``` r
sum(wet_month_days())
#> [1] 365.25
```
