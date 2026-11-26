# Code-check round 1: branch 210 (#190, #192, #207)

## Checklist read

- **code-check.md** (38 H3): I read the prose of all 14 H3s under `## Mechanisms`, skipping table rows. From the standalone rules I also read "Do not edit files a long test run is reading" and "Documentation Staleness". 22 not read: the other standalone rules, Security, and Spreadsheets/PDFs. Nothing in this diff uses them.
- **code-check-r.md** (132 H3): read: "`stats::aggregate()` has three separate silent behaviours…", "A fetcher's test helper must make the network fail, not just mock the reader", "`match()` treats NA as a matchable VALUE…", "`ifelse()` with an all-NA test returns a logical vector…", "A `function(...)` mock hides arguments the real callee no longer accepts", "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising…", "`tempfile()` lives in the session tempdir…". I checked these against the index text only, without opening the full section: "`paste()` with a zero-length argument returns length ONE", "`data.frame()` recycles a scalar against a zero-length column", "as.POSIXct on character infers ONE format", "A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check` if `pkg` is undeclared", "testthat counts an uncaught error under `error`, not `failed`". 125 not read in full.
- **code-check-shell.md** (75 H3): read "An S3 multipart ETag depends on the uploader's part size…". The diff's aws calls are a single PUT, so this was the only shell rule in scope. 74 not read.
- **code-check-spatial.md** (98 H3): 0 read in full. The only spatial code is a straight-line distance in Albers in the data-raw pin, and no heading names it. 98 not read.

## Probes run (read-only, scratch copy for tests)

- `git archive HEAD` into the scratchpad, then ran `test-wet_station_daily.R` (48 tests) and `test-wet_station_list.R` (11 tests) with `NOT_CRAN=true`: 0 failed, 0 errors, 0 skipped.
- Live on m1's cache:
  - `wet_station_list()`: H08KC0626/0703/0844 first days are 2014-08-03, 2014-08-04 and 2014-09-11, with licence `OGL-BC 2.0; days before 2021-09-30: CC-BY 4.0`.
  - `wet_station_list("hakai")` returns a typed 0-row frame.
  - `wet_station_daily("H08KC0626", sources = "hakai")` gives 2014-08-03 to 2019-09-30, with 1857 of 1885 days approved (98.5 %), matching the report.
  - The shipped Tool registry continues each of its 7 provincial stations once, so the new "two publishers continue" check does not fire on it.
  - In the Hakai file's three watersheds, every `Qflag` head is in `wet_hakai_codes`. The only `MV` hour (WTS703, 2018-08-24T18) is a mixed hour that carries a Qrate.
- Every number in the Hakai report agrees with NEWS, CLAUDE.md and the research file:
  - days 1885/1883/1846;
  - window-years 5→10, 2→7, 4→9;
  - approved 93.4–98.5 %;
  - 08K bound 205.26.
- Every number in the portal report agrees with the prose:
  - October 2021 to May 2026 at 99.9–100 % of hours;
  - Tool 38–83 % per year from 2022;
  - January–September 2021 at 0.1–24 %;
  - June–October 2026 at 80–91 %;
  - 10 stations read.

## Findings

- **[severity: bug]** research/station_sources.md:11. The answer says "the BC Water Tool's third-party gauges: 46 stations (35 passing)". That is wrong: 29 of the 46 pass.
  - Six of the Tool's 35 passing stations are not among the 46. They are 4601 and 4602 (BCCF) and 2601–2604 (Tofino), which are continuing listings at provincial sites (`data/checks/station_sources_20260717.txt`: "Water Tool passing stations at a site that also passes in the provincial files: 6 (4601, 4602, 2601, 2602, 2603, 2604)"). The harvest report counts them among the "7 continuing a provincial station".
  - The pre-consolidation text kept the two apart ("35 more stations pass … 6 of them at sites that also pass in the provincial files"; "wet reads 46 of them"). The inventory row in the same file is still right ("the Tofino and BCCF ones sit at provincial sites").
  - So the consolidation (#207) added a claim the evidence does not support. Suggested fix: "46 stations (29 passing), and seven listings continuing provincial records (6 more passing)", or drop the passing count from that bullet.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** scripts/station_sources_portal.R:10. The header says the survey report has "99.8-100 % of their common 24-hour UTC days within 0.1 % to 2020". The survey report's by-year table (`data/checks/station_sources_20260717.txt`, lines 110–130) has 99.7 % in 1999, 2000 and 2002.
  - research/station_sources.md states it correctly ("at least 99.7 %").
  - This is low stakes: the figure decides nothing in the script. But it sits in the registered-rules header, so correct it with a dated note rather than a silent edit.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

Nothing else found. I checked:
- the continuation refactor (`wet_continuing`, `wet_continue_days`, `wet_continue_list`) against the old Tool-only code;
- `wet_registry_check`'s arms;
- `wet_daily_try` re-raising registry conflicts;
- the empty-frame paths;
- the Hakai fetch's partial-file and md5 handling;
- the PST day arithmetic;
- the 08K cap;
- the portal script's rules 1–5 against its code (pick, agreement tolerance, 24-hour days, verdict thresholds, amendment 1);
- the report scripts' counts.

index, diff and changed files read from file
