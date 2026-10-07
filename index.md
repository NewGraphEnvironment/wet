# wet

> Stream flow and water temperature for BC’s Freshwater Atlas

Mean annual and monthly flow per stream segment, and flow and
water-temperature departures at hydrometric stations. wet builds its own
open estimate and scores other groups’ products (PCIC, fwapg, the BC
Water Tools) against it and against HYDAT.

Three paths:

- **Segments.** Gridded runoff is sampled to FWA fundamental watersheds,
  accumulated upstream by area weighting, and converted to m³/s. Two
  sources:
  - PCIC VIC-GL, historical, over the Peace, Fraser and Columbia;
  - an open water balance (climr precipitation less a Budyko-floored
    AET), province-wide, fitted at 315 HYDAT gauges and giving mean
    annual and monthly flow.

  The PCIC fetchers take PCIC’s climate-scenario runs through `run =`,
  but no scenario output is built yet.
- **Station flow.** Daily flow from HYDAT, continued by ECCC provisional
  and real-time data, summarised per year over month-day windows for
  [cd](https://github.com/NewGraphEnvironment/cd)’s departure
  statistics.
- **Station water temperature.** Daily water temperature from the ECCC
  readings that water-temp-bc archives (about 300 stations, from 2002),
  through the same windows to cd. The baseline is 2016–2025, because few
  loggers reach back to 1981–2010.

## Installation

``` r

pak::pak("NewGraphEnvironment/wet")
```

## Prerequisites

The segment path needs PostgreSQL with
[fwapg](https://github.com/smnorris/fwapg) loaded;
[fresh](https://github.com/NewGraphEnvironment/fresh)’s `docker/` has a
local setup. Connection is through the standard libpq env vars
(`PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`). The station
flow path needs a HYDAT database
([`tidyhydat::download_hydat()`](https://docs.ropensci.org/tidyhydat/reference/download_hydat.html)).
The water-temperature path needs `duckdb`; it reads water-temp-bc’s
public archive, so no credentials are needed.

## Example

Flow at Buck Creek since 1981, against its 1981–2010 normal in three
Chinook windows:

``` r

library(wet)

q <- wet_station_daily("08EE013")  # HYDAT, then provisional, then real-time
w <- data.frame(window = c("Migration", "Spawning", "Fry migration"),
                start = c("05-01", "08-01", "07-15"), end = c("08-01", "09-15", "09-07"))
s <- wet_window_stats(q, w, stats = c("mean", "min7"))  # one value per year, window, statistic
s$station_number <- NULL                                 # cd takes one station per call

cd::cd_anomaly(s, cd::cd_baseline(s, 1981:2010))
```

## Vignettes

- [Chinook flow at two
  stations](https://www.newgraphenvironment.com/wet/articles/station-flow.html):
  the station path on 08EE013 and 08EE003, from map to departure and
  trend.
- [Mean annual discharge per
  segment](https://www.newgraphenvironment.com/wet/articles/segment-discharge.html):
  parity with fwapg on the Salmon River, the open water balance on the
  Bulkley, the two estimates side by side, and the balance’s
  out-of-sample skill at 315 gauges.

Function reference and both vignettes are on the [pkgdown
site](https://www.newgraphenvironment.com/wet/).

## Ecosystem

| Package | Role |
|----|----|
| **wet** | Stream flow per segment and per station, and station water temperature (this package) |
| [fresh](https://github.com/NewGraphEnvironment/fresh) | Stream network modelling engine; its habitat rules can read mean annual discharge (`mad_m3s`) per segment |
| [link](https://github.com/NewGraphEnvironment/link) | Habitat interpretation layer that runs fresh’s pipeline; reads mean annual discharge per segment through `lnk_discharge()` |
| [cd](https://github.com/NewGraphEnvironment/cd) | Departure statistics (baseline, anomaly, trend) over wet’s per-year values, and ERA5-Land climate |
| [gq](https://github.com/NewGraphEnvironment/gq) | Map symbology for the vignettes |
| [water-temp-bc](https://github.com/NewGraphEnvironment/water-temp-bc) | Monthly archive of ECCC provisional hydrometric data (discharge and water temperature) that bridges HYDAT and real-time |

**Pipelines:**

- Fish habitat: wet (discharge) → link (`lnk_discharge()`, pipeline) →
  fresh (segment attribute, `mad` rules)
- Flow departure: wet (per-year window values) → cd (baseline, anomaly,
  trend), against 1981–2010
- Water-temperature departure: wet (per-year window values, °C) → cd,
  against 2016–2025

## License

MIT
