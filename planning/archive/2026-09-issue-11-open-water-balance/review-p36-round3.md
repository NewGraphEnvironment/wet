# Review: #11 Phases 3-7 staged diff, round 3

Reviewer: subagent, read-only on the repo. Probes ran in a scratch copy of the index (`git checkout-index`). That copy symlinked `data/wb/5c2feaefad/upstream` and `data/wb/stations.rds`, so `fits.rds` and the report were written to scratch.

## Reproducibility (checked first)

- **Working tree equals index** for every file under review (`git diff --stat` is empty). The only unstaged changes are `planning/active/task_plan.md`, `research/README.md` and `research/water_balance_method.md` (finding 3).
- **Run key.** Recomputed from the staged `wb_province.R` plus the five R files and the four input names, it is `5c2feaefad`, which is the run on disk. Every hashed file's mtime predates the run's 19:13:19 start. `wet_ws_geom()` and `wet_upstream_irregular()` live in `R/wet_ws_fetch.R`, so they are covered.
- **`data/checks/wb_validation.txt` reproduces byte for byte.** The staged `scripts/wb_validate.R` was re-run on `5c2feaefad` and `diff` shows no difference. `fits.rds` is also byte-identical (`cmp`).
- `wb_output.txt` (19:25:11), `wb_province_run.txt` (the same 1238 bytes as `province_run.log`) and the PNG (19:27, after `wb_map.R` at 19:26:45) were each written after their producing script was last edited.
- `climr_eccc.txt` and `wb_inputs.txt` (19:02) come after `wb_inputs.R` (19:00:44) and after the `wet_climr_normals.R` edit (19:01:04). The climr tif was written at 19:02:21.
- Tests: `NOT_CRAN=true devtools::test(filter = "wb_fit|flow_validate|cv_folds|share_fit|upstream_means|ws_sample|climr_normals")` gives FAIL 0, PASS 100.

## Findings

### 1. [Medium, method] The gate FAIL is caused by the catch-all pooled `"other"` level, not by the zone adjustment. The research conclusion drawn from it is overstated.

I found no code bug behind the FAIL, and the specific worries do not hold:
- `cal$zone` is defined (line 59) before `merge()` (line 70) and carries through it.
- `was_pooled` reads the dominant zone.
- The gate compares the same 290 stations and the same 218 headwater stations, both floored.
- `ins_fit$n` = 290 (no rows dropped by `complete.cases`).
- `wet_wb_pooled(cal)` is identical to `ins_fit$pooled`.
- `unseen` is empty in this run.
- The z shares sum to 1 at every calibration station, and the zp columns sum to `p_yr` (max abs diff 5e-13).
- `ro_raw` = `p_yr - aet_yr` (3e-5).

The FAIL is real for the procedure as specified. Its cause is one design element, though.

Decomposition of the blocked-CV headwater stations (the gate population), scratch probe on the staged code:

| headwater, held out with | n | raw MAE | blocked-CV MAE |
|---|---|---|---|
| own-zone coefficients in the fold | 118 | 34.1 % | **30.4 %** (adjustment helps) |
| the pooled `"other"` coefficients | 100 | 46.4 % | **65.4 %** (adjustment hurts) |

The `"other"` level fits a large positive intercept in almost every fold: a ≈ +150 to +188 mm with b ≈ -0.1 (the shipped fit has a = 167.7, b = -0.096). Zones 17, 06 and 04 are dry, with obs of 20-140 mm. Their stations get about +100 to +150 mm on top of a raw that already over-predicts. The seven largest headwater degradations are all such stations:

| station | zone | obs mm | CV mm | error change (pp) |
|---|---|---|---|---|
| 08LF081 | 17 | 20 | 175 | +717 |
| 08LF084 | 17 | 88 | 254 | +148 |
| 07FD001 | 06 | 86 | 234 | +135 |
| 08LG056 | 17 | 55 | 144 | +119 |
| 07FC003 | 06 | 90 | 206 | +117 |
| 08LG066 | 17 | 62 | 172 | +100 |
| 10CD003 | 04 | 139 | 291 | +90 |

08LF081 alone is worth 3.3 pp of the 6.6 pp gap.

The same happens **in-sample**, so it is not a CV artefact. The shipped fit makes zone 06 go from 23.9 % raw to 143.9 %, and zone 17 from 55.8 % to 353.9 % (`wb_validation.txt`). Zeroing the pooled level in the in-sample fit improves headwater MAE from 32.2 % to 25.3 %.

Sensitivity, blocked CV (all / headwater MAE %; raw is 34.7 / 39.8):

| variant | all | headwater |
|---|---|---|
| as staged (pooling per fold) | 39.1 | 46.4 → FAIL |
| pooling fixed from all locations | 38.9 | 44.8 → FAIL |
| one global level (every zone pooled) | 39.1 | 45.9 → FAIL |
| `min_gauges` 12 / 16 | 35.7 / 35.5 | 41.7 / 41.3 → FAIL |
| **pooled zones get no adjustment (coef 0), per fold** | **32.8** | **37.8 → PASS** |
| same, LOO | 32.1 | 37.6 |

