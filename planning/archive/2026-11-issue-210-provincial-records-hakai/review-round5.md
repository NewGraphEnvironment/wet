# Code-check round 5: the closing enumeration (branch 210-backlog-move-17-provincial-station-recor, HEAD 23b2b513)

## Checklist read

- `code-check.md`: of the 14 H3s under `## Mechanisms`, I read the prose of four: A proxy is not the property; A guard's scope, escape hatches, and remedies (first three paragraphs); The probe is broken before the world is; One fact derived twice. For the other ten I read the heading and its index line only. I read none of the 24 H3s outside Mechanisms.
- `code-check-r.md`, `code-check-shell.md`, `code-check-spatial.md`: index lines only. The only code that changed since round 3 is the new "only one copy" table in `scripts/station_sources_portal.R`, and I checked it by running it (below).
- index, diff and changed files read from file.

## How the checks were made

- I ran `scripts/station_sources_portal.R` from a detached worktree at HEAD with `WET_DATA_ROOT` set to the main checkout's `data/`. It read the cached portal copy and made no request, and it rewrote `data/checks/station_sources_portal_20261125.txt` **byte for byte** (`git status` clean). The new table reproduces.
- Two scratch R scripts, under the scratchpad's `ana/`, applied the script's own merge rules to the same caches:
  - the per-station and per-month shares of January–September 2021 at the four departing stations;
  - the first hour each copy holds per station;
  - for every "pinned files only" hour, whether the raw portal export holds any point within 30 minutes of it (counts only; no value is reported).
- Grep of the raw portal CSVs: the minute and second of the points in each span the new table calls pinned-only.
- The Hakai package's raw files: every watershed's first and last rows; the README PDF (via `pdftotext`) and `Data-Dictonary.csv`.
- The other tracked reports: the survey, harvest, Hakai, regulation and bound reports, plus the registries.
- `wet_station_daily(c("H08KC0626","H08KC0703","H08KC0844"), sources = c("bcenv","hakai"))`, for the unrounded approved shares.
- The bodies of #190, #192, #232 and #233, read with `gh issue view`.

## The mechanism, one axis over

Round 4's fix took "the hours both hold" to be the hours on which the report's inner merge matches. The merge, though, is on **portal points at the top of a UTC hour** (rule 4, `format(portal$t, "%M:%S") == "00:00"`). In several spans the portal's working series is logged off the hour:

| station | span | portal point times |
|---|---|---|
| 08HB0031 | April–October 2023 | :13:29, :28:29, … |
| 08NM0050 | June 2025 onward | :09, :24, … and later :03, :18, … |
| 08MH0056 | July–August 2025 | :06:46, … |
| 08NM0054 | April–August 2026 | :10, :25, … |

The new table's key compares top-of-hour portal points with the pinned hours, which are all on the hour (0 off-hour pinned hours). So an hour whose portal points fall off the hour is counted as one "only the pinned files hold". Of the table's 20,619 "pinned files" hours, the portal holds a point within 30 minutes at **20,593 (99.9 %)**. Every pinned-only run the prose names is one of these off-hour spans. The portal side of the table holds up: the pinned hours are all on the hour, so a top-of-hour portal point with no pinned hour is a real lack in the pin.

The same fact narrows "the hours both hold". Between October 2021 and May 2026, 15,040 pinned hours were never compared (beside 289,003 that were), and both copies hold values at those hours. In those spans the portal point nearest each pinned hour agrees with it, under the script's tolerance, on 10,793 of 20,593 hours. The breakdown:

| station | nearest portal point agrees |
|---|---|
| 08HB0031 | 3,648 of 4,257 |
| 08MH0056 | 991 of 995 |
| 08NM0050 | 5,487 of 12,051 |
| 08NM0054 | 586 of 3,196 |

So whether the files equal the portal there is **unmeasured**, not shown either way. The nearest point is not the hour's value.

## Enumeration

Verdicts: OK means the source supports the claim at the denominator written. "carried" means the text is unchanged from `origin/main` (faf26fdb) and was checked there or in round 3. Line numbers are HEAD's.

