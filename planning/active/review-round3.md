# Code-check round 3 (#152), branch at 4be8c59 against 6fbbf65

## Checklist read

- code-check.md: every H3 under `## Mechanisms`, prose only (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree; A wrapper's exit is not the work; Zero-length, empty, and unset; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice), and "An assertion that matches an interpolated value cannot see the claim around it".
- code-check-r.md index read; sections for the shapes this diff uses: "`tolerance` in testthat is RELATIVE", "`$` on a list partial-matches", "`match()` treats NA as a matchable VALUE", "Moving prose into a code chunk hides it from tools that scan the document", "A `data-raw/` script must load the source tree".
- code-check-shell.md and code-check-spatial.md indexes read; no shell, and no spatial code beyond what earlier rounds reviewed (the `where` chunk is unchanged in kind).

Both articles were rendered from a copy of the tree (`pkgload::load_all()` of the copy); every value below is from those renders or from the bundles.

## The mechanism

Every earlier finding, and every one below, has one shape: **a sentence's population is set by its words, and its guard's by a data-frame filter written for an earlier, narrower article.** The rebuilt article was one statistic (mean), one series (carried), one window set (the Bulkley's) and one interval type (the change interval). #152 added members on every axis: the lowest seven-day flow, the measured snow-gauge series, the Morice window set in the snow chunk, and a coverage rule for one interval type among several. Sentences written for the one-member article now quantify over the union ("borrowed departures", "the melt date", "a 90 % range"), while the filters (`statistic == "mean"`, `series == "carried"`, `group == "BULK"`, `ch$cover`) stayed on the old member. Round 2 then fixed the other direction by widening a filter for a guard. The same filtered rows also feed the printed numbers, so a printed range moved onto a population the sentence does not name (F1). The check that terminates the class: for each sentence, write down its subject's axes (statistic, route or series, window set, interval type), then confirm that the guard's filter and every printed value's filter equal that set on each axis, not a superset and not a subset.

## Findings

- **[bug]** vignettes/articles/flow-change-sparse-gauges.Rmd:540-546, 555-559. "measured flow at all 8 snow gauges … 25–63%" prints a range over 10 rows: the 8 gauges under the Bulkley windows plus Gosnell's two gauges again under the Morice migration window (May 1 – Sep 30). The 63% is 08ED001 under the Morice window (r² 0.6307). Under the Bulkley migration window the article uses everywhere else, the maximum is 0.6183 (08KA001), so 62%. research/chinook_sites.md:65 says 0.25–0.62, so the article and research now disagree. Round 2 dropped `group == "BULK"` from `og` so the guard would cover both window sets, but `og_mig$r2` also feeds the printed range. Keep the guard over both sets and print the range from the BULK rows, or name the Morice window in the sentence.
  - **Rule:** code-check.md "One fact derived twice" (a published number has two derivations; one population per measurand); code-check.md "A guard's scope, escape hatches, and remedies" (a guard written against the whole artifact redefines its subset).
  - **Inside an earlier round's fix?** yes (round 2)

- **[bug]** vignettes/articles/flow-change-sparse-gauges.Rmd:532-537, 559-562. "In the spawning window peak snow explains at most 16% of the borrowed departures and 31% of measured flow, and the melt date at most 23%." The melt-date clause follows "of measured flow" and so reads as covering both series, but `melt_spw` takes only `series == "carried"`. For measured flow the melt date explains up to 66% of spawning-window flow (08ED002, Bulkley window, r² 0.6634; 08ED001, 0.6433). The section's message, that snow explains little of spawning-window flow, is contradicted at Gosnell's two snow gauges. The base version had no measured-flow clause, so its melt-date clause was unambiguous. Either say "of the borrowed departures" in the melt-date clause, or extend `melt_spw` to the observed series and report what it shows.
  - **Rule:** code-check.md "A proxy is not the property" (a sentence describing a figure is a claim about the criterion: enumerate every result-describing sentence); code-check.md "A guard's scope, escape hatches, and remedies" (a sentence that gained a member is unsupported until checked).
  - **Inside an earlier round's fix?** no (introduced in df7ff7b when measured snow joined the paragraph)

- **[bug]** vignettes/articles/flow-change-sparse-gauges.Rmd:157-160 (guard 120-124). "Borrowed departures score worse in the spawning window than in the migration window at all four under the Bulkley's windows" comes straight after "Borrowed, the lowest seven-day flow in that window fell…". In this paragraph "borrowed" now names both statistics. The guard compares only `migration mean, k = 5` against `spawning mean`. For the seven-day low (`migration min7` against `spawning min7`, carried, BULK) the claim is reversed at three of four: Maxan 0.23 → 0.42, Naver 0.29 → 0.45, Gosnell 0.31 → 0.43 score *better* in spawning; only Swift (0.59 → 0.32) holds. In the base the article had only the mean, so the sentence was unambiguous. The same applies, less sharply, to "In the migration window the borrowed departures show no clear change at any stream" (guard 98-99, mean only). For min7 that is true today, but Swift's carried migration min7 range is -1.9..+123%, so a rebuild can flip it with no guard firing. Say "mean flow" in both sentences, or guard min7 as well.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"; code-check.md "A proxy is not the property".
  - **Inside an earlier round's fix?** no (round 1 qualified the window set of this sentence and did not touch its statistic)

- **[bug]** research/chinook_sites.md:46, CLAUDE.md:45 (Chinook pilots paragraph), vignettes/articles/flow-change-sparse-gauges.Rmd:78-82 (comment), Rmd:412 (Figure 4 caption), Rmd:555-556. Research says "The article calls an interval a 90 % range only above 0.87, so every range it draws on qualifies", and CLAUDE.md says "only where every coverage it draws on is at least 0.87". The guard (`drawn$cover >= 0.87`) reads only the change intervals in `ch`. The article also calls the filled-in years' OLS prediction intervals "its 90% range" (Figure 4 caption). The site reports measure that interval's held-out coverage at 85.0 (Maxan), 85.3 (Naver) and 82.7 % (Swift) ("Coverage of the nominal 90 % interval on held-out years: ols …"), all under the 0.87 bar. The measured article was demoted at 0.834–0.867 by the same bar. The snow slopes' "90% ranges above zero" (Rmd:555-556) were never put through any coverage test. The registered rule is not in question; the universal claim about it is. Scope the research and CLAUDE.md sentences, and the chunk comment, to the change ranges, and either stop calling Figure 4's per-year band a 90% range or state its measured coverage.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (enumerate the population a quantifier names; terminate by enumeration); code-check.md "A proxy is not the property" (a guard proving coverage must ask a wider question than the check).
  - **Inside an earlier round's fix?** no (the claim is new on the branch, 909fcdc/dace8a4; the caption is older)

- **[fragile]** vignettes/articles/flow-change-sparse-gauges.Rmd:460-464. Under the accepted convention, a point estimate's direction may be stated only if the sentence or its paragraph says whether the range clears no change. This paragraph states two directions without it. (a) "Borrowed, the spawning window's lowest seven-day flow fell by 26% to 40% at Maxan, Naver and Gosnell creeks": only Maxan's range (-63..-2) clears; Naver's (-56..+5) and Gosnell's (-49..+13) do not. "clearly only at Maxan" is in the answer paragraph, not this one. (b) "filling in each gauged stream's own record gives drops in the same direction (27%–57%)": Swift's extended range is -47..+0.4 and Naver's -67..+5.5, so only Maxan's clears. Round 2 added the route to (a) but not the range.
  - **Rule:** code-check.md "A proxy is not the property" (point estimate standing in for "fell"); convention accepted for this repo (direction plus range in the same paragraph).
  - **Inside an earlier round's fix?** yes (round 2, for (a)); (b) predates the branch

- **[fragile]** research/chinook_sites.md:62. "Swift 556 → 524": the bundle's `swe_ref` for 08KA012 is 555.458 mm, so 555. 556 is the snow report's 1-dp print, 555.5 (departure_site_snow_swift_bulk_20260717.txt:91), rounded a second time. This is the class round 2 fixed for Swift's -27 %. The other seven SWE numbers on the line are right.
  - **Rule:** code-check.md "One fact derived twice" (guard and print from the value, not from a printed form).
  - **Inside an earlier round's fix?** no

## Enumeration: every quantified, counted, comparative, directional or numeric sentence

Values are from the renders and bundles at 4be8c59. "Match" means the guard's set, route, window set and statistic equal the sentence's.

### flow-change-sparse-gauges.Rmd

| # | sentence (prose or caption) | guard | set / route / windows / statistic | verdict |
|---|---|---|---|---|
| 1 | Maxan, five full summers; Swift and Naver 14 and 18; Gosnell never gauged | 95-96 | sites | match |
| 2 | spawning mean lower at all four, 15%–46%, from nearby gauges' departures | 91-92 | 4 sites / carried / BULK / mean | match |
| 3 | at Maxan, Naver and Gosnell that route's 90% range stays below no change | inline `low_spw` | same | match |
| 4 | borrowed seven-day low fell at three, clearly only at Maxan, held at Swift | 103-107 | carried / BULK / min7 (MORR also falls, -31) | match |
| 5 | migration window: borrowed departures show no clear change at any stream | 98-99 | carried / both / **mean only** | narrower than the sentence (F3); true for min7 today |
| 6 | snow over every catchment peaked lower and melted earlier | 109-114 | 4 target catchments | match |
| 7 | borrowed departures score worse in spawning than migration at all four (Bulkley) | 122 | carried / BULK / **mean only** | false for min7 at 3 of 4 (F3) |
| 8 | two in the Skeena, two in the Fraser; rivers joined; compass and distance | 185-198 | 4 sites | match |
| 9 | Gosnell "just above" the Morice | 186 (into2) | adjacency only | no distance guard; low stakes |
| 10 | each borrows from a same-sized box | 200 | 4 sites | match |
| 11 | chinook in Swift most years since 1970; major spawning site < 5 km; Naver since mid-1980s; Gosnell one survey, 2001, three records | 308-314 | use report | match |
| 12 | Bulkley windows used at all four streams | 138 | sites$windows | match |
| 13 | flow peaks inside migration window at every stream | 331-332 | 4 sites / BULK | match |
| 14 | spawning window falls under a third of peak | 334-338 | window mean < peak/3 | match ("falls under" is met by the mean) |
| 15 | last ten years 2016–2025 vs 1951–1980 | 73 | periods | match (n_post 9 at some; caption 5 says so) |
| 16 | drop largest at Maxan and Naver, smallest at Swift | 451-452 | carried / BULK / mean | match |
| 17 | filled-in drops same direction, 27%–57% | 436-437 | extended / BULK / mean | direction without range (F5b) |
| 18 | borrowed seven-day low fell 26%–40% at Maxan, Naver, Gosnell | 104-105, 457 | carried / BULK / min7 | direction without range in its paragraph (F5a) |
| 19 | Fig 4 caption: grey line's "90% range" | none | OLS per-year interval, held-out coverage 82.7–85.3 % | under the article's own bar (F4) |
| 20 | Fig 4 caption: black lines = borrowed mean departure per period | 406-409 | carried / BULK | match |
| 21 | Fig 5 caption: to 2024 where 2025 not approved; 90% range | 396-397, 81-82 | years; change covers ≥0.87 | match |
| 22 | Morice spawning window a month later | 445 | 31 days | match |
| 23 | under it Gosnell's drop is smaller, 23%, range reaches no change | 438-441 | carried / MORR / mean | match |
| 24 | table caption: median over gauges; filled-in column is migration | 490-499 | scores BULK = settings migration ols | match |
| 25 | borrowed clear 0.5 in migration in every box | 123-124 | carried / both sets / mean | match |
| 26 | below it in spawning in every box (Bulkley), 0.42–0.49 | 123 | carried / BULK / mean | match (0.49 prints below 0.50) |
| 27 | seven-day low below the bar in 7 of 8 windows and boxes | 455-456 | carried / BULK / min7 | match under the Bulkley convention (MORR adds 2 more, both below) |
| 28 | filling in scores about the same elsewhere, poorly in upper Fraser, 11 records | 129-136, 500-502 | ols / BULK / mean both windows | match |
| 29 | Swift's filled-in change is the less certain route | 504-506 | width, both windows | match |
| 30 | peak snow 6%–9% less, melt 9–16 days earlier | 109-114 (signs); values inline | 4 targets | match (comment at 108 says 6–10 / 9–17, stale but inert) |
| 31 | migration flow rises with peak snow, borrowed, all four, ranges above zero, 41–51% | 523-529 | carried / both sets | match (range is 41–51 either way) |
| 32 | measured flow at all 8 snow gauges, two per stream, rises; 25–63% | 540-545 | observed / **both sets in the print** | printed max from the Morice window (F1) |
| 33 | "90% ranges above zero" for snow slopes | 528, 545 | slope intervals | not coverage-tested (F4) |
| 34 | spawning: peak snow at most 16% (borrowed), 31% (measured) | 530, 546 | carried, observed / both | match |
| 35 | the melt date at most 23% | 533-537 | **carried only** | measured-flow melt date up to 66% (F2) |
| 36 | Gosnell normal: N gauges, median +21%, ~60% at a quarter | 567-568 | BULK spawning | match |
| 37 | windows are the Bulkley's at all four; only the Morice has its own | 138 | sites | match |
| 38 | routed PCIC is Gosnell's normal and every hydrograph's source | 570 | normal, daily | match |
| 39 | word cap 1000 | 627-643 | body prose | renders, so under cap |

### flow-departure-normal.Rmd

| # | sentence | guard | verdict |
|---|---|---|---|
| 1 | 2016–2025 below normal in every window at both gauges, 5%–48% | 306 | match |
| 2 | every window both gauges below normal each year from 2023 | 227-233 | match |
| 3 | 11 of those 12 drier than nine 1981–2010 years in ten | 236-245 | match |
| 4 | normal at 08EE003 rests on 1981–1998 | 159-163 | match |
| 5 | before 2023 the decade swings both ways in every window | 253-256 | match (checked per gauge, stronger than the sentence) |
| 6 | from 2023 every bar below median and mean; 5 drier than any 1981–2010 year | 246-251 | match |
| 7 | same side of normal in all but one of the 18 window-years both recorded | 258-262 | match (2019 spawning splits: 127 % vs 94 %) |
| 8 | Fig 3 caption: recent line where each recent year has a record, 9 at Buck, no 2016 | 201-208, 555 | match (bundle holds 0 Buck days in 2016) |
| 9 | change bar narrower than a 90% CI with ten recent years or fewer; not called a 90% range | 291 (bundle md5 = report's Inputs md5) | match at 9/10; "or fewer" rests on #145's five-year measurement |
| 10 | 1 of the ten years rests on provisional flows | 694-699 | match |
| 11 | 2 of the 38 bars rest on 80%–91% of days | 266-273 | match |
| 12 | word cap 700 | (render) | renders, so under cap |

### research/chinook_sites.md (#152 section) and research/station_flow_departure.md (#152 section)

| claim | checked against | verdict |
|---|---|---|
| 20–30 years of 1951–1980, 9 or 10 of 2016–2025; 2025 for every Swift series and some of Naver's filled-in ones | bundle n_pre/n_post | match |
| intervals covered 0.904–1.000 | `ch$cover` | match |
| "every range it draws on qualifies" | Figure 4 band and snow slopes | false (F4) |
| measured article 0.834–0.867 | coverage report | match |
| change table, all 20 cells and ranges | bundle at full precision (all .5 boundary cases checked) | match |
| spawning drop largest Maxan/Naver, smallest Swift; carried clears at Maxan, Naver, Gosnell | bundle | match |
| migration no clear change, carried; Maxan extended -28 % (-46..-5) | bundle | match |
| min7 carried falls at three, clears only at Maxan, Swift +1 %, extended -18 %; 7 of 8 below 0.5 (0.23–0.59) | bundle, score_settings | match |
| SWE fell 6–9 %; 260→235, 556→524, 243→223, 974→891 | snow_change | Swift 556 is twice-rounded, 555 (F6) |
| melt 9–16 days earlier | snow_change | match |
| snow gauges: rise at all eight, R² 0.25–0.62; spawning at most 0.31 | snow (BULK) | match; the article now prints 25–63 (F1) |
| measured: -7/-8 % (08EE003), -5/-48 % (08EE013) | render `chg` | match |
| below normal each year from 2023, 11 of 12 below nine in ten; swings before | render | match |
| same side in 17 of 18, 2019 spawning splits | render `both` | match |
| Buck no 2016, no days in the bundle; 9 recent years | station_daily.rds | match |
| coverage 0.834–0.867, not called 90 % | coverage report | match |
