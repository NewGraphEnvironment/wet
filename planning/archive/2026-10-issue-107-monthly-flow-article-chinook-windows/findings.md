# Findings — Monthly-flow article: Chinook windows from the published daily flow (#107)

## Issue context

**If we do it:** the monthly-flow article's Chinook window table shows each source's window flow from the published days beside the gauge's daily record, so a reader sees how much of the gap between a window from monthly means and the daily record (up to 27 % in the fry-migration window, #65) the published days close. **If we never do:** the article keeps scoring windows from monthly means only, while `segment_daily` is published and reads them directly.

## What exists

- `discharge/fwa/v1/segment_daily` is published (#99): per segment, source and day of a common year; `wet_segment_daily(NULL, ids, groups = "BULK")` reads it, and `wet_flow_window()` gives `basis = "daily"` from it.
- `vignettes/monthly-flow.Rmd`'s window table (#65) already compares the observed months and the daily record at 08EE013, 08EE003 and 08EE004, and both sources' monthly windows; `data-raw/monthly_vignette_data.R` builds its bundle under `scripts/vignette_data_lib.R`'s guards.
- The bundle `inst/vignette-data/monthly_values.rds` was built at a4ea0a1 on 2026-10-20 from the live build 77585a8, whose publish report passes, so the data script reruns as it stands. It needs a local fwapg holding the `pcic` schema (`WET_FWAPG_COMMIT=7c30f58`), HYDAT 20260717 and the reduced fit bundle (`shape_daily.rds`, `fits.rds`, `upstream/400.rds`, `output/400.parquet` with month 0). `vd_commit()` refuses a dirty `R/`, `scripts/`, `data-raw/` or `data/checks/`, so the script change is committed before each run.

## To do

1. `data-raw/monthly_vignette_data.R`: read the three gauges' segments from `segment_daily` (their groups only), check the balance's days against the published months, and bundle each window's daily-basis flow for both sources.
2. The window table gains each source's daily-basis column, with its difference from the daily record.
3. The held-out scoring stays on months; the daily shape's own held-out scores are #70's (`data/checks/wb_shape_daily_20260717.txt`).
4. #110's writing-convention items for this article only (decided 2026-10-20; the other two articles stay with #110).

Relates to #65, #70, #99, #110.

## Decisions

Made at the plan gate on 2026-10-20 by the user; a resumed session treats them as settled.

1. **#110 for the monthly-flow article only.** Its citation chunk is written inline in `monthly-flow.Rmd`; #110 lifts it into the shared helper when it does the other two articles. The article has no word cap, so no cap decision.
2. **The window table gains, per source, a daily-basis column beside the monthly one**, each with its difference from the daily record in brackets. Columns: Gauge, Window, Years, Daily record, Monthly day-weighted, Routed PCIC (months), Routed PCIC (days), Water balance (months), Water balance (days).
3. **The "What's next" section is cut** (writing.md: no pointer to pending work). Its two items are already stated as what the product does: routed PCIC's seasonal shape in the scores prose, and the monthly scoring's limits in Limits. The "attributed to PCIC's model … recorded in #67" sentence keeps the attribution and drops the pointer.
4. **The bundle carries the days themselves** (3 gauges × 2 sources × 365), not only the window flows: the vignette then shows the daily-basis windows coming from `wet_flow_window()` on them, the same call as the monthly ones.
5. **Routed days are checked by routing the three segments again** in the data script from the run's `pcic.subbasin_daily` and `pcic.segment_weights` (the run's fingerprint held, as `vd_routed_check()` holds it), through `wet:::wet_routed_fold()` and `wet:::wet_routed_days()` on only the sub-basins the three weights name, at `tol = 0`. A difference that is one 1e-5 step at a rounding tie, by the publish's tie rule (`scripts/discharge_publish.R`, `day_tie`), is counted on its own; any other difference refuses the bundle. The balance's days are made again from the *published* months and the shape predicted from the bundle's upstream predictors (`wet_shape_predict(shape$fit, up[, shape$static])`, `wet_shape_daily()`), compared at the default tolerance (another machine's last bits), and each month's day mean must equal the published month within 1e-9 (the literal check in To do 1).
6. **Software cited**: the packages the article loads or names, `wet`, `duckdb`, `ggplot2`, `gq`, through `knitr::write_bib()`, printing concept DOI (`Config/DOI` via `inst/CITATION`), version and the commit when `packageDescription()$RemoteSha` is a 40-character hash.

## Plan

Parked 2026-10-20 after plan-mode exploration; `/planning-init 107` presents these phases as the draft.

