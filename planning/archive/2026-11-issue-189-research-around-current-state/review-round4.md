## Checklist read
- index: read in full from file, in chunks.
- code-check-python.md: read in full.
- code-check.md: the prose of every H3 under `## Mechanisms`, with table rows and evidence blocks left out.
- code-check-r.md, code-check-shell.md, code-check-spatial.md: no full sections opened. The diff is Markdown prose, and no index line names a shape it uses.
- diff and changed files: `git diff HEAD~3 HEAD -- research` was read whole. The four rewritten notes were read whole in the tree, and the research/README.md rows and fwapg_mad_method.md also through `git diff origin/main...HEAD`. The planning/archive hunks were only partly read (moved blocks are an accepted decision), and branch.diff was not read as one file.
- index, diff and changed files read from file (within the scope stated above).

## What was re-derived
- **Last three commits (chinook_sites.md, station_flow_departure.md).**
  - Gosnell's two sets of normal errors were recomputed from the per-gauge rows. Median absolute log error is 0.315 spawning against 0.155 migration under the Bulkley windows, and 0.232 against 0.126 under the Morice's.
  - The years-behind exceptions were checked against every row of sections 5 and 6 in all seven site reports.
  - Also checked: the shipped and filled-in change tables, interval coverage, the Bulkley-window `min7` counts (4 of 8, and 7 on section 3's pool), the snow-gauge rule and the Maxan donor years.
  - Buck Creek's winter monthly means were recomputed read-only from HYDAT 20260717: 0.025 to 3.945, median 0.554, n = 131.
- **Donor-test section.** Compared with the report and the rule file, and its figures hold. The pre-registration box counts have no tracked producer in either file; the note says they come from probes. The section differs from origin/main only in issue pointers.
- **Departure method.** The window, extension, carry, pilot and `covariance_pick` paragraphs agree with the three R files, the pilot, snow and PCIC reports, and pcic_hydrology.md.
- **Publish and fwapg.** The naming, layout, receipt, load-table, index and dataset-count claims agree with the code and the build report, apart from the two below. fwapg's Fraser figures and wet-side "since that run" claims agree with data/basin/100_report.txt and the scripts. fwapg's own source was not re-fetched.

## Findings
- **[severity: bug]** research/discharge_publish.md:112. "Values copied from a double are compared exactly. **Only the two means of twelve months** meet within a tolerance (relative 1e-9), because R's `mean()` and a sum over 12 round differently in the last bits." Only one of the two tolerance checks is a mean of twelve months.
  - In scripts/discharge_publish.R, the two `wet_values_compare()` calls left at the default `tol = 1e-9` are line 575 (`routed month 0 = mean of 1-12`) and lines 695-696 (`daily balance months = segment parts`).
  - The second is `aggregate(q_m3s ~ linear_feature_id + month, ..., mean)` over each month's **days** (28 to 31 values) against the published monthly parts. The script's comment at lines 614-615 says so: "their months must be the segment parts' months (relative 1e-9)". All the other calls pass `tol = 0`.
  - The note's own table, three rows above, lists this check as "daily balance, plain mean of each month's days = the `segment_monthly` parts", with largest difference 3.6e-12 and 0 differing. That check passes only through the tolerance the sentence says it does not get. The reason given (a sum over 12) also does not apply to it.
  - The sentence is carried over from origin/main (the script's comment at line 548 has the same stale wording). The note's header now says the check claims were re-read against the code.
  - Fix: name both tolerance checks (routed month 0 against the mean of its twelve months, and the balance's day means against its published months), and keep the `mean()` against sum-over-12 reason for the first only.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** research/discharge_publish.md:146. "It warns on a table whose comment records a subset load, and **stops on a scenario or source the table does not hold**." There is an exception in R/wet_segment_monthly.R (`wet_segment_pg()`).
  - `by_groups` is TRUE when the table comment's subset names `watershed_group_code IN`, and then `if (length(absent) && !by_groups) stop(...)` does not stop. A source the table does not hold reads as NA rows under the subset warning. The code comment gives the case: no routed segment in the Liard.
  - A reader relying on the sentence would take NA routed rows from a group-subset table to mean the source was loaded and has no value there. A scenario the table lacks, loaded by groups, leaves `have` empty, so it also reads as missing rather than stopping.
  - The sentence is carried over from origin/main.
  - Fix: add "except on a table loaded for some watershed groups, where an absent source or scenario reads as missing".
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** research/chinook_sites.md:101, text from the last three commits. "its held-out coverage in **the Bulkley-window site reports** is 83–85 % for the migration-window mean (85–88 % for the spawning-window mean)."
  - There are four Bulkley-window site reports. data/checks/departure_site_gosnell_bulk_20260717.txt gives OLS coverage of **86** for the migration mean (and 88 for the spawning mean). Over those four reports the migration range is therefore 83–86.
  - 83–85 and 85–88 are the ranges of the three **gauged** sites: Maxan 85/88, Swift 83/85, Naver 85/86. These are the only sites where the years figure draws an OLS band.
  - Fix: "in the gauged sites' Bulkley-window reports".
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

No script under scripts/ or data-raw/ was run, and no request went to pacificclimate.org or any other network host. HYDAT was opened read-only. The only file written in the tree is this one.
