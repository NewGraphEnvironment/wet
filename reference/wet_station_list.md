# Hydrometric stations beyond HYDAT that wet reads

One row per station of the networks
[`wet_station_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_station_daily.md)
reads outside Water Survey of Canada's HYDAT, with where each sits, the
days it holds, and the HYDAT station at the same site where there is
one. For HYDAT's own stations, use
[`wet_station_select()`](https://newgraphenvironment.github.io/wet/reference/wet_station_select.md).

## Usage

``` r
wet_station_list(sources = "bcenv", snapshot = wet_bcenv_snapshot)
```

## Arguments

- sources:

  Which networks to list; only `"bcenv"` so far.

- snapshot:

  The provincial snapshot, as `YYYYMMDD`.

## Value

`data.frame(station_number, name, lon, lat, source, network, first, last, regulation, hydat_site, hydat_km, licence, credit)`,
one row per station, ordered by number. `first` and `last` are the first
and last days
[`wet_station_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_station_daily.md)
returns for the station (`NA` for one with no complete day), recorded
when the snapshot was pinned and held to the reader's days by the
package's harvest check whenever its rules change; `hydat_km` is the
distance to `hydat_site`; `licence` and `credit` are the terms the
source's data carry and the line to credit it with.

## Details

The province's non-integrated hydrometric network (`"bcenv"`) is the one
such network so far: stations run by the province and its partners,
whose hourly discharge the province publishes beside HYDAT. Its list
comes from a pinned snapshot of those files, made with the package, so
it needs no download.

A provincial station at a HYDAT site keeps its own number, and its days
are never joined to the HYDAT station's: `hydat_site` names that station
(the same stream name within 1 km) so a caller can join the two.
Regulation is known only where a station's name says it (a dam,
diversion, intake and similar); every other station is `"unknown"`, not
natural.

## Examples

``` r
s <- wet_station_list()
nrow(s)
#> [1] 211
# provincial stations at a HYDAT station's site, carrying its record on in new years
head(s[!is.na(s$hydat_site), c("station_number", "name", "first", "last", "hydat_site", "hydat_km")])
#>    station_number                                    name      first       last
#> 4        08EE0001           Deep Creek at Farewell Bridge 2016-05-04 2018-11-22
#> 8        08HA0001                  Bonsall Creek at HWY 1 2016-08-06 2019-10-28
#> 12       08HA0019 Cusheon Creek at Outlet of Cusheon Lake 2017-05-26 2017-10-18
#> 13       08HA0020      Fulford Creek near Fulford Harbour 2018-02-16 2024-11-21
#> 15       08HA0022               Koksilah River at Trestle 2021-10-01 2026-10-02
#> 19       08HA0027             Patrolas Creek at Moss Road 2018-07-05 2019-09-11
#>    hydat_site hydat_km
#> 4     08EE022     0.14
#> 8     08HA022     0.86
#> 12    08HA026     0.04
#> 13    08HA055     0.21
#> 15    08HA045     0.06
#> 19    08HA019     0.20
```
