# Station sources beyond HYDAT: which networks hold BC discharge

**Verified:** 2026-10-28 · **Issues:** #123 (component 4 of #118), wet#140 (BC Hydro) · **Produced by:** web and API reads of each source (URLs inline), `scripts/station_sources_probe.R` → `data/checks/station_sources_20260717.txt` against HYDAT 2026-07-17, and an org-wide search of NewGraphEnvironment code and installed packages · **Status:** in progress

Tags: **[S]** the linked source says it · **[M]** measured (the probe report, or the command named beside it) · **[I]** inferred, not verified.

## The bar

Written before any source was checked (#123's plan gate, 2026-10-28). Every source and every asset found is recorded below, accessed or not, so the bar can be revisited. A verdict is a column over the inventory, not a filter on it.

- **harvest**: all four of these:
  - discharge (not only stage), with a maintained rating;
  - a licence that allows use and redistribution of derived values;
  - machine-readable access (API or bulk download);
  - at least 5 BC stations not in HYDAT, each with at least 3 complete years in a Chinook window.

  That is the size of record the Maxan pilot used (`research/station_flow_departure.md`). A window is the migration window (05-01–08-01) or the spawning window (08-01–09-15) of `inst/vignette-data/life_history_bulk.csv`. A complete year is a row that `wet_window_stats()` returns at `min_frac = 0.8`. A count taken from a listed period of record, without daily values, is a proxy tagged [I], and a proxy alone cannot reach harvest.
- **test-only**: discharge that can be used for scoring but fails the redistribution, QA or station tests. We score against it and never publish from it.
- **no**: stage only, no discharge, a duplicate of HYDAT, or no access. A station at a HYDAT site is a duplicate only where its period overlaps HYDAT's there. One that adds years at a discontinued HYDAT site is counted as "same site, new years".

Regulation is recorded for each station (natural, regulated or unknown), because the pilot's donor pool was natural only.

## Inventory

| Source | Asset | Discharge or stage; rating | QA | Licence | Access | Period, stations, not in HYDAT | Verdict |
|---|---|---|---|---|---|---|---|
| BC provincial hydrometric network | | | | | | | |
| Living Lakes Canada, Columbia Basin Water Hub | | | | | | | |
| Skeena Knowledge Trust | | | | | | | |
| DataStream hubs | | | | | | | |
| UNBC | | | | | | | |
| BC Hydro | | | | | | | |

## Already fetched by a New Graph package?

No (2026-10-28). The installed NewGraphEnvironment packages export only federal fetchers: `ngr::ngr_hyd_q_daily()`, `ngr::ngr_hyd_realtime()` (`tidyhydat::realtime_ws()`) and wet's `wet_station_*()`. A code search of the organisation finds these sources only cited, never fetched.
