# Findings — Backlog move 14: Regulation per non-HYDAT station (#196)

## Issue context

**If we do it:** every station in wet's non-HYDAT registry, provincial and third-party, carries a regulation status from what sits upstream of it, so the natural ones can be donors for departures at ungauged sites (#118). **If we never do:** `wet_station_select()` keeps leaving every non-HYDAT station out as a donor, because unknown is not natural, and the stations moves 8 and 13 bring serve as records and held-out tests only.

Order: `planning/backlog.md`, move 14. Run `/planning-init <this issue>`: one phase, one PR. It starts once move 13 has merged, so the status is computed once, over the provincial and the Tool's stations both.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 14, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

## Batch 16: regulation per non-HYDAT station

**Why here:** one column over the registry move 13 settles; the prerequisite for any non-HYDAT donor. Dams, reservoirs and licensed diversions are placed upstream of each snapped station on the FWA, as `scripts/wb_gauge_diversion.R` places water licences for the calibration gauges.

**Touches:** `R/wet_station_list.R`, `R/wet_station_select.R`, `data-raw/station_sources_snapshot.R`, `inst/extdata/station_sources/`, `research/station_sources.md`, `tests/testthat/test-wet_station_select.R`, and a new placement script with its report under `data/checks/`.

**Decided at the gate:** the rule for natural, regulated and unknown, registered in a script's header before it is applied; which registers enter (the provincial dam register, licensed diversions, reservoirs) and under what licence; whether a status can differ by window (a diversion that runs only in summer); where donor selection reads it.

| issue | title |
|---|---|
| #191 | Regulation per non-HYDAT station, so the natural ones can be donors |

### Carried issue #191

**If we do it:** each station of the province's non-integrated network (and, once #144 lands, the BC Water Tool's third-party stations) carries a regulation status, so the natural ones can serve as donors for departures at ungauged sites (#118). **If we never do:** none of them can be a donor, because `wet_station_select()` leaves out stations whose regulation is unknown, and unknown is not natural.

Today `wet_station_list()` knows regulation only where a station's name says it ("regulated by name": a dam, diversion, intake and similar; 10 provincial stations); every other station is `"unknown"`. Move 8 (#179) brought these stations to `wet_station_daily()` as records and held-out tests only, and left their regulation to this issue.

## To establish

- What upstream of each snapped station regulates its flow: dams (the provincial dam register), reservoirs, and licensed diversions, placed upstream on the FWA as `scripts/wb_gauge_diversion.R` places water licences for the calibration gauges.
- A rule, registered before it is applied, for when a station counts as natural, regulated or unknown, and whether it may differ by window (a diversion that runs only in summer).
- Where the status lives: a column of the station registry `data-raw/station_sources_snapshot.R` writes, read by `wet_station_list()` and by whatever selects donors.

Left out of move 8 (#179, #142).

## Exploration, 2026-11-23 (plan, read-only)

- `wet_station_list()` (`R/wet_station_list.R`) reads the registries' `regulation` column: `"regulated by name"` (from `scripts/station_sources_lib.R`'s `regulation_of()`) or `"unknown"`. Both registries are written by data-raw scripts (`data-raw/station_sources_snapshot.R` step 5; `data-raw/station_sources_bcwatertool.R` line ~252) and the harvest report checks the registries' column against the name rule (`scripts/station_sources_harvest.R` lines 219-220, 384).
- `wet_station_select()` is HYDAT-only: SQL on `STN_REGULATION.REGULATED = 0` and `DLY_FLOWS` complete years. The departure scripts (`scripts/departure_site.R:269`, `scripts/departure_pcic.R:393`) query HYDAT's flag directly for their donor boxes; `wet_window_extend()` takes a `stations` frame "as from `wet_station_select()`".
- `wet_station_snap()` needs `drainage_area_gross_km2` to choose between candidates. Provincial files state no area; 32 of the Tool registry's 53 rows carry `# Drainage Area,<value>` in their file header (21 `None`), measured on the survey's raw copy (`data/station_sources/raw/bcwatertool/`). The Tool's station listing `area` field is -1 throughout.
- #53's method (`scripts/wb_gauge_diversion.R`): WFS layers `WLS_WATER_RIGHTS_LICENCES_SV` and `WRIS_DAMS_PUBLIC_SVW`, paged and held to the server's count; licence rows deduplicated per licensee repeat; classes storage / instream / consumptive by purpose code; placement in FWA watersheds and `fwa_upstream()` on codes, with a stream-position test in the gauge's own reach; flags L ≥ 10 % and S ≥ 10 % of observed runoff.
- Dam register (the cached copy of #53's snapshot, 2026-10-07): 2,490 dams; regulated code Regulated 1,710, `Regulated - Part 3 Exempt` 290, Non-Regulated incl. minor 490; operation Active 2,081, Breached 122, Decommissioned 99, Not Constructed 110, Deactivated 34, Removed 22, Application 22; height median 3 m (165 NA).
- Registries: `bcenv_20261028_hydat.csv` 211 stations; `bcwatertool_20261028_hydat.csv` 53 rows (46 own, 7 continuing a provincial number, which `wet_station_list()` folds into the provincial row).

## Errors Encountered

| Error | Resolution |
|-------|------------|
