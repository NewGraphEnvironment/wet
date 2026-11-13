# Task: Backlog move 1: One refit chain: input keys, a committed run comparison, the donor zero test and the main-stem gate (#163)

**If we do it:** one rescore-refit-publish chain carries every change that stales the fit: input caches keyed on their source data, a committed script that proves a province rerun equals the last, a calibration gauge's months that no longer turn on the last bit of its upstream means, and a gate that scores the main stems. **If we never do:** each of these stales the fit on its own, so the chain (rescore every variant, compare, `wb_validate.R`, outputs, segment tables, BUILD, PUBLISH) is paid once per issue, and the shipped fit keeps its zone adjustment only through a per-fit override.

**Parked 2026-11-12, baseline only.** Approved by the owner as a park (the plan was drafted after "163" was misread as a go; the owner chose to park it rather than drop it). Does not wait on link#469: no shared files or data.

## Context

[wet#163](https://github.com/NewGraphEnvironment/wet/issues/163) carries batches 1 and 2 of `planning/backlog.md`: #23, #51, #24, #21, #158, #47. Each one, done alone, stales the fit and costs the full chain (rescore every variant, compare, `wb_validate.R`, shape, outputs, segment tables, BUILD). Done together, the chain is paid once. The umbrella and its members have no comments. #76 stays out: fwapg's tie rule (fwapg#39, fwapg PR #43) is still open.

What exploring the code showed:
- **The template is the #76 rerun** (`data/logs/76/chain.sh`, `run_compare.R`, `check_refit.R`, `compare_parquet.R`): set the old run aside under `data/wb/_preNN/`, run the province under the new key, compare, carry the fit's decision files, rescore, compare outputs, BUILD. #24 commits that ad hoc comparison.
- **Only two input names change.** The CGIAR crop and the DEM are named by their key. TerraClimate, land cover, MOD16, snow and zones are keyed on the grid, which does not change. climr is keyed on the DEM's *values* (`wet_raster_md5`), so it is reused if the rebuilt DEM's values match. The province key hashes `basename(f_in)`, so it changes once.
- **Rebuilding the DEM takes about 5 minutes** (`data/logs/dem_build.log`). The GLO-90 bucket answers a HEAD with an ETag per tile (the tile probed reads Last-Modified 2022-05-09).
- **#158 should not move the province run.** In the province run a gauge's watershed is exactly 0 from its donor. A tolerance changes only rebuilds by another route, for example `segment_group.R BULK`, whose 132 differing watershed rows should go to 0. `wet_donor_mean()` is also used by `wet_shape_predict()`, `wet_donor_weights()` and `wet_departure_carry()`. `tests/testthat/test-wet_shape.R:191` copies the rule as its oracle.
- **#47 can be scored from stored files.** Both fits' `cv_aet-<AET>.rds` (`fit_20251014` under `data/wb/_pre76/e675918817/`, `fit_20260717` under the current run) hold `raw_v` and `cv_v` with headwater, nested and `>10000 km2` summaries, so the rule is scored on every variant of both fits without a rerun. The gate is `keep_adjust_for()` (`scripts/wb_cv_lib.R:139`), used by `wb_validate.R:196` and `wb_aet_compare.R:114`.
- **#21's remaining check** is that tracked reports reproduce byte for byte across two runs. The rekeyed run gives that check for free: rescore under unchanged scoring code, and every report must equal the committed one apart from its `province run:` line.

## Decided at the gate (recommendations adopted by the owner's approval of the parked plan, 2026-11-12)

1. **DEM key (#23):** the grid, the method and each tile's name and ETag, read by parallel HEAD requests on every call (a few seconds; a cache hit re-reads them). The alternative was a pinned snapshot.
2. **CGIAR key (#23):** the two archives' local md5s go into the crop's key and into the `.extracted` marker. An archive whose md5 differs from the marker is extracted again.
3. **The comparison script (#24):** a new `scripts/wb_run_compare.R <old> <new>`. It sits beside `scripts/wb_upstream_order.R` and does not replace it: that script replays two runs' row orders, while this one compares two runs' contents.
4. **#158:** a tolerance on the zero test, `dd <= 1e-9 * median(dist)`. A donor within it takes the whole weight, and several within it share it equally.
5. **#47, the rule, registered in `wb_cv_lib.R`'s header in its own commit before any score:** keep the zone adjustment if it beats raw P − AET on headwater gauges. Otherwise keep it unless both of these hold:
   - it is worse on headwater gauges by more than **1.0 point** of blocked-CV MAE (the margin #83 set for accepting a refit);
   - it is no better on nested gauges.

   If the rule keeps the adjustment on `fit_20260717`, retire `adjust_override.txt`. If it drops the adjustment on the shipped fit, stop before the chain and bring the decision to you.
6. **Publish:** none, unless the BUILD's parts differ from the live ones. Parts are expected to be byte-identical, and move 2 publishes. **Reopened by the plan review (finding 1) and decided at resume: PUBLISH.**

## Decided at resume (the owner, 2026-11-13, recommendations taken)

- **Publish (finding 1):** a PUBLISH after the BUILD under the new key, as #76 did (parts whose ETag matches are skipped); then the BULK/SALR proof runs in this move.
- **The override (finding 5):** remove `adjust_override.txt`'s reader with the file, if the rule keeps the adjustment on `fit_20260717`.
- **Gate flips (Phase 5 stop condition, asked 2026-11-13 08:0x UTC):** the rule flips `fu35` from drop to keep on both fits (fit_20251014 by the margin arm, 0.40 point; fit_20260717 by the nested arm, 1.41 points worse on headwater but nested 19.01 % against raw 24.58 %). `fu35` is transparency only and cannot win; shipped `cfu` stays kept (margin arm, 0.03 point). The owner chose to go on; the chain still stops if the AET winner is not `cfu`.
- **CGIAR source check (finding 10):** compare the archives with figshare's `computed_md5` (one API call per call that rebuilds) and refuse on a mismatch.

## Phase 1: Input keys and the climr check rows (#23, #51)
- [x] Tests first: a CGIAR archive with another md5 gives another crop path and is extracted again; a tile with another ETag gives another DEM path; a cached DEM still reads the ETags (network mocked to fail by default). Rewrite `test-wet_dem_glo90.R:21-29` and `test-wet_cgiar_aet.R:44-49`, which assume a networkless cache hit
- [x] `R/wet_cgiar_aet.R`: archive md5s in the key and in the `.extracted` marker, figshare's `computed_md5` checked on a rebuild; `wet_cgiar_method` not bumped (findings)
- [x] `R/wet_dem_glo90.R`: tile names and ETags in the key (one `curl` multi pool of HEADs); `wet_dem_method` not bumped (findings)
- [x] `scripts/wb_inputs.R` and `scripts/wb_term_diagnose.R`: keep `DATASET == "mswx.blend"` and four-digit periods only, as `scripts/wb_plateau_p.R` does; `climr_eccc.txt` reports the old filter beside the new one from the same ECCC read, so its diff is the fix alone
- [x] roxygen, `devtools::test()`, lintr per file

## Phase 2: The run comparison script (#24)
- [x] `scripts/wb_run_compare.R <old> <new>`, from `data/logs/76/run_compare.R`, over the run's own files only (`sample/`, `upstream/`, `layers.tif`, `in_bc.tif`, `lc_ratios.csv`, `ex_filled_cells.txt`; never `fit_*`, `_pre*`, `sample_times.txt`): file sets, every rds `identical()`, raster values and names, text files. It reports every difference, file-set ones included, without stopping at the first, and exits non-zero on any. #24's "reports compared as line sets": done by Phase 3's report diff, said in the script's header
- [x] Proved both ways: `_pre16/962a9cc2c4` against `92b893c4da` must FAIL and name the snow layers among its differences (it also differs by pre-#76 rounding); a copy of a run with one value changed must FAIL naming that file; a run against itself must PASS
- [x] Cited in `CLAUDE.md`'s pipeline list

## Phase 3: Rekeyed inputs and province run; reports reproduce (#23, #51, #21)
- [x] `wb_inputs.R`: new crop and DEM; check that their values equal the old files' (`wet_raster_md5`) and that climr is reused. If the DEM's values differ, stop and attribute the difference (tiles, GDAL or ours) before the province run
- [x] Commit `data/checks/wb_inputs.txt` and `climr_eccc.txt` (#51: record the change in the MAP ratio and the MAT difference)
- [x] Move the old crop, DEM and any replaced climr file into `_pre163/` folders beside them (`wb_province.R:40-41` needs exactly one of each); set `92b893c4da` aside as `data/wb/_pre163/92b893c4da`; run `wb_province.R` under the new key; `wb_run_compare.R` must report identical
- [x] Carry `pooled_variant.txt`, `pooled_test.txt` and `adjust_override.txt` into the new `fit_20260717` (the check copied from `check_refit.R:40` changes in Phase 5, when the override retires)
- [x] Rescore all ten variants, compare, ship `cfu` under the **unchanged** scoring code. Every `wb_validation*_20260717.txt` and `wb_aet_compare_20260717.txt` must equal the committed one apart from the `province run:` line. That closes #21; commit the reports

## Phase 4: The donor zero test (#158)
- [x] Test first: a donor row moved by a last bit (1e-15) still gives that donor's shares; two donors within the tolerance share the weight equally; the existing tests still pass
- [x] `R/wet_donor_mean.R`; leave `test-wet_shape.R:180-199` as is (a frozen pre-#102 oracle that passes unchanged; editing it would make it a tautology)
- [x] Departure tests pass unchanged; record why the departure path cannot hit the tolerance (a target is never its own donor, `R/wet_departure_carry.R:109`), since the site parity test compares tracked reports only. `data/checks/departure_pcic_20260717.txt` names the old scoring md5: list it as knowingly stale (not rerun)

## Phase 5: The main-stem gate (#47)
- [x] Register the rule (decision 5) as one function both the gate and the score call, with a disclosure line that both fits' headwater numbers were public before it (#47 body, `research/water_balance_method.md:133`), and commit it before scoring. An NA nested MAE refuses rather than reaching `if()`
- [ ] `scripts/wb_gate_score.R`: the rule on every variant of both fits, from their stored `cv_aet-*.rds`, to `data/checks/wb_gate_main_stems.txt`, beside the main-stem ratios already in `wb_output*.txt`. It does not source `wb_cv_lib.R` (which refuses 20251014); it names which `fit_20251014` copy it reads (`_pre16/962a9cc2c4` or `_pre76/e675918817`) and why
- [x] Stop before the chain if any variant's keep or drop flips on either fit, or the AET winner would not be `cfu`
- [x] `keep_adjust_for()` takes the nested MAE (callers `wb_validate.R:196`, `wb_aet_compare.R:114`). `gate_pass` stays the strict headwater test; a new field records the deciding arm, and the GATE line names it. Update the texts tied to the override: `wb_aet_compare.R:244,266-270`, `wb_fit_accept.R:117,126`, `data-raw/segment_vignette_data.R:232-234`, `vignettes/segment-discharge.Rmd:936-938`
- [ ] Retire `adjust_override.txt` if the rule covers its case (decision 5); and its reader with it (decided at resume)

## Phase 6: The chain, once
- [ ] Under the new scoring code (logs under `data/logs/163/`, `WET_HYDAT_RELEASE=20260717`, `WET_FWAPG_COMMIT=7c30f58`): rescore all ten variants, compare, `wb_validate.R <winner>`, `wb_shape_daily.R`, `wb_share_snow.R`, `wb_share_donor.R`, `wb_output.R`, `pcic_routed_compare.R`, `segment_output.R`, `segment_daily_output.R`, `discharge_publish.R` BUILD
- [ ] Compare each against `_pre163` (`check_refit`/`compare_parquet` logic, through `wb_run_compare.R` where it fits): `output/` and segment parquets byte-identical, or every difference attributed
- [ ] The PUBLISH decided at resume, then `segment_group.R BULK` and `SALR`: 0 differing rows (BULK showed 132 watershed rows before #158)
- [ ] `wb_term_diagnose.R` rerun (#51; record whether zone 15's 1.05 or the valley ratios move)
- [ ] Commit the reports step by step, as #76's chain did

## Phase 7: Docs
- [ ] `CLAUDE.md` (pipeline list, gate and override text, the fit's decision files), `research/water_balance_method.md` §0, `research/segment_group.md`, `research/discharge_publish.md:3`, `vignettes/segment-discharge.Rmd`, `scripts/wb_fit_lib.R:17-19`, `scripts/wb_upstream_identity.R:9`, NEWS; say that the `inst/vignette-data/` bundles keep run 92b893c4da until move 2

## Owed at the end (reported, done after merge)
- [ ] `backlog.md` tick by `/gh-pr-merge` 9c; move 2 (#164) is next and publishes the refit fit

## Validation
- [ ] Tests pass
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved: #23 by tests and equal raster values; #24 by FAIL on two known-different pairs and PASS on identical ones; #21 by byte-identical reports under the new key; #158 by `segment_group.R BULK` at 0 differing rows and by unchanged outputs; #47 by the registered rule's report on both fits; #51 by the two reruns' recorded shifts. The chain proves the whole move: outputs identical to `_pre163`, or each difference attributed.
