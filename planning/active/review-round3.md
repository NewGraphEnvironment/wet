# Code-check round 3 (#102): branch b8fe71c...d746734, planning/ excluded

## Checklist read

- code-check.md: I read all 14 H3s under `## Mechanisms` in prose, `|` rows skipped. They are: a guard that fails toward pass; fixture; proxy; verification reads its own output; a guard's scope, escape hatches and remedies; a fix lands in one of two callers; restore the bug; shared working tree; wrapper's exit; zero-length, empty and unset; probe broken; written data outlives the fix; serialization; one fact derived twice. For the stand-alone, security and spreadsheet rules I read the index lines only; none applies.
- code-check-r.md: I read these headings in full: `$` partial match; `[[` on an atomic vector; `paste()` with a zero-length argument; `ifelse()` with an all-NA test; `match()` and NA; `expect_false(identical())`; `tolerance` is relative; Rscript reads a script as it runs; a data-raw script must load the source tree. The rest are not used by this diff (DBI, sf, duckdb, cli, arrow and so on).
- code-check-shell.md: index only. The diff has no shell.
- code-check-spatial.md: index only, plus the FWA main-stem heading, because `share_related()` uses FWA codes. Nothing else applies.

## Clean

None of the probes below found a defect. Tests from a `git archive HEAD` copy under the scratchpad (`NOT_CRAN=true`):

| Test file | Passed | Failed | Errors |
|---|---|---|---|
| test-wet_share_fit.R | 36 | 0 | 0 |
| test-wet_shape.R | 66 | 0 | 0 |

`wet_donor_mean()` holds its shape on a 1-row `x` with a 1-column `y` (1 x 1), and on 3 rows with 1 column (3 x 1).

## Mechanism

The three earlier findings came from one assumption: **the shipped shares are identified by `share_spec` alone, as the monthly regression on monthly climate (CGIAR monthly AET) plus that static set.** Before #102 that held by construction:

- `cv_share == cv_shares[[share_spec]]`
- "the snow predictors ship" meant "the regression uses snow"
- the shares depended on the monthly AET

Code, guards and prose therefore keyed on `share_spec` or described the regression. #102 adds a second axis, `share_method`. Every place that names, checks or describes "the shipped shares" through `share_spec` alone, or as the climate regression, is a candidate:

- **R1:** the wb_aet_compare sentence about CGIAR monthly AET.
- **R2:** the vignette guard on `share_spec`.
- **R2:** the report's AET line with no blend arm.

## Enumeration (source of truth: a grep of R/, scripts/, data-raw/, vignettes/, tests/, inst/, README, NEWS, _pkgdown.yml and DESCRIPTION)

The terms searched were `share_spec`, `cv_shares`, `cv_share`, `share_method`, `wet_share_fit`, `wet_share_predict`, `fits$share`, `$share`, "regression", "monthly AET" and "CGIAR monthly". I also searched the prose for "share ... model/predict". Each hit below has a verdict.

### The author's list (branches on `share_method`)

| Location | Verdict |
|---|---|
| R/wet_share_predict.R:18 | Holds. The switch has all three methods plus `stop`, and a NULL method falls back to regression. |
| scripts/wb_share_donor.R:35-36 | Holds. |
| scripts/wb_share_donor.R:134 | Holds. |
| scripts/wb_validate.R:159 (the rule) | Holds. |
| scripts/wb_validate.R:259 | Holds. |
| scripts/wb_validate.R:319 | Holds. |
| scripts/wb_validate.R:343 | Holds. |
| scripts/wb_validate.R:351 | Holds. |
| scripts/wb_shape_daily.R:125 | Holds. |
| scripts/wb_shape_daily.R:414 | Holds. |
| scripts/discharge_publish.R:307 | Holds. Blend is refused on purpose. "five most similar" is hard-coded, not read from `fits$share$k`. It is true, because `k = 5` is fixed by the registered rule and `min(5, 315)` is 5. |
| vignettes/monthly-flow.Rmd:527 | Holds. It refuses a non-regression bundle. |
| data-raw/monthly_vignette_data.R:59 | Holds. A NULL method gives a NULL expected value, so the fit is refused. |
| data-raw/monthly_vignette_data.R:65 | Holds, for the same reason. |

### Outside the list, the same assumption: keyed on `share_spec`, a regression default, or prose about how the shares are made

