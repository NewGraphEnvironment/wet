# Task: Monthly-flow article: Chinook windows from the published daily flow (#107)

Branch: `107-monthly-flow-article-chinook-windows-fro` (off `main` at 5bc6cc2, v0.4.16).

## Context

The monthly-flow article's Chinook window table scores each source's window flow from monthly means only (`basis = "monthly"`), while `segment_daily` has been published since #99 and `wet_flow_window()` reads it directly. The gap between a window from monthly means and the gauge's daily record reaches 27 % in the fry-migration window. The article should show each source's window flow from the published days beside the gauge record, so a reader sees how much of that gap the days close. The issue body carries a parked plan (2026-10-20); this is that plan, each phase checked against the code today.

**Checked today (2026-10-22), all on m1:** `data-raw/monthly_vignette_data.R` (305 lines) reads months only; `vignettes/monthly-flow.Rmd` (690 lines) has the `windows`/`window-table` chunks, a "What's next" section and issue numbers in prose; `tests/testthat/test-vignette_data.R:128-165` pins the bundle's three names. The bundle `inst/vignette-data/monthly_values.rds` was built at a4ea0a1 from live 77585a8 (512 parts in its catalog, daily ones included). The fit bundle has `shape_daily.rds` (donor, `code_md5` = `fits$code_md5` 37d93d99…, `shape_code_md5` b679de39…, md5 1f6da614…); its `static` is five columns (`elev`, `e_km`, `n_km`, `snowmelt_doy_50`, `swe_max`), complete on all 17 Bulkley watersheds in `upstream/400.rds`. fwapg (`fresh-db`, up) holds the `pcic` schema at 7c30f58; HYDAT 20260717 is cached. The `segment_vignette_data.R:167-191` daily read and `scripts/discharge_publish.R:520-610` (routed days routed again, the `day_tie` rule, balance days from output × shape) are the patterns to follow.

## Decided at the gate

Made 2026-10-20 by the user at the plan gate (in the issue body); treated as settled.

