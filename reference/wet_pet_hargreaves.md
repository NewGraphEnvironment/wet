# Monthly reference evapotranspiration by Hargreaves (FAO-56)

FAO-56 equation 52, `ET0 = 0.0023 (Tmean + 17.8) (Tmax - Tmin)^0.5 Ra`,
with `Ra` the extraterrestrial radiation (equation 21, converted to
mm/day by 0.408) on the month's representative day
`J = floor(30.4 M - 15)`, times the days in the month from
[`wet_month_days()`](https://newgraphenvironment.github.io/wet/reference/wet_month_days.md).
Allen et al. (1998), *Crop Evapotranspiration*, FAO Irrigation and
Drainage Paper 56, chapter 3.

## Usage

``` r
wet_pet_hargreaves(tmax, tmin, lat, month)
```

## Arguments

- tmax, tmin:

  Monthly mean daily maximum and minimum temperature (C): numeric
  vectors or `SpatRaster`s.

- lat:

  Latitude (degrees, south negative): numeric, or a `SpatRaster` such as
  `terra::init(tmax, "y")` on a geographic grid.

- month:

  Month, 1 to 12 (one value).

## Value

Reference evapotranspiration over the month (mm), numeric or a
`SpatRaster` like the inputs.

## Details

Hargreaves needs only temperature, so on climr's monthly `Tmax`/`Tmin`
normals it gives a demand on the same climate as the precipitation. A
negative diurnal range (independently downscaled `Tmin` above `Tmax`)
and `Tmean` below -17.8 C both give 0, never `NaN` or a negative demand.

## Examples

``` r
# a July at 50 N with a 20 C diurnal range: about 170 mm
wet_pet_hargreaves(tmax = 25, tmin = 5, lat = 50, month = 7)
#> [1] 171.0623
# the annual cycle at one place
round(vapply(1:12, function(m) wet_pet_hargreaves(c(-3, 0, 5, 11, 16, 20, 24, 24, 18, 10, 2, -3)[m],
  c(-10, -9, -5, -1, 3, 7, 9, 9, 5, 1, -4, -9)[m], 50.7, m), 0))
#>  [1]   7  15  37  70 111 133 155 131  75  33  11   6
```
