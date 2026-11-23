# Code-check enumeration: what ends the loop (#195, 2026-11-23)

Rounds 2 and 3 each found a defect inside the previous round's fix. Round 3 named the mechanism: **the Tool registry stores values derived from other artifacts, and a consumer combines a stored value with a live copy of its source, trusting the copy is the one the value came from**. The loop ends on this enumeration of every place that mechanism reaches, each held to its source of truth, with each guard added on this branch restored to the defect and watched to fail.

## Every value the Tool registry and manifest store (22)

| # | Field | Derived from | Held by |
|---|---|---|---|
| 1 | `station_number` | station list `nid` | harvest `treg_sel` (selection recomputed), `treg_bad`; runtime `wet_registry_check()` against the provincial registry |
| 2 | `id` | station list | harvest `treg_copy`; runtime `wet_bcwatertool()` refuses an id the manifest lacks |
| 3–6 | `name`, `network`, `lon`, `lat` | station list | harvest `treg_copy` (coordinates at the 15 digits `write.csv()` keeps) |
| 7–9 | `subdrainage`, `nearest_hydat`, `nearest_km` | HYDAT 20260717 | harvest `treg_near` (distance added at the enumeration) |
| 10–11 | `first`, `last` | Tool CSVs, the shipped rules, the cut | harvest `treg_off` |
| 12 | `regulation` | the name rule | harvest `treg_reg` |
| 13–14 | `hydat_site`, `hydat_km` | HYDAT 20260717, the survey's match | harvest `treg_site` |
| 15 | `credit` | each CSV's header | harvest `treg_copy` (added at the enumeration) |
| 16 | `continues` | provincial registry 20261028 | harvest `tshared_ok` (the survey's shared sites); runtime `wet_bcwatertool_against()` |
| 17 | `continues_before` | provincial days, manifest md5 and reader version | harvest `treg_cut`; runtime `wet_bcwatertool_against()` on `bcenv_days` |
| 18–19 | `bcenv_snapshot`, `bcenv_days` | the constants the pin read the provincial days through | runtime `wet_bcwatertool_against()`; registry validation (one value, not NA) |
| 20–22 | manifest `file`, `bytes`, `md5` | the survey's raw copy | `data-raw/station_sources_bcwatertool.R` against the survey report's two md5s; runtime `wet_bcenv_check()` per file read |

## Every consumer of the registry (4)

| Consumer | Combines with a provincial artifact | Guard |
|---|---|---|
| `wet_bcwatertool_station_days()` (`wet_station_daily()`) | yes | `wet_bcwatertool_against()`, `wet_registry_check()`; and the station-day given twice refused after the bind |
| `wet_station_list()` | yes | `wet_bcwatertool_against()`, `wet_registry_check()` |
| `scripts/station_sources_harvest.R` | yes | `wet_bcwatertool_against()` |
| `wet_bcwatertool_daily()` | no (the Tool alone: `id`, `subdrainage`) | needs none |

## Guards restored to the defect

- `wet_bcwatertool_against()` snapshot check removed: 2 failures in `test-wet_station_daily.R`.
- Its `bcenv_days` check removed: 2 failures.
- The station-day-given-twice refusal removed: 1 failure.
- Registry `credit` of the CRD rows and `nearest_km` of `ogc_1004` corrupted: the harvest exits 1 naming 8 and 1 listings.
