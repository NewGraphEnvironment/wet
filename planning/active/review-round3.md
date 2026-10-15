# Code-check round 3 (branch 16-snow-predictors-for-the-monthly-shares, diff 6fa5a0a...HEAD at f550adc)

Reviewer: subagent, 2026-10-14. No repo file was edited except this one. Probes ran from scratch scripts.
One used a `git archive HEAD` copy in the session scratchpad, with synthetic old and new upstream runs built
from the reduced bundle `data/wb/962a9cc2c4/`. One sourced `scripts/wb_cv_lib.R` read-only against that
bundle. One read the cd catalog and the cd cache.

## Mechanism and enumeration

**Mechanism.** One fact is established twice, by two reads or two derivations, and a guard or a report line
assumes the two agree without checking it. All six earlier findings fit:

- R1: `cd_sha`/`run_time` were read from a catalog shape that older cd does not have.
- R1: the shipped outcome was read from a cv file without checking that file against the current code.
- R1: the capped-cell count was taken over a different extent from the one the cap is applied on.
- R2: the identity compared `a` with `b[names(a)]`, a re-read that drops `irregular`, so it could never pass.
- R2: "nothing set aside" fell through as agreement, so the check could never fail.
- R2: the grid line came from the remote object while the md5 came from the cached copy.

So each place to check is a pair: what is compared, and whether that comparison can both pass and fail.

| # | Place | The two reads / derivations | Verdict |
|---|---|---|---|
| 1 | wb_upstream_identity.R:28-44 | old vs new upstream frame, column by column plus `row.names` and `irregular` | **Sound, measured.** Synthetic runs built from the reduced bundle (24 basins). Snow columns inserted after `n_km`, with `irregular` kept as `wet_upstream_means()` stores it, gives `identical: 24 basins, 335 watersheds`. A 1e-15 relative change in one `p_yr` stops with `upstream columns differ ...: p_yr`. Dropping one `irregular` id stops with `row names or irregular pairs differ`. `_complete` always lists codes (wb_province.R:278 writes them), so the loop cannot run empty. Column sums are per column (`rowsum()`, per-column segment trees, per-column `rowsum` in `wet_ws_sample()`), so the extra columns cannot move the others' bits. |
| 2 | wb_share_snow.R:46-61 | new cv files vs the set-aside ones (`cv_ann`, `raw`, `gate_pass`, `station_number`) | **Sound.** It stops unless exactly one set-aside fit exists and it holds this AET's cv file. It can pass: `predict_cv()` under HEAD, on the reduced bundle with cfu and the fixed variant, reproduces the stored pre-#16 `cv_ann` `identical()`ly, both with `share_specs = "base"` and with all three specs once snow columns are added. `gate_pass` uses the annual MAE only (`hw()` reads `mae_pct`), so the share specification cannot move it. Every field compared exists in the old file (`raw`, `gate_pass`, `cv_ann`, `station_number`; no partial `$` match). |
| 3 | wb_share_snow.R:37-41 | cv file vs current scoring code | **Sound.** Uses the same `score_code_md5` recipe as wb_validate.R, including this key's decision files. |
| 4 | wb_share_snow.R:126 (`KEPT (the fit ships ...)`) vs fits.rds | the shipped spec read from the cv file; what ships is in `fits.rds` | **Sound under the documented order.** Both are written from one `ship_share` in one wb_validate.R run, and the rule depends on neither the AET nor the annual balance, so a current cv file and a current fits.rds agree. A cv file can be current while fits.rds is not: a stale winner plus an explicitly named AET writes the cv file but not fits. In that case the line describes a fit that has not yet been written. wb_output.R and discharge_publish.R refuse a stale fits.rds, so nothing wrong ships. Latent only. |
| 5 | data-raw/monthly_vignette_data.R:64-71 | spec from `cvr$share_spec` vs the stored scores | **Sound.** The all.equal on the stored `cv_v` stations includes `nse_share`, so a recompute under the wrong spec stops. A pre-#16 cv file has no name matching `share_spec`, so it gets `NULL`, which becomes "base". |
| 6 | discharge_publish.R:296 | description from `fits$share_spec` | **Sound.** fits.rds is held to `score_code_md5` at :188. On an old fits.rds, `$share_spec` does not partial-match `share`. |
| 7 | wb_validate.R:96-111 (rule) vs wet_flow_validate's share NSE (wb_share_snow breakdown) | two derivations of per-gauge share NSE (raw shares vs `mod/sum(mod)`; literal `10` vs `min_obs = 10`) | **Agree today, measured.** On the reduced bundle, base spec: rule n 315 and wet_flow_validate n 315, max abs difference 6.7e-16, same median 0.8558. They can part only at a gauge whose held-out annual is floored to 0, which wet_flow_validate drops. The report labels the two populations separately. |
| 8 | wb_cv_lib.R:131-134 equal-n guard | n of each spec's share fit | **Cannot fail, and harmless.** The NA guard at :117 runs first over every static predictor, and the remaining `complete.cases` columns (shares, ppt/tave/aet) are common to all specs. So every spec drops the same rows and n is always equal. The real guard is :117. |
| 9 | wb_validate.R `cv$share` (`= sh[[1]]`, base) | the default `share` vs the shipped spec | **Sound.** It is overwritten at :109 before `cv_v`, the cv file or anything else reads it. `lo` and `plain` pass `share_specs = ship_share`. |
| 10 | wb_inputs.R:362-367, 387-388 | `n_capped` (literal `3000`, `1981:2010`, its own crop) vs what `wet_snow_normals()` does (its defaults `cap = c(swe_max = 3000)`, `years = 1981:2010`, the same crop expression) | **Agrees today.** The extent, the years and the cap each match. Two copies of three constants are a latent drift: a change to a default would leave the tracked count describing a cap that was not applied. Not reported as a finding. |
| 11 | wb_inputs.R:376-393 | build provenance (`cd_sha`, `run_time`) from the live catalog vs md5 and grid from the cached copy | **Finding F1 below.** The pair can disagree, and nothing compares them. |
| 12 | wb_inputs.R:390-397 | grid line read from the cached copy (R2 fix) | **Sound.** `grid_file` maps each href to its cached path. |
| 13 | wb_province.R:44 `one("data/snow", ...)` vs the manifest's `f_snow` | which snow grid the run reads | **Sound.** `one()` stops on more than one file. Tests and the example write to temp dirs only. |
| 14 | wet_snow_normals() cache: key vs `dest` content | values of the bands read, grid, vars, years, cap, `wet_snow_method` | **Sound.** This is the repo's builder-version convention (#19). The province key also hashes `R/wet_snow_normals.R`. |
| 15 | wb_province.R snow fill | `n_snow` / fill passes vs the mask assertion | **Sound.** The `moved` check covers the snow layers. The loop stops at 200 passes rather than passing. |

