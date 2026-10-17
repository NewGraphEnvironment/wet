# Code-check round 4 (#93): research/discharge_publish.md Status line

## Clean
No issues found.

Verified (2026-10-16):
- data/checks/discharge_publish_20260717.txt line 3: "wet commit 71af15a (segment table built at e280f5d)"; 67 of 67 parts identical to the published build acb820f.
- data/checks/segment_output_20260717.txt line 3: "wet commit e280f5d"; the tracked copy is byte-identical to its copy at 71af15a.
- git log: e280f5d "Routed comparison under #89 scoring code (#91)", 71af15a "Segment table under #89 scoring code (#91)", and the build report was committed in 382eabe (#91). So "rerun in #91" holds.
- Live manifest provenance: wet_commit acb820f, segment_commit 1718a3d. This matches "built at wet acb820f (segment table 1718a3d)". The segment report at acb820f also names 1718a3d.
- The paragraph near line 78 agrees: the segment report at the build commit 71af15a equals the tracked report, and the live segment_commit 1718a3d is earlier than e280f5d.
