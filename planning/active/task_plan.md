# Task: Have PUBLISH update the publish report's live-build line, so no BUILD rerun follows an upload (#117)

## Problem

`scripts/vignette_data_lib.R` `vd_published()` reads one line of `data/checks/discharge_publish_<release>.txt`:

```
parts identical to the published build <commit>: N of N here, N published (<manifest url>)
```

and refuses unless it names the live build with every part identical. Only a BUILD writes that line (`scripts/discharge_publish.R`, near `pub_line`), and it writes it before the upload, against whatever was live at the time. A republish therefore leaves the tracked report saying "6 of 512" (#76's republish on 2026-10-24) or "0 of N". The fix so far has been a second full BUILD after the upload (after #99, at 608147e, and again for #76). It rebuilds the whole tree and redoes every value check on bytes that have not changed since the first BUILD.

The upload already holds the fact that line needs: it compares each part's md5 with the local manifest, uploads, then reads every part back anonymously. #76's log: `published 512 parts (506 uploaded), 0 stale keys deleted; all verify at <manifest url>`.


Approved by the user at the plan gate, 2026-10-24.

## Context

`vd_published()` (`scripts/vignette_data_lib.R:62`) accepts the tracked publish report only when its
`parts identical to the published build <commit>: N of N here, N published (<url>)` line names the live
build with every part identical. Only a BUILD writes that line (`scripts/discharge_publish.R:683`), before
the upload, so every republish has been followed by a second full BUILD (about 3.5 h on m4) just to rewrite
it (#99 at 608147e, #76 at 34f38a9). PUBLISH already holds the fact: after uploading it reads every part back
anonymously (`wet_catalog_verify(cat_pub)`, `:133`). #94 is the gap in the same line: it identifies the live
build by commit and part count only, so a rebuild at the old commit from changed inputs passes.

## Decided at the gate

- **The #94 identity is a digest of the live parts' md5s** (md5 of the sorted `key md5` lines), not the
  manifest's `built` time. The digest is the property the line claims ("parts identical"); `built` is a
  proxy that changes on a rebuild of identical bytes. (Reject with `built` to switch.)
- The PR closes both #117 and #94.
- The digest is required: an old-format line (the tracked report today) is refused, never waved through.

## Phase 1: one line writer, one digest, one parser

- [x] `wet_catalog_digest(cat)` internal in `R/wet_catalog.R`: md5 of `paste(key, md5)` sorted with
      `method = "radix"` (locale-free), via a tempfile and `tools::md5sum()` as `digest_raw_md5()` does.
      Tests in `tests/testthat/test-wet_catalog.R`: stable under row order, changes when one md5 changes.
- [x] `publish_live_line(cat_local, cat_pub)` in `scripts/discharge_publish_lib.R`: the existing `sprintf()`
      moved here, with `; live parts md5 <digest of cat_pub>` appended (the `could not read` branch kept).
      BUILD's `pub_line` calls it.
- [x] `vd_published()`: parse the digest from the same line and refuse unless it equals
      `wet:::wet_catalog_digest(wet_catalog())`, alongside the existing commit and count checks.

## Phase 2: PUBLISH rewrites the line

- [x] `publish_report_live(f_report, cat_local, cat_pub, verified)` in `discharge_publish_lib.R`: refuses
      unless every `verified$ok` and `identical(cat_pub$md5, cat_local$md5)`; finds the one line after the
      single `## Against the published tree` heading (refuses on 0 or 2+); replaces it with
      `publish_live_line(cat_local, cat_pub)`; writes the file; changes no other line (asserted).
- [x] Call it at the end of PUBLISH after the verify, and stamp that the report is left modified for a commit.
      Header comment of `discharge_publish.R` updated: no BUILD follows an upload.

## Phase 3: the guards fire (tests)

- [x] `tests/testthat/test-publish_report_live.R`, sourcing both libs from the source tree into an env
      (skipped when `scripts/` is absent, i.e. under R CMD check, which excludes it), with `wet_catalog` and
      `wb_report` stubbed in that env:
  - a failed verify, or `cat_pub` md5s differing from `cat_local`, refuses and leaves the report byte-identical;
  - a passing call rewrites only that line, to N of N and the live digest;
  - `vd_published()` accepts that report; refuses one whose digest differs from the live catalog's (#94's
    sequence: same commit, same count, other parts); refuses the old-format line; refuses a FAIL.
- [x] Mutation table in `findings.md`: drop the digest compare in `vd_published()`, drop the `verified`
      check in `publish_report_live()`; each test named goes red, then restored.

- [x] Plan review's blocker: BUILD writes `tree parts md5` of its own tree; PUBLISH, `publish_report_live()`
      and `vd_published()` require it (`review-plan.md`)

## Phase 4: docs

- [x] `CLAUDE.md` publishing and segment-vignette paragraphs, `research/discharge_publish.md` (Status, line 84:
      the report after an upload is PUBLISH's line, the digest), so neither says a BUILD follows an upload.

## Owed at the end (reported, done after merge)

- [ ] The tracked report's line has no digest, and this branch changes `scripts/`, so PUBLISH would refuse the
      current tree anyway. Until the next BUILD on m4 (about 3.5 h) writes the new line, the vignette data
      scripts refuse. Nothing needs them now; the next republish carries it. Reported, not run.

## Validation

- [x] Tests pass (`devtools::test()`: 1411 pass, 0 fail), lintr clean on changed lines (the one left is `wet_catalog_digest` unseen in the installed package)
- [ ] `/code-check branch` clean
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

Verification: the unit tests above with the mutation table; `vd_published("20260717")` run once on this
machine against the live manifest refuses the current report for its missing digest (expected). The real
PUBLISH path (S3) is not run here: it is exercised through `publish_report_live()` and first runs live at
the next republish.

