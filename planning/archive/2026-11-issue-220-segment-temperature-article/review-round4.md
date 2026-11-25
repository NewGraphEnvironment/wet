# Code-check round 4, branch `220-article-stream-temperature-for-every-rea` at a3f15c92

Reviewed 2026-11-25, 21:25 to 21:35 UTC, read-only in the checkout. The renders, the tests and the bundle reads ran
in a detached worktree under the session scratchpad (removed; `git status` in the checkout is clean). The two
data-raw scripts were read, not run.

## Checklist read

- `checklist_index.md`: all of it.
- `code-check.md`: the prose of all 14 H3s under `## Mechanisms` (table rows skipped); of the 24 other headings,
  "Documentation Staleness" and "An assertion that matches an interpolated value cannot see the claim around it";
  22 not read (no infra, credential, YAML, URL, spreadsheet or PDF shape in this diff).
- `code-check-r.md`: 14 of 132 read: "A database driver's value is not a base R type", "`match()` treats NA as a
  matchable VALUE", "`sprintf("%g", x)` writes `Inf` and `NA` into SQL" (these three for the new `seg_order`
  query), "ggplot2 legends and labels", "knitr and pandoc rewrite a caption", "Moving prose into a code chunk hides
  it from tools that scan the document", "Regenerated binaries churn git even when nothing changed", "Postgres row
  order is never fixed unless the query fixes it", "A `data-raw/` script must load the source tree", "`nzchar(NA)`
  is TRUE", "Under `R CMD check`, tests run from a temp dir against the INSTALLED package", "`tolerance` in testthat
  is RELATIVE", "A duplicate knitr chunk label fails the build", "`paste()` with a zero-length argument returns
  length ONE"; 118 not read (checked from their index line only). My extract cut lines past about 1,200 characters,
  so a few evidence lines of the first nine were read short.
- `code-check-spatial.md`: 9 of 98 read: "sf: `st_intersection()` / `st_difference()` return a GEOMETRYCOLLECTION",
  "FWA main flow is not edge type 1000 alone", "FWA lookup area follows watershed codes", "A relation between FWA
  watershed codes is not a place", "A name is not a key", "`atan2(0, 0)` is 0", "`geom_sf(data = NULL)` draws
  nothing, silently", "A coordinate stored as an attribute can disagree with the geometry it describes", "A
  Freshwater Atlas main stem's downstream end lies on the receiving river's centreline"; 89 not read. Lines past
  about 900 characters were cut in my extract.
- `code-check-shell.md`: none read; the diff holds no shell.

## What was run

- The article rendered from a worktree copy at HEAD: clean, every citation key in the `.bib` (28 citations, none
  unresolved), no duplicate chunk label, body prose 1,193 words against the cap of 1,200. The four PNGs were read.
- The same render in eight separate sessions: four at HEAD and four with a3f15c92's `guides()` line removed from the
  holdout chunk. At HEAD all four figures have one md5 in all four builds. With the line removed, one build in four
  drew the holdout figure differently (md5 `631c5791…` against `3289f4fb…`); the other three figures did not move.
  So a3f15c92's fix is real and it holds.
- `tests/testthat/test-vignette_data.R` under `NOT_CRAN=true`: 18 blocks, 0 failed, 0 errors, 0 skipped (the six
  temperature blocks: 20, 9, 12, 10, 42, 10 expectations).
