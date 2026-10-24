# Task: Articles: bring the three vignettes to soul's current writing convention (software citation, dated words, issue pointers) (#110)

**If we do it:** the three articles follow soul's current `writing.md` (open with the answer; plain words; no word that dates and no pointer to pending work; name, link and cite the software, with a computed "Software and citation" section). Each article says which code and which release it describes, and none of its sentences goes false when an open issue closes. **If we never do:** the articles cite no software, and several sentences rest on open issues or dated wording that will go stale.

## Decided at the gate

Approved by the user at the plan gate, 2026-10-23 (recommended option 1 in each case unless noted).

1. **Word caps.** The issue leaves this decision to us.
   - **(Recommended)** Keep 900 and 600. Each guard stops counting at the `## Software and citation` heading, because that section is reference matter computed in the chunk. Body prose, including the new "the R package `wet`" wording, still counts. The segment article gets room from cutting its Validation section.
   - Raise the caps, for example to 1,000 and 700, and count everything.
   - Keep the caps and count everything, which cuts body prose by about 120 words in segment-discharge.
2. **Shared helper: an internal R function in wet, not a child Rmd, and not in `xciter` yet.** It is `wet_software_cite(pkgs)` in `R/wet_software_cite.R`, internal, and called as `wet:::wet_software_cite()`. It is testable, it ships with the installed package that pkgdown renders against, and there is one copy.
   - The user asked whether it belongs in `xciter`, then judged that probably not worth the dependency yet (2026-10-23). `xciter` is at 0.0.0.9001, with no DOI, no pkgdown site and no release. Depending on it would mean a `Remotes:` pin in wet for about 20 lines, and the articles would then have to cite it too.
   - The helper stays internal, so moving it later breaks no caller. An `xciter` issue records where it goes once a second repo needs the same line.
3. **Models stay in plain type.** VIC-GL, Raven and PNWNAmet are models and datasets, not installable software, which follows monthly-flow's precedent. PostgreSQL is software, so it goes in code font with a link.
4. **The zone-adjustment Limits bullet becomes a statement of a decision.** It does not list checks. It says that on headwater basins the adjustment does not beat raw precipitation less evapotranspiration and is kept by decision. This uses writing.md's "call a choice the evidence did not make a decision".


## Phase 1: Shared citation helper

