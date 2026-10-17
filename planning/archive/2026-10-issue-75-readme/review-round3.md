# /code-check round 3, branch 75-readme-correct-the-link-connection-list (#75)

Reviewed at HEAD afe954b: the branch diff (planning files and PNG excluded) and the full current
README.md, DESCRIPTION, _pkgdown.yml, data-raw/readme_figure.R, man/wet-package.Rd and
.github/workflows/update-citation-cff.yaml. Checklist: the README and writing sections and the
data-raw / R CMD build rules of the code-check conventions.

## The mechanism behind rounds 1 and 2

Both earlier findings were a sentence that names a set by its most familiar members
(`writing.md`, "State each claim by the code's definition"): "needs only duckdb" named the
duckdb read and missed `wet_temp_daily()`'s tidyhydat call; "on a common grid" named the grids
and missed a table and a formula. Every place in this diff where a sentence or desc names a set
of functions, paths, sources or packages was walked member by member below. The mechanism
reaches the reworded line itself.

## Findings

- **[claim]** _pkgdown.yml:53 (the afe954b rewording, "Water balance inputs"):
  "Precipitation, evapotranspiration, terrain, land cover and snow, and the evapotranspiration
  models applied to them." This leaves out temperature, which is an input, and one of the group's
  models is applied to it. `wet_climr_normals()` returns `Tave_01..12` by default
  alongside `PPT` (R/wet_climr_normals.R:26-27), and `Tmax`/`Tmin` on request.
  scripts/wb_inputs.R:47-49 builds the Tmax/Tmin normals for `wet_pet_hargreaves()`, whose only
  climate inputs are `tmax` and `tmin` (R/wet_pet_hargreaves.R:28). So "the evapotranspiration
  models applied to them" includes Hargreaves, applied to temperature, which the list does not
  name. This is the same mechanism, found inside round 2's fix: climr's normals are named by their
  most familiar layer, precipitation. Fix: e.g. "Climate normals (precipitation and
  temperature), evapotranspiration, terrain, land cover and snow, and the evapotranspiration
  models applied to them."

- **[claim, minor]** _pkgdown.yml:40 ("Watersheds and upstream accumulation"): "Sample a grid to
  FWA fundamental watersheds and average it over each upstream area." This misses two of the group's ten
  members. `wet_mm_to_m3s()` ("Convert a depth over an area to discharge") and `wet_month_days()`
  ("Days in each month, with February at 28.25") neither sample nor average. They are the step from
  the upstream mean to m³/s. Round 2 noticed this (row 45) and passed it. It is the same shape
  as the "Water balance inputs" desc that was then reworded, so it should be treated the same way.
  Fix: e.g. "... average it over each upstream area, and convert the result to discharge."

Nothing else found. In particular, these checks passed:

- **Workflow quoting.** `cff_create(authors_roles = c("aut", "cre", "cph"))` uses only double
  quotes inside the `Rscript -e '...'` single-quoted string, so the shell string is valid. The
  step was extracted verbatim from the YAML and run with bash in a temp copy (cffr 1.4.2, whose
  `cff_create` has an `authors_roles` formal). It wrote a valid CITATION.cff with authors Irvine
  and `name: New Graph Environment Ltd.`, in both `authors` and `preferred-citation`.
- **man/wet-package.Rd.** `roxygen2::roxygenise(roclets = "rd")` on a `git archive HEAD` copy
  reproduces `man/` byte for byte (`/usr/bin/diff -r`). A positive control (an edited
  Description) did reach the regenerated Rd, so the run is real. The new author lines
  ("(New Graph Environment Ltd.)", "[copyright holder, funder]") come from the unchanged
  `Authors@R`.
- **data-raw/readme_figure.R from a clean session.** `Rscript --vanilla data-raw/readme_figure.R`
  in a `git archive HEAD` copy ran with no package loaded. It needs only ggplot2, sf and gq
  and calls no wet function, so dropping `load_all` loses nothing. The data-raw "load the
  source tree" rule has nothing to protect here. It reproduced `man/figures/readme-pick.png`
  byte-identically (1050x960 RGB, no alpha, so the background is opaque). The script resolves
  paths relative to the repo root, as its usage line implies.
- **The header comment.** It reads only `segment_map.rds`, `station_map.rds` and
  `wet_segment.csv`, so it touches no bucket, fwapg or HYDAT. The article map
  (vignettes/segment-discharge.Rmd:173-207) is the same river layer plus gauges (`gpts`) and
  region labels (`lab`), so "without its gauges and labels" is exact.
- **Reference index.** The 46 NAMESPACE exports equal the index entries, with no duplicates.

