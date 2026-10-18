# Task: Sub-monthly flow per segment: a daily climatology for both sources, with weeks and windows derived from it (#70)

**If we do it:** a segment's flow can be read for any date range, such as a week or a species window like Chinook fry migration (Jul 15 – Sep 7), without estimating it from monthly means. The monthly-flow article (#65) measured that estimate at up to 27 % off the gauge's daily record. **If we never do:** every weekly or window question rests on monthly means, and the balance's flattened freshet (#16) cannot be seen below the month.

Decided at the plan gate (2026-10-17): this branch builds and scores the balance's **within-month** daily shape (each calendar month of days averages to the published monthly mean flow), on a **365-day common year** (29 Feb folded into 28 Feb), and stores it with the shipped fit. Publishing `segment_daily` for both sources is a follow-up issue (fwapg#25 is open). The issue's free day-of-year curve is measured and reported, deciding nothing.

Product: `q[d] = Q[m(d)] * n[m(d)] * w[d]`, `d = 1..365`, `n` the common-year day count, `sum_{d in m} w[d] = 1`. Candidates for `w`: `flat` (incumbent), `spline`, `donor` (k = 5), `basis` (6 components; static predictors + the 12 monthly shares). Rule: median per-gauge NSE of the 365-day shape with **observed** months, best candidate ships if it beats `flat` by >= 0.01.

## Phase 1: The rule, committed before anything else
- [x] `scripts/wb_shape_daily.R` header only (no body that runs): the product formula, the four candidates with every fixed setting, the sensitivity settings and their no-ship clause, the decision metric and why observed months, the 0.01 margin, the gauge filter and its vacuity, the leak sensitivity, the reported-only items, and the artifacts it will write
- [x] `planning/active/findings.md` records the commit SHA as the registration

