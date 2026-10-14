## Outcome

`vignettes/monthly-flow.Rmd` is the first look at months 1–12 of the published discharge product (#7). It covers:
- reading one segment's twelve months from the manifest's parts;
- both sources' hydrographs at three Bulkley gauges, with the Chinook windows and each window's flow as a day-weighted mean of monthly means, beside the gauge's daily record;
- scoring each source month by month at the shipped fit's calibration gauges.

Its data come from `data-raw/monthly_vignette_data.R`, which reads the published parts under the guards the segment data already used, now shared in `scripts/vignette_data_lib.R`. Every bundled published value is checked against its source. The held-out monthly balance is recomputed with `predict_cv()`, and the script refuses unless its annual equals the stored `cv_ann` exactly.

The gaps found became #67 (routed PCIC's seasonal shape, with a draft report to PCIC that has not been sent) and #68 (store the held-out monthly balance). The evidence went into #16 (snow in the shares) and #6 (which takes over the monthly scoring), and the period question is NewGraphEnvironment/fwapg#25.

What was learned about method: the article's numbers changed twice under review. First, its winter figures for the balance dropped the balance's own zero predictions. Second, it scored the balance only where routed PCIC exists. Both were filters judged neutral by argument. Recomputing each filter with and without it, recorded in `review-enumeration.md`, is what ended the review.

## Measurement

- **Water balance**, held out at 315 calibration gauges (3,780 gauge-months, HYDAT 2026-07-17, 1981–2010):
  - median error +8 % to +16 % January–May, within ±5 % June–December;
  - −67 % to −96 % in January–March at the 25 gauges routed PCIC does not reach (19 in the Liard);
  - zero held-out share in 123 gauge-months (36 in January);
  - below the gauge in its peak month at 69 % of the 243 gauges peaking in May or June (median −15 %);
  - median monthly NSE 0.71, matching `data/checks/wb_validation_20260717.txt`.
- **Routed PCIC** at 279 gauges, as published (1951–2012): −20 % in March–April, +19 % in July–August, median monthly NSE 0.81. On the shared 279 gauges, more of its gauges fall within ±20 % than the balance's in 10 of 12 months.
- **Period check**, at 113 gauges with ≥ 40 complete years in 1951–2012:
  - observed 1951–2012 against 1981–2010: −7 % in spring, +6 % in summer;
  - routed against the gauges' own 1951–2012 means: −19 % in spring, +10 % in summer;
  - so the period explains about 18 % of the spring shortfall and 32 % of the summer excess;
  - gauge by gauge, routed is low in spring at 66 % and high in summer at 63 %.
- **Basin size and lakes** (median monthly NSE, shared 279 gauges): routed beats the balance except below 100 km² (0.40 against 0.56). At lake outlets routed is 0.93 against the balance's 0.52.
- **Window approximation** (Buck Creek, Bulkley near Houston): day-weighted monthly means match the daily record within 3 % for migration and spawning, and differ by up to 27 % for fry migration, because late July runs below July's mean.
- **Wrong turns, kept:**
  - The first scores (balance +23 % in January, highest in January) were biased by dropping zero months and by a 1 mm cut.
  - "A misplaced outlet scales every month alike" was overstated, and was reworded to an argument from the median.
  - The first build failed because the reduced fit bundle keeps month 0 only in `output/`. Balance months are now recomputed where the bundle holds the watershed, and otherwise rest on the publish report.
- **The segment data refactor** rebuilt identical to the committed file, up to row order (its fwapg query has no `ORDER BY`).

No `research/` file: the article recomputes these numbers from the bundle at every build, and the verdicts live in #16, #67 and #6.

Closed by: the PR from branch `65-monthly-flow-vignette-explore-use-and-qa`