- [x] `R/wet_software_cite.R`: lift monthly-flow's `cite_line()` into an internal function. It runs `knitr::write_bib()` over `pkgs` and checks the result is non-empty. It returns one markdown bullet per package, holding the code-font name, version, concept DOI link when `citation()` has one, `commit <7>` only when `RemoteSha` is a 40-hex hash, and the text citation. It stops if `knitr` or any of `pkgs` is not installed.
- [x] Split out a pure formatter, an internal `wet_software_line(pkg, version, doi, sha, text)`, so the tests need no mocking of `utils`.
- [x] `tests/testthat/test-wet_software_cite.R`: test that no DOI gives no DOI text; that a 40-hex SHA prints its first 7; that a version string in `RemoteSha` (CRAN `1.5.2`) prints no commit; that `wet` itself returns its concept DOI 10.5281/zenodo.23305781; and that a missing package errors.
- [x] File an issue in `NewGraphEnvironment/xciter` (filed as xciter#6). It proposes `xciter` as the home for the software-citation line (concept DOI, version, commit-if-hash, from `knitr::write_bib()`) once a second repo needs it. It links wet's helper and soul's `writing.md` rule, with nothing moved now.
- [x] `vignettes/monthly-flow.Rmd`: replace the inline `cite_line()` with `cat(wet:::wet_software_cite(pkgs), sep = "\n")`. Its rendered text must not change, which the Phase 4 diff checks.

## Phase 2: `segment-discharge.Rmd`

- [x] Software names get code font and a first-mention link saying what each is: "the R package `wet`" linking the pkgdown site, `fwapg` (the fork link stays), `duckdb`, and `PostgreSQL`.
- [x] Remove the dating word: "The current build has …" becomes the build this article reads, named by its date and commit.
- [x] Remove the open-issue pointer: drop the fwapg#24 link from the Nechako Reservoir sentence. State what the build shows instead: routed flow is far below the balance's there. The existing `nech_bal > 90` guard already fails if that stops being true.
- [x] Limits: rewrite the zone-adjustment bullet as decision 4, in one sentence about what the product does.
- [x] Method link: plain text "how the balance is built" instead of the path `research/water_balance_method.md`, placed at the end as the article's one "how it's built" link.
- [x] Cut the `## Validation` section (the reader-pass rules, item 4). Its content becomes the opening paragraph of a new `## Software and citation` section: two sentences on when and from what build the numbers were bundled, plus a link to the build report. The `provenance` guard chunk stays.
- [x] Add a `## Software and citation` section with the helper over `wet`, `duckdb`, `ggplot2`, `gq` and `sf`. Then a Data line, following monthly-flow: PCIC hydromosaic, the `fwapg` fork at `prov$routed_commit`, the Freshwater Atlas through Norris (2026) `fwapg`, HYDAT release, and Chapman et al. (2018) for the method.
- [x] Score table: move the "PCIC does not list the gauges it calibrated to…" caption note into `kableExtra::footnote()`, using the reader-pass rules' measured form: `kable(format = "html")`, then `kable_styling(full_width = FALSE)`, then `footnote(general_title = "")`.
- [x] Word guard: apply decision 1, then render and confirm the count is within the cap.

## Phase 3: `station-flow.Rmd`

- [x] Read the article line by line for software names. This was not done in the audit. Expect `wet`, `cd` (the departure statistics), `tidyhydat` (the HYDAT read), `fwapg` and `gq`. Each gets code font and a first-mention link saying what it is.
- [x] Remove the prose paths `data-raw/station_vignette_data.R` and `data-raw/station_vignette_map.R`. "Cached inputs" becomes the opening of a `## Software and citation` section, in two sentences: HYDAT release, provisional and real-time retrieval date, life-history table commit, and map layers from the Freshwater Atlas and BC Geographic Names. Update "(see Cached inputs, below)" to point at the new section.
- [x] Trends: name the test behind "significant at p <". `cd_trend()`'s `mk_pvalue` points to Mann–Kendall; confirm it, and Sen's slope, in `cd`'s code first. Give each its reference on the Scores line, plus a plain reading of the test where the article reads the p-value.
- [x] `## Software and citation`: the helper over `wet`, `cd`, `tidyhydat`, `ggplot2`, `gq` and `sf`, with Data and Scores lines. Gottesfeld and Rabnett (2007) goes on the Data line, and the trend references go on the Scores line.
- [x] Grep for dated words and issue pointers (none found in prose in the audit), apply decision 1 to the guard, and confirm the count is within 600.

## Phase 4: Verify and document

- [x] Install the branch (`pak::local_install()`) so pkgdown and `system.file()` read the branch's helper.
- [x] Render all three articles on main and on the branch, strip the HTML to text, and diff. Only the prose meant to change may differ. monthly-flow must show no difference.
- [x] Check each built page: the footnote renders once, the caption is not numbered twice, and no `NA` appears in a table `style` attribute.
- [x] Record word and line counts before and after for each article, as writing.md's "Measure the simplification" asks.
- [x] `devtools::document()`, `devtools::test()`, `lintr::lint_package()` and `pkgdown::check_pkgdown()`. The helper is internal, so it needs no reference-index entry.
- [x] CLAUDE.md: one clause for the shared citation helper in the vignette paragraphs. NEWS goes at release.

## Owed at the end (reported, done after merge)

- [ ] pkgdown deploy: confirm the three articles on the live site carry their "Software and citation" sections, by checking the gh-pages provenance.

## Validation

- [x] Tests pass
- [x] `/code-check` clean (once over the branch with `/code-check branch`)
- [x] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:
- The helper is proved by unit tests on the formatter, one of them a restore-the-bug test where a version-string SHA must print no commit.
- monthly-flow's refactor is proved by a rendered-text diff against main showing nothing.
- The prose edits are proved by the rendered-text diff, read change by change, and by each article's own `stopifnot()` guards, which run at render.
- The caps are proved by the article word guards at render, with the counts reported.