## Phase 2: Observed day-of-year climatology at the gauges
- [x] `R/wet_doy_month.R`: internal `wet_doy_month()` → integer month of each day 1–365 of a common year, and `wet_doy_days()` → `n` (the common-year day count; **not** beside `wet_month_days()` in the hashed `wet_mm_to_m3s.R`)
- [x] `R/wet_station_doy.R`: exported `wet_station_doy(stations, hydat = wet_hydat_path(), years = attr(stations, "years"), min_days = 20)` → `data.frame(station_number, doy, q_m3s, share, n_years)`, doy 1–365; `years` a named list so a stations table without the attribute works; same `DLY_FLOWS` query as `wet_station_monthly()`, dates built with `as.Date(optional = TRUE)` as `wet_hydat_daily()` does so Feb 30 / Apr 31 drop by date; 29 Feb averaged into 28 Feb in leap years; `share = q / sum(q)` (NA when Σq = 0); the `min_days` guard kept
- [x] `tests/testthat/test-wet_station_doy.R`: offline `local_hydat()` fixture (365 rows per station, shares sum to 1, doy shares step by month); a leap fold with a **distinct** Feb 29 value (the fixture's flow = month number would pass trivially); missing years refused; empty input; `years` passed explicitly equals the attribute path; pinned live check (`local_hydat_pinned()`, `skip_on_ci`) that month-aggregated doy flow equals `wet_station_monthly()` at a few stations, with February's tolerance stated numerically (28 vs 29 days: ≤ 1/29 relative)
- [x] roxygen example (`\dontrun{}`, HYDAT is external, as the other station functions); `devtools::document()`; `_pkgdown.yml` beside `wet_station_monthly`

## Phase 3: Within-month shape candidates
- [x] `R/wet_shape_within.R`: internal `wet_shape_within(doy_share)` → 365 within-month weights per gauge (all-zero month → flat, flagged)
- [x] `R/wet_shape_fit.R`: exported `wet_shape_fit(d, w, method = c("donor", "basis"), static, k = 5, n_comp = 6, shares = NULL)` → class `wet_shape_fit` (donor table + training SDs, or basis + coefficients + centre + SDs); NA predictors refused
- [x] `R/wet_shape_predict.R`: exported `wet_shape_predict(fit, d, shares = NULL)` → n×365 `w` (each month sums to 1); `wet_shape_flat(n)` and `wet_shape_spline(q_month)` exported with the same output shape; `wet_shape_daily(q_month, w)` → n×365 daily flow `q = Q[m] · n[m] · w`, the one place the constraint is applied
- [x] `tests/testthat/test-wet_shape.R`: every candidate's months sum to 1; `tapply(wet_shape_daily(Q, w)[i, ], wet_doy_month(), mean) == Q[i, ]` to 1e-12 for each candidate; `spline` preserves monthly means, is continuous across Dec→Jan, and its negative / non-convergence fallback is exercised; `donor` with `k = 1` returns the nearest gauge, an identical predictor row returns the gauge itself, `k > n_train` capped; `basis` on a rank-6 synthetic set reconstructs it, and an all-≤0 month falls back to flat; `wet_flow_window()` over one calendar month of `wet_shape_daily()` output equals the monthly path
- [x] Examples, `document()`, `_pkgdown.yml`

## Phase 4: The run
- [x] `scripts/wb_shape_daily.R` body: sources `scripts/wb_cv_lib.R` for `cal`/`folds`; refuses `cvr$code_md5 != score_code_md5` (as `wb_share_snow.R:38`), `fits$code_md5 != cvr$code_md5`, `fits$share_spec != cvr$share_spec`, `cal$station_number != cvr$station_number`; recomputes complete years with `wet_station_select(wb_hydat(release), years = s$years, min_years = 10)` and asserts `n_years` equals the stations rds for all 315; `wet_station_doy()` → 365 rows per gauge asserted
- [x] Per fold: `donor` and `basis` fitted on training gauges, `w` predicted for held-out gauges; `spline` from `cv_share`-derived and from observed monthly means; `flat`; the identity `tapply(q, m, mean) == Q` asserted for every candidate; scores as registered; leak sensitivity; free donor curve; Chinook table (`wet_window_stats()` on `wet_station_daily()` for the gauge record, as the vignette)
- [x] Writes `<fit>/shape_daily.rds` (the shipped candidate fitted on all 315 gauges, or `method = "flat"`; stamped with `fits$code_md5`, `release`, and `shape_code_md5` = md5 of `scripts/wb_shape_daily.R`, `R/wet_shape_*.R`, `R/wet_station_doy.R`, `R/wet_doy_month.R`), `<fit>/cv_shape_daily.rds` (per-gauge held-out `w` per candidate, observed doy shares, NSEs, leak flags) and the tracked report `data/checks/wb_shape_daily_<release>.txt`, with no timestamps so a rerun reproduces it byte for byte
- [x] Run on m1; commit report + `progress.md`; `findings.md` records the outcome, the breakdowns and the free-curve numbers (the issue's proposal, measured). The rule is not edited after Phase 1; a bug fix after a run is recorded as such with the rerun

## Phase 5: Record and hand-off
- [x] `research/water_balance_method.md` §0: subsection "Daily shape within the month (#70)" — rule and its registration commit, candidates, outcome, leak sensitivity, Chinook windows, the free curve's numbers, what did not help; header `Verified`/`Issues` line updated
- [x] `research/discharge_publish.md`: the decided stored form of `segment_daily` (365-day common-year climatology per segment and source, flow units, months consistent by construction for the balance; weeks and windows derived on read; 29 Feb folded; fwapg#25's 366 folded on read) — decided, nothing described as published
- [x] CLAUDE.md Architecture: one sentence for `wet_station_doy()` → `wet_shape_*` → `scripts/wb_shape_daily.R` → `<fit>/shape_daily.rds` and the report; NEWS.md entry (written by `/gh-pr-merge`'s release bookkeeping, as every release here)
- [x] File the follow-up issue #99 (publish `segment_daily` for both sources: fwapg#25 dependency and its clamped-row count, the 366→365 fold, crate `segment_daily.yaml`, `segment_output.R`/`discharge_publish.R` for a daily dataset, readers over `doy` in `wet_segment_*`, `wet_db_load()`, `wet_values_compare()`, m4 run and size); edit #70's body to say what this branch did and point to it
- [x] `vignettes/monthly-flow.Rmd:689` ("once daily flow is published (#70)") re-pointed to the follow-up

## Validation

- [x] Tests pass (1206 pass, 0 fail, 0 skip, 2026-10-17) (`Rscript -e 'devtools::test()' 2>&1 | grep -E "(FAIL|ERROR|PASS)" | tail -5`)
- [x] `lintr::lint_package()` clean on new files (one `commented_code` lint on a prose line of the registered header, left as registered); `pkgdown::check_pkgdown()` clean
- [x] `/code-check branch`: three rounds, round 3 found defects inside round 2's fix, ended by enumerating every prose number against the report (findings.md)
- [x] The shipped fit is not staled (every hashed file identical to main; `wb_share_snow.R` reran and its report is unchanged): `git diff main -- $(Rscript -e 'source("scripts/wb_fit_lib.R"); source("scripts/wb_score_md5.R"); cat(score_files_for("20260717"))')` is empty, and `wb_share_snow.R` still runs
- [x] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion; archive README carries Measurement (median NSEs per candidate, the Chinook window errors) and Evidence (`data/checks/wb_shape_daily_20260717.txt`)
