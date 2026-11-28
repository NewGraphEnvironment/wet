## Checklist read
- index: read from file. The first part came through the tool; the same index text is in the session's loaded conventions.
- code-check-python.md: in full.
- code-check.md: the prose of "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A proxy is not the property", "Verification that reads its own output" and the start of "A guard's scope, escape hatches, and remedies" (the read was cut at 29,000 characters, partway through it). The remaining Mechanisms H3s were NOT re-read this round.
- code-check-r.md, code-check-shell.md, code-check-spatial.md: no full sections. The diff is Markdown prose, and no heading seen names a shape it uses.
- diff and changed files: the four notes were compared with origin/main. chinook_sites.md, station_flow_departure.md and discharge_publish.md were read from file; fwapg_mad_method.md through git diff plus lines 80-119 from file; the README rows through git diff. planning/archive hunks were not reviewed (accepted as verbatim).

## Mechanism
Each defect from rounds 1 and 2, and each one below, comes from the same step. Text written when it had one referent (one route, window set, statistic, site or run) was merged into a document or paragraph that now holds several. The qualifier that named the referent was in a heading, a neighbouring section or the document's date, not in the sentence. The merge changed or dropped that carrier and left the sentence and its figures alone. The figures still match some report row, so a check of figures against reports passes. The test that catches it is: for each unqualified sentence, list every referent now in scope and check the figure against each one.

## Enumeration
This covers merged, widened or condensed claims and unqualified summaries, lists and ranges. Each row is one claim group; there are 53 rows: 29 chinook, 11 station-departure, 8 discharge, 3 fwapg and 2 index. 50 hold, some with the limit stated in the row; 3 are findings (C16, C24, S9).

