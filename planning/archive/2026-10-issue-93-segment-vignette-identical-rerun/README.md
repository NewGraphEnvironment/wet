## Outcome

`data-raw/segment_vignette_data.R` had refused since #81, because it required the tracked segment report to name the live manifest's `segment_commit` (1718a3d). Every rerun of `segment_output.R` writes its own commit into that report, even when every published part stays byte-identical. It now takes the segment report the tracked publish report's build read. `vd_segment_report()` (`scripts/vignette_data_lib.R`) requires the tracked report to be identical to its copy at the build's commit, which `vd_published()` now parses from the publish report's head. The BUILD refuses uncommitted `data/checks`, so that copy is the report it read. The plan review found that comparing commits alone would pass a rerun at the same commit, which is why the whole report is compared. A rerun that leaves every part identical now needs a BUILD and a commit of its report, not a republish. The bundle records the report's commit (`segment_report_commit`) beside the live manifest's. A gap that predates this branch, found in review: `vd_published()` identifies the live build by commit and part count rather than by part md5s. Filed as #94. Research: `research/discharge_publish.md`, line 78 and Status.

## Measurement

- `segment_values.rds` regenerated on m1 at 70bf12c: `skill` and `segments` are identical to the previous bundle (5ad20df), and provenance differs only in `built`, `wet_commit` and the new `segment_report_commit`, which is e280f5d against the live manifest's 1718a3d. Routed values at the 289 gauges: 0 differing from fwapg's mean of twelve months, largest difference 1.1e-13 m³/s.
- Guard probes, run against the live manifest:
  - the tracked state (build 71af15a, segment e280f5d) passes;
  - a report from another build (1718a3d) is refused;
  - a count changed at the same commit, in a scratch worktree, is refused.
- The first data run died when Docker Desktop quit mid-run, not a code failure. It was rerun after a restart.

## Evidence

`data/logs/93/` on m1 (gitignored): the data run, the test run and the vignette render.

Closed by: PR for #93
