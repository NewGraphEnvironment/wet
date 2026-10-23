# Code-check round 4 (#110): terminating enumeration, branch e2d083b...97fac39

## Checklist read

- `code-check.md`: the index, then the prose of all 14 H3s under `## Mechanisms` (tables skipped), in full: "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A proxy is not the property", "Verification that reads its own output", "A guard's scope, escape hatches, and remedies", "A fix lands in one of two callers that share a harness", "Restore the bug and prove the guard fires", "A shared working tree…", "A wrapper's exit is not the work", "Zero-length, empty, and unset…", "The probe is broken before the world is", "Written data outlives the fix", "Serialization loses meaning silently", "One fact derived twice". The stand-alone and security H3s: index only.
- `code-check-r.md`: the index only (all 111 headings and first sentences). Rules applied from it: "Moving prose into a code chunk hides it", "A duplicate knitr chunk label", "`on.exit()` at a script's top level", "`tempfile()` lives in the session tempdir", "`vapply(..., USE.NAMES = FALSE)`".
- `code-check-shell.md`, `code-check-spatial.md`: not read. The diff has no shell or spatial code.

Probes, all run from scratchpad copies: a parse of `git diff -U0 e2d083b...HEAD` against the HEAD files' chunk fences (`r4/enum.R`); a prose scan of the three Rmds for plain package names, issue numbers and dated words (`r4/prose.R`); `monthly_values.rds`, `station_daily.rds`, `monthly_map.rds`, `segment_values.rds` and `segment_map.rds` provenance; `wet:::wet_software_cite()` on all nine article packages (installed wet 0.4.17 has it); the publish report's part rows summed by dataset.

## Mechanism

Round 3's mechanism is still at work, one level back. 97fac39 narrowed monthly-flow's closing paragraph from "numbers" to "flows" and moved the check claim onto them. But the sentence it kept, "checked every one against what it was built from", was copied from the summary line in `data-raw/monthly_vignette_data.R`'s header (:10-11, "Every published value bundled is checked against what it was built from"). Further down (:38-44, :295-300), that header contradicts itself: months 1-12 and the days rest on the publish report for any watershed the reduced fit bundle does not hold. The bundle records which watersheds it did hold (`shape_stations`: 08EE004 and 08EE013, not 08EE003). So the prose took the source's compressed claim and repeated it, and the condition the compression dropped is visible only in the paragraph it summarises (code-check.md, "Compression runs both ways"). "The flows in this article" is round 3's population error again. The article draws and quotes the gauges' observed flows, and its own legend labels them "Observed (HYDAT)".

## Counts

- Added lines in `git diff e2d083b...HEAD -- vignettes CLAUDE.md`: 145, of which 97 are prose outside code chunks (segment-discharge 43, station-flow 39, monthly-flow 14, CLAUDE.md 1) and 39 are in chunks; the rest are blank.
- Those 97 lines group into **47 sentences** and 2 headings (`## Software and citation` in segment-discharge and station-flow). Sentences re-flowed onto an added line count, though their words are older (S2a, S6b, T1a, T5a, T7, and C1-C3 and C5-C9 on CLAUDE.md:50).
- Sentences making a provenance, source, completeness, quantity, quantifier or software claim: **47 of 47**.
- Verdicts: **40 hold, 4 fail, 3 judgement**.
- Completeness: the table has one row per sentence (S1-S18 with S2a and S6b, T1-T13 with T1a and T5a, M1-M5, C1-C9). The Data lines (S17, T12, M5) are one sentence each, and their sub-claims are checked inside the row. Nothing from the 97 lines is unassigned.
- New `stopifnot()` arms in the diff: 6, in 5 calls. All 6 can fire (listed below).

## Enumeration (claim | file:line | evidence | verdict)

"R3#n" means the sentence is unchanged since 1ef7ed9, and I kept round 3's verdict and evidence.

### segment-discharge.Rmd

