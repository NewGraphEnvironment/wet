# Findings — Have PUBLISH update the publish report's live-build line (#117)

## Issue context

**If we do it:** after an upload, the tracked publish report already names the live build, so the vignette data scripts can run straight away. **If we never do:** every republish is followed by a full BUILD, about 3.5 hours on the machine with the full runs, only to rewrite one line that the upload already proved.

## Problem

`scripts/vignette_data_lib.R` `vd_published()` reads one line of `data/checks/discharge_publish_<release>.txt`:

```
parts identical to the published build <commit>: N of N here, N published (<manifest url>)
```

and refuses unless it names the live build with every part identical. Only a BUILD writes that line (`scripts/discharge_publish.R`, near `pub_line`), and it writes it before the upload, against whatever was live at the time. A republish therefore leaves the tracked report saying "6 of 512" (#76's republish on 2026-10-24) or "0 of N". The fix so far has been a second full BUILD after the upload (after #99, at 608147e, and again for #76). It rebuilds the whole tree and redoes every value check on bytes that have not changed since the first BUILD.

The upload already holds the fact that line needs: it compares each part's md5 with the local manifest, uploads, then reads every part back anonymously. #76's log: `published 512 parts (506 uploaded), 0 stale keys deleted; all verify at <manifest url>`.

## Proposed Solution

Once PUBLISH's anonymous verify passes, have PUBLISH rewrite the `parts identical to the published build` line of the tracked report itself, using the same `sprintf()` the BUILD uses, against the manifest it just wrote. PUBLISH already refuses unless the committed report names the build and fails no check, so the only change it makes is that line. The report is then left modified for a commit, the same as after a BUILD.

- Keep every value check in the BUILD. This removes only the second BUILD.
- The line should still come from code, never from a hand edit, so `vd_published()` keeps checking the bucket rather than our typing.
- While touching it, record the live manifest's `built` time, or the md5 of its parts, in the same place, which is #94's fix. Both edits are to the same line, which is also the one `vd_published()` reads.
- Test that the guard fires: with that line written by a PUBLISH whose verify failed, `vd_published()` must still refuse.

Relates to #94, #76, #93

## Exploration (2026-10-24)

- BUILD writes `pub_line` at `scripts/discharge_publish.R:683`, against the manifest live at build time; PUBLISH (`:66-138`) verifies every part anonymously (`:133`) then quits without touching the report.
- `vd_published()` (`scripts/vignette_data_lib.R:62`) parses the line with a start-anchored regex, so a suffix parses.
- The tracked report (`data/checks/discharge_publish_20260717.txt:49`) names live b4bbc50, 512 of 512, from the BUILD rerun at 34f38a9 (dd525f0).
- No testthat test reaches `scripts/`; `.Rbuildignore` excludes it, so a test that sources it must skip under R CMD check.
- PUBLISH refuses when `R/` or `scripts/` changed since the build commit, so this branch itself makes the current local tree unpublishable: the first report with a digest comes from the next BUILD.

## Tree digest (from the plan review)

The plan as approved let PUBLISH certify a committed report for whatever tree sat on disk at the report's commit
(`review-plan.md`). The report now also carries `tree parts md5 <digest>` of the BUILD's own tree, required by
PUBLISH before the upload, by `publish_report_live()` before the rewrite and by `vd_published()` against the
live parts.

## Real report against the live manifest (2026-10-25)

`vd_published("20260717")` on m1: live b4bbc50, 512 parts, digest 0f4f8caa89691c2196a551c11b345918; the tracked
report is refused ("not a passing value check of the live build b4bbc50"), because its line predates the digest.
Expected; the next BUILD writes both lines.

## Mutation table (scratch copy of the tree, `tests/testthat/test-publish_report_live.R`)

| guard removed | test that goes red |
|---|---|
| `vd_published()`: live-line digest | refuses a line naming the live commit and count over other parts (#94) |
| `vd_published()`: tree digest | same |
| `publish_report_live()`: `verified` all ok | leaves the report as it was unless its upload verified |
| `publish_report_live()`: published digest = local | same |
| `publish_report_live()`: tree digest in report | refuses a report of another build, a failed one, or one with no single live line |
| `publish_report_live()`: build commit in report | same |
| `publish_report_live()`: no FAIL | same |
| line writer: digest left out | rewrites only the live-build line, and vd_published() takes it; and the #94 test |

Each restored after its run. PUBLISH's own pre-upload tree check (`discharge_publish.R`) is not reachable from
testthat (S3); it calls the same `publish_tree_line()` the tested function does.

## Code-check round 2: the BUILD would have refused this branch

`scripts/vignette_data_lib.R` was on neither of the BUILD's code-changed exclusion lists, so the BUILD the owed
item names would have stopped with "code changed since ...segment_output_20260717.txt was built at 28105a3
(scripts/vignette_data_lib.R)". That would have meant rerunning `wb_output.R`, `segment_output.R` and
`segment_daily_output.R` first. Only `data-raw/` sources the file, so it feeds no table, and it is now in
`publish_own`. With it there, both guards replayed empty (`git diff --name-only 28105a3|f99df25 -- R scripts` with
the exclusions). `segment_daily_output.R`'s own list (`own`, :80) is left without it on purpose: editing that
script would trip the BUILD's daily guard (from f99df25, excluding only `publish_own`) and force a daily rerun.
The cost is that a lone rerun of `segment_daily_output.R` asks for `segment_output.R` first, which fails safe.
No scoring-code hash (`scripts/wb_score_md5.R`) covers a file this branch changed.

## Errors Encountered

| Error | Resolution |
|-------|------------|
