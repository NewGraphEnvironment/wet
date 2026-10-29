# Enumeration of the revised article's claims (#126, after revision review round 2)

The revision (73a6b95..HEAD) rewrote the article as `vignettes/articles/flow-change-sparse-gauges.Rmd`. Revision round 2 found a defect inside a round-1 fix: the year-by-year caption did not describe the new isolated-year points. So this loop ends on an enumeration. The set is every prose sentence, caption and table cell of the article, each with the set it names and the guard that holds it. Rows unchanged from the first article's enumeration (`planning/archive/2026-10-issue-126-chinook-sites/review-enumeration.md`) are cited by their old row number.

| # | claim | set named | guard |
|---|---|---|---|
| 1 | streams gauged for few summers or never; four streams in central BC that Chinook use | the four | `obs_n`, `kind`; use table (Swift, Naver, Gosnell); Maxan's use is its own article's |
| 2 | Maxan five, Swift 14, Naver 18 full summers; Gosnell never gauged | the four | inline `obs_n`; `obs_n == 5`; `kind` |
| 3 | run the same way, method fixed before any result; scored on gauges it was not given | method | registered headers (efc23f1); the held-out tests |
| 4 | spawning-window mean flow lower at all four, 12–46 %, from nearby gauges' departures | carried, four, Bulkley | `all(spw$pct < 0)`, inline |
| 5 | that route's range below no change at Maxan, Naver, Gosnell | carried | `low_spw` |
| 6 | migration window: no stream's mean flow shows a clear change | both routes, both window sets | `mig_all` |
| 7 | borrowing scores worse in spawning than migration at all four under these windows | carried, Bulkley | per-site spawning < migration over `ssc` (BULK) |
| 8 | locator caption: boxes the same size | four boxes | spans equal |
| 9 | numbers borrowed from gauges inside a same-size box | four | the box rule (site table), spans equal |
| 10–13 | Chinook records at Swift, Naver, Gosnell | as old rows 9–12 | as old rows 9–12 |
| 14 | Swift's 14 between 1985 and 1998 inside the baseline; Naver's 18 between 1956 and 1975 before it, as Maxan's five | three gauged | `obs_first/obs_last`, Maxan `obs_last < 1981` |
| 15 | panel caption: each stream with its rivers, lakes, towns and the gauges it borrows from | four panels | layers per site (tests); only donor roles drawn |
| 16 | a window is a stretch of the year...; dates from Gottesfeld and Rabnett for the Bulkley, used at all four | Bulkley windows, four | `wb` from the bundle; `windows` column |
| 17 | flow peaks inside the migration window at every stream | four | `peak` within the migration window |
| 18 | low in the spawning window, under a third of its peak | four | spawning mean < peak / 3 |
| 19 | hydrograph caption: published daily flow at the gauge, or Gosnell's mouth | four | `daily` built on the snapped gauge segment or the mouth segment; source routed PCIC, guarded |
| 20 | two routes: filled from one gauge; borrowed at every stream | method | the extension's single donor; `years` routes (tests) |
| 21 | year-by-year caption: every mark (measured points, filled line and range, borrowed line, small points for isolated years, period lines of the borrowed route) | figure | drawn as described; period-line differences equal the carried change (stopifnot) |
| 22 | drop largest at Maxan and Naver, smallest at Swift; filled-in drops same direction 25–56 % | as old 14–15 | as old 14–15 |
| 23 | change caption: since 2011 to 2024 or 2025 | every series | last year in 2024:2025 per site, window, route |
| 24 | Gosnell's own Chinook windows, spawning a month later; its drop smaller, range reaches no change | Gosnell | as old 16–17 |
| 25 | score table and caption | four | values from the bundle, each held to its report |
| 26 | bar of 0.5 set before any stream was run; borrowed clears it in migration in every box, falls below in spawning under these windows, 0.42–0.49 | carried | BULK guards; migration over both sets |
| 27 | filling in about the same in the Bulkley, Cottonwood and Morice boxes; poor in the upper Fraser, 11 gauges; Swift's filled-in change the less certain | filled-in, both windows | as old 8, 20, 21 |
| 28 | snow paragraph | carried | as old 22–23 |
| 29 | Gosnell's normal's error, 29 gauges | as old 24 | as old 24 |
| 30 | windows are the Bulkley's; only the Morice has its own | as old 25 | as old 25 |
| 31 | one neighbouring gauge per filled year | method | as before |
| 32 | software paragraph: HYDAT release; hydrographs and Gosnell's flow routed PCIC's as wet publishes it | four | `all(v$daily$source[v$daily$pick] == "pcic_routed")`, `v$normal$pick` |