## Findings

- **[fragile, report accuracy]** scripts/wb_inputs.R:376-382 (`snow_build`) and :386 — the manifest pairs two
  different reads:
  - The build line for each cd layer (`cd <sha>, built <run_time>`) comes from the live catalog (`cd_catalog()`, :356).
  - The md5 and grid on the lines next to it come from the bytes `cd_cache_fetch()` returned (:359).

  These are separate requests, and `cd_cache_fetch()` serves a cached copy without revalidating it in two
  cases: when its HEAD fails (with only an `inform()` message), and when `options(cd.cache_revalidate = FALSE)`
  is set. A republish between the two calls also leaves them describing different builds. cd guards against
  exactly this in its own code. Its internal `build_tags()` reads `CD_SHA`/`CD_RUN_TIME` "from the file actually
  opened, so a stale cached copy reports its own build rather than the one the catalog describes."

  Today the two agree. Both cached files carry `CD_SHA` 349f9d7… and `CD_RUN_TIME` 2026-10-10T22:36:36Z, the
  same as the catalog. The comment at :358 ("fetched once, so the grid and the manifest describe the same
  bytes") still overstates what is checked.

  Fix: take the build from the cached file, e.g. `terra::metags(terra::rast(snow_files[i]))` for `CD_SHA` and
  `CD_RUN_TIME`. Or stop when the cached file's tags differ from the catalog's `cd_sha`/`run_time`, or when its
  sha256 differs from `snow_cat$checksum`.

No bugs found. All three round-2 fixes are confirmed:

- The identity gate passes and fires (#1).
- wb_share_snow.R stops when nothing is set aside or the AET is missing from the set-aside fit (#2).
- The grid line reads the cached copy (#12).

## Verdict

One fragile item (F1, a provenance line read from the catalog rather than the bytes it describes). Of the 15
places the mechanism reaches, the other 14 are sound. #8 is a guard that cannot fire but is backed by a stronger
one. #4 and #10 are latent pairs that agree under the documented pipeline order.
