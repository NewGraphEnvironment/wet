# Code-check round 4: #27 Chinook revision

I worked on a copy (`scratchpad/r44IXubo/wet`, rsync of the staged tree; the working tree equals the index). I rendered it with `pkgload::load_all()` and `rmarkdown::render()`, saved the render environment, read the HTML prose and all five figures, and probed every claim against its object. The body prose is 535 words, measured by the vignette's own counter.

## Findings

- **[severity: bug, low]** vignettes/station-flow.Rmd:441 against :611-612 (and :476-477, cap_hydro :470-471). The limits bullet says 08EE003's "1981–2010 baseline rests on 1981–1998". That is true of the bars. It is not true of figure 3's "1981–2010" band and median line. `hb` takes every approved day in `baseline` years and has no 80% rule, so 08EE003's band also draws on 113 day-values from 2000–2010: Sep–Oct 2010 (61 days, 1 May–31 Oct season) and the 2000–2009 spot readings. Sep–Oct days rest on 19 years, not 18. The effect on the quantiles is small. Still, one label ("1981–2010") covers two different populations at one station, and the bullet's general wording ("Its … baseline") claims the narrower one for both. This is round 3's "fix one axis over": `y003`/`miss_003` pinned the year set for the window means only. Fix: restrict `hb` per station to the years in `qb` (`y003` for 08EE003), or scope the bullet to the window means.
- **[severity: fragile]** vignettes/station-flow.Rmd:611 and cap_recent :371, against `qb`. "08EE003 has a shorter normal" and "At 08EE003, the 1981–2010 baseline rests on 1981–1998" both imply that 08EE013's normal is full. It is not: 08EE013's spawning and fry migration baselines lack 1984 (29 of 30 years; migration has 30). No sentence states this and no guard checks it. `cd_baseline()` does not warn for it either: it warned only for 08EE003, so the `suppressWarnings()` comment is accurate. The figure 4 caption covers the blank 1984 cells in general terms only. Today the gap does not move a claim, because each of the 21 "nine in ten" bars beats at least 93.1% of its baseline years. But the asymmetric framing is unenforced. Fix: compute missing baseline years for every station and window (as `miss_003` does), then either state 08EE013's gap or assert it is empty for every station except 08EE003. That assertion would fail today.
- **[severity: fragile]** vignettes/station-flow.Rmd:249-250. "Buck Creek joins the Bulkley in the town" is a stronger location claim than "near Houston". Round 3 relaxed the only nearby guard to `< 10000` m for both stations (:197), so this sentence now has nothing closer than 10 km behind it. It is true today: 08EE013, HYDAT's "at the mouth", is 280 m from the Houston point. Fix: guard 08EE013's distance to `map$places` at about 1 km, or reword.
- **[severity: fragile]** vignettes/station-flow.Rmd:607 against cap_hydro :470 and :436. "A window counts when 80% of its days have flow" means "has a non-NA value" (R/wet_window_stats.R:181), and a 0 m³/s day counts. The hydrograph caption's "broken where a day has no flow" covers both missing days and zero days (`q_m3s > 0` at :436). So the phrase means two things in two sentences. No window day is zero today: the only zeros are 7 days in February 1986 at 08EE013. A dry summer day at Buck Creek would make the limits sentence read wrong. Fix: say "have a recorded flow" (or "a value"), and drop the zero case from "no flow" or name it.
- **[severity: bug, low]** research/station_flow_departure.md:64. "2022 was wet" is too broad. Spawning in 2022 was below the mean at both stations (08EE013 71%, 08EE003 99%). The vignette words this correctly: "the exception, with migration and fry migration above normal". Fix: "2022 was wet in migration and fry migration: …".

## Round 3 fixes reviewed

