# Code-check round 6: the closing enumeration (branch 210-backlog-move-17-provincial-station-recor, HEAD dee82103)

## Checklist read

- `code-check.md`: I listed all 14 H3s under `## Mechanisms`. I read the prose of two in full, "Zero-length, empty, and unset are three different things" and "A proxy is not the property". For the other twelve I read the heading and its index line only.
- `code-check-r.md`, `code-check-shell.md`, `code-check-spatial.md`: index lines only. The only code changed since round 5 is the coverage table in `scripts/station_sources_portal.R`.
- index, diff and changed files read from file.

## How the checks were made

- **The script.** I ran `scripts/station_sources_portal.R` from a detached worktree at HEAD (`WET_DATA_ROOT=/Users/airvine/Projects/repo/wet/data WET_PORTAL_SNAPSHOT=20261125`). It exited 0, and the raw directory still held 32 files, so no request was made. Its report `cmp`s **identical** to the tracked `data/checks/station_sources_portal_20261125.txt`, and `git status` was clean. The worktree has been removed.
- **An independent probe** (`scratchpad/r6/probe.R`):
  - It parses the 10 raw portal CSVs with `strsplit`, not `read.csv`, and buckets points by `seconds %/% 3600`, not by `format()`.
  - It reads the pinned hours through `wet:::wet_bcenv_hours`.
  - It recomputes per station and year: portal-only hours, pinned-only hours and not-compared hours, over 2021-01-01 to 2026-10-27 UTC.
  - Result: it reproduces the report's coverage table **row for row**. Totals: portal only 21,572; pinned only 0; not compared 20,619.
  - With Unusable pinned hours and the portal's −2 and gap rows put back in, pinned only is still 0.
  - The pinned side has 0 off-hour timestamps, 0 duplicate station-hours and 0 Unusable hours at these stations.
- **Off-hour spans** (minutes of the portal points in the not-compared hours):

  | station and year | not-compared hours | from | to | portal minutes |
  |---|---|---|---|---|
  | 08HB0031 2023 | 4,252 | 2023-02-11 | 2023-10-13 | :13 :28 :43 :58 |
  | 08MH0056 2025 | 985 | 2025-07-03 | 2025-08-13 | :06 :21 :36 :51 |
  | 08NM0050 2025 | 4,857 | 2025-03-14 | 2025-12-31 | :09 :24 :39 :54 |
  | 08NM0050 2026 | 7,198 | through 2026-10-27 | | :03 :18 :33 :48 |
  | 08NM0054 2026 | 3,192 | 2026-04-10 | 2026-08-21 | :10 :25 :40 :55 |

  These sum to 4,252 + 985 + 4,857 + 7,198 + 3,192 = **20,484**. The other 135 not-compared hours are scattered 1–41 h station-years.
- **First hours.**
  - Pinned: 2021-10-01 00:00 at 08HB0031, 08NM0057 and 08NM0054.
  - Portal: 2021-01-01 at 08HB0031 and 08NM0057, and **2021-03-29 20:30** at 08NM0054. So 4,444 portal-only hours in 2021 at 08NM0054, and 6,551 and 6,552 at the other two.
- **Last hours.** The last pinned hour across the snapshot is 2026-10-28 20:00 UTC, which gives fewer than 20 local-standard-time hours on 2026-10-28.
- **Hakai.**
  - The raw `2013-2019_Discharge_Hourly.csv` gives every watershed's first and last row: 1015 2014-07-31, 819 2014-08-01, 693 and 626 2014-08-02, 703 2014-08-03, 708 2013-09-08, 844 2014-09-10. All end 2019-10-01T00:00.
  - The README PDF's Table 1 gives coordinates for all seven.
- **Portal sampling intervals** per station, read from the raw CSVs.
- **Amor De Cosmos and Oliver Creek.** The pinned hours above 1,000 m³/s at 08HD0003 and 08HA0036, by grade.
- **The issues.** `gh issue view` of #190, #192, #232 and #233, read 2026-11-26 UTC.

## Enumeration

Rows 1–71 are round 5's, re-marked at HEAD. "unchanged" means neither the text nor its source moved since round 5's check: `dee82103` touched no report but the portal report's last table.

