# Task: Publish the snow-informed monthly balance and regenerate the vignette data (#77)

**If we do it:** the published discharge carries the snow-informed monthly shares (#16), and both vignettes are rebuilt from it. **If we never do:** `s3://fresh-bc/discharge/fwa/v1/` keeps the pre-#16 monthly balance (build 7c62b9e), and the vignette data scripts refuse to run, because the tracked publish report no longer names an identical live build.

## Context

#16 shipped the snow predictors for the monthly shares (fit_20260717, province run e675918817), and a value-checked BUILD of the new tree sits on m4 in worktree `~/Projects/repo/wet-16` (`data/publish/discharge/fwa/v1/`, built at acb820f, report committed at a18406a: every cross-check 0 differing, 6 of 67 parts identical to live 7c62b9e). Until it is uploaded, `vd_published()` (`scripts/vignette_data_lib.R`) refuses both vignette data scripts. The issue's four steps: upload, reload fwapg, read the stored held-out months (#68) instead of recomputing them, regenerate the vignette data and prose.

Checked during exploration:
- `git diff acb820f HEAD -- R scripts` is empty, so PUBLISH's code guard passes and a post-upload BUILD passes the segment-table guard (`discharge_publish.R:178`). **Order matters:** nothing under `R/` or `scripts/` may change before the post-upload BUILD. Phase 3 edits only `data-raw/`, which neither guard reads.
- `vd_published()` needs the tracked report to say `parts identical to the published build <live>: 67 of 67 here, 67 published`. The original report says 6 of 67 against 7c62b9e, so after the upload BUILD is rerun once (the #64 route: a rebuild of the same inputs writes the same bytes) and that report is committed.
- `cv_aet-cfu.rds` on m1 already carries `cv_share` (315×12, the shipped `snow` spec), `cv_ann`, `obs`, `obs_share`, `share_spec`. `data-raw/monthly_vignette_data.R:66-76` still recomputes them with `predict_cv()`.
- The segment-discharge vignette checks that `segment_map.rds` names the same build as `segment_values.rds` (`segment-discharge.Rmd:43-44`), so `data-raw/segment_vignette_map.R` is rerun too. The issue names only the two values files.
- The monthly-flow vignette holds its prose to the data with `stopifnot()` (e.g. `:264-274` Buck Creek freshet "under half and a month late", `:522` "high January to May"), and its gaps list names #16 as open (`:576`, `:666`). These will trip or go stale.

## Phase 1: Upload (m4)
- [x] On m4, in `~/Projects/repo/wet-16`: confirm HEAD's `data/checks/discharge_publish_20260717.txt` names build acb820f with no FAIL, and that the local tree verifies against its manifest
- [x] `AWS_PROFILE=airvine WET_PUBLISH=1 Rscript scripts/discharge_publish.R`, under `caffeinate -i`, logged to `data/logs/77/`. If auto mode refuses it as a production write, hand over the bare command
- [x] Confirm from m1, unsigned: the manifest names acb820f, and `wet_catalog_verify()` passes 67 of 67

## Phase 2: Report on the live build, and fwapg (m4)
- [ ] In the wet-16 worktree, check out this branch (no `R/`/`scripts/` changes yet). Rerun BUILD and confirm the report reads `identical to the published build acb820f: 67 of 67`, with every check ok
- [ ] Stop unless the rebuilt report is 67 of 67 identical, fails no check, and its reader lines equal a18406a's. Never run `WET_PUBLISH=1` from the rebuilt tree: its manifest names the branch HEAD
- [ ] Copy that report to m1 and commit it on this branch
- [ ] `wet_db_load()` the new manifest into m4's `discharge.fwa_v1_segment_monthly` and `discharge.fwa_v1_watershed_monthly`, from an ad hoc script outside `data/`. Confirm both table comments name acb820f, and that fresh's `month = 0 AND pick` row counts match the report's reader line; then VACUUM both tables (the replace doubles them on disk)

## Phase 3: Stored held-out months (#68)
- [x] `data-raw/monthly_vignette_data.R`: take `ann`/`share` from `cvr$cv_ann`/`cvr$cv_share` and drop `predict_cv()`. Guards: `cvr$share_spec == fits$share_spec`, `cvr$obs` and `cvr$obs_share` equal `cal`'s, and `long(cal, cv_ann, cv_share)` scored by `wet_flow_validate()` equals the stored `cv_v$stations` (all.equal)
- [x] Rewrite the header comment, which says the months are not stored
- [x] Update CLAUDE.md's monthly-flow paragraph ("reading the stored months instead (#68) waits on the next publish (#77)")

## Phase 4: Vignette data and prose (m1)
- [ ] Rerun `data-raw/segment_vignette_data.R`, `segment_vignette_map.R` and `monthly_vignette_data.R` (with `WET_FWAPG_COMMIT=341b078` and `WET_HYDAT`), each from a clean committed tree
- [ ] Render both articles. Fix every `stopifnot` and prose claim the new months break (the January–May bias, Buck Creek's freshet, the window table), each held to the new numbers
- [ ] Rewrite the monthly-flow gaps: #16 is shipped, so say what remains (`research/water_balance_method.md`, "Snow predictors…"). Do the same for CLAUDE.md's "Its gaps are #16, …"
- [ ] Fix the other stale sentences: monthly-flow.Rmd on recomputed months (:460, :721) and "no snow term" (:569); NEWS.md "until #77"; `research/water_balance_method.md` "not yet uploaded"
- [ ] Update `research/discharge_publish.md`'s status (live build acb820f, uploaded date, the fwapg load) and the #77/#68 issue bodies

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion; PR closes #77 and #68