| Fix | Verdict |
|---|---|
| Partial-window bullet (`part`, `part_text`, `part_share`, `win_days`, `need_text`) | Correct. `win_days` matches `wet_window_stats()`'s inclusive window length: no full window reads as partial, and the baseline has no partial windows at either station (measured). `kf$period` is still character when `part` is built (the factor conversion comes later in the `recent` chunk). The rendered output "3 of the 30 bars rest on 80%–91%" matches 37/46, 85/93 and 46/55. `need_text` reads the default, and line 140 passes no `min_frac`. |
| `y003` / `base_003` / `miss_003` | Correct for the window means. `split()` would drop a window with no rows, but the `nb` guard above it already requires ≥ 10 years per window. `gap` ⊇ `miss_003`, so the figure 4 sentence cannot be empty. It reproduces one axis over in the hydrograph band (finding 1), and the per-station framing leaves 08EE013's 1984 unstated (finding 2). |
| Hydrograph NA grid (`grid`, merge, `floor_q` na.rm) | Correct. There are no duplicate station-dates (0) and no NA `q_m3s`. 08EE003 in 2025 now breaks at 1–8 Jul and 3–11 Aug (17 NA days in season), as the figure shows. 2026 ends on 30 Sep. |
| "near Houston" and the label move | Correct: distances are 280 m and 4,605 m, and `map$places` has one row. The Houston label now sits centred under Buck Creek's marker, between the two stations. The axis-over sentence is finding 3. |
| "bars" / "cases" | Correct: 24 = 2 × 3 × 4 bars, and 15 = 5 × 3 window-year cases. NEWS ("24 station-window values") and the research file ("15 pairs") agree. |
| Rounded median guard | Correct. `pct()` and the guard both use `round()`. Mutation proof below. |
| research "continuous … except two provisional gaps" | Correct: 08EE003 from 2010-09-01 to 2026-09-30 has exactly two gaps, 2025-07-01–08 and 2025-08-03–11. |

## Mutation table (each in its own rsync copy, rendered)

| Guard | Mutation | Result |
|---|---|---|
| `nrow(part) > 0` (:359) | data: filled 08EE003's two 2025 gaps | stops: `nrow(part) > 0 is not TRUE` [recent-data] |
| `length(miss_003) > 0` (:156) | data: 08EE003 given every day 1999-01-01–2010-08-31 (08EE013 × 4) | stops: `length(miss_003) > 0 is not TRUE` [stats] |
| y003 identical sets (:152) | data: dropped 08EE003 1990-08-02–09-15 (spawning only) | stops: `length(unique(lapply(y003, sort))) == 1 is not TRUE` [stats] |
| `round(med_range[2]) < 100` (:366) | code: `med_range[2] <- 99.6` | stops: `round(med_range[2]) < 100 is not TRUE` [recent-data] |
| control: old unrounded guard, same mutation | code: as above, guard `med_range[2] < 100` | **renders**, so the rounding is load-bearing |

Each render stopped on the named guard's own message, not on a neighbouring guard.

## Sentence table (rendered prose and captions, every sentence)

