# Code-check round 1 (#152), branch 152-next-pass-on-the-two-flow-change-article @ e172783, base 6fbbf65

## Checklist read

- **code-check.md** (37 headings): read the prose of all 14 `## Mechanisms` H3s (table rows skipped) and "Documentation Staleness". Not read: 22 (the other stand-alone, Security and Spreadsheets/PDFs rules; none matches a tool or shape in this diff).
- **code-check-r.md** (115 headings): read in full "`stats::aggregate()` has three separate silent behaviours…" (the measured article's new `aggregate()` calls), "`$` on a list partial-matches…" (`p$ci`/`ci_c`, `p$i1`/`i1_c`, `p$cover`/`cover_c` in the new `p152` lists), "`sort()` and `order()` collate by `LC_COLLATE`…" (`p$donors_c`), "Moving prose into a code chunk hides it…" (bib writing), "`ifelse()` with an all-NA test…", "`strsplit()` drops a trailing empty field…"; plus the index lines of the rest. Not read in full: 109.
- **code-check-shell.md** (70 headings): no shell in the diff; index only. Not read in full: 70.
- **code-check-spatial.md** (93 headings): the diff changes no spatial code (map chunks unchanged); index only. Not read in full: 93.

## What was run (in a scratch copy, nothing in the repo touched but this file)

- Rendered `vignettes/flow-departure-normal.Rmd`, `vignettes/articles/flow-change-sparse-gauges.Rmd` and `vignettes/segment-discharge.Rmd` with `pkgload::load_all()`: all three build, every `stopifnot()` and word cap passes, no unresolved citation (`???`) in the HTML.
- `NOT_CRAN=true` `test_file("tests/testthat/test-vignette_data.R")`: 0 failed, 0 error, 0 skipped.
- Read the bundle (`chinook_sites_values.rds`) to check prose claims the guards do not cover. `station_daily.rds` md5 equals the coverage report's (2ab0f583…).
- Checked the new `p152` blocks in `scripts/departure_site.R` and `scripts/departure_site_snow.R`: the vectorised `cover_of()` resamples the same way `interval_of()` does (a year drawn twice keeps one residual), no RNG use follows `set.seed(1520)`, the partial-match pairs (`ci`/`ci_c`, `i1`/`i1_c`, `cover`/`cover_c`) are all read only under `ext`, and the snow script refuses a site rds from another `departure_site.R`.

## Findings

- **[bug]** vignettes/articles/flow-change-sparse-gauges.Rmd:158 and :523–525. Two sentences lost their "under these windows" qualifier in this rewrite. They now claim more than their guards check, and the bundle contradicts them.
  - The opening says "Borrowed departures score worse in the spawning window than in the migration window at all four".
  - The scores paragraph says the borrowed departures "fall below it in the spawning window in every box, … so their ranges there carry that weaker score".
  - The guards (`ss_spw`, `ss_mig`, lines ~117–120) read only `group == "BULK"`.
  - Under the Morice windows, Gosnell Creek's borrowed spawning-mean score is 0.66 against 0.62 for migration (`score_settings`, gosnell/MORR). That window scores better than migration and is above the 0.5 bar.
  - The article presents that Morice spawning result two sections earlier ("Under it Gosnell Creek's spawning-window drop is smaller, 23%, and its range reaches no change"). A reader would take that range as carrying the weaker score, and it does not.
  - The old text read "at all four under these windows" and "under these spawning windows fall below it in every box".
  - Fix: restore the qualifier, or widen both guards to every window set and change the prose to match.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[bug]** vignettes/articles/flow-change-sparse-gauges.Rmd:525–526. "The lowest seven-day flow scores lower still, below the bar in 7 of 8 windows and boxes": no guard checks "lower still", and the data do not support it.
  - "Lower still" compares with the spawning-window mean scores just quoted (0.42–0.49).
  - The borrowed min7 scores under the Bulkley windows are 0.23, 0.42, 0.59, 0.32, 0.29, 0.45, 0.31 and 0.43. Swift's migration min7 (0.59) is above every spawning-mean score.
  - Within the spawning window, Naver's min7 (0.45) beats its own mean (0.42).
  - The chunk guards only `length(m7_sc) == 8`, and the count in the sentence is computed inline.
  - The claim holds only for the median, so it needs a guard that says so, or a reworded sentence.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (a sentence that gained a comparative is unsupported until checked)

- **[fragile]** vignettes/flow-departure-normal.Rmd:286–289 and :648–650. The article states the coverage outcome as fact, and nothing executes it.
  - It says the bar "is narrower than a 90% confidence interval: it shows the spread of the resamples, not a test".
  - The chunk comment says "it covers 83-87% of no-change records, under the 87% bar".
  - That rests on `data/checks/departure_interval_coverage.txt`, but no `stopifnot()` reads the report's OUTCOME, its coverages, or its `station_daily.rds` md5.
  - The two match today (md5 2ab0f583…, all four coverages below 0.87). A rebuilt `station_daily.rds`, or a change to the years or windows, would leave the sentence standing with nothing to refuse it.
  - The comparison article does guard its own claim (`drawn$cover >= 0.87`, from the bundle). Its sibling does not.
  - Fix: carry the four coverages, or the report's md5 and outcome, into a bundle the article can read and guard it. `data/` is not in the built package, so the guard cannot read the report directly under R CMD check.
  - **Rule:** code-check.md "A guard that fails toward pass" (a comment stating a property is an unexecuted claim) ; code-check.md "One fact derived twice"

- **[fragile]** research/chinook_sites.md, new #152 section, first paragraph. "approved HYDAT ends in 2024 for most series, and in 2025 for Swift's and Naver's filled-in migration record" misstates which series reach 2025.
  - Every Swift series reaches 2025 on both routes and in both windows (`n_post` = 10 in every Swift row of the bundle and of `departure_site_swift_bulk_20260717.txt` section 5).
  - Naver's filled-in spawning cov_day also has 10 years.
  - It is a research note, not the article, but it is the durable record of which years each period holds.
  - **Rule:** none
