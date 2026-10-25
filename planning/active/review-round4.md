# Code-check round 4 (#117): review of bf15a80 and the branch

## Checklist read

- code-check.md (330698 bytes): the prose of every H3 under `## Mechanisms` (table rows skipped); in particular "A guard that fails toward pass" ("Where the guard sits": a check that exists only in the post-write verifier), "A proxy is not the property" (irreversible write reads the live target), "A guard's scope, escape hatches, and remedies" (remedy in the error message), "A fix lands in one of two callers that share a harness", "Restore the bug and prove the guard fires", "One fact derived twice". Other sections not read.
- code-check-r.md (177187 bytes): headings read: "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising", "`tryCatch()` nests its handlers", "Under `R CMD check`, tests run from a temp dir against the INSTALLED package", "A `skip_if_not()` skips only its own `test_that()` block", "`sort()` and `order()` collate by `LC_COLLATE`", "`tempfile()` lives in the session tempdir". About 125 not read.
- code-check-shell.md (124118 bytes): "git pathspec excludes: use the long form", "`git diff a..b` compares TIPS". About 95 not read.
- code-check-spatial.md (155517 bytes): none apply (no spatial code in the diff). Not read.

## The latest fix (bf15a80)

1. **Does publish_report_check() refuse everything the two old checks refused?** Yes, it refuses a superset.
   - The old pre-upload check (2fec813, discharge_publish.R:94-98) tested `grepl("^wet commit <built_at> ")`, `any(rep_head == tree_line)` and FAIL. The new one tests `startsWith` with the same prefix, which is equivalent because `built_at` is validated as hex at :73, so it holds no regex metacharacters. It also asks for exactly one tree line (`sum == 1`), which is stricter than `any`, keeps the same FAIL test, and adds the heading test.
   - The old rewrite check (2fec813 lib:51-60) is the new body verbatim, with the heading literal replaced by `publish_live_heading`. BUILD writes that same constant (discharge_publish.R:717).
   - Ran tests/testthat/test-publish_report_live.R in a scratch copy with NOT_CRAN=true: 29 passed, 0 failed, 0 errors, 0 skipped.
2. **Do the error messages lead to the right action in both callers?**
   - Before the upload, the first message ("commit the build's report ... first") is the right remedy.
   - After the upload that message would be the wrong remedy. It cannot fire there, though (see point 3): the rewrite reads a file equal to the one already checked, for the same `cat_local`.
   - The heading message names no remedy in either caller. It fires only on a hand-edited report, because BUILD always writes the heading and the line. It is not misleading, so I am not flagging it.
3. **HEAD's copy before the upload, the working copy at the rewrite.** The two are equal at the start of the run, because the clean-tree check at :61 covers `data/checks` (the location from `wb_report()`) and porcelain status also lists untracked files. Nothing between :94 and :139 writes to the report or runs git. A copy could differ only if something outside the script changed the file during the upload. A previous PUBLISH's uncommitted rewrite is refused at :61. Once that rewrite is committed, a rerun passes the pre-check: the tree line is unchanged and the live line still matches the heading regex.
4. **Anything else PUBLISH finds only after the upload.** I went through every raise after the first `put`:
   - aws put, list and delete failures; `wet_catalog(publish_url)`; `identical(cat_pub$md5, cat_local$md5)`; `wet_catalog_verify(cat_pub)`; and in `publish_report_live()`, the `verified` and digest refusals. All of these are about the live object, so they can only run after it is written.
   - `publish_report_check()`: covered by the call at :94.
   - `publish_live_line()` needs `cat_pub`'s `provenance$wet_commit`. `cat_pub` is the manifest just uploaded, byte-identical to the local one, whose `wet_commit` is validated at :73, so :73 covers it.
   - `stopifnot(identical(out[-i], lines[-i]))`: can never fail.
   - `writeLines`: a local file that the clean-tree check already found tracked and readable.
   - Downstream, `vd_published()` reads the rewritten report. What it needs from the report (FAIL-free, exactly one tree line with the live digest, the live-line regex including `live parts md5`, matching counts and commit) is either written by `publish_live_line()` or checked before the upload. The digest equality holds because `publish_report_live()` refuses unless the live digest equals the local one.

## Mechanism

The mechanism is a refusal that sits only in the post-write step ("Where the guard sits"). After bf15a80 no instance remains in the PUBLISH path: each raise after the upload either depends on the uploaded object or is covered by a check before the upload (:73, :94, :95). The pre-upload check is only as good as the clean-tree check at :61, because it reads HEAD's copy and the rewrite reads the working copy. That holds today, since :61 includes `data/checks`.

## Clean
No issues found.
