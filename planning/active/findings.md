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

## Errors Encountered

| Error | Resolution |
|-------|------------|
| The plan took the season's dates from `gsdd::gsdd()`, which returns `year` and `gsdd` only | `gsdd::gss()` returns each season's `start_dayte` and `end_dayte`; its `gsdd` is held to `wet_temp_gsdd()`'s |
| `vm_tree()` took the basin's polygon from its watershed groups and stopped on its own guard: BULK, KISP, MORR and ZYMO hold 94,575 tree segments, 52,293 under the Bulkley's code | The basin is the fundamental watershed polygons under the main stem's code |