| # | Sentence (rendered) | Qualifier → where its meaning is set | Enforced? | Verdict |
|---|---|---|---|---|
| 1 | Chinook use the Bulkley River in summer. | "summer" → the three windows kept by `touches_ice()` (May 1–Sep 15) | filter + identity `stopifnot` (:57) | OK |
| 2 | Adults migrate upstream from May 1 and spawn from Aug 1, and fry move downstream from Jul 15. | dates → `w_start` from CSV rows; "upstream"/"downstream" → life-stage semantics (contract) | `stopifnot(identical(life_stage…))`, dates (:80) | OK |
| 3 | …over the last five years, 2022–2026, compares with 1981–2010 at two hydrometric stations near Houston. | "last five" → `recent` from `max(daily$date)`; "near" → < 10 km | :93 per-window end; :197 (280 m, 4,605 m) | OK |
| 4 | Chinook incubation (Aug 1 – Mar 31) and emergence (Apr 15 – Jul 7) reach into November–April… so they are left out. | → `out` = rows `touches_ice()` flags | definition | OK |
| 5 | Both stations are near Houston. | < 10 km | :197 | OK |
| 6 | Buck Creek joins the Bulkley in the town, and the Bulkley gauge sits downstream, so it measures Buck Creek's flow as well. | "in the town" → nothing tighter than 10 km; "downstream"/"as well" → containment | containment 0.99993 > 0.99; "in the town" unguarded | **FINDING 3** |
| 7 | Buck Creek drains 24% of the area above the Bulkley gauge. | FWA areas (566.9/2315.1 = 24.49%) | computed; FWA/HYDAT 0.997, 0.998 | OK |
| cap1 | …Buck Creek's catchment (567 km²) lies inside the Bulkley gauge's (2,315 km²), so the two records are not independent. | "inside" → intersection share | :195 | OK |
| 8 | These are the calls that produced the numbers. | recipe dates and arguments → typed | :80 window `stopifnot`; `stats=`, baseline and trend_start match :140, :83, :85 | OK |
| 9 | They need HYDAT, the water-temp-bc archive and the ECCC real-time feed… | `prov$ranges` sources: hydat, provisional, realtime | data | OK |
| 10 | Each bar is one window in one year. | per station facet row | figure | OK |
| 11 | Its height is the window's mean flow as a percentage of that window's 1981–2010 mean. | `pct = 100 + anomaly` (cd % of baseline mean); mean over days present | partial bars disclosed in sentence 31 | OK |
| 12 | Every window at both stations was below normal in 2023–2026. | "normal" → baseline mean; `low_years` = all `pct < 100` | definition; `length >= 2` | OK |
| 13 | That is not simply a typical year falling under a mean that wet years pull up. | median < mean as printed | `round(med_range[2]) < 100`, mutation-proved | OK |
| 14 | A median 1981–2010 year sits at 64%–96% of the mean, but 21 of the 24 bars from those years were drier than nine 1981–2010 years in ten, and 6 were drier than any. | "nine in ten" → `value < quantile(type 7, 0.1)`; at n = 18, type 7 admits 88.9% | `n_dec > 0`; measured: each of the 21 beats ≥ 93.1% of its years; "1981–2010 years" is 18 at 08EE003 (disclosed) and 29 at 08EE013 spawning/fry (not disclosed) | OK (margin); see FINDING 2 |
| 15 | The lowest was spawning at Bulkley River near Houston in 2024, at 19% of normal. | `which.min(kr$pct)` over all 30 | definition (18.53%) | OK |
| 16 | 2022 was the exception, with migration and fry migration above normal at both stations. | `up_years`, `up_both` | `length(up_years) == 1`; `up_both` non-empty | OK |
| 17 | For each window and year, the two stations' bars fall on the same side of normal in 15 of 15 cases. | `agree` over window × year | definition | OK |
| 18 | That is partly by construction, because one catchment holds the other. | containment | :195 | OK |
| cap2a | Mean flow in each Chinook window, 2022–2026, as a percentage of its 1981–2010 mean (solid line, given in m³/s in each panel). | `ref$label`, `signif(…, 2)` | computed | OK |
| cap2b | The dashed line is the median 1981–2010 year. | `linetype "22"`; `median_pct` | figure | OK |
| cap2c | At 08EE003, the 1981–2010 baseline rests on 1981–1998: no window in 1999–2010 has 80% of its days. | `y003`, `miss_003`, `need_text` | identical-sets and `miss_003` guards, mutation-proved | OK for 08EE003; implicit contrast is FINDING 2 |
| 19 | The same five years, day by day. | `recent` | definition | OK |
| 20 | The grey band is the middle half of 1981–2010 flows on each day, and its line is the median, not the mean. | `hb` = approved days in `baseline` years, no 80% rule | literal true; population differs from bars at 08EE003 | **FINDING 1** |
| cap3 | Daily flow, May to October, 2022–2026 (lines, broken where a day has no flow), over the 1981–2010 median day and middle half (drawn only on days with at least 10 years). The Chinook windows run beneath. Log scale. | "no flow" → NA grid + `q_m3s > 0`; "10 years" → `n >= min_baseline` (n = years; 0 duplicates) | grid merge; definition | OK; "no flow" vs "have flow" is FINDING 4 |
| 21 | The same departures for every year since 1981, to put the last five in context. | `heat` from `stats` year ≥ 1981 | definition | OK |
| 22 | 08EE003 has no window with 80% of its days in 1999–2010. | `gap` ⊇ `miss_003` | non-empty through the `miss_003` guard | OK |
| cap4 | Window mean flow above or below its 1981–2010 mean, in %. Blank cells have under 80% of their days, or none. | `min_frac`; NA class not drawn | `nb` guard (no anomaly NA, 0 rows) | OK (covers 08EE013 1984 and 2016 blanks) |
| 23 | The slope of each window's departure, from 1981 and from 2000, for the window mean and its lowest seven-day mean. | "lowest seven-day mean" → `min7`, 7 consecutive present days | R/wet_window_stats.R:201 | OK |
| 24 | Of 24 slopes, 2 are significant at p < 0.05, all of them negative. | `tr`, `sign_text` | no NA p (measured) | OK |
| 25 | Chance alone would give about 1, but the tests are not independent: fry migration shares 38 of its days with spawning, and one station drains into the other. | `shared`; containment | `shared > 0` | OK |
| 26 | At 08EE003, "from 2000" starts in 2011. | `start_003` | `all(start_003 > 2000)` | OK |
| cap5 | Theil-Sen slope… from 1981 and from 2000. Filled where the Mann-Kendall p is below 0.05. | `tr$sig` | definition | OK |
| 27 | The latest years are provisional. | `n_prov` | `n_prov > 0` | OK |
| 28 | Approved HYDAT flows end in March 2025, so 2 of the five years shown rest on provisional flows that may still be revised. | `hydat_end` (2025-03-04 / 03-02); `frac_provisional` = 1 for every 2025 and 2026 bar | measured | OK |
| 29 | Some bars have days missing. | `part` | `nrow(part) > 0`, mutation-proved | OK |
| 30 | A window counts when 80% of its days have flow. | `formals(wet_window_stats)$min_frac`; "have flow" = non-NA, 0 counts | default used at :140 | OK; wording is FINDING 4 |
| 31 | 3 of the 30 bars rest on 80%–91% of their days, where the record has gaps: Bulkley River near Houston in 2025 (migration, spawning and fry migration). | `part_share`, `part_text` | measured 37/46, 85/93, 46/55 | OK |
| 32 | 08EE003 has a shorter normal. | `miss_003` | `length > 0`, mutation-proved | OK; contrast is FINDING 2 |
| 33 | Its 1981–2010 baseline rests on 1981–1998. | `base_003` | true for window means | **FINDING 1** (band) |
| 34 | No window in 1999–2010 has 80% of its days. | `miss_003`, identical sets | guarded | OK |
| 35 | The windows come from the literature, not from observation. | CSV source column | `identical(src, …)` | OK |
| 36 | NGE's life-history table cites Gottesfeld and Rabnett (2007) for all three, though its fry migration citation is carried over from a neighbouring watershed's row. | "neighbouring watershed" → note "the other area in the template"; knowledge's table at c97c4d0 has only BULK and MORR (Morice, which joins the Bulkley at Houston) | `grepl("other area")` + one source key | OK |
| 37 | Cached inputs. HYDAT release 2026-07-17… retrieved 1 October 2026; life-history table at commit c97c4d0… Map layers from the Freshwater Atlas (fwapg) and BC Geographic Names… | `prov`; data-raw/station_vignette_map.R (BC outline is `fwa_bcboundary`, also FWA) | provenance | OK |

