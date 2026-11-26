# Code-check round 3 (branch 210-backlog-move-17-provincial-station-recor, HEAD d9460851)

## Checklist read

- `code-check.md`: the prose (tables skipped) of all 14 H3s under `## Mechanisms`: A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice. 24 other H3s not read.
- `code-check-r.md`, 22 read in full: `stats::aggregate()` has three separate silent behaviours; `read.delim()` quotes by default; as.POSIXct on character infers ONE format; `tryCatch()` nests its handlers; `on.exit()` at a script's top level never fires; A fetcher's test helper must make the network fail; A `function(...)` mock hides arguments; testthat counts an uncaught error under `error`; testthat 3e `expect_message()` returns the condition; `expect_message(expr, regexp)` checks only the FIRST condition; `data.frame()` recycles a scalar against a zero-length column; `system2(stdout = TRUE)` warns on a non-zero exit; `tempfile()` lives in the session tempdir; `match()` treats NA as a matchable VALUE; `ifelse()` with an all-NA test; A `data-raw/` script must load the source tree; Under `R CMD check`, tests run from a temp dir; A `pkg::` call in a test; `unlist()` prefixes a `split()` group's name; `sort()` and `order()` collate by `LC_COLLATE`; Tests that silently do not run; `identical()` on two reader results. 110 not read.
- `code-check-shell.md`: index lines only for An S3 multipart ETag and `aws s3 cp` cannot tell a missing key (the backup is one `put-object` with Content-MD5, so neither applies). 75 not read in full.
- `code-check-spatial.md`: none read in full (the only spatial step is a straight-line Albers distance); 98 not read.

## Mechanism behind round 1's findings

Both round-1 findings were a figure retyped by hand from a report table into prose, where the prose gives a summary (a count, a range, a set word) and the table holds the rows. Round 1's two cases: a passing count for one set (35, which includes the 6 continuing listings) stated as the count for a nearby set (the 46 stations of their own, of which 29 pass); and a range read off the wrong rows. The same mechanism covers a set word ("neither", "every", "accepted") placed over a total from the report when one member of the set behaves differently. The table below lists every number, date, range and set word in the prose this branch adds or rewrites, each checked against its source.

## Enumeration

