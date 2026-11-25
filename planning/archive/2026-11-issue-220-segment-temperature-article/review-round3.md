# Code-check round 3, branch `220-article-stream-temperature-for-every-rea` at b3dde4f8

Reviewed 2026-11-25 (UTC), read-only in the checkout; the render, the tests and every probe ran in a detached
worktree under the session scratchpad (removed) or read the committed bundles and the local fwapg with `SELECT`s.
The two data-raw scripts were read, not run.

## Checklist read

- `code-check.md`: the prose of all 14 H3s under `## Mechanisms` (table rows skipped); of the 24 other headings,
  "Documentation Staleness" and "An assertion that matches an interpolated value cannot see the claim around it";
  22 not read (no infra, credential, YAML, URL, spreadsheet or PDF shape in this diff).
- `code-check-r.md`: 11 of 132 headings read in full: "Moving prose into a code chunk hides it from tools that scan
  the document", "A `data-raw/` script must load the source tree, not the installed package", "Regenerated binaries
  churn git even when nothing changed", "`nzchar(NA)` is TRUE", "ggplot2 legends and labels", "Under `R CMD check`,
  tests run from a temp dir against the INSTALLED package", "knitr and pandoc rewrite a caption", "`tolerance` in
  testthat is RELATIVE", "A duplicate knitr chunk label fails the build", "`paste()` with a zero-length argument
  returns length ONE", "Postgres row order is never fixed unless the query fixes it"; 121 not read (checked against
  the diff from their index line only).
- `code-check-spatial.md`: 10 of 98 read in full: "sf: `st_intersection()` / `st_difference()` return a
  GEOMETRYCOLLECTION", "FWA main flow is not edge type 1000 alone", "FWA lookup area follows watershed codes",
  "A relation between FWA watershed codes is not a place", "A name is not a key", "`atan2(0, 0)` is 0",
  "`sf::st_make_valid()` rewrites geometry that was already valid", "A Freshwater Atlas main stem's downstream end
  lies on the receiving river's centreline", "`geom_sf(data = NULL)` draws nothing, silently", "A coordinate stored
  as an attribute can disagree with the geometry it describes"; 88 not read.
- `code-check-shell.md`: 0 of 75 read; the diff holds no shell.

## What was run

- Article rendered from a worktree copy (`rmarkdown::render`, exit clean, word cap passed); the four PNGs read.
- `tests/testthat/test-vignette_data.R` under `NOT_CRAN=true`: 18 blocks, 0 failed, 0 errors, 0 skipped
  (the six temperature blocks: 18, 9, 12, 10, 39, 10 expectations).
- Both bundles read with `readRDS()`; every number the article prints was recomputed from them.
- Issues #220, #213, #223, #219, #214 (edited 20:50 UTC today), #222, #224 read at their current text.
- Local fwapg, read-only: the Bulkley's segments under `400.431358` by edge type, in and out of the main-flow tree.

## Mechanism

Both candidates are real, and they are one mechanism seen from two sides.

**The article's numbers have a producer; its sentences do not.** Every value that comes out of a bundle is held by a
`stopifnot()` or a test (rows marked "bundle" below: none is wrong). Everything else the page prints is a hand-typed
restatement of a fact whose source of truth lives somewhere the build never reads:

1. an issue body that is still being edited (#213 and #223 at 18:47 UTC, #214 at 20:50 UTC today);
2. a constant in a `data-raw/` script that the bundle does not record (500 ha, order 7, 200 m);
3. a dependency's default (`gsdd`'s 5 °C, 4 °C, 7 days);
4. a data file the article draws but also describes in words (the chain CSVs against `alt_chain` and the
   "everything above it" sentence; the registry's hex against the captions' colour words);
5. a set named by its everyday label ("reach", "station", "neighbours", "usually") where the code or the issue
   defines a narrower or wider one.

