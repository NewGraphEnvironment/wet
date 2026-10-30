# Code-check round 2 (#149)

Diff: `git diff 14fc428...HEAD -- . ':(exclude)planning'` at 1089be0. Rendered a copy of
`vignettes/segment-discharge.Rmd` (the installed bundles are byte-identical to `inst/vignette-data/`),
purled it and probed the values behind each sentence; ran the duckdb group recipe and the
`wet_segment_monthly()` recipe as written against the live build (both work, `INSTALL httpfs; LOAD httpfs;`
in one `dbExecute()` is fine, 30,037 BULK rows in 2.7 s); `pkgdown::check_pkgdown()` clean; no duplicate
chunk labels; the `#what-is-a-window` anchor exists on the live comparison article; no remaining links to
`monthly-flow.html` outside the redirect.

## Checklist read

- code-check-r.md: read "Moving prose into a code chunk hides it", "A duplicate knitr chunk label fails the
  build", "`$` on a list partial-matches", "A `for` loop that builds `aes()`", "ggplot2 legends and labels",
  "`match()` treats NA as a matchable VALUE", "`summarise()` and `mutate()` evaluate in order", "Inside a
  dplyr verb, a column named like a local variable wins", "duckdb in R: … `LOAD icu`" (with its httpfs
  paragraph), "`ifelse()` with an all-NA test". 101 headings not read.
- code-check-shell.md: no shell in the diff; 0 read, 67 not read.
- code-check-spatial.md: read "`geom_sf(data = NULL)` draws nothing", "FWA main flow is not edge type 1000
  alone". 91 not read.
- code-check.md: the prose of all 14 H3s under `## Mechanisms` (table rows skipped); plus "Documentation
  Staleness", "An assertion that matches an interpolated value cannot see the claim around it", "A link to
  a repo-hosted artifact must be *tracked*", "Bare `y`, `n` … are booleans in YAML 1.1". 19 not read.

## Findings

