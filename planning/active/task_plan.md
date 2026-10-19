# Task: Monthly shares from donor gauges' day-of-year records: #70 measured 0.939 against the shipped 0.874 (#102)

**If we do it:** the balance's monthly shares at ungauged watersheds come from the most similar gauges' own day-of-year records instead of, or blended with, the twelve share regressions, and #70's measurement says that is worth about +0.065 median NSE at the monthly scale on the held-out gauges. **If we never do:** the shipped shares stay the #16 regression, which the monthly article already shows flattens the freshet (#16, #65), and the stronger shape sits in a report nobody acts on.

## Context

The balance splits annual runoff into months with twelve share regressions (#16, snow predictors). The monthly article shows that this flattens the freshet. #70 measured, without registering anything, that the donor mean of the five nearest training gauges' shares scores a median share NSE of **0.939** against the shipped **0.874** on the same 315 held-out gauges. This issue registers a rule before any scoring, scores donor and blend against the regression under the shipped fit's blocked CV and a leak-free pool, and ships the winner only if the rule picks one. It then runs the stale chain through to a publish build.

## Decided at the gate (airvine, 2026-10-19)

1. **Months only; the daily side comes later.** If a candidate ships, its 12 monthly shares replace the regression's (`cv_share`, `fits$share`, the published months). #70's within-month shape (`shape_daily.rds`) stays the daily method and is refitted on the new months by rerunning `wb_shape_daily.R`. Whether the donor's free 365-day curve should become the daily shape is #99's question, decided when the daily data is published. The `wb_shape_daily.R` rerun reports the free curve beside the shipped shape, so that comparison is ready.
   *In plain terms:* "months only" changes how a year's water is split into months. How each month's water is spread over its days stays #70's method, now laid on the new months.
2. **The leak test is symmetric.** For each held-out gauge, every candidate is refitted on its fold's training gauges minus those upstream or downstream of it, the regression included. A candidate must beat that leak-free regression by at least 0.01.

## Fixed now, before scoring (written into `wb_validate.R`'s header in Phase 1, committed before any run)

- **Donor:** k = 5 nearest training gauges in the shipped static share predictors (`elev, e_km, n_km, snowmelt_doy_50, swe_max` on this fit, which is #16's outcome). Each predictor is divided by its SD across the training gauges. Weights are `1/(d + 1e-6·median d)`, and an exact match takes the whole weight, as in `wet_shape_predict()`'s donor. The donor averages the gauges' **observed monthly shares** (`share_01..12`, from monthly volumes, the same values it is scored against), not doy records summed to months. Those agree up to the Feb 29 fold. This keeps a HYDAT daily read out of the scoring code.
- **Blend:** the equal-weight mean of the donor and regression shares, which already sums to 1.
- **Incumbent:** the regression on the same static set.
- **Rule:** per gauge, the share NSE (`share_nse()` as in #16: observed runoff ≥ 10 mm, gauges every candidate scores), median over gauges. A candidate passes if its median beats the regression's by ≥ 0.01 under the blocked CV **and** under the leak-free pool (1e-9 tolerance). If both pass, the higher blocked-CV median ships. Otherwise the regression stays. Nothing is tuned after scoring. The rule is AET-independent, as #16's is.
- No "kept on both fits" clause. Headwater and nested gauges, and the short-record test stations, are reported beside the rule and do not gate it.

## Phase 1: Register the rule (no code that scores yet)
- [x] `scripts/wb_validate.R` header: the candidates and the rule above, word for word, committed alone, so the git history shows the rule came before any candidate code.

## Phase 2: Share candidates in the package (tests first)
- [x] `tests/testthat/test-wet_share_fit.R`: donor (k nearest, exact match takes the whole weight, k capped at n, shares sum to 1, predictors scaled by the training SD), blend (the mean of the two, sums to 1), regression unchanged (`identical()` to the current output), bad `method`/`k` refused.
- [x] `R/wet_donor_mean.R` (internal): the k-nearest inverse-distance mean, factored out of `wet_shape_predict()`'s donor branch. A test asserts that `wet_shape_predict()` output is `identical()` before and after the refactor.
- [x] `R/wet_share_fit.R`: `method = c("regression", "donor", "blend")` and `k = 5`. `R/wet_share_predict.R` dispatches on `fit$method`, with the donor vectorised in row chunks so that `wb_output.R` is fast over a whole basin. `fits$share` therefore stays one object, and `wb_output.R`'s `wet_share_predict(fits$share, up)` is unchanged.
- [x] `scripts/wb_score_md5.R`: add `R/wet_donor_mean.R` to `score_files_for()` (and to `wb_shape_daily.R`'s shape_files).
- [x] roxygen, `devtools::document()`, lintr, and `pkgdown::check_pkgdown()`.

## Phase 3: Scoring in the CV
- [x] `scripts/wb_cv_lib.R`: add `share_related` (the upstream/downstream matrix via `wet:::wet_fwa_upstream()`, as `wb_shape_daily.R` builds it). Add a share-only `cv_share_methods(d, fold, static, methods, leak_free = FALSE)` that returns held-out shares per method. `predict_cv()` gains `share_method` (default `"regression"`) so that LOO and the transparency runs use the shipped method.
- [x] `scripts/wb_validate.R`: run #16's rule first (unchanged), then the #102 rule on the shipped static set. Set `cv$share` and `ins_share` from the shipped method. `fits.rds` and `cv_aet-<AET>.rds` gain `share_method`, `cv_share_methods`, `cv_share_methods_leakfree` and `share_method_rule`. `share_spec` keeps meaning #16's static set. Add a report line (SHARE METHOD) beside SHARES.
- [x] Consumers that assume `cv_share == cv_shares[[share_spec]]`: `data-raw/monthly_vignette_data.R:59`, `vignettes/monthly-flow.Rmd:525`, and the `wet_balance` description in `scripts/discharge_publish.R:306` (it names the snow regression). Each checks against `share_method` and states the shipped method.

## Phase 4: Breakdowns script
- [ ] `scripts/wb_share_donor.R`: reads the cv file and refuses it if it is stale (`score_code_md5`). Reports, without refitting: the rule restated with its outcome; medians by month, zone, freshet gauges (peak May–June), peak in other months, the Liard (WSC area 10), lake outlets, zones 11/17/04, headwater and nested; the leak-free medians; and the short-record test stations with twelve months (`s$test`/`s$test_monthly` via `with_predictors()`, predicted from the calibration gauges outside their sub-sub-drainage, as `wb_pooled_test.R` blocks them). Writes the tracked report `wb_report("wb_share_donor", release)` with no timestamp.

## Phase 5: The stale chain on m4 (a worktree of the branch, `data/` symlinked; logs in `data/logs/102/`, moved to the main checkout before the worktree is removed)
- [ ] Rescore all ten AET variants (`wb_validate.R <v>`), run `wb_aet_compare.R`, then `wb_validate.R <winner>`.
- [ ] `wb_share_snow.R`, `wb_share_donor.R` and `wb_shape_daily.R` (refits #70's shape on the shipped months; m4 lacks `shape_daily.rds` today, so this run creates it there).
- [ ] `wb_output.R`, then `segment_output.R` (`WET_FWAPG_COMMIT=7c30f58`), then `discharge_publish.R` BUILD; commit the reports.
- [ ] Copy the reduced bundle back to m1 (fits.rds, cv_aet-cfu.rds, aet_winner.txt, shape files, output month 0).
- [ ] **If the regression stays:** outputs and parts should be byte-identical, so no upload is needed. Confirm with the BUILD's identical count.
- [ ] **If a candidate ships:** the upload is the user's step (auto mode refuses a production write). I hand over the bare command and continue on Phase 6's text while it runs.

## Phase 6: Docs and articles
- [ ] `research/water_balance_method.md`: a new section, "Monthly shares from donor gauges (#102)", covering the rule, the result, the breakdowns and the leak test. Update the #70 bullet that points here, and the follow-ups.
- [ ] After the upload (only if something ships): rerun `data-raw/monthly_vignette_data.R` and rewrite the monthly article's balance scores and freshet sentence. Rerun `data-raw/segment_vignette_data.R` if its guards require it. README only if it states the share method.
- [ ] CLAUDE.md: the `wb_validate.R` paragraph names the #102 rule and `share_method`; add `wb_share_donor.R` to the pipeline list.

## Owed at the end (reported, done after merge)
- [ ] m4: remove the worktree after moving `data/logs/102/` into the main checkout; update the m4 and m1 memories (fit md5, live build).
- [ ] #99's body: the daily decision it now owns (the donor's free curve against #70's shape on the new months), with the numbers from the rerun.

## Validation
- [ ] Tests pass (`devtools::test()`), and `R CMD check` passes on CI.
- [ ] `/code-check branch`, three rounds minimum.
- [ ] PWF checkboxes match the landed work.
- [ ] `/planning-archive`, then `/gh-pr-push`.

**How each change is proved:** the rule's commit precedes the first commit of candidate code (git log). The regression path is `identical()` to before (test). The `wet_shape_predict()` refactor is `identical()` (test). Under symmetric leak-free pools, the regression's blocked-CV median equals the #16 number in the existing report (0.8735) to 1e-9, which checks the scorer before anything is decided. The `wb_validate.R` reports and `wb_aet_compare.R` are reproducible. If nothing ships, BUILD is 67/67 identical to live 94deeb5. If a candidate ships, BUILD's value checks pass and the monthly vignette data's guards accept the uploaded build.