| # | claim | file:line | evidence | verdict |
|---|---|---|---|---|
| S1 | "The R package `wet` publishes the mean flow … for the year, each month and each day" | :107-109 | R3#1 | holds |
| S2a | "…the manifest, which lists every part with its rows, size and md5" (re-flowed) | :110-111 | catalog columns key, rows, bytes, md5 (monthly_vignette_data.R provenance `parts`) | holds |
| S2 | "The build this article reads has N parts, X GB, built on D at `wet` commit C" | :111-113 | R3#2 | holds |
| S3 | "New Graph's fork of `fwapg`, PostgreSQL tools … places PCIC's outlets … spreads flow … by drainage area" | :129-132 | R3#3 | holds |
| S4 | "`wet`'s own estimate, after Chapman et al. (2018)…" | :134-137 | R3#4 | holds |
| S5 | "The balance takes every segment with a value in the Liard … where routed flow is far below the balance's" | :177-179 | R3#5 | holds |
| S6 | "Read the parts from the bucket with the R package `duckdb`" | :226 | R3#6 | holds |
| S6b | "`scenario`, `forcing` and `source` are in each part's path, not the file…" (re-flowed) | :226-228 | the Hive keys (CLAUDE.md publishing paragraph); read-duck chunk uses `hive_partitioning` | holds |
| S7 | "Or load it into `PostgreSQL` beside the Freshwater Atlas" | :246 | R3#7 | holds |
| S8 | "The zone adjustment is kept by decision." | :370 | R3#9 | holds |
| S9 | "On headwater basins it does not beat raw P − ET, and zones with too few gauges … get none" | :370-372 | R3#9, R3#10 | holds |
| S11 | "The routed values … and the picks on the map are the published product's, read on D from the build at `wet` commit C; the routed values were held equal to `fwapg`'s…" | :379-382 | R3#11, R3#12. The new guard :45 `identical(map$provenance$built, prov$built)` holds the one read date (both 2026-10-20; segment_vignette_map.R:155 `built = Sys.Date()`) | holds |
| S12 | "The province counts are from the segment table that build was cut from" | :382-383 | R3#13 | holds |
| S13 | "The balance's scores are its held-out predictions from the fit on HYDAT R…" | :383-384 | R3#14 | holds |
| S14 | **changed in 97fac39**: "The build's own check of its published flows is its report" | :384-385 | discharge_publish_20260717.txt:27 "every published flow". Compared counts equal the published rows: routed 40,524,444 + 3,377,037 = 43,901,481 (reader row :52); balance 58,889,207 (:53); watershed parts 41,904,356 = the sum of the 24 `watershed_monthly` part rows; daily 1,232,618,505 and 1,653,427,735 (:54-55) | holds |
| S15 | "Cite `wet` by the DOI above, which resolves to its latest release" | :410 | R3#19 | holds |
| S16 | "How the balance is built, and each of its choices tested: [the water balance method]" | :410-412 | carried from main's wording; research/water_balance_method.md exists | holds |
| S17 | Data line (routed flow and its fork commit, FWA through fwapg, HYDAT release, climr, CGIAR floored by Fu–Budyko, GLO-90, ERA5-Land snow for the shares, BC Hydrologic Zones) | :414-428 | R3#20-29; guard :406-407 `aet == "cfu"` | holds |
| S18 | Method: Chapman, Kerr and Wilford (2018) | :430-434 | R3#30 | holds |

### station-flow.Rmd

