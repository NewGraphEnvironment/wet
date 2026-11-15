# Task: Backlog move 2: The published build's record: receipt, the fit beside the product, the load table (#164)

**If we do it:** each published discharge build carries one receipt in crate's shape, a database that loads it records which parts it holds, the shipped fit is published beside the product so one watershed group's build runs anywhere, and the manifest gives both reasons a month's days need not average to the month. **If we never do:** the manifest, the vignette bundles and the table comment keep three provenance shapes, consumers key on a comment that names only the last scenario loaded, and `scripts/segment_group.R` runs only where the fit sits.

Batch 3 of `planning/backlog.md`: #108, #161, #88, #160. One format change and one PUBLISH; the parts' bytes do not change.

## Decided at the gate (user, 2026-11-15)

- **The receipt sits beside the manifest**, not in its place. `manifest.json` stays the catalog at `manifest_version = 1`, so older wet installs on link's hosts keep reading it, and its md5s keep matching S3 ETags. `wet_catalog()` reads only the manifest. #161's body gets edited to say this.
- **Load table `discharge.wet_load`**, one row per loaded part: `dataset, scenario, key, md5, rows, subset, manifest, built, wet_commit, recipe_id, loaded_at`. The primary key is `(dataset, scenario, key)`. A scenario's rows are replaced in the same transaction as its data. The table comment stays word for word, because link parses it.
- **The fit goes beside the product**: `fits.rds` plus each watershed group's province-run sample as parquet, under `discharge/fwa/v1/fit/`. Each file is listed in the manifest (key, bytes, md5, role) and in the receipt.
- **Move 1's owed items carry to #165**, along with #161's bundle-attribute item: bundle regeneration, the Nechako sentences, `readme-pick.png`, and reloading `pcic` on the bundle machine. They get written into #165's body and stay in #164's, and whichever merge does them ticks both.
- Mine, approved with the plan: **crate goes in `Suggests`, not `Imports`**, with `requireNamespace()` in the receipt writer. Only the BUILD writes a receipt, and readers like link shouldn't have to install crate. `Remotes:` gains `NewGraphEnvironment/crate`, floored at 0.16.0.
- Mine, approved with the plan: the manifest gains optional top-level `receipt` and `fit` entries and keeps `manifest_version = 1`. An older `wet_catalog()` ignores fields it doesn't know (checked by a test that reads the new manifest with the v1 field set).

## Phase 1: #108, the February fold in the daily description
- [x] `scripts/discharge_publish.R`: the `pcic_routed` description names both reasons a month's days need not average to the month: each day is clamped on its own, and 28 February also carries 29 February's flow, which the month weights by its days. The wording follows `segment_daily.yaml` and `research/discharge_publish.md`.
- [x] Grep `research/`, `R/` and `vignettes/` for the old sentence and fix any copy.

## Phase 2: #88, the load table
- [x] Test first, in `tests/testthat/test-wet_db_load.R` against the fixture tree: after a load, the schema's `wet_load` holds one row per loaded part, with key and md5 equal to the catalog's, rows equal to what was loaded, and `subset` NULL for a full load and the WHERE clause for a partial one. A reload of the same scenario replaces its rows. A second scenario's load leaves the first scenario's rows alone. A load that fails leaves both the data and `wet_load` as they were. The comment test still matches the old text exactly.
- [x] `R/wet_db_load.R`: create `<schema>.wet_load` if it's absent (column list from one `cols_load` vector), and inside the existing transaction delete `(dataset, scenario)` and insert the parts. `recipe_id` comes from `attr(catalog, "receipt")` and is NA for a manifest without one. Roxygen documents the table and how to read it.
- [x] Return value: still `data.frame(key, rows)`, so callers don't break.

