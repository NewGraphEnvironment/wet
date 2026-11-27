# Task: Backlog move 15: Re-run the segment chain and a publish BUILD after 0.4.40 (#208)

**If we do it:** the published segment discharge is confirmed unchanged by 0.4.40's `pick` column and the publish guards' new list of non-inputs, every live part is checked byte-identical to the manifest, and the reports the run leaves modified are committed. **If we never do:** the guards keep treating two files that are no longer inputs as inputs, so the next real publish rebuilds and re-uploads tables whose content did not change, and nobody has checked the live parts since 0.4.40.

Batch 17 (#198): re-run `scripts/segment_output.R`, `scripts/segment_daily_output.R`, then `WET_FWAPG_COMMIT=5d50cc1 scripts/discharge_publish.R` BUILD, expecting every part byte-identical to the live manifest and no upload. Touches `data/checks/segment_output_20260717.txt`, `data/checks/segment_daily_output_20260717.txt`, `data/checks/discharge_publish_20260717.txt`. Move 16 (#209) waits on it.

## Decided at the gate

- Parked with no plan gate in this pane (a coordinator-dispatched `park review`, 2026-11-25): the gate is the coordinator's plan gate on the pushed review.
- One phase of work, one PR: the three reports. No code change is planned; a code change found necessary is its own finding and goes under `## Open decisions`.
- Machine: always the machine with the full province run. A machine holding a reduced bundle only (`data/wb/768876badf` is 31 MB: `fit_20260717/` with `output/` and `upstream/`, no `segment/`, no `segment_daily/`; measured 2026-11-25) cannot run the chain.
- No upload. BUILD only: `WET_PUBLISH` stays unset. A BUILD that finds a part differing from live is a stop, not a republish.

## Phase 1: Prepare the full-run machine (the plan review's corrections folded in)
- [x] Before building: bash "$T/skills/_shared/members_check.sh" <origin> 208 208-backlog-move-15-re-run-the-segment-chain --batch 17
- [ ] On the full-run machine, run from the **main checkout** (`wb_key_dir()` reads the relative `data/wb`; a worktree with `data/` symlinked would put the reports in the wrong tree; at most symlink `data/wb` alone). `git fetch`, check out this branch, `git merge origin/main`; tree clean and committed, and no merge, checkout or stash between runs (they can touch report mtimes the guards read).
- [ ] The premise moves: HEAD is v0.7.0 (v0.4.44 at the park), not 0.4.40, and many files under `R/` and `scripts/` changed (`scripts/discharge_publish_own.R` gained #169's PCIC readers and coverage scripts since the park) since the live segment commit 66cf795 (`segment_output.R`, `wb_output.R`, `wb_fit_lib.R`, `R/wet_source_pick.R` did not). The run checks the live parts against 0.7.0's code; record the `wet_version` it names.
- [ ] Probe before the long runs: fwapg with `DBI::dbConnect(..., connect_timeout = 10)` (a hang means ask the user to restart Docker); installed crate 0.16.0, arrow 25.0.1, duckdb 1.5.6 (the live report's lines; another arrow version breaks byte identity with no code to blame); S3 reachable for the live manifest (else no identical line, and 512 of 512 is unproven); `fits$aet == "cfu"`; `wb_output` and `wb_output_*` exist; routed run fingerprint 179854603.510890 at fwapg 5d50cc1.
- [ ] Disk: `mv` (not `cp`) `segment/` and `segment_daily/` to `_pre208` beside the fit, since `segment_output.R:64` unlinks both at start; the BUILD also rewrites the 33 GB publish tree. Check free space first.

## Phase 2: Re-run the chain
- [ ] `WET_FWAPG_COMMIT=5d50cc1 Rscript scripts/segment_output.R` (log under `data/logs/208/`); compare each parquet with `_pre208` by `tools::md5sum`, a difference then read and tested with `identical()` (parquet bytes depend on the arrow version); commit its report. The report always differs from the live one (it carries the HEAD commit), which is expected.
- [ ] `WET_FWAPG_COMMIT=5d50cc1 Rscript scripts/segment_daily_output.R` (about 2 h 12 min at its #99 run; the table is about 2.9e9 rows); compare as above; commit its report (its `elapsed` and commit lines differ by design).
- [ ] `Rscript scripts/discharge_publish.R` BUILD (about 3.5 h; `WET_PUBLISH` unset; `WET_FWAPG_COMMIT` is not read by the BUILD, so omit it), after both reports are committed.
- [ ] Pass condition, exactly: the report line `parts identical to the published build a0318b7: 512 of 512 here, 512 published`; `tree parts md5 d554e3aad481d86bffa4baef687287ed` unchanged; no `FAIL`; every cross-check `ok`; segment and daily parquet md5s equal to `_pre208`. Commit `data/checks/discharge_publish_20260717.txt`. Its `receipt hashed in N s`, arrow line and commit differ by design, so compare per part against the manifest, never the reports whole.

## Phase 3: Record
- [ ] Parts identical: nothing to publish. Accepted: the live manifest and receipt keep naming the old `wet_commit` and `wet_version`, since "no upload" leaves them; say so in the PR.
- [ ] Any part differing: no upload, attribute the difference (ours, theirs or unresolved), and file an issue naming move 15 and [wet#209](https://github.com/NewGraphEnvironment/wet/issues/209) (move 16).
- [ ] The vignette bundles are not rebuilt here (rebuilding one alone could break the article setup's one-build check). `vd_published()` and `vd_segment_report()` read the committed reports; the BUILD's own success proves their guards, so no `data-raw/` script runs.

## Validation

- [ ] Reports in `data/checks/` committed; `git status` clean on the full-run machine before each run
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`; the diff is three reports)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved: the BUILD report's per-part line reads 512 of 512 identical to live, its tree parts md5 equals the live parts md5, and the segment tables' md5s equal `_pre208`'s or each difference is attributed.