- Both bundles read with `readRDS()`; every number and size word the page prints was recomputed from them.
- Issues #213, #223, #219, #214, #215, #222, #224, #220 fetched at 21:26 UTC. None has been edited since round 3
  read them (#213 18:47, #223 18:47, #219 17:42, #214 20:50, #215 17:28, #222 18:25, #224 18:48, #220 18:11 UTC).
- `git diff b3dde4f8..HEAD` read in full outside `planning/`.

## Round 3's four wrong rows

| Round 3 | Now | Verdict |
|---|---|---|
| A3 "usually between two confluences" | "(a mapped stretch of stream)" | fixed; no quantifier left |
| C12 lake threshold typed twice, guard one-directional | the map script names `lake_min_ha` and `context_min_order` once, the bundle records them (`drawn`), the article asserts `identical(lake_min, 500)` and `identical(drawn$context_min_order, 7)`, and `vm_write()` compares attributes other than provenance, so the bundle was rewritten for it | fixed; a script moved to 1,000 ha now stops the build |
| C20, R17 third panel greyed three stations | `use$network` is every other station, the stream through the hidden one is drawn heavy (`lean`), the title is "From traits and the stream network", and caption, alt text, registry label and the paragraph under the figure say the same thing | fixed; matches #223's "traits of #213 as fixed effects, plus a tail-down covariance" |

## Round 3's fifteen weak rows

| Round 3 | Now |
|---|---|
| A8 the 5 °C and 4 °C weekly rule | unchanged: `gsdd::gsdd()` defaults are 5, 4 and a 7-day window at 0.3.0.9009, the bundle's version; nothing in the build reads them. Still weak (A8) |
| A32 "two ways" | unchanged: #213's rule can report the population mean as the baseline. Still weak (A35) |
| A36 "everything above it in the diagram" | the arrows into `model` are now asserted; "above" is still not, and `air_reach` sits at the model's own height (y 2.9). Still weak (A37) |
| A51 "Readings that are not water" | unchanged; accepted item 2 covers showing the reading. Still weak (A61) |
| C13 "its larger rivers thin" | the order is recorded and asserted. Weak for a new reason: "larger rivers" now has two definitions on the page (C13) |
| C18 "a relation fitted to every other station" | unchanged. Still weak (C18) |
| T1 "near zero in winter" | unchanged: measured days in January and February read about 2 °C; the line at 0 is open-loop. Still weak |
| T2 "late August and September" | unchanged; not tied to `pick$gap_start`. Still weak |
| T5 chain alt text | held by `feeds()` on `fills`, `baseline` and `model`. ok |
| R6 "Bulkley River basin" | unchanged. Still weak |
| N10 "weekly temperature" | now "temperature". ok |
| D7 "another basin is a data edit" | unchanged. Still weak |
| D11 "393 KB at 200 m" | unchanged: the bundle is 393.1 KB, the map-script header says the tree layer is 351 KB. Still weak |
| D13 "a piece that lands changes a state there" | an arrow that moves now stops the build at `feeds()`. ok |
| S9 comment "at a few hundred gauges" | unchanged at Rmd:122; the prose says "stations". Still weak |

## The new size words

| Words | Guard | Value | Can it fail | Status |
|---|---|---|---|---|
| "a few hundred stations" | `truth_stations >= 200, < 500` | 257 | yes | ok |
| "tens of thousands of reaches" | `n_reach >= 2e4, < 1e5` | 52,293 | yes | ok |
| "About a dozen" (prose and map alt text) | `n_st >= 9, <= 15`, and `net$with_station == n_st` | 11 | yes | ok |
| "some only recently" | `n_short >= 2`, every unfitted station's first day in the last year read, that year asserted to be 2025 | 3, all January 2025 | yes | ok |
| "most reaches are small streams, as in the basin above" | `share_small > 0.5`, small = order 1 or 2 | 75.1 %; order 1 alone is 53.3 % | yes | ok: holds at either cut |
| "Most stations sit on larger rivers, as in the basin above" | `share_river > 0.5`, larger river = order 5 and up, on the basin's 11 stations | 8 of 11 | yes | weak: see below |
| "about 129 degree days on average" | `season_mae` in 100 to 150, printed from the bundle | 128.7 | yes | ok |

The one that turns on its definition is "most stations sit on larger rivers". Measured on the bundle, the basin's
eleven stations by each reading of "larger river":

| Reading | Stations | Share |
|---|---|---|
| stream order 5 and up (the guard's) | 8 | 73 % |
| "River" in the station's name | 6 | 55 % |
| gross drainage area 500 km² and up | 6 | 55 % |
| stream order 6 and up | 5 | 45 % |
| on one of the map's three heavy named rivers (within 300 m) | 5 | 45 % |
| stream order 7 and up, which is what "larger rivers" means in the map caption | 3 | 27 % |

Order 5 takes in Goathorn Creek (121 km²), Buck Creek and the Telkwa below Tsai Creek. The province-wide half of
the sentence rests on #214 ("the gauges are mostly rivers") and `research/station_temperature_fill.md:27`
("year-round ECCC gauges, mostly rivers"), not on anything the build reads. The half the bullet is for is much
firmer under the guard's own cut: 1 of the 11 stations is on a stream of order 1 or 2, where 75 % of the reaches
are. The line is owner-approved (accepted item 11) and true under the guard as written, so this is a weak row, not
a finding; a guard on `mean(v$stations$stream_order <= 2)` being small would hold the point the bullet makes without
leaning on where "larger" starts.

## Enumeration

Status: **ok** (holds, and no other copy in the diff disagrees), **weak** (true today, but resting on nothing the
build reads, or one copy words it differently, or a leftover of a reworded sentence), **WRONG** (none this round).
"bundle" is a value of a committed `.rds` recomputed this round.

### Article body (78 rows)

| # | Claim | Rests on | Other copies | Status |
|---|---|---|---|---|
| A1 | `wet` does not yet give stream temperature for every stream reach | the package; #214 | CLAUDE.md "opens by saying … not built"; README "not all built yet" | ok |
| A2 | the article shows where the work starts, what it aims for, how it will be tested | its own sections | heading A45 | ok |
| A3 | the aim: growing-season degree days at every reach (a mapped stretch of stream) in BC | #214 opening | chain boxes "at every reach"; A21 defines a reach exactly | ok |
| A4 | "can be computed at a few hundred stations across the province" | guard; bundle 257 | #214 "a few hundred places"; comment S9 says "gauges" | ok |
| A5 | getting to every reach takes a model on the stream network | #214, same words | chain | ok |
| A6 | the roadmap says what is done and what is next | #214's sections | — | ok |
| A7 | a fish grows faster in warmer water, up to a point | general | — | ok |
| A8 | summed from the first week above 5 °C to the first week below 4 °C | `gsdd` defaults (5, 4, 7 days), no guard | — | weak |
| A9 | 10 °C for 100 days gives 1,000 | arithmetic, asserted | — | ok |
| A10 | low totals: summer-hatched fish too small to survive winter | Coleman and Fausch 2007 | A62 | ok |
| A11 | Simpson Creek at its mouth, about 4 km north-west of Smithers | bundle; `stopifnot` | C1 | ok |
| A12 | joins Kathlyn Creek on the way to the Bulkley River | `pick$into1/into2`, asserted | — | ok |
| A13 | recorded every day March to November 2020 except 29 days from 25 August | bundle; `stopifnot`; test | C3; CLAUDE.md | ok |
| A14 | a season with a missing day has no total, so the gap is filled first | `gsdd$unfilled` NA; test | — | ok |
| A15 | fill: air2stream corrected by the station's readings either side and by nearby stations | `R/wet_temp_fill.R` | A65 "sub-drainage" | ok |
| A16 | on air alone the model is "open-loop" | fill's method names | C5; R4 | ok |
| A17 | a reach with no station has no readings, so open-loop is where it starts | #213 Problem | — | ok |
| A18 | the fill restarts from every reading, so a bad one is carried | #222 | — | ok |
| A19 | last reading about 6 °C above the day before, air barely moved | bundle (5.98); `stopifnot` | C8 | ok |
| A20 | hiding it lowers the total from 1,460 to 1,393 | bundle (1,460.38; 1,393.35); test | A61 "67"; CLAUDE.md "67" | ok |
| A21 | a reach here is one Freshwater Atlas segment with its own identifier | #214 | A3 | ok |
| A22 | the Bulkley runs north-west from Houston past Smithers to the Skeena at Hazelton | computed; three `stopifnot`s | C14 | ok |
| A23 | its basin's network has tens of thousands of reaches | guard; 52,293 | CLAUDE.md and map-script header give the count | ok |
| A24 | about a dozen hold a federal hydrometric station that has recorded water temperature | guard; 11 | T4; R9; README; CLAUDE.md "eleven" | ok |
| A25 | some only recently | guard; 3 began January 2025 | — | ok |
| A26 | small-stream loggers are not in `wet` yet, so the map shows only these stations | #215 (title and Problem) | — | ok |
| A27 | the network stands on Simon Norris's `fwapg`, which loads the Freshwater Atlas into PostgreSQL | #214 "The network"; #220 "`fwapg` (Simon Norris)" | A70 | ok |
| A28 | side channels trimmed so water never splits, as a stream network model needs | `vm_tree()`; #214 | N6 "with no splits"; map-script and `vm_tree()` headers reworded to match | ok |
| A29 | that step runs from a fork of `fwapg` today | #214 "runs today from … our fork" | A70 | ok |
| A30 | the diagram's colours say which parts exist | chain CSV and registry | C15 | ok |
| A31 | traits: position, elevation, snow, lakes and glaciers | #213 traits (easting, northing, elevation, snow, glacier and lake cover) | — | ok |
| A32 | two reaches with like traits should warm alike | premise of #213 | — | ok |
| A33 | the baseline is the simple answer to measure a fuller model against | #213 opening | E6 | ok |
| A34 | air2stream has three settings, fitted at each station | `fit$a1..a3`; fitted where a station has 365 days | C17 | ok |
| A35 | the baseline predicts them from traits, two ways | #213 candidates 2 and 3; #214 item 2 | C21; CLAUDE.md; #213's rule can also report the population mean as the baseline | weak |
| A36 | a network model fits every station at once; reaches on one stream inform each other | #214 | N10 | ok |
| A37 | it can draw on everything above it in the diagram: network, stations and fills, traits, air at every reach, how the baseline did | `feeds("model")`; #214 "What we can bring" | `air_reach` is beside the model, not above | weak |
| A38 | "what the habitat work needs from it" is temperature at every reach with its uncertainty, and degree days with it carried through | #214 "What the habitat work needs in the end" | the phrase has no antecedent on the page | weak |
| A39 | two fitted in northern BC, Nechako and Skeena, and this work follows them | #214; bib | — | ok |
| A40 | the method is open | #214, same words | CLAUDE.md | ok |
| A41 | a process model simulates water and heat from the weather | #219 | N8 | ok |
| A42 | PCIC's gives daily water temperature at points on its own network, past weather and climate models to 2100 | #219, #214 | N8 | ok |
| A43 | its temperatures can be compared with the same station records | #219 | E10 "compared at the stations" | ok |
| A44 | one way to ask where streams are becoming warm enough | #219, #214 | E11 | ok |
| A45 | heading "How will it be tested?" | accepted (11) | #220's body lists the old heading | ok |
| A46 | a holdout takes a station's whole record away | #213 | CLAUDE.md | ok |
| A47 | three predictions, at stations across the province with a complete growing season: the baseline's two, and one that adds the network | #213 truth set; #223 | C17, C21; CLAUDE.md | ok |
| A48 | a network model can be checked against the same hidden stations | #214 "scores on the same holdout" | — | ok |
| A49 | kriging: weighting the near ones most | definition | — | ok |
| A50 | on a network, near is along the water and in the direction it flows | #223 tail-down | — | ok |
| A51 | it starts from the same traits and adds the network, so its gain over the baseline is what the network adds | #223 Model; #214 | C20, W1, the third panel: agree. Carries A35's caveat | ok |
| A52 | each prediction run through air2stream on the hidden station's own air | #213 Run | — | ok |
| A53 | two marks: the station's own fit, and the average of all stations | #213 benchmark and candidate 1 | — | ok |
| A54 | each tried twice, with and without the neighbours up and down its stream | #213 Pools | — | ok |
| A55 | for the network's prediction that difference is what the neighbours are worth | #223 Pools | — | ok |
| A56 | a season hidden, air alone: about 129 degree days on average | bundle (128.74); guard | #213, #214 "129" | ok |
| A57 | a reach with no station can only do worse; how much is what the test measures | #213 | — | ok |
| A58 | most stations sit on larger rivers, as in the basin above | guard at order 5 and up: 8 of 11; #214, the research file | 5 of 11 at order 6; 3 of 11 at the caption's order 7 | weak |
| A59 | most reaches are small streams, as in the basin above | guard: 75 % order 1 or 2 | #215 | ok |
| A60 | so the test says least about them | #215 "says little about the creeks" | — | ok |
| A61 | readings that are not water: one like the first figure's moved its year by 67 | bundle (67.03); guard | C8 "most likely"; CLAUDE.md "is a sensor out of the water" | weak |
| A62 | cutthroat, Colorado: 900 to 1,200 best, under 800 unsuitable | Coleman and Fausch 2007; #214 | — | ok |
| A63 | Elk Valley reports apply them | bib | — | ok |
| A64 | none found yet for the other species of BC | #214 | — | ok |
| A65 | the fill borrows from its sub-drainage, so the recipe reads them all | recipe; `pool` | A15 | ok |
| A66 | recipe comment: most gauges of 08E record no water temperature | 74 gauges, 25 in the archive (round 3) | data-script comment | ok |
| A67 | the recipe returns the picked year | the data script runs the committed chunk; `recipe-check` | CLAUDE.md | ok |
| A68 | read 25 November 2026, 2002-01-01 to 2025-12-31, HYDAT 2026-07-17, built at 36700ca2 | bundle provenance; 36700ca2 is the commit that added the stream-order read | accepted (6): a3f15c92 changed two lines of the holdout chunk | ok |
| A69 | `wet`, `cd`, `gsdd`, `tidyhydat` roles | code | — | ok |
| A70 | `fwapg` loads the atlas; the network with no splits is built on it | #214 | A27, A29 | ok |
| A71 | `SSN2` is the software for kriging on a stream network | #223 | — | ok |
| A72 | `ggplot2`, `ggrepel`, `gq`, `sf`, `knitr`, `bookdown`, R | the article's code | — | ok |
| A73 | "This build ran on `wet` 0.4.44, `cd` 0.6.13 (commit c8bc100) and `gq` 0.25.0 (commit 298b016)" | rendered | the same chunk in two other articles | ok |
| A74 | data: ECCC stations as archived by water-temp-bc | script `root` | — | ok |
| A75 | data: ERA5-Land | `cd` | — | ok |
| A76 | data: PCIC named, not yet read | no PCIC read in either script | CLAUDE.md | ok |
| A77 | data: Freshwater Atlas and BC Geographic Names | `vm_*()` | — | ok |
| A78 | heading "Where do we have temperature, and where not?" | #220 | — | ok |

### Captions (21 rows)

| # | Claim | Rests on | Status |
|---|---|---|---|
| C1 | Simpson Creek at its mouth in 2020 | `stopifnot` | ok |
| C2 | black, orange, pale band, blue | registry; read on the render | ok |
| C3 | 29 days filled, 25 August to 22 September | bundle; tests | ok |
| C4 | the fill's 95% interval | `stopifnot(formals(wet_temp_fill)$level == 0.95)` | ok |
| C5 | air alone through air2stream, the open-loop line | `s_open_c` | ok |
| C6 | growing season 28 April to 22 October, to 1,460 | bundle; tests | ok |
| C7 | the stretch on filled days is orange | `dd_fill` | ok |
| C8 | 15.5 °C after 9.6 °C, most likely a sensor leaving the water | bundle; #222 | ok |
| C9 | every reach of its stream network, heavier on larger streams | `stopifnot(all(net$orders$drawn))` | ok |
| C10 | the federal stations that have recorded water temperature (orange; Simpson Creek's black) | 10 orange and 1 black on the render | ok |
| C11 | Bulkley, Morice and Telkwa drawn heavy and named | `stopifnot(setequal())` | ok |
| C12 | lakes of 500 ha and up are pale blue | `drawn$lake_min_ha`, `identical(, 500)`; smallest lake 513 ha | ok |
| C13 | land outside dimmed, "its larger rivers thin", the Skeena named | `drawn$context_min_order` asserted 7 | weak: "larger rivers" is order 7 and up here and order 5 and up behind A58 |
| C14 | three towns labelled, bar 30 km, inset | `stopifnot`; `gq_scale_breaks()` | ok |
| C15 | chain colours and states; dashed because a comparison | registry; `stopifnot`; test | ok |
| C16 | a sketch on a made-up network (pale lines) | `toy` | ok |
| C17 | one hidden (orange), three ways, blue used, grey left out | `use`; `stopifnot` | ok |
| C18 | traits: "a relation fitted to every other station" | #213 candidate 2; blocked CV leaves out the hidden station's fold | weak |
| C19 | the few stations most like it, wherever they are | #213 candidate 3 | ok |
| C20 | traits and the network together, leaning most on the stream up and down from the hidden station (heavy line) | #223; `lean` runs through stations a, f and b | ok |
| C21 | the first two are the baseline | #213, #223 | ok |

### Alt text (6 rows)

| # | Claim | Rests on | Status |
|---|---|---|---|
| T1 | "rising from near zero in winter to a summer peak" | typed; measured winter days read about 2 °C | weak |
| T2 | "a gap in late August and September" | typed | weak |
| T3 | a second line for air alone; climbing to 1,460 | bundle | ok |
| T4 | about a dozen orange and black points on its rivers and creeks | guard 9 to 15 | ok |
| T5 | what feeds gap filling, the baseline and the network model; a process model to one side | `feeds()` asserted on all three | ok |
| T6 | three copies, seven stations, the used stations differ, the third marks the stream through the hidden one | `toy`, `use`, `lean` | ok |

### Registry labels (19 rows)

| # | Label | Status |
|---|---|---|
| R1–R5 | Measured day; Filled day; Range the filled day most likely lies in; Air temperature alone (air2stream); Growing season | ok (5) |
| R6 | Bulkley River basin (typed; in no legend; the basin is a row of `scripts/temperature_basins.csv`) | weak |
| R7–R9 | Stream reach; Named river; Federal station with water temperature | ok (3) |
| R10 | Simpson Creek station (held by `stopifnot(identical(pick$stream, "Simpson Creek"))`) | ok |
| R11–R14 | In place; Being built; From a network model; An existing process model | ok (4) |
| R15–R16 | Station hidden; Station the prediction draws on | ok (2) |
| R17 | Station not used (true of the middle panel; the other two have none) | ok |
| R18 | Stream | ok |
| R19 | Stream the prediction leans on most (new; matches C20 and T6) | ok |

### Chain boxes (11 rows) and arrows (11 rows)

| # | Box or arrow | Status |
|---|---|---|
| N1–N9 | as round 3 | ok (9) |
| N10 | Network model, temperature at every reach (the time step is gone, as #214 leaves it open) | ok |
| N11 | Degree days at every reach with their uncertainty | ok |
| E1–E5 | readings→fills; air→fills; fills→degree days; fills→baseline "the fitted models"; traits→baseline | ok (5) |
| E6 | baseline→model "all of the above and the baseline's result" | ok |
| E7–E9 | network→model; air at every reach→model; model→degree days at every reach | ok (3) |
| E10 | PCIC→baseline "compared at the stations", dashed (matches A43) | ok |
| E11 | PCIC→degree days at every reach "future change", dashed | ok |

### Panel titles and axis text (2 rows)

| # | Text | Status |
|---|---|---|
| W1 | "From catchment traits", "From the stations most like it", "From traits and the stream network" | ok |
| W2 | "Water temperature (°C)", "Degree days so far", "1,460 degree days" | ok |

### README and `_pkgdown.yml` (2 rows)

| # | Claim | Status |
|---|---|---|
| M1 | README: what degree days are, how few reaches of one basin hold a federal station, steps not all built | ok |
| M2 | `_pkgdown.yml` lists `articles/segment-temperature` | ok |

### CLAUDE.md paragraph (19 rows)

| # | Claim | Rests on | Status |
|---|---|---|---|
| D1 | title, Articles menu, twin of `segment-discharge` | `_pkgdown.yml`; #220 | ok |
| D2 | opens by saying the product is not built; four figures | article | ok |
| D3 | the Bulkley's network with its eleven temperature stations | bundle: 11 | ok |
| D4 | the sketch: the baseline's two trait predictions (#213) and kriging on the network beside them (#223) | article | ok |
| D5 | no checklist, no baseline or PCIC scores; revised when #213, #223, #219 have run | article | ok |
| D6 | the header holds the two rules "written before the pick was computed" | accepted (1) | ok |
| D7 | "another basin is a data edit" | true of the two scripts; the article and registry type the towns, rivers, stream, station and year behind `stopifnot()`s | weak |
| D8 | 08EE012, 2020, the only qualifying year of the eleven stations' | bundle | ok |
| D9 | fills the 08E pool; season from `gsdd::gss()`; runs the recipe; second fill adds 67 °C-days | script; bundle | ok |
| D10 | keeps the committed file to `all.equal()`'s tolerance (#224) | script `same()` | ok |
| D11 | "(52,293 segments, 393 KB at 200 m)" | 393.1 KB is the whole map bundle; the map-script header gives the tree layer as 351 KB | weak |
| D12 | needs the main-flow tree table; row count and ids' md5 recorded | bundle provenance | ok |
| D13 | the chain is two CSVs, so a piece that lands changes a state there | a moved arrow now stops at `feeds()` | ok |
| D14 | colours from the registry; word cap 1,200 | Rmd `cap <- 1200`; 1,193 words | ok |
| D15 | new: "it names no owner for any piece" | the prose names Simon Norris for `fwapg`, and PCIC for the process model in prose and on a chain box; what was removed is who builds each planned piece | weak |
| D16 | new: "gives sizes in place of reach and station counts that move" | no reach or station count left in prose, captions or alt text | ok |
| D17 | new: "compares models with station records (never 'scores' one against another)" | no "scor" in the Rmd, the registry or the chain CSVs | ok |
| D18 | new: "leaves the method, the formats and the time step open" | the page says "The method is open" and names no time step; it says nothing about formats, which is #214's sentence | weak |
| D19 | new: "the map bundle records the thresholds its caption quotes (`drawn`)" | bundle attribute; test | ok |

### Script headers and comments (20 rows)

| # | Claim | Rests on | Status |
|---|---|---|---|
| S1 | data-script header: the bundle's elements, stations now with stream order | test `expect_named()`; bundle | ok |
| S2 | basin rule | as round 3 | ok |
| S3 | station-year rules 1 to 5 | code; test | ok |
| S4 | the rule was written after a read of the archive | accepted (1) | ok |
| S5 | map-script header: layers, order 7 and up | code | ok |
| S6 | "4,510,368 rows" | bundle provenance | ok |
| S7 | "all 52,293 segments are 351 KB" | as round 3 | ok |
| S8 | `vm_tree()` header, reworded "as a stream network model runs on it" | matches A28 | ok |
| S9 | Rmd:122 quotes the prose as "at a few hundred gauges" | the prose says "stations" | weak |
| S10 | comments in the six temperature test blocks, with the new `drawn` lines | each matches its assertions | ok |
| S11 | Rmd:305 "a lake cut by the frame keeps its whole area" | `vm_lakes()` | ok |
| S12 | new, map-script header: `drawn` holds three thresholds "which the article's caption quotes and holds itself to" | the caption quotes one (500 ha), the article asserts two, and nothing reads `simplify_m` | weak |
| S13 | new, Rmd:234 "the prose gives sizes, not counts that move" | the guard under it | ok |
| S14 | new, Rmd:236–237 small is order 1 or 2, a larger river order 5 and up | the guard's definition (A58) | ok |
| S15 | Rmd:244–245 two comments on one guard; the first, "too short to fit a station model yet", is the removed sentence's | leftover | weak |
| S16 | new, Rmd:384 "what feeds what, as the prose and the figure's alt text say it" | T5, A37 | ok |
| S17 | new, Rmd:480–481 and 485 the network's prediction keeps the traits; the middle way draws on fewer | `use`; `stopifnot` | ok |
| S18 | new, Rmd:534 two legends need an order or "their order follows a hash that differs between sessions" | reproduced: 1 build in 4 differs without the line, 0 in 4 with it; the hash as the cause was not probed | ok |
| S19 | Rmd:61–66 `in_words()`, "a small count in words, as prose writes it" | no caller since the counts left the prose | weak |
| S20 | Rmd:496 "the station error the section closes on", with `val$season_open$n > 800` | the error is quoted in the next section, and the prose no longer prints the season count | weak |

### Count

189 rows: 78 body, 21 captions, 6 alt texts, 19 registry labels, 11 boxes, 11 arrows, 2 panel and axis texts,
2 README and pkgdown, 19 CLAUDE.md, 20 headers and comments.

**ok 169, weak 20, WRONG 0.** Per surface (ok / weak / wrong): body 72 / 6 / 0, captions 19 / 2 / 0, alt text
4 / 2 / 0, registry 18 / 1 / 0, boxes 11 / 0 / 0, arrows 11 / 0 / 0, panel and axis 2 / 0 / 0, README and pkgdown
2 / 0 / 0, CLAUDE.md 15 / 4 / 0, headers and comments 15 / 5 / 0.

The 20 weak rows, by what they rest on:

- an issue's current text, with no anchor in the build (3): A35, A38, C18;
- a dependency's default (1): A8;
- a typed description of a figure (3): A37, T1, T2;
- a size word whose guard turns on where a threshold sits (2): A58, C13;
- a second copy worded differently from the first (6): A61, R6, D7, D11, D15, D18;
- a leftover of the rewording (5): S9, S12, S15, S19, S20.

Round 3 had 15 weak rows. Three closed (T5, N10, D13), twelve carry over (A8, A35, A37, A61, C13, C18, T1, T2, R6,
D7, D11, S9), and eight are new, all from the rewording: A38, A58, D15, D18, S12, S15, S19, S20.

## The five questions asked

1. **Sentences the rewording touched.** None reproduces an earlier defect one step over. The third prediction is
   now one thing in the caption, the alt text, the panel title, the registry label, the code comment and the
   paragraph under the figure. The reach definition in the opening no longer carries a quantifier.
2. **Round 3's weak rows.** Tabled above: three closed, twelve unchanged.
3. **Size words.** Every one sits behind a guard that can fail. One, "most stations sit on larger rivers", passes
   at the guard's cut and fails one stream order up (A58).
4. **Restatements left behind.** Five, all comments or dead code, none on the built page: S9, S12, S15, S19, S20.
   Nothing on the page, in the registry, the chain CSVs, the README line or the CLAUDE.md paragraph still carries a
   reworded sentence's old form (no "scor", "weekly", "has to", "beat", "New Graph", reach or station count).
5. **Against #213, #223, #219, #214.** The page says nothing those four do not say at their current text. Two
   phrases are carried from #214 without what makes them clear there: "the habitat work" (A38), and CLAUDE.md's
   "the formats … open" (D18), which is #214's sentence and not the article's.

## Notes that are not findings

- Body prose is 1,193 words against a cap of 1,200 that stops the build, so the next edit has seven words of room.
- 36700ca2 does not build on its own: it added the `share_river` guard and the `stream_order` test one commit
  before 983f24c8 put `stream_order` in the bundle (the bundle at 36700ca2 has no such column). HEAD is fine; this
  only matters to a bisect.
- The new `seg_order` query is ordered on a unique key, reads `linear_feature_id` through `as.numeric()` in the
  session that fetched it, saves `stream_order` as integer, and stops on an unmatched segment; the tests hold the
  type and refuse `integer64` columns.

## Clean

No issues found. 189 rows walked: 169 ok, 20 weak, 0 wrong.
