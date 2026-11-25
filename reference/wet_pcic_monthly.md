# Mean monthly total per cell, fetched one year at a time

The monthly counterpart of
[`wet_pcic_annual()`](https://newgraphenvironment.github.io/wet/reference/wet_pcic_annual.md):
fetches each calendar year with
[`wet_pcic_fetch()`](https://newgraphenvironment.github.io/wet/reference/wet_pcic_fetch.md)
(cached per year), reduces it to that year's twelve monthly totals with
[`wet_runoff_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_runoff_monthly.md),
and averages them over the years. The result equals
[`wet_runoff_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_runoff_monthly.md)
on the whole period, and its twelve layers sum to
[`wet_pcic_annual()`](https://newgraphenvironment.github.io/wet/reference/wet_pcic_annual.md)'s.

## Usage

``` r
wet_pcic_monthly(
  variable,
  bbox,
  years,
  run = "TPS_gridded_obs_init",
  dir = "data/pcic",
  timeout = 3600
)
```

## Arguments

- variable:

  Character. VIC output variable, e.g. `"RUNOFF"` or `"BASEFLOW"`.

- bbox:

  Numeric `c(xmin, ymin, xmax, ymax)` in longitude/latitude.

- years:

  Integer vector of whole calendar years.

- run:

  Character. Run identifier. Default is the historical run.

- dir:

  Cache directory.

- timeout:

  Seconds allowed for the download.

## Value

A 12-layer `SpatRaster`, layers `m01` to `m12` (units of the variable
per month).

## Examples

``` r
if (FALSE) { # \dontrun{
# 1981-2010 runoff by month for one CMIP5 run, over a box near Prince George
# (30 one-year requests to PCIC, cached under data/pcic/)
m <- wet_pcic_monthly("RUNOFF", c(-123, 53.8, -122.5, 54.2), 1981:2010,
                      run = "CanESM2_rcp45_r1i1p1")
terra::global(m, "mean", na.rm = TRUE)
} # }
```
