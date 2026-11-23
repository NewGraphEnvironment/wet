# Findings — Backlog move 8: Stations beyond HYDAT (#179)

## Issue context

**If we do it:** `wet_station_daily()` reads the province's non-integrated hydrometric stations and the BC Water Tool's third-party gauges, so departures at ungauged sites anywhere in BC (#118) gain donors and held-out tests beyond Water Survey of Canada's network. **If we never do:** donors stay federal only, and basins only the province or a third party gauges keep no local record in wet.

Order: `planning/backlog.md`, move 8. Run `/planning-init <this issue>`: one phase, one PR.

Split out of move 5 (#167) at its plan gate, 2026-11-18: at the four chinook sites these networks add no donor. Counted from `data/checks/station_sources_20260717.txt` against each box in `scripts/departure_sites.csv`, the Maxan, Swift and Gosnell boxes hold no beyond-HYDAT station with three complete chinook-window years, and the Naver box five provincial stations with three or four, all from 2016–2020. A carry donor needs at least ten years inside 1981–2010, so their value is province-wide, not at those sites.

## Batch 7: stations beyond HYDAT

**Why here:** both feed `wet_station_daily()`, share the QA and regulation questions, and meet at six sites both hold.

**Touches:** `R/wet_station_daily.R` and new readers, `research/station_sources.md`, `data/checks/`.

**Decided at the gate:** keep, flag or drop ungraded and unchecked values; which copy at the shared sites; the credit line each published series carries.

| issue | title |
|---|---|
| #142 | Harvest the province's non-integrated hydrometric discharge into wet_station_daily() |
| #144 | Harvest the third-party gauge records the BC Water Tool serves into wet_station_daily() |


## Errors Encountered

| Error | Resolution |
|-------|------------|
| Full suite: `test-wet_bcenv.R` failed after `test-wet_bcenv_daily.R`, alone it passed | A bare `on.exit()` inside a `test_that()` replaced the frame's exit handlers, so the mock of `wet_bcenv()` was never restored (and the tempdirs not removed); `withr::defer()` instead. testthat 3.3.2's `local_mocked_bindings()` has no `.local_envir`: `.env` is the cleanup frame, and an unknown argument is read as a binding to mock |
| duckdb outside strict mode reads a non-numeric value as NULL and keeps a row with extra fields; it drops only a blank line | Values read as text and refused unless numeric; the line-count check catches the blank line |
| The harvest report's largest relative difference moved between runs (8.78e-16, 8.24e-16) | duckdb's parallel `avg()` sums in no fixed order; the report prints the threshold it meets (`under 1e-12`) |
