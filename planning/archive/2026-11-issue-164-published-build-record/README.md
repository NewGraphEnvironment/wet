## Outcome

Backlog move 2 (#164) gave the published discharge build one record of itself and published the fit beside it, in one format change and one PUBLISH. The manifest's daily description names the February fold beside the clamp (#108). `wet_db_load()` records each loaded part in `discharge.wet_load` inside the load's transaction, keyed `(dataset, scenario, key)` and with the table comment unchanged (#88). The BUILD writes crate's provenance receipt, `receipt.json`, beside the manifest rather than in its place, so the manifest stays `manifest_version = 1` (#161). The BUILD also publishes `fit/fits.rds` and each group's sample as parquet, and `scripts/segment_group.R` gained `WET_GROUP_FROM=published` to rebuild one group from them on a machine without the province run (#160). Running published mode from a checkout with no `data/wb` exposed a gap that m1's reduced bundle had hidden. The scoring md5 hashes the stations file and the fit's decision files, so it can't be recomputed away from the province machine. Published mode now holds the checkout's scoring code files, by content, to the build's commit, which checked the fit on the province machine. Its first form used `git diff`, which an index flag can blind; review round 4 found that.

## Measurement

- BUILD on m4 from a0318b7: 2 h 59 min, 0 FAIL. 512 of 512 parts byte-identical to the live build 3e8a968, so the parts digest stayed `d554e3aa…`. Fit: 247 files, 1.44 GB. Receipt: crate hashed the 759 files it lists in 94 s.
- PUBLISH (the user's word): 8 min. 0 parts uploaded, 248 fit and receipt files uploaded, 0 stale keys deleted, all verified anonymously; the live build is now a0318b7.
- A wet installed before this branch (0.4.33) reads the new manifest as its 512 parts and ignores `receipt` and `fit`.
- `segment_group.R BULK` from the published fit, in a checkout with no `data/wb`, took 23 s (2.8 s of it fetching the fit and samples). Its `watershed.parquet` and `segment.parquet` are byte-identical to the province-run mode's (272,610 and 390,481 rows), and both are at parity with a0318b7's rows.
- A scratch load (`months = 0, pick_only = TRUE`) took 102 s for 43 parts and 4,532,843 rows. Its 43 `wet_load` rows equal the catalog's keys and md5s, and carry `recipe_id` and the subset.
- Samples against `layers.tif`, measured at the gate: 1.1 GB of rds for the 246 samples against 526 MB; one sample is 21.3 MB as rds and 26.0 MB as zstd parquet. The user kept samples.

Durable record: `research/discharge_publish.md` ("Beside the parts: the receipt and the fit", "Which parts a table holds") and `research/segment_group.md` ("From the published build").

## Evidence

`data/logs/164/` on m4 (the BUILD, PUBLISH and segment_group runs); tracked reports `data/checks/discharge_publish_20260717.txt` and `data/checks/segment_group_BULK*_20260717.txt`.

## Owed

- Move 1's owed items and #161's bundle-attribute item, done by #165 (mirrored in both bodies): regenerate `inst/vignette-data/` against this move's build, rewrite the segment-discharge Nechako sentences, remake `man/figures/readme-pick.png`, and reload `pcic` from fwapg 5d50cc1 on the bundle machine.
- Tell link (in a link issue) that `discharge.wet_load` exists, so its walk cache can key on the historical load's rows instead of the comment.
- wet#171: `segment_daily_output.R`'s `own` list lacks the two files #164 added to `publish_own`; fixing it forces a daily rerun.

Closed by: the PR for branch `164-backlog-move-2-the-published-build-s-rec`
