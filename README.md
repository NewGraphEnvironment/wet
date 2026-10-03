# wet <img src="man/figures/logo.png" align="right" height="139" alt="wet hex sticker" />

> Stream discharge for BC's Freshwater Atlas

Monthly, seasonal and mean annual flow per stream segment, historical and climate-scenario, from modelled runoff and hydrometric stations. wet builds its own open estimate and scores other groups' products (PCIC, fwapg, the BC Water Tools) against it and against HYDAT.

Two paths:

- **Segments.** Gridded runoff (PCIC VIC-GL, or an open water balance fitted at 290 HYDAT gauges) is sampled to FWA fundamental watersheds, accumulated upstream by area weighting, and converted to m³/s.
- **Stations.** Daily flow from HYDAT, continued by ECCC provisional and real-time data, summarised per year over month-day windows for [cd](https://github.com/NewGraphEnvironment/cd)'s departure statistics.

## Installation

```r
pak::pak("NewGraphEnvironment/wet")
```

## Prerequisites

The segment path needs PostgreSQL with [fwapg](https://github.com/smnorris/fwapg) loaded; [fresh](https://github.com/NewGraphEnvironment/fresh)'s `docker/` has a local setup. Connection is through the standard libpq env vars (`PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`). The station path needs a HYDAT database (`tidyhydat::download_hydat()`).

## Example

Flow at Buck Creek since 1981, against its 1981–2010 normal in three Chinook windows:

```r
library(wet)

q <- wet_station_daily("08EE013")  # HYDAT, then provisional, then real-time
w <- data.frame(window = c("Migration", "Spawning", "Fry migration"),
                start = c("05-01", "08-01", "07-15"), end = c("08-01", "09-15", "09-07"))
s <- wet_window_stats(q, w, stats = c("mean", "min7"))  # one value per year, window, statistic
s$station_number <- NULL                                 # cd takes one station per call

cd::cd_anomaly(s, cd::cd_baseline(s, 1981:2010))
```

## Vignettes

- [Chinook flow at two stations](https://www.newgraphenvironment.com/wet/articles/station-flow.html): the station path on 08EE013 and 08EE003, from map to departure and trend.
- [Mean annual discharge per segment](https://www.newgraphenvironment.com/wet/articles/segment-discharge.html): parity with fwapg on the Salmon River, the open water balance on the Bulkley, and its out-of-sample skill at 290 gauges.

Function reference and both vignettes are on the [pkgdown site](https://www.newgraphenvironment.com/wet/).

## Ecosystem

| Package | Role |
|---------|------|
| **wet** | Stream discharge per segment and per station (this package) |
| [fresh](https://github.com/NewGraphEnvironment/fresh) | Stream network modelling engine; its habitat rules can read mean annual discharge (`mad_m3s`) per segment |
| [cd](https://github.com/NewGraphEnvironment/cd) | Departure statistics (baseline, anomaly, trend) over wet's per-year values, and ERA5-Land climate |
| [gq](https://github.com/NewGraphEnvironment/gq) | Map symbology for the vignettes |
| [water-temp-bc](https://github.com/NewGraphEnvironment/water-temp-bc) | Monthly archive of ECCC provisional hydrometric data that bridges HYDAT and real-time |

**Pipelines:**

- Fish habitat: wet (discharge) &rarr; fresh (segment attribute, `mad` rules)
- Flow departure: wet (per-year window values) &rarr; cd (baseline, anomaly, trend)

## License

MIT