| # | claim | file:line | evidence | verdict |
|---|---|---|---|---|
| T1a | "Adults migrate upstream from X … fry move downstream from Z" (re-flowed) | :191-193 | `w_start` from life_history_bulk.csv | holds |
| T1 | "This article uses the R package `wet` to ask how flow in those three windows over the last five years … compares with B at two hydrometric stations near Houston" | :193-195 | R3#32 | holds |
| T2 | **changed in 97fac39**: "These are the calls that produced the flow statistics." | :308 | The window means, min7, baseline, departure and trend come from these calls (stats chunk :139-188). The hydrograph's daily median and middle-half band (:466-471, `stats::quantile` over `daily`) come from no call in the recipe. They are drawn but not quoted as numbers | judgement: "flow statistics" reads as the next sentence's baseline/departure/trend; strictly, the daily band is one more statistic the calls did not produce |
| T3 | "Baseline, departure and trend come from the R package `cd`, and the real-time feed is read with the R package `tidyhydat`" | :308-311 | R3#33, R3#34 | holds |
| T4 | "The calls need HYDAT, the water-temp-bc archive and the ECCC real-time feed, so the article runs on a cached copy…" | :311-314 | R3#35 | holds |
| T5a | "The slope of each window's departure … for the window mean and its lowest seven-day mean" (re-flowed) | :594-595 | `cd_trend` on q_mean and q_min7 | holds |
| T5 | "The slope is Theil–Sen's, the median of the slopes between every pair of years, so one extreme year moves it little" | :595-596 | R3#37 | holds |
| T6 | "Each is tested with Mann–Kendall's test … p is the chance of a trend at least that consistent if flow had none" | :596-598 | R3#38 | holds |
| T7 | "Of N slopes, n are significant at p < α" (re-flowed) | :598-599 | computed from `trend` | holds |
| T9 | **changed in 97fac39**: "The flows in this article are cached from HYDAT release R, with provisional and real-time flows retrieved D; the windows are NGE's life-history table at commit C, and the catchment areas are the Freshwater Atlas's, through `fwapg`." | :648-652 | All flows come from station_daily.rds (:29, the only flow bundle): sources hydat 1930-09-09..2025-03-04, provisional 2025-03-03..2026-09-12, realtime 2026-09-13..09-30; `hydat` "2026-07-17"; `retrieved` 2026-10-01 = `Sys.Date()` at station_vignette_data.R:50. Windows from life_history_bulk.csv, `knowledge_sha` (:26). Catchment areas: `fwa_watershedatmeasure()` area_ha through fwapg (scripts/vignette_map_lib.R:24-41), and the 24% follows from them. No number in the article is left unattributed | holds |
| T10 | "The map's layers come from the Freshwater Atlas, BC Geographic Names and HYDAT's station locations" | :652-653 | R3#40 | holds |
| T11 | "Cite `wet` by the DOI above…" | :664 | R3#19 | holds |
| T12 | Data line (HYDAT R, ECCC provisional via water-temp-bc, real-time feed; Gottesfeld and Rabnett 2007; FWA through fwapg; BC Geographic Names) | :666-674 | R3#43-45 | holds |
| T13 | Trends: Mann 1945, Kendall 1975, Theil 1950, Sen 1968 | :676-684 | R3#46 | holds |

### monthly-flow.Rmd (every sentence verified fresh)