| claim | where | source | verdict |
|---|---|---|---|
| province: 211 stations, 110 passing | research L10, L34 | survey "Per network"; harvest tier (i) | OK |
| Tool: 46 of their own, 29 passing; 7 continuing, 6 more passing | research L11 | survey "Stations passing" (35) and L80 (6: 4601, 4602, 2601–2604); harvest "listings read: 53, 46 ... 7" | OK |
| Hakai: three provincial records, 2014–2019 | research L12, README row, CLAUDE.md, NEWS | registry first 2014-08-03/08-04/09-11, last 2019-09-30 | OK |
| Water Hub 29 pass on listed periods | research L14, L42, L86 | survey L76 | OK |
| 147 stations at 140 sites; 3 km drops 4 (08HA0024, 08LC0006, 08MG0002, 08NM0006) | research L16 | survey L65–88 | OK |
| grades: Undefined 58.8 %, Unspecified 7.3 %; 134 of 211 mostly ungraded | research L34 | survey "Provincial files" | OK |
| 153 new, 57 same site, 1 dup, 44 seasonal | research L34 | survey bcenv row | OK |
| 10 stations read from the portal | research L36, L96 | portal report: 32 files = 10 discharge CSVs; 08MH0016 not read | OK |
| Tool passing CRD 8, GBC 7, OGIN 7, EAO 5, Tofino 4, BCCF 2, BCER 2 = 35; Tofino and BCCF at provincial sites | research L38 | survey L65–74, L80 (BCCF's 2 passing are 4601 and 4602) | OK |
| 78 BC ENV listings, 2 with discharge (08MH0061, H08KC1015) | research L39 | survey bcwatertool BC ENV row; L142 | OK |
| DFO 14, Delta 6, CVRD 3, Surrey 2, Wasa 1 | research L40 | survey rows | OK |
| Hakai: 7 watersheds; "Package 2014–2019" | research L41 | the pinned file: 7 watersheds; WTS708 runs from 2013-09-08 (52,904 rows), the rest from Jul–Sep 2014 | **minor disagreement (finding 3)** |
| Hub: 76 datasets (43 CBWMF); Amended 39, BY-SA 19, BY-NC-SA 18; 54 new, 21 same site, 1 dup | research L42 | survey L45–62, L162–163 (sums computed) | OK |
| BC Hydro 20 in the Tool, 5 with discharge, none passing; CRD 12; UNBC 0 passing | research L45, L52, L53 | survey rows | OK |
| no Water Tool or Hakai station in any box | research L67 | `scripts/departure_sites.csv` lat_min ≥ 51.74; Hakai at 51.64–51.66 N | OK |
| lower bars 250/238, 238/227 (185, 51, 2), 60, 72/29 | research L83–86 | survey L77–79 | OK |
| robots rows; the Tool's 391 CSVs, 2 HTTP 500 | research L94–101 | survey L23–24 | OK (robots reads not reproducible offline) |
| l/s at 6 stations; 800,830 NaN at 121 | research L108 | survey "units" | OK |
| Oliver 2.1 million (2021–2024), Amor De Cosmos ~7,000 (2021–2025), Big Bar to 9,887 | research L109 | survey ">1,000 m^3/s" | OK |
| Tool vs files ≥ 99.7 % a year to 2020; 61–92 % from 2021 | research L110; portal header | survey by year (min 99.7; 61.1–92.2) | OK |
| portal = pinned files Oct 2021–May 2026 (99.9–100 % a month) | research L110; CLAUDE.md L93; NEWS L4 | portal "By month" 2021-10..2026-05 | OK |
| Tool vs portal 38–83 % of days a year from 2022 | research L110 | portal "By year" 82.9 … 38.2 | OK |
| Jan–Sep 2021: "the portal agrees with neither (0.1–24 % of hours)"; "has (since) been revised" | research L110; NEWS L4; CLAUDE.md L93 | portal "By station and year": 07FC0001 2021 is 172 days at 100.0 / 100.0 (portal = province = Tool) and 4,146 hours at 100.0 %. The portal copy holds 07FC0001 points in Apr–Sep 2021 only (plus 446 in Oct), so at least 1,938 of those hours fall in Jan–Sep. The monthly 11–24 % is mostly that one station agreeing in full | **disagrees (finding 1)** |
| from June 2026, 80–91 % | research L110 | 91.1, 86.5, 80.5, 89.9, 86.0 | OK (80.5 written as 80) |
| "the revised water year 2021" | research L124 | portal read from 2021-01-01; Oct–Dec 2020 never compared | **overreach (folded into finding 1)** |
| "which provincial copy is current (the pinned files, from October 2021)" | research/README.md row | portal: 80.5–91.1 % from June 2026 | **open-ended (folded into finding 1)** |
| 08JC0002/0006 a degree apart; 17 under the Regulator | research L111 | survey (111.6 km; 17 listed) | OK |
| 66.3 % unchecked; 16 grades | research L119 | harvest L22; survey grade list (16); code `wet_bcenv_grades` | OK |
| 15 once-a-day stations | research L120 | harvest: 211 read, 196 with a complete day (wording carried from main) | OK |
| 58 matched to HYDAT; ten continued (7 Tool, 3 Hakai); six add days | research L121 | survey 57 same-site + 1 dup; regulation report "58 stations"; harvest continuing table; Hakai report | OK |
| 215,300 / 211 / 110; 215,168 complete, 208 dropped, 110 pass | research L122 | harvest L6–16; bound report "Applied" | OK |
| 52 natural, 101 regulated, 58 unknown | research L123 | regulation "Status by source" | OK |
| four passing stations 1.4–1.9 km | research L124 | survey sensitivity (1.39–1.85) | OK |
| 391 listings; 271, 17, 50 out; 46 (CRD 8, OGIN 10, GBC 7, EAO 7, Regulator 6, BC Hydro 5, UNBC 2, BCCF 1) and 7 remain | research L132 | harvest tier (ii) per network; left-out list (271, 17, 50; 391 − 338 = 53) | OK |
| Tofino's four add nothing; BCCF's three add 2012–2015 to 08HB0011/0008/0012 | research L133 | harvest continuing listings | OK |
| 22.1 % of 53,821 | research L134 | harvest L41 | OK |
| 149 of 53,970 dropped, 145 at four CRD creeks; 53,970 / 103 / 35 | research L135 | harvest drop list (07FB0001 4; HRB3142 70, HRB3144 65, HRB3143 9, HRB6660 1, all Capital RD in the registry) | OK |
| Tool 23 natural, 9 regulated, 14 unknown | research L136 | regulation "Status by source" | OK |
| fewer than 10 stations → 2,490.71; 08H 268.07 over 82 | research L142, L145 | bound report | OK |
| H08KC0626 → 08K | research L143 | `wet_bcenv_ratio()` | OK |
| 08K 205.26 | research L166; tests | bound report; `wet_bcenv_bound` | OK |
| seven watersheds; 626/703/844 = H08KC…; gap 2019-10-01 to 2021-09-30 | research L159 | file (7); registry continues_before 2021-09-30, first complete provincial day 2021-10-01 | OK |
| every watershed's last row 2019-10-01T00:00 | research L162 | file: all 7 end 2019-10-01T00:00:00Z | OK |
| SSN626 rain lag 2 h (r 0.37); radiation peak at 13:00 | research L162 | cited "[M, the cached copy]", but the cache holds the discharge file only | not reproducible from the cited source; not contradicted |
| solar noon at 128° W ≈ 12:30 PST | research L162 | 8° × 4 min = 32 min | OK |
| BR only beside EV; MV only mixed; no SVD | research L164, L171 | Hakai report code table | OK |
| approved = every hour AV alone at Qlevel 2 | research L165; wet_hakai.R header; roxygen ("accepted … after quality control") | `wet_hakai_days()` | OK |
| "approved" where Hakai accepted every hour | NEWS L3 | `wet_hakai_days()` needs Qlevel 2 too; three complete days with every hour flagged AV are provisional because one hour is AV at Qlevel 1 (WTS626 2017-12-31, 2019-05-31; WTS703 2019-05-31) | **disagrees (finding 2)** |
| 693, 708, 819, 1015 left out | research L168; CLAUDE.md; data-raw | file has 7 watersheds | OK |
| 1,885, 1,883, 1,846 days; 93.4–98.5 % approved; 5→10, 2→7, 4→9 | research L171; NEWS (2→7) | Hakai report | OK |
| the three are `unknown` (no accepted snap) | research L171 | `regulation_20261028.csv` | OK |
| 204 of 257; 75 (52+23), 110 (90, 53, 44, 11), 72 (49, 18, 4, 2); 58 sites; 30 natural: 11/10/9 | research L181 | regulation report | OK |
| 211 provincial, 46 Tool | research L177 | regulation "Population" | OK |
| provincial records begin 2021-10-01 / in October 2021 | wet_hakai.R header; NEWS L3 | provincial registry `first` 2021-10-01 (continues_before, the first usable hour, is 2021-09-30) | OK as the first complete day |
| 45,252 / 45,207 / 44,312 hours | Hakai report | file row counts | OK |
| pick: 112 listed, 82 eligible; roles as printed | portal report | not re-derived (needs the caches; rounds 1–2 covered it) | not re-checked |
| History passages "as they stood there on 2026-11-25" | four archive READMEs | every moved paragraph grep-matched verbatim against `origin/main:research/station_sources.md` | OK |

## Findings

- **[severity: fragile]** research/station_sources.md:110, NEWS.md:4, CLAUDE.md:93 — Mechanism: a set word over a total. Research says that for January–September 2021 "the portal agrees with neither (0.1–24 % of hours)". NEWS and CLAUDE.md go further and say the pinned files' January–September 2021 "has since been revised". The report contradicts this at 07FC0001. In "By station and year", its 2021 is 172 station-days at 100.0 % with the province and 100.0 % with the Tool, and 4,146 hours at 100.0 %. The portal copy holds its points in April–September 2021 (446 in October), so the monthly 11–24 % from April on is mostly this one station agreeing in full, and the other stations agree on almost nothing. For January–September 2021 the portal departs from both copies at four of the five stations with hours in those months; at 07FC0001 it equals both. Two related overreaches: research L124's "the revised water year 2021" (the portal was read from 2021-01-01, so October–December 2020 was never compared), and research/README.md's "the pinned files, from October 2021", which has no end date although June 2026 onward is 80–91 %. These matter because NEWS and CLAUDE.md are what readers act on. "Revised" with no station named reads as all stations, and #232's newer pin is justified by it.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (compression: a sentence that gained a quantifier is unsupported until checked against each source)

- **[severity: fragile]** NEWS.md:3 — The NEWS line describes the approved set by a nearby, larger set: "`"approved"` where Hakai accepted every hour". The code (`wet_hakai_days()`, `accepted` = every hour `AV` alone at `Qlevel` 2) marks three complete days "provisional" although Hakai flagged every hour of them `AV` (accepted): WTS626 2017-12-31 and 2019-05-31, and WTS703 2019-05-31. Each has one `AV` hour at Qlevel 1 (raw). The roxygen ("accepted every hour of it after quality control") and research L165 are exact; only the NEWS bullet is wrong.
  - **Rule:** code-check.md "A proxy is not the property"

- **[severity: fragile]** research/station_sources.md:41 — The inventory's period column reads "Package 2014–2019". The pinned file covers more: WTS708 runs from 2013-09-08T16:00 (52,904 rows against about 45,250 for the others), and the file is named 2013-2019. "2014–2019" is true of the three watersheds wet reads (and of "water years 2014–2019", L159, where it is cited [S]). It is not true of the package that row describes.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

## Code

No new code defect found. `tests/testthat/test-wet_station_daily.R` (48 blocks) and `test-wet_station_list.R` (11 blocks) both pass with `NOT_CRAN=true`, from a detached scratch worktree at HEAD, live tests included (counted as `failed > 0 | error`). Checked and clean:
- `wet_registry_check()`: a duplicate across registries, a station continued twice, and the class carried out through `wet_daily_try()`.
- `wet_continue_days()` and `wet_continuing()`, shared by both publishers.
- `wet_hakai_days()`: the PST day arithmetic (`label - 3600`, UTC; the cached file's first WTS626 hour 2014-08-02T13:00 gives a 12-hour first day and a first complete day of 2014-08-03, as the registry has it).
- `wet_hakai_shape()`: the cap over complete positive days.
- `wet_station_list()`: the empty-template rbind for `"hakai"` alone.
- The data-raw backup: a single PUT with Content-MD5, and the ETag compared with the md5.
- The portal script's `aggregate()`: every value is finite, so `na.omit` drops nothing.

index, diff and changed files read from file
