# Plan review for #220 (spawned 2026-11-25 18:18 UTC, returned about 18:30 UTC)

Blockers raised: 1
Owner forks: 0

The review ran in the background beside Phase 1 and read the tree up to 36e72c6b. Each finding below was
probed before it was folded in or declined.

| # | Finding | Verdict |
|---|---|---|
| B1 | The recipe of "four calls" cannot return the bundled values: the bundled fill is the 25-station pool fit and the pick's `b` is 1.04, so one station alone fills differently; a recipe also needs the pool's stations, coordinates and `gsdd::gss()` | **Right** (bundle `fit$b` = 1.045). Folded: the recipe is the whole pool, with coordinates from `tidyhydat::allstations` (they differ from HYDAT's by under 5e-6°), and the guard compares the picked year |
| O1 | Phase 1 is ticked without the recipe guard; `vd_commit()` does not watch `vignettes/`; Phase 3 has no step to change the script, rerun and re-prove the bundle | Right. Folded: Phase 3 gains the sequence (article with its recipe committed, script rerun, bundle committed, article built) |
| O2 | The budget test breaks as each new bundle file lands; no checkbox makes the two chain CSVs | Right. Folded: the budget entry grows with each file; Phase 3 gains the CSVs' checkbox and test |
| O3 | The map script depends on the values bundle and should refuse an uncommitted one; test that both bundles hold the same stations and segments | Right. Folded |
| O4 | The cartography classes will move once the figures exist; each edit needs a reinstall | Noted; no change |
| G1 | A minimum-order cut could leave the picked station (order 3) on no drawn stream | Moot: every order is drawn (351 KB at 200 m) |
| G2 | "The basin's reach count": the plan's 57,371 is `fwa_stream_networks_sp` in BULK and MORR; the tree under the Bulkley's code is 52,293 | Right. The bundle already counts the tree (52,293, the fork's own figure for the Bulkley); the plan's Context is corrected |
| G3 | The database records no build for the tree; the local table lacks `upstream_area_ha`, so it is an earlier build than the one the network check ran on | Right (four columns, no comment; 4,510,368 rows, the 2026-10 build's count). Folded: provenance carries the row count and an md5 of the basin's ordered ids, and the script's header says the area step was not run on this copy |
| G4 | `s_open_c` is bundled but the plan draws no open-loop line | Folded: Figure 1 draws it; the registry already has the class |
| G5 | `gsdd` sums any number of seasons; the article says "the season" | Folded: the article stops unless the year has one season |
| G6 | An unaccepted snap off the main stem is dropped silently | Folded: the script prints every unaccepted pool snap |
| G7 | The basin polygon has no reference area to be held to | Declined: its source is its definition (the watershed polygons under the main stem's code, one part, no holes, 12,141 km²), and no independent area for the whole Bulkley is in hand |
| G8 | "Two panels on one time axis" names no mechanism; no `patchwork` in `DESCRIPTION` | Folded: facets, `ggplot2` only |
| A1 | The out-of-water day is larger than the plan treats it: the fill sums 75.7 °C-days above open-loop across the gap, six times the 30-day holdout's 12.8 | **Right** (reproduced from the bundle). Folded: the bundle carries a second fill with the day before the gap hidden, as a comparison and not the pick; the caption states the difference; the article does not present the 30-day holdout error as this fill's |
| A2 | The rule has one candidate and its widening adds none | Known; stands |
| A3 | Eleven stations, not eight | As Phase 1 found |
| A4 | `gsdd` is unpinned (0.3.0.9009 here; the validation ran on 0.3.0.9007) | Noted: the bundle records the version |
| A5 | `vm_places()` could drop Hazelton | Checked: all three towns returned, each once, and the script stops otherwise |
| A6 | "Lowest order under 500 KB" is a size rule, not a legibility rule | Folded into Phase 4's figure review, which may raise the order drawn |
| A7 | No existing `.bib` holds the new references; `vignette_bib.R` stops on an entry with no url or doi | Known; Phase 3's Zotero step |
| S1 | Three of the eleven stations began in January 2025; the count is fixed by the script's 2002–2025 range | Folded: the prose says so and drops "dated by the archive read" |
| S2 | Which validation line the article closes on is not named | Folded: open-loop's whole-season degree-day error (128.7), named as air2stream on air temperature alone |
| S3 | The test hard-codes 08EE003 as the main-stem station | Folded: the bundle carries the basin's watershed code |
| C1 | The byte-for-byte rerun read the cache, and `same()` keeps `retrieved`, so a fresh read on another day rewrites the file | Right. Folded: `same()` drops `retrieved`; the proof is a rerun from an emptied cache |
| C2 | The pick test repeats the script's expression on the script's columns | Folded: the candidate table carries each year's run lengths and which touch the window's ends, and the test recomputes the gap from them |
| C3 | A word cap set from the first draft cannot fail | Folded: 1,200 words, set before drafting |
| C4 | The phone read is by the owner, who has the context | Folded: a cold read of the rendered text by a reader with none of the repo's context, asked the issue's question |
| C5 | Breaking a value in a copy tests nothing unless the article reads the broken copy | Folded: the broken copy is rendered after `pkgload::load_all()`, whose `system.file()` reads the source tree, and the stop message is recorded |
| C6 | Alt text has no check | Folded: every `<img>` of the built page is checked for a non-empty `alt` |
| C7 | "Every station point lies in the basin" tests coordinates against a simplified polygon | Folded: the map script holds each station's segment to the tree at build; the test holds the two bundles to one another |
| P1 | A phrase naming the build machine as the session's own, in the plan | Folded: reworded |
| P2–P4 | Repos named are public; provenance holds no host or path; confirm the Elk Valley reports have a public URL | Noted for Phase 3 |

## Files the plan names

data-raw/temperature_vignette_data.R
data-raw/temperature_vignette_map.R
scripts/temperature_basins.csv
scripts/vignette_map_lib.R
inst/cartography/wet_temperature.csv
inst/vignette-data/temperature_values.rds
inst/vignette-data/temperature_map.rds
inst/vignette-data/temperature_chain_nodes.csv
inst/vignette-data/temperature_chain_edges.csv
tests/testthat/test-vignette_data.R
vignettes/articles/segment-temperature.Rmd
vignettes/articles/segment-temperature.bib
_pkgdown.yml
README.md
NEWS.md
CLAUDE.md
