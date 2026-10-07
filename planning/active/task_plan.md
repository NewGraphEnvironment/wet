# Task: Refit the open water balance on HYDAT 2026-07-17, and settle the pooled-zone adjustment (#43)

## Problem

- The open water balance (#11, #15) is fit on HYDAT 2025-10-14. ECCC no longer lists that release. The newest release is 2026-07-17, and tidyhydat's default copy on m1 already is that one.
- `wet_hydat_path()` resolves to tidyhydat's default directory. So a plain `scripts/wb_stations.R` run would quietly fit on whichever release that directory holds.
- Zones with fewer than 8 dominant gauges are pooled. The pre-set specification gave them one fitted level and failed the gate. The "none" variant that passes was offered after that result (`research/water_balance_method.md` §0, "Pooled zones, and an open decision"). Every skill figure since carries the caveat.

## Context

#43: refit the open water balance on HYDAT 2026-07-17 (fit is on 2025-10-14, no longer listed by ECCC) and settle the pooled-zone adjustment. Decided at this gate (2026-10-06):
- **Window stays 1981–2010.** The new release only revises data inside it, so the refit buys a fit rebuildable from a public release, plus the code to hold several fits side by side (which #44 and #45 need). The issue body's "gains the years and gauges added since" is wrong and gets corrected.
- **Pooled zones are judged on fresh gauges:** natural gauges with 1–9 complete years, never used by the fit, under a rule written before scoring.
- **Acceptance:** the refit ships unless headwater held-out MAE is more than 1.0 point worse than the 2025-10-14 fit on the gauges common to both.

### What exploration found (shapes the plan)

- **A HYDAT change does not change the run key** (`scripts/wb_province.R:39-59` hashes input rasters and code only), so `wb_inputs.R` and `wb_province.R` do not re-run. The chain is `wb_stations.R` → `wb_validate.R` → `wb_output.R` → `wb_map.R` → `data-raw/segment_vignette_*`. About 4 min per validate, 2 min output.
- **One fit per key today.**
  - `data/wb/stations.rds` (outside the key dir) and the key dir's `fits.rds`, `cv_aet-*.rds`, `aet_winner.txt`, `output/` and `runoff_annual.tif` are overwritten in place.
  - `score_code_md5` (`scripts/wb_score_md5.R`) hashes `stations.rds` and the scoring scripts. A new station set therefore stales every fit, and `wb_validate.R:22-26` then writes no `fits.rds`.
  - `wb_aet_compare.R` stops unless it reproduces #15 exactly, so it cannot re-pick AET on a new release.
- **HYDAT path:** `wet_hydat_path()` (`R/wet_station_select.R:58`) is tidyhydat's default. On m4 that is 2025-10-14 (the fit's); on m1 it is 2026-07-17. `WET_HYDAT` exists only in the station-flow scripts. `wb_stations.R:25` and `wb_output.R:79` read HYDAT.
- **Pooled zones:** `wet_wb_fit(pooled_adjust = c("other", "none"))` with `min_gauges = 8` (`R/wet_wb_fit.R:36`). The variant is chosen by inner blocked CV (`scripts/wb_cv_lib.R:72-88`). `keep_adjust` comes from the headwater gate (`wb_validate.R:60`).
- **Test pool:** 137 natural stations with 1–9 complete years in 1981–2010 (`data/checks/stations_wb.txt`). `wb_stations.R` already computes them (`loose`), but does not snap or keep them.
- **m4:** 16 cores and 128 GB, with the full run `962a9cc2c4` (3.6 GB) and both releases (tidyhydat default = 2025-10-14, `data/hydat/20260717/`). Its checkout is clean but 48 commits behind, and the installed wet is 0.0.0.9000. fwapg (for snapping) needs checking there.

## Phase 1: Pre-register and correct the issue

- [ ] `findings.md`, committed before any run:
  - **Acceptance rule:** headwater blocked-CV MAE of the 2026-07-17 fit against the 2025-10-14 fit on common calibration gauges; ship unless worse by more than 1.0 point.
  - **Pooled-zone rule:** fit "other", "none" and the nested choice on all calibration gauges and predict the 1–9-year test gauges. The variant with the lower test-gauge MAE ships. A tie within 1.0 point keeps the shipped nested choice. The test-gauge MAE is reported as the out-of-sample figure, and the caveat goes if the shipped variant wins or ties.
  - **AET:** cfu is carried from the 2025-10-14 fit; AET is not re-picked.
- [ ] Edit #43's body: no new years (window fixed), the caveat settled by fresh gauges, both rules.

## Phase 2: Fits keyed by HYDAT release

- [ ] Pin HYDAT: `WET_HYDAT` (path to `Hydat.sqlite3`) in `wb_stations.R` and `wb_output.R`. The release date from its `VERSION` table names the fit, and there is no silent default.
- [ ] **Layout:** `data/wb/stations_<YYYYMMDD>.rds`, and `data/wb/<key>/fit_<YYYYMMDD>/` holding `fits.rds`, `cv_aet-*.rds`, `aet_winner.txt`, `output/` and `runoff_annual.tif`. A committed default release in `wb_cv_lib.R` (`WET_HYDAT_RELEASE`) picks the shipped fit.
- [ ] **Readers updated:** `wb_score_md5.R`, `wb_cv_lib.R`, `wb_validate.R`, `wb_aet_compare.R`, `wb_output.R`, `wb_map.R`, `data-raw/segment_vignette_{data,map}.R`.
- [ ] **AET carry:** `wb_validate.R` takes the winner from a named reference fit when the fit has no `aet_winner.txt` of its own, and records the source.
- [ ] **Test set:** `wb_stations.R` also snaps and saves the 1–9-year natural stations (`$test`), with their annual observed runoff, and reports them.
- [ ] **New script `scripts/wb_pooled_test.R`:** applies the Phase 1 rule and writes `data/checks/wb_pooled_test.txt`.
- [ ] Tests for any new package-level helper; `/code-check`; commit.

## Phase 3: The 2025-10-14 fit under the new layout (regression proof, on m4)

- [ ] **m4:** check out the branch, install, confirm fwapg is up. Copy (not move) the existing fit files into `fit_20251014/` and keep the originals until verified.
- [ ] Re-run `wb_stations.R` (2025-10-14), `wb_validate.R` for every AET variant, then `wb_aet_compare.R`. It must reproduce #15 exactly, and `fits.rds` and the held-out errors must match the original byte for byte, or the restructure changed something.
- [ ] Commit the tracked checks.

## Phase 4: The 2026-07-17 fit (on m4)

- [ ] `wb_stations.R` on `data/hydat/20260717/`: report gauges added, dropped and changed.
- [ ] `wb_validate.R cfu` with AET carried. Apply the acceptance rule; record the outcome in `findings.md`.
- [ ] `wb_pooled_test.R`: apply the pooled-zone rule; record the outcome.
- [ ] If accepted: `wb_output.R`, `wb_map.R`, and switch the default release to 20260717. If not: keep the 2025-10-14 default and report why.

## Phase 5: Ship and record

- [ ] Copy the reduced bundle for the shipped fit to m1, as for #28.
- [ ] Rebuild `data-raw/segment_vignette_data.R` on m1, after PR #42 merges.
- [ ] Re-render the vignette and check its guards hold.
- [ ] Update `research/water_balance_method.md` §0 (both fits, test-gauge result, caveat status) and CLAUDE.md's HYDAT paragraph (fits by release, `WET_HYDAT`).
- [ ] NEWS line.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] Phase 3 reproduces the 2025-10-14 fit exactly
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion, then `/gh-pr-push`

### Critical files

`scripts/wb_stations.R`, `wb_cv_lib.R`, `wb_score_md5.R`, `wb_validate.R`, `wb_aet_compare.R`, `wb_output.R`, `wb_map.R`, new `wb_pooled_test.R`, `data-raw/segment_vignette_{data,map}.R`, `R/wet_station_select.R` (`wet_hydat_path`), `research/water_balance_method.md`, `CLAUDE.md`. Reused: `wet_station_select(min_years =)`, `wet_station_snap()`, `wet_station_monthly()`, `wet_wb_fit(pooled_adjust =)`, `wet_wb_pooled()`, `predict_cv()` and `choose_variant()` in `wb_cv_lib.R`.

Branch: `43-refit-the-open-water-balance-on-hydat-20`. Runs on m4 over ssh with `caffeinate -i` and teed logs; results are committed from m4 and pulled here.
