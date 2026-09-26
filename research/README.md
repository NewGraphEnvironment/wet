# Research

What is known, outliving the issue that found it. Each file is one topic, revised in place; `git log --follow` is its history.

| File | Covers |
|---|---|
| [pcic_hydrology.md](pcic_hydrology.md) | PCIC hydrologic products: hosts, gridded runs (historical + 12 CMIP5), grid and time axis, station and salmon products, the unreleased Raven CMIP6 work, terms |
| [fwapg_mad_method.md](fwapg_mad_method.md) | How fwapg builds `fwa_stream_networks_discharge`, the `wet` parity result, and how much area-weighted sampling moves it |

Naming: `<topic>.md`, revised in place, from 2026-09-06.

## Related work

- fwapg `extras/discharge/`: the SQL build `wet` reproduces.
- fresh#114: MAD predicate, the first consumer.
- knowledge#19: habitat-threshold and life-cycle timing evidence, which the monthly output feeds.