What this changes:
- `research/water_balance_method.md` (unstaged) says: "The zone adjustment does not generalise to ungauged basins province-wide. Out of sample it is worse than no adjustment." Its skill table is correct. That conclusion is not. What fails out of sample is the single `"other"` level that mixes 9 heterogeneous zones. Own-zone adjustments improve held-out headwater stations.
- The same file's "out-of-sample skill of this method family ... is 35-40 % MAE" inherits that framing.
- The gate verdict flips on a structural choice that the plan did not put to a decision.

Caveat: the "pooled → 0" variant was chosen after seeing CV results. Adopting it on this evidence alone is selection on the test set. This is a method decision for the author, not a patch. At minimum, correct the research wording, and record the own-vs-pooled split in the tracked report.

### 2. [Low-Medium] The `wet_wb_fit()` documentation misdescribes the mechanism behind finding 1

`R/wet_wb_fit.R:20-21` (and `man/wet_wb_fit.Rd`) says: "A level with no information in the data (all its stations held out) gets coefficient 0, i.e. no adjustment."

Under the procedure `wb_validate.R` now uses (`pooled = NULL`, decided per fold), a zone whose dominant stations are all held out has 0 dominant gauges in training. It is therefore **pooled**, and its held-out stations get the `"other"` coefficients (≈ +168 mm), not 0. That is exactly the 136 "pooled in the fold" stations in the report. Coefficient 0 only arises when `pooled` is fixed from outside and the zone's columns are all zero. The test at `test-wet_wb_fit.R:43-46` pins only that case.

Lines 17-19 ("pass `pooled` ... so each cross-validation fold fits the same model structure that is shipped") and the `wet_wb_pooled()` text ("decided once from every station and passed to each cross-validation fold") also describe the round-2 design, which was reverted. Anyone reading the docs to understand the gate would conclude that held-out zones get no adjustment.

### 3. [Low] The staged record of the key result is inconsistent: the new numbers live only in unstaged files

- The staged `planning/active/findings.md` still says "Gate passed on headwater stations: 39.2 % vs 43.8 %", under a heading marked "superseded, see below". Nothing below it gives the mswx result or the FAIL.
- The FAIL (46.4 vs 39.8), and the decision to ship raw P - AET, appear only in `research/water_balance_method.md` and `research/README.md`. Both are ` M`, **unstaged**, as are the checkbox flips in `task_plan.md`.
- Committing the index as it stands ships a tracked report saying FAIL, a figure (`research/wb_runoff_annual.png`) of raw P - AET, and a findings file whose last validation entry says PASS.

Stage the research and plan files with this commit, or add the mswx result to `findings.md`.

### 4. [Low] `scripts/wb_map.R`: the legend says "Calibration gauge" but the map plots every accepted snap

`wb_map.R:147-149` plots `s[s$accepted, ]`, which is 309 stations. The calibration set is 290: basin ≥ 95 % in BC and on the grid, with observed runoff. The 19 stations excluded from calibration are drawn and labelled as calibration gauges.

Either filter to the calibration stations (for example, persist `cal$station_number` in `fits.rds`), or label the points "HYDAT gauge (accepted snap)".

### 5. [Low, latent] `wb_map.R` picks its run differently from validate/output

`wb_map.R:138-140` selects the single `data/wb/<key>` that has `runoff_annual.tif`. It does not require `upstream/_complete` or `fits.rds`.

Consider a new complete run next to this one. `wb_validate.R` and `wb_output.R` would then stop (two complete runs). `wb_map.R` would still silently map the old run, because only the old run has the tif. It does not trigger now, since `data/wb` holds one run dir. Using the same selector as the other two scripts closes it.

## Checked clean this round

- **Fix 1 (pooling per fold).** `wet_wb_fit(d[tr, ])` decides pooling from the training rows only, and the report counts come from `fit$pooled` in each fold. LOO 72 = the 40 stations in the 9 shipped-pooled zones plus the 32 in zones 07/10/23/24, each at exactly 8 dominant gauges, which drop to 7 in LOO. That is consistent. `n_floored` is 0 in both CV schemes, so round 2's zone-07 collapse is gone.
- **Fix 2 (`_complete`).** Written only when every code's `.rds` exists; the file contains the 24 codes. `wb_validate.R` and `wb_output.R` both require exactly one complete run, and output additionally requires `fits.rds`.
- **Fix 4 (unseen zones).** Their columns are dropped from `cal` before `zone`, the folds and every fit. `wb_output.R` drops columns not in `fits$wb$coef`. The map loops over `fits$wb$coef` only. All three treatments agree.
- **Fix 5 (run key).** See Reproducibility above.
- **Fix 6 (`wet_wb_pooled`, all-NA rows).** Rows with no finite share are removed before `max.col`. The test covers it.
- **`keep_adjust = FALSE` is applied consistently.**
  - Output: annual = `pmax(up$raw, 0)`, the same floor the gate's raw baseline uses.
  - Map: `ro_raw` clamped at 0, with no coefficient loop.
  - Report: "not applied (gate failed)".
  - The monthly share model is applied in every case. It was never gated, as designed.
- **Map grid.** No artefact. The pale block in NE BC is the 0-99 mm class. `ro_raw` sampled along 58.6°N and 59.2°N from -122.5 to -119.5 is smooth.