| # | claim | where | source | verdict |
|---|---|---|---|---|
| 1–21 | round 5 rows 1–21 (sources and counts, bar, inventory, grades, robots) | research L9–101 | unchanged | still holds |
| 22 | Oliver 2.1 million, Amor about 7,000 m³/s "on graded hours"; Big Bar to 9,887 (rewritten in dee82103) | research L109 | hours > 1,000: Oliver max 2,117,656 on RISC U; Amor graded max 6,995 (RISC C; its 7,041.9 peak is Unspecified); 9,886.9 | holds (RISC U counts as graded under wet's own status rule) |
| 23 | Tool vs files ≥ 99.7 % a year to 2020, 61–92 % from 2021 | research L110; portal header; #190 | survey by year (2004–2005 hold no common days) | still holds |
| 24 | where the portal logs on the hour, files equal it Oct 2021–May 2026, 99.9–100 % of compared hours a month | research L110; CLAUDE.md; NEWS; README row; #190; #232 | "By month" 2021-10..2026-05: 99.9–100.0 | holds (fixed) |
| 25 | Tool matches portal on 38–83 % of days a year from 2022 | research L110; #190 | By year 82.9…38.2 | still holds |
| 26 | Jan–Sep 2021: portal departs at four of five stations; equals both at 07FC0001 | research L110; NEWS; CLAUDE.md; #190; #232 | unchanged | still holds |
| 27 | "0.1–24 % of all five stations' hours a month agree" | research L110 | By month 2021-01..09: 0.1–23.8, over the five | holds (fixed) |
| 28–29 | #190 "0.1–24 % of all hours a month"; #232 "0.1–24 % a month" | #190; #232 | same | still holds |
| 30 | from June 2026, 80–91 % | research L110; #190; #232 | 91.1, 86.5, 80.5, 89.9, 86.0 | still holds |
| 31 | portal holds Jan–Sep 2021 at 08HB0031 and 08NM0057 and "from March at 08NM0054", whose pinned records begin in October (2021) | research L110; #190; #232 | portal-only 6,551 / 6,552 / 4,444; 08NM0054 portal from 2021-03-29; pinned first 2021-10-01 at all three | holds (fixed) |
| 32 | portal holds 07FC0001's 2026 season | research L110; #190; #232 | 3,718 portal-only hours in 2026; 41 compared | still holds |
| 33 | (replaced) "Every pinned hour has a portal point in it" | research L110; #190; #232 | pinned-only 0 in every row; 0 also with all grades | holds |
| 34 | (replaced) report's coverage table counts portal-only hours and pinned hours no comparison reaches | research L110; CLAUDE.md; report heading; script header L65–70 | code L273–286; independent reproduction | holds |
| 35 | a newer pin would bring these in | research L110, L124; #190; #232 | forward claim | not contradicted |
| 36–67 | round 5 rows 36–67 (coordinates, LST days, status, harvest, Tool, bounds, Hakai rules and report, regulation, roxygen, headers, pick) | research L111–185; CLAUDE.md; roxygen; R/wet_hakai.R, scripts/ and data-raw/ headers; #190 | unchanged; Hakai report and registry re-read (1,885/1,883/1,846; 98.5/93.4/95.0; 5→10, 2→7, 4→9; continues_before 2021-09-30; first 2014-08-03/08-04/09-11) | still holds |
| 68 | #192 title "2014–2019"; body drops "from 2013" | #192 | file: 626/703/844 from 2014-08-02/03, 09-10 | holds (fixed) |
| 69 | #233 "708 from September 2013, the others from summer 2014, to September 2019" | #233 | 708 2013-09-08; 1015 07-31, 819 08-01, 693 08-02 2014; all end 2019-10-01T00:00 PST hour end | holds (fixed) |
| 70 | 1015 listed only by the Tool | #233; #192 | survey BC ENV row | still holds |
| 71 | archive READMEs' history | planning/archive | excluded | n/a |
| 72 | off-hour spans named: 08HB0031 in 2023, 08MH0056 in 2025, 08NM0050 in 2025–2026, 08NM0054 in 2026 | research L110; #190; #232 | not-compared rows of those station-years; portal minutes all off :00 | holds |
| 73 | "20,484 hours" | research L110; #190; #232 | 4,252 + 985 + 4,857 + 7,198 + 3,192 = 20,484 (table rows) | holds |
| 74 | "no comparison reaches, so equality there is unmeasured" | research L110; #190; #232 | those hours are in no `hh` row | holds |
| 75 | coverage table: hour keys UTC, window 2021-01-01..2026-10-27, three columns | report; script L273–286 | `hours$t` tzone UTC, portal parsed UTC, both filtered by `as.Date` in from..to; reproduced independently | holds |
| 76 | NEWS: "the portal holds months the pin lacks at four stations" | NEWS | 08HB0031, 08NM0057, 08NM0054, 07FC0001 (other portal-only spans are 1–190 h) | holds |
| 77 | NEWS and CLAUDE.md: "spans where a logger records off the hour were not compared" / "pinned hours no comparison reaches (loggers off the hour)" | NEWS; CLAUDE.md | row 72 | holds |
| 78 | README row: "the pinned files, October 2021 to May 2026, where the portal logs on the hour" | research/README.md | row 24 | holds |
| 79 | Tool: "One CSV row is one day, likely a UTC one [I]" (reworded) | research L134 | inference, tagged | not contradicted |
| 80 | #192: "93–99 % approved"; H08KC0703 "now meets the survey's three-year test" | #192 | 93.41–98.51; 2→7, FALSE→TRUE | holds |
| 81 | #233: coordinates "from the package README's Table 1" | #233 | Table 1 lists all seven watersheds' coordinates | holds |
| 82 | #232: "the record stops at 2026-10-27" | #232 | last pinned hour 2026-10-28 20:00 UTC, under 20 LST hours that day; Hakai report last day 2026-10-27 | holds |
| 83 | #232 to-do: compare the off-the-hour spans | #232 | matches the coverage table | holds |
| 84 | research "Still open": revised and added months, spans no comparison reached (#232) | research L124 | #232 body | holds |
| 85 | portal: "The same database, **15-minute points** with grade and approval [M]" | research L36 | raw CSVs: 08NE0001 at 5 min (100 % of steps), 08NM0057 at 5 min on 63.7 %, 08HB0031 hourly on 10.3 %; the other seven at 15 min | **wrong (finding 1)** |
| 86 | report reruns byte for byte from the cached copy, no request | script header; research L101 | `cmp` identical; 32 files before and after | holds |

**86 claims checked (rows 1–21 and 36–67 each group several figures, re-marked as a block because neither text nor source moved). 1 wrong (row 85).** Round 5's five wrong claims (rows 24, 27, 33, 34, 68–69) all now hold. Separately, one code finding (finding 2).

## Findings

- **[severity: fragile]** research/station_sources.md:36: "15-minute points". This is the inventory's Aquarius row, added on this branch at 616440ab and not enumerated in round 5.
  - **What the raw exports hold:** 08NE0001 logs every 5 minutes (100 % of steps), and 08NM0057 every 5 minutes on 63.7 % of steps (15 minutes on 29.4 %). 08HB0031 is hourly on 10.3 % of its steps. Only the other seven stations are at 15 minutes.
  - **Why it matters:** the round-5 fix rests on the portal recording points at varied times and intervals. A blanket "15-minute" misdescribes the product the coverage table explains.
  - **Fix:** "points as recorded (5 to 60 minutes apart)".
  - **Rule:** none

- **[severity: fragile]** scripts/station_sources_portal.R:330–336, 361. This is a defect inside round 5's fix.
  - **What happens:** when `cov` has no rows (every pinned hour holds a top-of-hour portal point and the portal holds no hour the pin lacks), `as.data.frame(table(...))` is 0×4, and `stats::reshape(..., direction = "wide")` stops with "undefined columns selected".
  - **Why it matters:** the script dies before `writeLines()`, so its `else "    none"` branch is unreachable. Round 4's version guarded this case (`if (nrow(only)) ... else data.frame(...)`), and round 5's rewrite dropped the guard.
  - **How it was shown:** reproduced in isolation (`Rscript`, an empty `cov`). It fails loudly, writes no report and cannot occur on the tracked 20261125 copy. A later `WET_PORTAL_SNAPSHOT` that matches perfectly would hit it.
  - **Fix:** build `cov_tab` only when `nrow(cov) > 0`.
  - **Rule:** code-check.md "Zero-length, empty, and unset are three different things"

## Code

Apart from finding 2, the coverage table in `scripts/station_sources_portal.R` checks out:
- Both sides are keyed on the UTC hour.
- `pa` takes the same from..to window as `hours`.
- `setdiff` and `intersect` de-duplicate the keys.
- The column order after `reshape` follows the factor levels.

An independent re-derivation reproduces every row, and the script reruns byte for byte with no request.

## Closing (main session, 2026-11-26)

- The Aquarius row now says "points as recorded" and names no interval.
- The empty-coverage guard is restored. Proved on empty input: the round-5 code (`stats::reshape()` of an empty table) stops with "undefined columns selected"; the guarded code returns a zero-row table with the five columns. The tracked report is byte-identical on a rerun from the cache.
- The loop ends on this round's enumeration: 86 claims, 1 wrong and now fixed, plus the guard proved on its failure case.
