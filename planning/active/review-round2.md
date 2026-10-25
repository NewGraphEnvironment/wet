# Code-check round 2 (#117, #94)

## Checklist read

- code-check.md: the prose of all 14 H3s under `## Mechanisms`, without their `|` table rows; read closely: "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A guard's scope, escape hatches, and remedies", "One fact derived twice". None of the H3s under "Rules that stand alone", "Security" or "Spreadsheets and PDFs" (about 20), since none names a tool or shape this diff uses.
- code-check-r.md: none in full. From the index only: "Rscript reads a script as it runs", "Under `R CMD check`, tests run from a temp dir against the INSTALLED package", "A `pkg::` call in a test passes `devtools::test()`", "`sort()` and `order()` collate by `LC_COLLATE`", "`identical()` on two reader results", "`system2(stdout = TRUE)` warns on a non-zero exit". The diff handles each of these (radix sort, skip when scripts/ is absent, git() checks status). About 110 headings not read.
- code-check-shell.md: none read (no shell in the diff; the git pathspec excludes the guard uses are unchanged code).
- code-check-spatial.md: none read (no spatial code in the diff).

## Findings

- **[severity: bug]** scripts/discharge_publish.R:203 (`publish_own`) and :244 (the daily guard), together with this branch's edit to scripts/vignette_data_lib.R. The BUILD refuses this branch's own tree, so the step left "Owed at the end" (the next BUILD writes the digests) cannot run as planned. BUILD's two code-changed guards run `git diff --name-only <seg_commit|day_commit> HEAD -- R scripts`, excluding only `publish_own` (R/wet_catalog.R, R/wet_db_load.R, R/wet_values_compare.R, scripts/discharge_publish.R, scripts/discharge_publish_lib.R) and, for the monthly guard, also `segment_daily_output.R`. This branch also changes `scripts/vignette_data_lib.R`, which is on neither list. Measured at HEAD:
  - `git diff --name-only 28105a3 HEAD -- R scripts <the monthly guard's exclusions>` gives `scripts/vignette_data_lib.R`;
  - `git diff --name-only f99df25 HEAD -- R scripts <publish_own>` gives `scripts/vignette_data_lib.R`;
  - from 28105a3 to the base f435121 the same diff is empty, so this branch is what trips it.

  The next BUILD on m4 therefore stops at "code changed since data/checks/segment_output_20260717.txt was built at 28105a3 (scripts/vignette_data_lib.R): rerun scripts/wb_output.R and scripts/segment_output.R". Following that remedy means rerunning wb_output.R, segment_output.R, segment_daily_output.R and then the BUILD, all for a file that builds no table: it is sourced only by `data-raw/` scripts. Until all of that runs, `vd_published()` refuses every vignette data script, because the tracked report has no digests. The plan, CLAUDE.md and research/discharge_publish.md all describe the remedy as "the next BUILD (about 3.5 h)". A later edit to `vignette_data_lib.R`, for example for an article, would trip the same guard, but this branch is the first to do it.

  Suggested fix: add `scripts/vignette_data_lib.R` to `publish_own`, and to `own` in scripts/segment_daily_output.R:80 so a daily rerun stays consistent. It is a reader of the published product, not an input to the tables. Or, if the stricter rule is wanted, correct the "Owed" step and the docs to name the full rerun.

No other defect found. I checked:
- the human sequence across machines: BUILD, then commit the report, then PUBLISH (dirty check, `HEAD:` report with the commit and tree lines), then `publish_report_live()` on the working copy (equal to HEAD under the dirty check), then commit, then pull on the other machine and run `vd_published()`;
- a refusal after the upload, which leaves the file unchanged, so a rerun of PUBLISH is not blocked by the dirty check;
- a BUILD whose live-build line reads `could not read`, which `publish_report_live()` accepts;
- a republish of identical bytes, whose BUILD line already passes;
- the three data-raw callers, which record only `pb$catalog`, `pb$report`, `pb$reader` and `pb$segment_commit`; nothing parsed the old line's tail;
- the doc sentences on "both", "only" and "requires" against the code: they hold for reports written at or after this branch.

The test file passes in a copy (24 pass, 0 fail, no error).
