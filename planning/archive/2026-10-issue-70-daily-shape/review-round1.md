# Code-check round 1: branch 70-sub-monthly-flow-per-segment-a-daily-cli

Reviewed against merge-base 80ab129 (diff + full contents of the changed files), with the R, shell and spatial checklists.

## Clean

No real issues found.

## What was checked (so the verdict is auditable)

- `wet_nse(obs, mod)` argument order matches every call in `scripts/wb_shape_daily.R` (observed first).
- `cal$obs` is an exact column of `cal` (`scripts/wb_cv_lib.R:52`), so the `$` read is not a partial match; every `fit$…`, `st$…`, `cvr$…` read in the new code has an exact key (`fit$n` and `fit$n_comp` both exist, so neither answers for the other).
- The script runs under `devtools::load_all()` (`wb_cv_lib.R:8`), so `system.file("vignette-data", …)` and `wet:::` reach the source tree, and the `shape_code_md5` it stamps hashes the code that ran. Recomputed from the branch's files: `ccbb528d10480021613c2b514bfde17b`, identical to the tracked report's `shape code`.
- The branch touches none of the files `scripts/wb_score_md5.R` hashes (`wb_score_md5.R`, `wb_cv_lib.R`, `wb_validate.R`, …): `git diff --name-only 80ab129...HEAD` lists only the new R files, tests, man, docs, report and planning files.
- `wet_fwa_upstream(wa, la, wb, lb)` returns TRUE where b is upstream of a; `up[i, ]` and `related <- up | t(up)` use it in that sense.
- `wet_station_doy()`: the date vector's first element is always day 1 of a month (`rep(1:31, n)`), so `as.Date(optional = TRUE)` picks `%Y-%m-%d` from a valid string and `strptime` returns NA for 30 Feb / 31 Apr; the `min_days` check mirrors `wet_complete_years()`'s `FLOW IS NOT NULL` count; the flat-fill indexing in `wet_shape_within()` (`rep(1/n[m], each = nrow(x))` under a column-major logical matrix) lands `1/days[m(j)]` in column j.
- `wet_shape_predict()` basis: the intercept and the 12 shares are collinear, `lm.fit` pivots one column out and the code zeroes its NA coefficient. Probed in a scratch copy with 30 synthetic gauges: `max |X %*% coef - lm.fit fitted| = 1.4e-12`, and a prediction for a new row with shares summing to 1 gives months that sum to 1.
- `wet_flow_window()` accepts `doy` input and `by = character()` (the `k <- rep("", nrow(x))` branch), and builds window days from a 2001 (common) year, matching the 365-day convention.
- Tests mutate the HYDAT fixture through `local_hydat()`, which is a `withr::local_tempfile()` copy, not a shared file.
- Both new test files pass from a copy of the package in the scratchpad (`NOT_CRAN=true`, 92 expectations, 0 failures).

## Observations not reported as findings (do not meet the bar)

- `wet_station_doy()` on a station with complete years but no `DLY_FLOWS` rows at all (0-row `d`) would die inside `stats::aggregate()` with "no rows to aggregate" rather than the function's own message. Unreachable from `wet_station_select()` output, and it still errors rather than returning data.
- The rule's February scoring lays `share_02 / 28.25` on 28 days, so February's daily total is 0.9 % under the share for every candidate alike; the CLAUDE.md note says this is deliberate.
