# Review round 3: branch 103-routed-pcic-over-1981-2010-switch-the-pc (2675636...7771eef)

Reviewer: code-check round 3, 2026-10-19, on m1. Nothing in the working tree was modified; vignettes were
rendered and tests run from a `cp -r` copy in the session scratchpad.

## Mechanism

Rounds 1 and 2 found prose that states a state of the world (publish state, upload, which build is live), written
at one moment and not rechecked when that state moved. This round found the same thing in a second form. The
branch updates hand-written restatements of mutable facts (the run's period, its fingerprint, the live build,
counts, scores, "every"/"each" quantifiers), and **the places to update come from a list drawn up at planning
time**: findings.md's "Period text and assertions", and Phase 5's line list ("`period` is a column", "the routed
row of the value-check table", the #58/#57 block, `discharge_publish.md:62`, CLAUDE.md :49/:63). No grep for the
*values* that changed was run (`178035348`, `1951`, the old per-gauge routed errors). The list and the set of
sentences that state those values agree only on the listed lines. Off the list:

- the sentence right under the value-check table, whose row the branch did edit, still gives the old run's fingerprint;
- the SALR per-gauge routed errors are still the 1951–2012 run's.

A second strand of the same mechanism: a quantifier carried over from the issue body ("Every routed value does
[move]") was never measured, and the Status paragraph repeats it as "every routed value changed".

## Enumeration (each sentence/claim: location, verdict, evidence)

Every sentence the diff adds or keeps that states a publish state, period, live build, count or score:

| location | claim | verdict | evidence |
|---|---|---|---|
| CLAUDE.md:36 | run read is `PNWNAmet, historical, 1981-2010` since #103; 7c30f58 for both runs | true | `R/wet_segment_monthly.R:93` `period = "1981-2010"`; report headers name fwapg 7c30f58 |
| CLAUDE.md:49 | monthly article scores both "over 1981–2010 (#103). Its gaps are #67 and #6" | true | vignette "What's next" lists #67 and #6; chunk guard `identical(period_of("pcic_routed"), period_of("wet_balance"))`; rendered text "Both sources cover 1981–2010" |
| CLAUDE.md:63 | source series "PNWNAmet daily 1951–2012"; "wet reads the 1981–2010 run (#103; the 1951–2012 run until then)" | true | pcic.runs has both runs; pin above |
| R/wet_segment_monthly.R:18-19, man/wet_segment_monthly.Rd | from = "fwapg" reads 1981-2010 | true | `wet_segment_sources()` |
| README.md:36-37 | example output | true | `wet_segment_monthly(NULL, 17057325, groups = "BULK")` run on live parts today prints exactly `pcic_routed 118 32 24 20 55 221 299 250 182 118 95 71 46` / `wet_balance 118 45 50 48 86 220 303 203 109 106 98 87 62` |
| README.md figure caption/alt | routed most of province, balance far north and Nechako | true | `segment_map.rds` provenance wet_commit 94deeb5, built 2026-10-19T06:08:31Z = live manifest |
| data-raw/segment_vignette_data.R:126, :224 | published routed rows carry the run's period | true | rds `provenance$routed_period == "1981-2010"`; test passes |
| data-raw/monthly_vignette_data.R header | no period element | true | rds names `segments, gauges, provenance`; test-vignette_data.R 7/7 blocks pass (NOT_CRAN=true) |
| scripts/segment_output.R:33 | routed 1981-2010 since #103, balance 1981-2010 | true | segment report header "periods: routed 1981-2010, balance 1981-2010" |
| scripts/pcic_routed_lib.R:8 | the package names the run, the one place #103 changes | true | `routed_run` reads `wet_segment_sources()` |
| vignettes/segment-discharge.Rmd:118, :298, caption | routed period from the published rows; both scored over 1981–2010 | true | rendered: "Routed PCIC (pcic_routed, 1981–2010)"; guard at :46 holds |
| vignettes/segment-discharge.Rmd (computed) | 67 parts, 1.84 GB, wet 94deeb5; 3,154,131 / 1,378,712 / 222,906; routed closer at 169 of 290; 24.2/27.6/27.5 % | true | rendered values = manifest, segment report and routed report (169/290 = 58 %) |
| vignettes/monthly-flow.Rmd | both sources and the gauges cover 1981–2010; routed −11 % Mar–Apr, +16 % Jul–Aug; per gauge 61/68/41 % of 279; recorded in #67 | true | rendered; matches `evidence/period_probe.txt` (−11.5, +15.8, 61/68/41); #67 body now on the 1981–2010 run |
| vignettes/monthly-flow.Rmd (unchanged, data moved) | Buck Creek: the gauge peaks in May "and so does routed PCIC" | true | bundle: routed 08EE013 May 26.5 m³/s is its maximum |
| research/discharge_publish.md:3 | Verified 2026-10-19, published | true | S3 Last-Modified of all 67 parts 2026-10-19 14:45:29–14:50:29Z, manifest 14:50:30Z |
| :5 | replaced on 2026-10-19 by the 1981–2010 build, about 5 min | true | Last-Modified span of the 67 parts is exactly 5:00 |
| :5 | built at wet 94deeb5, segment table 5215906 | true | live manifest `provenance`: wet_commit 94deeb5, segment_commit 5215906 |
| :5 | 67 parts, 1.84 GB, 43 + 24, 102,790,688 and 41,904,356 rows; row counts those of 7c62b9e | true | manifest: 43/24 parts, row sums 102,790,688 / 41,904,356, 1.836 GB |
| :5 | **"every routed value changed"** | **false** | see Finding 1 |
| :5 | 4,733 picks moved | true | `evidence/pickmove.txt` 1,720 + 3,013 |
| :5 | BUILD rerun at 00a3805, every check passing, 555,857,796 compared, 0 differing, 67 of 67 identical | true | report: sum of the 8 compared columns = 555,857,796; "67 of 67 here" vs 94deeb5 |
| :5 | before the upload, 35 of acb820f's 67; every routed part and the balance parts of basins where a pick moved changed | true | 9b601dc report "35 of 67"; 20 routed parts + 12 balance segment parts with a moved pick (pickmove.txt) = 32 = 67 − 35 |
| :5 | 1d0faf8 58 of 67, 71af15a 67 of 67 | true | report at 2675636 "58 of 67"; prior text |
| :50 | `period` column: both 1981–2010 since #103 | true | pickmove.txt periods; live parts read by the data scripts |
| :62 | live manifest names pcic.discharge_monthly 1981–2010, fwapg 7c30f58, fingerprint 178918222.786650 | true | live manifest `sources[pcic_routed].provenance` |
| :71 | value-check table row "since #103 its run PNWNAmet historical 1981–2010"; counts | true | report |
| :77 | **"equals the table's fingerprint (178,035,348.248310 m³/s)"** | **false** | see Finding 2 |
| research/water_balance_method.md:76-83 | 290 of 315; 24.2/27.6; 13.1/18.0; 63/54; +1.4/+9.0; 58 %; headwater 28.3/31.0; nested 11.7/17.2; 1,000–10,000 11.9/22.3; Fraser 30.7/28.4; Peace 19.0/19.2; Columbia 24.6/32.7; Coast 19.2/25.1; median better and closer at > half in all four | true | `data/checks/pcic_routed_compare_20260717.txt` (medians 11.9<16.6, 17.6<23.8, 13.0<15.1, 11.1<15.9; closer 61/59/55/60) |
| :80 | old run 24.1/13.0/+0.2/59; total 0.5 % higher; bias about +1 point overall; Columbia +3.8, Peace −3.9; Mar–Apr −19.5 → −11.5, Jul–Aug +18.7 → +15.8; about 40 % and 15 % | true | report at 2675636 (Columbia +7.8 → +11.6, Peace +9.4 → +5.5); 178918222.79 / 178035348.25 = 1.0050; period_probe.txt; 8.0/19.5 = 41 %, 2.9/18.7 = 16 % |
| :82 | without the 11, 21.5 / 27.2 | true | report "21.5 % routed, 27.2 % balance" |
| :83 | 178: 25.3/28.0/30.3; 171: 25.0/25.3/30.5; 112: routed 18.1, balance 23.3 | true | report |
| :84 | both cover 1981–2010; observed is complete years within 1981–2010, at least 10 | true | report "Not like for like" |
| :86 | 26.8 % of flips in the Nechako groups | true | segment report "26.8 %" |
| :98 | 7 fall to balance, 6 closer; pick 23.0 / routed 24.2 / balance 27.6; 315: 23.3 / 27.5; old 22.9/24.1/27.6 and 23.2/27.5 | true | both reports |
| :102-103 | 3,154,131 (69.6 %), 1,378,712; 222,906, 6.6 %, Fraser 113,604; 4,733 = 3,013 + 1,720, 0.10 %; old 3,152,838 / 1,380,005 / 224,199 | true | segment reports (222,906 / 3,374,133 = 6.61 %; 4,733 / 4,532,843 = 0.104 %; net 1,293 consistent across all three) |
| :105-108 | Nechako 26.8 %; GUIC 73 %; 1410 11.8 %, 1400 10.9 %, 1000/1200 5.1 %, 1250 0.6 %, 1450 5.3 %; order 1 5.4 %, order 7 0.9 % | true | segment report (GUIC 72.7) |
| :110 | routed months sum to 0.97–1.02 of annual (median 1.003; 0.93–1.02 old) | true | re-queried in round 1 (`review-round1.md:49-51`) |
| :113 | both sources' rows 1981–2010 since #103 | true | pickmove.txt |
| :74 (not in the diff) | SALR per-gauge routed errors | stale | see Finding 3 |
| planning/active/findings.md:18 | "Every routed value does [move]" | false | see Finding 1 |
| planning/active/progress.md (2026-10-19) | upload exited 14:50 UTC; manifest 94deeb5, 06:08:31Z | true | manifest Last-Modified 14:50:30 GMT, `built` 2026-10-19T06:08:31Z |

## Findings

- **[severity: false-claim]** research/discharge_publish.md:5 — "every routed value changed" is false. About 9 % of routed values are identical in the two runs, and 92,539 segments are identical in all twelve months. The same unmeasured quantifier is at planning/active/findings.md:18 ("Every routed value does"), copied from the #103 issue body. Measured on m1's fwapg with a join of the two runs on `(linear_feature_id, month)` from `pcic.discharge_monthly` (the 1951–2012 run equals the acb820f parts value for value, per #101):
  `40524444 | 3824264 equal | 1368632 equal and zero | 92539 segments with all 12 months equal`.
  "Every routed **part** changed" (same paragraph) is true and is what the 35-of-67 count rests on. Fix: write something like "most routed values changed (all but about 3.8 million of 40.5 million monthly values, 1.4 million of them zero in both runs)", or drop the quantifier.

- **[severity: false-claim]** research/discharge_publish.md:77 — "The routed months' total, rounded to 1e-6 m³/s per value, equals the table's fingerprint (178,035,348.248310 m³/s)." That is the 1951–2012 run's total. The branch edited the row of the table directly above to say "since #103 its run PNWNAmet historical 1981–2010", so the table and this sentence now read as the current build, which totals 178,918,222.786650 (`data/checks/discharge_publish_20260717.txt`: "routed months 1-12, total rounded to 1e-6 per value: 178918222.786650 m3/s; the table's fingerprint: 178918222.786650 m3/s"). The section's other figures (the counts, 0 differing, 9.1e-13) are unchanged in the current report, so the fingerprint is the only stale value in it. Found with `git grep -n "178,035,348"`.

- **[severity: false-claim, low; not in the diff, reached by the same mechanism]** research/water_balance_method.md:74 — the SALR bullet gives routed PCIC's per-gauge errors as "08JE001 Stuart −0.1 %, 08JE004 Tsilcoh +4 %, 08KC001 −6.5 % … 07ED001 Nation (−12 %) and 08KC003 Muskeg (+31 %, the balance +24 %)". These are the 1951–2012 run's values (report at 2675636: −0.1, +3.7, −6.5, −12.3, +31.3). The current report gives −2.5, −0.4, −12.0, −14.4 and +23.9. So routed is now marginally closer than the balance at Muskeg (+23.9 against +24.3), and "It is off at … Muskeg" no longer holds. The bullet names its producer commit (wet 7b83959) but not the run, and the file's header now says routed was "rescored on its 1981–2010 run". The headline "routed PCIC is closer at most" still holds (4 of 5). Fix: name the run ("on the 1951–2012 run") or replace the five values from the current report.

No code defects found. The pin flip, the removed period block and its tests, and the two new guards (`segment_vignette_data.R:127`, `segment-discharge.Rmd:46`, `monthly-flow.Rmd`'s periods-identical check) are consistent. Both articles render with every `stopifnot()` passing. `test-vignette_data.R` (7 blocks) and `test-wet_segment_monthly.R` (47 expectations) pass with NOT_CRAN=true, 0 failed, 0 errors, 0 skipped. The README example matches the live parts.
