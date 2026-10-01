# Task: Vignette: Chinook flow at two stations, last five years vs 1981–2010, with a map (#27)

## Problem

The first pass (#29) built the path and the pkgdown scaffold, but the vignette is hard to review:

- **Too much at once.** 11 BULK windows across five species, so the hydrograph carries 11 strips per station and the heat strip 22 rows.
- **No sense of place.** Nothing shows where Buck Creek (08EE013) and Bulkley River near Houston (08EE003) are, or how they relate to each other.
- **The comparison a reader wants is not drawn on its own.** The question is how the last five years compare with 1981–2010, window by window. The heat strip holds the answer, but it is buried among 45 years and 11 windows.
- **Little interpretation.** The prose explains how to read the figures, not what they show.

Decided at the issue revision and the plan gate (2026-10-01): Chinook open-water windows only (migration, spawning, fry migration); baseline 1981–2010; recent years 2022–2026; heat strip and trends kept for the three windows; record-by-source figure and ice prose removed. Machine change approved with the plan: upgrade `cd` to >= 0.5.0 via `pak::pak("NewGraphEnvironment/cd")`.

## Phase 1: Map inputs
- [ ] `pak::pak("NewGraphEnvironment/cd")`, then confirm the current vignette renders locally (baseline before changes)
- [ ] `data-raw/station_vignette_data.R` gains a map section writing `inst/vignette-data/station_map.gpkg` (EPSG:3005). Its layers:
  - BULK watershed group;
  - order-≥5 streams in BULK, plus the full Bulkley and Buck Creek by blue_line_key, simplified after length is taken;
  - lakes over 100 ha;
  - both stations from HYDAT `STATIONS`, with drainage area;
  - each station's upstream catchment, via `wet_station_snap()` and `fwa_watershedatmeasure()`;
  - Houston from BC Geographic Names (bcdata);
  - a simplified BC outline for the keymap.
- [ ] Re-run the script. The daily series refreshes too, and its provenance records the new retrieval date. Check the bundle stays under 500 KB.
- [ ] `tests/testthat/test-vignette_data.R`: the gpkg has the expected layers, CRS 3005, both stations, and is inside the size cap
- [ ] `sf` and `tmap` added to Suggests

## Phase 2: Vignette, Chinook open-water
- [ ] Filter windows to CH rows that do not touch November–April, computed with the existing `touches_ice` test rather than hand-listed. Assert the result is exactly migration, spawning and fry migration.
- [ ] Remove the ice and provisional-winter machinery:
  - the drop rule;
  - the record-by-source figure and its prose;
  - the ice share and winter-mean sentences;
  - Houston's winter-gauging text.
- [ ] `recent <- (last_year - 4):last_year`. Assert every window's end date in `last_year` is on or before `max(daily$date)`.
- [ ] Registry (`inst/cartography/wet_station.csv`):
  - `recent_year` gets five ordinal classes;
  - drop `record_source` and the `dropped`/`no_baseline` classes;
  - add `station_catchment`;
  - add a two-class below/above layer for the key figure, from the BrBG ends already used.

## Phase 3: The map and the key figure
- [ ] Map (tmap v4, static), following the cartography rules:
  - catchments as a fill, so the subject is contained;
  - the Bulkley and Buck Creek emphasised over the order-≥5 network;
  - stations labelled with name and number, and Houston labelled;
  - a BC keymap in its own corner;
  - bbox matched to canvas aspect, no title, legend built from registry values;
  - self-reviewed against all 12 checks at delivered width.
- [ ] Key figure: one panel per station × window (2 × 3).
  - One bar per year, 2022–2026, as % of the window's 1981–2010 mean.
  - A 100% reference line, bars coloured below/above, and the value printed on each bar.
  - The 1981–2010 mean in m³/s in each panel label.
- [ ] Interpretation: three or four sentences, every number computed and guarded with `stopifnot`. For example: how many of the 25 window-years (5 years × 3 windows) were below normal at each station, the driest year and window, and whether the two stations agree.
- [ ] Hydrograph: three CH window strips and five recent-year lines. The daily-median band is named as the median (the #29 lesson).

## Phase 4: Heat strip, trends, limits, prose
- [ ] Heat strip: three windows × two stations from 1981, without the dropped and no-baseline classes
- [ ] Trends: three windows. Recompute the `n_tested`, `n_sig` and shared-dates text: CH spawning no longer shares dates with SK, but migration and spawning share 08-01.
- [ ] "What it does not show", in two or three lines:
  - the recent years are provisional;
  - the windows come from the literature;
  - a mean normal is skewed by wet years (keep the computed spawning mean vs median line).
- [ ] Framing paragraph and recipe chunk updated to the CH windows. Word cap held at 600, with the target lower.
- [ ] `research/station_flow_departure.md` § Species windows: add the Chinook open-water result, and a dated verified line

## Phase 5: Verify and ship
- [ ] `devtools::test()`, `devtools::check()` (vignette rebuilds), `pkgdown::check_pkgdown()`, local `pkgdown::build_site()`
- [ ] Read every figure PNG at delivered width. Enumerate every computed claim against the object it is computed from.
- [ ] `/code-check` per commit; Plan-agent review of the baseline, run concurrently
- [ ] `/planning-archive` (as `2026-10-issue-27-chinook-revision`), then `/gh-pr-push`

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