| Location | What it assumes | Verdict |
|---|---|---|
| scripts/wb_cv_lib.R:168 | `predict_cv(share_method = "regression")` defaults to the regression. | Holds. The only callers are wb_validate.R:118 (meant to be the regression, for #16's comparison and the identity guard), :180 and :184, and the last two pass `ship_method`. |
| scripts/wb_cv_lib.R:191 | Passes the method through. | Holds. |
| scripts/wb_validate.R:148 | Identity guard: regression shares equal #16's. | Holds. Same rows and same order; neither matrix carries dimnames. |
| scripts/wb_validate.R:165-185 | `cv_v`, `ins_v`, `lo_v` and `plain` should all use the shipped method. | Holds. `cv$share` is replaced before `cv_v`. The gate reads annual MAE only. |
| scripts/wb_validate.R:320 | "shares shipped ... every table below uses them". | Holds. `raw_v` carries NA months, as before. |
| scripts/wb_validate.R:305-309 | The #16 snow line, scored on the regression. | Holds. The registered #102 rule runs on the static set #16 chose. "snow predictors KEPT" stays true under donor, because donor searches in that same space. |
| scripts/wb_shape_daily.R:165 | `stopifnot(share_spec == "snow")`, "the shipped shares' static predictors". | Holds under donor. They are the donor's search space. |
| scripts/wb_shape_daily.R:193 | Basis predicts from the held-out `cv_share`. | Holds. The registered rule names `cv_share` generically, and under donor it is the donor's held-out shares. The shape outcome may move on rerun, which the plan already expects. |
| scripts/wb_shape_daily.R:106 (header) | Its refusal list names `share_spec` only. | Comment only, not a report. The code also checks the method. |
| scripts/wb_share_snow.R:30, 41, 140 | Reads `cv_shares`, which are regression-only. | Holds. The report never calls them the shipped shares, and "KEPT (the fit ships the snow predictors)" stays true. |
| scripts/wb_aet_compare.R:249 | Fixed in R1. | The new sentence holds: the method is decided from `cal` shares and static columns alone, and `cal$raw` is never read, so the method does not depend on the AET. |
| scripts/wb_aet_compare.R:94 | Reads the summaries. | Holds. The decision is annual MAE only. |
| scripts/wb_output.R:63 | Calls `wet_share_predict()` through `fits$share`. | Holds. |
| scripts/wb_output.R:142 | Prints the method. | Holds. The line is not parsed: discharge_publish.R parses only the basin rows. |
| scripts/wb_fit_accept.R:102 | Uses annual errors only. | Not reached. |
| scripts/pcic_routed_lib.R:97 | Reads `cv_v$stations`. | Not reached: those errors are annual. |
| scripts/segment_output.R | Reads `output/`. | Not reached. |
| data-raw/segment_vignette_data.R:64-66 | Parses the wb_validation report under the heading `^### Adjusted, blocked CV`. | Holds. The heading is unchanged and no other heading matches it. The renamed headings for `lo` and `ins` start "Adjusted, leave-one-out" and "Adjusted, in-sample". The annual MAE column is unchanged. |
| data-raw/monthly_vignette_data.R:181 | Recomputes months through `wet_share_predict()`. | Holds for any method. |
| data-raw/monthly_vignette_data.R:27 (header) | "under the share specification the fit shipped". | Comment, incomplete but not false. |
| vignettes/monthly-flow.Rmd:525 + 549-557 | Prose describing the regression. | Guarded by line 527. |
| vignettes/monthly-flow.Rmd:119-121 | "split into months by a model of each month's share of the year, fitted to the gauges (`wet_share_fit()`)". | Holds under donor. |
| vignettes/segment-discharge.Rmd | Describes the annual balance only. | Not reached. |
| R/wet_share_fit.R roxygen | Updated for every method. | Holds. |
| R/wet_share_predict.R roxygen | Updated for every method. | Holds. |
| R/wet_shape_fit.R roxygen | Updated. | Holds. |
| R/wet_snow_normals.R:10 | "the two predictors the monthly shares were scored with". | Holds. |
| scripts/wb_province.R:149 | "predictors for the monthly shares". | Holds. |
| README.md:9 | "for each month from models". | Holds. |
| NEWS.md:41 | Historical. | Not stale. |
| _pkgdown.yml | Section text. | Holds. |
| crate schemas (segment_monthly.yaml, watershed_monthly.yaml) | Do they describe how the shares are made? | Not reached: they do not. |
| tests/ | Only test-wet_share_fit.R and test-wet_shape.R touch shares. | Both updated. |

### Scoring hash

`R/wet_donor_mean.R` is in `score_files_for()` and in wb_shape_daily.R's `shape_files`. The functions every new scoring path calls all sit in hashed files:

- `wet_share_fit()`, `wet_share_predict()`, `wet_donor_mean()`
- `wet_nse()` (R/wet_flow_validate.R)
- `wet_fwa_upstream()` (R/wet_cv_folds.R)
- wb_cv_lib.R

So no change to a scored path escapes the stale-fit check.

### Verdict

Nothing outside the author's enumeration branches on, guards or states the method in a way that is now false. Every remaining place that assumes the shares are identified by `share_spec` still holds under donor: the static set is still #16's, and it is the donor's search space. The rest are annual-only consumers, or comments that are incomplete but not false.
