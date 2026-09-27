# Review: #11 staged diff, round 4 (nested pooled-variant selection)

Reviewer: subagent, read-only on the repo. Probes ran in a scratch copy of the index (`git checkout-index`), with `data/wb/stations.rds`, `upstream/`, `layers.tif` and `in_bc.tif` symlinked and `fits.rds` / reports written to scratch.

## Reproducibility and mechanics (checked clean)

- **`data/checks/wb_validation.txt` reproduces byte for byte** from the staged `scripts/wb_validate.R`. The run took 3 min 45 s. `fits.rds` is byte-identical (`cmp`).
- **Run key.** `wet_wb_fit.R` is not in the province hash, and does not need to be, since it is used only downstream of `upstream/`. The key stays `5c2feaefad`.
- **Timestamps.**
  - `wb_validation.txt` and `fits.rds` (19:42:44) were written after `wb_validate.R` (19:38:57) and `R/wet_wb_fit.R` (19:34:25).
  - `wb_output.txt` and `runoff_annual.tif` (19:44:28) were written after `fits.rds`.
  - The PNG (19:44:50) was written after `wb_map.R` (19:42:57).
  - `wb_province_run.txt` is identical to `data/wb/province_run.log`.
- **Tests.** `NOT_CRAN=true devtools::test(filter = "wb_fit|flow_validate|cv_folds|share_fit|upstream_means|ws_sample|climr_normals")` gives FAIL 0, PASS 104.
- **Nested selection is free of the outer held-out rows.**
  - `predict_cv()` calls `choose_variant(d[tr, ])`. The inner folds are `substr(station_number, 1, 4)` of those training rows only.
  - `cv_annual()` fits `wet_wb_fit(d[tr, ], ...)` with `pooled = NULL`, so inner pooling also comes from inner-training rows.
  - The only globals used are the constants `variants` and `mae`.
  - The script-level `pooled <- wet_wb_pooled(cal)` is used only in the report text.
  - For the LOO outer loop (290 folds), the inner CV is blocked over the other 289 stations; all 290 chose `"none"` (probe).
  - Outer blocked folds equal the inner blocking unit (sub-sub-drainage), so a held-out block is never split across inner training.
- **The gate compares like with like.** `hw(cv_v)` against `hw(raw_v)` covers the same 218 headwater stations, and both are floored at 0. The nested headline is identical, row for row, to "forced none" (`all.equal` TRUE), which is consistent with 93/93 folds choosing `"none"`.
- **Pooled zones get zero adjustment in every path.**
  - `wb_output.R`: `fits$wb$coef` has a = b = 0 for the 9 pooled zones; `unseen` is empty, and dropped columns contribute nothing. Adjusted annual NA is 22,041, the same as raw NA, so the adjustment introduces no NA.
  - Cell-wise map: `runoff_annual.tif` matches a recomputation from `layers.tif` and `coef` to 5e-4 mm (float32). On all 716,106 cells in pooled zones, the map equals `clamp(ro_raw, 0)` exactly. No cell has `ro_raw` defined with `zone` or `p_yr` NA, so the loop blanks nothing.
- **`wb_map.R`.** It selects the run by `upstream/_complete`. All 290 `fits$calibration` ids are in `stations.rds`. The legend "Calibration gauge" is now correct.
- **Research §0 numbers match the tracked reports.** The skill table, the ±20 % column and the share NSE all match `wb_validation.txt`: 34.7/39.8/19.4, 33.1/38.1/17.9, 32.3/37.8/15.5, 22.6/25.5/13.8, 39.1/46.4/16.9; 47/50/54/58/52; 0.87/0.88/0.88/0.87. The following also match:
  - The major-river ratios 0.86–1.17.
  - Fraser/PCIC 0.93 (2477 / 2656.4).
  - 22,041 NA (0.68 %).
  - <100 km² 58.8 %; >10,000 km² 20.8 %.

## Findings

### 1. [Medium, method/claims] The gate PASS rests on a specification changed after seeing CV. Nesting does not remove that, but the docs say it does.

- `task_plan.md` decision 5 fixes the primary specification "before seeing skill" as pooling into one `"other"` level. It allows selection inside the fold only for *experiments*. Under that specification the gate failed: 46.4 % vs 39.8 % (the "forced other" transparency block).
- The `"none"` candidate was introduced after round 3 inspected held-out results. The inner CV then picks it unanimously (full-data inner MAE: other 39.1 % vs none 33.1 %). So the nested headline equals the post-hoc variant exactly.
- Nesting guards against choosing *among offered candidates* using held-out rows. It cannot undo the choice of candidates, which was made from the outer CV.
- The artefacts contradict each other:
  - `wb_validation.txt` labels the forced-`"none"` block "found after seeing CV; optimistic", and labels a numerically identical block "(headline)" with no caveat.
  - `research/water_balance_method.md:59` says "The nested choice is what makes the variant legitimate to report".
  - `research/water_balance_method.md:56` cites "plan decision 5" as the basis for the choice, but decision 5 fixed the other specification.
- `task_plan.md` decision 5 is not revised to record the deviation.
- The PASS margin is 1.7 pp on 218 stations. Whether a post-hoc variant may flip ship/no-ship is the author's call; round 3 flagged it as such. No record shows it was put to the user.
- **Fix:**
  - State in the report headline label, in research §0 and in the findings that the pre-specified gate failed and that `"none"` is a post-hoc specification.
  - Revise decision 5 in `task_plan.md`.
  - Put ship/no-ship to the user as a decision rather than presenting the nested PASS as a clean test.

### 2. [Low, stale number] Research §0 own-zone figure comes from the retired `"other"` procedure

`research/water_balance_method.md:62` says "Own-zone coefficients help (34.1 % → 30.4 % on headwater stations predicted with their own zone)". The 30.4 % is round 3's probe under the `"other"` variant. Under the shipped nested procedure (probe on the staged script), the figures are:
- Headwater, dominant zone not pooled in its fold: n = 118, raw 34.1 % → CV **30.9 %**.
- Headwater, pooled in its fold: n = 100, raw 46.4 % → CV 46.6 %, which is slightly worse even with zero pooled-zone adjustment.

Neither figure is in any tracked report, so the sentence has no producer. Either add the split to `wb_validation.txt` or cite the corrected number with its source.

### 3. [Low, wrong number] "zones 15, 17, 23, 24 run +100–250 % raw" is false for two of the four zones

`research/water_balance_method.md:64`. The raw mean errors in `wb_validation.txt` are 15 +103.9 %, 17 **+55.8 %**, 23 **+59.1 %** and 24 +234.2 %. The range for these zones is +56 to +234 %.

The adjacent claim "Our in-sample 22.6 % over 29 zones" (line 63) is also loose. The in-sample fit estimates 20 zone levels, and the 9 pooled zones get no adjustment.

### 4. [Low, docs] `wet_wb_fit()` `@return` does not describe `"none"` or the returned field

`R/wet_wb_fit.R:31-33` and `man/wet_wb_fit.Rd:28` say the fit returns `list(coef, pooled, n)` with "pooled zones repeat the pooled coefficients". Two things differ in the code:
- The object also carries `pooled_adjust`.
- Under `"none"` the pooled zones carry a = b = 0, not a shared fitted coefficient.
