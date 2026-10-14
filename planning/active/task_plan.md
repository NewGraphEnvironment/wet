# Task: Snow predictors for the monthly shares (#16)

**If we do it:** the monthly split may improve where timing is snowmelt-driven. The median blocked-CV NSE on the shares is 0.87; zones 27–29 are at about 0.5. **If we never do:** the monthly shares keep using monthly P, T and AET only.

Done together with #68 (store the held-out monthly balance with each fit).

## Plan context

The monthly shares (`wet_share_fit()`) are regressions on the same month's P, T and AET plus elevation and location. Under blocked CV the balance flattens the freshet (#65): it is below the gauge in the peak month at 69 % of the 243 gauges that peak in May or June, and the median share NSE is about 0.5 in zones 27–29. #16 adds cd's ERA5-Land `snowmelt_doy_50` and `swe_max` (1981–2010 mean) as upstream-mean predictors, and keeps them only if they pass a rule fixed before the rerun. #68 lands first in the same branch: it stores the held-out monthly values with each fit, so the snow comparison reads them instead of recomputing `predict_cv()`. Both change hashed scoring code, so one rerun of both chains on m4 covers both.

Decisions made at the plan gate (2026-10-14):
- **Province key:** snow is a new pair of layers in the province stack, so the run gets a new key. The old `962a9cc2c4` is set aside as `data/wb/_pre16/`. `pooled_variant.txt` and `adjust_override.txt` are carried to the new fit dirs, which is valid only if each fit's held-out annual (`cv_ann`) is identical to the old one's. That is asserted.
- **Keep rule:** keep snow iff the blocked-CV median per-gauge share NSE over all calibration gauges rises by ≥ 0.01, applied in `wb_validate.R` on each fit's own held-out gauge-months. Zones 27–29, the May/June freshet-peak gauges (peak-month error) and WSC area 10 are reported but do not decide.
- **Publish scope:** build the publish tree and its report on m4, and do not upload. Upload, vignette-data regeneration and the switch of `data-raw/monthly_vignette_data.R` to stored months go to a follow-up issue, unless snow is rejected and the build is byte-identical to the live one (then that switch is done here, see Phase 7).

Facts from exploration:
- cd publishes `snowmelt_doy_50_annual.tif` and `swe_max_annual.tif` (76 bands, 1950–2025, 0.1°, cd_sha 349f9d7, built 2026-10-10). Over 1981–2010, every land cell has 30/30 non-NA years for both variables: 20,739 cells for doy and 20,746 for swe_max; sea is NA.
- `cd_baseline()` is `mean(value, na.rm = TRUE)` over the baseline years and never reads `anomaly_type`, so cd#139 cannot reach a baseline. `swe_max` comes from state variables (`sde`, `rsn`), so cd#88 does not touch it. `snowmelt_doy_50` comes from accumulated `smlt`, which cd#88 does touch.
- `wet_share_fit(d, static =)` already takes extra per-station predictors. `wet_share_predict()` uses `fit$static`, so `wb_output.R` needs no change beyond the upstream columns being present.
- `score_files_for()` (`scripts/wb_score_md5.R`) hashes `wb_validate.R`, `wb_cv_lib.R` and `R/wet_share_fit.R`, so every fit goes stale. `wb_province.R`'s key hashes `basename(f_in)` and its `code_files`.

## Phase 1: Check the snow inputs in cd (cd#88, cd#139)
- [ ] cd#139: record that `cd_baseline()` is a plain mean over baseline years and never reads `anomaly_type`, and that wet's per-cell baseline uses the same definition
- [ ] cd#88: confirm from cd's backfill provenance (`scripts/backfill_edh_snow.py`, run logs or COG tags) that 1981–2010 `snowmelt_doy_50` was written from a store that reached past each year's end (365/366-day years). `swe_max` comes from state variables and is not affected. Record the evidence in `findings.md`
- [ ] Record the per-cell completeness measured above (30/30 years on every land cell) and the grid (0.1°, sea NA)

## Phase 2: Store the held-out monthly balance with each fit (#68)
- [ ] `scripts/wb_validate.R`: add `cv_share` (held-out shares, n × 12, the shipped specification) and `obs_share` (observed shares, n × 12) to `cv_aet-<AET>.rds`, so `long()` can be rebuilt from the file alone
- [ ] Update the header comment and `CLAUDE.md`'s `wb_validate.R` line to name the stored months