- **[severity: bug]** vignettes/segment-discharge.Rmd:858-861 (guard 779-789) — "It is low from March to May
  and high in July and August … The shape holds at most of its gauges, not only at the median". The guard
  tests the two halves separately (`mean(g_low) > 0.5`, `mean(g_high) > 0.5`: 65.9 % and 67.7 %), but the
  shape the sentence names is the conjunction, and `mean(g_low & g_high)` is **45.9 %** of the 279 gauges
  (41.2 % under monthly-flow's old 3:4 spring). So "at most of its gauges" is false for the shape, and the
  inference built on it ("so it is the model's, not the placement's") rests on a premise the data do not
  support. Inherited from monthly-flow (which computed `shape_pct[["both"]]` and never guarded it), but the
  merged article prints it. Either guard `mean(g_low & g_high) > 0.5` (which fails) and reword (e.g. "low in
  spring at two thirds of its gauges and high in summer at two thirds"), or drop the claim.

- **[severity: bug]** vignettes/segment-discharge.Rmd:968-973 — "A Chinook window starts and ends mid-month …
  At the gauges that costs little where flow changes slowly: in migration and spawning the gauge's own
  monthly means and daily record agree within 3%." The article's own windows (line 522, and Table 2) are
  Migration **May 1 – Aug 1** and Spawning **Aug 1** – Sep 15: migration starts and ends on month
  boundaries, spawning starts on one. Migration's "Months vs days" is 0 % at both gauges because the window
  is whole months, not because flow changes slowly (May–July is the freshet, the fastest-changing flow of
  the year). The guard (`max(approx_w[good_w]) < 5`) cannot tell slow flow from a whole-month span, so it
  guards the number, not the reason. Inherited from monthly-flow ("The windows start and end mid-month"),
  still printed.

- **[severity: bug]** vignettes/segment-discharge.Rmd:862-864 — "At all 315 gauges its median monthly error
  is within ±10% in every month". New wording on this branch (monthly-flow said "Its median error is within
  ±10% in every month"). "At all 315 gauges" reads as a per-gauge claim, and per gauge it is false: only
  **28.9 %** of the 315 have a median monthly error within ±10 % (`tapply(bal$ratio_wb, station, median)`).
  The guard (`max(abs(wb_med)) < 10`) is on the median across gauges per month. Say "Over all 315 gauges,
  the median monthly error is within ±10% in every month".

- **[severity: fragile]** vignettes/segment-discharge.Rmd:812-814 — the round-1 rewording "at the 315 HYDAT
  gauges the balance is built on or the subset routed PCIC reaches" still says routed is scored where it
  reaches; it reaches 290 and is scored at 279 (the table, the lead and the figure all say 279). The next
  sentences correct it, so the paragraph is not wrong as a whole, but this sentence is. "or the 279 of them
  routed PCIC is scored at (below)" would match.

- **[severity: fragile]** vignettes/segment-discharge.Rmd:177-178 — "Few streams in BC have a gauge, so this
  gives every one of them an estimate". The article itself prints, two sections later, that 374,598 segments
  (7.6 %) have neither source. Defensible only if "stream" excludes the connectors and secondary channels
  those are (97.8 % of them by edge type); nothing guards it. Inherited from monthly-flow's "an estimate for
  all of them".

- **[severity: fragile]** vignettes/segment-discharge.Rmd:203-204 — "A month is the mean of its daily flow, and
  a day is routed day by day, so its days need not average to its month." Routing day by day is not what
  makes them differ: on the three Bulkley segments in the bundle, routed PCIC's published days average to the
  published month within rounding in every month except February (the 29 February fold), max 0.13 %
  (08EE013, Feb). The old segment-discharge text gave the cause ("Clamped daily and folded"). Low impact,
  but the stated reason is not the code's.

- **[severity: fragile]** vignettes/segment-discharge.Rmd:514 — "Three gauges on the Bulkley River": 08EE013 is
  Buck Creek at the mouth, on Buck Creek (the next sentence says it joins the Bulkley). monthly-flow said
  "Three gauges, one inside the next"; the branch added "on the Bulkley River". "in the Bulkley basin" would be
  true.

- **[severity: fragile]** research/discharge_publish.md:84 — the sentence now lists three readings (gauge
  values, the map's picks, the Bulkley months and days) from three data scripts, but keeps "both data
  scripts refuse unless this report names the live build", which meant segment_vignette_data.R and
  segment_vignette_map.R. monthly_vignette_data.R refuses the same way (`vd_published()`), so "all three"
  (or naming them) is the true count.

- **[severity: fragile]** CLAUDE.md:51 — "colours from `inst/cartography/wet_segment.csv` (`pick_source`,
  `gauge`, `flow_source`, `bulkley_map`)" reads as the complete set; the article also reads `segment_map`
  from that file and `hydrograph` from `inst/cartography/wet_station.csv` (and gq's main registry for
  streams, lakes, towns). The paragraph also lists the bundles it reads as segment_values, segment_map,
  monthly_values and monthly_map, while the setup chunk also reads the station article's `station_map.rds`
  (`$bc`), `station_daily.rds` and `life_history_bulk.csv`. Incomplete rather than wrong, but it is the
  record of what the article depends on.

## Checked and clean

- Round-1 fixes: "unbiased" is gone everywhere; the setup guard now compares `province_run`, and every pm/ps
  field it compares exists in both (no `NULL == NULL` vacuous pass, no `$` partial match: values printed).
- Every number in "Which value to use", the Bulkley section, the score table, the weakness bullets other
  than those above, the window section's other sentences and Limits matches its guard and the rendered
  table (n_both_src is the intersection: 3,377,037 + 4,529,939 − 4,532,843; daily rows = 365 × monthly
  segments).
- sk and g annual routed values are identical at all 290 (not only the same set), so the yearly and monthly
  rows score one set of routed values.
- `station_daily.rds` is HYDAT 2026-07-17, the release the citation names (unguarded, but true).
- `_pkgdown.yml` redirect form is pkgdown 2.2.0's, `url:` is set, and the articles index covers every
  vignette.
