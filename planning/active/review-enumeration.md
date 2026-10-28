# Enumeration: every claim the article makes, and what holds it (#126, after code-check round 2)

Round 2 found a defect inside a round-1 fix (the build digest added to the citation was not held), so the review loop ends on this enumeration, not on a quiet round. The candidate set is every prose line of `vignettes/articles/chinook-sites.Rmd` outside code chunks and above "Software and citation", plus the figure and table captions and the citation's two data-derived values: 23 claims. The mechanism behind rounds 1 and 2 was the same: a sentence written from a number seen during the work, with no `stopifnot()` in the chunk that computes it.

| # | claim (article line at f59fc76) | held by |
|---|---|---|
| 1 | Maxan: a five-summer record, spawning-window flow lower | `obs_n == 5`, Maxan extended spawning `pct_hi < 0` |
| 2 | Swift and Naver each gauged for under twenty years | `obs_n < 20` |
| 3 | Gosnell never gauged | `kind == "ungauged"` (no HYDAT station in its basin: `chinook_sites_use.txt`, held by the use table) |
| 4 | spawning flow lower at all four, by X to Y % (carried) | `all(spw$pct < 0)`, inline values |
| 5 | at Maxan, Naver and Gosnell creeks the range stays below no change | `low_spw` computed from `pct_hi < 0` |
| 6 | migration window: no clear change at any stream by either route | every migration row's range spans zero, both routes |
| 7 | scored about as well as Maxan in the Cottonwood and Morice boxes, worse in the upper Fraser | within 0.15 on both routes; Swift's ols at least 0.2 below |
| 8 | Swift: NuSEDS Chinook in most years since 1970 | use table: first year 1970, distinct use years over half the span |
| 9 | Swift: a major spawning site within 5 km of the mouth | `use_obs` row, "Major spawning", measure < 5000 m |
| 10 | Naver: in most years since the mid-1980s | first year 1984–1986, distinct use years over half the span |
| 11 | Gosnell: one survey with adults, in 2001; three provincial records | `nus_use == 1`, 2001–2001, `obs == 3`, `obs_spawning == 0` |
| 12 | Swift's record inside 1981–2010; Naver's before it | `obs_first`/`obs_last` |
| 13 | drop largest at Maxan and Naver, smallest at Swift | rank of `spw$pct` |
| 14 | filled-in records give drops in the same direction (X–Y %) | `all(ext$pct < 0)`, inline values |
| 15 | Morice spawning window a month later | start difference 25–35 days, from the bundle's windows |
| 16 | Gosnell's Morice-window drop smaller, its range reaches no change | `abs(morr) < abs(bulk)`, `morr$pct_hi > 0` |
| 17 | carried departures score at least 0.5 in every box | `all(sc$carried >= 0.5)` |
| 18 | only N gauges in the upper Fraser box | inline `ext_gauges`, held to its report line |
| 19 | Swift's filled-in change the less certain of its two routes | range widths, both windows |
| 20 | migration flow follows peak snow at all four, ranges above zero, R² X–Y % | `all(sn_mig$lo > 0)`, inline values |
| 21 | spawning: peak snow at most X %, melt date at most Y % | `r2_spw < min(r2_mig) / 2`, `r2_melt < min(r2_mig)` |
| 22 | Gosnell's normal off by a typical factor X in the spawning window | inline `err_factor`, held to its report line |
| 23 | the windows are the Bulkley's at all four; only the Morice has its own | `windows` column, Gosnell alone with a second set |
| caption | each box the same size as Maxan's | box spans equal |
| caption | Gosnell has no record of its own to fill in | `kind` |
| citation | Gosnell's typical flow is routed PCIC's; build digest | `pick == "pcic_routed"`; digest held to its report line |

Each number the guards read is itself held to its tracked report line by `data-raw/chinook_sites_data.R`, or parsed from the tracked report (`chinook_sites_use.txt`). Before this enumeration, rows 1, 3, 7, 23 and the box caption had no guard; they were added at f59fc76. Nothing in the set sits above its source.
