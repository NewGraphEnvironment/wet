# Download a PCIC VIC-GL subset over OPeNDAP

Requests `VAR[t0:t1][lat0:lat1][lon0:lon1]` as NetCDF and caches it. The
download reads its HTTP status: a 429 or 503 (the server asking for
less) waits for `Retry-After`, or 60 s doubling when none is given, and
tries again, five tries in all; any other status but 200 stops. A 200 is
checked for a NetCDF signature, and its days must be exactly `start` to
`end`, before it is kept: an HTML page saved under a `.nc` name, or a
file on another calendar, is exactly how a download goes wrong silently.
A file already in the cache is returned as it is, unread. Requests carry
the user agent `wet`.

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

## Details

A function set as option `wet.pcic_request_log`, taking
`(url, status, bytes, secs)`, is called after every request this makes,
a retry or a refused one included (`status` 0 where curl itself failed),
so a caller can keep a record of each request.
