# Review round 1: branch 110-articles-bring-the-three-vignettes-to-so (base e2d083b..8d80cc0)

## Checklist read

- `code-check.md`: the prose of all 14 H3s under `## Mechanisms`, without the `|` table rows. Of the standalone rules I read only the index lines; none of their full sections apply to this diff (no YAML, URLs built from filenames, credentials or dispatch chains). About 30 headings not read in full.
- `code-check-r.md`: read in full the sections "Moving prose into a code chunk hides it from tools that scan the document", "A duplicate knitr chunk label fails the build", "Under `R CMD check`, tests run from a temp dir against the INSTALLED package", "A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check` if `pkg` is undeclared", "`vapply(..., USE.NAMES = FALSE)` strips ALL dimnames", "`cffr::cff_create()` writes a CRAN DOI…", "Tests that silently do not run", "`on.exit()` at a script's top level never fires", "`tempfile()` lives in the session tempdir…" and "A `skip_if_not()` skips only its own `test_that()` block" (10). The other ~125 were read as index lines only.
- `code-check-shell.md`: index only. The diff has no shell, so no heading applies (0 read in full).
- `code-check-spatial.md`: index only. The diff touches no spatial code; the sf calls in the vignettes are unchanged (0 read in full).

## Probes run (in the scratchpad, not the repo)

- Rendered HEAD copies of all three articles with `rmarkdown::render(output_dir = scratchpad)` against the installed wet 0.4.17, whose `wet_software_cite` matches `R/wet_software_cite.R` (checked with `identical(deparse())`). All three render, and none has a footnote marker.
- Word counts with the new guard: segment-discharge 829 of 900 (1068 without the cut; 899 on main), station-flow 580 of 600 (773 without the cut; 535 on main). Both guards fail loudly (`stopifnot(length(cite) == 1)`) if the heading is renamed.
- `test-wet_software_cite.R` with `NOT_CRAN=true`: 15 expectations, 0 failed, 0 errors, 0 skipped.
- No chunk label is duplicated within any article. `tools:::.check_packages_used(".")` is clean, and kableExtra, Kendall and zyp are all in Suggests.
- Checked the cited DOIs on Crossref (Chapman 2018 JAWRA 54(3) 676–693; Mann 1945 Econometrica 13(3); Sen 1968 JASA 63(324) 1379–1389); all match. Every newly added link returns 200, and figshare returns 202. fwapg PR 6 is merged. The removed fwapg#24 link is to an issue that is still open, so removing it was right.
- `cd::cd_trend()` runs `Kendall::MannKendall()` (two-sided `sl`) and `zyp::zyp.sen()` (median pairwise slope), so the new definitions of Theil–Sen and Mann–Kendall in station-flow match the code. `cfu` is max(CGIAR, Fu) (`research/water_balance_method.md`), so "held no lower than a Fu–Budyko estimate" is right, and the article's guard pins it.

## Findings

- **[severity: fragile]** `vignettes/segment-discharge.Rmd:377-379`: the sentence "Its routed values at the gauges and the picks on its map were read on `` `r format(prov$built)` ``" takes one date, from `segment_values.rds`, and applies it to both bundles. The map's picks come from `segment_map.rds`, which `data-raw/segment_vignette_map.R` writes with its own `provenance$built = Sys.Date()`. The `load` chunk ties the two bundles only on `published$wet_commit` and `published$built`, never on the date each was read. Both bundles are dated 2026-10-20, so the sentence is true today. If the map is regenerated alone, for example after a style or simplify change, the article publishes a wrong read date and no guard fires. Fix: add `identical(map$provenance$built, prov$built)` to the `stopifnot()` in `load`, or give each bundle its own date in the text.

- **[severity: bug (published claim wider than the code)]** `vignettes/segment-discharge.Rmd:380-381`: "...and every value was checked against what it was built from before it was written." This sentence is about the article's own bundle (the next sentence credits the build's report separately), and the bundle scripts do not check every value:
  - `data-raw/segment_vignette_data.R:150-165` compares only one set with its source: routed annual flow at the gauge segments against fwapg's mean of twelve months.
  - The province pick counts are held to the build's reader counts and to fwapg's segment counts.
  - The days in the daily-read table (Table 1) are checked only for `!anyNA`. Only the balance's days are tied to its months; routed PCIC's days are compared with nothing.
  - The per-segment picks on the map (`data-raw/segment_vignette_map.R:58-60`) are checked only as counts per source.

  On main the claim was narrower and true: "its data are not written unless the gauge values equal fwapg's." The same sentence in monthly-flow is backed by a script that routes the days again and rebuilds the balance from its months. The segment script does neither. Fix: go back to the narrow claim (the gauge values equal fwapg's, and the picks match the build's counts), or add the checks.

- **[severity: fragile (instruction text wrong)]** `CLAUDE.md:50`: "each article's word cap counts body prose up to that section." `vignettes/monthly-flow.Rmd` has no word cap: no `wordcount` chunk on main or on this branch (`grep -n wordcount vignettes/*.Rmd` finds only segment-discharge and station-flow). An agent reading CLAUDE.md would assume monthly-flow's prose is capped. Fix: say "the segment-discharge and station-flow articles' word caps…".

## Not findings (checked, and noted so the next round need not redo them)

- The empty-file guard after `knitr::write_bib()` (`R/wet_software_cite.R:29-31`) can fire only if none of the packages gets a record, and every package has already passed `requireNamespace()`. The per-package case its roxygen describes is actually caught by `utils::citation(p)` raising inside the `vapply()`. The behaviour is the same as main's inline chunk, and no wrong line can reach the page, so this is not reported.
- The `after/station-flow.*` copies supplied for review predate HEAD's change to the Data line ("ECCC's provisional and real-time records…"). The HEAD render reads "ECCC's provisional records as archived by water-temp-bc, and its real-time feed", as the source does.

## Verdict

Two issues to fix before merge, both in segment-discharge's "Software and citation" paragraph: one sentence's claim is wider than the bundle scripts check, and its read date is unguarded for the map bundle. CLAUDE.md:50 also needs a one-line correction. Everything else is clean: all three articles render, both word caps hold, the helper's tests pass, and the citations and links check out.