| # | claim | where | source | verdict |
|---|---|---|---|---|
| 1 | three sources beyond HYDAT, all through `wet_station_daily()`/`wet_station_list()` | research L9 | code: `sources` default and list | OK |
| 2 | province 211 stations, 110 passing | research L10, L34 | survey "Per network"; harvest tier (i) | OK |
| 3 | Tool 46 of their own (29 passing); 7 continuing (6 more passing) | research L11 | survey 35 passing, "6 (4601, 4602, 2601–2604)"; harvest "53, 46 … 7" | OK |
| 4 | Hakai continues three Calvert/Hecate provincial records with 2014–2019 | research L12; README row; CLAUDE.md; NEWS; roxygen; `R/wet_hakai.R` L2 | registry first 2014-08-03/08-04/09-11, last 2019-09-30; reader | OK |
| 5 | Water Hub 29 on listed periods; two USGS test-only | research L14, L42, L86 | survey "period proxy 29"; USGS row | OK |
| 6 | 147 stations at 140 sites; 3 km drops 4 (08HA0024, 08LC0006, 08MG0002, 08NM0006) | research L16 | survey L65–88 | OK |
| 7 | bar: thresholds 3 years, 5 stations; windows 05-01–08-01, 08-01–09-15; `min_frac = 0.8` | research L22–26 | carried; `wet_window_stats()` default `min_frac = 0.8` | OK |
| 8 | grades Undefined 58.8 %, Unspecified 7.3 %; 134 of 211 mostly ungraded | research L34 | survey "Provincial files" | OK |
| 9 | 1998–2026; 153 new, 57 same site, 1 dup (08NM0015), 44 seasonal | research L34 | survey bcenv row | OK |
| 10 | portal: 10 stations read | research L36, L96; #190 | portal report: 10 discharge CSVs, 08MH0016 not read | OK |
| 11 | Tool passing CRD 8, GBC 7, OGIN 7, EAO 5, Tofino 4, BCCF 2, BCER 2 = 35 | research L38 | survey "Stations passing" | OK |
| 12 | 78 BC ENV listings; 2 with discharge (08MH0061, H08KC1015) | research L39 | survey BC ENV row; harvest "not read" line | OK |
| 13 | stage-only DFO 14, Delta 6, CVRD 3, Surrey 2, Wasa 1 | research L40 | survey rows | OK |
| 14 | Hakai 7 watersheds; package 2013–2019 (the three, 2014–2019); ERDDAP 2013–2026 | research L41 | file: 7 watersheds, WTS708 from 2013-09-08; the three from 2014-08/09; ERDDAP carried from main | OK |
| 15 | Hub 76 (43 CBWMF), 20 tag-only; licences 39/19/18; 54/21/1 | research L42 | survey; carried | OK |
| 16 | Also-found table (USGS, BC Hydro 220/7/20/5, CRD 12/22, OBWB ~75, RFC 522/7/11, …) | research L51–63 | carried from main | OK (carried) |
| 17 | no Tool or Hakai station in any box; box stations and window-years; all 2011–2021 | research L67–75 | round 3 (`departure_sites.csv`; Hakai at 51.64–51.66 N); carried | OK |
| 18 | lower bars 250/238; 238/227 (185, 51, 2); 60; 72/29 | research L83–86 | survey "Lower bars" | OK |
| 19 | robots rows; 391 CSVs, 2 HTTP 500 | research L94–101 | survey; both `.status` files read "HTTP 500" | OK |
| 20 | portal robots "Empty (2026-11-25)"; media host none served | research L96–97; CLAUDE.md; data-raw header; `R/wet_hakai.R` | dated reads, not reproducible offline | not re-checkable; not contradicted |
| 21 | l/s at 6 stations; 800,830 NaN at 121 | research L108 | survey "units" | OK |
| 22 | Oliver 2.1 million (2021–2024); Amor De Cosmos ~7,000 (2021–2025); Big Bar to 9,887 | research L109, L144 | survey ">1,000" | OK |
| 23 | Tool vs files ≥ 99.7 % a year to 2020; 61–92 % from 2021 | research L110; portal header; #190 ("every year from 1998 to 2020") | survey by year: min 99.7 (1999, 2000, 2002); 61.1–92.2; 2004–2005 have no days | OK |
| 24 | on the hours both hold, the files equal the portal Oct 2021–May 2026 (99.9–100 % a month) | research L110; CLAUDE.md; NEWS; README row; #190; #232 | "By month" 2021-10..2026-05. True on the hours **compared**, but those are top-of-hour portal points only: 15,040 pinned hours in that span, at which the portal also holds points, were never compared | **narrower than written (finding 1)** |
| 25 | Tool matches portal on 38–83 % of days a year from 2022 | research L110; #190 | "By year" 82.9 … 38.2 | OK |
| 26 | Jan–Sep 2021: portal departs at four of the five stations both hold then; equals both at 07FC0001 | research L110; NEWS; CLAUDE.md; #190; #232 | stations with compared hours: 07FC0001, 08MH0054, 08MH0056, 08NM0002, 08NM0004; Jan–Sep shares 100, 3.21, 0.09, 0.03, 1.68 %; Tool days 100 % at 07FC0001 | OK |
| 27 | "(0.1–24 % of hours agree)" attached to those four stations | research L110 | the 0.1–23.8 % is "By month" over **all five** stations, and April–September's 11–24 % is mostly 07FC0001 agreeing in full. At the four: 0.03–3.2 % per station and 0.0–4.8 % per month | **wrong denominator (finding 2)** |
| 28 | "(0.1–24 % of all hours a month agree)" | #190 | aggregate stated as such | OK |
| 29 | "0.1–24 % a month from January to September 2021", of the pinned files overall | #232 | "By month" 2021-01..09 | OK |
| 30 | from June 2026, 80–91 % | research L110; #190; #232 | 91.1, 86.5, 80.5, 89.9, 86.0 | OK |
| 31 | portal holds Jan–Sep 2021 at 08HB0031, 08NM0057, 08NM0054, whose pinned record begins 2021-10-01 | research L110; #190; #232 | pinned first hour 2021-10-01 00:00 UTC at all three. Portal: 08HB0031 and 08NM0057 from 2021-01-01, but 08NM0054 only from **2021-03-29 21:00** (4,443 h) | OK for two; overstated for 08NM0054 (late March–September), folded into finding 1 |
| 32 | portal holds 07FC0001's 2026 season | research L110; #190; #232 | portal-only on-hour points Apr 46, May–Sep 744/720 h; the pin holds 41 h in October | OK |
| 33 | "the pinned files hold runs the portal's working series lacks (08NM0050 in 2025–2026, 08NM0054 in 2026, 08HB0031 in 2023, 08MH0056 in 2025)" | research L110; #190; #232 (with "which a newer pin must not lose", and its first to-do); NEWS ("the pin hours the portal lacks at others") | the portal holds 15-minute points over every one of these runs, off the top of the hour. Of 20,619 "pinned files" hours, 20,593 have a portal point within 30 min | **wrong (finding 1)** |
| 34 | "Each copy also holds hours the other lacks" / "the report also counts the hours only one copy holds" | research L110; CLAUDE.md L93; report heading; script header L65–68 | the portal side is right. The pinned side counts hours with no top-of-hour portal point | **wrong for the pinned side (finding 1)** |
| 35 | a newer pin would bring in the revised and added months | research L110, L124; #190; #232 | forward claim; the added months (portal-only) are real | not contradicted |
| 36 | 08JC0002/0006 a degree off; 17 under the Regulator | research L111 | survey (111.6 km; 17 listed) | OK |
| 37 | LST days: UTC−8, UTC−7 in 07 and 10; East Kootenay/Creston at UTC−8; Elk Valley one value a day | research L118 | carried from main L133 | OK (carried) |
| 38 | 66.3 % unchecked; 16 grades | research L119 | harvest; survey grade list (16) | OK |
| 39 | 15 once-a-day stations | research L120 | harvest "211 read, 196 with a complete day"; main L135 | OK |
| 40 | 58 matched to HYDAT; ten continued (7 Tool, 3 Hakai); six add earlier days | research L121 | survey 57 + 1; harvest continuing table (BCCF 3 add, Tofino 4 add 0); Hakai report (3 add) | OK |
| 41 | 215,300 / 110; 215,168, 208 dropped, 110 passing | research L122 | harvest tiers (i), (ii) | OK |
| 42 | 52 natural, 101 regulated, 58 unknown | research L123 | regulation "Status by source" | OK |
| 43 | four passing stations 1.4–1.9 km | research L124 | survey sensitivity 1.39–1.85 | OK |
| 44 | 391 listings; 271, 17, 50 left out; 46 (8, 10, 7, 7, 6, 5, 2, 1) and 7 remain | research L132 | geojson: 398 non-WSC listings with years, 391 distinct nids (7 behind the first of their nid); harvest left-out 271/17/50; per-network counts | OK |
| 45 | Tofino's four add nothing; BCCF's three add 2012–2015 to 08HB0011/0008/0012 | research L133 | harvest continuing listings | OK |
| 46 | 22.1 % of 53,821 | research L134 | harvest | OK |
| 47 | 149 of 53,970 dropped, 145 at four CRD creeks; 53,970 / 103 / 35 | research L135 | harvest drop list; tier (i) | OK |
| 48 | Tool 23/9/14 | research L136 | regulation "Status by source" | OK |
| 49 | bound: ≥ 3,650 days; fewer than 10 → 2,490.71; 08H 268.07 over 82; 402 | research L142, L145 | bound report L8, L12, L19; 402 carried | OK |
| 50 | `H08KC0626` → `08K`; 08K 205.26 | research L143, L166 | `wet_bcenv_ratio()`; bound report L21 | OK |
| 51 | seven watersheds, October 2013 to September 2019 [S] (708 from September 2013 [M]) | research L159 | file: 708 2013-09-08 → 2019-10-01; README "between 2013 and 2019", "up to October 1st, 2019". "October 2013" not in the README; plausibly Korver et al. 2022 (not checkable offline) | not contradicted |
| 52 | 626/703/844 = H08KC…; gap 2019-10-01 to 2021-09-30 | research L159; #192 | registry `continues_before` 2021-09-30; package ends 2019-10-01T00:00 | OK |
| 53 | Qrate = mean of 12 five-minute values [S] | research L161 | Data-Dictonary.csv | OK |
| 54 | PST hour ends [S]; last rows 2019-10-01T00:00; rain lag and radiation [M] | research L162 | README Table 3 ("end time", PST); file last rows (checked) | OK (lag and radiation per round 4) |
| 55 | flag codes AV/EV/SVC/SVD/MV [S]; BR undefined; MV only in mixed hours | research L164 | README lists AV, EV, SVC; dictionary AV, EV, MV; SVD cited to Korver et al. 2022 §3.2 (offline). Hakai report: MV only as AV+MV | OK as far as checkable |
| 56 | approved = every hour AV alone at Qlevel 2; 1 raw, 3 derived [S] | research L165; roxygen; `R/wet_hakai.R`; NEWS ("its level 2"); #192 | `wet_hakai_days()`; level definitions not in the README or dictionary (Korver et al. 2022, offline) | OK as far as checkable |
| 57 | 1,885, 1,883, 1,846 days; 93.4–98.5 % approved; 5→10, 2→7, 4→9 | research L171; NEWS (2→7); #192 ("93–99 %") | Hakai report; unrounded 98.51, 93.41, 94.96 | OK |
| 58 | the three `unknown`, no accepted snap | research L171; #192 | `regulation_20261028.csv` | OK |
| 59 | regulation 204 of 257; 75 (52+23), 110 (90/53/44/11), 72 (49/18/4/2); 58 sites; 30 natural 11/10/9 | research L181 | regulation report "Why, by status", HYDAT table | OK |
| 60 | 211 provincial, 46 Tool listed | research L177 | regulation population | OK |
| 61 | no New Graph package fetches these | research L185 | carried | OK |
| 62 | provincial records begin in October 2021 / on 2021-10-01 | NEWS; `R/wet_hakai.R` header | pinned first hour 2021-10-01 00:00 UTC; first complete day 2021-10-01 | OK |
| 63 | "a day above the same bound dropped"; 08K bound | roxygen `wet_station_daily` | `wet_hakai_shape()` | OK |
| 64 | "`hakai` alone lists no station" | roxygen `wet_station_list` | code; round-3 tests | OK |
| 65 | Hakai pin: watersheds 626/703/844; others 693, 708, 819, 1015 left out | CLAUDE.md; data-raw header; research L168; #233 | file: 7 watersheds | OK |
| 66 | station test, ≥ 3 window-years, no HYDAT station at these sites | `scripts/station_sources_hakai.R` header | Hakai report; survey match | OK |
| 67 | pick: 5 differ most, 3 agree, one each 07, 08H, 08N; 11 picked | #190; script header rule 2 | portal report pick table | OK |
| 68 | #192: "Hakai publishes these stations' discharge from 2013" and title "2013–2020" | #192 | the package README: transducers "installed in the fall of 2013 at watershed 708 and in the fall of 2014 at the" others; file: 626/703/844 from 2014-08-02/08-03/09-10 | **wrong for these three (finding 3)** |
| 69 | #233: "2014–2019 discharge at four more watersheds (693, 708, 819 and 1015)" | #233 | file: WTS708 from 2013-09-08 | **understated for 708 (finding 3)** |
| 70 | #233: 1015 is listed only by the Tool | #233; #192 | survey BC ENV row (H08KC1015) | OK |
| 71 | archive READMEs' history passages | four `planning/archive/*/README.md` | excluded by the brief (verbatim history) | n/a |

