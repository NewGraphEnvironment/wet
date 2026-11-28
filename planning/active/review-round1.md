## Checklist read
- code-check.md: the prose of all 14 H3 under `## Mechanisms` (table rows skipped) and "Documentation Staleness" in full; "A link to a repo-hosted artifact must be *tracked*, not merely present" opening only. The other 22 of its 38 H3 not read.
- code-check-shell.md: the heading on exit statuses lost by a waiter in full (its title is shortened here); "`git diff a..b` compares TIPS..." opening only. The other 73 of 75 not read.
- code-check-r.md: "Regenerated binaries churn git even when nothing changed" in full; "`identical()` on two reader results tests the reader, not the file" opening only. The other 132 of 134 not read.
- code-check-spatial.md: none of its 99 read (the diff uses no spatial tool).
- index, diff and changed files read from file

## Findings

- **[severity: security]** planning/active/findings.md:33 — The second row of the "Errors Encountered" table records local environment setup and how one machine is reached from another, in a public repo. The repo rule keeps both out of added text, and the row above it records a push refused for the same kind of content. The line enters in the branch's last commit, c6e24dbd, which is not on the remote yet (`git ls-remote` gives the branch head as 08a8c552). So amend that commit before pushing: a follow-up commit would still publish the text in history. Restate the row as the general lesson (a waiter's liveness test failed because the tool it called was not found, so check that the tool resolves before the loop), with nothing about where or how the shell ran, or drop it.
  - **Rule:** none

- **[severity: fragile]** planning/active/progress.md:52 — "Merged origin/main again (c64f84bf, v0.7.1); no report or table script moved" is false as written. `git diff --name-only 08a8c552 c64f84bf` lists five tracked reports under `data/checks/` (station_regulation, station_sources_hakai, temp_logger_thresholds, temp_loggers_nhg, temperature_bayesian_alignment). The merge also moved the 12 files under `R/` and `scripts/` that findings.md lists as making a BUILD at this head refuse the tables. What holds is that none of this plan's three reports, nor `segment_output.R`, `segment_daily_output.R`, `discharge_publish.R`, `discharge_publish_own.R` or `wb_output.R`, moved. Say that, so the line is not read as "the guards still pass at this head".
  - **Rule:** none

No other issues found.

## What was checked and held
- Run times (8.5 min, 2 h 10 min, 3 h 18 min), the commit each run started at, and the BUILD ran with no upload: match the run logs.
- The before and after md5 lists are equal (23 monthly, 246 daily) and match the set-aside list. Each report's diff is limited to the lines the planning files name.
- 16 of 16 cross-checks `ok`, no `FAIL`, 15,040,448,264 values compared with 0 differing, 512 of 512 identical: match the report and the log.
- "Only receipt.json differs" and the five differing fields, checked from the anonymous public manifest and receipt. The live recipe with only the commit, wet version and crate version changed gives recipe_id b35107a5... exactly. The live receipt with those fields, the recipe_id and `context.time` (2026-11-28T02:52:45Z, in line with the log) changed, digested with the 247 live fit files, gives 69ea40edfe375cbbea65ef8e07acce2e exactly. The live tree is 512 parts, 247 fit files and the receipt (760).
- crate v0.16.0 to v0.21.0: no discharge schema, `crt_schema_conform()` or its helpers, or receipt writer or reader file changed.
- `vd_published()` and `vd_segment_report()` pass against live. `test-publish_own.R` (13) and `test-publish_report_live.R` (33) pass with no failure, error or skip.
- Both code guards, run as diffs at this head, list exactly the 12 files named. v0.7.1 holds moves 19, 22 and 26.
- Since the park, only `discharge_publish_own.R` among the plan's code and report files moved before f943096d. `segment_output.R`, `wb_output.R`, `wb_fit_lib.R` and `R/wet_source_pick.R` did not change from 66cf795 to 6a1d7316.
- Not checkable from the inputs and not relied on above: the pre-run probes that left no log, disk sizes, and the directory the runs started in.
