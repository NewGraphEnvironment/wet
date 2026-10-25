# Code-check round 1 (#117, #94), branch diff f4351217...83da9fe

## Checklist read

- code-check.md (330,698 bytes): the prose of every H3 under `## Mechanisms`, all 14, `|` rows skipped
  (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property;
  Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of
  two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what
  generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different
  things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning
  silently; One fact derived twice). Rules-that-stand-alone and later sections: not read beyond the index (about 20).
- code-check-r.md (177,187 bytes): read in full 7 sections: "`sort()` and `order()` collate by `LC_COLLATE`",
  "`tempfile()` lives in the session tempdir", "Read-back shape must match write-back shape", "`identical()` on
  two reader results tests the reader", "Under `R CMD check`, tests run from a temp dir against the INSTALLED
  package", "`system2(stdout = TRUE)` warns on a non-zero exit", "`paste()` with a zero-length argument". The
  rest (about 100) from the index only.
- code-check-shell.md (124,118 bytes): index only; the diff adds no shell, and its git calls are unchanged
  `system2()` lines. 0 sections read.
- code-check-spatial.md (155,517 bytes): index only; nothing spatial in the diff. 0 sections read.

## Clean

No issues found.

What was checked, against the "look especially at" list:

- **Guards failing toward pass.** Every new comparison fails toward refusal: an NA digest (unreadable tempfile)
  makes `if (NA)` error, and `lines == "tree parts md5 NA"` counts 0. `vd_published()`'s regex is anchored at
  both ends, the digest group is exactly 32 lowercase hex (what `tools::md5sum()` returns), and
  `length(same) != 1L` refuses a duplicate line. "FAIL" cannot occur inside a lowercase hex digest.
- **Certifying a report for other parts.** PUBLISH's pre-upload check (`rep_head`, committed copy) and
  `publish_report_live()` (working copy, equal to HEAD because the top-of-script dirty check covers
  `data/checks`) both require the report's `tree parts md5` to equal the local tree's digest, and
  `vd_published()` requires it to equal the live digest. So the parts the value checks ran on (by key and md5)
  are the live parts whenever a report is accepted. The #94 sequence and the plan review's blocker sequence
  (restore an older committed report over a rebuilt tree) are both refused.
- **Order of PUBLISH's steps.** Rewrite comes after `stopifnot(identical(cat_pub$md5, cat_local$md5))` and the
  anonymous verify; a refusal writes nothing. A failed mid-upload leaves the old manifest live, and the report's
  tree digest (new) differs from live, so `vd_published()` refuses.
- **Digest definition.** Keys are unique (`wet_catalog()` refuses duplicates) and contain no spaces
  (`wet_part_parse()`'s regex), md5s are 32 hex, so `<key> <md5>` lines are unambiguous. `method = "radix"` sorts
  in the C locale. All ASCII, so no encoding dependence.
- **Same catalog BUILD writes and PUBLISH reads.** `cat_local` is read from `manifest.pending.json`, which is
  renamed (not rewritten) to `manifest.json` after the report; nothing writes a part after line 426. The digest
  uses only `key` and `md5`, not `href`, so the rename cannot move it.
- **Tests and mutations.** In the scratch copy, `test-publish_report_live.R` passes (24 expectations, 0 failed,
  0 error) and `test-wet_catalog.R` passes. Four mutations each go red: dropping the tree-line check in
  `vd_published()` (1 failure), the live-line digest check in `vd_published()` (1), the tree-line check in
  `publish_report_live()` (2), the cat_pub/cat_local digest check in `publish_report_live()` (2).

Not flagged (not reachable in practice): if a live manifest's `provenance` lacked `wet_commit`, `sprintf()` with
a NULL argument returns `character(0)`, so BUILD would write no live-build line, and `publish_report_live()`
would then refuse after every upload, where its header says to rerun PUBLISH. This is the old `sprintf()`'s
behaviour, unchanged, and `wet_manifest_write()` always writes `wet_commit`.
