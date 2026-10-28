# Enumeration: every claim the article makes, what holds it, and whether the guard covers the claim's scope (#126)

Round 2 found a defect inside a round-1 fix, so the review loop ends on an enumeration. Round 3 named the mechanism behind every finding so far: **a guard checked one value (the migration window, the borrowed series, complete windows, a 7-gauge subset) while its sentence spoke for a group.** The first version of this enumeration (b6a1634) checked that each claim had a guard. This version also checks that each guard covers the set its sentence names. Round 4 checked it row by row and found five rows that did not hold (7, 8, 13, 24 and the table caption) and six sentences missing; those are corrected or added below. The candidate set is every prose line of `vignettes/articles/chinook-sites.Rmd` outside code chunks, the figure and table captions, and the citation's data-derived values: 34 entries.

| # | claim | set the sentence names | held by | guard covers that set? |
|---|---|---|---|---|
| 1 | Maxan: five summers, spawning-window flow lower | Maxan, its record route | `obs_n == 5`, extended spawning `pct_hi < 0` | yes |
| 2 | Swift and Naver gauges hold 14 and 18 full summers | the two target gauges | inline `obs_n` | yes (the number is the claim) |
| 3 | Gosnell never gauged | Gosnell's basin | `kind`; no HYDAT station inside its basin is refused by `scripts/chinook_sites_use.R` before the use report is written | yes |
| 4 | spawning-window mean flow lower at all four, 12–46 % (borrowed) | four sites, carried, mean, spawning | `all(spw$pct < 0)` over the same rows | yes |
| 5 | range below no change at Maxan, Naver, Gosnell | as listed | `low_spw` from `pct_hi < 0` | yes |
| 6 | migration window: no stream's mean flow shows a clear change by either route | four sites × two routes, mean | every migration-mean row spans zero, both routes | yes |
| 7 | borrowed departures 0.51–0.65 in migration, 0.42–0.49 in spawning, below the bar at all four under the Bulkley windows | four sites, Bulkley windows, carried | `all(ss_spw$carried < 0.5)`, `all(ss_mig$carried >= 0.5)` over the BULK set | yes (the sentence now names the Bulkley windows; under the Morice's, Gosnell scores 0.66) |
| 8 | filling in and borrowing about as well as Maxan in Cottonwood and Morice, filling in worse in the upper Fraser | both routes, both windows (the sentence names none) | within 0.15 at Naver and Gosnell and Swift's filled-in 0.2 or more below, each in the migration and the spawning window | yes |
| 9 | Swift: NuSEDS Chinook in most years since 1970 | distinct years | `nus_use_years` over half the span, first 1970 | yes (distinct years, not rows) |
| 10 | Swift: a major spawning site within 5 km | provincial records | `use_obs` row | yes |
| 11 | Naver: most years since the mid-1980s | distinct years | as 9 | yes |
| 12 | Gosnell: one adult survey in 2001; three provincial records | NuSEDS use rows; observations | `nus_use == 1`, 2001; `obs == 3` | yes |
| 13 | Swift's 14 full summers between 1985 and 1998, inside the baseline; Naver's 18 between 1956 and 1975, before it | complete migration windows | inline `obs_n`, `obs_first`, `obs_last`; first and last against the baseline | yes ("between": Naver lacks 1959 and 1961) |
| 14 | drop largest at Maxan and Naver, smallest at Swift | carried spawning mean | rank of `spw$pct` | yes |
| 15 | filled-in records give drops in the same direction (25–56 %) | three gauged sites, extended | `all(ext$pct < 0)` | yes |
| 16 | Morice spawning window a month later | Gosnell's two window sets | start difference 25–35 days | yes |
| 17 | Gosnell's Morice-window drop smaller, range reaches no change | carried spawning mean | `abs(morr) < abs(bulk)`, `pct_hi > 0` | yes |
| 18 | score table | four sites | values from the bundle, each held to its report line | yes |
| 19 | at least 0.5 in migration, below it in spawning, every box | as 7 | as 7 | yes |
| 20 | only 11 gauges; few long records | the four boxes' extension pools | Swift's below every other box's | yes |
| 21 | Swift's filled-in change the less certain of its routes | Swift, both windows | range widths in both windows | yes |
| 22 | migration-window borrowed departures follow peak snow at all four, R² 41–51 % | carried series, four sites | `all(sn_mig$lo > 0)`, inline range | yes (sentence now names the borrowed series) |
| 23 | spawning: peak snow at most 16 %, melt date at most 23 % | carried series | `max` over the four of each predictor | yes |
| 24 | Gosnell's published spawning flow a median 21 % above measured, about 60 % or more at a quarter of its 29 long-record gauges | the departure-pool gauges with an accepted snap | median and upper quartile (+59.7 %), held to the report | yes ("about": the quartile is 59.7 %) |
| 25 | the windows are the Bulkley's at all four; only the Morice has its own | four sites | `windows` column | yes |
| caption | each box the size of Maxan's | four boxes | spans equal | yes |
| caption | Gosnell has no record to fill in; the table gives filling in's migration-window score | Gosnell; the table's column | `kind`; the column is `sc$ols`, the migration mean | yes |
| citation | Gosnell's typical flow is routed PCIC's; build digest | Gosnell's normal | `pick == "pcic_routed"` both windows; digest held | yes |
| added | each filled-in year rests on one neighbouring gauge | the extension | the OLS extension's single covering donor per year (`wet_window_extend()`) | yes (method, not data) |
| added | Gosnell's departures tested only at the gauges around it | Gosnell | `kind`; sections 2–3 of its report are box scores | yes |
| added | both routes are scored by hiding a gauge's own record | the scoring | #120's leave-gauge-out and pseudo-record tests | yes (method) |
| added | the ranges carry that weaker score | the carried interval | the carried bootstrap adds held-out carried residuals per statistic and window | yes (method) |
| added | gauges "near the mouth" and "at Hixon" | 08KA012, 08KE014 | HYDAT station names | yes |
| added | blue and orange in the change caption | the routes | the registry's `chinook_sites_change` classes, asserted in the setup chunk | yes |

Not claimed, and so not guarded: the min7 and cov_day changes (Swift's migration min7 rose, and Swift's and Gosnell's migration cov_day moved earlier with ranges excluding zero; round 3). The article speaks only of mean flow, and every such sentence now says so. Nothing in the set sits above its source.
