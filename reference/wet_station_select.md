# Natural-flow HYDAT stations with a usable record in a period

Selects stations whose HYDAT regulation flag is `0` (stations with no
regulation record are treated as unknown and left out) and which have at
least `min_years` complete years inside `years`. A complete year has all
12 months, each with at least `min_days` days of daily flow. Seasonal
gauges therefore never qualify.

## Usage

``` r
wet_station_select(
  hydat = wet_hydat_path(),
  years = 1981:2010,
  min_years = 10,
  min_days = 20,
  prov = "BC"
)
```

## Arguments

- hydat:

  Path to the HYDAT sqlite database. Defaults to tidyhydat's download
  location.

- years:

  Integer vector of calendar years.

- min_years:

  Minimum number of complete years.

- min_days:

  Minimum days of flow for a month to count as complete.

- prov:

  Province or territory codes (`PROV_TERR_STATE_LOC`).

## Value

`data.frame(station_number, station_name, prov, lon, lat, drainage_area_gross_km2, n_years)`,
one row per qualifying station, with the complete years as attribute
`"years"` (a named list by station).

## Details

HYDAT's stations only. For natural stations outside HYDAT, the
province's non-integrated network and the BC Water Tool's gauges, see
[`wet_station_list()`](https://newgraphenvironment.github.io/wet/reference/wet_station_list.md)'s
`regulation`; they are not donors, since none holds 10 years of
1981–2010 record and on an estimated baseline they made carried
departures worse.