## Every set-naming sentence in the diff, member by member

| Where | Set named | Members checked | Verdict |
|---|---|---|---|
| DESCRIPTION / Rd | "published ... from two sources: PCIC's routed model, and an open water balance" | `wet_segment_sources()`: pcic_routed, wet_balance | exact |
| DESCRIPTION / Rd | "Daily flow and water temperature at hydrometric stations are summarised per year over month-day windows" | `wet_station_daily()`, `wet_temp_daily()` -> `wet_window_stats()` | supported (fill and GSDD are not mentioned; this is not an "only" claim) |
| README opening | flow and water temperature at stations; gaps filled from air temperature | `wet_station_daily`, `wet_temp_daily`, `wet_temp_fill(temp, air, pool)` | supported |
| README caption | "each larger river's default flow" with two colours | segment_map.rds `class`: pcic_routed 4,010, wet_balance 1,303, none 458 features (not drawn) | not a finding: the undrawn "none" rivers are under 0.3 % of drawn length per the article. The caption leaves that out, which the user's "not too much detail" covers |
| README caption | balance "fills in where that model does not reach or reads far too low" | `wet_source_pick()`: routed NA, or routed < 0.2 x balance on its own line | supported (round 2 row 14) |
| README Installation | "Reading the published flow needs only duckdb" | `wet_catalog()` (curl, jsonlite: Imports), `wet_segment_monthly(NULL, ...)` (duckdb); `wet_db_load()` needs Postgres but is a load into a database, and the `conn`/`fwapg` reads presuppose one | supported for reading the parts |
| README Installation | temperature also tidyhydat; flow a HYDAT database; building the flow fwapg | R/wet_temp_daily.R:98,166; R/wet_station_daily.R:167,189; `wet_ws_fetch` | supported (round 2 table) |
| README Example | both sources; month 0 is the year | output: routed month 0 = 1411/12 = 117.6 -> 118; 17057325 = 08EE004 Bulkley River at Quick in monthly_values.rds | supported |
| README Learn more | three articles, then the temperature group, then reference | vignettes/: monthly-flow, segment-discharge, station-flow; titles match; temperature group = temp_daily/fill/gsdd | exact |
| README Ecosystem | link reads wet's published discharge; cd computes departures | link origin/main (41cb8fd6) R/lnk_discharge.R:189-237, R/lnk_preflight_discharge.R:14 read `discharge.fwa_v1_segment_monthly` loaded by `wet::wet_db_load()` | supported |
| README Data | routed = PCIC VIC-GL + Raven, placed by the fwapg fork | fwapg PR #6 merged 2026-10-08 into `newgraph`; repo public | supported |
| README Data | "Station data come from HYDAT, ECCC's real-time feed and its provisional records as archived by water-temp-bc" | flow: the three; temperature: water-temp-bc Parameter=5 only | supported (each member draws from the named set) |
| _pkgdown:7 Published discharge | read per-segment and per-watershed published discharge | wet_catalog (manifest, both datasets), wet_db_load(`dataset =` any ID), wet_segment_monthly (segment; its `from = "fwapg"` mode reads the pre-publish table) | supported |
| _pkgdown:13 Station flow | daily/monthly flow; gauges the balance is fitted at | station_daily, station_monthly; station_select (natural-flow gauges), station_snap (snaps them to the FWA) | supported |
| _pkgdown:20 Water temperature | daily, gap filling, GSDD | temp_daily, temp_fill, temp_gsdd | exact |
| _pkgdown:26 Date windows | mean flow, or per-year statistics, over month-day windows | flow_window, window_stats, windows_calendar (defines the windows) | supported |
| _pkgdown:32 PCIC gridded runoff | fetch VIC-GL variables, summarise per year | pcic_url/index/fetch, pcic_annual, runoff_annual | supported |
| _pkgdown:40 Watersheds and upstream | sample, then average upstream | ws_fetch/geom/sample, upstream_mean(s)/sums/irregular/pairs; **mm_to_m3s, month_days not covered** | finding 2 |
| _pkgdown:53 Water balance inputs | P, ET, terrain, land cover, snow, and ET models applied to them | climr_normals (**P and temperature**), cgiar/terraclimate/mod16 AET, dem_glo90, landcover_nrcan, snow_normals, aet_budyko, aet_landcover, chapman_table3, **pet_hargreaves (on temperature)** | finding 1 |
| _pkgdown:67 Water balance fit | fit at gauges, split into months, score held out | wb_fit/adjust/pooled, share_fit/predict, cv_folds, flow_validate | supported |
| readme_figure.R header | reads two rds and one csv; never bucket, fwapg, HYDAT | the script body | exact |
