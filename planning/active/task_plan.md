# Task: Monthly flow vignette: explore, use and QA the published monthly values, with Chinook life-stage windows (#65)

**If we do it:** we and others get one worked place to explore the published monthly flows: how to pull a stream's twelve months, how the two sources compare with the gauges month by month, and how flow lines up with a species' life-stage windows. Writing it is also the QA pass on the monthly values, and its gaps become the list of what to fix next. **If we never do:** the monthly half of the published product (months 1–12) stays unexamined and unscored, and every user works out the read, the plot and the life-stage overlay on their own.

## Context (from plan mode)

The published product (#7, `s3://fresh-bc/discharge/fwa/v1/`) carries months 1–12 per segment for `pcic_routed` and `wet_balance`, but only month 0 has been looked at or scored (#58, #64). #65 asks for one vignette that (1) explores the monthly values as hydrographs, (2) shows a reader how to pull and plot a segment's twelve months with Chinook windows, and (3) QAs them against HYDAT month by month and files what is missing as issues.

What exploration established (shapes the phases):

- **Dependencies:** #59 (`wet_segment_monthly()`) and #6 are open, so the vignette reads through `wet_catalog()` + duckdb parquet, and carries the first monthly scoring for #6 to take over. #64 is closed (the product page to link).
- **BULK is routed-covered:** 30,037 of 32,472 BULK segments carry routed flow (local fwapg). Skeena is part `400`; m1's reduced bundle has `output/400.parquet`, so the data script runs on m1.
- **Gauges:** 08EE013 (Buck Creek) is a calibration gauge (29 complete years, 1981–2010). 08EE003 (Bulkley near Houston) is **not** in the 352 selected, though it has 1981–2010 data and is unregulated — most likely seasonal (no complete years). Its observed monthly comes from the daily record already bundled in `station_daily.rds`, months with data only; that is itself a finding. Other BULK calibration gauges (08EE004 Bulkley at Quick, 08EE020 Telkwa, …) are available as context.
- **Held-out monthly balance is not stored:** `cv_aet-cfu.rds` keeps held-out annual (`cv_ann`) and per-station NSE, not the monthly values. `predict_cv()` in `scripts/wb_cv_lib.R` recomputes them (annual × held-out share); the data script reruns it and asserts its annual equals the stored `cv_ann` exactly, so the balance is scored held out as in #64. The published balance at a gauge is in-sample and is plotted, not scored.
- **Reuse:** `wet_station_monthly()`/`s$monthly` (observed, complete years), `wet_flow_validate()` (per-station NSE on months and shares), `wet_window_stats()` (daily window means), `life_history_bulk.csv` and `station_daily.rds` (already bundled for #27), `routed_mm()`/`routed_annual()`/`shipped_heldout()` in `scripts/pcic_routed_lib.R`, `wet_values_compare()`, `wet_catalog_verify()`; the guard pattern of `data-raw/segment_vignette_data.R`.
- **Colours:** no source colours in the registries; window strips exist in `wet_station.csv` (`hydrograph/window`).

## Phase 1: Shared vignette-data guards
- [x] Move the guards `data-raw/segment_vignette_data.R` and the new script share into `scripts/vignette_data_lib.R`: clean-tree check and commit, routed table = tracked routed report, live manifest = passing publish report, parts verified against the manifest before and after a read
- [x] `data-raw/segment_vignette_data.R` sources it; rebuild `segment_values.rds` on m1 and confirm everything but `built`/`wet_commit` is identical to the committed file

## Phase 2: Monthly data script
- [ ] `data-raw/monthly_vignette_data.R` writes `inst/vignette-data/monthly_values.rds`:
  - `segments`: months 0–12, both sources, read from the published parts on the segments 08EE013 and 08EE003 snapped to (plus 08EE004, 08EE020 for context), with `period`, `pick`, `coverage`
  - `gauges`: per calibration gauge × month 1–12 (0 kept): observed (`s$monthly`, 1981–2010 complete years), held-out balance (recomputed `predict_cv()` shares × `cv_ann`, annual asserted equal to the stored), published routed on the gauge's segment; all in mm over wet's accumulated area as `scripts/pcic_routed_compare.R` takes them; with zone, nesting, area class
  - `observed_bulk`: observed monthly means at 08EE003 and 08EE013 from `station_daily.rds` for 1981–2010 and 1951–2012, with years per month
  - `provenance`, and value checks: published months 1–12 routed = fwapg's monthly table; balance months = the fit's `output/400.parquet` through the lut; none differing, none empty
- [ ] Extend `tests/testthat/test-vignette_data.R`: new budget entry (≤500 KB), plain ids, checks non-empty and zero-differing, 12 months per gauge per source

## Phase 3: Vignette — explore and use
- [ ] `vignettes/monthly-flow.Rmd` (`bookdown::html_vignette2`): what months 1–12 are and each source's period, linking the segment-discharge article for the product itself
- [ ] Hydrographs at 08EE013 and 08EE003: both sources' twelve months and the gauge's observed means, with the period difference stated and quantified (observed 1951–2012 vs 1981–2010)
- [ ] Chinook windows (migration, spawning, fry migration) shaded on the same axis; flow per window as a day-weighted mean of monthly means, beside the gauge's daily-record window mean (`wet_window_stats()` over 1981–2010), so the approximation error is separated from model error
- [ ] Recipe chunk (`eval = FALSE`): any `linear_feature_id` → twelve months via `wet_catalog()` + duckdb `hive_partitioning`, note that `wet_segment_monthly()` (#59) replaces it
- [ ] Source and observed colours added to `inst/cartography/wet_segment.csv`; window strips from `wet_station.csv`

## Phase 4: Vignette — monthly QA at the gauges
- [ ] Per month and source: median log ratio (bias), its spread, and the share of gauge-months within ±20 %; held-out balance at all calibration gauges, routed at those its segments cover; per-station NSE on months and shares via `wet_flow_validate()`
- [ ] Figure of bias by month for both sources, and a table; say where each source's seasonal shape is right or wrong (freshet timing, winter low flow)
- [ ] Decide whether a contrasting regime (coastal rain-fed or lake outlet) is needed, from what the scores show; add one only if BULK hides a problem it exposes
- [ ] "What's next": each gap found filed as an issue in wet (or the owning repo) and linked
- [ ] Render, self-review figures (cartography checklist), `pkgdown::check_pkgdown()`

## Phase 5: Docs
- [ ] `CLAUDE.md` architecture: the vignette, its data script and its guards
- [ ] Body edit to #6 noting the first monthly scoring lives in the vignette, if it holds

## Validation
- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Verification
- `Rscript data-raw/segment_vignette_data.R` reproduces the committed values after Phase 1
- `WET_FWAPG_COMMIT=341b078 WET_HYDAT=... Rscript data-raw/monthly_vignette_data.R` on m1 passes its checks
- `devtools::test()`, `devtools::build_vignettes()` / `pkgdown::build_article("monthly-flow")`, read rendered PNGs
