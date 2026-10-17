# Findings — segment_vignette_data.R refuses after a rerun that leaves every published part identical (#93)

## Issue context

**If done:** `data-raw/segment_vignette_data.R` runs after a rescore or a `segment_output.R` rerun that leaves every published part byte-identical, without a republish. **If never done:** it refuses after every such rerun until the next publish that changes values, as it has since #81 (and again after #91).

## What happens

`data-raw/segment_vignette_data.R:170` requires the tracked segment report to begin `wet commit <segment_commit>;`, where `segment_commit` is the one the live manifest names. The live manifest names 1718a3d (build acb820f). The tracked report has named f854c21 since #81 and e280f5d since #91. Each rerun of `segment_output.R` writes the current HEAD into the report, so the check fails even when the rerun's parts are byte-identical to the live ones, which `discharge_publish.R` BUILD confirms ("parts identical to the published build acb820f: 67 of 67").

`scripts/vignette_data_lib.R` `vd_published()` checks only the publish report's identical-parts line, so `monthly_vignette_data.R` passes the same state.

## Options

1. Accept a segment report whose build fed a passing publish report with every part identical to the live build (the publish report names its segment commit), instead of requiring the live manifest's commit.
2. Leave it, and republish identical parts after each such rerun (#77's pattern: BUILD, `WET_PUBLISH=1`, BUILD again). #91 declined this.

Related: #81, #91, #64.

## Plan review (Plan agent, 2026-10-16, no blockers)

- **Gap, taken:** the segment report's head (`scripts/segment_output.R:257`) names commit, fit, province run and
  scoring code, nothing that marks a run, so a rerun at the same commit would pass a commit match. The publish
  BUILD refuses uncommitted `data/checks` (`scripts/discharge_publish.R:54`), so the report at the build's commit
  (71af15a) is the one it read. `vd_segment_report()` compares the tracked report with that copy, whole.
- **Q4, not taken:** an `is-ancestor` check of the live manifest's segment commit (1718a3d) against the publish
  report's. Every part is byte-identical to the live build, so it adds nothing about values.
- **Ordering:** the test needs `segment_report_commit`, which the bundle gets only on regeneration (Phase 2).
- **Q2:** only the PUBLISH branch (`discharge_publish.R:83`) also reads the publish report's head; unchanged.
  `segment_vignette_map.R` and `monthly_vignette_data.R` call `vd_published()` and inherit its new
  single-segment-commit parse, which matches the tracked report.

## Guard probes (`vd_published()` live, no fwapg)

- Tracked state: build 71af15a, segment table e280f5d, live manifest segment 1718a3d. `vd_segment_report()` passes.
- `build_commit` set to 1718a3d (another build's report): refused.
- Same commit, one count changed in a scratch worktree's report: refused.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| First data run: `FATAL: terminating connection due to administrator command` | Docker Desktop on m1 quit at about 17:45 PDT mid-run (not this session); asked the user |