Each such fact is typed in up to nine places (prose, caption, alt text, registry label, chain box, README,
CLAUDE.md, script header, code or test comment) and nothing enumerates the copies, so a correction reaches the
copies the fixer remembers. That is candidate (a). Candidate (b) is what the same absence looks like for a single
copy: with no producer to read the set from, the sentence takes the label. In `code-check.md`'s terms this is
"One fact derived twice" (its last-but-two paragraph: partition every literal into a contract this repo chose and a
fact about another artifact, and "a curated list misses the ones inside strings that get printed — titles, captions,
alt text") terminated the way "A guard's scope, escape hatches, and remedies" asks ("enumerating every claim a diff
makes about behaviour elsewhere and executing each"). The earlier findings about claims all fit: the version line
(one chunk copied into three articles), "no measurement at all", the lake caption's guard, CLAUDE.md's "no status
and no scores", the reach count, kriging as a baseline version, the unheld `edge` values, the README line. The three
that were plain code or drawing defects (`nzchar()` on a value that can be NA, the zero-season stop, the town square
under a station point) do not, and nothing of their kind turned up this round.

What would close it rather than find more of it: (i) record in the map bundle the constants the caption quotes
(`min_ha`, the context streams' minimum order) and assert `identical()` on them; (ii) hold `alt_chain` and the
"what goes to it" sentence to the edges CSV with three `setequal()`s on the arrows into `fills`, `baseline` and
`model`; (iii) for the sentences that restate #213, #223 and #219, there is no mechanical anchor, so the table below
is the control: re-walk it whenever one of those bodies is edited, since the page says it "is revised when #213,
#223 and #219 have run".

## Enumeration

Status: **ok** (holds, and no copy disagrees), **weak** (true today, but resting on nothing the build reads, or one
copy words it differently), **WRONG** (reported under Findings). "bundle" means a value of the committed `.rds`
recomputed this round.

### Article body (67 rows)

| # | Claim | Rests on | Other copies | Status |
|---|---|---|---|---|
| A1 | `wet` does not yet publish temperature for every stream reach | the package; #214 | CLAUDE.md "opens by saying … not built"; README "not all built yet": agree | ok |
| A2 | target: growing-season degree days for every reach in BC | #214 opening | chain boxes "at every reach" agree; the model's network is the trimmed tree (A27) | ok |
| A3 | a reach is "a stretch of stream, usually between two confluences" | nothing; never measured | #214 and A21 define a reach as one `linear_feature_id` | **WRONG** (F2) |
| A4 | "can be computed at a few hundred stations" | `stopifnot(truth_stations` in 200–499`)`; bundle 257, from the tracked report's line | #213 "257 stations", #214 "306 … stations" agree; code comment at Rmd:122 still quotes "gauges" | ok (comment: weak) |
| A5 | getting to every reach takes a model of the whole network, not built yet | #214 | chain colours agree | ok |
| A6 | the roadmap says what is done and what is next | #214's sections | — | ok |
| A7 | a fish grows faster in warmer water, up to a point | general statement, uncited | — | ok |
| A8 | summed "from the first week that averages above 5 °C to the first week that falls below 4 °C" | `gsdd::gsdd()` defaults (5, 4, 7 days: read from the installed 0.3.0.9009, the bundle's version); no guard | `wet_temp_gsdd()` passes no thresholds | weak |
| A9 | 10 °C for 100 days gives 1,000 | arithmetic | — | ok |
| A10 | low totals: summer-hatched fish too small to survive winter | Coleman and Fausch 2007 (title matches; PDF not opened) | A52 | ok |
| A11 | Simpson Creek at its mouth, about 4 km north-west of Smithers | bundle (3.9 km, bearing computed); `stopifnot(town_near, town_km <= 10)`; station name "SIMPSON CREEK AT THE MOUTH" | caption C1 agrees | ok |
| A12 | joins Kathlyn Creek on the way to the Bulkley River | `pick$into1/into2`, `stopifnot` on both | — | ok |
| A13 | recorded every day March–November 2020 except 29 days from 25 August | bundle; `stopifnot(identical(filled[in_win], in_gap[in_win]))`; test | C3; CLAUDE.md "otherwise observed": agree | ok |
| A14 | a season with a missing day has no total | bundle `gsdd$unfilled` NA; `stopifnot`; test | — | ok |
| A15 | fill: air2stream corrected by the station's readings either side and by "nearby stations" | `R/wet_temp_fill.R`; "nearby" is the WSC sub-drainage pool (25 stations of 08E) | A55 says "sub-drainage" | ok |
| A16 | air alone, no readings: "open-loop" | `scripts/temp_fill_validate.R` method names | C5, registry R4 agree | ok |
| A17 | a reach with no station has to start open-loop | #213 Problem | — | ok |
| A18 | the fill restarts from every reading, so a bad one is carried | #222 | — | ok |
| A19 | last reading before the gap about 6 °C above the day before, air barely moved | bundle (5.98; air 9.75 → 9.78); `stopifnot`; test | C8 "15.5 °C after 9.6 °C" agrees | ok |
| A20 | hiding it lowers the total from 1,460 to 1,393 | bundle (1,460.38, 1,393.35); test sums the second fill over the season | A51 "67", CLAUDE.md "67 °C-days": agree (67.03) | ok |
| A21 | a reach here is one Freshwater Atlas segment with its own identifier | #214 | A3 disagrees in emphasis | ok |
| A22 | the Bulkley runs north-west from Houston past Smithers to the Skeena at Hazelton | direction computed; three `stopifnot`s | caption C14 | ok |
| A23 | the stream network of its basin has 52,293 reaches | bundle; `stopifnot`; test; fwapg probe: 52,293 of the 54,589 segments under the code are in the tree | caption C9, README, CLAUDE.md, map-script header, registry R7: agree | ok |
| A24 | eleven hold a federal hydrometric station that recorded water temperature by 2025 | bundle; `stopifnot(net$with_station == n_st)`; (`all(days > 0)` is true by construction) | C10, T4, CLAUDE.md, README agree | ok |
| A25 | three of those began too recently to model | bundle (08ED004, 08EE008, 08EE025, all first in 2025, 340–348 days against `min_days = 365`); `stopifnot` | — | ok |
| A26 | loggers run by others are not in `wet` yet | #215 | registry R9 "Federal station" agrees | ok |
| A27 | network: Freshwater Atlas by `fwapg`, "side channels trimmed so that water never splits" | `vm_tree()`; #214; probe: of 2,296 dropped segments 1,182 are side-channel types, 1,110 type-1450 connectors, 4 other | chain box N6 "with no splits" agrees | ok |
| A28 | the diagram's colours say which parts exist | chain CSV + registry | C15 | ok |
| A29 | traits: elevation, snow, lakes and glaciers | #213 traits | — | ok |
| A30 | like traits should warm alike | premise of #213 | — | ok |
| A31 | air2stream has three settings, fitted at each station | `fit$a1..a3`; fitted where a station has 365 days | C17 "settings" | ok |
| A32 | the baseline predicts them from traits, two ways | #213 candidates 2 and 3; #214 item 2 | C21, A41, CLAUDE.md agree; #213's rule can also report the population mean as the baseline | weak |
| A33 | a network model fits every station at once; temperature and degree days with uncertainty | #214 "What we are hoping for" | N10, N11 | ok |
| A34 | two fitted in northern BC, Nechako and Skeena | bib titles; #214 | — | ok |
| A35 | which method carries it is left open | #214 "The method is open" | — | ok |
| A36 | "what goes to it is everything above it in the diagram": network, stations and fills, traits, air at every reach, the baseline's score | edges into `model`; #214 "What we can bring" | `air_reach` sits beside the model, not above | weak |
| A37 | a process model simulates water and heat from the weather | #219 | N8 | ok |
| A38 | PCIC's gives daily water temperature at points on its network, past weather and climate models to 2100 | #219, #214 | N8 "at its outlets to 2100" agrees | ok |
| A39 | scored at the stations beside the baseline; one way to ask where streams are becoming warm enough | #219, #214 | E10 "scored beside it", E11 "future change" agree | ok |
| A40 | a holdout takes a station's whole record away | #213 | CLAUDE.md "whole-station holdout" | ok |
| A41 | three predictions, on stations drawn from the 257: the baseline's two and one from the network | #213 (257; stations under 95 % in BC dropped), #223 | C17, C21, CLAUDE.md agree | ok |
| A42 | a network model would be scored on the same hidden stations | #214 | — | ok |
| A43 | kriging: weighting the near ones most | definition | — | ok |
| A44 | on a network, near is along the water and in the direction it flows | #223 "tail-down covariance" | — | ok |
| A45 | each prediction run through air2stream on the hidden station's own air | #213 Run | — | ok |
| A46 | two marks: the station's own fit, and the average of all stations | #213 benchmark and candidate 1 | — | ok |
| A47 | each scored twice, with and without the neighbours up and down its stream | #213 Pools ("every candidate is scored in both") | — | ok |
| A48 | the network's gain over the baseline is what the network adds beyond traits | #223, #214 | presumes the network prediction contains the traits; C20 and the third panel say it does not | ok here; see F1 |
| A49 | season hidden, air alone: about 129 degree days on average (897 seasons, one at a time) | bundle, parsed from the tracked report's `season open` row (n 897, 128.74); `stopifnot` ranges | #213, #214 "129": agree | ok |
| A50 | a reach with no station can only do worse | #213 | — | ok |
| A51 | "Readings that are not water … one like the first figure's", moved its year by 67 | bundle; `stopifnot(50 < edge_cost < 100)`; #222 | caption C8 says "most likely"; CLAUDE.md says "is a sensor out of the water" | weak |
| A52 | cutthroat, high-elevation Colorado: 900–1,200 best, under 800 unsuitable | Coleman and Fausch 2007; #214 same numbers | — | ok |
| A53 | Elk Valley reports apply them | bib titles (Harmer Creek) | — | ok |
| A54 | none found yet for other BC species | #214 | — | ok |
| A55 | the fill borrows from its sub-drainage, so the recipe reads them all | recipe; `pool = substr(, 1, 3)` | A15 | ok |
| A56 | recipe comment: "most record no water temperature" | measured: 74 gauges start `08E`, 25 in the archive | data-script comment agrees | ok |
| A57 | the recipe returns the picked year | the data script evaluates the committed chunk and stops otherwise; `recipe-check` | CLAUDE.md agrees | ok |
| A58 | read 25 November 2026, 2002-01-01 to 2025-12-31, HYDAT 2026-07-17, commit 8d5da4a1 | bundle provenance | accepted (6) | ok |
| A59 | `wet`, `cd`, `gsdd`, `tidyhydat` roles | code (`wet_temp_daily()` reads time zones from `tidyhydat`) | — | ok |
| A60 | `fwapg`, the fork, "Kriging on the network will use `SSN2`" | #223 | round-2 fix reached it | ok |
| A61 | `ggplot2`, `ggrepel`, `gq`, `sf`, `knitr`, `bookdown` | the article's code | — | ok |
| A62 | "This build ran on `wet` 0.4.44, `cd` 0.6.13 (commit c8bc100) and `gq` 0.25.0 (commit 298b016)" | rendered; round-1 fix | same chunk in two other articles: same fix in both | ok |
| A63 | data: ECCC stations as archived by water-temp-bc | script `root` | — | ok |
| A64 | data: ERA5-Land | `cd` | — | ok |
| A65 | data: PCIC named, not yet read | no PCIC read in either script | CLAUDE.md "no … PCIC scores" | ok |
| A66 | data: Freshwater Atlas and BC Geographic Names | `vm_*()` | — | ok |
| A67 | heading "Where do we have temperature, and where not?" | #220 verbatim; "we" is `wet` (A26) | README no longer says "where it is not" | ok |

### Captions (21 rows)

| # | Claim | Rests on | Status |
|---|---|---|---|
| C1 | Simpson Creek at its mouth in 2020 | `stopifnot` on stream, station, year | ok |
| C2 | black, orange, pale band, blue | registry hex, checked by eye on the render; `classes()` asserts names, not colours | ok |
| C3 | 29 days filled, 25 August to 22 September | bundle; tests | ok |
| C4 | the fill's 95% interval | typed; `stopifnot(formals(wet_temp_fill)$level == 0.95)` | ok |
| C5 | air alone through air2stream, the open-loop line | `s_open_c`; the script holds its RMSE to the fit's | ok |
| C6 | growing season 28 April to 22 October, to 1,460 | bundle; tests | ok |
| C7 | the stretch that rests on filled days is orange | `dd_fill` | ok |
| C8 | 15.5 °C after 9.6 °C, "most likely a sensor leaving the water" | bundle; #222 | ok (certainty: A51) |
| C9 | all 52,293 reaches of its stream network, heavier on larger streams | `stopifnot(all(net$orders$drawn))` | ok |
| C10 | the 11 federal stations (orange; Simpson Creek's black) | bundle; 10 orange and 1 black counted on the render | ok |
| C11 | Bulkley, Morice and Telkwa drawn heavy and named | `stopifnot(setequal())` | ok |
| C12 | "Lakes of 500 ha and up are pale blue" | `lake_min <- 500` typed in the Rmd; `stopifnot(min(area_ha) >= lake_min)` | **WRONG** guard (F3); the claim is true today |
| C13 | land outside the basin dimmed, "its larger rivers thin", the Skeena named | script constant `min_order = 7`, unrecorded; 13.2 km of the Suskwa and 0.2 km of the Thautil lie inside the basin under the same thin line | weak |
| C14 | three towns labelled, bar 30 km, inset | `stopifnot`; `gq_scale_breaks()` | ok |
| C15 | chain colours and what each state means; dashed because a comparison | registry; `stopifnot` on dashed = comparison; test | ok |
| C16 | a sketch on a made-up network (pale lines) | `toy` | ok |
| C17 | one hidden (orange), three ways, blue used, grey left out | `use`; `stopifnot` | ok |
| C18 | traits: "a relation fitted to every other station" | #213 candidate 2; under blocked CV the fit leaves out the hidden station's whole fold | weak |
| C19 | the few stations most like it, wherever they are | #213 candidate 3 | ok |
| C20 | network: "its neighbours up and down the same stream", three stations grey | #223 | **WRONG** (F1) |
| C21 | the first two are the baseline | #213, #223 | ok |

### Alt text (6 rows)

| # | Claim | Rests on | Status |
|---|---|---|---|
| T1 | "rising from near zero in winter to a summer peak" | typed; measured days in January and February are 1.9–2.9 °C (the open-loop line is the one at 0) | weak |
| T2 | "a gap in late August and September" | typed; true of 25 August–22 September, not tied to `pick$gap_start` | weak |
| T3 | second line for air alone; climbing to 1,460 | bundle | ok |
| T4 | Bulkley basin in north-west BC, 11 orange and black points on its rivers and creeks | bundle; keymap | ok |
| T5 | chain: readings and air feed gap filling; fills and traits feed a baseline; baseline, network and air at every reach feed a network model | the edges CSV (matches all three groups at HEAD); no `stopifnot` ties the sentence to the file | weak |
| T6 | three copies, seven stations, the used stations differ | `toy`, `use`; `stopifnot` | ok |

### Registry labels, `inst/cartography/wet_temperature.csv` (18 rows)

| # | Label | Status |
|---|---|---|
| R1–R5 | Measured day; Filled day; Range the filled day most likely lies in; Air temperature alone (air2stream); Growing season | ok (5) |
| R6 | Bulkley River basin (typed; drawn in no legend; the basin is a row of `scripts/temperature_basins.csv`) | weak |
| R7–R9 | Stream reach; Named river; Federal station with water temperature | ok (3) |
| R10 | Simpson Creek station (typed; `stopifnot(identical(pick$stream, "Simpson Creek"))`) | ok |
| R11–R14 | In place; Being built; From a network model; An existing process model (match C15; test holds the state set) | ok (4) |
| R15–R16 | Station hidden; Station the prediction draws on | ok (2) |
| R17 | Station not used (wrong of the third panel: F1) | **WRONG** (F1) |
| R18 | Stream | ok |

### Chain boxes (11 rows) and arrows (11 rows)

| # | Box or arrow | Rests on | Status |
|---|---|---|---|
| N1–N4 | Station readings; Air temperature at the stations; Gaps filled; Degree days at the stations: in place | #214 "In place"; `cd` | ok (4) |
| N5 | Catchment traits of every station and reach: being built | #213 (stations); #214 "per station and per segment" | ok |
| N6 | Stream network with no splits: in place | #214 "In place" | ok |
| N7 | Baseline, a station's model predicted where there is no station: being built | #213 | ok |
| N8 | PCIC's process model, daily water temperature at its outlets to 2100: comparison | #219 | ok |
| N9 | Air temperature at every reach: being built | #214 item 4 (#216) | ok |
| N10 | Network model, "weekly temperature" at every reach | #214 hopes for "week by week" and also says "the time step [is] open"; #213 "weekly or daily" | weak |
| N11 | Degree days at every reach with their uncertainty | #214 | ok |
| E1–E5 | readings→fills; air→fills; fills→degree days; fills→baseline "the fitted models"; traits→baseline | #213 | ok (5) |
| E6 | baseline→model "all of the above and the score to beat" | #214 | ok |
| E7 | network→model (round 2's fix) | #223, #214 | ok |
| E8–E9 | air at every reach→model; model→degree days at every reach | `stopifnot` on the chain's ends | ok (2) |
| E10–E11 | PCIC→baseline "scored beside it"; PCIC→degree days "future change", both dashed | #219; `stopifnot` | ok (2) |

### Panel titles and axis text (2 rows)

| # | Text | Status |
|---|---|---|
| W1 | "From catchment traits", "From the stations most like it", "From the stream network" | ok |
| W2 | "Water temperature (°C)", "Degree days so far", "1,460 degree days" | ok |

### README and `_pkgdown.yml` (2 rows)

| # | Claim | Status |
|---|---|---|
| M1 | README: what degree days are, "how few stream reaches of one river basin hold a federal station recording water temperature", steps not all built | ok (round 2's fix; agrees with A24) |
| M2 | `_pkgdown.yml` lists `articles/segment-temperature` | ok |

### CLAUDE.md paragraph (14 rows)

| # | Claim | Rests on | Status |
|---|---|---|---|
| D1 | title, listed in the Articles menu, twin of `segment-discharge` | `_pkgdown.yml`; #220 | ok |
| D2 | opens by saying the product is not built; four figures | article | ok |
| D3 | the Bulkley's network with its eleven temperature stations | bundle | ok |
| D4 | the sketch: the baseline's two trait predictions (#213) and kriging beside them (#223) | #213, #223 | ok |
| D5 | no checklist, no baseline or PCIC scores; revised when #213, #223, #219 have run | article | ok |
| D6 | the header holds the two rules "written before the pick was computed" | the header, which adds that the rule followed a probe | ok (accepted 1) |
| D7 | "another basin is a data edit" | true of the two scripts; the article types the towns, the three rivers, "Simpson Creek", `08EE012` and 2020, and the registry types R6 and R10, each behind a `stopifnot()` that stops the build | weak |
| D8 | 08EE012, 2020, "the only one of the Bulkley's eleven stations' years that qualifies" | bundle: 1 of 68 candidate rows qualifies | ok |
| D9 | fills the 08E pool; season from `gsdd::gss()`; runs the recipe; second fill adds 67 °C-days | script; bundle | ok (certainty: A51) |
| D10 | keeps the committed file to `all.equal()`'s tolerance (#224) | script `same()` | ok |
| D11 | `vm_tree()` draws every order "(52,293 segments, 393 KB at 200 m)" | 393 KB is the whole map bundle (393.05 KB measured); the map script's header gives the same segments as 351 KB, the tree layer alone | weak |
| D12 | needs the main-flow tree table; row count and ids' md5 recorded | bundle provenance (4,510,368 rows) | ok |
| D13 | the chain is two CSVs, "so a piece that lands changes a state there" | true of a state; an arrow that moves also needs T5 and A36 edited by hand | weak |
| D14 | colours from the registry; word cap 1,200 | Rmd `cap <- 1200` | ok |

### Script headers and comments (11 rows)

| # | Claim | Rests on | Status |
|---|---|---|---|
| S1 | data-script header: the bundle's elements | test `expect_named()` | ok |
| S2 | basin rule: the Bulkley alone ran clean with the additive-function step | the fork's record (not opened); #214 names the Skeena and Bulkley as clean on the topology check | ok |
| S3 | station-year rules 1–5 | code; the test re-derives the pick from the candidate table | ok |
| S4 | "the rule was written after a read of the archive" | accepted (1) | ok |
| S5 | map-script header: layers, lakes of at least 500 ha, streams of order 7 and up | code | ok |
| S6 | "4,510,368 rows" | bundle provenance | ok |
| S7 | "all 52,293 segments are 351 KB, inside the 500 KB the tests allow" | `planning/active/findings.md`; the four files sum to about 403 KB | ok (see D11) |
| S8 | `vm_tree()` header (KISP and ZYMO each carry one Bulkley-coded tree segment) | not probed | ok |
| S9 | Rmd:122 comment quotes the prose as "at a few hundred gauges" | the prose says "stations" | weak |
| S10 | comments in the six temperature test blocks | each matches its assertions | ok |
| S11 | Rmd:297 "a lake cut by the frame keeps its whole area" | `vm_lakes()` takes the atlas's `area_ha` | ok |

### Count

163 rows: 67 body, 21 captions, 6 alt texts, 18 registry labels, 11 boxes, 11 arrows, 2 panel and axis texts,
2 README and pkgdown, 14 CLAUDE.md, 11 headers and comments.
**ok 144, weak 15, WRONG 4** (A3; C12; C20 and R17, one finding). Per table: body 62 / 4 / 1, captions 17 / 2 / 2,
alt 3 / 3 / 0, registry 16 / 1 / 1, boxes 10 / 1 / 0, arrows 11 / 0 / 0, panel and axis 2 / 0 / 0, README and
pkgdown 2 / 0 / 0, CLAUDE.md 11 / 3 / 0, headers and comments 10 / 1 / 0.

By anchor, the 19 rows that are weak or wrong: the current text of an issue, 5 (A32, C18, C20, R17, N10); a script
constant the bundle does not record, 2 (C12, C13); a dependency's default, 1 (A8); a typed description of a figure
or of a data file, 5 (A36, T1, T2, T5, D13); a quantifier nobody measured, 1 (A3); a second copy worded differently
from the first, 5 (A51, R6, D7, D11, S9). No row that rests on a bundle value behind a `stopifnot()` or a test is
weak or wrong: every one of the 19 is a row the build cannot see.

The 15 weak rows are not findings; they are the mechanism's reach, for whoever decides which are worth an edit:
A8, A32, A36, A51, C13, C18, T1, T2, T5, R6, N10, D7, D11, D13, S9 (C8 and D9 share A51's certainty, and the
comment half of A4 is S9).

## The last commit (b3dde4f8) as a fix

- `network → model` in the edges CSV: drawn correctly (render read), and `alt_chain` matches it. Nothing ties the
  two, which is row T5.
- The new test lines pass and can fail: `sum(t_edge_c[in_season])` against `edge$gsdd` is an independent path
  (the script takes `edge$gsdd` from `wet_temp_gsdd()` on the second fill). The two lines holding `edge$t_mean_c`
  and `edge$t_before_c` to `year` compare the bundle with itself, which is all a test without the archive can do.
- "The stream network of its basin has 52,293 reaches": holds (A23), with the network's definition two paragraphs
  below it.
- The README line and the CLAUDE.md sentence follow the article.
- What the fix left: it rewrote the prose under the holdout figure to say the network's gain is "what the network
  adds beyond traits" (A48) and left the caption and the third panel saying the network prediction draws on three
  neighbours and nothing else (F1). The fix corrected which predictions are the baseline's and not what the third
  one is made from.

## Findings

- **[severity: fragile]** `vignettes/articles/segment-temperature.Rmd:465` and `:481-486`, with
  `inst/cartography/wet_temperature.csv:18` — the sketch's third panel and its caption say the network prediction
  is made "from the stream network, its neighbours up and down the same stream", drawing on three stations and
  leaving three under the legend's "Station not used". #223 defines that prediction as "the traits of #213 as fixed
  effects, plus a tail-down covariance on the stream network": the trait terms are fitted to every station, and a
  tail-down covariance also joins stations that are not flow-connected (the three grey ones all share a junction
  downstream). The article's own next paragraph (`:520-522`) says the network's gain over the baseline "is what
  the network adds beyond traits", which only follows if the traits are inside the network prediction. So the
  caption and the paragraph under it describe two different third predictions, and the caption's is narrower than
  the issue's. Accepted item (8) covers keeping three panels, not which stations the third one greys. One way out
  that keeps the sketch: colour the third panel's other stations as used and let the caption say "from traits and
  the stream network, leaning most on its neighbours up and down the same stream".
  - **Rule:** none (nearest text: `code-check.md` "A guard's scope, escape hatches, and remedies", the paragraph on
    executing a compression against each of its sources; the writing rule it breaks, "State each claim by the
    code's definition", is not in the code-check index)

- **[severity: fragile]** `vignettes/articles/segment-temperature.Rmd:166` — "every reach (a stretch of stream,
  usually between two confluences)". Never measured, and the basin the article draws does not support "usually":
  of the 52,293 tree segments under `400.431358`, 24,229 (46 %) are the only segment between two changes of local
  watershed code on their blue line, and 28,064 (54 %) share that stretch with other segments (16,617 of the 27,858
  first-order segments among them; the atlas also breaks a stream at lakes, wetlands and connectors). Measured
  2026-11-25 on the local fwapg by grouping the tree's segments on `(blue_line_key, localcode_ltree)`; the local
  code as the marker of a confluence-to-confluence stretch is this probe's assumption, checked on one three-segment
  stretch whose route measures run end to end. The sentence was moved here from the map section by round 2's fix,
  which changed "usually from one confluence to the next" to "usually between two confluences" without a count.
  "Often" holds; so does dropping the parenthesis, since the map section defines a reach exactly.
  - **Rule:** none (candidate: a quantifier in prose is a number and needs a producer)

- **[severity: fragile]** `vignettes/articles/segment-temperature.Rmd:297-298` — round 1's fix for "lakes of 500 ha
  and up" can now fail, but in one direction only. `lake_min <- 500` is typed in the article, the threshold is
  typed again at `data-raw/temperature_vignette_map.R:71`, and the bundle records neither; the guard is
  `min(map$lakes$area_ha) >= lake_min`. A map script changed to `min_ha = 1000` writes a bundle that passes (run
  this round on the committed bundle with the 10 lakes under 1,000 ha removed: `TRUE`), and the caption goes on
  saying 500 while ten lakes it promises are missing. Lowering the threshold is caught. Record the constant in the
  bundle (the list's "network" attribute or its provenance) and assert `identical()` on it; the same holds for the
  context streams' `min_order = 7` behind "its larger rivers".
  - **Rule:** code-check.md "One fact derived twice"
