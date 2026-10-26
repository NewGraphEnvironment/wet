# Each year's ERA5-Land snow over one watershed

Reads cd's annual snow layers (one band per year, ERA5-Land at 0.1
degree) and returns each year's mean over a watershed: the per-year
values that
[`wet_snow_normals()`](https://newgraphenvironment.github.io/wet/reference/wet_snow_normals.md)
averages over 1981-2010 onto a grid, here kept year by year and for one
area.

## Usage

``` r
wet_snow_annual(
  ws,
  vars = c("snowmelt_doy_50", "swe_max"),
  years = NULL,
  catalog = NULL,
  cap = c(swe_max = 3000)
)
```

## Arguments

- ws:

  [`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html)
  of polygons, in any CRS: one watershed.

- vars:

  cd variable names, each with an `"annual"` row in `catalog`, for
  example `snowmelt_doy_50` (the day of the year by which half the
  year's snowmelt has happened), `swe_max` (the year's peak snow water
  equivalent, mm) or `snowmelt_rate_peak` (the peak weekly melt rate, mm
  per week).

- years:

  Years to return; every one must be a band of each variable's file.
  `NULL` returns every band year of the first variable, which every
  other variable must also have.

- catalog:

  A `data.frame` with columns `variable`, `period` and `href`, as from
  [`cd::cd_catalog()`](https://newgraphenvironment.github.io/cd/reference/cd_catalog.html);
  `NULL` reads cd's default catalog. A remote `href` is read through
  [`cd::cd_cache_fetch()`](https://newgraphenvironment.github.io/cd/reference/cd_cache_fetch.html);
  any other must be a local file.

- cap:

  Named numeric: an upper limit for each cell's value of each named
  variable, applied in every year before the mean. Variables not named
  are not capped. The default caps `swe_max` when it is in `vars`; a
  `cap` given explicitly must name only variables in `vars`.

## Value

`data.frame(year, <vars>, cover)`, one row per year in ascending order.
`cover` is the same in every row; where it is 0 the values are `NA`.

## Details

`ws` is one watershed, given as its fundamental watersheds (as fetched
from fwapg) or as a single outline. The polygons are dissolved into one
with
[`terra::aggregate()`](https://rspatial.github.io/terra/reference/aggregate.html)
and that union is sampled once with
[`wet_ws_sample()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_sample.md)
(`method = "area"`), so the fundamental watersheds and their union as
[`terra::aggregate()`](https://rspatial.github.io/terra/reference/aggregate.html)
returns it give identical results, and nested or overlapping polygons
count their ground once. A union stored and read back (as WKT, say)
agrees to the rounding of its coordinates. Several watersheds passed
together return the mean over their union; call once per watershed for
separate values.

The mean weights each cell by the share of that 0.1-degree cell the
watershed covers, as
[`wet_ws_sample()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_sample.md)
does, not by the cell's ground area. A cell's area shrinks with
latitude, by about 2.4 % per degree at 54 N, so for a watershed spanning
half a degree of latitude the two weightings differ by about 1 % between
its north and south edges; for one spanning many degrees, cells to the
south are underweighted by more.

Each variable and year is one layer of a single stack, so
[`wet_ws_sample()`](https://newgraphenvironment.github.io/wet/reference/wet_ws_sample.md)'s
rule holds across all of them: a cell counts only where **every** layer
has a value, and `cover` is one number, the share of the watershed on
those cells. A cell missing in one year or one variable therefore leaves
every year's value over the remaining cells, and a year's value can
depend on which `years` and `vars` are asked for. ERA5-Land has no cell
over the sea, so a watershed reaching the coast can report `cover` below
1.

`cap` limits each cell's value in each year before the mean, as
[`wet_snow_normals()`](https://newgraphenvironment.github.io/wet/reference/wet_snow_normals.md)
limits each cell's 1981-2010 mean: ERA5-Land's glacier points carry
perennial snow, with `swe_max` of 5,000 to 10,000 mm against a seasonal
maximum of about 3,000 mm elsewhere.

## See also

[`wet_snow_normals()`](https://newgraphenvironment.github.io/wet/reference/wet_snow_normals.md)
for the 1981-2010 means on a grid.

## Examples

``` r
# Maxan Creek above Bulkley Lake (08EE018) and cd's layers cropped to it,
# bundled with wet (data-raw/snow_pilot_data.R)
d <- system.file("extdata", "snow_pilot", package = "wet")
outline <- readRDS(file.path(d, "maxan_outline.rds"))
ws <- terra::vect(outline$wkt, crs = outline$crs)
cat <- utils::read.csv(file.path(d, "catalog.csv"))
cat$href <- file.path(d, cat$href)
snow <- wet_snow_annual(ws, c("swe_max", "snowmelt_doy_50"), catalog = cat)
head(snow)
#>   year  swe_max snowmelt_doy_50 cover
#> 1 1950 222.3437        142.0184     1
#> 2 1951 223.9557        129.9008     1
#> 3 1952 231.5902        136.5852     1
#> 4 1953 195.6545        132.3004     1
#> 5 1954 310.2845        144.5180     1
#> 6 1955 204.3500        148.6459     1
# peak snow and melt date over 2011-2025 against 1950-1980
rbind(early = colMeans(snow[snow$year <= 1980, 2:3]),
      late = colMeans(snow[snow$year >= 2011, 2:3]))
#>        swe_max snowmelt_doy_50
#> early 258.7510        138.3252
#> late  248.8356        128.5111
```
