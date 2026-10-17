# Code-check round 2 (#93): adversarial

Diff: branch vs 122bdac at 2600e8e (planning/ and the .rds excluded). Probes ran in a scratch worktree at
2600e8e, now removed.

## Clean

No issues found.

## What was tried

- **The live state passes.** `vd_published()` + `vd_segment_report()` at 2600e8e against the live manifest:
  build_commit 71af15a, segment_commit e280f5d, live manifest acb820f / 1718a3d; the segment report equals its
  copy at 71af15a (342 lines). The bundled rds carries `segment_report_commit = "e280f5d"` beside
  `published$segment_commit = "1718a3d"`.
- **A segment_output.R rerun after the BUILD is refused.** The report's head moved to a new commit and
  committed: `vd_segment_report()` stops with "is not the segment report ... was built from (at 71af15a ...):
  rerun scripts/discharge_publish.R (BUILD)".
- **An older passing publish report is refused against the current segment report.** The publish report from
  31bc53d (build e8e482d, segment f854c21, also "67 of 67" identical to acb820f) committed over the current
  one: refused by `vd_segment_report()`. Restoring both old reports together passes, and that is correct,
  because both describe parts identical to the live ones.
- **The counts are tied to the live parts.** The picks are checked against the publish report's reader counts,
  which come from a tree whose md5s matched the live parts. `fwa`/`no_lut` are checked against fwapg, and
  `neither` follows from them by arithmetic. `far_low` rests only on the report being identical to the one the
  build read, and was so before this branch too. Counts are unchanged in the segment reports at 7260294,
  cdb0238, acb820f, e8e482d and 71af15a.
- **The BUILD reads the committed report.** It refuses dirty `data/checks` (`git status --porcelain`, so
  untracked and staged changes count too), so HEAD's segment report at build time is the one it parsed.
  `vd_commit()` runs first in the data script, so `readLines(f)` equals HEAD's copy.
- **`git show` itself:** the path is relative to the repo root (`wb_report()`), the report is ASCII with
  lines of at most 111 characters, there is no `.gitattributes` and no autocrlf, and no pager runs without a
  tty. Merged stderr (an ambiguous short sha, a git warning) can only make the comparison fail, which
  refuses.

## Note: pre-existing, not introduced here, not blocking

`vd_published()` identifies the live build by its `wet_commit` and part count, not by part md5s. Two
different trees with one `wet_commit` are possible only by checking out the old build commit L, rebuilding
from changed untracked `data/wb` inputs (for example a #76 rounding rerun), committing that report on top of
L, and publishing. After that, an older tracked report that says "identical to published build L: 67 of 67"
would pass while the live parts differ. This needs a deliberate publish from an old checkout. It was equally
open under the old `segment_commit` check and is outside this diff. If it ever matters, the fix is for the
publish report to record the live manifest's `built` time or its md5s, and for `vd_published()` to compare
those.
