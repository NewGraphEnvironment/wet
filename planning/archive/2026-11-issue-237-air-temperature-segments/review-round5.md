# Code-check round 5 (commits 24987d65..HEAD)

## Checklist read

code-check.md `## Mechanisms`: the prose of each H3, table rows skipped. Read in full: "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "Restore the bug and prove the guard fires" and "One fact derived twice". Also read in code-check.md: "Documentation Staleness". In code-check-r.md: "duckdb in R: the query that autoloads `icu`…", which covers the `INSTALL httpfs; LOAD httpfs;` call the diff wraps in `invisible()`. From the index I also skimmed the R rules on DESCRIPTION pins ("Two repos pinning the same remote…"), which do not apply to a Suggests floor. The diff touches no shell, spatial or SQL code. Index, diff and changed files read from file.

## What I checked, and what held

- **The publish report's arithmetic.**
  - Status counts: 4,864,743 + 41,734 + 962 + 2 = 4,907,441, the table's count. On the main-flow tree, 4,472,713 + 36,833 + 820 + 2 = 4,510,368.
  - The 246 per-group rows sum to the province's own, moved, no_data and outside counts exactly.
  - `cell_daily`: 13,613 cells × 27,759 days (1950–2025, 19 leap years) = 377,883,267 rows. Three variables give 1,133,649,801 values.
  - The station report's 322 parts = 76 + 246.
- **The two builds.** The first and second publish reports differ only in their commit line (`git diff fbc0c3bd HEAD`).
- **Timings, from the logs** in the main checkout's `data/logs/237/`:
  - First BUILD: 00:25:55Z to 02:17:22Z, which is 1 h 52 min.
  - Second BUILD: 02:31:21Z to 03:50:07Z, which is 1 h 19 min. It started 6 s after b2de756e was committed.
  - Station check: 02:21:50Z to 02:26:07Z, which is 4 min.
- **The station report.**
  - 314 placed + 28 not placed = 342, and all 28 are listed.
  - 300 + 14 = 314.
  - 26,065,701 = 313 segments × 83,277: 08NM240 and 08NM241 share one segment. 24,983,100 = 300 × 83,277.
  - The 14 cell pairs differ by 1 or by 3,600, so every one is a neighbouring cell under `wet_air_cell_id()`. Their distances run from 47 to 1,463 m.
- **Research numbers.**
  - 1.55 GB, 153 MB and 1.7 GB in all match the byte counts.
  - 2.8 GB matches the cube manifest's 2,802,215,004 bytes (findings line 37). 228 files = 76 years × 3 variables.
  - The percentages 0.85 % and 0.020 % are correct.
  - VICT: 1,733 + 289 + 125 = 2,147 segments. 2,147 × 27,759 = 59,598,573 rows, and 125 × 27,759 = 3,469,875 NA.
  - The status table equals the report, and so does the sizing probe in findings.
- **CLAUDE.md claims.**
  - `wet_db_load()` refuses the air tree: R/wet_db_load.R:81.
  - The `cell_id` formula is on the global 0.1° grid.
  - `air_code_files` and the PUBLISH guard (scripts/air_publish.R:73, :78) match the paragraph.
  - The mask day is 2025-01-01.
- **No stale crate version.** No reference to crate 0.21.0 remains outside `planning/`. `inst/air/` holds no receipt whose `recipe_id` would carry the old version.
- **Nothing private.** No host, machine, tunnel or private repo is named in the changed files.

## Findings

- **[severity: fragile]** research/air_temperature_segments.md:41: "Each check, run on a mutated copy of the built parts, turned red." The recorded runs do not support this for the `no_data` check.
  - The province mutation table (planning/active/findings.md:115–124) turns five of the report's six checks red: own, moved (twice), outside, completeness and values.
  - It never turns the `no_data rows: none of the nine cells has data` check red. The only `no_data` mutation (line 121) flips a no_data row to outside, which reddens the `outside` check. The `no_data` check just sees one row fewer and still passes.
  - Round 2 found this same gap in the fixture tests, and they were fixed. The province table repeats it, and the sentence claims a proof the table does not hold.
  - Fix: add a row to the mutation table, for example a moved or own row set to `no_data` with its cell cleared, which round 2 showed turns that check red. Otherwise, narrow the sentence to the five checks shown red.
  - **Rule:** code-check.md "Restore the bug and prove the guard fires"

- **[severity: fragile]** NEWS.md:3: "moved to the nearest cell with data where its own has none" overstates the rule the code applies.
  - cd's rule, as `air_check_cells()` recomputes it (scripts/air_publish_lib.R:180–183) and as the report's check line states it, moves a segment only to the nearest of the eight cells around its own. Where none of the nine cells has data, the segment is `no_data` and gets no cell (962 segments).
  - As written, "the nearest cell with data" reads as an unbounded search. A reader would then take every segment with no cell to be off the grid, not 962 segments in empty neighbourhoods.
  - Fix: write "moved to the nearest of the eight cells around it that has data".
  - **Rule:** none (writing.md "State each claim by the code's definition")

## Note (not a finding)

research/air_temperature_segments.md:5: the status line names the first build, e461b677. The tracked report it cites names b2de756e, the second build, and the PUBLISH guard counts from that commit. The claim is supported by the first run, whose report is at fbc0c3bd, and the line goes on to say a second build wrote byte-identical parts. Naming the report's commit would make the line and the report agree.
