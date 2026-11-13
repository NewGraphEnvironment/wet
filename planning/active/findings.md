# Findings — Backlog move 1: One refit chain (#163)

## Issue context

**If we do it:** one rescore-refit-publish chain carries every change that stales the fit: input caches keyed on their source data, a committed script that proves a province rerun equals the last, a calibration gauge's months that no longer turn on the last bit of its upstream means, and a gate that scores the main stems. **If we never do:** each of these stales the fit on its own, so the chain (rescore every variant, compare, `wb_validate.R`, outputs, segment tables, BUILD, PUBLISH) is paid once per issue, and the shipped fit keeps its zone adjustment only through a per-fit override.

Order: `planning/backlog.md`, move 1. Run `/planning-init <this issue>`: one phase per batch, one PR.

## Batch 1: province inputs, and proving a rerun equals the last

**Why here:** keying the CGIAR crop and the DEM on their source data renames those inputs, which changes the province run key (`scripts/wb_province.R` hashes `basename(f_in)`), so the whole chain reruns under a new key. A committed comparison script is the oracle that the new run holds the same values, and the same run closes the byte-for-byte report check #21 left open. `scripts/wb_inputs.R` reruns here anyway, so its climr check is fixed in the same pass.

**Touches:** `R/wet_cgiar_aet.R`, `R/wet_dem_glo90.R`, `scripts/wb_inputs.R`, `scripts/wb_term_diagnose.R`, a new `scripts/wb_run_compare.R`, `data/checks/`.

**Decided at the gate:** the DEM's key (tile list plus ETags or sizes, or a pinned snapshot); whether the compare script replaces `scripts/wb_upstream_order.R`.

| issue | title |
|---|---|
| #23 | Key the CGIAR and DEM caches on their source data |
| #51 | climr check scripts average the 1961-1990 reference row into 1981-2010 means |
| #24 | Commit a province-run comparison script |
| #21 | Stable row and zone order in the province run |

## Batch 2: the fit's own rules

**Why here:** both change scoring code (`scripts/wb_score_md5.R` hashes `R/wet_donor_mean.R` and the gate), so each stales the fit; under one rescore they cost one chain, not two.

**Touches:** `R/wet_donor_mean.R` (shared with `wet_shape_predict()`), `scripts/wb_validate.R`, `scripts/wb_cv_lib.R`, the fit's `adjust_override.txt`.

**Decided at the gate:** a tolerance on the zero-distance test, or leave it; the main-stem gate's rule, registered before it is scored on both fits; whether the override retires.

| issue | title |
|---|---|
| #158 | Donor shares at a calibration gauge turn on an exact-zero distance, so the last bits of the upstream means decide them |
| #47 | Water-balance gate: score the main stems, not headwater basins alone |

#76's remaining step (the `fwa_indexpoint()` tie-break, which reruns `scripts/wb_stations.R` and needs this same chain) joins this move if fwapg's tie rule lands before it starts. #44 (blending the zone adjustment) waits for batch 2's gate.


## Exploration (2026-11-12, plan mode, at 1d6a89f)

- Members' bodies read: #23, #51, #24, #21 (status 2026-10-24: fetch half landed in #76; only the byte-for-byte check remains), #158, #47. None of #163's members has comments.
- Run key: `scripts/wb_province.R:47-61` hashes `basename(f_in)` plus code md5s. CGIAR crop named `cgiar_aet_c<cells>_<method8>.tif`; DEM `glo90_<key10>.tif` from grid + method. climr dest name keys on `wet_raster_md5(elev)` (values), TerraClimate/land cover/MOD16/snow/zones on the grid.
- Current run: `data/wb/92b893c4da` (fit_20260717 only). Set-aside runs: `_pre16/962a9cc2c4` (fit_20251014, fit_20260717), `_pre76/e675918817` (fit_20251014).
- Template chain and ad hoc comparisons: `data/logs/76/chain.sh`, `run_compare.R`, `check_refit.R`, `compare_parquet.R`. #91 durations on m4: scoring ten variants 2 min 11 s, compare 3 min 25 s, output chain through BUILD 17 min. DEM build 5.4 min (`data/logs/dem_build.log`).
- GLO-90: anonymous HEAD gives ETag and Last-Modified per tile (N54 W128: "79570191aca5306672c619e23f8fc69c", 2022-05-09); anonymous ListObjectsV2 also works.
- `wet_donor_mean()` callers: `wet_share_predict()`, `wet_shape_predict()`, `wet_donor_weights()`, `wet_departure_carry()`; oracle copy at `tests/testthat/test-wet_shape.R:191`. Hashed by `wb_score_md5.R` and `wb_shape_daily.R` (shape_code_md5).
- Gate: `keep_adjust_for()` at `scripts/wb_cv_lib.R:139`; callers `wb_validate.R:196`, `wb_aet_compare.R:114`. Both fits' `cv_aet-*.rds` hold `raw_v`/`cv_v` summaries by nesting (headwater, nested) and area class; `fits.rds` does not.
- Reports naming the run key (`province run:` line etc.): every `wb_validation*_20260717.txt`, `wb_aet_compare`, `wb_output`, `wb_share_*`, `wb_shape_daily`, `segment_*`, `pcic_routed_compare`, `discharge_publish` reports.
- fwapg#39 and fwapg PR #43 (tie rule) still open on 2026-11-12, so #76 stays out of this move.

## Errors Encountered

| Error | Resolution |
|-------|------------|
