# Task: Merge the segment-discharge and monthly-flow articles into one article on the published product (#149)

**If we do it:** one article answers "what does wet publish for my stream, which value should I use, how do I read it, and how good is it", for the yearly, monthly and daily values together. **If we never do:** a reader has to read "Stream Discharge per Segment" and "Monthly Flow per Segment" side by side, and both repeat the two sources, their periods, how to read the parts and the scores at the calibration gauges.

## Decided at the gate (user, 2026-10-29)

- **Address:** keep `vignettes/segment-discharge.Rmd`, titled "Stream Discharge per Segment". Only `articles/monthly-flow.html` goes away, and pkgdown's `redirects:` (pkgdown 2.2.0) sends it to `articles/segment-discharge.html`.
- **Gauge set:** both sources are scored on the **279** gauges where routed PCIC has flow and the gauge's segment carries at least a fifth of the gauge's flow (`routed_far_low` 0.2, as in the routed report and the monthly article). The balance is also scored on all 315. Measured: the yearly routed scores move from MAE 24.2 % / bias +1.4 % / 63 % within ±20 % (290 gauges) to 21.5 % / +5.1 % / 66 % (279). Routed is closer at 168 of the 279. Every claim in the prose still holds.
- **Scope:** Fixes #80 (drop the `n_both_src > 0.5 * n_with` half of the check). Takes #74's recipe fix (`INSTALL httpfs` before `LOAD httpfs` in the article's duckdb recipe). #74 stays open for having `segment_vignette_data.R` run the recipe and rebuild the bundle.
- **Bundles:** both data scripts, both bundles and every data-script guard stay as they are. No bundle is regenerated.

## Phase 1: Baseline renders

- [x] Install main and render both current articles (`pkgdown::build_article()`) into the scratchpad. Strip each to text and record its body-prose word count (the articles' own counting rule) and every number in its text.

## Phase 2: One article

- [x] Rewrite `vignettes/segment-discharge.Rmd` with these sections:
  1. **What it is.** The three datasets (`segment_monthly` months 0–12, `watershed_monthly`, `segment_daily`) and the manifest. The two sources and their periods, with how each fills its months: routed's annual value is the plain mean of its 12 months, and the balance's months sum to its year.
  2. **Which value to use.** `pick`'s rule, the province counts and the province map, unchanged.
  3. **How to read it.** `wet_segment_monthly()` and `wet_segment_daily()` for one segment (Buck Creek, 17094080, both reads already run by the data scripts), plus `wet_flow_window()`. Then the duckdb group read of `pick`, now with `INSTALL httpfs`. Then `wet_db_load()`. Then one paragraph on the row's columns.
  4. **What a year looks like.** The Bulkley map and the hydrographs at 08EE013, 08EE003 and 08EE004, with the Chinook-window strips. Short prose: routed overshoots Buck Creek's freshet and falls short at Quick, and the balance is in-sample at the two calibration gauges.
  5. **How good it is.** **One table**: yearly rows (MAE, bias, middle half, within ±20 %) and monthly rows (median per-gauge NSE of the 12 months, median monthly error at its lowest and highest months, gauge-months within ±20 %). Columns are routed PCIC and the held-out balance on the 279 gauges, plus the balance on all 315. One sentence says which 11 gauges are left out and why. The monthly error-by-month figure stays (it shows routed's seasonal shape). The weaknesses become one list: headwaters, small basins, the dry interior, lake outlets and basin size (from the NSE groups), routed's spring-low/summer-high shape, and the Liard.
  6. **A window from months or from days.** The current section, shrunk. One short table at 08EE013 and 08EE003 over the three windows: the gauge's cost of reading a window from its monthly means, then each source's error from its months and from its days. A few sentences: the days remove that cost where a source's daily pattern is right, and the balance's borrowed pattern at Houston is the exception. Windows are defined in "How Stream Flow Has Changed Where Gauges Are Few", which is linked.
  7. **Limits.** The two lists merged with duplicates removed.
  8. **Software and citation.** One provenance paragraph for both bundles. `wet_software_cite(c("wet", "duckdb", "ggplot2", "gq", "sf"))`. Data, method (Chapman et al. 2018), windows (Gottesfeld and Rabnett 2007) and scores (Nash and Sutcliffe 1970, Moriasi et al. 2007).
- [x] The setup loads both bundles and asserts they come from one published build (same `wet_commit` and `built`), because the merged prose names one build. Every `stopifnot()` guarding a surviving sentence is kept. Guards whose sentences are cut are removed, and `progress.md` lists them. Cut: the Buck Creek spring-window table (the window section makes the same point), though its guard tying the shown recipe to the bundled read stays; the 12-row monthly error table (the figure carries it); and the separate NSE group table (it goes into the one table and the bullets).
- [x] The word-count chunk caps body prose at 2,000 words.
- [x] `git rm vignettes/monthly-flow.Rmd`.

## Phase 3: Addresses and docs

- [x] `_pkgdown.yml`: remove `monthly-flow` from the article list, and add `redirects: - ["articles/monthly-flow.html", "articles/segment-discharge.html"]`.
- [x] README "Learn more": one line for the merged article.
- [x] CLAUDE.md: merge the two vignette paragraphs into one describing the merged article, both bundles and their guards.
- [x] Comments that name the monthly article as current: the `data-raw/monthly_vignette_data.R` and `data-raw/monthly_vignette_map.R` headers, `scripts/wb_shape_daily.R:95`, and `research/discharge_publish.md` (what the article reads). Historical mentions stay as written (NEWS, `research/water_balance_method.md:525`, the comment in `test-wet_flow_window.R`).
- [x] NEWS.md: ~~a development-version line~~ moved to the release step. Here NEWS is written by `/gh-pr-merge`'s release commit (every NEWS change since 0.4.24 is a `Release vX.Y.Z` commit).
- [x] Issue bodies: #145 (the merged title is settled here) and #74 (the recipe half is done; the data-script half is still open).

## Phase 4: Verify

- [x] Install the branch, build the article and the redirects. `docs/articles/monthly-flow.html` must be a meta refresh to `segment-discharge.html`, and `pkgdown::check_pkgdown()` must pass.
- [x] Strip the new render to text. Report its word count against the 1,800–2,000 forecast and the about 2,500 before, and name what set the floor.
- [x] Number check: a script pulls every number from the new text and confirms each one appears in the old renders, except the intended moves (yearly routed scores on 279 gauges, and the new table's monthly cells, each derived in the chunk). It lists every exception.
- [x] The rendered HTML has no stray `\@ref` and no footnote marker without a footnote section. Read the figures at their published width.

## Validation

- [x] Tests pass (`devtools::test()`; no R/ change expected)
- [x] `/code-check` clean (once over the branch with `/code-check branch`)
- [x] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Owed at the end (reported, done after merge)

- [ ] After the deploy, fetch `https://newgraphenvironment.github.io/wet/articles/monthly-flow.html` and confirm it redirects. Check the deploy provenance on `gh-pages` first.

