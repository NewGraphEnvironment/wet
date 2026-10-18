# Observed day-of-year flow climatology at HYDAT stations

For each station, the mean daily flow on each day of a 365-day common
year over its complete years, the same years
[`wet_station_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_station_monthly.md)
uses, so the daily and monthly climatologies describe one record. 29
February is folded into 28 February: in a leap year the two days are
averaged before the years are. A day with no value in any complete year
(at most 11 days a month can be missing in a complete year) is filled by
linear interpolation from its neighbours around the year, and counted in
the `"filled"` attribute. `share` is the day's part of the year's
volume, so the 365 shares sum to 1.

## Usage

``` r
wet_station_doy(
  stations,
  hydat = wet_hydat_path(),
  years = attr(stations, "years"),
  min_days = 20
)
```

## Arguments

- stations:

  Output of
  [`wet_station_select()`](https://newgraphenvironment.github.io/wet/reference/wet_station_select.md),
  or any data frame with a `station_number` column when `years` is
  given.

- hydat:

  Path to the HYDAT sqlite database. Defaults to tidyhydat's download
  location.

- years:

  Named list, by station, of the complete years to average over; by
  default the `"years"` attribute
  [`wet_station_select()`](https://newgraphenvironment.github.io/wet/reference/wet_station_select.md)
  sets.

- min_days:

  Minimum days of flow for a month to count as complete.

## Value

`data.frame(station_number, doy, q_m3s, share, n_years)`, 365 rows per
station, with attribute `"filled"`: a data frame of the
`station_number, doy` pairs that were interpolated (zero rows when
none).

## Examples

``` r
if (FALSE) { # \dontrun{
# a HYDAT release pinned through wet's cache (see wet:::wet_hydat)
h <- wet:::wet_hydat("20260717")
s <- wet_station_select(h)
d <- wet_station_doy(s[s$station_number == "08EE013", ], h,
                     years = attr(s, "years")["08EE013"])
# a month's days average to its monthly mean, February aside (28 vs 28.25 days)
tapply(d$q_m3s, wet:::wet_doy_month(), mean)
} # }
```
