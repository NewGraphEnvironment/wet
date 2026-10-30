# Code-check round 3 (#149): the terminating enumeration

Diff: `git diff 14fc428...HEAD -- . ':(exclude)planning'` at 0aebe14. Copied `vignettes/segment-discharge.Rmd`
to a scratch dir, purled it and ran it against the installed bundles (all guards pass), saved the workspace
and probed every value behind a sentence. Rendered the copy as well (renders; body prose 1,805 words under the
2,000 cap; no duplicate chunk labels; every `ps$`/`pm$`/`pub$` field the Rmd reads exists by its exact name).
Also read `R/wet_flow_window.R`, `R/wet_segment_monthly.R`, `R/wet_segment_daily.R`, `R/wet_cv_folds.R`,
`R/wet_share_fit.R`, `R/wet_shape_fit.R`, `scripts/segment_output.R`, `scripts/wb_shape_daily.R`,
`data-raw/segment_vignette_data.R`, `data-raw/segment_vignette_map.R`, `data/checks/segment_output_20260717.txt`,
`data/checks/wb_validation_aet-cfu_20260717.txt`, research/discharge_publish.md's routed-days section, and the
fit's `cv_shape_daily.rds` (for `leak_down`).

## Checklist read

- code-check.md: the prose of all 14 H3s under `## Mechanisms` (table rows and evidence blocks skipped), and
  "An assertion that matches an interpolated value cannot see the claim around it". 22 other headings not read.
- code-check-r.md: "Moving prose into a code chunk hides it", "A duplicate knitr chunk label fails the build",
  "`$` on a list partial-matches", "duckdb in R: … `LOAD icu`" (with its httpfs paragraph). 107 not read.
- code-check-shell.md: no shell in the diff; 0 read, 67 not read.
- code-check-spatial.md: none read this round (the spatial code is unchanged from round 2, which read
  "`geom_sf(data = NULL)`" and "FWA main flow is not edge type 1000 alone"); 93 not read.

## Enumeration

Verdicts: S = SUPPORTED, D = DEFINITIONAL, U = DATA-TRUE-UNGUARDED, F = FALSE/OVERSTATED. Lines are the working
tree's at 0aebe14.