| # | claim | file:line | evidence | verdict |
|---|---|---|---|---|
| M1 | "The flows in this article are the published product's." | :826 | The article draws and quotes the gauges' observed flows: observed monthly means (`obs`, :187-215: calibration `obs_mm` converted to m³/s, and 08EE003 from `station_daily.rds` HYDAT days), the hydrograph's "Observed (HYDAT)" line (`flow_source` class `observed`, inst/cartography/wet_segment.csv:3), "its May–June flow is X m³/s against Y at the gauge" (:435-437), and the window table's "Daily record" and "Monthly, day-weighted" columns (:782-783, from `station_daily.rds`). None of these are published, and `station_daily.rds` was bundled by data-raw/station_vignette_data.R, not by the script the next sentence names | **fails** |
| M2 | "`data-raw/monthly_vignette_data.R` bundled them on D from the published build at wet C, and checked every one against what it was built from before writing them." | :827-829 | The bundle's own `published_check` (rows 3, 5, 7) compared balance months 1-12 against the recomputed fit for only 26 of the 39 Bulkley balance months (2 segments × 13), and balance days for 730 of 1,095 (2 × 365). `prov$shape_stations` is `c("08EE004", "08EE013")`, and check 3 compared 2 watersheds. The 12 balance months 1-12 and the 365 balance days on Houston's (08EE003) segment were never compared with what they were built from. The script says so itself (monthly_vignette_data.R:38-44, "the rest of the months rest on the publish report's value-by-value check", and :295-300 for the days). Check 8 holds the published days' means to the published months, which is published against published. The article uses those values: Houston's balance line in the hydrograph, and the "Water balance (months)" and "(days)" cells and "the balance stays several times the gauge in both late-summer windows" (:774-775, guard :754 `b003 > 200`) | **fails** |
| M3 | "The scores compare them, and the water balance held out by its fit on HYDAT R, with HYDAT's observed runoff." | :829-831 | Routed PCIC is scored as published (`routed_mm` from `pub_gauge`), and the balance held out (`wb_mm` = `cv_ann`/`cv_share`, fit_20260717). Observed runoff is `cal$obs` from HYDAT 2026-07-17. "them" takes in the published balance, which the scores do not use, but the clause after "and" says what they do use | judgement |
| M4 | "The build's own check of its published flows is its report." | :831-833 | as S14 | holds |
| M5 | Data line: routed flow from PCIC (hydromosaic; fork at `routed_commit`); FWA through fwapg; HYDAT R; "for the balance" climr normals, CGIAR AET held no lower than Fu–Budyko, GLO-90, ERA5-Land snow through `cd` for its monthly shares, BC Hydrologic Zones; Chinook windows from Gottesfeld and Rabnett | :849-865 | `prov$routed` "pcic.discharge_monthly (PNWNAmet historical 1981-2010), built by NewGraphEnvironment/fwapg at 7c30f58"; `routed_commit` 7c30f58; HYDAT 2026-07-17, the same in `station_daily.rds`; guard :842 `aet == "cfu"`, `share_spec == "snow"`; `share_method` donor matches on the static predictors (R3#26-27); `keep_adjust` is required by monthly_vignette_data.R (`stopifnot(fits$keep_adjust, …)`), so zones feed it; windows guard :250. **Missing:** the map's place labels (Houston, Telkwa) are BC Geographic Names (monthly_map.rds `places`; data-raw/monthly_vignette_map.R:14, `vm_places()` reads `WHSE_BASEMAPPING.GNS_GEOGRAPHICAL_NAMES_SP`). The sibling station-flow Data line (:674) and map sentence (:652-653) name it | **fails (completeness, low)**: the same gap round 2 found in segment-discharge's Data line |

### CLAUDE.md:50 (the line changed, so all of its sentences are re-added)

| # | claim | evidence | verdict |
|---|---|---|---|
| C1 | monthly-flow "is about months 1–12 of the published product" | article scope | holds (unchanged) |
| C2 | "draws both sources' hydrographs at three Bulkley gauges … with the Chinook windows" | hydrographs chunk | holds (unchanged) |
| C3 | "gives each window's flow two ways … and scores both sources month by month … both over 1981–2010" | windows chunk; `period_of()` guard :74-75 | holds (unchanged) |
| C4 | **changed**: "All three articles carry #110's writing convention (software in code font and linked, no issue pointers or dated words in prose, and a closing 'Software and citation' section whose package lines come from the internal `wet_software_cite()`; the word caps … monthly-flow has none)" | The section, the helper and the caps hold (R3#49-50; monthly-flow has no wordcount chunk). Issue pointers: none in any prose (prose scan). Code font fails in monthly-flow: :828, "from the published build at wet `r …`", is plain `wet` on a line 97fac39 rewrote (segment-discharge's matching line :113 and :380 says "at `wet` commit"); :169 "[PostgreSQL](https://www.postgresql.org/)" is linked but not in code font (segment-discharge :246 is [`PostgreSQL`]) | **fails (low)** |
| C5 | "It reads monthly_values.rds, built by … under the same guards … parts verified before and after the read" | monthly_vignette_data.R: `vd_verify(parts)` before and after, `vd_published`, `vd_routed_check` | holds (unchanged) |
| C6 | "The bundle's days are checked as the publish checks them: routed PCIC routed again …, the balance made again from its published months and shape_daily.rds, and each month's day mean held to the published month" | the balance's days are made again only on the held segments (730 of 1,095) | judgement (unchanged text; C8 states the gap for months but not for days) |
| C7 | "The held-out monthly balance is the one wb_validate.R stored …, refused unless …" | monthly_vignette_data.R `cvr` checks | holds (unchanged) |
| C8 | "the balance's months are recomputed where it can and otherwise rest on the publish report" | monthly_vignette_data.R:38-44; bundle `shape_stations` | holds (unchanged), and it contradicts M2 |
| C9 | "Colours come from inst/cartography/wet_segment.csv (`flow_source`)" | wet_segment.csv:3-5 | holds (unchanged) |

### New `stopifnot()` arms in the diff (each can fire)

| guard | file:line | fires when | current value |
|---|---|---|---|
| `identical(map$provenance$built, prov$built)` | segment-discharge.Rmd:46 | segment_map.rds is rebuilt on a day other than segment_values.rds, e.g. map built 2026-10-21 | both 2026-10-20 |
| `identical(prov$aet, "cfu")` | segment-discharge.Rmd:407 | the fit ships `"cgiar"` (or `aet` is absent: `identical(NULL, "cfu")` is FALSE) | "cfu" |
| `length(cite) == 1` (wordcount) | segment-discharge.Rmd:442 | the heading is renamed (0) or duplicated (2) | 1 |
| `length(cite) == 1` (wordcount) | station-flow.Rmd:692 | the same | 1 |
| `identical(prov$aet, "cfu"), identical(prov$share_spec, "snow")` | monthly-flow.Rmd:842 | the AET is `"cgiar"`, or the shares ship `"static"` | "cfu", "snow" |

None of them guards M1 or M2. The values that would have to be guarded are `prov$shape_stations` and the published_check counts against `nrow(v$segments)`.

### R/wet_software_cite.R and the three citation chunks

No defect. `requireNamespace()` refuses a missing package before `write_bib()`. `on.exit(unlink(bib))` is inside a function, so it fires. `vapply(..., "", USE.NAMES = FALSE)` returns a plain character vector. `RemoteSha` NULL, NA, short or upper-case gives no commit (tests :11-19). A citation's text style wraps onto lazy-continuation lines. I printed all nine packages' lines: none of the continuation lines starts with a list or heading marker (`2.2.2,` and `1.5.2,` are not ordered-list markers), so each bullet stays one list item. The roxygen fix in 97fac39 (":4 the first DOI its citation carries (for wet, its concept DOI)") matches `wet_software_line()` :50 and the test :21-27. The three chunk comments say the same thing.

## Findings

1. **monthly-flow.Rmd:827-829, "checked every one against what it was built from": a universal quantifier the bundle's own record contradicts.** This is round 1's segment-discharge finding, repeated in the sibling article by 97fac39. The bundle compared the balance's months 1-12 and its days with what they were built from on only two of the three Bulkley segments (`published_check` rows 5 and 7: 26 of 39 months, 730 of 1,095 days; `prov$shape_stations` = 08EE004, 08EE013). Houston's (08EE003) 12 balance months and 365 balance days were not compared. data-raw/monthly_vignette_data.R:38-44 and :295-300 say they "rest on the publish report", and the article shows exactly those values: Houston's balance line in the hydrograph and its window-table cells, with the claim that the balance stays "several times the gauge" (:774-775). The sentence was copied from the script's header summary (:10-11), which its own later paragraph contradicts. Fix: say what was checked, for example "checked the routed values, and the balance's values where the bundled fit holds the watershed, against what they were built from; the rest rest on the build's check (below)". Guard it with `prov$shape_stations` (or the compared counts) so the sentence fails at render if the set changes. The load-chunk comment at :33-34 ("every value below … each checked … by data-raw/monthly_vignette_data.R") and the script header :10-11 carry the same false claim (comments, not rendered).

2. **monthly-flow.Rmd:826, "The flows in this article are the published product's": the population is wider than the claim (round 3's mechanism, still open after the narrowing from "numbers" to "flows").** The article draws and quotes the gauges' observed flows: the "Observed (HYDAT)" hydrograph line, "its May–June flow is X m³/s against Y at the gauge" (:435-437), and the window table's "Daily record" and "Monthly, day-weighted" columns. Those come from HYDAT, and for the daily record and 08EE003 through `station_daily.rds`, which data-raw/station_vignette_data.R bundled, not the script the next sentence names. Fix: "The routed and balance flows in this article are the published product's; the observed flows are HYDAT's (release R), the daily record cached as in the station-flow article." Or scope the sentence to "the sources' flows".

3. **Low. monthly-flow.Rmd:849-865, the Data line omits BC Geographic Names**, the source of the map's place labels (Houston, Telkwa; data-raw/monthly_vignette_map.R:14, `vm_places()`). This is the gap class round 2 found in segment-discharge, and the sibling station-flow names it (:652-653, :674). Fix: add "; place names from BC Geographic Names".

4. **Low, not rendered. CLAUDE.md:50 "All three articles carry … software in code font" fails in monthly-flow.** :828 has a plain `wet` on the line 97fac39 rewrote (segment-discharge's twin lines use "`wet` commit"), and :169 links PostgreSQL without code font (segment-discharge :246 uses [`PostgreSQL`]). Fix: the two spans in monthly-flow, or narrow the CLAUDE.md sentence.

Noted, not findings: T2 ("the flow statistics" leaves out the hydrograph's daily quantile band, which is computed in the article from the cached days); M3 ("them" takes in the published balance, which the scores do not use, but the clause after it names the held-out balance); C6 (CLAUDE.md says the balance's days are made again, which happens only on the held segments; the text is unchanged on this branch).

/Users/airvine/Projects/repo/wet/planning/active/review-round4.md
