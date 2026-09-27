# Review: #11 Phases 3-6 staged diff, round 2

Reviewer: subagent, read-only on the repo. Probes ran in a scratch copy of the index (`git checkout-index`). The staged `scripts/wb_validate.R` was re-run against `data/wb_old/climatena_d73b4ef710`, with every output redirected to scratch. Relevant tests pass: `NOT_CRAN=true devtools::test(filter = "wb_fit|flow_validate|cv_folds|share_fit|upstream_means|ws_sample")` gives FAIL 0, PASS 87.

## Findings

### 1. [Medium] With pooling fixed from locations, blocked CV now fits an "own" zone from almost no information, and zone 07 collapses to 0

`R/wet_wb_fit.R:44-46` sets a coefficient to 0 only when `lm.fit` marks it `NA`, which happens only when the level's columns are exactly zero. Blocked CV keeps zone 07 as its own level (8 dominant gauges overall). Fold `07FB` then holds out 7 of those 8. The training set still has zone-07 columns from one dominant gauge (07EF004) plus 9 stations with partial shares. It fits **a = -3874, b = 2.948**, against the shipped a = 225, b = -0.254.

All 7 held-out predictions go negative and are floored to 0.

| station | obs mm | raw | blocked CV | LOO |
|---|---|---|---|---|
| 07FB001 | 475 | 436 | **0** | 439 |
| 07FB004 | 210 | 227 | **0** | 333 |
| 07FB006 | 755 | 612 | **0** | 518 |

The other four 07FB stations show the same pattern.

With the staged code on the same inputs, zone 07's blocked-CV MAE goes from 25.4 % to **99.6 %**, with median error -100 %, 0 % within 20 %, and `logsd` NA. Meanwhile the "all" MAE *improves*, from 33.6 % to 33.1 %, so the aggregate hides a zone predicting zero runoff. LOO has one zero as well (zone 24).

The fix itself is correct: it now scores the shipped structure, and there is no leakage. What it exposes is that the shipped structure has no fallback when a block removes most of a zone's gauges, and the "no information → 0" guard does not cover near-zero information. The report should surface this at least. The count of held-out predictions floored to 0 per run would do it. Otherwise the CV block reads as healthier than it is. Possible remedies: a minimum dominant-gauge count *in the training fold* before a fixed own level is fitted, which falls back to 0 or to pooled, or shrinkage toward the pooled coefficients. Either is a method choice for the author, not something to patch silently.

### 2. [Medium] The "exactly one run dir" guard in `wb_validate.R` passes on an incomplete province run

`scripts/wb_validate.R:12-14` accepts any single `data/wb/<key>` that contains `layers.tif`. `scripts/wb_province.R:43-67` writes `layers.tif` first, before sampling and before any `upstream/<CODE>.rds`. Nothing marks accumulation as complete.

This is the state right now: `data/wb/eaf922d584` has `layers.tif`, 28 of 246 samples and 0 upstream files. Validate would error at that moment, because `rbind` of an empty list gives NULL. After a run interrupted part-way through accumulation, though, it runs silently on the stations in the basins that exist. That interruption is the resumable case the design aims for. Validate would then write `fits.rds` and the tracked report, and `wb_output.R:25` would write parquet for only those basins.

Related: `wb_output.R:15-17` picks the single dir with `fits.rds` and ignores whether a newer run dir exists. With the new key churn (any edit to three files makes a new key), a new run in progress next to an old fitted one makes output silently regenerate the old run.

Remedy: write a completion marker after `stamp("accumulation done")`, for example `upstream/_complete` holding `length(codes)`. Require it in both scripts, and require that `fits.rds` sits in the only run dir.

### 3. [Low] The tracked artifacts in the index do not match the staged code

- `data/checks/wb_validation.txt` (staged) predates fixes 2 and 5. It has no "pooled zones ... decided from locations" line and still reads "309 accepted snaps with predictors". Re-running the staged `wb_validate.R` on the same run (`climatena_d73b4ef710`) changes:
  - blocked-CV "all" MAE: 33.6 → 33.1
  - gate on headwater stations: 39.2 → 37.1
  - the zone 07/13/10 rows (see finding 1)

  `planning/active/findings.md` quotes the pre-fix 33.6 / 39.2. It marks them superseded for the climr switch, not for the code change.
- `data/checks/climr_eccc.txt` and `data/checks/wb_inputs.txt` were regenerated for `mswx.blend`, but that regeneration is **unstaged** (` M`). The staged `scripts/wb_inputs.R` says mswx.blend while the staged reports are still ClimateNA (49 stations, 8 dropped, versus 57 and 0). `data/checks/wb_output.txt` is untracked.