## Phase 3: Snow normals on the 30″ grid
- [ ] `R/wet_snow_normals.R`: `wet_snow_normals(grid, vars = c("snowmelt_doy_50", "swe_max"), years = 1981:2010, dir = "data/snow", catalog = NULL)`. It reads cd's annual COGs (`cd::cd_catalog()`, `cd::cd_cache_fetch()`; cd stays in Suggests with `rlang::check_installed`), requires every year's band, takes the per-cell mean over `years` (`cd_baseline()`'s definition), and projects bilinearly onto a template of `grid`. The cache is keyed on the grid, the catalog checksums and a method version. Cells with no ERA5-Land land cell are left NA for the caller
- [ ] `tests/testthat/test-wet_snow_normals.R`: a synthetic local catalog and COGs. Covers: the mean over exactly `years`, refusal on a missing year band, a variable absent from the catalog, cache hit and key change, and NA left where the source is sea
- [ ] A runnable `@examples` (`@examplesIf interactive()`, as in `wet_terraclimate_aet()`), `devtools::document()`, `pkgdown::check_pkgdown()`
- [ ] `scripts/wb_inputs.R`: build it, and add manifest rows (source COG hrefs, cd_sha and checksums, output md5 and grid)
- [ ] One-off check, recorded in `findings.md`: for two AOIs, the area mean of the wet grid matches `cd_baseline(cd_extract(...))` within resampling error

## Phase 4: Snow layers in the province run
- [ ] `scripts/wb_province.R`: `f_in[["snow"]]` and `R/wet_snow_normals.R` in `code_files`. Snow layers are added after the analysis mask like the ET-experiment layers, with coastal cells off ERA5-Land's land filled from the nearest ERA5-Land cell and counted in `ex_filled_cells.txt`. The existing "mask must not have moved" assertion covers them
- [ ] `R/wet_share_fit.R`: document the snow predictors as optional `static` columns, and test a fit with `static = c("elev", "e_km", "n_km", "snowmelt_doy_50", "swe_max")` in `test-wet_share_fit.R`

## Phase 5: Score both share specifications and apply the rule
- [ ] `scripts/wb_cv_lib.R`: `predict_cv()` returns held-out shares for both specifications (`share_base`, `share_snow`) in the same folds. `share` is the shipped one
- [ ] `scripts/wb_validate.R`: the pre-set rule (keep snow iff the blocked-CV `nse_share_median` rises by ≥ 0.01). `fits.rds$share` and `share_snow` use the chosen specification, the cv file stores `cv_share_base`, `cv_share_snow` and the outcome, and the report gets a share-specification section (both medians, the rule, the outcome)
- [ ] `scripts/wb_share_snow.R` (not hashed): reads the stored months only, and writes `data/checks/wb_share_snow_<release>.txt` with base vs snow by month, by zone (27–29 named), at the freshet-peak gauges (peak-month error, share below gauge) and in WSC area 10. Where the set-aside fit exists, it asserts `cv_ann` is identical to the old fit's for every AET variant scored
- [ ] Commit the rule before any rerun (the commit is the pre-registration)

## Phase 6: Rerun on m4 (worktree of this branch, data linked to the main checkout's)
- [ ] `wb_inputs.R` (snow grid), then `wb_province.R 4` (new key); set `962a9cc2c4` aside as `data/wb/_pre16/`
- [ ] `fit_20251014`: `wb_validate.R` for every AET variant, `wb_aet_compare.R` (must reproduce #15), `wb_validate.R <winner>`, `wb_share_snow.R`
- [ ] `fit_20260717`: carry `pooled_variant.txt`, `pooled_test.txt` and `adjust_override.txt`, run `WET_AET_CARRY=20251014 wb_validate.R`, then `wb_share_snow.R`. Its `cv_ann` identity assertion must pass, or stop and report
- [ ] `wb_output.R`, `segment_output.R`, `discharge_publish.R` BUILD only (no `WET_PUBLISH`), and commit the tracked reports
- [ ] Copy a reduced bundle of the new key to m1, replacing `962a9cc2c4` there (the old one set aside), and update the machine memories

## Phase 7: Record the outcome
- [ ] `research/water_balance_method.md`: the share predictors, the rule, and the result by zone and at the freshet gauges
- [ ] `CLAUDE.md`: architecture lines for `wet_snow_normals()`, `wb_share_snow.R` and the stored months
- [ ] Edit the #16 and #68 issue bodies with the outcome
- [ ] If snow is kept, file the follow-up for upload, vignette-data regeneration and the switch of `monthly_vignette_data.R` to stored months (#68's last bullet). If snow is rejected and the BUILD is byte-identical to the live build, make that switch here and regenerate to prove the result identical

## Validation

- [ ] Tests pass (`devtools::test()`), `lintr::lint_package()` clean, `devtools::document()`, `pkgdown::check_pkgdown()`
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
