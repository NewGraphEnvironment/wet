# Code-check round 2 (#65): branch 65-monthly-flow-vignette-explore-use-and-qa at 13a9d1b

Method: the vignette was purled and run (pkgload::load_all on a `git archive HEAD` copy in the
scratchpad). Every inline value and asserted claim was then recomputed over the set its
sentence names. The data script, the lib refactor, the segment script's use of it, the test,
the CSV and CLAUDE.md were read against wet_values_compare(), wet_flow_validate(),
wb_cv_lib.R and wb_output.R. The bundle was built at 0924aa0, and no R/, scripts/ or data-raw/
file has changed since, so it is not stale. All five published_check rows reconcile with their
sources: 3480 = 12 x (289 gauge segments + 08EE003's), 2 watersheds held, 26 = 2 x 13.

All four round-1 fixes hold. Their numbers: 290 - 11 = 279 gauges; 3348 - 33 - 89 = 3226
gauge-months; the 89 zero-balance months fall at gauges whose held-out annual is 293 mm or
more, so they really are zero shares; Quick is -23.7% and -23.9%; the Dec-May minimum of 7.3%
is above the Jun-Nov maximum |5.1|%; n_long = 113 with 2 far-low gauges dropped.

## Findings

- **[bug] vignettes/monthly-flow.Rmd:344-348**: same mechanism as round 1. The sentence reads
  "In fry migration ... Even there the approximation is smaller than either source's error ...,
  which is as large as `pct(err_of("routed")[which.max(...)])` ... and
  `pct(err_of("balance")[which.max(...)])`". The maxima are taken over all six window rows, not
  the window "there" names. The balance's +317% is 08EE003 *Spawning*; its worst Fry-migration
  error is +261% (08EE003). The routed +74% does fall in Fry migration (08EE003), but only by
  coincidence: nothing pins it. Either take both maxima over `win$window %in% poor_w`, or
  reword so the maxima are over all windows.

- **[bug] vignettes/monthly-flow.Rmd:337-338**: "The first two numeric columns of the table
  below separate that approximation from model error. The first is the gauge's own daily
  record ...". In the window table the first numeric column is `Years` (line 353), so the
  first two are Years and Daily record. The sentence should name the columns, as "Daily record
  and Monthly, day-weighted", or say "the first two flow columns".

- **[fragile] vignettes/monthly-flow.Rmd:430-434, guard at 392**: the prose says
  "`n_routed` gauges where it has flow, less `length(far)` ... That leaves `n_both_gauges`
  gauges". That is the subtraction n_routed - length(far) == n_both_gauges, and nothing asserts
  it. `n_both_gauges` is counted from `both`, which drops a gauge whose months are all excluded
  (all under 1 mm, or a zero balance in every month). Such a gauge would make "290 less 11
  leaves 279" false while every guard still passes. It holds today (279 = 279). Add
  `n_routed - length(far) == n_both_gauges` to the stopifnot at 392. Likewise "where it has
  flow" counts `!is.na(routed_mm)`, not `> 0`; 0 gauges have routed month 0 = 0 today, also
  unasserted.

- **[fragile] vignettes/monthly-flow.Rmd:530-531, guard at 585-588**: "The period explains part
  of the summer excess and little of the spring shortfall." The guard pins only
  `spring_5112 < -10`; nothing compares the spring shift with the summer one or bounds it.
  Today spring moves from -22.7% to -18.5% (4.1 points, 18% of the shortfall) and summer from
  +14.1% to +9.6% (4.5 points, 32%). "Little" is defensible now, but if spring_5112 were -11
  against an 8110 value of -23, the sentence would be false and the article would still build.
  Assert the "little", for example that the spring shift is a smaller fraction of its
  shortfall than the summer shift is of its excess, or under a stated bound.

- **[fragile] vignettes/monthly-flow.Rmd:644**: the Validation prose hardcodes
  `data/checks/discharge_publish_20260717.txt`. The bundle already carries that path
  (`prov$published$report`, which equals it today), so this is one fact stated twice: rebuilt
  on a newer release, the prose would cite the old report. Use `` `r prov$published$report` ``.

- **[fragile, minor] vignettes/monthly-flow.Rmd:279-280**: "08EE003 ... is seasonal and has no
  complete years". The bundled daily record (station_daily.rds) has 15 complete years for
  08EE003, 1971 and 2011-2024. It has none in 1981-2010, where it reads 4-7 days a year over
  2000-2009, and it is seasonal only in that period. The claim is true only "in 1981-2010",
  which is what excludes it from calibration. Qualify it.

- **[fragile, minor] vignettes/monthly-flow.Rmd:265, guard at 256**: "routed PCIC, which
  overshoots it" (the May peak) is asserted through `fr`, the May-June day-weighted mean, not
  through the May values the sentence is about. It holds: May routed is 27.9 against 22.0
  observed.

- **[minor] vignettes/monthly-flow.Rmd:515-517**: "reads low in March and April (median
  `pct(mean(smv(..., r_spring, "median")))`)" prints the mean of two monthly medians under the
  word "median". The values (-19.7, -19.4) make this harmless today. The same holds for July and
  August (+19.4, +17.2).

Nothing else found. Checked and found sound:
- The lib refactor: the segment script uses no removed name.
- vd_routed_check()'s default release is the same as before.
- The recompute matches wb_output.R.
- area_km2 equals upstream_area_m2 / 1e6, so the vignette's mm to m3/s conversions invert the
  data script's.
- The balance's months sum to month 0 exactly on all three Bulkley segments.
- The NSE medians given inline equal the group table's "All gauges" row (0.74, 0.81).
- The far set (11) matches the routed report's.
- r_closer is 10 months and includes May-September.
- The group-table claims hold.
