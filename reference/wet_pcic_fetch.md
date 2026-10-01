# Download a PCIC VIC-GL subset over OPeNDAP

Requests `VAR[t0:t1][lat0:lat1][lon0:lon1]` as NetCDF and caches it. The
file is checked for a NetCDF signature before it is kept: an HTTP error
or redirect page saved under a `.nc` name is exactly how a download goes
wrong silently (PCIC moved hosts in 2026 and `curl` without `-L` saves
the 301 body).

## Usage

``` r
wet_pcic_fetch(
  variable,
  bbox,
  start,
  end,
  run = "TPS_gridded_obs_init",
  dir = "data/pcic",
  overwrite = FALSE,
  timeout = 3600
)
```

## Arguments

- variable:

  Character. VIC output variable, e.g. `"RUNOFF"` or `"BASEFLOW"`.

- bbox:

  Numeric `c(xmin, ymin, xmax, ymax)` in longitude/latitude.

- start, end:

  Dates (or strings coercible by
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html)), inclusive.

- run:

  Character. Run identifier. Default is the historical run.

- dir:

  Cache directory.

- overwrite:

  Logical. Re-download even when the cached file exists.

- timeout:

  Seconds allowed for the download.

## Value

Path to the NetCDF file.
