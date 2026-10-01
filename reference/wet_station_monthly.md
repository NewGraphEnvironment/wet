# Observed monthly and annual flow climatology at HYDAT stations

For each station, averages the monthly mean daily flow over its complete
years, the same set of years for every month, so the monthly and annual
values describe one record. Monthly volumes use
[`wet_month_days()`](https://newgraphenvironment.github.io/wet/reference/wet_month_days.md),
and the annual flow is the volume-weighted mean over a 365.25-day year,
so the twelve shares sum to 1.

## Usage

``` r
wet_station_monthly(stations, hydat = wet_hydat_path(), min_days = 20)
```

## Arguments

- stations:

  Output of
  [`wet_station_select()`](https://newgraphenvironment.github.io/wet/reference/wet_station_select.md);
  its `"years"` attribute says which years to use per station.

- hydat:

  Path to the HYDAT sqlite database. Defaults to tidyhydat's download
  location.

- min_days:

  Minimum days of flow for a month to count as complete.

## Value

`data.frame(station_number, month, q_m3s, share, n_years)`, with `month`
1-12 and 0 for the annual mean flow (`share` 1).
