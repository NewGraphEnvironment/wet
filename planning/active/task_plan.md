# Task: Article: stream temperature for every reach, from stations to a network model (#220)

The roadmap (#214) tracks what is being finished and in what order. It is the right place for status and the wrong place to learn the idea: it has no figures, and a reader has to know what a holdout, an open-loop fill or network kriging is before the first section. The functions have reference pages and the methods have research files, but nothing shows how they fit together.

Branch `220-article-stream-temperature-for-every-rea` off `origin/main` (6095690). One pull request.

## Context

The roadmap (#214) is text written for a modeller. Nothing public shows, with figures, what growing-season
degree days are, where temperature is measured and where it is not, and how stations become a value at every
reach. #220 asks for one article, `vignettes/articles/segment-temperature.Rmd`, served at
`articles/segment-temperature.html`, with four figures built from a committed bundle, so the site build needs
no database. No baseline or PCIC scores go in (those wait on #213 and #219); the page is revised in place when
they exist.

What exploration found, which shapes the phases:

- The article pattern is settled: `vignettes/articles/flow-change-sparse-gauges.Rmd`
  (`bookdown::html_document2`, bundle read with `system.file("vignette-data", ...)`, colours from a gq registry
  CSV with each class set asserted, `stopifnot()` beside every number the prose quotes, a closing "Software and
  citation" section, a `wordcount` chunk with a cap, a `.bib` written by `data-raw/vignette_bib.R`).
- Map layers come from `scripts/vignette_map_lib.R` (`vm_stations()`, `vm_bc()`, `vm_places()`, `vm_points()`,
  `vm_simplify()`, `vm_layers()`, `vm_write()`, which leaves an unchanged bundle untouched). `vm_streams()`
  selects by a box and a minimum order, not by basin, so the basin's network needs one new helper there.
- `tests/testthat/test-vignette_data.R` holds every file in `inst/vignette-data/` to a named budget of 500 KB
  per article (`expect_setequal(files, unlist(budget))`), so new bundle files must be added to it or it fails.
- `wet_temp_fill()` needs the station's whole record and its sub-drainage peers to fit, so the fill is run in
  `data-raw/` and its result bundled; `wet_temp_gsdd()` returns the value but not the season's dates, which
  `gsdd::gsdd()` gives.
- The build database holds `whse_basemapping.fwa_stream_networks_mainflow_tree`. The Bulkley's tree is 52,293
  segments, 27,858 of them first order (the 57,371 first written here counted every Freshwater Atlas segment
  of the BULK and MORR groups), so what the map can draw inside 500 KB is measured, not assumed.
- `gsdd` is not installed on the build machine; `fresh` (0.55.1, published 0.57.0) and `gq` (0.22.0, published 0.25.0)
  are stale. Zotero answers here, so the `.bib` can be written.
- A read of the public archive (2002–2025, the eight `08EE` stations) found one year that has a single gap
  inside an otherwise observed March to November: 08EE012, Simpson Creek at the mouth, 2020, 25 August to
  22 September (29 days). The day before the gap reads 15.5 °C after 9.6 °C the day before it.

## Decided at the gate

- **Listed in the Articles menu**, after `segment-discharge` (not under `internal`): the issue asks for it on
  the site and for the roadmap to link it. Mine, 2026-11-25.
- **Title** "Stream Temperature per Segment: How We Get There", opening with the statement that the product is
  not built yet (the issue's).
- **File names**, fixed before the baseline: `data-raw/temperature_vignette_data.R`,
  `data-raw/temperature_vignette_map.R`, `scripts/temperature_basins.csv`,
  `inst/vignette-data/temperature_values.rds`, `temperature_map.rds`, `temperature_chain_nodes.csv`,
  `temperature_chain_edges.csv`, `inst/cartography/wet_temperature.csv`.
- **The basin is a table row** (`scripts/temperature_basins.csv`: basin id, main stem `blue_line_key`, the
  watershed groups, the towns labelled, the rivers named), read by both data scripts, so a second basin later
  is a data edit (the repo's site-table convention). The station-year is computed by the rule, never stored
  in the table.
- **The basin rule**, written in the data script's header before the pick is computed:
  1. candidates are whole basins the fork's network check ran clean on with the additive-function step on,
     as the fork's network-check record states when the script is written (today: the Bulkley alone; the
     Skeena ran the topology check only, and the other clean runs are single watershed groups);
  2. among them, the basin with the most temperature stations snapped to its network.
- **The station-year rule**, in the same header:
  1. stations whose Freshwater Atlas snap (`wet_station_snap()`) lies in the basin; water from
     `wet_temp_daily()` over 2002-01-01 to 2025-12-31, a fixed range so the pick does not move as the archive
     grows;
  2. a year qualifies when 1 March to 30 November has exactly one run of missing days of 7 to 45 days with
     observed days on both sides, and every other missing run is 2 days or shorter (the fill validation's
     tolerance);
  3. the station is fitted by `wet_temp_fill()` (pool: its WSC sub-drainage), the filled year gives a degree-day
     value where the unfilled year gives `NA`, and the gap lies inside the growing season `gsdd` finds;
  4. the pick is the year whose gap is closest to 30 days (the validation's 30-day holdout, whose error is
     known); ties go to the later year, then the station number;
  5. with no candidate the gap bound widens once to 60 days, then the next basin by the basin rule; with none
     still, the script stops and prints the candidate table.
  The rule was written after the probe above, which is why it is stated here with what the probe showed.
  It is not adjusted for the warm day before the gap: Phase 1 checks that day against air temperature and the
  two neighbours observed that year and records what it finds, and the article shows the day as
  `wet_temp_daily()` returns it, saying so if it reads as a logger out of the water.
- **The diagram and the holdout sketch are drawn with `ggplot2`**, already in `Suggests`: a static figure that
  rebuilds identically, no new dependency and no widget. The diagram's boxes and arrows are two small CSVs
  (label, position, state: in place, being built, a network model's, comparison), so a state change when work
  lands is a data edit. The holdout sketch is a drawn toy network, labelled as a sketch: the trait table for
  temperature stations does not exist yet (#213 builds it), so real neighbours cannot be drawn honestly.
- **The map draws the main-flow tree** (the network a model is handed), plain `geom_sf` with gq styles, a
  keymap and a scale bar as the other wet articles do, with no tile basemap. It draws down to the lowest
  stream order that keeps the bundle under the test's 500 KB, and the caption says which orders are drawn and
  how many reaches are not.
- **Counts the article carries:** the basin's reach count and how many reaches hold a temperature station,
  from the bundle, dated by the archive read; and the measured station error it closes on (the whole-season
  degree-day error, read from its line in the tracked `data/checks/temp_fill_validate.txt`). No roadmap
  progress, no checklist; the article links #214 for status.
- **The article does not call `gsdd` at build.** The bundle carries the fill and the degree-day value; the
  article accumulates the bundled daily means over the bundled season and stops unless its total equals the
  bundled value.
- **Package installs on the build machine, approved with this plan:** `gsdd` (in `Suggests`, missing), and `fresh` and
  `gq` brought to their published releases before the data scripts run.
- **The issue body moved during the plan gate** (edited 2026-11-25 18:11 UTC; re-read before this baseline).
  Its closing now says growing-season degree-day thresholds exist for cutthroat trout (from Colorado
  subspecies, applied to westslope cutthroat in the Elk Valley reports) and none has been found yet for the
  other BC species, where the copy the plan was approved on said no source gives one for a BC species. Phase
  3's closing section and its citations follow the body as it stands; nothing else in the plan moves.
- **Folded in from the plan review** (`review-220.md`, 2026-11-25; mine): the recipe is the whole pool, not
  one station; Figure 1 draws the open-loop line and its caption states what the suspect day adds, from a
  second fill with that day hidden; the article closes on open-loop's whole-season error, named as such; the
  word cap is 1,200, set before drafting; a reader with none of the repo's context reads the built page.
- **Release:** a NEWS bullet under the development heading and `Bump: patch` in the PR body; no function
  changes.

## Phase 1: The rule, the pick and the values bundle

- [x] Install `gsdd`; upgrade `fresh` and `gq`; state the versions in `findings.md`.
- [x] `scripts/temperature_basins.csv` with the Bulkley's row.
- [x] `data-raw/temperature_vignette_data.R`: the two rules in its header; `vd_commit()` first; reads the basin
      row; snaps the temperature stations (`wet_station_snap()`, HYDAT release from `wb_hydat(wb_release())`);
      reads water for the sub-drainage pool (`wet_temp_daily()`) and air (`cd::cd_extract_daily()`, dropping
      the stations cd names as outside its cube, as `scripts/temp_fill_validate.R` does); builds the candidate
      table and the pick; runs `wet_temp_fill()` and `wet_temp_gsdd()`; takes the season's first and last day
      from `gsdd::gss()` (`gsdd::gsdd()` returns none; corrected in Phase 1) and stops unless its value equals
      `wet_temp_gsdd()`'s. No station of this pool lies outside cd's cube, so the drop-and-retry was left out:
      a point cd cannot place stops the script with cd's message.
- [x] The bundle `inst/vignette-data/temperature_values.rds`: the picked station's year (observed days, filled
      days with their interval, air, open-loop `S`), the season dates and the degree-day value filled and
      unfilled, the fit row, the candidate table and the pick, the stations in the basin with their segment,
      the validation line read from `data/checks/temp_fill_validate.txt`, and provenance (commit, archive read
      date, HYDAT release, `cd` and `gsdd` versions). Plain types, no `integer64`.
- [x] A rerun that changes no value leaves the file's bytes as they are (compare before writing, as
      `vm_write()` does).
- [x] Check the day before the gap against air and the neighbours; record the finding in `findings.md`.
- [x] Tests in `tests/testthat/test-vignette_data.R`: the budget list gains a `temperature` entry; the bundle's
      names and types; the pick satisfies the rule on the bundle's own candidate table; filled days lie only in
      the gap; the accumulated degree days equal the bundled value.

## Phase 2: The basin map bundle

- [x] `vm_tree()` in `scripts/vignette_map_lib.R`: the main-flow tree's segments under a main stem's watershed
      code, ordered on `linear_feature_id`, merged per blue line and stream-order class and simplified in sf,
      with a per-order table of every segment (drawn or not), and the basin polygon with its area taken before
      the simplify.
- [x] `data-raw/temperature_vignette_map.R`: basin, tree, lakes (`vm_lakes()`), towns (`vm_places()`, from the
      basin row), the province outline (`vm_bc()`), the stations as points with the pick marked, the rivers the
      map names; `vm_layers()` provenance plus the tree's build as far as the database records it; written
      with `vm_write()`.
- [x] Measure the bundle at each minimum order and take the lowest that keeps both temperature bundles under
      500 KB together; record the measurements in `findings.md`.
- [x] `inst/cartography/wet_temperature.csv`: the map's classes (basin, network, station, the picked station),
      the station-year figure's (observed, filled, interval, air, season), the diagram's four states and the
      sketch's marks.
- [x] Tests: the layers are sf in EPSG:3005 and non-empty; the two bundles hold the same stations and
      segments (the script holds each segment to the tree at build); the picked station is among them; the
      per-order table sums to the basin's reach count.
- [x] From the review: the values bundle gains the basin's watershed code, each candidate year's run lengths,
      and a second fill with the day before the gap hidden; `same()` drops the read date; unaccepted snaps
      are printed; the map script refuses an uncommitted values bundle and records the tree's row count and
      an md5 of the basin's ordered segment ids.

## Phase 3: The article

- [x] `vignettes/articles/segment-temperature.Rmd`, headings as the reader's questions, each term defined
      where it first appears (reach, growing-season degree days, air2stream, open-loop, holdout, kriging):
  - the opening: what the product will be and that it is not built yet;
  - **What are growing-season degree days, and why do they matter for fish?** Figure 1, the picked station's
    year in two panels on one time axis: daily water temperature (observed, the gap, the fill with its
    interval, air temperature behind, the season's start and end) and degree days accumulating to the season's
    total;
  - **Where do we have temperature, and where not?** Figure 2, the basin map, with towns, the rivers named, a
    keymap and a scale bar, the exterior dimmed;
  - **How do we get from stations to every reach?** Figure 3, the chain from the two CSVs: observations, fills,
    catchment traits, air temperature, the baseline, a network model, degree days at every reach, with PCIC's
    process model beside it as a comparison and a source of future change;
  - **How will we know it works?** Figure 4, the holdout sketch: a station hidden, predicted from traits, from
    its nearest neighbours in trait space and from the network, each compared with the station's own fit;
  - **What is not known yet?** The error at the stations themselves, and the thresholds: growing-season
    degree-day thresholds exist for cutthroat trout (from Colorado subspecies, applied to westslope cutthroat
    in the Elk Valley reports), and none has been found yet for the other BC species; each claim read in its
    source before it is cited; a link to #214 for what is done and what is next;
  - a recipe chunk (`eval = FALSE`) of the calls behind Figure 1 for the whole pool (the fill borrows from the
    pool's other stations, so one station alone would not return it), which the data script runs as written
    from the committed `.Rmd` and refuses to bundle unless it returns the picked year's bundled values;
  - "Software and citation" (wet, cd, gsdd, fwapg and our fork's main-flow tree, SSN2, ggplot2, gq, sf, knitr,
    bookdown, R; the Nechako and Skeena network models by their memos; air2stream; the degree-day rule; ERA5-Land;
    PCIC's channel-scale output; the Freshwater Atlas; ECCC's records through water-temp-bc), references, and
    a `wordcount` chunk with a cap of 1,200 words, set before drafting.
- [x] `inst/vignette-data/temperature_chain_nodes.csv` and `temperature_chain_edges.csv`, with a test that every
      edge joins two nodes and every state is one of the registry's four; the budget entry gains both.
- [x] In order: the article with its recipe committed, the data script rerun from an emptied cache with the
      recipe guard, the bundle committed, the article built.
- [x] `stopifnot()` beside every number and every "each" or "every" the prose states; every caption names
      every mark its figure draws; alt text on each figure; no footnotes; no private repo named.
- [x] Add any missing reference to the Zotero group library, then
      `Rscript data-raw/vignette_bib.R vignettes/articles/segment-temperature.Rmd` and commit the `.bib`.
- [x] `_pkgdown.yml`: `articles/segment-temperature` in the Articles menu. `README.md`: one line in its
      articles list.

## Phase 4: Proof and records

- [x] Install the branch, `pkgdown::build_article("articles/segment-temperature")` twice; the four figure files'
      md5s and the page's text are the same both times.
- [x] Read each figure at 700 px wide against the cartography self-review (placement and "does it
      communicate"); fix what fails.
- [x] Break one bundled value and one caption-backed claim in a copy, rendered after `pkgload::load_all()` so
      the broken copy is the one read, and record each stop message.
- [x] A cold read of the built page's text by a reader with none of the repo's context, asked what goes to a
      network model and what comes back; every `<img>` has a non-empty `alt`.
- [x] Send the rendered page for a read on a phone before the pull request.
- [x] `CLAUDE.md` (above the marker): the article, its two data scripts, the basin table and the rule, in the
      Architecture section's form. No `NEWS.md` edit on the branch: this repo's release step writes the bullet
      at the merge (every NEWS change in its history is a release commit), so the PR body carries the line
      and `Bump: patch`.
- [x] `lintr` compared per file against `origin/main`; `pkgdown::check_pkgdown()`; `devtools::document()`.

## Owed at the end (reported, done after merge)

- [ ] Once `https://www.newgraphenvironment.com/wet/articles/segment-temperature.html` is served, replace the
      opening line of #214's body with the link, and confirm the deploy on `gh-pages` names the merge commit.

## Validation

- [x] Tests pass (`NOT_CRAN=true`, the whole suite)
- [ ] `/code-check branch` clean
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:

- **The rule:** the bundle carries the candidate table; a test re-derives the pick from it. The script run a
  second time leaves `temperature_values.rds` byte for byte.
- **The map:** `vm_write()` reports every layer identical on a rerun; the size measurements are in
  `findings.md`.
- **The article:** two builds with equal figure md5s and equal text; each guard shown to stop the build on a
  broken value; `grep -c 'footnote-ref'` is 0; the word count is under its cap.
- **Done when (the issue's):** four figures on the page; the phone read answers "what goes to a network model
  and what comes back"; #214's link is the owed item.