### Phase 1: the data script reads, checks and bundles the days

`data-raw/monthly_vignette_data.R`

- [ ] After the monthly published read: select the historical `segment_daily` parts for `BULK` (both sources; `stopifnot(setequal(source, …))` as `segment_vignette_data.R` does), `vd_verify()` them, read the three segments with `wet_segment_daily(NULL, seg_bulk$linear_feature_id, groups = "BULK", catalog = cat_pub)`, `vd_verify()` again; assert 2 × 3 × 365 rows, no NA, both sources.
- [ ] Routed days routed again (decision 5): weights for the three ids from `pcic.segment_weights` (`routed_weights_table`, `routed_where`), `pcic.subbasin_daily` for their own and upstream subids, `wet_routed_fold()` → `wet_routed_days()`; `wet_values_compare(tol = 0, time = "doy")`, ties counted as the publish counts them; add the row to `cmp`/`pub_check` ("routed days (Bulkley segments) = routed again from the run's sub-basin days").
- [ ] Balance days made again (decision 5): `shape <- readRDS(file.path(fit_dir, "shape_daily.rds"))`, `stopifnot(identical(shape$method, "donor"), identical(shape$code_md5, fits$code_md5))`; weights from `up` (the Bulkley watersheds the bundle holds), days from the published months 1–12 via the lut; two `pub_check` rows: "balance days = published months × shape" (default tol) and "balance months from the days = published months" (day mean per `wet_doy_month()`, tol 1e-9). Extend the `compared` identity check so every row's `compared` is its source's row count.
- [ ] The daily-basis windows run here too, as the recipe check does: `wet_flow_window()` on the days with the article's three Chinook windows must give `basis = "daily"` and no NA.
- [ ] Bundle `segments_daily` (`station_number, linear_feature_id, source, doy, q_m3s`), ordered as `segments`; provenance gains the daily parts (`cat_pub` already carries all 512 parts), `shape_code_md5` and the `shape_daily.rds` md5; `no64()` on it; budget stays 500 KB.
- [ ] Header comment: the new element and the daily checks, in the header's own words.
- [ ] Commit the script, then run it (`WET_FWAPG_COMMIT=7c30f58 Rscript data-raw/monthly_vignette_data.R`); commit the bundle. Each prose number of Phase 3 is read from this bundle.

### Phase 2: the bundle's test

`tests/testthat/test-vignette_data.R`, "the monthly values hold both sources' months…"

- [ ] `expect_named(v, c("segments", "segments_daily", "gauges", "provenance"))`; `segments_daily`: 3 × 2 × 365 rows, no NA, no duplicate `(linear_feature_id, source, doy)`, same segments as `segments`; the balance's day means per month equal `segments`' balance months 1–12 within 1e-9; `provenance$published_check` has the three daily rows with `compared > 0` and `differing == 0`; no integer64.

### Phase 3: the article

`vignettes/monthly-flow.Rmd`

