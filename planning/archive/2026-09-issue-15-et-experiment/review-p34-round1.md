# Review p34, round 1 (staged diff: wet_wb_raw, wb_cv_lib, wb_validate, wb_output, wb_province, wb_aet_compare)

## Findings

- **[fragile]** scripts/wb_aet_compare.R:51-57 — the `cv_aet-<v>.rds` files are keyed only on the province run directory, not on the scoring code. The compare script checks just `identical(station_number)`. If `scripts/wb_cv_lib.R`, `scripts/wb_validate.R` or `R/wet_wb_fit.R`/`wet_wb_adjust.R` change after some variants were scored and before others, the rule (a)-(c) and the nested selection (d) silently mix variants scored under different procedures. The nested loop recomputes from `res[[v]]$raw` (P - AET only), so (d) is unaffected, but the top table and `keep_adjust` per variant are not. Cheap fix: store `tools::md5sum()` of the lib, wb_validate.R and the R/ fit files in each rds, and stop in the compare script unless they are equal across variants.

No bugs found. Checked and probed:

1. **Leakage in (d): none.** Per outer fold, `d <- cal[tr, ]` and `d$raw <- res[[v]]$raw[tr]`. `raw` is P - AET with no obs. `choose_variant()`, the keep/gate test (`metrics()` on the inner CV of the training stations, folds = `d$fold`, meaning the remaining outer folds), `decide()` and `wet_wb_fit(d[tr, ], pooled_adjust = pv)` all see training rows only. `wet_wb_fit` computes `pooled` from its own `d`. The global `pooled`, `unseen` and `cal$zone` use zone shares only. The folds are `substr(station_number, 1, 4)` (wet_cv_folds), the same blocking `choose_variant` uses inside.
2. **`decide()` matches the rule text exactly.** (a) `hw <= cg$hw - 2.0`; (b) `all <= cg$all`; (c) `nes_mae <= cg + 1.0` and `nes_in20 >= cg - 3`; eligible = lc, tc, fu, cfu (fu15/20/35 excluded); lowest hw wins, and `which.min` breaks a tie by row order, which the rule leaves open. (d) `nested hw < cgiar as-shipped hw`, applied to the top-level winner. (Not a bug: cgiar's as-shipped baseline carries its own gate-selection optimism, while the nested figure does not, so (d) errs toward "cgiar stays".)
3. **`metrics()` vs `wet_flow_validate()` are consistent on this data.** Both use min_obs 10 with `>=` kept, in20 `<=`, and `nesting` in {headwater 218, nested 72, NA 0}, so `!hw` == "nested". No calibration station has obs < 10. On a copy of the script, with the old run's real `cv_aet-cgiar.rds` and four synthetic variants built through `predict_cv`, the headwater guard passed for every variant, `res$cgiar$raw` is identical to `cal$ro_raw`, and the nested loop ran to completion (about 6.7 min for 5 candidates × 93 outer folds). The guard compares only hw, but all, nes_mae and nes_in20 come from the same formula.
4. **wb_province.R.** A terra probe confirmed:
   - `sum(is.na(lay)) > 0` then `mask` gives the #11 layers NA exactly where `bad`, and the multi-layer `is.na(lay) != bad` recycles `bad` per layer, zone included.
   - `cover()` fills only on `!bad`, because `aet_yr`/`p_yr` are NA on `bad`.
   - `max(r1, r2)` is cellwise (NaN where an input is NA, which `is.na` catches).
   - `init(x, "y")` gives latitude.
   - `ex[["aet_tc"]] <- ...` keeps the names.

   Hargreaves and Budyko clamp their inputs at 0 (`wet_pos`, with the acos argument clamped), so they return NA only where Tmax/Tmin are NA. The assertion then fails loudly rather than letting a layer through with holes. No new layer name matches `^zp?[0-9]+$`. `wet_share_fit` builds `ppt_/tave_/aet_%02d` explicitly, so `ppt_tc`/`aet_tc` cannot enter it. The `wet_aet_landcover` domain (`maskvalues = c(NA, 0)` on `inbc >= 0.5`) and the masked `aet_yr` give the plan's denominators.
5. **wb_output/wb_validate.** `fits.rds` is written only when `aet_v == ship_aet`, and it records `aet`. `wb_output` reads `fits$aet` for both the parquet raw and the grid (`wet_wb_raw` works on a SpatRaster, as the test shows). A new run key means a new directory, so no stale fits carry across. (Side note: the old run's `data/wb/5c2feaefad/fits.rds` already carries `aet`, because the verification run of the new wb_validate.R overwrote it. That is harmless, since the report reproduced.)

Probe artifact, not a bug: the detail section errors when a variant's upstream column is absent (`data.frame(..., greata_aet = NULL)`). That only happened because the old run has no `aet_lc` and the other new columns. A real #15 run has them.
