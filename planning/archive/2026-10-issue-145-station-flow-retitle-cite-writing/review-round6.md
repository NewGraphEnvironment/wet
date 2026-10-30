# Review round 6: the revision in 7f80112 (#145)

## Checklist read

- code-check.md, `## Mechanisms`, the prose of each H3. Applied: "A proxy is not the property" (findings 1, 2), "A guard's scope, escape hatches, and remedies" (findings 1, 4), "One fact derived twice" (finding 1: the normal's years come from `qb` for the windows and from the raw daily table for the year figure).
- code-check-r.md index; full sections read for "Inside a dplyr verb...", "`paste()` with a zero-length argument" (not hit), "ggplot2 legends and labels" (not hit).
- writing.md: "State each claim by the code's definition", "Cut what serves the authors", "Name, link and cite the software", "Measure the simplification".
- Method: purled the Rmd into `/private/tmp/claude-501/-Users-airvine-Projects-repo-wet/a74fd527-b599-4433-8bfe-aca6f384c772/scratchpad/r6/` and ran it against the installed `wet` (its `station_daily.rds`, `station_map.rds` and `life_history_bulk.csv` md5s equal the source tree's), with probes appended; read `hydrograph-1.png` and `change-1.png`, and the rendered page's text.

## Findings

1. **[severity: high] vignettes/flow-departure-normal.Rmd:529–531 (`yr <- rbind(day_stats(h[h$year %in% baseline, ], ...` ). Rule: writing.md "State each claim by the code's definition"; code-check.md "A proxy is not the property", "One fact derived twice".**
   The year figure's 1981–2010 line at the Bulkley gauge is not the normal the article states. The revision dropped the old restriction to the window normal's years (`paste(station, year) %in% paste(qb$station_number, qb$year)`), so the daily line takes every day of record in 1981–2010. At 08EE003 that means 1981–1998, plus 127 days of 2010 (4 May to 31 Dec), plus 4 to 7 single days in each of 2000–2009 (spot readings). Measured:
   - Between 1 May and 15 September, 49 of the 138 days average more than the 18 years of the normal. Across those days, including the extra years moves the mean day by −4.8% to +54% against 1981–1998 alone.
   - The panel's tallest grey point, 89.4 m³/s on 22 May, is an artifact. That day averages 20 years, two of them single readings: 22 May 2002 at 311 m³/s and 22 May 2007 at 147 m³/s. On 23 May, with 18 years, the line drops to 68.1. The spike is visible in `hydrograph-1.png`. `top`, which sizes the strips, is also taken from it.
   - The opening says "At Bulkley River near Houston, the normal rests on 1981–1998", and the lead-in says "The same comparison across the whole year". This line rests on another set of years.
   - The guard at :537–538 checks only that window days are non-NA and that Jan–Mar is NA. Nothing checks which years the line averages.
   - The same mechanism, a per-day row count used as the test for "a period's line", also varies the recent line's years. At 08EE003, 1–8 July and 3–11 August average 4 years, with 2025 missing. The orange line jumps from 11.0 to 18.0 and 19.0 m³/s on 7–8 July, both 4-year days, then falls back to 13.9 on the first 5-year day. From 1 October onward, both gauges' recent lines are 2022–2025 only, because the record ends on 30 September 2026. The caption's "at least 4" discloses that the count varies, but not that the years change from day to day.
   Fix: restore the `qb` year filter for the baseline (and say so: "over the same years as each window's normal"). Either require all five recent years on window days, or state in the caption that the recent line averages four years where a year is missing. Then guard that the baseline line's years at each station equal `qb`'s.

2. **[severity: medium] :117–131 (change-data) and :305–307 (opening). Rule: code-check.md "A proxy is not the property"; writing.md "State each claim by the code's definition".**
   "90% range" and "for 4 of the 6 the whole 90% range is a drop" rest on a percentile bootstrap that is too narrow at n = 5. The sentence describing the method ("comes from resampling the years in each period") is accurate. The label "90%" and the opening's count are what overclaim.
   - With five values, resampling with replacement gives a variance of the mean (n−1)/n of the sample's. There are also only 126 distinct resamples, so percentile limits of a 5-year mean undercover.
   - Simulated with this exact method (5 lognormal "recent" years against 30 "baseline" years, sd 0.4 on the log scale, equal true means, 1,000 trials of 1,000 draws), the "90%" range covered the truth 82.3% of the time.
   - The count of 4 hinges on Buck Creek's migration window, whose upper limit is −3.5%. A Welch t 90% interval on the same data puts it at −60.0% to +1.9%, and a t interval on log flows at −51.0% to +3.2%. Under either, the count is 3 of 6 (Bulkley migration and fry migration cross zero under all three).
   - The count is stable across seeds: 4 under each of seeds 1–200. So this is the method, not Monte Carlo noise.
   Fix: either use an interval that holds its coverage at n = 5 (a t interval on log flow, or a studentised bootstrap), or keep the method, drop "90%" from the prose in favour of "the middle 90% of resamples", and take the count out of the opening.

3. **[severity: medium] :694–695 (Data list). Rule: writing.md "Name, link and cite the software" (data credit; OGL-BC requires attribution); a regression of round 3's verified line.**
   The revision replaced five Data lines with one: "Streams, lakes and catchments: the Province of British Columbia's Freshwater Atlas, through DataBC". It dropped "Place names: BC Geographic Names, through DataBC", whose data is still used:
   - The map's only label, Houston, is `map$places`, from `WHSE_BASEMAPPING.GNS_GEOGRAPHICAL_NAMES_SP` via `vm_places()` (bcdata).
   - The prose "joins the Bulkley River in the town" and "at Hazelton, about N km north-west of Houston" are computed from `map$towns`, from the same source.
   The keymap's province outline (`fwa_bcboundary`) is now covered only implicitly by "Freshwater Atlas", and gauge locations only by the HYDAT line; both are tolerable. Round 3's enumeration (review-round3.md:136) had verified the place-names line as correct. Fix: restore it.

4. **[severity: low] :534–538 and the caption at :549–550. Rule: code-check.md "A guard's scope, escape hatches, and remedies".**
   "so the Bulkley gauge, with too few winters on record, has no winter normal" is guarded on 1 January to 31 March only. The figure shades November to April as the ice months. In that shading, the Bulkley's grey lines run from 1 to 13 November, and April is empty. A reader takes "winter" from the shading, and the line enters it. Fix: either guard and say "no normal from mid-November to April", or define winter in the caption as the months the guard checks.

5. **[severity: low] :548 (`labs(y = "Mean flow (m³/s)")`). Rule: writing.md "State each claim by the code's definition".**
   The axis title says mean flow over a panel where half the lines are median days. "Daily flow (m³/s)", the caption's own phrase, covers both.

6. **[severity: low] :543–548 (the scale).** The old figure removed y ticks among the window strips ("they are rows, not flows"). The new linear scale does not, and the strips occupy y < 0. At the current data, `pretty()` puts its first negative break (−10 at Buck Creek, −30 at the Bulkley) beyond the drawn range, so no negative flow tick prints. Nothing guards this: a refresh in which the strips reach a full break step below zero (when `top` is about 5 × the step) prints a negative discharge tick. Fix: `scale_y_continuous(breaks = function(l) { b <- scales::extended_breaks()(l); b[b >= 0] })`.

`data-raw/vignette_bib.R` (the url/doi stop): Clean. The guard applies to every entry, matches the two-space field indent that `toBibtex()` and the biblatex export both write, and fails loudly. It could not be run, because Better BibTeX is down, which is accepted.

## Enumeration

Each claim or mark: its set, then its guard or source, and whether the guard covers the set.

### Opening (:305–310), rendered: "Over 2022–2026, mean flow in every timing window at both gauges was below its 1981–2010 normal, by 25% to 62%, and for 4 of the 6 the whole 90% range is a drop. Every window at both gauges was below normal in each year from 2023, and 21 of those 24 window means were drier than nine 1981–2010 years in ten. At Bulkley River near Houston, the normal rests on 1981–1998, the years with enough record."

| claim | set | guard / source | covers? |
|---|---|---|---|
| "Over 2022–2026" | `recent` = last five years of the data | `recent <- (last_year-4):last_year`; every window over in the last year (:107) | yes |
| "mean flow in every timing window at both gauges was below its normal" | all 6 rows of `chg`, mean of 5 recent window means / mean of `qb` | `stopifnot(nrow(chg) == 6, all(chg$pct < 0))`; `length(r) == 5` and `mean(b) == ref$mean_q` per row | yes (re-derived: −29.0, −62.3, −51.4, −24.8, −57.6, −37.7) |
| "by 25% to 62%" | range of abs(pct) over 6 rows | `chg_range`, `pct()` rounding | yes (24.83→25, 62.33→62) |
| "for 4 of the 6 the whole 90% range is a drop" | rows with `hi < 0` | `n_clear` computed; seed-stable (seeds 1–200 all 4) | the count matches the figure, but "90%" overclaims coverage (finding 2) |
| "Every window at both gauges was below normal in each year from 2023" | each year 2023–2026, every window × station | `low_years` all-below, `identical(low_years, min:last_year)`, a full table per year | yes |
| "21 of those 24 window means were drier than nine 1981–2010 years in ten" | `low` rows, value < q10 | `n_dec == sum(share_wetter >= 0.9)`, `n_dec > 0` | yes (unchanged since round 5) |
| "the normal rests on 1981–1998" | 08EE003 `qb` years, the same in every window | `y003` identical across windows; `miss_003` non-empty | yes for the window normals; **false for the year figure's daily normal** (finding 1) |

### "What did the year look like?" (:513–549)

| claim / mark | set | guard / source | covers? |
|---|---|---|---|
| Lead-in: "The same comparison across the whole year, day by day: the last five years' mean and median day against 1981–2010's" | per-day mean/median over years | `day_stats()` | **no** at 08EE003: other years than the normal's (finding 1) |
| Caption: "mean (solid) and median (dashed) day" | `stat` mean/median | `scale_linetype_manual(mean = solid, median = "22")`, legend "Mean day"/"Median day" | yes |
| "over 1981–2010 (grey) and over 2022–2026 (colour)" | `period` base/recent | `pal_period` (grey `median` registry colour, orange `below`) | colours yes; years: base at 08EE003 mixes in 2000–2010 days, recent Oct–Dec is 2022–2025 (finding 1) |
| "A 1981–2010 line is drawn on days with at least 10 years of record" | rows per station-doy ≥ `min_baseline` | `out[out$n < need, ] <- NA` | yes (n counts rows; one row per year per day) |
| "a 2022–2026 line on days with at least 4" | rows ≥ `length(recent) - 1` | same | yes |
| "so the Bulkley gauge, with too few winters on record, has no winter normal" | 08EE003 base, winter | guard: all NA for doy < 1 April | partial: the line runs 1–13 Nov in the shaded months (finding 4) |
| "The shaded months, November to April, are when the gauges can read under ice" | `ice` rects, 1 Jan–30 Apr and 1 Nov–31 Dec | literal dates; matches `ice_months` (:52) | yes |
| "The chinook timing windows run beneath as bars" | `strip`, from `windows` | `windows` start/end as dates; labelled by `window` | yes (drawn 1 May–1 Aug, 1 Aug–15 Sep, 15 Jul–7 Sep, as in the figure) |
| Mark: grey solid peak at the Bulkley, 89.4 m³/s on 22 May | — | — | artifact of two single-day 2002/2007 readings (finding 1) |
| Mark: orange solid step at the Bulkley, 7–8 July | — | — | year-set change (2025 missing) (finding 1) |
| Mark: y-axis "Mean flow (m³/s)" | both mean and median lines | `labs()` | no (finding 5) |
| Mark: y ticks | ≥ 0 at the current data | `pretty()` only | unguarded (finding 6) |
| Guard: "summer normal and recent line through every window" | all of `yr`, 1 May–15 Sep | `!anyNA(...)` | yes (no caption claim rests on it) |

### "How much has mean flow changed?" (:552–566)

| claim / mark | set | guard / source | covers? |
|---|---|---|---|
| "Each point is the change in a timing window's mean flow, from its 1981–2010 mean to the mean of 2022–2026" | `chg$pct` = 100·(mean(r)/mean(b) − 1) | change-data | yes (the 08EE003 baseline is 1981–1998, stated in the opening) |
| "Its range comes from resampling the years in each period" | independent bootstrap of `b` and `r`, ratio of means, 5–95% percentiles | change-data | the description is accurate; the coverage is not 90% (finding 2) |
| "with only five recent years, one of them wet, the ranges are wide" | `up_years` | `length(up_years) == 1` (:242) | yes for "one year with a window above normal" (2022, 4 of 6 windows; its spawning windows were below); "wet" is loose but backed by that guard |
| Caption: "at each gauge (point), with a 90% range ... (bar); the vertical line is no change" | `geom_point`, `geom_errorbarh(lo, hi)`, `geom_vline(0)` | figure code | marks yes; the "90%" label as finding 2 |
| Mark: facets per window, y = station short names | `by_window`, `station_label` | yes | yes |
| Mark: points coloured "below" for all six | — | all `pct < 0` guarded | yes |

### Recipe paragraph (:577–597)

| claim | set | guard / source | covers? |
|---|---|---|---|
| "These calls produced the window statistics, with normal and departure from ... cd" | `wet_window_stats(stats = "mean")`, `cd_baseline`, `cd_anomaly` | matches the stats chunk; windows' dates guarded identical (:88–89) | yes; it does not claim to cover the change figure or the daily lines, so no gap |
| "They read HYDAT, the water-temp-bc archive and ECCC's real-time feed (through tidyhydat)" | `daily$source` ∈ {hydat, provisional, realtime} | table: hydat, provisional and realtime rows present at both stations | yes |
| Recipe code | `stats = "mean"`, no `cd_trend` | matches the article | yes |

### Software and Data lists (:648–695)

| claim | source | covers? |
|---|---|---|
| "catchments, the stream mouths and the rivers they join are the Freshwater Atlas's" | `vm_*` via fwapg `whse_basemapping` | yes |
| `wet` reads the gauge records and makes the timing-window statistics | `wet_station_daily`, `wet_window_stats` | yes |
| `cd` takes the normal and the departures | `cd_baseline`, `cd_anomaly` | yes; `cd_trend` is gone everywhere in the article (grep: no trend/min7/Kendall/zyp/Theil/Mann left) |
| `tidyhydat` reads the ECCC real-time feed | wet's real-time path | yes (unchanged) |
| `fwapg` "loads the Freshwater Atlas into PostgreSQL and delineates each gauge's catchment from it" | `fwa_watershedatmeasure()` after `wet_station_snap()` (data-raw/station_vignette_map.R:10–11) | yes |
| `ggplot2`, `gq`, `sf` make the figures and the map; `knitr`, `bookdown` render; R | code | yes |
| Data: HYDAT, release | `prov$hydat` | yes |
| Data: provisional and real-time, water-temp-bc | `daily$source` | yes |
| Data: timing windows, species-timing table citing Gottesfeld and Rabnett | `unique(ch$source)` guarded | yes |
| Data: "Streams, lakes and catchments: the Freshwater Atlas, through DataBC" | `vm_lakes`, streams, catchments via fwapg | yes for what it names; **BC Geographic Names (Houston label; Houston and Hazelton placements) is no longer credited** (finding 3) |

Other checks: `n_clear` and every opening number re-derived from a run of the purled article against the installed data. Body prose is capped at 700 by the wordcount chunk, which still runs. No chunk reads a removed object (`trend`, `pal_year`, `pal_dep`, `heat`, `band`): the purled script ran to completion with rc 0.
