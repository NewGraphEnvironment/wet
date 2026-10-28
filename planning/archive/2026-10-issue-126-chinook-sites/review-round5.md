# Review round 5 (#126): enumeration re-verified against the bundle and reports

HEAD f519744. Bundle `inst/vignette-data/chinook_sites_values.rds` (provenance commit 7cda19d); every report md5 in `provenance$reports` equals the tracked file's md5. Numbers below were recomputed from the bundle with the article's own `pct_of()` and `round()`, and checked against the report lines.

## Enumeration verified

- 1 holds: Maxan obs_n 5; extended spawning -55.9 % (-73.0..-27.9), upper end < 0.
- 2 holds: obs_n 14 (Swift), 18 (Naver).
- 3 holds: kind "ungauged"; use report gauges "none".
- 4 holds on numbers and set (carried spawning -46.3, -12.1, -41.2, -34.6, renders "12% to 46%"); its period does not hold, see finding A.
- 5 holds: carried spawning upper ends -16.7, +6.0, -4.2, -4.7, so Maxan, Naver, Gosnell.
- 6 holds on the data (all eight BULK migration-mean ranges span 0; the MORR row also spans 0); guard is BULK-only, finding F.
- 7 holds: migration carried 0.63, 0.51, 0.60, 0.65; spawning 0.49, 0.43, 0.42, 0.45.
- 8 holds: OLS migration 0.50 / 0.63 / 0.48 / 0.14, spawning 0.42 / 0.44 / 0.44 / 0.14; Naver and Gosnell within 0.15, Swift 0.36 and 0.28 below. (The enumeration's claim text says "filling in and borrowing"; the sentence says filling in only. The guard covers more than the sentence, which is fine.)
- 9 holds: 55 distinct use years over 1970-2024, i.e. every year.
- 10 holds: major spawning location at 4938 m.
- 11 holds: 24 distinct years over 1985-2023 (39).
- 12 holds: nus_use 1 (2001), obs 3, obs_spawning 0.
- 13 holds: 1985-1998 inside 1981-2010; 1956-1975 (gaps 1959, 1961) before it; spawning observed years equal the migration ones, so "full summers" holds.
- 14 holds: order Maxan -46.3, Naver -41.2, Gosnell -34.6, Swift -12.1.
- 15 holds: extended spawning -55.9, -24.9, -28.5, renders "25%-56%".
- 16 holds: Morice 09-01 vs Bulkley 08-01, 31 days.
- 17 holds: MORR -23.0 % (-46.7..+10.7), |-23.0| < |-34.6|.
- 18 holds: table cells match the bundle and the reports' settings tables (Gauges scored 31/13/24/30 equal the spawning carried_n too).
- 19 holds on the data (MORR migration carried 0.62 also >= 0.5); migration clause is unqualified while the guard is BULK-only, finding F.
- 20 holds: extension pool 11 vs 17, 18, 21.
- 21 holds: Swift widths migration 29.5 vs 23.6, spawning 41.2 vs 33.8 points.
- 22 holds: carried swe-only migration R2 0.409, 0.411, 0.506, 0.510 (renders 41-51 %); all lower bounds > 0.
- 23 holds: carried spawning swe max 0.155 (16 %), doy max 0.229 (23 %).
- 24 does not hold: the numbers hold (median +20.6 %, q75 +59.7 %), but "long-record gauges" names the wrong set, finding B.
- 25 holds: windows BULK x3, "BULK MORR" at Gosnell.
- caption (map) holds: lon_span 3.8 and lat_span 2.2 at all four.
- caption (table) holds: `sc$ols` is the migration mean, k = 5 (0.50, 0.14, 0.63, 0.48).
- citation holds: all four `normal` rows pick pcic_routed; digest 0f4f8ca matches the report's build digest.
- added (one neighbouring gauge per filled-in year) holds: "Limit: each extended year rests on one donor" in all three gauged reports.
- added (Gosnell tested only at the gauges around it) holds.
- added (both routes scored by hiding a gauge's record) holds.
- added ("the ranges in the change figure carry that weaker score") does not hold, finding C.
- added ("near the mouth", "at Hixon") holds: "Swift Creek Near the Mouth", "Naver Creek at Hixon".
- added (blue and orange) holds on the data (carried #0072b2, extended #d55e00); the guard asserts class names, not colours, finding G.

## Findings

**A. The period "2011-2025" names years that three of the four streams do not have (headline, line 109; change caption, line 189; research note "Change is 2011-2025").** n_post is 14 for Maxan (both routes), Naver carried and spawning-extended, and Gosnell (both window sets). Their per-year tables stop at 2024; only Swift (both routes) and Naver's extended migration series reach 2025 (n_post 15). "In a typical year of 2011-2025 ... at all four streams" therefore speaks for 2011-2025 when the data are 2011-2024 at three of the four. The reports label the period by its definition ("mean departure 2011-2025 minus ..."), but the article presents it as the years the typical year comes from. Not in the enumeration, and no guard checks the span. Fix: say "2011-2024" (Swift adds 2025) or "since 2011", or guard `max post year` per row against the stated span.

**B. Row 24: "the 29 long-record gauges in its box" (line 300) is not the set the article elsewhere calls long-record.** The 29 are the departure pool (>= 10 baseline migration years) with an accepted snap (report line 203: "migration-mean departure pool, snap accepted"). The article uses "long-record" for the extension pool (>= 30 years): the table caption's "the box's long-record gauges" and the Swift sentence's "only 11 gauges have long enough records". For Gosnell's box that set is 18 (the table's "Gauges tested"), so a reader sees 18 long-record gauges in the table and 29 in this bullet. The guard (`err_n`, median, q75) does not cover the set the word names. Fix: "at the 29 gauges in its box with ten or more baseline years" (or "the gauges its departures are scored at").

**C. "The ranges in the change figure carry that weaker score" (lines 262-263) is true of the blue ranges only.** Per every gauged report, the extended (orange) interval adds "a held-out residual to each extended year" (the extension's residual). Only the carried interval adds "a held-out carried residual". So the figure's orange ranges carry the extension's score, not the borrowed departures' spawning score the sentence calls "that weaker score". The enumeration's "added" row checks "the carried interval", which is narrower than the sentence's "the ranges in the change figure". Fix: "the borrowed ranges in the change figure carry that weaker score".

**D. Missing from the enumeration: "Each stream has recorded Chinook use" (line 177).** The set is the four streams. The `use` chunk and the use report cover Swift, Naver and Gosnell; Maxan has no row in `v$use` and no guard. The claim is true (the short-record article cites NuSEDS records at Maxan), but neither this article nor its guard holds it for Maxan. Fix: "Each of the three new streams has recorded Chinook use", or name Maxan's source.

**E. Missing from the enumeration, and not true for Naver: "The two gauged streams' records sit in different places from Maxan's five summers" (line 182).** Maxan's five summers (1975-1979) fall before the 1981-2010 baseline, and so do Naver's 18 (1956-1975), which the sentence itself goes on to say ("before it"). Both end in 1975. The research note calls Naver "the Maxan-like case" and says only Swift's record makes "a different test from Maxan's five summers". Only Swift's record sits elsewhere relative to the baseline; Naver's differs in length, not place. No guard compares either record with Maxan's years. Fix: e.g. "Swift Creek's record sits inside the baseline, unlike Maxan's; Naver Creek's, like Maxan's, falls before it but is longer", with a guard on `obs_last` against Maxan's and 1981.

**F. Rows 6 and 19 (and 4, 22, 23 by the same reading): unqualified sentences with BULK-only guards.** "In the migration window no stream's mean flow shows a clear change by either route" (line 112) and "score at least 0.5 ... in the migration window in every box" (line 260; only the spawning clause is qualified "under the Bulkley windows") cover Gosnell's Morice-window run too, but `mig_all` and `ss_mig` filter `group == "BULK"`. The data hold under MORR (migration range -14.6..+16.3 %; carried 0.62), so the sentences are true, but the guards are narrower than the sentences. Fix: drop the group filter in those two guards, or qualify the sentences.

**G. Change caption's "Blue ... orange" (line 189): the guard asserts class names only.** `classes("chinook_sites_change", c("extended", "carried"))` checks names, not that carried draws blue and extended orange. The registry now gives #0072b2 and #d55e00, so the caption is true. A colour edit in `wet_station.csv` would leave it wrong with every guard passing, while the enumeration row says "asserted in the setup chunk". Low severity. Fix: assert the two hex values, or the hue family, beside the names.

**H. research/chinook_sites.md: "Naver's years since 1999 rest on 08KH006" is true of the migration mean through 2024 only.** In `data/checks/departure_site_naver_bulk_20260717.txt`, the spawning mean's 1999-2024 years rest on 08KC001 (with 08KG001 in 2008-2010 and 2013), and the migration mean's 2025 on 08KH001. Neither 08KC001 nor 08KG001 is in the report's printed "Donor chain", which is the migration mean's. Fix: scope it to the migration mean ("Naver's migration-window years 1999-2024 rest on 08KH006; its spawning-window years since 1999 on 08KC001 and 08KG001").

Rest of research/chinook_sites.md checked and holds: the use table (rows, use, distinct years, observations, spawning), Swift's 6 km, eight fry and one major spawning record, the 14 and 18 windows, the 651/908 km2, the Gosnell/Lamprey tie at 4 and its tie-break, the Morice windows, every cell of the results table (pools, OLS/ratio medians and picks, carried NSE, spawning and migration changes and intervals), ratio picked in two of three new boxes, migration carried >= 0.5 in every box including MORR, the spawning carried scores and MORR's 0.66, the snow R2 values, the SWE cap binding nowhere, Gosnell's normal (34.4, 8.7), the error medians (+0.04, +0.19, +21 %, +60 %), 25 of 29 picks routed PCIC, and the snow-gauge amendment (08KD001 skipped).