| # | note: claim | verdict (source) |
|---|---|---|
| C1 | chinook: use table and Swift/Naver/Gosnell selection sentences | holds (chinook_sites_use.txt) |
| C2 | 08KA012 14 windows 1985-1998; 08KE014 18 windows, across both window sets | holds (all four site reports; Naver lacks 1959 and 1961, and the range is still correct) |
| C3 | "2 to 4 gauges per box are uncovered" | holds (4, 3, 3, 4, 2, 4, 4) |
| C4 | held-out weighting table, 7 rows | holds (section 6) |
| C5 | shipped-route score table ("each statistic" means mean and min7; cov_day is not tabled) | holds for what it shows |
| C6 | migration mean >= 0.5 in every row; spawning below only at Swift | holds |
| C7 | min7 "least well at most sites"; 4 of 8, and 7 on distance | holds |
| C8 | extension race, both window sets; pools of 11 and 10 | holds |
| C9 | shipped change table, 28 cells | holds (sections 5 and 6, rounding) |
| C10 | filled-in table, 20 cells | holds (section 5) |
| C11 | spawning-mean bullet | holds |
| C12 | migration-mean bullet | holds |
| C13 | spawning min7 bullet | holds |
| C14 | migration min7: no common sign, three clear cases, low scores | holds (scores for the three cited cases are all below 0.5) |
| C15 | interval coverage 0.904-1.000 and >= 0.92, now including UFRA and COTR | holds |
| C16 | years figure's OLS band, held-out coverage 83-85 % | **wrong as unqualified** (finding 3) |
| C17 | 2016-2025 has 9 or 10; 1951-1980 exceptions 10, 30, 14, 18, 17 | holds |
| C18 | Naver filled-in donors since 1999, now two window sets | holds (BULK and COTR per-year rows agree) |
| C19 | carried snow R2, both windows; "same holds" under own windows | holds (qualitatively for own windows: spawning 0.11, 0.04, 0.00) |
| C20 | snow change 1951-1980 to 2016-2025 | holds |
| C21 | measured snow gauges: R2 ranges, melt-date sentences | holds |
| C22 | snow-gauge selection rule | holds |
| C23 | Gosnell normals, both window sets | holds |
| C24 | Gosnell normal's error (+0.04, +0.19, +21 %, +47 %) after both normals | **wrong for Morice** (finding 1) |
| C25 | routed PCIC picked at all 29 | holds for both (58 of 58 rows in each report) |
| C26 | Maxan donor years by window | holds |
| C27 | Maxan before/after table, distance 1951-1980 figures, r 0.93 and 0.78 | holds |
| C28 | pilot snow bullets, including years since 1950 | holds (table and intercepts compared with the Maxan site snow report; pilot-only figures rest on round 2) |
| C29 | donor-test section | holds as carried over (light edits; not re-derived) |
| S1 | departure: sources table and join paragraph | holds (540 days in code; archive dates per round 2) |
| S2 | non-HYDAT numbers read from the publishers | holds (default sources include hakai) |
| S3 | ice, provisional winter, seasonal gauge, August bullets | holds (rounds 1 and 2 recomputed; not repeated) |
| S4 | method-choice bullets | holds as carried over |
| S5 | 2016-2025 section, "every window", 11 of 12, 17 of 18 | holds (per round 2) |
| S6 | pilot pool, extension and carry figures | holds (Maxan site report sections 1-3 for pool, race and carry; block-regression figures per round 2) |
| S7 | later sites keep OLS; ratio picked at two other boxes | holds |
| S8 | covariance_pick province-wide paragraph | holds against the old text |
| S9 | snow method paragraph: "1950-2024", "all 24 fits" under a generalised heading | **fragile** (finding 2) |
| S10 | snow headline, parity, intercepts (marked as pilot) | holds |
| S11 | "a site's extended series ... fitted on a few years" (was Maxan's, five) | holds loosely (Maxan 5, Swift 14, Naver 18 target years) |
| D1 | discharge: live build, dataset table, sources | holds (build report; manifest per round 1) |
| D2 | naming and layout bullets as condensed | holds |
| D3 | receipt and fit | holds (report lines) |
| D4 | check table and the sentence on unchecked columns | holds (report) |
| D5 | three vignette scripts call vd_published() | holds (grep) |
| D6 | routed days, clamp, day-mean, balance figures | holds (daily report) |
| D7 | 4,532,843 = 3,213,337 + 1,319,506; 15,040,448,264 total | holds (report; sum reproduced) |
| D8 | load cost, 2x and 4x, index created only with the table | holds (arithmetic; R/wet_db_load.R) |
| F1 | fwapg method steps | holds (per round 2's read at 6aa6c2d; not re-fetched) |
| F2 | Fraser figures, including 186 near-edge centroids | holds (100_report.txt) |
| F3 | "since that run" and accumulation bullets | holds as far as checked (40 test seeds); the 13 s and 2.1 GB first-run figures were not re-derived |
| R1 | research/README: fwapg and discharge rows | holds |
| R2 | research/README: departure and chinook rows | holds |

## Findings

- **[severity: bug]** research/chinook_sites.md:115, "Gosnell's normal". The merge added "24.0 and 5.3 under the Morice's" to the parenthesis, just before "**Its** error at the 29 departure-pool gauges ... has a median of +0.04 (migration) and +0.19 (spawning). In the spawning window that is a median of +21 % and an upper quartile of +47 %." Those figures are the Bulkley windows' only (`departure_site_gosnell_bulk_20260717.txt`: median 0.039 / 0.187, spawning q75 0.384). `departure_site_gosnell_morr_20260717.txt` gives median **0.046 / -0.003** and spawning q75 **0.232** (+26 %). So the spawning median is about 0 %, not +21 %. A reader applies the bias to both normals, and it is wrong for the 5.3 m3/s one. origin/main's sentence named only the Bulkley normals. Fix: say "Under the Bulkley windows its error ...". Either add the Morice figures (+0.05 and -0.00; spawning upper quartile +26 %) or leave them out explicitly. "The spawning-window normal is the weak part" can still hold under Morice by spread (median absolute log error 0.34 spawning against 0.16 migration), but not by that bias. "29" and "routed PCIC is the pick at all 29" hold for both window sets.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** research/station_flow_departure.md:92-96, "Snow and the window flows". origin/main's heading was "Snow and the window flows **at the pilot** (#121)". The new heading drops "at the pilot" and moves the section under the general "At an ungauged or short-record site". The first sentence is a present-tense method statement: "regressed on both, **1950–2024**". The paragraph then says "all **24** fits are reported". 1950–2024 and 24 describe the pilot. The site snow runs are the current method, and each report reads "OLS over every year **1950-2025**". Their Naver and Swift series reach 2025 (for example 08KH006, 75 years to 2025), and they have their own fit counts. The pilot is named only indirectly, through "registered in scripts/departure_snow.R". Fix: open with "In the pilot, ...", or give the method's range as the site reports do and tie 1950–2024 and the 24 fits to the pilot.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** research/chinook_sites.md:101. "It does not call the years figure's OLS band a 90 % range, because its held-out coverage in the site reports is **83–85 %**." The figure draws both windows' means (the caption in `flow-change-sparse-gauges.Rmd`: "Each ... window's mean flow"). 83–85 % is the **migration**-mean coverage alone (BULK reports: Maxan 85.0, Swift 82.7, Naver 85.3). For the **spawning** mean the same reports give OLS coverage of **88** (Maxan), 85 (Swift) and 86 (Naver); see the "spawning mean" row of each sensitivity table. The sentence is unchanged from origin/main, and the article's code comment (line 49) says the same thing. It is still inside a note now stamped "re-read: every figure below". Fix: write "83–85 % on the migration-window mean (85–88 % on the spawning mean)".
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

No script under scripts/ or data-raw/ was run. No request was made to PCIC or any other network host. The only file written in the tree is this one.
