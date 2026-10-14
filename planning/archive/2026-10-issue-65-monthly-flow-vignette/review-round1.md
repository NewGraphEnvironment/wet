# Code-check round 1: branch 65-monthly-flow-vignette-explore-use-and-qa

Reviewer: subagent, 2026-10-13. Method: read the branch diff and the code it calls. Ran the vignette's
code (`knitr::purl`, with `load_all` on a scratch copy of R/, inst/ and vignettes/) against the
committed `inst/vignette-data/monthly_values.rds`, printed every number the prose interpolates, and
ran `tests/testthat/test-vignette_data.R` (7 blocks, 0 failed, 0 errors). Checked that nothing under
R/, scripts/, data-raw/ or data/checks/ changed between the recorded build commit 0924aa0 and HEAD
(it did not).

## Findings

- **[bug] vignettes/monthly-flow.Rmd:381-382, 426-430**: the excluded gauge-month counts are taken over
  a different set from the one the sentence describes. `n_low_obs` and `n_zero_wb` are counted over
  all 315 gauges (`m <- g[g$month > 0, ]`), but the sentence goes straight on to "the figure and table
  use the 3,226 gauge-months both sources have, at 279 gauges". On the bundled data the article prints
  46 and 122, while among the 279 gauges the figure uses the counts are 33 and 89
  (279 x 12 = 3,348; 3,348 - 33 - 89 = 3,226). A reader who checks the arithmetic gets
  3,348 - 46 - 122 = 3,180, not 3,226. Either count over `m$station_number %in% both$station_number`,
  or word the counts as being over all 315 gauges. Also add a `stopifnot` that the counts reconcile
  with `nrow(both)`.

- **[bug] vignettes/monthly-flow.Rmd:268-271**: the article says that at Quick (08EE004) "both sources
  come close to the gauge in May–June", then prints 338 m³/s observed, 258 routed and 257 balance.
  Both sources are 24% low. Two sentences earlier, at Buck Creek, a 44% shortfall is called "hardly
  a freshet", and the article's own scoring band is ±20%. No `stopifnot` backs this claim: the
  `bulkley-numbers` chunk asserts the Jan–Apr and Jul–Aug claims at Quick but nothing about May–June.
  The claim is wrong for the bundled numbers. Rewrite it (for example, both about a quarter low) and
  assert it.

- **[fragile] vignettes/monthly-flow.Rmd:463, 467, 491**: the article says "the water balance reads high
  from December to May", set against routed in "the two sources fail in different seasons". The
  assertion `all(c(12, 1:5) %in% wb_high)` checks only that those months are high, not that the
  others are not. On the bundled data the balance median is also positive in July, August and
  September (+1.2%, +5.1%, +4.6%), and August's +5.1% is close to May's +7.6%. So the claim reads as
  a seasonal pattern that the guard cannot catch failing, and that the data only partly supports.
  Either narrow the wording or also assert that the months outside December–May are lower, or within
  some margin.

- **[fragile] vignettes/monthly-flow.Rmd:477-478, 510-511**: `n_long` is said to count "calibration
  gauges with 40 or more complete years in 1951–2012 and routed flow on their segment". `lp` also
  drops the `far` gauges, so the 113 leaves out 2 gauges that do have routed flow (122 period gauges,
  7 without routed, 2 far). This is a small mis-description of the set the number is computed over,
  in the same section that elsewhere spells out "less N whose segment carries under 20%".

Nothing else found:

- Unit conversions are consistent: mm↔m³/s through `days[month + 1]` with 365.25 for month 0, matching
  `wb_cv_lib.R` and `wet_station_monthly()`.
- The held-out recompute guard (`identical(cv$ann, cvr$cv_ann)`) is exact.
- The `wet_values_compare()` expected-count guard counts keys on either side, so a missing or extra
  published row cannot pass.
- The recipe check compares the full rows.
- The `rr_all` parse fails closed on NA.
- The `vignette_data_lib.R` move leaves no dangling variable in `segment_vignette_data.R`.
- The test file's assertions are non-vacuous and pass.
