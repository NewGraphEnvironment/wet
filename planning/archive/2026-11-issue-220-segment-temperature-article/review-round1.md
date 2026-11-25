# Code-check round 1, #220 (branch diff against origin/main 60956900, HEAD d8fa4d39)

## Checklist read

- **code-check.md**: the prose of all 14 H3s under `## Mechanisms` (table rows skipped); in full "Documentation Staleness" and "An assertion that matches an interpolated value cannot see the claim around it"; the other 22 headings by index line only.
- **code-check-r.md**: in full: "knitr and pandoc rewrite a caption…", "A `data-raw/` script must load the source tree…", "Regenerated binaries churn git…", "ggplot2 legends and labels…", "`nzchar(NA)` is TRUE…", "`paste()` with a zero-length argument…", "Moving prose into a code chunk…", "`tolerance` in testthat is RELATIVE…", "`$` on a list partial-matches…", "A database driver's value is not a base R type…", "Postgres row order is never fixed…", "`identical()` on two reader results…", "Under `R CMD check`, tests run from a temp dir…", "Numeric routines that err at their edge, and `round()`", "`data.frame()` recycles a scalar…", "`c()` dispatches on its first argument…", "A `pkg::` call in a test…" (17); the other 115 by index line only.
- **code-check-spatial.md**: in full: "A relation between FWA watershed codes is not a place", "FWA lookup area follows watershed codes…", "A Freshwater Atlas main stem's downstream end…", "FWA main flow is not edge type 1000 alone", "A name is not a key…", "sf: `st_intersection()` / `st_difference()` return a GEOMETRYCOLLECTION…" (6); the other 92 by index line only.
- **code-check-shell.md**: none in full (the diff holds no shell); all 75 by index line only.

## What was run (in a detached worktree of HEAD, removed afterwards; the checkout was not touched)

