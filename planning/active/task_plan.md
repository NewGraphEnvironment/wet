# Task: README: correct the link connection, list all three vignettes, describe the published product (#75)

The README is close to current (v0.4.4), but it states one pipeline connection that does not exist yet, and it leaves out the published product and a vignette.

## Context (from plan mode, 2026-10-16)

The New Graph website takes its wet copy from the README (newgraphenvironment.github.io#53), so the
README has to be right. The 2026-10-14 audit found three problems: one connection is described
ahead of the code, shipped work is missing, and links point at two different URLs. You chose the
full `readme.md` convention: section order, lifecycle badge and pin line, a figure made by a
committed script, Citation, and the tagline, DESCRIPTION and About kept in step.

Facts checked today (2026-10-16) that change the issue's premises:

- **The link item is out of date.** link#331 closed today (link PR #344, link v0.66.0). A link
  bundle now chooses `pipeline: discharge_source: fwapg | wet` (absent means fwapg). `default_tuned`
  reads wet's annual `pick` from `discharge.fwa_v1_segment_monthly`, loaded with `wet_db_load()`.
  `default` and `bcfishpass` stay on fwapg. **`lnk_discharge()` is not exported**; it is internal
  `.lnk_discharge_*`. So the fix is not "describe as planned". The README will say what is true
  now and will not name `lnk_discharge()`.
- **URL.** `newgraphenvironment.github.io/wet/` answers 301 to `www.newgraphenvironment.com/wet/`.
  `_pkgdown.yml`, DESCRIPTION and every sibling repo (link, fresh, gq, cd, flooded, drift) use
  github.io, so the README will too.
- **The README's "Segments" path describes the wrong product.** It covers PCIC VIC-GL accumulated
  by wet. The published product is routed PCIC (`pcic_routed`, 1951–2012) plus the open balance
  (`wet_balance`, 1981–2010), chosen per segment by `pick`.
- **The GitHub About is stale.** It says "climate-scenario" and "seasonal", neither of which is
  built.
- `.github/workflows/update-citation-cff.yaml` calls `cffr::cff_create()` without
  `authors_roles`, so New Graph Environment Ltd. is missing from `CITATION.cff`.

## Phase 1: Reference index grouped by purpose (`_pkgdown.yml`)
- [x] Add `reference:` sections, using each function's Rd title:
  - **Published discharge**: `wet_catalog`, `wet_db_load`, `wet_segment_monthly`, `wet_flow_window`, `wet_month_days`
  - **Station flow**: `wet_station_daily`, `wet_station_monthly`, `wet_station_select`, `wet_station_snap`, `wet_window_stats`, `wet_windows_calendar`
  - **Water temperature**: `wet_temp_daily`, `wet_temp_fill`, `wet_temp_gsdd`
  - **PCIC gridded runoff**: `wet_pcic_url`, `wet_pcic_index`, `wet_pcic_fetch`, `wet_pcic_annual`, `wet_runoff_annual`
  - **FWA watersheds and upstream accumulation**: `wet_ws_fetch`, `wet_ws_geom`, `wet_ws_sample`, `wet_upstream_mean`, `wet_upstream_means`, `wet_upstream_sums`, `wet_upstream_irregular`, `wet_upstream_pairs`, `wet_mm_to_m3s`
  - **Water balance inputs**: `wet_climr_normals`, `wet_cgiar_aet`, `wet_terraclimate_aet`, `wet_mod16_aet`, `wet_aet_budyko`, `wet_aet_landcover`, `wet_chapman_table3`, `wet_pet_hargreaves`, `wet_dem_glo90`, `wet_landcover_nrcan`, `wet_snow_normals`
  - **Water balance fit and validation**: `wet_wb_fit`, `wet_wb_adjust`, `wet_wb_pooled`, `wet_share_fit`, `wet_share_predict`, `wet_cv_folds`, `wet_flow_validate`
- [x] `pkgdown::check_pkgdown()` passes, so every one of the 46 exports is placed

## Phase 2: README figure from committed code
- [x] `data-raw/readme_figure.R`: draws the province map of the source `pick` takes on main-flow rivers
  of order 5 and up, with the 315 calibration gauges. It reads the bundled `inst/vignette-data/segment_map.rds`,
  `station_map.rds` and `segment_values.rds` from the source tree (`pkgload::load_all()`), takes its
  colours from `inst/cartography/wet_segment.csv` through gq, and draws the same ggplot as the
  segment article's `map-pick` chunk. It writes `man/figures/readme-pick.png`, opaque, at the README's width.
- [x] Read the PNG and run the cartography self-review (placement 1–7, communicate 8–12) at about 700 px

## Phase 3: README rewrite (`README.md`)
- [ ] Title line: hex sticker, lifecycle badge (experimental), and a tagline matching the DESCRIPTION `Title`
- [ ] Opening, 1–3 plain sentences: mean monthly and annual flow on every FWA segment, published
  openly from two sources, plus flow and water-temperature departures at stations. Say which
  decisions it informs: the discharge input to habitat models such as link's, and the flow and
  temperature in species windows for monitoring. Name no functions.
- [ ] Figure and caption, with alt text
- [ ] Installation, then what each path needs (fwapg and libpq env vars, HYDAT, duckdb; the
  published product needs no credentials). Add the "under active development, see NEWS" line and
  the `@vX.Y.Z` pin placeholder.
- [ ] Example: one short read of the published product (`wet_segment_monthly()` on one Bulkley
  segment, through duckdb), with output pasted from a real run. This replaces the station
  example, which the station article already shows.
- [ ] Learn more: all three articles with their titles ("Chinook Flow at Two Stations",
  "Stream Discharge per Segment", "Monthly Flow per Segment"), each a line on what it shows, then
  the function reference. All links on `newgraphenvironment.github.io/wet/`.
- [ ] Ecosystem: roles worded as in the sibling READMEs. link reads wet's published annual
  discharge in bundles set to `discharge_source: wet` and fwapg's table otherwise; no `lnk_discharge()`.
  Pipelines line corrected to match.
- [ ] Data and methods it builds on: PCIC VIC-GL and its Raven routing (hydromosaic), placed on
  the FWA by NewGraphEnvironment/fwapg#6; the FWA through fwapg; HYDAT; climr normals; CGIAR AET;
  ERA5-Land snow through cd; water-temp-bc; Chapman et al. (2018)
- [ ] Citation (`citation("wet")` / CITATION.cff) and License
- [ ] Leave out version strings, counts of published rows and function tables
- [ ] Check every claim against code: every function named is exported, every link resolves
  (curl each), each "both", "every" and plural checked against the code path

## Phase 4: Text that travels with the README
- [ ] DESCRIPTION `Description` in step with the opening (routed PCIC plus the balance, not
  VIC-GL alone), and "Under active development." Keep `Title` unless the tagline changes it.
  Run `devtools::document()`.
- [ ] `update-citation-cff.yaml`: `cffr::cff_create(authors_roles = c("aut", "cre", "cph"))`
- [ ] GitHub About, with `gh repo edit --description`: drop "climate-scenario" and "seasonal" and
  match the tagline. The homepage stays `www.newgraphenvironment.com/wet/`, which is where
  github.io lands.
- [ ] NEWS entry

## Validation

- [ ] `pkgdown::check_pkgdown()` clean; `pkgdown::build_site()` locally renders the home page with
  the figure and the grouped reference
- [ ] Tests pass (no R/ changes expected; `devtools::document()` clean)
- [ ] `/code-check` clean (once over the branch, `/code-check branch`), with the reviewer
  enumerating every README claim against code
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