**71 claims checked (rows 16 and 59 each group several figures). 5 wrong: rows 24, 27, 33, 34, 68–69. They come down to 3 findings.**

## Findings

- **[severity: fragile]** research/station_sources.md:110, NEWS.md:4, CLAUDE.md:93, data/checks/station_sources_portal_20261125.txt (last table's heading), scripts/station_sources_portal.R:65–68 and 271–278, the #190 body ("Hours only one copy holds" bullet), and the #232 body (its paragraph, "which a newer pin must not lose", and its first to-do). This is a defect inside round 4's fix.
  - **The claim:** "the pinned files hold runs the portal's working series lacks (08NM0050 in 2025–2026, 08NM0054 in 2026, 08HB0031 in 2023, 08MH0056 in 2025)", and NEWS's "the pin hours the portal lacks at others". Both are contradicted by the portal's own raw export.
  - **What the export holds:** the portal holds 15-minute points over every one of those runs, logged off the top of the hour: 08HB0031 at :13:29/:28:29/…, 08NM0050 at :09/:24/… then :03/:18/…, 08NM0054 at :10/:25/…, 08MH0056 at :06:46/….
  - **Why the table counts them:** rule 4 keeps only portal points at minute and second 0, and the new table keys those against the pinned hours, which are all on the hour. So it counts an hour whose portal points are off the hour as held only by the pinned files. Of its 20,619 "pinned files" hours, the portal holds a point within 30 minutes at 20,593 (99.9 %).
  - **"The hours both hold" is narrower than it reads:** between October 2021 and May 2026, 15,040 pinned hours, at which both copies hold values, were never compared (beside 289,003 compared). The nearest portal point agrees with the pinned value at only 586 of 3,196 such hours at 08NM0054 and 5,487 of 12,051 at 08NM0050. So equality in those spans is unmeasured, not shown.
  - **Smaller overstatement:** "the portal holds January–September 2021" at 08NM0054 overstates. Its portal series begins 2021-03-29.
  - **Why it matters:** #232 tells the next pin to preserve hours "the portal's working series lacks", which it does not lack. The portal side of the table is sound, because the pinned hours are all on the hour.
  - **The fix:** state the pinned side as hours with no top-of-hour portal point (the portal logs off the hour there), and the shares as taken on top-of-hour points.
  - **Rule:** code-check.md "A proxy is not the property" (the presence of a top-of-hour point standing in for "the portal holds the hour")

- **[severity: fragile]** research/station_sources.md:110: "the portal departs from both copies at four of the five stations both hold then (0.1–24 % of hours agree)".
  - **Where the range comes from:** the 0.1–24 % is the report's "By month" share over all five stations. From April on it is mostly 07FC0001's hours agreeing in full, the station the sentence then sets apart.
  - **The four stations' own shares:** January–September 2021 agree on 3.21 % (08MH0054), 0.09 % (08MH0056), 0.03 % (08NM0002) and 1.68 % (08NM0004), and 0.0–4.8 % a month taken together.
  - **How it happened:** round 4's rewording dropped "all … a month". #190 keeps it ("0.1–24 % of all hours a month agree") and is right.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (a figure at a coarser grain than the set the sentence names)

- **[severity: fragile]** GitHub #192 body and title, and #233 body.
  - **#192:** "Hakai publishes these stations' discharge from 2013" and the title "Hakai's 2013–2020 discharge at its three Calvert and Hecate stations". The package README says the transducers were installed "in the fall of 2013 at watershed 708 and in the fall of 2014 at the" others, and the file starts 626, 703 and 844 on 2014-08-02, 2014-08-03 and 2014-09-10. 2013 belongs to watershed 708, which wet does not read. The body's Outcome section is right (2014–2019).
  - **#233:** "2014–2019 discharge at four more … watersheds (693, 708, 819 and 1015)". This misses 708's 2013-09-08 start.
  - **Rule:** none

## Code

- `scripts/station_sources_portal.R` reruns byte for byte from the cached copy.
- In the new table's keys, both sides are UTC (`hours$t` gets `tzone` "UTC"; the portal is parsed with `tz = "UTC"`). Both sides are top-of-hour: there are 0 off-hour pinned hours, and `ph` is filtered to `:00:00`. There are no duplicate keys on either side.
- The code does what it was written to do. The defect is the table's meaning (finding 1): the portal's series is not always logged on the hour, so top-of-hour against top-of-hour does not compare like with like.