- [ ] `windows` chunk: `src_d <- wet_flow_window(v$segments_daily[…], windows, by = c("station_number", "source"))`, `stopifnot(all(src_d$basis == "daily"))`; `win` gains `routed_daily`, `balance_daily`; `err_of()` serves both bases.
- [ ] `window-table` chunk: the columns of decision 2; caption says the days are the published `segment_daily`, laid on the fit's daily shape for the balance and routed day by day for PCIC.
- [ ] Prose in "Flow in the Chinook windows": open with the answer (how much of the fry-migration gap the days close, per source, from the bundle's numbers), each claim held by a `stopifnot()` in the chunk, as the section's claims are now. Where the days close less of the gap for one source than the other, say so as what the product does, not what the reader should do.
- [ ] Intro paragraph: one sentence that the windows are also taken from the published days.
- [ ] Limits: replace the `basis = "monthly"` bullet (it names #99) with what the table shows, no issue pointer.
- [ ] Validation: the new `pub_check` rows appear in the table by construction; one sentence on what the routed and balance days were checked against; `shape_code_md5` printed with the fit's provenance.
- [ ] #110 items (decision 1): "the R package `wet`" with a link on first mention; `duckdb`, `fwapg`, Postgres in code font and linked; remove `#67`, `#6`, `#16`, `#102`, `fwapg#6` from prose (the scores prose keeps "`wet_share_fit()`" and the snow terms, and says the donor shares were chosen by a pre-set rule without the issue number); cut "What's next" (decision 3); the method link to `research/water_balance_method.md` as plain link text ("how the balance is built"), the GitHub URL, not a path.
- [ ] "Software and citation" section (decision 6): a chunk writing `knitr::write_bib(c("wet", "duckdb", "ggplot2", "gq"), tmp)` and printing each entry with DOI, version, commit-if-hash, as #110's body specifies.
- [ ] `CLAUDE.md`'s monthly-flow paragraph: the windows have both bases, the daily checks, and that the article carries #110's convention. `README.md`'s article line unchanged unless its one-line description reads false.

### Phase 4: render, check, archive

- [ ] Render before (main) and after; strip both to text and diff: only the intended prose differs, every number the prose quotes is held by a `stopifnot()`.
- [ ] `devtools::test()` (the vignette-data test), `lintr::lint_package()`, `pkgdown::check_pkgdown()` (no new export, so a pass is expected).
- [ ] `/code-check branch` (three-round floor); PWF checkboxes; `/planning-archive`; `/gh-pr-push`.

### Owed at the end (reported, done after merge)

- #110's body: the monthly-flow bullets confirmed done under #107 at merge (its body already says they are taken here).

### Verification

- The data script refuses unless every `pub_check` row has `differing == 0` and `compared` equal to its source's row count, the parts verify before and after each read, and `vd_published()`, `vd_routed_check()` and `vd_commit()` pass; the bundle is under 500 KB.
- The test above fails on the old bundle (no `segments_daily`) and passes on the new.
- The rendered article: the window table has the daily columns; the fry-migration row's daily-basis difference from the daily record is smaller than its monthly-basis one for the gauge's own record (the days close the approximation), and the prose number equals the table's; no `#N` in the rendered prose; a "Software and citation" section with wet's DOI, version and commit.
- Text diff of the render before and after shows only the windows section, Limits, the cut "What's next", the citation section and the #110 wording changes.



## Errors Encountered

| Error | Resolution |
|-------|------------|
| `pcic.subbasin_daily … (0 rows …) is not what pcic.runs describes` (data script, m1) | load the run's days: `curl … pcic.subbasin_daily.<run>.csv.gz \| gunzip \| psql -v table=subbasin_daily -f load/pcic_run.sql` |

## Pre-existing test failure on main (found 2026-10-23)

`test-vignette_data.R:59` expected `segment_values.rds` to have names `skill, segments, provenance`; #99 added `daily` to the bundle (`data-raw/segment_vignette_data.R`) and did not update the test. CI runs pkgdown only, so it never showed. Fixed here in the same file Phase 2 edits (one line).

## m1's `pcic.subbasin_daily` was empty (2026-10-23)

The first data-script run refused: `pcic.subbasin_daily … (0 rows, 0 sub-basins, total NA) … is not what pcic.runs describes`. m1's `pcic` schema (loaded 2026-10-18) had the weights, crosswalk, runs and both monthly runs, but no sub-basin days for either run. Loaded the 1981-2010 run with fwapg's `load/pcic_run.sql` from `fresh-bc/fwapg/extras/pcic.subbasin_daily.pnwnamet_historical_1981-2010.csv.gz` (13,786,122 rows, 37,667 sub-basins, 90 s; checked against `pcic.runs` by the load itself). The 1951-2012 run's days are still not on m1; nothing reads them.

## Plan review

`planning/active/review-plan.md`: 12 findings, 7 already covered by the code as written, 5 taken (citation chunk guards, prose written after the bundle, a Limits sentence for To do 3, daily parts in provenance, the CLAUDE.md gaps sentence).

## The article, rendered before and after (2026-10-23)

Both renders with `devtools::load_all()` (the before from `main`'s Rmd and bundle, a4ea0a1), stripped to text: 2,413 → 2,992 words. `/usr/bin/diff` (the shell's `diff` is a git wrapper that prints nothing here) shows 175 changed lines, all intended: the intro, the two source bullets, software names in code font with links, the windows prose and the table's four source columns, the scores prose (issue numbers out), the cut "What's next", Limits, Validation's day checks, the citation section, and the bundle's commit and date. No `#N` remains in the rendered prose.

What the days do in the fry-migration window (the bundle's numbers): the gauge's days run 21 % (Buck Creek) and 20 % (08EE003) below its monthly means. Routed PCIC's days fall further, 33 % and 24 %, so its error goes +39 % → −7 % at Buck Creek and +60 % → +21 % at 08EE003. The balance's days fall 21 % at Buck Creek (its donor shape there is the gauge's own), leaving its annual error, −12 %; at 08EE003 they fall only 5 % and the error stays +356 %. In migration the days move no window by over 1 %; in spawning by up to 9 % (routed at Buck Creek). The reviewer's finding 9 was right: the days do not "close the gap" for the balance at 08EE003, and the prose says so.
