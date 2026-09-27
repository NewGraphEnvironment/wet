# Research

What is known, outliving the issue that found it. Each file is one topic, revised in place; `git log --follow` is its history.

| File | Covers |
|---|---|
| [pcic_hydrology.md](pcic_hydrology.md) | PCIC hydrologic products: hosts, gridded runs (historical + 12 CMIP5), grid and time axis, station and salmon products, the channel-scale VIC-GL-Raven CMIP6 portal (May 2026), terms |
| [fwapg_mad_method.md](fwapg_mad_method.md) | How fwapg builds `fwa_stream_networks_discharge`, the `wet` parity result, and how much area-weighted sampling moves it |
| [water_balance_method.md](water_balance_method.md) | Chapman, Kerr & Wilford 2018 (the BC Water Tools method) and `wet`'s open reimplementation (#11): the method, 23 points where a reimplementation must choose and what was chosen, and blocked-CV skill at 290 HYDAT stations (33 % MAE out of sample, against 23 % in-sample). Map: [wb_runoff_annual.png](wb_runoff_annual.png) |
| [runoff_prior_art.md](runoff_prior_art.md) | Inputs for an open BC water balance (climr, ET sources), ranked comparison products (PCIC, GEOGLOWS, GloFAS, TerraClimate, BC runoff isolines, …), gauged-basin datasets, and nested-gauge validation practice |

Naming: `<topic>.md`, revised in place, from 2026-09-06.

## Related work

- fwapg `extras/discharge/`: the SQL build `wet` reproduces.
- fresh#114: MAD predicate, the first consumer.
- knowledge#19: habitat-threshold and life-cycle timing evidence, which the monthly output feeds.
