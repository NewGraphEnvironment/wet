# Findings — Article: stream temperature for every reach, from stations to a network model (#220)

## Issue context

**If we do it:** anyone can see in four pictures what growing-season degree days are, where we have temperature and where we do not, and how the pieces get from stations to every reach. **If we never do:** the only public account is the roadmap issue, which is text, assumes the vocabulary, and is written for a modeller.

## Problem

The roadmap (#214) tracks what is being finished and in what order. It is the right place for status and the wrong place to learn the idea: it has no figures, and a reader has to know what a holdout, an open-loop fill or network kriging is before the first section. The functions have reference pages and the methods have research files, but nothing shows how they fit together.

## Proposed approach

One article, `vignettes/articles/segment-temperature.Rmd`, answering the reader's questions in order, each with one figure:

1. **What are growing-season degree days, and why do they matter for fish?** One station's year: the observed days, a gap, the fill across it, and degree days accumulating, with the season's start and end marked.
2. **Where do we have temperature, and where not?** One basin on a map: the stream network, the gauges on it, and the reaches with no station.
3. **How do we get from stations to every reach?** The whole chain as one diagram: observations, fills, catchment traits, air temperature, the baseline, a network model, degree days at every reach. It marks what exists, what is being built and what a network model adds, and where a process model that already exists (PCIC's channel-scale output, #219) sits beside it as a comparison and as a source of future change.
4. **How will we know it works?** The holdout as a sketch: hide a station, predict it from traits, from its nearest neighbours in trait space and from the network, and compare each with the station's own fit.

It closes with what is not known yet: the error at the stations themselves, and the thresholds: growing-season degree-day thresholds exist for cutthroat trout (from Colorado subspecies, applied to westslope cutthroat in the Elk Valley reports), and none has been found yet for the other BC species.

How it is built:

- **Figures come from wet's own functions and a committed bundle** built by a `data-raw/` script, so the site build needs no database. Map layers go through `scripts/vignette_map_lib.R`, with towns labelled and the river named.
- **The diagram is drawn in code,** not pasted in as an image.
- **Plain language.** Each term is defined where it first appears: reach, air2stream, open-loop, holdout, kriging.
- **It says what it stands on:** `fwapg` (Simon Norris) for the network, the Nechako and Skeena network models by their published memos, `gsdd` for the degree-day rule, PCIC for the process model. Citations from a `.bib`, as the other articles do.
- **No status and no counts that move.** The article links #214 for what is done and what is next, and carries no checklist.
- **One address, revised in place.** The page is `articles/segment-temperature.html`, the twin of `segment-discharge`, and the address does not change. This first version is titled for what it is ("Stream Temperature per Segment: How We Get There") and opens by saying the product is not built yet. Once it is, the same page is rewritten to say what the product is and how well it does.
- **Which basin and which station** are picked by a rule written in this issue's plan (a basin the network check has run clean on, a station with a complete season and a real gap), not by eye.

## Out of scope

- Results from the baseline or from the PCIC comparison. The article describes the tests; scores go in when #213 and #219 have run, as a revision.
- A second basin.
- The network model itself.

## Done when

- The article is on the site with its four figures, and rebuilds identically from the bundle.
- A reader with none of our context can say, after reading it, what goes to a network model and what comes back.
- #214 links it at the top.

Relates to #214, #213

## Packages on the machine that built the bundles (2026-11-25)

Installed before Phase 1: gsdd 0.3.0.9009 (was missing), gq 0.25.0 (was 0.22.0), fresh 0.57.0 (was 0.55.1).
Already there: cd 0.6.13, sf 1.1.2, ggplot2 4.0.3, ggrepel 0.9.7, duckdb 1.5.6, tidyhydat 1.0.1, R 4.5.2.

## The pick (Phase 1)

`Rscript data-raw/temperature_vignette_data.R`, run log `data/logs/220/temperature_vignette_data_1.log`
(71 s from an empty cache; a second run left `temperature_values.rds` at md5 2a43ca3b, unchanged).

- **The pool is 25 stations, the basin 11.** The archive lists 27 stations whose number starts `08E`; two
  (08EC003, 08EF006) have no day in 2002–2025 that passes `wet_temp_daily()`'s rules. Eleven snap under the
  Bulkley's main stem (watershed code 400.431358): three on the Morice side (08ED001, 08ED002, 08ED004) and
  eight `08EE`. The plan's probe had read only the eight `08EE` stations; the rule, run on all eleven, lands
  on the same year.
- **Three basin stations are not fitted** (08ED004, 08EE008, 08EE025: each began in January 2025 and has
  under 365 observed days), so they can be drawn but not filled.
- **Eleven station-years have one interior gap longer than 2 days; one qualifies.** Ten of the gaps are 3 to
  5 days, under the rule's 7. The eleventh is 08EE012 (Simpson Creek at the mouth), 2020: 25 August to
  22 September, 29 days, inside the season `gsdd::gss()` finds (28 April to 22 October). Filled, the year
  gives 1,460.4 °C-days; unfilled, `NA`. The rule did not need its 60-day widening.
- **`gsdd::gsdd()` returns no season dates** (the plan said it would); `gsdd::gss()` does, and the script holds
  the sum of its seasons to `wet_temp_gsdd()`'s value and to the daily means summed over each season.
- **The open-loop series** is rebuilt with the fit's own `wet_a2s_run()` over the station's record and held
  to the fit's `rmse_open` (0.958 °C), so the bundled `s_open_c` is the fit's `S`.

### The day before the gap is not a water temperature

| day (2020) | 08EE012 mean | min | max | hours | air (ERA5-Land) |
|---|---|---|---|---|---|
| 22 Aug | 9.36 | 8.80 | 10.04 | 24 | 9.90 |
| 23 Aug | 9.56 | 8.86 | 13.77 | 24 | 9.75 |
| 24 Aug | 15.54 | 12.37 | 17.43 | 21 | 9.78 |
| 25 Aug | (gap begins) | | | | 8.87 |

Over 22 to 24 August none of the five neighbours observed that week moved by more than 0.5 °C (08ED001
12.2 to 12.3, 08ED002 12.7 to 12.8, 08EE004 14.6 to 14.8, 08EE013 13.4 to 13.1, 08EE020 7.75 to 7.73), and
air fell. The creek's daily minimum rose 3.5 °C in a day, to above the day's mean air. The last hours of
23 August and the 21 hours of 24 August read as a sensor leaving the water before the record stops:
`wet_temp_daily()`'s range cannot catch that in summer, as its documentation says.

What it does to the figure: the fill starts from every observed day, so it enters the gap at 14.6 °C and
decays to meet 8.76 °C on 23 September, where open-loop air2stream reads 8.8 to 8.1 °C across the same days.
The first two weeks of the fill are too warm, and the year's degree days with them. As the plan decided, the
rule is not bent and the day is shown as read; the article says what it is. Ours: a limit of the fill (an
unscreened reading beside a gap is carried into it), to be filed as its own issue.

## The map bundle (Phase 2)

`Rscript data-raw/temperature_vignette_map.R`, run logs `data/logs/220/temperature_vignette_map_*.log`.

- **The basin is the watershed polygons under the Bulkley's code, not its watershed groups.** 52,293 tree
  segments carry a code under 400.431358: 30,046 in BULK, 22,245 in MORR and one each in KISP and ZYMO, so
  the groups' polygon is not the basin's (a first version that used it stopped on its own guard). The 35,191
  fundamental watershed polygons under the code union to one part with no holes, 12,141 km², in 6.5 s.
- **Every stream order fits.** The tree as one MULTILINESTRING per order, xz-compressed:

  | simplified at | orders 1 and up | 2 and up | 3 and up |
  |---|---|---|---|
  | 100 m | 436 KB (55,541 vertices) | 144 KB | 61 KB |
  | 200 m | 351 KB (44,544 vertices) | 104 KB | 39 KB |
  | 300 m | 322 KB (40,697 vertices) | 90 KB | 31 KB |

  At 200 m (about a pixel of a 7 in map of a 165 by 226 km window at 150 dpi) and every order, the map bundle
  is 393 KB and the two temperature bundles 402 KB together, under the test's 500 KB. So the cut is order 1:
  no reach is left undrawn. Whether that many lines read at the published width is Phase 4's figure review.
- **The tree by order:** 27,858 / 11,401 / 5,926 / 3,659 / 1,663 / 989 / 253 / 544 segments at orders 1 to 8;
  24,675 km in all. All eleven stations sit on a tree segment.
- **Which tree:** the build database's table has four columns and no comment, 4,510,368 rows (the count of
  the fork's 2026-10 build) and no upstream-area column, so the additive-function step of the network check
  has not been run on this copy. The bundle records the row count and an md5 of the basin's ordered ids.
- A rerun reports every layer identical and leaves the file as it is.

## What the suspect day adds (from the review, A1)

The values bundle carries a second fill with 24 August 2020 hidden (`year$t_edge_c`, `edge`), a comparison
beside the pick. Across the 29 gap days the fill sums to 320.7 °C-days, the fill without that day to 259.7
and open-loop air2stream to 245.0. The year's degree days are 1,460.4 as read and 1,393.4 with the day
hidden: one reading is worth 67 °C-days, five times the 30-day holdout's mean degree-day error (12.8).

## The article (Phase 3)

- **The recipe returns the bundle.** The article's `recipe` chunk, run as written by the data script (the
  whole 08E pool read again from the archive, coordinates from `tidyhydat::allstations`, which differ from
  HYDAT's by under 5e-6°), returns 08EE012's 2020 day for day and its 1,460.4 °C-days.
- **`wet_temp_daily()` is not bit-reproducible.** Two reads of the same archive on 2026-11-25 differed in
  `t_mean_c` on 22,201 of 47,430 station-days, by 7.1e-15 at most; air from `cd` was identical. The daily
  mean is duckdb's `avg()` over the hourly means, taken in parallel in no fixed order. Ours, and the
  function's to fix (filed as its own issue). So a rebuild from an emptied cache is equivalent, not identical:
  the data script compares to `all.equal()`'s default tolerance and says so in its header. Proof:
  `data/logs/220/temperature_vignette_data_6.log` (cache emptied, recipe returned the bundle, file left at
  md5 940b6ec3). The run before it (`_5.log`) stopped on the script's own guard, because the article was
  edited while it ran.
- **The picked stream's placement:** Simpson Creek joins Kathlyn Creek, which joins the Bulkley River; the
  station is 4 km north-west of Smithers (computed from the two bundles).
- **Thresholds, read in their sources before citing:** Coleman & Fausch 2007 (the field study; abstract):
  900–1,200 degree days best, 800–900 recruitment in some years, under 800 unsuitable, for greenback and
  Colorado River cutthroat. The two Harmer Creek reports (Thorley & Branton 2022; Hocking et al. 2022) apply
  Coleman & Fausch's relations to westslope cutthroat in the Elk Valley.
- **One reference added to the Zotero group library:** PCIC's channel-scale output (dataset, May 2026), key
  `pacificclimateimpactsconsortium2026VICGLRavenMBCn`. The `.bib` has 25 entries, each with a url or doi.
- **Words:** 1,066 of body prose against the cap of 1,200 set before drafting.

## Proof (Phase 4)

- **Two builds, one page.** The branch installed to a scratch library, then
  `pkgdown::build_article("articles/segment-temperature", lazy = FALSE)` twice: the four figures' md5s are
  the same both times (chain a08cf584, holdout 7d49826c, map 4aa2197c, year 4567d27f) and the two HTML files
  are byte-identical. No `footnote-ref`; no unresolved citation; each of the four figures has alt text.
- **Each guard stops the build on a broken fact.** In a scratch worktree, rendered after
  `pkgload::load_all()` so the broken copy is the one read:

  | broken | stop message |
  |---|---|
  | the bundled degree-day total raised by 5 | `isTRUE(all.equal(max(yr$dd, na.rm = TRUE), gsdd)) is not TRUE` |
  | the map's network says ten reaches hold a station | `net$with_station == n_st is not TRUE` |
  | a dashed arrow leaves the baseline in the chain's table | `identical(edges$style == "dashed", edges$from %in% comp) is not TRUE` |
  | the reading before the gap made an ordinary day | `jump > 5 is not TRUE` |

  The intact control renders. (A first control failed in the `versions` chunk for a reason that is not the
  article's: `utils::citation("wet")` under `load_all()` could not find the package in a worktree whose
  directory was not named `wet`. In one named `wet` it renders, and the pkgdown builds read the installed
  package.)
- **A cold read.** A reader given only the built page's text (an agent with none of the repo's context, told
  to open one file) answered the issue's question correctly: into a network model go the network, the
  stations and their filled records, the traits, air temperature at every reach and the baseline's result;
  back come temperature with its uncertainty at every reach, and degree days with the uncertainty carried
  through. It also listed what it had to guess at. Fixed from its list: `wet` and "reach" explained in the
  opening; "the most a reach with no station can have" (which read as contradicting the network model)
  reworded; the two fitted network models set beside "not built yet" with what is left open; three baseline
  versions named where the text had two; the province's stations told apart from the basin's eleven; the
  process model defined; why the figure keeps the total with the suspect reading. Left: the season's 5 and
  4 °C limits (cited, not explained), which score counts as success (the baseline's rule is not written
  yet), and orange meaning "the subject" in three figures.
- **Figures against the cartography self-review**, read from the built PNGs: the map fills its frame; the
  legend, the keymap and the scale bar each have a corner over dimmed land outside the basin; the basin is
  the only undimmed area; all eleven stations are countable once labels were made to keep clear of them;
  every drawn mark is in the legend or the caption. Every stream order stays drawn: at this size the
  first-order lines read as texture and the larger rivers stand out by weight.
- **The rendered page was sent for a read on a phone** before the pull request.
- **The whole suite** (`NOT_CRAN=true devtools::test()`, `data/logs/220/devtools_test_1.log`): 541 tests in 69
  files, 0 failed, 3,606 expectations passed, 9 skipped. The skips are in `test-wet_bcenv.R` (1),
  `test-wet_bcwatertool.R` (1), `test-wet_station_daily.R` (2) and `test-wet_station_snap.R` (5), none in
  the file this branch changes. `lintr` on the two existing files the branch edits finds nothing new against
  `origin/main`; `pkgdown::check_pkgdown()` reports no problems; `devtools::document()` changes nothing.

## The branch review and the wording pass (2026-11-25)

Four review rounds, each by a reviewer with none of this session's context, findings in `review-round1.md` to
`review-round4.md`.

| Round | Findings | Fixed | Inside the previous fix? |
|---|---|---|---|
| 1 | 7 (1 bug, 6 fragile) | 7 | — |
| 2 | 4 fragile | 4 | yes: the README line still made the claim round 1 had narrowed in the article |
| 3 | 3 fragile, and the mechanism with a table of 163 claims | 3 | yes: the lake guard could fail one way only; a reworded aside had gained an unmeasured "usually" |
| 4 | none: 189 claims re-walked, 169 ok, 20 weak, 0 wrong | leftovers cleared | no |
| 5 | 2 fragile, on the 36 claims changed after round 4 | 2 | yes: three unrendered copies kept wording the pass had replaced |

- **The mechanism (round 3):** the article's numbers have a producer and its sentences do not. A fact typed by
  hand sits in up to nine places (prose, caption, alt text, registry label, chain box or arrow, README,
  `CLAUDE.md`, script header, comment) and a correction reaches the copies the fixer remembers. What closed it:
  the map bundle records the thresholds its caption quotes, the chain's arrows are asserted where the prose
  restates them, and for the sentences that restate #213, #223 and #219 the claim table is the control, to be
  walked again whenever one of those bodies is edited.
- **The baseline issue moved during the build.** #213 was edited at 18:47 UTC to split kriging out to #223; round
  2 caught the article still calling it one of the baseline's versions.
- **One build in three drew the holdout sketch differently** once it had two legends: with no `order`, ggplot2
  places guides by a hash that differs between sessions. A two-build comparison had passed by luck; the proof is
  now three builds, and round 4 restored the defect (1 in 4 differed) and the fix (0 in 4).
- **The owner's wording rules** (given in chat after round 3) were applied in one pass: the prose is about the
  method, assigns no piece to anyone, gives sizes in place of counts that move ("tens of thousands of reaches",
  "about a dozen" stations), compares models with station records, and leaves the method and the time step open.
  He approved the heading "How will it be tested?" and a line on small streams.
- **A second cold read, as an outside modeller** deciding whether to reply: it would, cautiously. From its list:
  kriging read as the method already chosen (the article now calls it a simple stand-in for the network in the
  test); the test read as built around air2stream (any model is now said to be compared on the same hidden
  stations' daily temperature and degree days); "the logger" for a federal station; "two have been fitted"
  reading as the only two. One point is the test's and not the article's: the fill borrows from neighbouring
  stations, so a hidden station's readings may sit inside its neighbours' filled records. That is for the
  baseline issue, put to the owner.
- **Words:** 1,199 against the cap of 1,200.
- **How the loop ended:** by enumeration. Round 4 walked 189 claims and found none wrong; round 5 walked the 36
  changed after it, and its two findings were fixed with their copies swept by grep (`review-verdict.md`).
  Eight reviewer and reader agents ran on this task: the plan review, two cold readers and five review rounds.
- **After the last fix:** the whole suite again (`data/logs/220/devtools_test_2.log`: 541 tests, 0 failed, 3,618
  passed, the same 9 skips), `pkgdown::check_pkgdown()` clean, three pkgdown builds byte-identical, 1,198 words.
- **The owner read the rendered page** and asked for one more thing, that the basin be said to be an example of
  a province-wide aim; he then asked for the pull request.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| The plan took the season's dates from `gsdd::gsdd()`, which returns `year` and `gsdd` only | `gsdd::gss()` returns each season's `start_dayte` and `end_dayte`; its `gsdd` is held to `wet_temp_gsdd()`'s |
| `vm_tree()` took the basin's polygon from its watershed groups and stopped on its own guard: BULK, KISP, MORR and ZYMO hold 94,575 tree segments, 52,293 under the Bulkley's code | The basin is the fundamental watershed polygons under the main stem's code |
| A rebuild from an emptied cache rewrote the values bundle: every numeric element differed in the last bits | `wet_temp_daily()`'s parallel `avg()`; the script's `same()` compares with `all.equal()` |
| The empty-cache rerun stopped with "commit vignettes/articles/segment-temperature.Rmd first" | The article was edited while the run was in flight; rerun after the commit, touching nothing |
| Two pkgdown builds gave different md5s for `holdout-1.png` after a second legend was added | `guides(fill = guide_legend(order = 1), colour = guide_legend(order = 2))`; three builds compared from then on |