| line | claim | guard / computation | verdict |
|---|---|---|---|
| 176-178 | wet publishes mean flow of FWA segments, m³/s, for year, month, day | three datasets (`product` chunk) | D |
| 178-179 | almost every stream gets an estimate | `sg$neither < 0.1 * sg$fwa` (7.6 %) | S |
| 180-181 | public at s3://…, bucket allows no listing | CLAUDE.md, bucket policy | D |
| 182-183 | manifest lists every part with rows, size, md5 | `pub$parts` columns `rows`, `bytes`, `md5` | D |
| 183-185 | 512 parts, 33.23 GB, built 24 Oct 2026 at b4bbc50 | inline from `pub` | S |
| 187-189 | segment_monthly: one row per segment, month, source with a value; 102,790,688 rows; month 0 annual | `sum(seg_parts$rows) == sum(reader$rows)`; rows/13 = 7,906,976 = `sum(n_src)` | S |
| 190-191 | watershed_monthly: per fundamental watershed, balance only | `all(ws_parts$source == "wet_balance")` | S |
| 192-193 | segment_daily is segment_monthly per day, 2,886,046,240 rows, Feb 29 folded | rows/365 = 7,906,976 = monthly segment-sources (measured); not guarded | U |
| 193 | one part per source and watershed group | `grepl("^[A-Z]{4}$", code)`; 445 parts, 445 distinct source-group pairs (measured) | U |
| 195 | two sources, both over 1981–2010 | `period_of()` both "1981-2010", `ps$routed_period` | S |
| 197-200 | PCIC runs VIC-GL on 0.0625° grid, observed climate, Raven | external (CLAUDE.md data sources) | D |
| 201-205 | fwapg fork places PCIC points; segment = upstream accumulation + share of own sub-basin | research/discharge_publish.md routed days: `max(Σ q_acc[upstream] + q_local · share, 0)` | D |
| 205-207 | month = mean of daily flow; days clamped and rounded one by one, Feb 29 folded, need not average to month | research/discharge_publish.md (#99): 4.614 % of segment-months differ, clamp and fold | U |
| 207-209 | annual = plain mean of 12 months; day weighting moves it ≤ 0.4 % on Bulkley segments | `pm$published_check` "routed month 0 = mean of fwapg's 12 months" differing 0 (guarded); `wtd_diff` computed | S |
| 211-217 | balance: P − AET from normals, upstream average, zone adjustment against HYDAT | `ps$keep_adjust` (limits chunk) | S |
| 218-220 | months from shares of the five most-like gauges, matched on elevation, location, snow | `pm$share_method == "donor"`, `pm$share_spec == "snow"`; k = 5 and static `elev, e_km, n_km, snowmelt_doy_50, swe_max` in wet_share_fit()/wb_validate.R (unguarded k) | S |
| 220-221 | each month into days by the same gauges' pattern | wb_shape_daily.R: donor, k = 5, same static set, same inverse-distance weighting | U |
| 221 | its days average to its months, months add up to its year | `pm$published_check` "balance months from the days = published months" differing 0; `bal_sum` all.equal month 0 | S |
| 221-222 | covers almost all of BC | 4,529,939 of 4,907,441 segments (92 %); unguarded | U |
| 243-244 | 3,374,133 segments have both | `n_both_src = sum(n_src) - n_with` (= segment report's "both sources") | S |
| 244-246 | pick once per segment, on annual flow, same source every month and day | scripts/segment_output.R (13 months); daily `pick` is the monthly rows' | D |
| 248-253 | pick rule: routed; balance under a fifth on own line; off line keep routed; whichever has a value | `ps$far_low == 0.2`; `routed_own_line_sql`; segment report own_line table | D |
| 255-259 | 4,907,441 segments; routed 3,154,131 (64 %), balance 1,378,712 (28 %; 222,906 far low), 374,598 neither | inline from `sg`; data script `pick_routed + pick_balance + neither == fwa` | S |
| 259-260 | neither: almost all connection lines and secondary channels with no watershed polygon | `no_lut_connector > 0.9 * neither` (97.8 %) | S |
| 260-261 | balance takes every segment with a value in the Liard | `liard$pcic_routed == 0`, `liard$wet_balance > 0` | S |
| 261 | where routed PCIC has none | guard tests pick, not presence; research: 35 Liard groups have no routed segment | U |
| 261-262 | 98 % of those in the four Nechako Reservoir groups | `nech_bal > 90`; `nechako` is 4 groups | S |
| 262 | where routed flow is far below the balance's | segment report: 59,814 of 59,821 flipped | U |
| cap_pick | main-flow rivers order ≥ 5, wider for higher orders | `mp$min_order`, `order_width` increasing, `mp$main_flow` | S |
| cap_pick | 6 % of BC's segments | `sum(mp$drawn)` **includes** `drawn[["none"]]`, which the next sentence says is not drawn; 5.80 % vs 5.77 %, both print 6 % | F (fragile) |
| cap_pick | the 315 calibration gauges; 1,557 segments of that order with neither not drawn | `nrow(sk)`; `rv` drops class "none" | S |
| 309-310 | reading a stream takes its linear_feature_id and nothing else | true for wet_segment_monthly(); wet_segment_daily() from the parts **requires** `groups` (R/wet_segment_daily.R:28) | F (fragile) |
| 310-312 | parts sorted by watershed group; naming the group skips the rest, seconds | R/wet_segment_monthly.R roxygen; `read-check` | D |
| 331-333 | returns linear_feature_id, month, q_m3s, source, the shape of wet_station_monthly() | roxygen @return | D |
| 333-334 | a segment a source lacks comes back with NA months, not missing rows | roxygen: "all 13 rows, with q_m3s NA" | D |
| 334-335 | wet_segment_daily() reads days; wet_flow_window() a window from days or months | roxygen; `vs$daily$days$basis == "daily"` | S |
| 342 | a group's default annual flow is one query | recipe run in round 2 (30,037 BULK rows) | S |
| 342-344 | scenario, forcing, source in the part's path, not the file | wet_catalog() key form `scenario=/forcing=/source=` | D |
| 359-361 | load into PostgreSQL; wet_segment_monthly() reads it given conn | wet_db_load(conn, catalog); roxygen | D |
| 368-370 | row carries runoff_mm (NA routed off own line), coverage = share the balance's inputs cover, period | segment_output.R:181-183: routed rows' runoff NA off own line (S); routed rows' `coverage` is NA on **every** routed row, unstated while runoff's NA case is stated | F (fragile) |
| 517 | three gauges in the Bulkley basin, one inside the next | `inside() > 0.99` twice | S |
| 517-519 | Buck joins at Houston; Houston just downstream measures it; Quick drains the whole basin above | `inside()`; snap table | S |
| 519-520 | Buck Creek and Quick are calibration gauges, Houston is not | `not_cal == "08EE003"` | S |
| 520-521 | Houston reads only in open water, no complete year 1981–2010 | `!any(table(...) == 12)`; months May–Oct | S |
| 523-527 | Chinook windows per Gottesfeld and Rabnett (2007), May 1–Aug 1, Aug 1–Sep 15, Jul 15–Sep 7 | `unique(ch$source)`; `span_of()` | S |
| cap_map | three catchments and areas 567 / 2,315 / 7,342 km²; Quick drains both | `area_of()` from `catch`; `inside()` | S |
| cap_hyd | each source's monthly flow beside observed monthly means 1981–2010; Houston months with ≥ 10 years of 20 days (May–October) | `obs` construction, `min_years`, `min_days`, `m003_text` | S |
| 619-621 | Buck peaks in May, so does routed, which overshoots: 23 against 16.4 May–June | `peak_month()` both 5; `fr$pcic_routed > fr$observed` | S |
| 621-623 | Quick: routed about a quarter short May–June (259 vs 338), high Jul–Aug | `-33 < q_short < -20` (−23 %); `hq(7:8)` | S |
| 625-628 | in-sample at Buck and Quick: own monthly pattern at balance's annual, about −12 % and −9 % every month | `diff(range(ratio_of)) < 0.02`, `-15 < wb_off < 0` | S |
| 629-630 | Houston: true estimate for an ungauged site, checked only in open water | not a calibration gauge (guarded); months May–Oct | S |
| 812-813 | routed closer at 168 of the 279 | `n_rt_closer > n_both / 2`; inline | S |
| 813-814 | month by month about the same | NSE within 0.05, gauge-months within 5 points | S |
| 814 | routed errs with the season | season guards (789-792) | S |
| 815-817 | scored on mean annual runoff and monthly means over complete years 1981–2010; balance at 315, routed at 279 | `n_bal_gauges == nrow(sk)`, `n_both_gauges == n_both` | S |
| 817 | error = modelled minus observed, % of observed | `100 * (mod / obs - 1)` | D |
| 818-820 | held out by sub-sub-drainage (08EE) | wet_cv_folds(): `substr(station, 1, 4)` | D |
| 820 | so a gauge's neighbours on the same river cannot vouch for it | wb_validation_aet-cfu_20260717.txt:10 "nested with upstream leak > 0: 18"; `cv_shape_daily.rds` `leak_down` TRUE at 71 of 315: same-river gauges in other sub-sub-drainages stay in the fit | F (fragile) |
| 820-823 | 290 with routed flow, less 11 under a fifth | `n_routed - length(far) == n_both_gauges` | S |
| score caption | error at calibration gauges, annual runoff and 12 monthly means | `score_tab` | S |
| note_score 1 | PCIC lists no calibration gauges, may be in sample | research (external) | D |
| note_score 2 | NSE definition, 1 perfect, 0 flat line at annual mean | `wet_nse(x, x) == 1`, `wet_nse(x, mean) ≈ 0` | S |
| note_score 2 | Moriasi bands 0.75 / 0.65 / 0.50 | `nse_rating()` test | S |
| cap_err | median and middle half by month, % of gauge's 1981–2010 mean; balance at 315, routed at 279; ±20 % | `sm`, `n_bal_gauges`, `n_both_gauges`, `err_cut` | S |
| 861-862 | routed low Mar–May, high Jul–Aug | `smv(3:5) < -10`, `smv(7:8) > 10` (−11.1, −12.2, −17.2; +19.9, +13.0) | S |
| 862 | as if its melt started late and ran on | interpretation | D |
| 862-864 | each half at most of its gauges (66 %, 68 %), not only the median | `mean(g_low) > 0.5`, `mean(g_high) > 0.5` | S |
| 865 | so it is the model's, not the placement's | inference, unmeasured; the reason monthly-flow gave ("a misplaced outlet changes one gauge's size, not the season") was dropped | U |
| 866-868 | over all 315 the median monthly error within ±10 % every month; in no month half within ±20 % | `max(abs(wb_med)) < 10` (7.0); `max(within) < 50` (47.3) | S |
| 869-870 | where flow peaks May–June the balance more often falls short than overshoots | `mean(pk$ratio_wb < 1) > 0.5` (57.6 % of 243) | S |
| 871-873 | 31 % at headwater (no other gauge upstream) vs 18 % nested | `mae_nest < mae_head`; wet_cv_folds() nesting definition | S |
| 873-875 | 40 % under 100 km² vs 20 % over 1,000 km² | `mae_small > mae_large` | S |
| 875-876 | by monthly score still the stronger source under 1,000 km² | `nse_g(gw) > nse_g(gr)` for `<100`, `100-1000` (0.61 vs 0.43, 0.82 vs 0.80) | S |
| 877-878 | zone 24, Southern Thompson Plateau, 9 gauges average 93 % | `worst %in% c(15, 17, 23, 24)`, `sum(zone_mae > 2 * mae) == 1` | S |
| 878-880 | runoff a small remainder of P, so a small ET error is large in runoff | research/water_balance_method.md reasoning | U |
| 881-883 | routed stronger over 1,000 km² and at lake outlets | NSE guards (0.92 vs 0.87, 0.95 vs 0.93, 0.92 vs 0.73) | S |
| 883-885 | routing follows the lake; donors matched without regard to it | static predictors carry no lake term (wet_share_fit()); Raven lake routing external | D |
| 886-887 | no value at 25 gauges, most in the Liard | `mean(startsWith(none, "10")) > 0.5` (19 of 25, all 10A–10C) | S |
| 979-981 | from monthly means every window day takes its month's mean | wet_flow_window() `basis = "monthly"` | D |
| 982 | costs nothing where a window covers whole months, **as migration does** | windows are inclusive at both ends (wet_flow_window() @param `windows`), so May 1 – Aug 1 includes Aug 1, one August day; the guard `identical(end, "08-01")` reads `08-01` as exclusive. Cost 0.06 %, prints 0 % | F (fragile) |
| 982-985 | little where the cut month changes slowly: spawning ends mid-September, agree within 3 % | `approx_w[good_w] < 5` (3.0 %); Sep first half at 0.91 and 0.95 of Sep mean against July's 1.37/0.65 (measured, unguarded) | S |
| 985-987 | fry migration takes the second half of July as the freshet recedes; months overstate by about a quarter | `late_july < 0.9`; `20 < approx_err < 30` (27 %, 24 %); July carries 25 and 23 of the points, Sep 1–7 under 2 (measured) | S |
| 989 | the days remove that cost where a source's daily pattern is right | interpretation | D |
| 990 | routed's fry-migration error shrinks at both gauges | `abs(err routed_daily) < abs(err routed)` in the poor window | S |
| 990-992 | balance days at Buck fall with the gauge's, its own pattern; only the annual error remains | `abs(move_balance - move_obs) < 1`, `abs(err - wb_off) < 2` (exactly equal in all three windows, measured) | S |
| 992-994 | at Houston the borrowed pattern keeps more water into late summer; balance several times the gauge in both late-summer windows | `move_balance < 0`, `< half of move_obs`; `b003 > 200` (+479 %, +356 %) | S |
| 994 | that error is ours | attribution | D |
| window caption | daily record = window mean per year with enough days; months vs days = same years' monthly means | `ws`, `yrs`, `om` | S |
| 1028-1029 | besides the Liard, no routed value in a few northern and border basins, only some on outer islands | `length(no_rt) > 1` (800, 945, 990); islands from research | U |
| 1030-1032 | adjustment kept by decision; on headwaters it does not beat raw P − AET; pooled zones get none | `keep_adjust`, `!gate_pass`, `pooled_variant == "none"` | S |
| 1033-1035 | of the 374,598 neither, 369,217 have no lut watershed | data script `no_lut <= neither`; segment report "without (no value from either source)" | S |
| 1036-1039 | in-sample at gauges; 08NM240/241 share the mean of theirs; near-alike watersheds get almost the same | CLAUDE.md donor rule; inverse-distance construction | D |
| 1040-1042 | a day right only as far as the pattern; scores above are of the months; daily pattern scored where fitted | wb_shape_daily.R scores it held out | D |
| 1043-1044 | Houston's monthly means cover May–October, from 19 of 1981–2010 | `m003_text`, `n003` | S |
| 1045-1046 | **the scores are province-wide, split by basin size and lake outlets, not by region** | the article's own zone bullet (877-880) scores one hydrologic zone, the Liard bullet scores by region, and 871-873 splits by nesting; no guard | F (bug) |
| 1050-1052 | flows, routed gauge values, map picks are the published product's, read 2026-10-24 at b4bbc50 | setup identity guards (`map`, `pm`, `ps`) | S |
| 1052-1054 | routed held equal to fwapg's table, Bulkley days routed again | `ps`/`pm` `published_check` all `differing == 0` (289 gauge segments; 3,480 months; 1,095 days) | S |
| 1054-1056 | balance months and days made again from the fit at 08EE004 and 08EE013 | `pm$shape_stations`; checks compare 2 watersheds, 26 months, 730 days (measured; counts not tied to the names in the Rmd) | U |
| 1056-1057 | the build's own report covers the rest | `pub$report` | D |
| 1057-1058 | province counts from the segment table the build was cut from | data script `vd_segment_report()` | S |
| 1058-1059 | gauges' daily flows are HYDAT's | `dh <- daily[daily$source == "hydat", ]` | S |
| 1059-1061 | scores: routed as published, balance held out on HYDAT 2026-07-17, observed runoff | `ps$hydat_release`; `pm$hydat_release` identical | S |
| 1090 | DOI resolves to latest release | concept DOI (wet_software_cite comment) | D |
| 1094-1114 | Data line: PNWNAmet, fwapg at 7c30f58, HYDAT release, climr normals, CGIAR held no lower than Fu–Budyko, GLO-90, ERA5-Land snow for shares, BC Hydrologic Zones, Gottesfeld and Rabnett | `ps$aet == "cfu"`, `pm$share_spec == "snow"`, `ps$routed_commit`, `ps$hydat_release` | S |

Counts: SUPPORTED 63, DEFINITIONAL 24, DATA-TRUE-UNGUARDED 11, FALSE/OVERSTATED 6 (1 bug, 5 fragile).
104 rows.

Docs outside the article:

| file | claim | verdict |
|---|---|---|
| CLAUDE.md:51 | section list, 279/315, recipes, bundles, setup refusal, 2,000-word cap | true (measured above) |
| CLAUDE.md:51 | colours from wet_segment.csv (5 layers) and wet_station.csv (`hydrograph`) | true but omits `gq_reg_main()` (`streams_all`, `lake`, `town`, Rmd:491-493), so the list reads complete and is not; round 2's finding, half fixed |
| research/discharge_publish.md:84 | "(two bundles since the monthly-flow article merged into it)" | false: the three readings land in three bundles (`segment_values.rds`, `segment_map.rds`, `monthly_values.rds`), one per data script; before the merge it was two |
| research/discharge_publish.md:84 | "each of its data scripts refuses unless this report names the live build" | true of the three that read the parts (all call `vd_published()`); the article's other data scripts (`monthly_vignette_map.R`, `station_vignette_*.R`) read no parts and do not refuse |
| research/water_balance_method.md:81 | "the seasonal shape the segment-discharge article attributes to PCIC's model" | true (Rmd:865) |
| README.md Learn more | yearly, monthly, daily; which source; how to read; a year at three Bulkley gauges; how well it matches | true |
| _pkgdown.yml | redirect `articles/monthly-flow.html` → `articles/segment-discharge.html`, `url:` set, index without monthly-flow | true |

## Findings

- **[severity: bug]** vignettes/segment-discharge.Rmd:1045-1046 — "The scores are province-wide, split by basin
  size and lake outlets, not by region." Moved from monthly-flow, where the scores were monthly only and split
  only by area and lake. In the merged article the weakness bullets score the yearly error **by region**: zone
  24, the Southern Thompson Plateau, 9 gauges at 93 % (877-880), and the Liard (886-887), and split it by
  nesting (871-873). The article contradicts itself, and no guard covers the sentence. True if narrowed to the
  monthly scores ("The monthly scores are province-wide, …") or reworded to name the yearly splits.

- **[severity: fragile]** vignettes/segment-discharge.Rmd:818-820 — "each Water Survey sub-sub-drainage … is
  left out of the fit in turn …, so a gauge's neighbours on the same river cannot vouch for it." Blocking is by
  the first four characters of the station number (`wet_cv_folds()`), so a gauge on the same river in another
  sub-sub-drainage stays in the fit. The shipped fit's report counts 18 nested gauges with an upstream gauge in
  another fold (`data/checks/wb_validation_aet-cfu_20260717.txt:10`, median leak 0.35 of the basin), and the
  fit's `cv_shape_daily.rds` has `leak_down` TRUE at 71 of 315. That is why #102 added a leak-free pool.
  Inherited from main's segment-discharge. "neighbours in the same sub-sub-drainage cannot vouch for it" is true.

- **[severity: fragile]** vignettes/segment-discharge.Rmd:982 (guard 959-965) — "That costs nothing where a window
  covers whole months, as migration does". `wet_flow_window()` takes `start` and `end` as "both inclusive"
  (R/wet_flow_window.R:24-25), so Migration, May 1 – Aug 1, is May–July plus Aug 1. The cost is 0.06 % and prints
  0 %, so the number holds, but the reason does not, and the guard (`identical(end, "08-01")`, with the comment
  "covers whole months") treats the end as exclusive. Same mechanism as round 2's finding at this sentence: the
  guard pins the window bounds, not what they mean. "covers whole months but a day" would be true.

- **[severity: fragile]** vignettes/segment-discharge.Rmd:309-310 — "reading a stream takes its
  `linear_feature_id` and nothing else." That holds for `wet_segment_monthly()`, where `groups` is optional.
  `wet_segment_daily()`, shown three paragraphs later, requires `groups` when it reads the parts
  (R/wet_segment_daily.R:23-30). The sentence came from monthly-flow, which read months only; the merged article
  publishes and reads days too. "reading a stream's months takes …" would be true.

- **[severity: fragile]** vignettes/segment-discharge.Rmd:368-370 — "a row carries `runoff_mm` … (NA for a routed
  row off its watershed's own line), `coverage`, the share of that area the balance's inputs cover". It names
  runoff's NA case, but every routed row's `coverage` is NA (scripts/segment_output.R:23-25, 183:
  `coverage = NA_real_`), so a reader expects a value there. "(on the balance's rows)" would be true.

- **[severity: fragile]** vignettes/segment-discharge.Rmd:279-284 (cap_pick) — "%s of BC's segments" is
  `pct(100 * drawn / sg$fwa)` with `drawn <- sum(mp$drawn)`, which includes `mp$drawn[["none"]]`, the 1,557 segments
  the same caption says are not drawn. It prints 6 % either way (5.80 % against 5.77 % for the drawn ones), so
  nothing on the page is wrong today. The population is the wrong one, though, and a build with more "none" could
  round differently. `sum(mp$drawn[names(mp$drawn) != "none"])` matches the sentence.

- **[severity: fragile]** research/discharge_publish.md:84 — "(two bundles since the monthly-flow article merged
  into it, #149)". The three readings the sentence lists come from three bundles, one per data script
  (`segment_values.rds`, `segment_map.rds`, `monthly_values.rds`), and before the merge it was two. "each of its
  data scripts refuses" holds for the three that read the parts, not for `monthly_vignette_map.R` or the
  station scripts, which read none. "three bundles" and "each script that reads the parts" would be true.

- **[severity: fragile]** CLAUDE.md:51 — the colour sources are now listed as the two CSVs. The article also
  draws streams, lakes and towns from `gq::gq_reg_main()` (Rmd:72, 491-493), so a list that reads as complete
  still is not. This is round 2's finding, fixed for the CSV layers only.

Checked and clean: round 2's fixes (the shape bullet now says "Each half" and prints both shares; "Across all 315
gauges its median"; "routed PCIC at 279 of them"; "almost every one of them"; the routed-days reason now gives
the clamp and fold, matching research/discharge_publish.md's #99 section; "in the Bulkley basin"); the window
section's poor-window reason (July carries 25 and 23 of the 27 and 24 points); every printed number matches its
guard and the rendered tables.
