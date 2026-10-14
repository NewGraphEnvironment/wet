# Task: Per-segment flow: wet_segment_monthly(), and wet_flow_window() for date windows (#59)

## Problem

Segment flow is read in at least four places, each with its own code:
- `scripts/mad_basin.R`, `scripts/mad_parity.R` and `scripts/wb_term_diagnose.R` join fwapg's gridded annual table (`fwa_stream_networks_discharge`) by hand.
- `scripts/pcic_routed_compare.R` (#58) has its own SQL against the routed table, plus `routed_annual()` in `scripts/pcic_routed_lib.R`.
- `data-raw/monthly_vignette_data.R` reads the published parts with duckdb. `vignettes/monthly-flow.Rmd` shows that read and says this function replaces it.
- The monthly article computes window flow from monthly means by hand (`from_months()` in its `windows` chunk). It measured that estimate at up to 27 % off the gauge's daily record.

Life-stage windows straddle months, and a freshet can rise and fall inside one month. Until daily flow exists (#70), a window estimated from months is the best available, and it should be labelled as such rather than computed silently in each caller.

## Decisions (plan gate, 2026-10-14)

- **Source:** published product by default; `from = "fwapg"` opt-in reads fwapg's routed monthly table. Reason: `pcic_routed_compare.R` runs *before* a publish (segment_output and the publish refuse a routed table other than the compare report's), so it must score fwapg's table, not the last publish. Both mappings live in one internal lookup.
- **pcic_gridded:** left out. Its readers keep their SQL; adding it later is one lookup row.
- **Missing segment:** 13 rows (months 0–12), `q_m3s` NA.

## Phase 1: Tests first
- [x] `tests/testthat/test-wet_segment_monthly.R`: fixture tree (`local_discharge_tree()`, `wet_catalog(<local manifest>)`) through the parquet path — both sources' months 0–12 equal the fixture; a missing segment gives 13 NA rows; `groups` filters; duplicates in `segments` deduped, NA refused; unknown source, source with no parts and absent scenario stop with the name
- [x] Same file, `local_fwapg()`: Postgres published path on the fixture loaded into a throwaway schema (as `test-wet_db_load.R`), equal to the parquet path; missing table stops naming `wet_db_load()`; `from = "fwapg"` on 17094080 equals the routed table's months with month 0 = mean of 12; `wet_balance` and a non-historical scenario refused from fwapg; missing fwapg table names the fork
- [x] `tests/testthat/test-wet_flow_window.R`: monthly path reproduces the article's `from_months()` (copied as oracle) on the three Chinook windows; a window inside one month equals that month; `"12-15"`–`"01-15"` = (17·Dec + 15·Jan)/32; an `"02-29"` end takes 28 February days; a daily fixture gives `basis = "daily"`; `by = "station_number"` on `wet_station_monthly()`-shaped input; a missing month gives NA; month+doy, duplicates, bad windows refused; month 0 ignored
- [x] Confirm both files fail (functions absent)

## Phase 2: wet_segment_monthly()
- [ ] `R/wet_segment_monthly.R`: exported function, internal `wet_segment_sources()` and `wet_segment_read()` (dataset ID → table or parts; timebase → time column)
- [ ] roxygen with a runnable example: `inst/extdata/` ships only the fixture manifest, so `data-raw/discharge_fixture.R` also writes the fixture's parquet parts beside it (a few KB; the manifest's md5s stay true) and the example reads them offline, guarded by `requireNamespace("duckdb")`
- [ ] `_pkgdown.yml` reference entry; `devtools::document()`; `pkgdown::check_pkgdown()`
- [ ] Phase 1 reader tests pass

## Phase 3: wet_flow_window()
- [ ] `R/wet_flow_window.R`, reusing `wet_windows_check()`; runnable example (synthetic months + `wet_windows_calendar()` + a species window)
- [ ] `_pkgdown.yml`; document; Phase 1 window tests pass

## Phase 4: Callers
- [ ] `routed_annual()` in `scripts/pcic_routed_lib.R` becomes `wet_segment_monthly(conn, lfid, "pcic_routed", from = "fwapg")` month 0; probe: old SQL vs new on every calibration-gauge segment, identical (covers `data-raw/segment_vignette_data.R` too)
- [ ] `scripts/pcic_routed_compare.R`: commit, rerun (`WET_FWAPG_COMMIT=341b078`), tracked `data/checks/pcic_routed_compare_20260717.txt` reproduces except its wet-commit line
- [ ] `data-raw/monthly_vignette_data.R`: the recipe check calls `wet_segment_monthly(NULL, lfid, groups = "BULK", catalog = <verified catalog>)`; the bundle read (`read_pub()`, needs period/pick/coverage/runoff_mm) stays and says why
- [ ] `vignettes/monthly-flow.Rmd`: the `read` chunk shows `wet_segment_monthly()`; `from_months()` → `wet_flow_window()` (sources by `c("station_number", "source")`, observed months by `station_number`); prose that promised #59 updated, gaps bullet removed
- [ ] Regenerate `inst/vignette-data/monthly_values.rds`; values identical to the old bundle except provenance (`built`, `wet_commit`)
- [ ] Render the article before and after: window table and every inline number identical

## Phase 5: Docs
- [ ] `CLAUDE.md`: readers line (`wet_catalog()`, `wet_db_load()`, `wet_segment_monthly()`, `wet_flow_window()`) and the monthly-flow paragraph; `research/discharge_publish.md` readers section
- [ ] Issue #59 body: record the plan-gate decisions (both stores, gridded out, NA shape)

## Validation
- [ ] Tests pass
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
