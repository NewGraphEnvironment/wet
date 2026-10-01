# Convert a depth over an area to discharge

`m3/s = mm * area_m2 / 1000 / (days * 86400)`. The default `days = 365`
is the conversion fwapg uses for mean annual discharge. The water
balance uses 365.25 for a year and
[`wet_month_days()`](https://newgraphenvironment.github.io/wet/reference/wet_month_days.md)
for months, so that monthly volumes sum to the annual one.

## Usage

``` r
wet_mm_to_m3s(mm, area_m2, days = 365)
```

## Arguments

- mm:

  Depth over the period, mm.

- area_m2:

  Contributing area, m^2.

- days:

  Length of the period, days.

## Value

Discharge, m^3/s.

## Examples

``` r
wet_mm_to_m3s(500, 1e8)  # 500 mm/yr over 100 km2 is about 1.59 m3/s
#> [1] 1.58549
wet_mm_to_m3s(40, 1e8, days = wet_month_days()[7])  # 40 mm in July
#>      Jul 
#> 1.493429 
```
