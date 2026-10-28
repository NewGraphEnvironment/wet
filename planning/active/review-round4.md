# Code-check round 4 (#126): adversarial check of the claim enumeration

## Checklist read

- code-check.md, every H3 under `## Mechanisms` (prose, table rows skipped): a guard that fails toward pass; a fixture that cannot reach the failure mode; a proxy is not the property; verification that reads its own output; a guard's scope, escape hatches, and remedies; a fix lands in one of two callers; restore the bug and prove the guard fires; a shared working tree; a wrapper's exit is not the work; zero-length, empty and unset; the probe is broken before the world is (read through "Before believing an error").
- code-check-r.md index lines for what the diff uses: `match()` treats NA as a value, `paste()` with a zero-length argument, `tolerance` is relative, `sprintf("%g")`, `nzchar(NA)`, `$` partial matching, `expect_*` argument rules, `skip_if_not()` scope, `read.delim()` quoting, `ifelse()` with an all-NA test.
- Probes: bundle values (`inst/vignette-data/chinook_sites_values.rds`) printed in full and every inline value of the article recomputed by hand; the five site reports' sections 1-4, the use report and the snow reports' cap lines read against the article and `research/chinook_sites.md`.

## Enumeration verified

1. Maxan five summers, spawning lower: holds (obs_n 5; extended spawning hi -0.33).
2. Swift 14, Naver 18 full summers: holds.
3. Gosnell never gauged: holds, but the article's guard is only `kind`; the bundle's `use` table drops the gauges column, so "use table none" is held by `scripts/chinook_sites_use.R:134`'s stop, not by the article.
4. Spawning carried lower at all four, 12-46 %: holds (-46.3, -12.1, -41.2, -34.6; MORR -22.9 also inside).
5. Range below zero at Maxan, Naver, Gosnell: holds (hi -0.18, -0.04, -0.05; Swift +0.06).
6. Migration: no clear change by either route: holds (every BULK migration-mean row spans 0; Gosnell MORR -0.16..0.15 as well).
7. Borrowed 0.51-0.65 migration, 0.42-0.49 spawning, "below the bar ... at all four streams": numbers hold under the Bulkley windows; the set does not (see finding 3).
8. Filling in about as well as Maxan in Cottonwood and Morice, worse in upper Fraser: true of the data in both windows; guard covers the migration window only (see finding 4).
9. Swift: most years since 1970: holds (55 distinct use years over 1970-2024).
10. Swift: major spawning site within 5 km: holds (FISS 1980, 4938 m).
11. Naver: most years since the mid-1980s: holds (24 of 1985-2023's 39 years).
12. Gosnell: one adult survey in 2001; three provincial records: holds.
13. Swift full summers 1985-1998; Naver 1956-1975: does not hold for Naver (see finding 2).
14. Drop largest at Maxan and Naver, smallest at Swift: holds.
15. Filled-in drops same direction, 25-56 %: holds (-24.9, -28.5, -55.9 render 25-56).
16. Morice spawning window a month later: holds (31 days).
17. Gosnell Morice drop smaller (23 % vs 35 %), range reaches no change: holds.
18. Score table: values hold to the reports; caption does not (finding 4).
19. "at least 0.5 in migration in every box, below it in spawning in every box": does not hold for the Gosnell box under the Morice windows (finding 3).
20. Only 11 gauges, few long records: holds (extension pool 11, others 17-21).
21. Swift's filled-in change the less certain route: holds (wider range in both windows).
22. Migration borrowed departures follow peak snow, 41-51 %, range above 0 at all four: holds.
23. Spawning: snow at most 16 %, melt at most 23 %: holds (0.155, 0.229).
24. Gosnell spawning published flow median 21 % above, "more than 60 % at a quarter of 29 gauges": the median holds; the quartile sentence does not, and "its box" names a wider set than the 29 (findings 1 and 5).
25. Windows the Bulkley's at all four, only the Morice its own: holds.
caption (map): boxes the size of Maxan's: holds (3.8 x 2.2 degrees each).
caption (table): Gosnell has no record to fill in: holds; "tested on the migration window": does not (finding 4).
citation: Gosnell's normal is routed PCIC's, digest held: holds.

Missing from the enumeration, all checked and holding: the third limit bullet ("each filled-in year rests on one neighbouring gauge", the reports' Limit lines); "its departures are tested only at the gauges around it"; "both routes are scored by hiding a gauge's own record"; "the ranges in the change figure carry that weaker score" (carried intervals add held-out carried residuals); the gauge places "near the mouth" and "at Hixon" (HYDAT names 08KA012 Swift Creek Near the Mouth, 08KE014 Naver Creek at Hixon); the change caption's "Blue"/"orange" (registry #0072b2 carried, #d55e00 extended). The table has 28 entries, not the 27 its header says.

research/chinook_sites.md: every number in the table and bullets matches the reports (each % and interval recomputed from the bundle; SWE cap line in all five snow reports; 25 of 29 routed picks; Naver's 08KH006 years 1999-2024; Swift's records all within 5984 m, eight 2012 fry). Line 36 "fall below it on the spawning-window mean in every box" carries finding 3's scope; line 38 "the 29 box gauges" carries finding 5's.

## Findings

- **[severity: bug]** vignettes/articles/chinook-sites.Rmd:294 (guard :219) — "more than 60% above at a quarter of them" is false. `err_q75` is 0.4679, which is +59.7 %, rendered "60%" by `pct()` and then preceded by "more than". In the Gosnell BULK report's spawning error table only 6 of the 29 gauges exceed +60 % (08FE003 0.593 and up, 21 %); 08ED001 and 08EE012 sit at 0.468 (+59.7 %), so "more than 60 %" is not true at a quarter of them. The guard only checks `err_q75 > err_median`. Either state the quartile as a quartile ("a quarter of them run about 60 % or more above"), or render it with `floor` and "at least", and guard the count of gauges above the rendered figure against `err_n / 4`. research/chinook_sites.md:38 says "an upper quartile of +60 %", which is correct as written.

- **[severity: bug]** vignettes/articles/chinook-sites.Rmd:177-179 (guard :150) — "Naver Creek's at Hixon [has full summers] for 1956–1975" reads as every summer of that span, but the report's line is `08KE014 18 (1956-1958, 1960, 1962-1975)`: 1959 and 1961 are not full summers. The guard checks only `obs_first`/`obs_last`, the endpoints, not the span the sentence names. Swift's 1985–1998 is contiguous (14 of 14), so the same sentence form is right there and wrong here. Enumeration row 13 marks it "yes".

- **[severity: fragile]** vignettes/articles/chinook-sites.Rmd:108-110 and :253-256 (guards :74-79) — "below the bar ... at all four streams" and "below it in the spawning window in every box" are guarded on `group == "BULK"` only. Gosnell's box is also scored under the Morice windows, which the article reports two paragraphs earlier (:227-229): there the borrowed departures score 0.62 in migration and **0.66 in spawning** (`score_settings` row 26; the gosnell_morr report's By-setting table), above the bar. The Morice-window spawning change the article reports is therefore the one spawning result whose borrowed route clears the bar, and the reader is told the opposite. This is round 3's mechanism (a guard filtered to one window set while the sentence speaks for every box). Scope both sentences to the Bulkley windows, or guard over every `score_settings` row and say how Gosnell's Morice windows score. Same scope in research/chinook_sites.md:36.

- **[severity: bug]** vignettes/articles/chinook-sites.Rmd:243 (caption), with :111-112 and :257-258 (guards :86-89) — the caption says "Filling in a record is tested at the box's long-record gauges, on the migration window". Each report's Sensitivities table tests ols on every setting, including "spawning mean" (0.42 Maxan, 0.14 Swift, 0.44 Naver, 0.44 Gosnell BULK, 0.52 Gosnell MORR; the bundle holds them in `score_settings$ols`). The table column is the migration score, but the extension is not tested on the migration window alone. The two prose sentences "Filling in a record scored about as well as at Maxan in the Cottonwood and Morice boxes, and worse in the upper Fraser" name no window, while their guard reads `sc$ols`, the migration mean only. The data do support them in the spawning window too (Naver and Gosnell within 0.02 of Maxan's 0.42, Swift 0.28 below), so the sentences are true. The guard is narrower than they are, and enumeration row 8 marks it "yes". Fix the caption (e.g. "the table shows the migration window's score") and extend the guard to the spawning-mean rows of `score_settings`.

- **[severity: fragile]** vignettes/articles/chinook-sites.Rmd:292-293 — "At the `r nerr$err_n` gauges in its box" renders "At the 29 gauges in its box", but Gosnell's box holds 80 natural gauges (54 in the box pool). The 29 are the box's migration-mean departure-pool gauges with an accepted snap (report: "The normal's error at the box gauges (migration-mean departure pool, snap accepted)"). The number is right; the set the sentence names is wider than the one measured, and no guard ties them. Same wording in research/chinook_sites.md:38 ("the 29 box gauges").

No defect found in round 3's parsers. The per-setting score parser (`data-raw/chinook_sites_data.R:153-172`) has bounded sections, single-row matches, a stop on 0 or 2 rows, the right field positions in both tables (checked against the Swift report), and a migration-mean cross-check against the series file. A reversed section bound refuses rather than misreads. The use-table parser's 15 groups map to the printed columns (checked against `scripts/chinook_sites_use.R:152-159`). The observation parser refuses an unreadable row, and a row it skips is caught by the per-stream count check.
