## Checklist read
- index: in full, from file.
- code-check-python.md: in full.
- code-check.md: the prose of every H3 under `## Mechanisms` (table rows filtered out), plus "Documentation Staleness". No other H3 read in full.
- code-check-r.md, code-check-shell.md, code-check-spatial.md: no full sections. The diff is Markdown prose only, and no heading in these files names a shape it uses (index lines read).
- index, diff and changed files read from file. The four notes were read from the tree and the research/README.md, fwapg, discharge and archive changes through `git diff origin/main...HEAD`. For `discharge_publish.md` I also read the removed lines.

## Findings

- **[severity: bug]** research/chinook_sites.md, "What changed", bullet "Years behind each period": "2016–2025 has 9 or 10 on every route: approved HYDAT ends in 2024 for most series, and in 2025 for every Swift series and some of Naver's filled-in ones." The list of series that reach 2025 is wrong. A `rec` of 10 means 2025 is included, and section 6 of the site reports (the shipped `covariance_pick` route) has it well beyond that list:
  - Naver BULK carried: mean migration, mean spawning, min7 spawning, both cov_day and max spawning.
  - Naver COTR carried: mean migration, mean spawning, min7 spawning, cov_day spawning and max spawning.
  - Gosnell: min7 migration under both window sets, and mean spawning under MORR. Gosnell has no record and no filled-in series.
  - Maxan carried max, both windows.

  These include the Naver spawning-mean rows behind the headline -35 %. The sentence was true of the old section-5-only text it came from (distance carried at Naver, Gosnell and Maxan is all 9). Widening it to "every route" with `covariance_pick` shipped made it false.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: bug]** research/chinook_sites.md, "Maxan by inverse distance", first paragraph: "Maxan's **window flows** are extended by OLS ... Three supply years: Buck Creek ... Goathorn Creek (08EE008) 1961–1971 and 2016; and the Bulkley at Quick (08EE004) ... 1931–1960 and 1972." These years are for the **migration** window only. `departure_site_maxan_bulk_20260717.txt` section 4 heads the list "Years supplied per donor, migration mean". For the spawning window:
  - The same section gives "30 08EE004, 12 08EE008" before 1981, and "before 1960, 08EE004 supplies every year". So Goathorn supplies **1960**-1971, and Quick 1931-1959 and 1972.
  - `departure_snow_20260717.txt` section 5 also shows Goathorn supplying the spawning window in **1984** (donor spw 08EE008) and 2016.

  The old note said "Maxan's **migration-window mean** is extended ..." (origin/main station_flow_departure.md), and the rewrite widened it. The paragraph two below ("30 ... in the spawning window ... before ... 1960") contradicts it.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: bug]** research/station_flow_departure.md, "Sources and where they meet": "The archive holds every day of 2024 for both stations, so **even a HYDAT that ends in 2023** now joins it". This holds only for a HYDAT ending on or after 2023-10-17. A read-only `wet_provisional_daily()` call today shows the 75 days of 2023 are 2023-10-18 to 2023-12-31, for both stations. A HYDAT ending earlier in 2023 would still leave a hole. The case the old note meant was the 2025-10-14 release (08EE013 to 2023-12-31). The next sentence gives "75 days of 2023" without saying they are the last 75, so a reader cannot see the limit. Say "a HYDAT ending 2023-12-31", or give the archive's 2023 start date.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** research/chinook_sites.md, "How well each box carries and extends", second bullet under the shipped-route table: "The lowest seven-day flow is the weakest statistic." The table directly above does not bear this out as written. In three rows the seven-day minimum scores higher than a window mean for the same window:
  - Swift BULK migration: min7 0.59 against mean 0.55 (and above the spawning mean, 0.43).
  - Naver BULK spawning: min7 0.64 against mean 0.60.
  - Naver COTR spawning: min7 0.64 against mean 0.56.

  The old sentence it descends from (moved to the #152 archive) was about the spawning-window min7 on the distance route, where 7 of 8 were below 0.5. On the shipped route it holds as a tendency, not in every site-window. Qualify it ("on the whole" or "at most site-windows"), or rest on the 4-of-8 count that follows.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

## Checked and agreeing
- **Round 1 fixes:** these now match their sources.
  - Maxan's carried base: 10 years, and 30 for max. HYDAT shows 08EE003, 08EE013 and 08JA016 with no 1952-1970 record, and 08JB002 with all 19 years.
  - The 1951-1980 exceptions (14, 18 and 17) are complete over every section 5 and section 6 row of all seven reports.
  - DJF monthly means from 1981: 0.025-3.94, median 0.554.
  - The migration-mean sentence about the shipped and filled-in tables.
  - The snow-gauge selection sentence, against all seven snow report headers.
- **chinook_sites.md:**
  - Covered counts and leave-one-out and leak-free scores in all seven reports, and both change tables.
  - The extension race, extension pool sizes, "4 of 8" and "7" for min7 below 0.5, and interval coverage (0.904 and 0.921 minima).
  - Shipped-route snow R2 and slopes, the measured-snow-gauge R2 claims, and snow change.
  - Naver's donors since 1999 and the pilot's snow table.
- **station_flow_departure.md:** ice counts, August figures, seasonal-gauge months and complete years, the coverage report, and snow parity and intercepts. The 2023 and 2026 archive extents agree with the live read.
- **discharge_publish.md:** check table, clamp and day-mean figures, row and fit-file counts, the compared total (15,040,448,264), picked counts, and load-time ratios. The figures I looked for among the removed lines (probe, build-time and publish lines) are present in planning/archive.
- **fwapg_mad_method.md:** the method matches fwapg's SQL and discharge.sh at 6aa6c2d (read through `gh api`). The Fraser figures match data/basin/100_report.txt, and the timing ranges match both upstream-area reports.
- **research/README.md:** the four rewritten rows agree with their notes.

No script under scripts/ or data-raw/ was run, and no request went to PCIC. The only network reads were `wet_provisional_daily()` (water-temp-bc S3) and `gh api` for fwapg's files.
