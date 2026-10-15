# Code-check round 2 (branch 16-snow-predictors-for-the-monthly-shares, diff 6fa5a0a...HEAD at 67b2d6b)

Reviewer: subagent, 2026-10-14. No repo file edited except this one. Probes ran from scratch scripts
against the reduced bundle on this machine (`data/wb/962a9cc2c4/`) and the cd cache.

## Findings

- **[bug]** scripts/wb_upstream_identity.R:30 (`if (!identical(a, b[names(a)]))`) — the check can never pass.
  Every stored upstream file carries an `irregular` attribute (set by `wet_upstream_means()`, kept through
  `up$wscode <- ...` and `saveRDS()` in wb_province.R:265-271). `b[names(a)]` goes through `[.data.frame`,
  which drops custom attributes, so the left side has `irregular` and the right side does not.
  Reproduced on `data/wb/962a9cc2c4/upstream/300.rds`: `attributes(a)` is
  `names, irregular, row.names, class`; with `b <- a; b$snowmelt_doy_50 <- 1; b$swe_max <- 2` (the same run
  plus snow columns, attributes kept), `identical(a, b[names(a)])` is FALSE, even `identical(a, a[names(a)])`
  is FALSE, and the per-column diagnostic finds 0 differing columns. So on the real run the script stops at
  the first basin with "upstream columns differ from the set-aside run: " and an empty column list. The plan
  (task_plan Phase 6) makes this script a gate "before any fit", so the pipeline blocks on a false failure,
  and the obvious reading of an empty list invites loosening the check. Compare the columns and the
  attributes separately, for example
  `identical(as.list(a), as.list(b)[names(a)]) && identical(attr(a, "row.names"), attr(b, "row.names")) &&
  identical(attr(a, "irregular"), attr(b, "irregular"))`, and name `irregular` in the stop message when only
  it differs.

- **[fragile]** scripts/wb_share_snow.R:519-533 — the cv_ann identity assertion fails toward pass. If
  `data/wb/_pre16/*/fit_<release>` is absent (the set-aside directory named differently, not yet moved, or
  the script run on a machine where `_pre16` was not copied), or present but holding no cv file of the same
  name, the loop does nothing and the report says "no fit set aside before #16 to compare the held-out annual
  with" while the script exits 0. The plan states "Its cv_ann identity assertion must pass, or stop and
  report" (task_plan line 52). The report line does disclose it, so this is not silent, but nothing stops.
  If the assertion is meant to be required on m4, stop when `length(ident) == 0` unless an explicit opt-out
  is given.

- **[fragile, report accuracy]** scripts/wb_inputs.R:388 and :390-392 — the two cd rows put
  `file = snow_cat$href`, the https URLs (`.../swe_max_annual.tif`), and `is_tif` matches them, so
  `grid_of()` runs `terra::rast(<url>)`, which terra opens over /vsicurl/ (checked: it reads
  `121 x 261 x 76` from the live object). So the manifest's `grid:` line for those rows describes the live
  S3 object at manifest time, not the cached copy whose md5 is on the line above, contrary to the comment at
  :358 ("fetched once, so the grid and the manifest describe the same bytes"). It also makes the manifest step
  need the network. Small in practice (the fetch ran minutes earlier), but the band count can differ if cd
  appends a year in between. Use `grid_of(snow_files[i])` for those rows (keep the URL in `source`/`file`).

## Round 1 fixes, checked

- Fix 1 (wb_inputs.R:378-382): the fallback is `rep(..., nrow(snow_cat))`, so `sprintf()` over
  `snow_cat$href` gets equal lengths; the `data.frame()` rows now match under cd < 0.6.5. Correct.
- Fix 2 (wb_share_snow.R:512-515): sources `scripts/wb_score_md5.R` after `load_all()`, `wb_fit_lib.R` and
  `release` are set, which is everything it needs; it compares `cvr$code_md5` with `score_code_md5`, which
  includes this key's fit decision files. Correct.
- Fix 3 (wb_inputs.R:364-367): the crop is the same expression `wet_snow_normals()` uses
  (`extend(ext(grid), 2 * res(r))`, `snap = "out"`, grid = `rast(f_aet)`). The fix omits `na.rm = TRUE`
  in `terra::mean()`, unlike the function; measured on the cached `swe_max_annual.tif` over the grid's
  extent, no cell has a partial set of NA years (30 or 0 NA bands only) and the count is 584 either way, so
  it makes no difference.

## Checked and found sound (no action)

- `$` partial matching: old cv files have no `share_spec*` name and old `fits.rds` has `share` (not a prefix
  match for `share_spec`), so `cvr$share_spec` / `fits$share_spec` are NULL on pre-#16 files as intended;
  `fits$share` on a new fits.rds matches `share` exactly.
- wb_share_snow.R group summaries: `wet_flow_validate()` emits only group values present, so an absent
  value would crash `grp()`'s `vapply`; but the shipped fit has calibration gauges in zones 27, 28 and 29
  (12, 16, 13) and 19 in WSC area 10, so every requested value exists.
- `obs_share * obs` and `sh * cv_ann` recycle down columns, matching `long()`.
- `groups` in wb_cv_lib.R is built after the merge with folds, so `lake = groups$lake` and
  `zone = cal$zone` in the cv file align with `station_number`.
- `wet_ws_sample()` and `wet_upstream_means()` work column by column (elementwise and `rowsum()`), so the
  added snow layers cannot perturb other columns' arithmetic; the identity itself should hold once the check
  above is fixed.
- discharge_publish.R: `fits` is read at line 186, before the description uses `fits$share_spec`.
- wb_aet_compare.R uses annual metrics only, so the share specification cannot move the #15 reproduction.

## Verdict

One bug: the upstream identity gate always fails on attributes, blocking the rerun with a misleading empty
column list. Two fragile items: the cv_ann identity in wb_share_snow.R passes when there is nothing to
compare, and the manifest's grid line for the cd layers is read from the remote object.