- The supplied diff is byte-identical to `git diff origin/main...HEAD -- . ':(exclude)planning'` at d8fa4d39.
- The article renders (`rmarkdown::render` after `pkgload::load_all`); body prose is 1,176 words against the 1,200 cap; no duplicate chunk label; no unresolved citation; `pkgdown::check_pkgdown()` is clean.
- `NOT_CRAN=true testthat::test_file("tests/testthat/test-vignette_data.R")`: the six temperature tests and the budget test pass (0 failed, 0 errors, 0 skipped).
- Both bundles read and printed; the four figures read as images.
- Independent of the snap: the 25 pool stations' `tidyhydat` coordinates against the bundled basin polygon give 11 inside, the same 11 the bundle holds; all 32 HYDAT stations inside the polygon are `08E`, so the pool prefix drops none.
- The bundle's commit (8d5da4a1) against HEAD: the data script differs only in `same()`, a message and a line wrap, and the `recipe` chunk is unchanged since that commit, so the recipe the script ran is the one the article shows.
- The validation report's parse (`row_of()`): the `season open` pattern matches one row, and fields 3, 4, 7 are `n`, `rmse_mean`, `gsdd_mae` (897, 1.290, 128.74).
- The cited issues (#213, #214, #219, #222, #224) exist and are about what the text says; every linked repo is public; the two Hill et al. author spellings (N.H., N.E.) are the publisher's own.

## Findings

- **[severity: bug]** vignettes/articles/segment-temperature.Rmd:60 and :595 (chunk `versions`) — the "This build ran on" sentence is joined wrongly whenever the last package carries a commit. `and_text()` pastes the parts with `", "` and turns the last `", "` into `" and "`, but each part can itself hold `", commit <sha>"`. Rendered here: "This build ran on wet 0.4.44, cd 0.6.13, commit c8bc100, gq 0.25.0 and commit 298b016", which reads as if the commit were a fourth item and puts no "and" before `gq`. Reproduced with all three carrying a commit (the CI case): "…`cd` 0.6.13, commit c8bc100, `gq` 0.25.0 and commit 298b016". The same line is live on the published sibling (`flow-departure-normal.html` reads "wet 0.4.44, cd 0.6.13, commit 1e44183, gq 0.25.0 and commit 298b016"); `vignettes/flow-departure-normal.Rmd:742` and `vignettes/articles/flow-change-sparse-gauges.Rmd:674` hold the same code, so a fix belongs in all three (for example the commit in parentheses, so no part contains the separator).
  - **Rule:** code-check.md "Serialization loses meaning silently" ; code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: fragile]** vignettes/articles/segment-temperature.Rmd:320 ("Every other reach has no measurement at all"), :302 (caption: "the 11 stations that have recorded water temperature"), :319, and inst/cartography/wet_temperature.csv:8 (legend: "Stream reach with no temperature station") — the sentence names every measurement; its guard (:235, `all(v$stations$days > 0)`) and the data behind it cover one set: Environment and Climate Change Canada hydrometric gauges in the water-temp-bc archive whose number starts `08E` (data-raw/temperature_vignette_data.R:111), 2002–2025. Nothing in the build enumerates any other network (seasonal loggers, which `wet_temp_fill()`'s own documentation names as a source and `research/station_temperature_fill.md` says were never held out), so "no measurement at all" is unmeasured, and the population is named only in the closing Data list. The count of 11 itself holds for that set (checked independently above). State the set by the code's definition in the sentence, the caption and the legend label.
  - **Rule:** code-check.md "A proxy is not the property"

- **[severity: fragile]** vignettes/articles/segment-temperature.Rmd:297-298 — the caption's "Lakes of 500 ha and up" is a literal typed in the article (`lake_min <- 500`, a copy of `min_ha = 500` in data-raw/temperature_vignette_map.R), and its guard is `stopifnot(min(map$lakes$area_ha) >= 0)`, which no bundle can fail: a bundle with a 100 ha lake passes it (reproduced) and the caption still prints 500. The bundle's smallest lake is 513 ha, so `>= lake_min` passes today and is the guard the sentence needs.
  - **Rule:** code-check.md "A guard that fails toward pass" ; code-check.md "One fact derived twice"

- **[severity: fragile]** tests/testthat/test-vignette_data.R:348 — `expect_true(all(nzchar(c(v$pick$stream, v$pick$into1, v$pick$into2))))` cannot fail on a missing value: `nzchar(NA)` is TRUE (reproduced: `all(nzchar(c("Simpson Creek", "Kathlyn Creek", NA)))` is TRUE), and `NA` is exactly what `vm_into()` returns for `into2` where `into1` runs to the sea. The test's comment says the picked stream "is placed by what it flows into"; only the article's `identical(pick$into2, "Bulkley River")` holds that today. Add `!anyNA()`.
  - **Rule:** code-check-r.md "`nzchar(NA)` is TRUE — non-empty checks silently pass NA"

- **[severity: fragile]** data-raw/temperature_vignette_data.R:203-211 (`seasons_of()`) — a candidate year in which `gsdd::gss()` finds no season stops the script with "character string is not in a standard unambiguous format" instead of giving `in_season = FALSE`. `gss()` returns zero rows there (measured on gsdd 0.3.0.9009: a year that never holds 5 °C for a week, and any year whose March–November window still has a missing day after the fill, such as a record that starts on 2 or 3 March), and `paste0(y, character(0))` is `"2020"`, which `as.Date()` refuses (reproduced). No Bulkley year reaches it, so the committed bundle is unaffected; it bites when another row of `scripts/temperature_basins.csv` is run, which the header and CLAUDE.md call a data edit. Return a zero-row frame when `nrow(g) == 0`.
  - **Rule:** code-check-r.md "`paste()` with a zero-length argument returns length ONE, not zero" ; code-check.md "Zero-length, empty, and unset are three different things"

- **[severity: fragile]** vignettes/articles/segment-temperature.Rmd:330-331 with caption :304 — the caption says Houston, Smithers and Hazelton "are labelled (squares)", and Houston's square is not visible in the rendered map: the town point is 280 m from station 08EE013 (measured on the bundle), about 3.5 px at the rendered width, and the stations are drawn after the places, so the station's point covers it. Smithers' and Hazelton's squares show. Draw the places after the stations, or drop "(squares)".
  - **Rule:** none

- **[severity: fragile]** CLAUDE.md, the paragraph beginning "The article `vignettes/articles/segment-temperature.Rmd`" — "It carries no status and no scores" is not what the article does: the chain figure colours each piece by where it stands ("in place", "being built", which the same paragraph later says a landed piece changes in the nodes CSV), and the article prints the fill's held-out error (129 degree days over 897 seasons, from `data/checks/temp_fill_validate.txt`). A session that trusts the sentence would not look for either when #213 or the validation report moves. Say which status and scores it leaves to #214 (the baseline's and the per-reach product's).
  - **Rule:** code-check.md "Documentation Staleness"

## Checked and not flagged

- Every number the prose and captions print is computed from the bundle at render (29 days, 25 August to 22 September, 28 April to 22 October, 1,460, 1,393, 67, 15.5 and 9.6 °C, about 6 °C, 52,293, eleven, three, 257, 129, 897, 30 km, about 4 km north-west), and the literals the recipe types (station, year, pool, range) are pinned by `stopifnot()`. 1,460 − 1,393 and the printed 67 agree at the printed precision.
- "A season with a missing day has no total" holds over all 68 candidate rows (`gsdd_unfilled` is NA exactly where a year has a missing run).
- "Three of those began too recently to model": the three unfitted stations have 340 to 348 days, under `wet_temp_fill()`'s `min_days = 365`, and each began in 2025.
- The 5 °C and 4 °C thresholds and the one-week window are gsdd's defaults (`start_temp`, `end_temp`, `window_width`), which `wet_temp_gsdd()` does not override.
- PCIC's output holding daily water temperature to 2100 is what `research/pcic_channel_scale.md` records.
- The four accepted items in the brief (the rule's timing, the 24 August reading, `all.equal()` on a rebuild, no tile basemap) and the standing lint style were not re-flagged.
