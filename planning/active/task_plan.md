# Task: Segment discharge article: reorder for readers, define terms, recommend an estimate, map every named gauge (#39)

## Problem

`vignettes/segment-discharge.Rmd` (#28) is accurate, but it is ordered for the people who built it:

- It opens by proving that wet reproduces fwapg. That matters only to someone who already knows what fwapg is, and a sentence would carry it as well as the scatter plot does.
- Terms are never defined or linked: fwapg, PCIC, VIC-GL, HYDAT, the Freshwater Atlas, watershed group, stream order, sub-sub-drainage, held out, blocked cross-validation, nested.
- Runoff in mm/yr and discharge in m³/s appear side by side with nothing to connect them.
- Error is shown three ways: % over/under in the table, a log ratio relabelled as % in the skill plot, and four classes on the Bulkley map.
- The Salmon River comparison, which holds the main finding, is one dense paragraph. Four of the five gauges in its table lie outside the map's frame.
- It shows that the two estimates disagree, but never says which to use.

## Context

`vignettes/segment-discharge.Rmd` (#28) is a developer's validation report. It opens with fwapg parity, never defines its terms, mixes mm and m³/s, shows error three ways, puts four of five named gauges off the map, and never says which estimate to use. You asked for: a recommendation, one article (longer is fine), every term defined and linked, helpful figures, the fwapg match as a sentence rather than a figure, maps that tell the whole story, and every named station on a map.

### What exploration found (shapes the plan)

- **The recommendation can rest on evidence.** Local fwapg holds `fwa_stream_networks_discharge` for 150 watershed groups (2.7 M rows), which is PCIC's coverage. About 185 of the 290 calibration gauges lie in the Peace (07E/07F), Fraser (08J–08M) and Columbia (08N). Scoring fwapg there is the same `fwa_streams_watersheds_lut` → discharge join that `data-raw/segment_vignette_data.R:139-145` already runs for the five Salmon River gauges.
- **The data rebuild runs on m1.** The reduced `data/wb/` bundle is enough for `data-raw/segment_vignette_data.R` (memory note), `data/parity/` is present, and fwapg is up. The script refuses uncommitted `R/`, `scripts/` or `data-raw/`, so script edits are committed before each rebuild.
- **The bundle budget is 500 KB, with 427 KB used.** Dropping the 9,000-row parity frame (the figure goes) frees room for the gauge and coverage layers.
- Colours come from `inst/cartography/wet_segment.csv` (gq registry). The `gauge_error` PuOr 4-class scale (±20 % breaks) becomes the one error scale everywhere.

### Recommendation (decided at this gate, with a pre-set rule)

**Use wet's open water balance everywhere. fwapg/PCIC is a yardstick where it exists.** This follows the repo rule: publish our own open estimate, and score others' products against it and HYDAT.

The pre-set rule is written into `findings.md` before the scoring runs. At the calibration gauges inside PCIC's coverage, if the balance's held-out mean absolute error is more than 5 points worse than fwapg's, **I stop and bring it back to you** before writing the recommendation, because the evidence would then argue against the repo rule. The article states two things either way:
- the balance's error is out of sample;
- fwapg's may be partly in sample, since PCIC calibrates VIC-GL to gauges.

### Phase 1: Data for the new figures

- [x] Pre-set recommendation rule recorded in `findings.md` (commit before scoring)
- [x] `data-raw/segment_vignette_data.R`:
  - fwapg `mad_mm` at every calibration gauge with a fwapg value (`skill$fwapg_mm`, NA outside coverage), with one value per gauge asserted;
  - lon/lat on `gauges_salr`;
  - the 9,000-row `parity` frame replaced by its summary (segment count, all matched to fwapg's five decimals).
- [x] `data-raw/segment_vignette_map.R`:
  - PCIC coverage outline (union of the watershed groups fwapg gives discharge);
  - places for the widened Salmon River frame (Prince George, Fort St. James), since the frame grows to hold all five gauges.
- [ ] Commit the scripts, rerun both, commit `inst/vignette-data/`. Update `tests/testthat/test-vignette_data.R` for the new fields and stay under the 500 KB budget.
- [x] Registry rows for any new layer (coverage outline, gauge label) in `inst/cartography/wet_segment.csv`

### Phase 2: The article, reordered

- [ ] **What mean annual discharge is.**
  - A worked unit example: a 100 km² basin at 300 mm/yr carries about 0.95 m³/s.
  - A short "Terms" list, each with a link where one exists: Freshwater Atlas, stream segment and order, watershed group, fwapg, PCIC hydrologic model output and VIC-GL, HYDAT, the water balance after Chapman et al. 2018, BC Water Tools, calibration gauge, held out, headwater/nested gauge, hydrologic zone. Every URL is checked live before it goes in.
- [ ] **Which estimate to use.**
  - The recommendation, then the two products scored at the same in-coverage gauges.
  - One figure: each gauge's error under both products on the single % over/under scale.
  - A small table of mean absolute error and share within ±20 %, all gauges and split headwater/nested.
- [ ] **How close it is, province-wide.**
  - A map of BC with the 290 gauges filled by held-out error, PCIC coverage outlined, and the Salmon and Bulkley groups marked.
  - A strip or histogram of the errors with the ±20 % band.
  - The weak dry-interior zone, named in text, shown on the map.
  - The 25-row zone plot is replaced.
- [ ] **Salmon River: two estimates side by side.**
  - A two-panel map, fwapg | water balance, on the same discharge classes.
  - The frame holds all five gauges, each labelled with its station number and filled by that panel's product error.
  - The table lists the same five gauges.
- [ ] **Bulkley River: the water balance alone.**
  - The map with its seven gauges labelled.
  - A table of the seven: name, area, observed, modelled, error.
  - One worked example traced from segment value to gauge.
- [ ] **Limits, ordered by what affects a user:** coverage, dry zones, small streams, missing segments.
- [ ] **How it is built.**
  - The fwapg match in one sentence (no scatter plot).
  - The sampling change, with its figure kept small.
  - The recipe and cached inputs.
  - The stale-upstream-area note moves here.
- [ ] Keep a `stopifnot()` behind each prose claim. Add one that fails if a station named in the prose or a table is missing from a map. Raise the word cap from 800 to 1,600.

### Phase 3: Verify and record

- [ ] Build the article (`pkgdown::build_article("segment-discharge")`), then read every rendered map PNG against the cartography self-review: placement checks 1–7 and the "does it communicate" checks 8–12. Fix and re-render until each map passes.
- [ ] Links resolve (HTTP 200); no footnotes or `\@ref` (pkgdown drops them).
- [ ] `devtools::test()`, `lintr` on the touched files, `pkgdown::check_pkgdown()`
- [ ] `research/water_balance_method.md`: the PCIC-vs-balance score at the in-coverage gauges, replacing the five-gauge-only statement
- [ ] Issue #39 body reconciled; NEWS line under a dev heading

### Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion, then `/gh-pr-push`

### Critical files

`vignettes/segment-discharge.Rmd`, `data-raw/segment_vignette_data.R`, `data-raw/segment_vignette_map.R`, `inst/vignette-data/segment_{values,map}.rds`, `inst/cartography/wet_segment.csv`, `tests/testthat/test-vignette_data.R`, `research/water_balance_method.md`. Reused: `gq::gq_bbox_aspect()`, `gq::gq_scale_breaks()`, `gq::gq_tmap_classes()`, `station_map.rds$bc`, the `draw_map()` pattern in the current vignette.

Relates to #28


