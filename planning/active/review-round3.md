# Code-check round 3 (#93): claims

Reviewer angle: every quantified or factual claim the branch adds or changes, checked against the code a real run takes.

## Findings

- **[fragile, pre-existing, next to the diff]** research/discharge_publish.md:5 (Status). The paragraph says "The build report is `data/checks/discharge_publish_20260717.txt`: the value-checked rebuild at wet eb17bca". The tracked report's line 3 actually reads `wet commit 71af15a (segment table built at e280f5d)`, and main has carried that line since 382eabe (#91). The paragraph this branch adds at line 78 rests on "the commit this report's build ran at", and `vd_segment_report()` compares the segment report against that commit. A reader who takes the build commit from the Status line gets eb17bca, which is the wrong commit for the copy the guard compares against. Line 5's "segment table 1718a3d" is the live manifest's commit, not the report's (e280f5d), and the new paragraph says those two can differ. This is not introduced by the diff, but the branch re-dated this file's Verified header, so it is the moment to correct it. Remedy: name 71af15a / e280f5d as the build report's commits on line 5.

## Claims checked and true (no action)

- "The build refuses uncommitted data/checks": scripts/discharge_publish.R:54 runs `git status --porcelain -- R scripts data/checks DESCRIPTION` and stops on any output, before the segment report is read at :168. The check has existed since 7e738e1 and is present at the live report's build commit 71af15a.
- "That is the report as committed at the build's commit" / "the build reads only committed reports": `wet_commit` is `rev-parse --short HEAD` (:57), and the segment report is read from a working tree whose data/checks is clean. Every report the build reads is under data/checks (`wb_output`, `segment_output`).
- "Compared whole, since its head names only a commit, and a rerun at the same commit would name the same one": segment_output.R:257 writes only `wet commit %s; fit ...` as its head.
- "The live manifest may name an earlier segment commit": the live manifest names 1718a3d, the report names e280f5d, and 1718a3d is an ancestor of e280f5d.
- `segment_report_commit` "the commit the segment report and the publish report's build name": the build derives `seg_commit` from the same report it read (:170) and writes it into its head (:469). Identity at the build commit therefore implies equality.
- The remedy "rerun scripts/discharge_publish.R (BUILD)" works. After a committed segment_output rerun, BUILD at the new HEAD names that commit. Once its report is committed (`vd_commit()` asks for that), `vd_segment_report()` passes. If parts changed, `vd_published()` refuses first ("M of N here").
- `re_seg` matches the build's sprintf at :469 exactly. The current report has exactly one such line.
- "Both data scripts": data-raw/segment_vignette_data.R:105 and data-raw/segment_vignette_map.R:46 both call `vd_published()`. Only the data script reads the segment report.
- CLAUDE.md "needs no republish": true. It needs a BUILD and a commit of its report, not a PUBLISH.
- Vignette provenance comment: matches the guards (`vd_published()` requires N of N parts identical).
- inst/vignette-data/segment_values.rds: `provenance$segment_report_commit` is "e280f5d", equal to the publish report's "segment table built at e280f5d". `published$segment_commit` is "1718a3d".
- tests/testthat/test-vignette_data.R under `pkgload::load_all()` with NOT_CRAN=true: all 7 blocks pass, with 0 failed, 0 error and 0 skipped. The segment-values block has 24 passes, including the new `segment_report_commit` expectations.

Verdict: the diff's own claims are clean. One adjacent stale Status line should be corrected.
