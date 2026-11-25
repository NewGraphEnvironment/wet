## Outcome

One pkgdown article, `vignettes/articles/segment-temperature.Rmd` ("Stream Temperature per Segment: How We Get
There"), says the per-segment temperature product is not built and shows how it gets there in four figures built
from committed bundles: one station's year with its gap filled and degree days adding up, the Bulkley's
main-flow tree with its federal temperature stations, the chain from stations to every reach drawn from two
tables, and the whole-station holdout as a sketch. The station-year was picked by a rule in the data script's
header (08EE012, Simpson Creek at the mouth, 2020), and the tests re-derive the pick from the bundled candidate
table. What was learned: the article's numbers were easy to hold to their source and its sentences were not.
Every review finding was a hand-typed fact restated in several places, or a sentence naming a wider set than
the code or the cited issue defines, and the issues the article describes were edited twice while it was being
built (kriging split out of the baseline; the roadmap reworded). The owner's wording rules, given after the
third review round, made the prose about the method: no piece assigned to anyone, sizes in place of counts that
move, models compared with station records, the method and the time step left open. Two defects found on the
way are their own issues: a reading that is not water, beside a gap, is carried into the fill (#222), and two
reads of the archive by `wet_temp_daily()` differ in the last bits (#224); both are in
[`research/station_temperature_fill.md`](../../../research/station_temperature_fill.md) and
[`research/station_water_temperature.md`](../../../research/station_water_temperature.md).

## Measurement

- **The pick.** Of the Bulkley's 11 temperature stations (25 in the 08E pool), 11 station-years have one
  interior gap longer than 2 days in 1 March to 30 November; 10 of the gaps are 3 to 5 days, and one qualifies:
  08EE012 in 2020, 29 days from 25 August, inside the growing season (28 April to 22 October). Filled, the year
  is 1,460.4 °C-days; unfilled, `NA`.
- **The reading before the gap is not water:** 15.5 °C after 9.6 °C, with air at 9.8 °C and no neighbour moving
  more than 0.5 °C. Hidden, the year is 1,393.4 °C-days: one reading is worth 67 °C-days, five times the 30-day
  holdout's mean error (12.8). It changed the article (the day is shown as read and said to be what it is).
- **The network fits whole.** The Bulkley's main-flow tree is 52,293 segments (27,858 first order); as one line
  per stream order simplified at 200 m it is 351 KB, so every order is drawn and the two bundles are 402 KB
  against the tests' 500 KB. The basin is the 35,191 watershed polygons under the main stem's code (12,141 km²),
  not its watershed groups: one tree segment each of two other groups carries the Bulkley's code.
- **`wet_temp_daily()` is not bit-reproducible:** two reads differed in `t_mean_c` on 22,201 of 47,430
  station-days, by 7.1e-15 °C at most. So a rebuilt bundle is held to `all.equal()`'s tolerance, not to its bytes.
- **One build in three drew a figure differently** once it had two legends with no order; a two-build
  comparison had passed by luck. The proof became three builds.
- **The review:** five rounds; 16 findings fixed (1 bug, 15 fragile). The loop ended by enumeration: 189 claims
  walked with none wrong, then the 36 changed after. Eight reviewer and reader agents ran in all.
- **Final state:** 541 tests, 0 failed, 9 skipped in files the branch does not touch; three pkgdown builds
  byte-identical; 1,198 words of body prose against a cap of 1,200.

Wrong turns kept in `findings.md`: the probe that shaped the rule read 8 of the basin's 11 stations; the basin
polygon first came from watershed groups and stopped on its own guard; a rebuild from an emptied cache rewrote
the bundle before the tolerance; a rerun stopped because the article was edited under it; a first control for
the broken-fact test failed for a reason that was not the article's.

## Evidence

`data/logs/220/temperature_vignette_data_*.log`, `data/logs/220/temperature_vignette_map_*.log` and
`data/logs/220/devtools_test_*.log` in the main checkout (gitignored); the five rounds' findings and their claim
tables are `review-round1.md` to `review-round5.md` here, with `review-220.md` (the plan review) and
`review-verdict.md`.

## Owed

- Once `https://www.newgraphenvironment.com/wet/articles/segment-temperature.html` is served, replace the opening line of #214's body with the link, and confirm the deploy on `gh-pages` names the merge commit.

Closed by: the pull request for branch `220-article-stream-temperature-for-every-rea`
