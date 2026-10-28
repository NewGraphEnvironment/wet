# Task: Article: flow change at an ungauged stream, the Maxan Creek Chinook windows (#130)

## Context

Maxan Creek (08EE018) was gauged for only five Chinook migration windows (1975–1979). The Maxan pilot (#120) extended its record across 1931–2024 from neighbouring gauges and carried donors' departures onto it, and #121 regressed the window flows on each year's snow. Both are written up only in `research/` and two tracked reports, so no outside reader sees them. This article puts the answer in front of a reader:
- how much Chinook-window flow at Maxan has changed;
- how sure we are;
- how much of the change follows snowpack and melt timing.

It sits beside `vignettes/station-flow.Rmd`, which covers gauged departures at Buck Creek and the Bulkley near Houston.

## Decided at the gate (2026-10-27, airvine)

- **Donors for the second estimate:** keep #120's nearest Bulkley donors (08EE013, 08EE003, 08EE008, 08EE020, 08JA016). The headline is Maxan's extended record (ordinary least squares on the nearest covering donor), and no donor choice changes it.
- **One sentence on #122:** province-wide, donors picked by PCIC's modelled covariance carry departures better (median held-out NSE 0.72 against 0.67). At Maxan those donors include four plateau gauges 100–230 km east, and their series starts in 1973, so the article keeps the nearest donors. *Dropped after the plan review (G1): its numbers are in no file the data script reads, and `writing.md` cuts how a decision was reached.*
- **After the plan review (2026-10-27, `review-plan.md`):** renamed from "ungauged" to "short-record" (Maxan has five years, and the extension needs them): `vignettes/short-record-flow.Rmd`, `data-raw/short_record_vignette_*.R`, `inst/vignette-data/short_record_*.rds`, registry keys `short_record_map` and `short_record_series`. The change table keeps three rows (the migration 7-day minimum's two routes disagree in sign); scores are per window statistic; the limits name the Bulkley at Quick.

## Exploration that shaped the plan

- **The pilot's series.** `data/departure/departure_pilot_20260717.rds` (gitignored, stamped `code_md5`) holds `mx[["q_mean migration"]]` and the other statistics:
  - `e`: the extended series, 1931–2024, with value, 90 % interval, donor and source;
  - `a`: the carried departures and their donors;
  - `diff`/`ci`: the change from before 1981 to 2011–2025;
  - the observed-year and record scores.
- **The snow script saves no series.** `scripts/departure_snow.R` writes only `data/checks/departure_snow_20260717.txt`, whose per-year snow table is rounded to whole millimetres and days. The pilot already saves its series after its report (the #121 pattern), so the snow script will do the same.
- **The covariance-picked donors at Maxan** (from #122's rds): 08EE013, 08JE004, 07EE009, 08KC003 and 08JC017, covering 1973–2025.
- **The model to follow is `vignettes/station-flow.Rmd`:**
  - data from `inst/vignette-data/`, colours from `inst/cartography/wet_station.csv` through gq;
  - a `stopifnot()` behind every number the prose quotes;
  - a 600-word cap on body prose;
  - a closing "Software and citation" section from `wet:::wet_software_cite()`.
- **Map layers** come from `scripts/vignette_map_lib.R` (`vm_stations()`, `vm_catchments()`, `vm_streams()`, `vm_lakes()`, `vm_places()`, `vm_bc()`, `vm_layers()`).
- **Repo guards** come from `scripts/vignette_data_lib.R` (`vd_git()`, `vd_commit()`, `vd_connect()`).

## Phase 1: the snow regression saves its series

- [x] `scripts/departure_snow.R`: after the report, save `data/departure/departure_snow_20260717.rds` (gitignored), as the pilot does. It holds:
  - each watershed's per-year `swe_max`, `snowmelt_doy_50` and `snowmelt_rate_peak`, 1950–2025;
  - the eight response series and the 24 fits;
  - `release` and `code_md5` (`tools::md5sum` of the script). The before/after table is recomputed in Phase 2 and the cd SHA parsed from the report.
  
  The header and `CLAUDE.md` name the file.
- [x] Rerun it from a frozen copy. The tracked report must regenerate byte-identical; a diff stops the phase. Log to `data/logs/130/`.

## Phase 2: the article's data bundle

- [x] `data-raw/short_record_vignette_data.R` → `inst/vignette-data/short_record_values.rds` (first named `ungauged_*`). It reads the two rds files and refuses:
  - when a file's `code_md5` is not the md5 of its script at HEAD;
  - when `R/`, `scripts/`, `data-raw/` or `data/checks/` hold uncommitted changes (`vd_git()`).

  It bundles:
  - Maxan's extended migration- and spawning-window means, 1931–2024: value, 90 % interval, donor, observed or extended;
  - the before-1981 against 2011–2025 changes (window mean and 7-day minimum, both windows): change, % of normal, 90 % interval, years in each period, and the carried change;
  - the held-out scores the prose quotes: the extension's median NSE and interval coverage, the carried departures' pool median and Maxan's own score;
  - the carried series;
  - per-year snow and log flow departures at the three gauges (08EE003, 08EE013, 08EE018), and the before/after snow table;
  - donor names from HYDAT;
  - provenance: commit, build date, HYDAT release and cd's layer SHA.

  Each bundled number is asserted equal, at its printed precision, to its line in the tracked pilot or snow report.

## Phase 3: map layers and colours

- [x] `data-raw/short_record_vignette_map.R` → `inst/vignette-data/short_record_map.rds`, through `vignette_map_lib.R`:
  - Maxan, Buck and Houston with their catchments, and the donor gauges as points;
  - the Bulkley River and Maxan Creek by `blue_line_key`;
  - lakes, Bulkley Lake among them;
  - Houston as the place name;
  - the BC outline for the keymap.
- [x] `inst/cartography/wet_station.csv` gains the classes the article draws: the map's subject gauge, donor gauges and catchments, and the series' observed, extended, interval and carried lines. The values come from gq and the existing palettes, with no hex literal in the vignette.

## Phase 4: the article

- [x] `vignettes/short-record-flow.Rmd`, titled "Chinook Flow at a Short-Record Stream". Headings follow the reader's questions:
  1. An opening that gives the answer with its numbers.
  2. **Where Maxan Creek is:** a map of Maxan, Buck and Houston, their catchments and the donor gauges.
  3. **How flow has changed:** the extended series in both windows, with its 90 % band, the observed years marked, and a table of the four changes and their intervals.
  4. **How we know:** record extension and carried departures, a sentence each with its held-out score; the carried change beside the extended one; the sentence on covariance-picked donors.
  5. **Snow and melt:** each year's window-flow departure against peak snow and melt date at the three gauges, and the snow change between the two periods.
  6. **What it does not show:**
     - each extended year rests on one donor, through a relation fitted on five years;
     - the Bulkley at Houston contains Maxan;
     - ERA5-Land's cells are coarse.
  7. **Software and citation.**

  It follows #110's convention: software in code font and linked, no issue numbers or dated words in the prose, and a 600-word cap enforced in a chunk. Every quoted number has its `stopifnot()`.
- [x] Link it from the README's "Learn more" list (plain language), and point to it from `research/station_flow_departure.md`'s Maxan section.

## Phase 5: check and PR

- [x] `tests/testthat/test-vignette_data.R`: the new bundles in the size budget, and a shape test for each (plan review B1).
- [x] `CLAUDE.md` names the article and its scripts beside the other three, and the headers of `scripts/vignette_map_lib.R` and `scripts/vignette_data_lib.R` name the new scripts (plan review G6).
- [ ] Install the branch, then `pkgdown::build_article("short-record-flow")`. Read the rendered figures at their delivered width against the cartography self-review, and check that the word cap passes.
- [ ] `pkgdown::check_pkgdown()`; `devtools::test()`.
- [ ] `/code-check branch`; `/planning-archive`; `/gh-pr-push`.

## Owed at the end (reported, done after merge)

- [ ] Tick #130 in #118's component list.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:
- **Phase 1:** `departure_snow_20260717.txt` regenerates byte-identical, and the rds's per-year snow rounds to the report's table.
- **Phase 2:** rerunning the data script reproduces the values bundle `identical()`. A series file stamped with another md5 makes the data script refuse; so do a dirty `scripts/` and one report number moved in a copy of the report.
- **Phase 3:** the map layers are rebuilt, and the catchments' areas are held to HYDAT within 10 % (the `vm_catchments()` check).
- **Phase 4:** the article renders after install, every `stopifnot()` holds, the cap passes, and the rendered PNGs are read before the PR.