## Restatements

| File | Claim | Verdict |
|---|---|---|
| NEWS.md #27 bullet | nested catchments; three open-water windows; all below the 1981-2010 mean in 2023-2026; 21 of 24 station-window values drier than nine baseline years in ten | OK |
| README.md:4 | map; last five years against 1981–2010 in the open-water Chinook windows; daily hydrograph; departure since 1981; trends | OK |
| CLAUDE.md vignette sentence | three open-water Chinook windows, last five years against 1981–2010, two data-raw scripts | OK |
| research "Chinook open-water windows" | window dates; 24 values, 21 < q10, 6 < min (named correctly); lowest 19%; 126–206%; medians 64–96%; 1981–1998 (18 years) in all three; spot values 2000–2009; two 2025 gaps; 37/46, 85/93, 46/55; 567 and 2,315 km², 24%, 0.997 and 0.998; 15 pairs; 24 slopes, 2 significant (08EE013 spawning mean, 08EE003 migration mean, since 2000); 38 of 55 days | All OK except "2022 was wet" (FINDING 5) |

## Convergence

Every sentence and caption is enumerated above, along with the four restating files. Five findings remain. None is a wrong number. Three come from one root: round 3 pinned the qualifier for the object a sentence sat next to (window means, a 10 km radius, the bars), while the same word also describes a neighbouring object built from a different population (the band, the confluence sentence, 08EE013's baseline). Finding 4 is the same "one phrase, two meanings across sentences" pattern. Finding 5 is a restatement that overgeneralises.
