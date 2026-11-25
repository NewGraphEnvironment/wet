# Review round 5 (#220): the wording changed after round 4

Scope: `a3f15c92..ae17143b`, `planning/` excluded (the article, one header comment in
`data-raw/temperature_vignette_map.R`, one sentence of `CLAUDE.md`). Reviewed 2026-11-25 in a detached
worktree of `ae17143b`, removed afterwards; the checkout was not touched.

## Checklist read

- `code-check.md` (38 headings): all 14 under `## Mechanisms` read in full, table rows skipped. Of the other
  24, two read in full ("Documentation Staleness", "An assertion that matches an interpolated value cannot
  see the claim around it"); 22 by index line only.
- `code-check-r.md` (132 headings): three read in full ("Moving prose into a code chunk hides it from tools
  that scan the document", "knitr and pandoc rewrite a caption: `fig.cap` is evaluated late, and `alt` copies
  it", "Numeric routines that err at their edge, and `round()`"); 129 by index line only.
- `code-check-shell.md` (75 headings): none in full; the diff holds no shell. 75 by index line only.
- `code-check-spatial.md` (98 headings): none in full; the diff changes no spatial code. 98 by index line only.

## What was run

- **Render:** `rmarkdown::render()` of the article after `pkgload::load_all()`: exit 0, 28 of 28 chunks, no
  pandoc `citation ... not found` line, 25 keys cited and 25 in the `.bib`, none dropped or added by the delta.
- **Tests:** `NOT_CRAN=true testthat::test_file("tests/testthat/test-vignette_data.R")`: 18 tests, 367
  expectations passed, 0 failed, 0 errors, 0 skipped.
- **Word count** by the article's own `wordcount` logic: 1,199 at HEAD (1,193 at `a3f15c92`), cap 1,200.
- **Guards, by mutation** (the bundle changed in the copy, the article's chunks run from `knitr::purl()`):

  | Mutation | Result |
  |---|---|
  | none (control) | no guard fires |
  | air 0.1 °C cooler on the edge day than the day before | stops: `air_at(edge$date) - air_at(edge$date - 1) >= 0` (the old `abs() < 0.5` would have passed) |
  | air 0.6 °C warmer on the edge day | stops: `... < 0.5` |
  | 4 of 11 stations on stream order 1 or 2 | stops: `on_small < 0.25` |
  | no station on order 1 or 2 | passes (the guard has no lower bound; see notes) |
  | orders 1 and 2 cut to 10,000 of 23,034 reaches | stops: `share_small > 0.5` |
  | season MAE 160 | stops: `season_mae < 150` |
  | season `n` = 5 | passes, as intended: the `n > 800` arm was removed and `n` is printed nowhere |
  | validated stations 150 | stops: `truth_stations >= 200` |
  | hiding the reading raises the total | stops: `edge_cost > 50` |
  | lakes recorded at 400 ha | stops: `identical(lake_min, 500)` |

## Findings

- **[severity: fragile]** `vignettes/articles/segment-temperature.Rmd:167` — "A fish grows faster in warmer
  water." lost its "up to a point" in this pass. It is the one sentence in the delta whose truth changed with
  the cut: growth rises with temperature to an optimum and falls above it, and the article's subject is the
  whole province, where some streams run warmer than that. Nothing guards or cites the sentence (the citation
  that follows is for the degree-day rule). Restoring the four words takes the body to 1,203 against the cap
  of 1,200, so it needs three words from elsewhere; it is the owner's to weigh, and is reported because it is
  not on the accepted list.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** `inst/cartography/wet_temperature.csv:2`, `vignettes/articles/segment-temperature.Rmd:94`,
  `CLAUDE.md:60` — three unrendered copies were left with the wording the delta replaced. None reaches the
  page, and none can fail a build.
  - The registry row's `note` still reads "what the logger read" for the federal station's reading; the
    caption (Rmd:141) and the prose (Rmd:175) now say "the station recorded", and "logger" on the page now
    means only the small-stream records of #215.
  - The comment above the tightened guard still says the reading was "warmer than the day before although
    the air was not". The guard now requires the air to be no cooler (`>= 0`), the bundle has it 0.03 °C
    warmer, and the prose says "the air barely warmed".
  - `CLAUDE.md` still says "the map bundle records the thresholds its caption quotes (`drawn`)", in the
    sentence this delta edited. The delta corrected the same statement in the map script's header: the caption
    quotes one threshold, the lakes' 500 ha.
  - **Rule:** code-check.md "Documentation Staleness"

## The rows checked

36 rows: 33 ok, 2 with a stale unrendered copy (finding 2), 1 unsupported (finding 1).

| # | Changed text (file:line at HEAD) | Rests on | Other copies | Status |
|---|---|---|---|---|
| 1 | `CLAUDE.md:60` "assigns no piece to anyone (software and data are cited where they are used)" | the article's prose: the only people or bodies named are Simon Norris with `fwapg`'s citation and PCIC with its citation | `planning/active/findings.md` wording rules | ok |
| 2 | `CLAUDE.md:60` "leaves the method and the time step open" ("the formats" dropped) | Rmd:449–450; #214 "The method is open", "the time step are open" | — | ok |
| 3 | `CLAUDE.md:60` "records the thresholds its caption quotes" (unchanged tail of the edited sentence) | `attr(map, "drawn")` holds three; the caption quotes one | map script header, corrected in this delta | stale copy |
| 4 | `data-raw/temperature_vignette_map.R:27–28` "the article's caption quotes the lakes' and holds the layers to the first two" | Rmd:299–302, 308, 313; test lines 480–483 | CLAUDE.md (row 3) | ok |
| 5 | Rmd: `in_words()` removed | no call at `a3f15c92` or HEAD; render passes | — | ok |
| 6 | Rmd:98 air guard, `>= 0` and `< 0.5` | bundle: air 9.746 then 9.777 °C (+0.031); both arms fire under mutation; the test (lines 443–444) holds both days present, so the comparison cannot be zero-length | comment at Rmd:94 | ok; comment stale |
| 7 | Rmd:116 comment "at a few hundred stations" | Rmd:161; `truth_stations` 257 in [200, 500) | #214 "a few hundred places" | ok |
| 8 | Rmd:141 caption "as the station recorded it" | typed; registry label "Measured day" | registry `note` "what the logger read" | ok; note stale |
| 9 | Rmd:157–158 "`wet`, for stream flow and water temperature in British Columbia, does not yet give temperature for every stream reach" | `DESCRIPTION` Title; README tagline | CLAUDE.md "opens by saying the per-segment temperature product is not built" | ok |
| 10 | Rmd:167 "A fish grows faster in warmer water." | nothing | — | unsupported (finding 1) |
| 11 | Rmd:175 "The station recorded every day from March through November of 2020 except 29 days from 25 August" | guard Rmd:85; `pick` | caption: 25 August to 22 September | ok |
| 12 | Rmd:209 "while the air barely warmed" | row 6 | caption names no air | ok |
| 13 | Rmd:210 "as the method gives it" ("today" dropped) | accepted | — | ok |
| 14 | Rmd:230–234 comment and guard `share_small > 0.5, on_small < 0.25` | map bundle: 39,259 of 52,293 reaches on order 1 or 2 (75.1 %); values bundle: 1 of 11 stations (08ED004, order 2); both arms fire | row 32 | ok |
| 15 | Rmd: duplicate comment "too short to fit a station model yet" removed | the comment at Rmd:238 says it | — | ok |
| 16 | Rmd:305 caption "One basin as an example, the Bulkley River: every reach ..." | `v$basin$name`; six `%s` and six arguments; renders | alt text "Map of the Bulkley River basin"; README "one river basin" | ok |
| 17 | Rmd:320 "The aim is the whole province; the Bulkley River basin is used here only as an example." | the opening paragraph; #214 "every stream reach in BC"; owner-approved | caption (row 16) | ok |
| 18 | Rmd:320–321 "A reach here is one stream segment of the Freshwater Atlas" ("with its own identifier" dropped) | #214 "A reach here is a Freshwater Atlas stream segment" | Rmd:160 "(a mapped stretch of stream)" | ok |
| 19 | Rmd:324 "Small-stream loggers are not in `wet` yet." (clause on the map dropped) | #215, open: "none is in wet" | — | ok |
| 20 | Rmd:438–439 catchment traits (second sentence dropped) | #213 "Traits per station" | chain box "Catchment traits of every station and reach" | ok |
| 21 | Rmd:440 "The baseline is the simple answer: what catchment traits alone can say." | #213 candidates 2 and 3; #214 item 2 | chain box "Baseline"; caption "The first two are the baseline" | ok |
| 22 | Rmd:446–448 "What is needed from it is temperature at every reach with its uncertainty, and degree days with that uncertainty carried through." | #214 "What we are hoping for" | chain box "Degree days at every reach with their uncertainty" | ok |
| 23 | Rmd:448–449 "Network models of weekly stream temperature have been fitted for the Nechako and Skeena watersheds ..., and this work follows them." | #214 "The network models this follows: weekly air2stream ..."; `research/station_temperature_fill.md:68`; the two `.bib` titles | — | ok |
| 24 | Rmd:449–450 "The method and the time step are open." | #214 | CLAUDE.md (row 2) | ok |
| 25 | Rmd:489 comment: the error "What is not known yet?" quotes | Rmd:548 | — | ok |
| 26 | Rmd:492 guard without `val$season_open$n > 800` | `n` (897) is printed nowhere, at either commit; `season_mae` 128.74 from `data/checks/temp_fill_validate.txt` line 8 | #213 "about 129 °C-days" | ok |
| 27 | Rmd:510–513 "Three simple predictions are to be tested ..., at stations across the province with a complete growing season, on daily temperature and the season's degree days" | #213 "Truth set", "Scores"; #223 "Same frame, same scores" | caption "predicted three ways" | ok |
| 28 | Rmd:513 "The same hidden stations are there for any model to be compared on." | #223; #219 "The same truth set and breakdowns as the baseline" | — | ok |
| 29 | Rmd:537–538 "a simple stand-in for the network, not the network model: it adds the network to the same traits, so its difference from the baseline is what the network adds" | #223 "Model"; #214 "It says what the network adds beyond traits" | caption "from traits and the stream network together" | ok |
| 30 | Rmd:538–541 "Each of the three ... compared with two marks: the model fitted to that station's own record, the best these three could do, and the average of all stations, what knowing nothing gives." | #213 "Run", "Scores", candidate 1, Decisions (the benchmark) | — | ok |
| 31 | Rmd:549–550 "With air2stream, a reach with no station can only do worse; how much worse is what the test measures." | #213 "Problem" | #214 "Why the baseline matters" | ok |
| 32 | Rmd:551–552 "Most reaches are small streams and few stations sit on one, as in the basin above" | row 14, for the basin; #215 for the province; owner-approved | alt text "on its rivers and creeks" | ok |
| 33 | Rmd:553 "Nothing screens yet for one like the first figure's." (the 67 degree days dropped) | figure 1's caption; `edge_cost` (67.03) is now guarded and not printed, and its guard still holds "lowers the total from 1,460 to 1,393" (Rmd:210–211) | CLAUDE.md "it adds 67 °C-days" | ok |
| 34 | Rmd:554 "The thresholds. They exist for cutthroat trout in high-elevation Colorado streams ..." | #214 "In place"; the `.bib` title | — | ok |
| 35 | Rmd:557–558 "None has been found yet for other British Columbia species." | #214 "No growing-season degree-day requirement has been found yet for the other BC species" | — | ok |
| 36 | Rmd:562 "The fill borrows from its sub-drainage's other stations, so the recipe reads them all." | the `recipe` chunk's `pool`; `v$pool$prefix` "08E" (Rmd:585) | — | ok |

Nothing a removed line guarded is still printed: `share_river` went with its sentence (row 32), the season's
`n` was never printed (row 26), and `in_words()` had no caller (row 5).

## Notes, not findings

- **Two lines the delta wrote are over 120 characters** (Rmd:98 at 149, Rmd:305 at 121). Under the lintr
  settings this machine applies (`~/.lintr`; the repo tracks none) the article had 0 lints at `a3f15c92` and
  has these 2 at HEAD. Style, so not reported; both sit in chunks, so wrapping them leaves the word count alone.
- **`on_small < 0.25` has no lower bound**, so "few stations sit on one" would also pass with none. It is 1
  of 11 today and a station does not leave the bundle's fixed range, so this is a remark on the guard, not a
  defect.
- **`to_title()` (Rmd:65) and `n_state` (Rmd:401) are defined and never used**, at `a3f15c92` as at HEAD.
  They predate this delta.
