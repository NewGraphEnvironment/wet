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

## Phase 1 (2026-11-13, m1)

- **Method versions not bumped.** Both comments say to bump when what the file *holds* changes; it does not. The names change anyway, because the archives' md5s and the tiles' ETags now enter the keys, so no old file can be reused: the CGIAR crop becomes `cgiar_aet_c4908-7920_r3588-5016_<md5(method|md5s)8>.tif`, the DEM `glo90_<md5(grid|method|sorted tile ETag pairs)10>.tif`.
- **The VRT keeps its tile order.** Only the key sorts the tile/ETag pairs (radix); the VRT still stacks tiles in `wet_glo90_names()` order, so the rebuilt DEM's values can equal the old one's.
- **ETag read, measured from m1:** 261 tiles over the BC crop's bbox in 5.0 s (pool of 20 per host). Tile N54 W128 still reads `"79570191aca5306672c619e23f8fc69c"`, as probed at the park.
- **CGIAR order of operations changed:** a cache hit needs both archives beside the crop (md5 of 560 MB, about a second); a rebuild asks figshare first (one call), re-downloads any archive whose md5 differs, then checks the cache again under the new name, then extracts only if the marker's md5s differ. A marker-less tree is still removed and extracted again; the old test that a figshare failure removes it changed, since figshare is now asked before the tree is touched.
- **#51:** both check scripts keep `DATASET == "mswx.blend"` and four-digit periods, assert 30 rows per point, and report the pre-#51 mean from the same `downscale()` read, so the committed reports' diff is the fix alone. `wb_term_diagnose.R`'s ECCC cache is keyed on the script's md5, so it rebuilds.
- Mutation check: dropping the md5s from the CGIAR key, the ETags from the DEM key, or the marker comparison each turns at least one new test red.

## Phase 4 (2026-11-13, m1)

- `wet_donor_mean()`: a donor within `1e-9 * median(dist)` takes the whole weight, shared equally by every donor within it; at `median(dist) = 0` this is the old exact-zero test. New `tests/testthat/test-wet_donor_mean.R`: the last-bit and shared-weight tests fail on the old rule (checked in a detached worktree) and pass on the new; `test-wet_shape.R:180-199` (frozen pre-#102 oracle), share, donor-weight and departure tests pass unchanged.
- A weight discontinuity of about `1e-6` relative remains at the tolerance (a donor just beyond it already holds about 1 - 1e-3 of the weight at `1e-9 * median`, from the `1e-6 * median` offset). Accepted: it is the decided rule.
- **Departure path:** `wet_departure_carry()` builds its donors as `setdiff(stations, target)` (`R/wet_departure_carry.R:109`), so a target is never its own donor. A donor falls within the tolerance only if it sits on the target's watershed with predictors differing in their last bits; two stations on one watershed share one predictor row, so their distance is exactly 0 and took the whole weight before #158 too. The site parity tests compare tracked reports only, so they cannot show this; the argument stands in for them.
- **Knowingly stale:** `data/checks/departure_pcic_20260717.txt` names the scoring md5 of its day; it is not rerun in this move (its donors and scores do not pass through the calibration gauges' own rows).
- **Ordering on m4:** Phase 4's and Phase 5's commits change scoring code, so they stay unpushed until Phase 3's rescore (under the unchanged scoring code) has run from m4's checkout.

## Phase 2 (2026-11-13, m4, logs `data/logs/163/20261113T075010Z_run_compare_*`)

- `92b893c4da` against itself: IDENTICAL, exit 0; 275 files, 270 rds, 2 rasters, 3 text files, 3,245,453 upstream watersheds (about 4.5 min).
- `_pre16/962a9cc2c4` against `92b893c4da`: exit 1, 272 differences, every sample and upstream rds and `layers.tif` naming `snowmelt_doy_50, swe_max` as only in the second; every column also differs, the pre-#76 row order; `ex_filled_cells.txt` differs; `in_bc.tif` and `lc_ratios.csv` are identical.
- An APFS clone of `92b893c4da` with one `aet_yr` value in `upstream/400.rds` multiplied by `1 + 1e-15`: exit 1, one difference, `upstream/400.rds: columns differing: aet_yr` (`..._run_compare_onechange.log`, written at the rerun).
- m4's `cp` on PATH is GNU, so the clone needs `/bin/cp -c` (first try failed with `cp: invalid option -- 'c'`).

## Phase 5 gate score, first read (2026-11-13, m4, before the chain; `data/logs/163/wb_gate_main_stems_try.txt`)

From a copy of `wb_gate_score.R` writing under `data/logs/163/`, so it left `data/checks/` clean for Phase 3. 2 of 20 flip, both `fu35`: fit_20251014 29.31 against raw 28.91 on headwater (margin arm), fit_20260717 28.98 against 27.57 (worse by 1.41) but nested 19.01 against 24.58 (nested arm). Shipped `cfu` on fit_20260717: 30.72 against 30.69, margin arm. Stored score md5s: fit_20251014 `363fdc6915a6`, fit_20260717 `37d93d99ca65`. Taken to the owner (task_plan, decided at resume): go on.

## Phase 3 (2026-11-13, m4, logs `data/logs/163/chain163_a.log`, `wb_inputs.log`, `input_values.log`, `wb_province.log`, `wb_run_compare.log`, `wb_validate_*.log`)

- `wb_inputs.R` 08:13–08:23Z. New crop `cgiar_aet_c4908-7920_r3588-5016_0aebcfd5.tif` (built in 23 s, archives re-extracted once since the old marker was empty) and DEM `glo90_18361bbeb7.tif` (about 9 min with the ETag read): **values and bytes identical** to the old files (`f24bedbc`, `ae0bdc5602`), so climr was reused (still two files). Old files moved to `data/cgiar/_pre163/`, `data/dem/_pre163/`; run `92b893c4da` to `data/wb/_pre163/`.
- `wb_inputs.txt`: only the file names, the build date and cd's version (0.5.0 → 0.6.13) change; every md5 is the same.
- **#51:** `climr_eccc.txt`, 57 stations: MAP ratio p10/median/p90 0.915/1.034/1.153 → 0.916/1.035/1.153; MAT difference −0.547/−0.098/0.346 → −0.527/−0.081/0.362 °C. The pre-#51 line, from the same ECCC read, equals the committed report's numbers, so the change is the fix alone.
- Province run under the new key `768876badf`, 08:23–08:40Z (17 min). `wb_run_compare.R _pre163/92b893c4da 768876badf`: **IDENTICAL**, 275 of 275 files byte-identical, 270 rds, 3,245,453 upstream watersheds.
- Decision files carried; ten variants rescored, compared and cfu shipped under the unchanged scoring code (08:44–08:50Z). **Every `wb_validation*_20260717.txt` (11) and `wb_aet_compare_20260717.txt` equal the committed ones byte for byte once `province run: 92b893c4da;` reads `768876badf;`.** That closes #21.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `cp: invalid option -- 'c'` on m4 (GNU cp first on PATH) | `/bin/cp -c -R` for an APFS clone |