Stage all of these together after the mswx run, or commit the code without the stale reports.

### 4. [Low, latent] Whether a zone with no calibration data gets the pooled coefficients or no adjustment depends on which basins have stations

The comment at `scripts/wb_output.R:31-32` says: "a zone the fit never saw (no calibration station anywhere in it) gets no adjustment". The fit's zone list, however, is every zone column in any basin file that holds an *accepted* station. `wb_validate.R:28-32` fills missing columns with 0. A zone present there with zero share at every calibration station has 0 dominant gauges, so it is pooled and takes the `"other"` coefficients (pinned by `test-wet_wb_fit.R:35-42`). A zone that only occurs in station-free basins is dropped and gets no adjustment. Two equally unobserved zones are therefore treated differently.

This does not trigger in the ClimateNA run: every fitted zone is touched by at least 4 calibration stations, and `zones_unfitted` = 0 in every basin. It can trigger once the mswx run covers new ground. Remedy: in `wb_validate.R`, drop zone columns whose share sums to 0 over `cal` before fitting, so the output's "drop unknown zones" rule covers them. Alternatively, correct the comment and accept the pooled treatment explicitly.

### 5. [Low] The run key covers only three code files, and its comment overclaims

`scripts/wb_province.R:33-35` says "a code change never reuses old samples". It hashes `wb_province.R`, `R/wet_ws_sample.R` and `R/wet_upstream_means.R`. It does not hash `wet_ws_geom()` (sampling polygons), `wet_upstream_sums()`, `wet_upstream_irregular()` or `wet_ws_fetch()` (accumulation). A change to any of those reuses cached `sample/` and `upstream/` files under the same key. Either hash those files too, or narrow the comment.

### 6. [Low, latent] Exported `wet_wb_pooled()` counts an all-NA row toward the first zone

`R/wet_wb_fit.R:91-93` sets NA shares to 0, then `max.col(..., ties.method = "first")`. A station with coverage 0 (all shares NA; 9 of the 309 accepted snaps here) therefore counts as a dominant gauge of `zc$zone[1]`, which can un-pool that zone. `wb_validate.R` passes `cal` (coverage ≥ 0.95), so it does not trigger there. A direct caller passing accepted stations would hit it. Drop rows with no finite share before counting.

## Fixes verified clean

- **No y leakage from pooling.** `wet_wb_pooled()` reads only the `z<k>` shares, which are geometry and climate. `cal` membership depends on `obs` being present, not on its value.
- **A zone in `pooled` but absent from a fold.** An absent column is removed by `intersect(pooled, zc$zone)` (`wet_wb_fit.R:39`). A present but all-zero column makes `a_other`/`b_other` zero, so `lm.fit` gives NA and the coefficient becomes 0 (test at lines 43-46). An own zone emptied in a fold behaves the same way.
- **`wet_wb_adjust()` with no zone columns** returns the floored `raw` (test at lines 64-65).
- **The cell-wise map in `wb_output.R:92-103` matches the per-watershed application.** Pooled zones repeat the `"other"` row in `coef`, so looping per zone equals `a_other * sum(z) + b_other * sum(zp)`. Zones not in the fit get nothing in either path. `zone` is NA only where `layers.tif` is already fully masked. Zone codes round-trip (`"08"` becomes 8, `sprintf("z%02d")`). The only difference is the floor, which is applied per cell for the map and per watershed for the output, as designed.
- **Discharge units.** `mm * area_m2 / 1000 / (days * 86400)`. `mm` is n×13. `area` (length n) recycles down the columns and `rep(days, each = n)` matches the column-major order, so month 0 uses 365.25 and the months use `wet_month_days()`, which sums to 365.25. The same days are used on the observed side (`wb_validate.R:41-44`). `watershed_feature_id` and `month` reps align with `as.vector(mm)`.
- **HYDAT mouth means.** Every one of the 7 mouths has exactly 30 full months for each calendar month in 1981-2010, so the unweighted `AVG(MONTHLY_MEAN)` has no seasonal-gap bias.
- **`wet_flow_validate()`.** A missing `mod` is excluded from `n` and the means and counted in `n_no_mod`. `n_low` excludes those stations.
- **Report line.** It now counts `coverage > 0`, and reproduces 300.
- **`wet_climr_anomaly_mean()`.** The literal prefix strip is correct for `mswx.blend`, and it refuses layers from a different dataset. The cached filename carries the dataset, so the old ClimateNA normal is not reused, and the province key changes through `basename(f_in)`.
- **`on.exit` is gone** from the top level of `wb_province.R`, and the log-path comment is fixed.