## Phase 3: #161, the receipt beside the manifest
- [x] Declaration `inst/receipt/discharge_fwa_v1.yaml` (`crt_receipt_keys()` form). Recipe inputs: `province_run`, `fit` (fit release and scoring md5), `hydat_release`, `routed_run` (fingerprint) and `fwapg_commit`. Summary: rows per dataset. No tables fingerprinted, since 2.9 billion daily rows is past crate#50's limit and the parts' bytes are covered by SHA-256. No tolerances: the upstream sums have been order-stable since #76, and the declaration says so.
- [x] `wet_receipt_write()` (internal, in `R/wet_catalog.R` beside `wet_manifest_write()`) calls `crate::crt_receipt_write(publish = TRUE, keys =)`. Its inputs: `output$name = id`, `recipe.code$wet` (40-character commit, version, dirty = FALSE), the inputs above, every part and fit file as `result.parts`, and the summary. It writes `receipt.json` next to `manifest.json`. The manifest's `receipt` entry records `{key, bytes, md5, recipe_id}`, so the manifest names the receipt that goes with it.
- [x] `wet_catalog()` reads the optional `receipt` and `fit` entries into attributes (`receipt`, `fit`), and a new internal `wet_catalog_files()` lists parts, fit files and receipt for `wet_catalog_verify()`. *Corrected while building:* `wet_catalog_digest()` stays over the parts alone, because tracked reports (the publish report's `tree parts md5`, the departure site reports, `data-raw/chinook_sites_data.R`) hold that digest and the parts do not change; the fit and receipt get their own report line (Phase 4). Tests: a v1 manifest without the new entries still reads. A manifest with them reads, and verifying it catches a changed fit file. A fixture receipt round-trips through `crate::crt_receipt_read()`, and a rebuild of the fixture tree compares `identical`.
- [x] `DESCRIPTION`: crate in Suggests (>= 0.16.0), `Remotes:`. The test helper gains `local_discharge_tree_fit()`; the bundled `inst/extdata/discharge_manifest.json` stays a manifest without them, the older shape every reader must still read.

## Phase 4: #160, the fit beside the product
- [x] Measure on m4 (over Tailscale, or ask the user if ssh stays down): the sample count, total bytes and largest file under `768876badf/sample/`, and parquet size after conversion. Record the numbers in findings.
- [x] `scripts/discharge_publish.R` BUILD: copy `fits.rds` to `fit/fits.rds`, and write each `sample/<G>.rds` to `fit/sample/part-<G>.parquet`, refusing unless a read-back is `identical()` to the rds once column types are matched. The fit files go into `wet_manifest_write(fit =)`, with release, province run and `score_code_md5`. PUBLISH: put the fit files and receipt with Content-MD5 (skipping a file whose live ETag matches), add them to the keep list so the stale-key delete leaves them, and verify them anonymously. The report gains fit and receipt lines with their own md5 over the fit files and receipt; the parts' digest is unchanged.
- [x] `scripts/segment_group.R`: `WET_GROUP_FROM=published` reads `fits.rds` and the reach's samples from the live manifest's `fit` entry, verified by md5 before and after. It refuses unless the manifest's fit release, province run and scoring md5 are the ones it applies, and it skips the province upstream parity (reported as not compared). Default mode is unchanged.
- [x] `research/segment_group.md` and `research/discharge_publish.md` describe the published fit and the receipt. `CLAUDE.md`'s Publishing and `segment_group.R` lines get one clause each.

## Phase 5: build, publish, record (m4)
- [ ] On m4, on this branch, with a `connect_timeout` probe first: BUILD. Expect 512 of 512 parts identical to live 3e8a968, a new manifest digest (description, `receipt` and `fit`), and SHA-256 time recorded. Commit the report.
- [ ] `WET_PUBLISH=1` **only on the user's word** (an outward write; auto mode may refuse it, in which case I hand over the bare command). It uploads the manifest, receipt and fit only, then verifies anonymously. Commit the report PUBLISH rewrote.
- [ ] On m4: `scripts/segment_group.R BULK` in both modes, published and local, and the two reports agree row for row. Reload `wet_db_load(months = 0, pick_only = TRUE)` into m4's `discharge` and check that `wet_load` lists the parts. The comment still names `scenario historical`.
- [ ] Edit the bodies: #161 (beside, not in place; crate in Suggests; bundle attributes carried to #165), #88 (columns as built), #160 (what is published), #165 (add the move-1 owed items and #161's bundle item, mirrored from #164).

## Owed at the end (reported, done after merge)

- [ ] Move 1's owed items and #161's bundle-attribute item, done by #165 (mirrored in both bodies): regenerate `inst/vignette-data/` against this move's build, rewrite the segment-discharge Nechako sentences, remake `man/figures/readme-pick.png`, and reload `pcic` from fwapg 5d50cc1 on the bundle machine.
- [ ] Tell link (in a link issue) that `discharge.wet_load` exists, so its walk cache can key on the historical load's rows instead of the comment.

## Validation

- [ ] Tests pass (`devtools::test()`, with the local fwapg for `wet_db_load`)
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] `lintr` per-file diff against `origin/main`, with no new lints
- [ ] `pkgdown::check_pkgdown()`
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:
- **#108:** BUILD reports every part byte-identical to the live build, and only the manifest digest moves.
- **#88:** the db tests above, plus mutations: drop the delete and a reload doubles the rows; move the insert outside the transaction and a failed load leaves rows behind.
- **#161:** a receipt round-trips through crate's reader, a fixture rebuild compares `identical`, and the v1 manifest without the new fields still reads.
- **#160:** `segment_group.R BULK` from the bucket equals the local mode and the published rows. A changed fit file fails `wet_catalog_verify()`.

