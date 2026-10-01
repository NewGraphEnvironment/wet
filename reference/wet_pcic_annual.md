# Mean annual total per cell, fetched one year at a time

For basin-scale extents a whole 30-year daily subset does not fit in
memory (the Fraser is ~22,000 cells x 10,957 days per variable). This
fetches each calendar year with
[`wet_pcic_fetch()`](https://newgraphenvironment.github.io/wet/reference/wet_pcic_fetch.md)
(cached per year), reduces it to that year's total with
[`wet_runoff_annual()`](https://newgraphenvironment.github.io/wet/reference/wet_runoff_annual.md),
and averages the yearly totals: the same result as
[`wet_runoff_annual()`](https://newgraphenvironment.github.io/wet/reference/wet_runoff_annual.md)
on the whole period, i.e. cdo's `-timmean -yearsum`.

## Usage

``` r
wet_pcic_annual(
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

A one-layer `SpatRaster` (units of the variable per year).
