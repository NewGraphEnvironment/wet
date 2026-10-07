# Research

What is known, outliving the issue that found it. Each file is one topic, revised in place; `git log --follow` is its history.

| File | Covers |
|---|---|
| [pcic_hydrology.md](pcic_hydrology.md) | PCIC hydrologic products: hosts, gridded runs (historical + 12 CMIP5), grid and time axis, station and salmon products, the channel-scale VIC-GL-Raven CMIP6 portal (May 2026), terms |
| [fwapg_mad_method.md](fwapg_mad_method.md) | How fwapg builds `fwa_stream_networks_discharge`, the `wet` parity result, and how much area-weighted sampling moves it |
| [water_balance_method.md](water_balance_method.md) | Chapman, Kerr & Wilford 2018 (the BC Water Tools method) and `wet`'s open reimplementation (#11): the method, 23 points where a reimplementation must choose and what was chosen, and blocked-CV skill at HYDAT stations (290 on HYDAT 2025-10-14; 315 on the 2026-07-17 refit shipped by #43, 27.5 % MAE). The ET experiment (#15) scored land-cover, TerraClimate and Fu–Budyko AET under a pre-set rule, and ships CGIAR floored by Fu–Budyko: 27.7 % MAE out of sample (31.2 % headwater), against 33.1 % (38.1 %) with CGIAR alone. MOD16 (#18) was scored against it under a second pre-set rule and loses (36.3 % headwater). The dry-interior diagnosis against PCIC (#45) names no single term: our P and AET both run well above PCIC's, and the dry zones differ from the rest in P. Scored at plateau-elevation gauges and snow courses (#50), climr is at most modestly high (not decided), and part of the gap is PNWNAmet's. Map: [wb_runoff_annual.png](wb_runoff_annual.png) |
| [station_flow_departure.md](station_flow_departure.md) | Per-year flow departure at hydrometric stations (#25): HYDAT → provisional (water-temp-bc) → real-time and where they meet, ice and provisional-winter limits, seasonal-gauge baselines, and 2023–2026 results at Buck Creek and Bulkley nr Houston |
| [station_water_temperature.md](station_water_temperature.md) | Water temperature at hydrometric stations (#36): the water-temp-bc `Parameter=5` archive, junk readings and the −1…35 °C range, local-standard-time days and the 20-hour rule, and baseline coverage by decade, which sets the 2016–2025 baseline |
| [runoff_prior_art.md](runoff_prior_art.md) | Inputs for an open BC water balance (climr, ET sources), ranked comparison products (PCIC, GEOGLOWS, GloFAS, TerraClimate, BC runoff isolines, …), gauged-basin datasets, and nested-gauge validation practice |

Naming: `<topic>.md`, revised in place, from 2026-09-06.

## Related work

- fwapg `extras/discharge/`: the SQL build `wet` reproduces.
- fresh#114: MAD predicate, the first consumer.
- knowledge#19: habitat-threshold and life-cycle timing evidence, which the monthly output feeds.
