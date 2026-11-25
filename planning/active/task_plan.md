# Task: Water temperature at stations with no record: a whole-station holdout of air2stream parameters predicted from catchment traits and the stream network (#213)

## Problem

`wet_temp_fill()` fits air2stream per station from that station's own record. A reach with no
station has no record to fit, so its parameters have to come from something else. Nothing in wet
predicts them yet, and the fill's validation (#40) hid days or seasons, never a whole station.
Even with a station, a hidden season refitted on the rest of the record misses GSDD by about
129 °C-days. This work measures how much worse a station-free estimate is, which sets the bar any
network model has to beat (#214, #217).

Branch `213-water-temperature-at-stations-with-no-re` off `origin/main` (6095690). The issue has
no comments.

## What exploration found (shapes the phases)

- **Truth set exists, cached:** `data/temp_fill/` in the main checkout holds
  `water_2002_2025.rds`, `air_2002_2025.rds`, `truth_years.rds` (999 station-years, 257 stations)
  and `validate_scores.rds`. No new fetch of water or air is needed.
- **Own fits are cheap and already coded:** `wet:::wet_fill_prepare()` gives each station's
  open-loop `a1, a2, a3` (`$open`); `wet:::wet_a2s_run()` runs the model from any parameters
  (`R/wet_temp_fill.R:360`). #40's run prepared 254 stations in about a minute.
- **Only 132 of the 257 truth stations are snapped and accepted** in
  `data/wb/stations_20260717.rds` (the water balance keeps natural long-record gauges). The other
  125 need `wet_station_snap()`, and their upstream means exist only where the full province
  run's `upstream/` is; the reduced bundle holds the 336 accepted watersheds alone.
- **Trait layers in `upstream/`:** `elev`, `e_km`, `n_km`, `snowmelt_doy_50`, `swe_max`,
  `upstream_area_m2`, with `bc_fraction` and `coverage`.
- **Glacier cover is built once already:** `scripts/wb_small_basin.R` (query `q_glacier` on
  `whse_basemapping.fwa_glaciers_poly`, cache `data/wb_small_basin/glacier_ws_<key>.rds`, summed
  upstream with `wet:::wet_fwa_upstream()`). Lake cover is new; the local database has
  `fwa_lakes_poly` and `fwa_manmade_waterbodies_poly`.
- **Folds and the leak-free pool exist:** `wet_cv_folds()` (blocks by WSC sub-sub-drainage,
  `R/wet_cv_folds.R`), `share_related()` and `cv_share_methods(related = )` in
  `scripts/wb_cv_lib.R:205-228`; the donor recipe is `wet:::wet_donor_mean()` (k = 5 for the
  shares).
- **Kriging cannot start yet:** the network check on every watershed group is still open on the
  fwapg fork, and no issue yet places stations on the main-flow tree or keeps an SSN object for a
  basin (#217 says so). SSN2 0.4.0 and the SSNbler fork are installed.
- **Repo patterns to follow:** a rule file with a verdict function and its own test
  (`scripts/wb_small_basin_rule.R`, `tests/testthat/test-wb_small_basin_rule.R`); a `_lib.R`
  tested from `tests/testthat/` with a skip when `scripts/` is absent; another script's
  definitions taken by `parse()`, not copied (#176); a report under `data/checks/` that is
  byte-identical on a rerun; `WET_DATA_ROOT` naming the main checkout's `data/` from a worktree.
- **Stale install:** cd 0.6.11 against 0.6.13. Air is read from the cache, so no cd call is
  planned; it is upgraded anyway so a cache rebuild would run on the current release.

## Decided at the gate

- **Kriging is split out** (the owner, 2026-11-25). #213 keeps the truth set, traits, the
  recovery harness (with its network-correlated part and the leak-free check), the registered
  rule and candidates 1-3. #223 carries candidate 4, scored on this issue's stored holdout
  frame under the rule registered here. #213's and #214's bodies are edited to name it.
- **Rule thresholds** (the owner, 2026-11-25): *close* means the baseline's mean GSDD absolute
  error is within 50 °C-days of the own-parameter benchmark's, half the width of the cutthroat
  band (800 to 900). A trait candidate is reported as the baseline only if it beats the
  population mean by at least 10 °C-days in both pools; otherwise the population mean is.
  Regression wins a tie with the donor mean. The relative gap is printed beside it and decides
  nothing.

Mechanism, decided in the plan (mine, one line of why each):

- **Parameters are predicted as θ = (a1/a3, a2/a3, qlogis(a3))**, the equilibrium intercept, the
  equilibrium slope and the response rate, then turned back. Averaging raw `a1` and `a2` across
  stations with different `a3` does not give any station's equilibrium.
- **The benchmark is the station's own fit on its whole record**, as the issue words it
  ("the same model with the station's own parameters"). #40's hidden-season open-loop score on
  the same station-years is printed beside it as context and decides nothing.
- **The rule's statistic** is the mean over held-out stations of each station's mean absolute
  GSDD error over its truth years: the station is the held-out unit. The station-year mean is
  printed too, since #40's 129 is one.
- **Traits:** `elev`, `e_km`, `n_km`, `snowmelt_doy_50`, `swe_max`, log10 upstream area, glacier
  cover and lake cover (lakes plus manmade waterbodies, since a reservoir is a lake to the
  water), each cover a share of upstream area. Stations under 0.95 `bc_fraction` or `coverage`
  are dropped and counted, as the water balance does.
- **Donor mean uses k = 5**, traits z-scored on the training rows of each fold, as the shares do.
- **Intervals stop at the parameters.** Each candidate gives a predictive mean and sd for θ;
  coverage is scored in the recovery and against the own fits. No interval on GSDD: that is
  #218's and #217's, and the report says so.
- **No new exported function.** Scripts and a tested lib, calling `wet:::` internals, as #40's
  validation does.
- **The holdout frame's handover format is #217's.** Here it is an rds under
  `data/temp_baseline/` plus a tracked text report.

## Phase 1: The rule, registered before anything is scored

- [x] File the kriging issue (candidate 4 on SSN2: what it waits on, that it is scored on this
      issue's frame under this rule, its recovery step), then edit #213's body (candidates 1-3,
      the split named) and #214's item 2.
- [x] Upgrade cd to 0.6.13 (`pak::pak("NewGraphEnvironment/cd")`).
- [x] `scripts/temp_baseline_rule.R`: the constants (close 50 °C-days, displace 10 °C-days,
      both pools, regression on a tie), the statistic, and `tb_verdict()` returning the baseline
      candidate and close / not close from a table of scores by candidate and pool. It also
      covers a fourth candidate arriving later: kriging is scored in both pools and reported
      beside the baseline, never displacing it under this rule.
- [x] `tests/testthat/test-temp_baseline_rule.R`: every arm (displaces in both pools; in one
      pool only; regression and donor tied; at, just inside and just outside 50; a missing pool
      refused), skipped when `scripts/` is absent.
- [x] `scripts/temp_baseline.R` header: the rule in words, the θ transform, the pools, the
      benchmark, what is printed as context. Committed with the rule file; the commit is the
      registration, and its sha is written into the header by the next commit.

## Phase 2: Traits and the holdout frame

- [x] `scripts/temp_baseline_traits.R`, run where the full province run's `upstream/` is, or
      on a bundle cut to the watersheds it lists when it stops: snap the truth stations with
      `wet_station_snap()` (the truth set by `truth_years()` taken from
      `scripts/temp_fill_validate.R` by `parse()`, on the cached water after its air filter: 999
      station-years, 257 stations), and hold those the water balance snapped, test stations
      included, to their rows in `stations_<release>.rds` (146, all on the same segment).
      *Review:* `truth_years.rds` holds 1,006 at 259, before the air filter, so nothing is held
      to it; a stuck sensor (08LG048) and a station outside the pinned HYDAT (07FA008) are
      dropped by rules now in the registered header (Amendment 1).
- [x] Upstream means for each accepted station from `upstream/*.rds`; glacier cover from
      `q_glacier` and its cache key, taken from `scripts/wb_small_basin.R` by `parse()`; lake
      cover from the same query shape on `fwa_lakes_poly` and `fwa_manmade_waterbodies_poly`
      (area computed before any simplify, `ORDER BY` on a unique key), cached under
      `data/temp_baseline/` and keyed on the query and the tables' row counts and areas.
- [x] Folds from `wet_cv_folds()`, the related matrix as `share_related()` builds it, the snap's
      lake-outlet flag. Written to `data/temp_baseline/frame_<key>.rds`. *Review:* the frame also
      carries HYDAT's regulation flag and each station's own fit (the simulation's scale; fitting
      is not a score).
- [x] Report `data/checks/temp_baseline_frame.txt`: stations kept and each one dropped with its
      reason, station-years left, trait ranges, folds, headwater and nested counts, pairs the
      leak-free pool removes. Byte-identical on a rerun from cache.

## Phase 3: Candidates and the recovery run

- [x] `scripts/temp_baseline_lib.R`: the θ transform and its inverse; `tb_predict()` for
      `mean`, `regression` (`lm` per θ) and `donor` (`wet:::wet_donor_mean()`), each returning a
      mean and predictive sd; `tb_cv()` for the blocked folds and the leak-free pool (each
      held-out station predicted from its fold's training stations less those upstream or
      downstream of it, every candidate refitted); `tb_score()` for daily RMSE on observed
      Mar-Nov days of the truth years and GSDD error (`gsdd_year()` taken from
      `scripts/temp_fill_validate.R` by `parse()`).
- [x] `tb_simulate()`: on the real frame's traits and topology, θ from known coefficients, plus
      a network part built as a weighted mean of each station's own and its upstream stations'
      independent draws (so only flow-connected stations are correlated), plus noise.
- [x] `tests/testthat/test-temp_baseline_lib.R`: the transform round trip; each candidate on a
      toy frame with known answers; the leak-free pool leaves no related station in training;
      the simulated network part is correlated only between connected pairs; empty and NA
      inputs.
- [x] `scripts/temp_baseline_recover.R`, fixed seed, 200 simulated parameter sets: bias, RMSE and
      90 % interval coverage per candidate, θ component and pool; the leak-free check (each
      candidate's leak-free error equals, within Monte Carlo error, its error when the held-out
      station's network part alone is replaced by an independent draw of the same variance);
      and the same difference in blocked CV, which is the leak. Then 5 end-to-end sets: daily
      water simulated from the true θ on the stations' real air with an AR(1) departure,
      refitted with `wet:::wet_a2s_fit()`, candidates run on the fitted θ, GSDD error against
      the simulated truth (a run on the true θ has no error against the departure-free series,
      by assertion). *Review:* replacing the network part everywhere, as first planned, also
      removes the correlation among training stations and is wrong for the donor mean; and the
      assertion cannot be against a truth that carries the departure.
- [x] Report `data/checks/temp_baseline_recover.txt` (naming the frame and `tb_code_md5()`, one
      md5 over every file a score depends on; *review:* not the lib and rule alone), log under
      `data/logs/213/`, committed before Phase 4 runs.

## Phase 4: The real scores

- [x] `scripts/temp_baseline.R` refuses unless the recovery report is committed, names the
      current `tb_code_md5()` and the frame, and says its leak-free check passed.
- [x] Own fits from `wet:::wet_fill_prepare()` on each station's whole record; θ per station;
      candidates in both pools; `wet:::wet_a2s_run()` on the predicted parameters over the
      station's own air; scores per station-year, for each candidate, the population mean and
      the own-parameter benchmark.
- [x] Report `data/checks/temp_baseline.txt`: scores by candidate and pool (daily RMSE, GSDD
      mean absolute error by station and by station-year, bias, the absolute and relative gap
      to the benchmark), coverage of the own-fit θ by each candidate's interval, breakdowns by
      WSC sub-drainage, by lake influence (outlet flag, lake cover classes) and by glacier cover
      (none, some) and by HYDAT's regulation flag (*review*), #40's hidden-season score on the
      station-years both scored as context, and the rule's outcome in the rule's
      own words from `tb_verdict()`. Byte-identical on a rerun.
- [x] Scores stored in `data/temp_baseline/scores_<key>.rds`, for the kriging issue to score
      against.

## Phase 5: Write it down

- [x] `research/station_temperature_fill.md`: a section on stations with no record (method, the
      recovery result, scores by candidate and pool, the breakdowns, the rule's outcome, what
      is not done: kriging, GSDD intervals, loggers); header line updated (Verified, Issues,
      Produced by). `research/README.md` row revised if its description no longer fits.
- [x] `CLAUDE.md` (above the marker): the three scripts, the rule file and their reports in the
      gap-fill paragraph.
- [x] `NEWS.md` bullet and `Bump: patch` in the PR body. This repo's `NEWS.md` has no development
      heading: its last four releases wrote the bullet in the release commit, from the PR, so the
      bullet is in the PR body and `NEWS.md` is not edited on the branch.
- [ ] Archive README with `## Measurement` and `## Evidence` (the reports and
      `data/logs/213/` by prefix).

## Owed at the end (reported, done after merge)

- [ ] Move `data/logs/213/` and `data/temp_baseline/` from the worktree into the main checkout
      before the worktree is removed.
- [ ] Tick item 2 of #214's list by hand once the PR is merged.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:

- **The rule came first:** `git log` shows the rule and header commit before the first commit of
  `data/checks/temp_baseline.txt`, and the recovery report's commit between them.
- **The guard fires:** `temp_baseline.R` run with an edited lib (md5 changed) exits non-zero
  before reading any water; restored, it runs.
- **The leak-free pool does what it claims:** the recovery report's check, plus the lib test
  with a planted related station left in training going red.
- **Scores are the model's:** on the end-to-end simulated sets GSDD error is 0 when the true θ
  is given; on real data the benchmark's in-sample daily RMSE equals `rmse_open` from
  `wet_fill_prepare()` when scored over the same days.
- **Reports reproduce:** each of the three reports is byte-identical on a second run from cache
  (`cmp`).
- `devtools::test()`, `lintr::lint_package()` compared per file against `origin/main`,
  `devtools::document()` showing no change.