1. **#110 for the monthly-flow article only.** Its citation chunk is written inline in `monthly-flow.Rmd`; #110 lifts it into the shared helper for the other two articles. No word cap on this article.
2. **The window table gains, per source, a daily-basis column beside the monthly one**, each with its difference from the daily record in brackets. Columns: Gauge, Window, Years, Daily record, Monthly day-weighted, Routed PCIC (months), Routed PCIC (days), Water balance (months), Water balance (days).
3. **"What's next" is cut.** Its two items are stated as what the product does (routed PCIC's seasonal shape in the scores prose; the monthly scoring's limits in Limits). The "attributed to PCIC's model … recorded in #67" sentence keeps the attribution, drops the pointer.
4. **The bundle carries the days themselves** (3 gauges × 2 sources × 365), so the vignette's daily-basis windows come from `wet_flow_window()` on them, the same call as the monthly ones.
5. **Routed days are checked by routing the three segments again** from the run's `pcic.subbasin_daily` and `pcic.segment_weights` (fingerprint held), through `wet:::wet_routed_fold()` and `wet:::wet_routed_days()` on only the sub-basins the three weights name, at `tol = 0`; a one-step 1e-5 difference at a rounding tie (the publish's `day_tie` rule) is counted on its own, any other difference refuses the bundle. The balance's days are made again from the *published* months and the shape predicted from the bundle's upstream predictors (`wet_shape_predict(shape$fit, up[, shape$static])`, `wet_shape_daily()`), compared at the default tolerance (another machine's last bits), and each month's day mean must equal the published month within 1e-9.
6. **Software cited**: `wet`, `duckdb`, `ggplot2`, `gq`, through `knitr::write_bib()`, printing concept DOI (`Config/DOI` via `inst/CITATION`), version, and the commit when `packageDescription()$RemoteSha` is a 40-character hash.

Added today from the code (mechanism, no fork): the routed-days check also holds `routed_daily_fingerprint(conn)` to the `daily:` line of the tracked `data/checks/segment_daily_output_20260717.txt`, as `discharge_publish.R:246,266` does, so the sub-basin days routed here are the run the publish checked.

## Phase 1: the data script reads, checks and bundles the days

`data-raw/monthly_vignette_data.R`

- [x] After the monthly published read: select the historical `segment_daily` parts for `BULK` (both sources; `stopifnot(setequal(source, …))` as `segment_vignette_data.R:174` does), `vd_verify()` them, read the three segments with `wet_segment_daily(NULL, seg_bulk$linear_feature_id, groups = "BULK", catalog = cat_pub)`, `vd_verify()` again; assert 2 × 3 × 365 rows, no NA, both sources.
- [x] Routed days routed again (decision 5): hold `routed_daily_fingerprint(conn)` to the daily report's `daily:` line; weights for the three ids from `pcic.segment_weights` (`routed_weights_table`), `pcic.subbasin_daily` (`routed_daily_table`, `routed_where`) for their own and upstream subids; `wet_routed_fold()` → `wet_routed_days()`; `wet_values_compare(tol = 0, time = "doy")`, ties counted by the publish's rule (`discharge_publish.R:585-589`); add the row to `cmp`/`pub_check` ("routed days (Bulkley segments) = routed again from the run's sub-basin days").
- [x] Balance days made again (decision 5): `shape <- readRDS(file.path(fit_dir, "shape_daily.rds"))`, `stopifnot(identical(shape$method, "donor"), identical(shape$code_md5, fits$code_md5))`; weights from `up` (the Bulkley watersheds, `shape$static` complete); days from the published months 1–12 (`pub_bulk`, balance) via `seg_bulk`'s watershed; two `pub_check` rows: "balance days = published months × shape" (default tol) and "balance months from the days = published months" (day mean per `wet:::wet_doy_month()`, tol 1e-9). Extend the `compared` identity check (`:218-219`) so every row's `compared` is its source's row count.
- [x] The daily-basis windows run here too, as the recipe check does: `wet_flow_window()` on the days with the article's three Chinook windows (`life_history_bulk.csv`, CH migration/spawning/fry_migration) must give `basis = "daily"` and no NA.
- [x] Bundle `segments_daily` (`station_number, linear_feature_id, source, doy, q_m3s`), ordered as `segments`; provenance gains the daily parts used (`cat_pub` already carries all 512), `shape_code_md5`, the daily fingerprint, and `shape_daily.rds` in `md5`; `no64()` on it; budget stays 500 KB.
- [x] Header comment: the new element and the daily checks, in the header's own words.
- [x] Commit the script, then run it (`WET_FWAPG_COMMIT=7c30f58 Rscript data-raw/monthly_vignette_data.R`; `vd_commit()` refuses a dirty tree); commit the bundle. Each prose number of Phase 3 is read from this bundle.

## Phase 2: the bundle's test

`tests/testthat/test-vignette_data.R`, "the monthly values hold both sources' months…"

- [x] `expect_named(v, c("segments", "segments_daily", "gauges", "provenance"))`; `segments_daily`: 3 × 2 × 365 rows, no NA, no duplicate `(linear_feature_id, source, doy)`, same segments as `segments`; the balance's day means per month equal `segments`' balance months 1–12 within 1e-9; `provenance$published_check` has the three daily rows with `compared > 0` and `differing == 0`; no integer64. Written before Phase 1's bundle lands, so it fails on the old bundle first.

## Phase 3: the article

`vignettes/monthly-flow.Rmd`

- [x] `windows` chunk: `src_d <- wet_flow_window(v$segments_daily[…], windows, by = c("station_number", "source"))`, `stopifnot(all(src_d$basis == "daily"))`; `win` gains `routed_daily`, `balance_daily` (the table's two gauges, 08EE013 and 08EE003, the ones with a daily record); `err_of()` serves both bases.
- [x] `window-table` chunk: the columns of decision 2; caption says the days are the published `segment_daily`, laid on the fit's daily shape for the balance and routed day by day for PCIC.
- [x] Prose in "Flow in the Chinook windows": open with the answer (how much of the fry-migration gap the days close, per source, from the bundle's numbers), each claim held by a `stopifnot()` in the chunk, as the section's claims are now. Where the days close less of the gap for one source than the other, say so as what the product does.
- [x] Intro paragraph: one sentence that the windows are also taken from the published days.
- [x] Limits: replace the `basis = "monthly"` bullet (it names #99) with what the table shows, no issue pointer.
- [x] Validation: the new `pub_check` rows appear in the table by construction; one sentence on what the routed and balance days were checked against; `shape_code_md5` printed with the fit's provenance.
- [x] #110 items (decision 1): "the R package `wet`" with a link on first mention; `duckdb`, `fwapg`, Postgres in code font and linked; remove `#67`, `#6`, `#16`, `#102`, `fwapg#6` from prose (the scores prose keeps "`wet_share_fit()`" and the snow terms, and says the donor shares were chosen by a pre-set rule, no issue number); cut "What's next" (decision 3); the method link to `research/water_balance_method.md` as plain link text ("how the balance is built"), the GitHub URL, not a path.
- [x] "Software and citation" section (decision 6): a chunk writing `knitr::write_bib(c("wet", "duckdb", "ggplot2", "gq"), tmp)` and printing each entry with DOI, version, commit-if-hash.
- [x] `CLAUDE.md`'s monthly-flow paragraph: the windows have both bases, the daily checks, and that the article carries #110's convention. `README.md:43` unchanged unless its one-line description reads false.

## Phase 4: render, check, archive

- [x] Render before (main) and after; strip both to text and diff: only the intended prose differs, every number the prose quotes is held by a `stopifnot()`.
- [ ] `devtools::test()` (the vignette-data test), `lintr::lint_package()`, `pkgdown::check_pkgdown()` (no new export, so a pass is expected).
- [ ] `/code-check branch` (three-round floor); PWF checkboxes; `/planning-archive`; `/gh-pr-push`.

## Owed at the end (reported, done after merge)

- [ ] #110's body: the monthly-flow bullets confirmed done under #107 at merge (its body already says they are taken here).

## Validation

- [ ] Tests pass
- [ ] `/code-check branch` clean
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

### Verification

- The data script refuses unless every `pub_check` row has `differing == 0` and `compared` equal to its source's row count, the parts verify before and after each read, and `vd_published()`, `vd_routed_check()` and `vd_commit()` pass; the bundle is under 500 KB.
- The Phase 2 test fails on the old bundle (no `segments_daily`) and passes on the new.
- The rendered article: the window table has the daily columns; the fry-migration row's daily-basis difference from the daily record is smaller than its monthly-basis one for the gauge's own record (the days close the approximation), and the prose number equals the table's; no `#N` in the rendered prose; a "Software and citation" section with wet's DOI and version, and the commit when the install recorded a 40-character hash (a build from a checkout, pkgdown's included, records none; plan review finding 8).
- Text diff of the render before and after shows only the windows section, Limits, the cut "What's next", the citation section and the #110 wording changes.

