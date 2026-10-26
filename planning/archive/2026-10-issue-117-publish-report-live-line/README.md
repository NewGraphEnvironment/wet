## Outcome

After an upload, PUBLISH (`WET_PUBLISH=1 Rscript scripts/discharge_publish.R`) now rewrites the publish report's live-build line itself, once its anonymous verify passes (`publish_report_live()` in `scripts/discharge_publish_lib.R`), and leaves the report for a commit. The second full BUILD that followed every republish only to rewrite that line (about 3.5 h on the machine with the full runs) is gone. BUILD and PUBLISH write the line with one function (`publish_live_line()`), which now ends in the md5 of the live parts' `<key> <md5>` lines (`wet:::wet_catalog_digest()`), and `vd_published()` requires it, closing #94: a report naming the live commit and part count over other parts is refused. The plan review found that, as approved, PUBLISH could certify an older committed report for a tree rebuilt at the same commit from other inputs, which would have reopened #94. So the BUILD also records `tree parts md5` of its own tree, which PUBLISH requires before uploading, the rewrite requires again, and `vd_published()` requires to equal the live digest. Code-check round 2 found that the branch's own edit to `scripts/vignette_data_lib.R` would have made the next BUILD refuse and demand a full table rerun; that file feeds no table and is now in `publish_own`. Round 3 found that the report's layout was checked only after the upload, and that the pre-upload tree-line check was looser than the rewrite's; both are now one `publish_report_check()`, run before the upload and again at the rewrite. The durable description is `research/discharge_publish.md` (Status, and the paragraph on the vignette data guards).

## Measurement

- `devtools::test()`: 1411 pass, 0 fail. `tests/testthat/test-publish_report_live.R` has 29 expectations and skips under R CMD check, because `scripts/` is build-ignored.
- Mutation table (`findings.md`): removing each of the ten guards one at a time turns a named test red.
- `vd_published("20260717")` against live b4bbc50 (512 parts, digest `0f4f8caa89691c2196a551c11b345918`) refuses the tracked report, which predates the digests. This is expected.
- The BUILD's code-changed guards replayed empty on the branch: `git diff --name-only 28105a3|f99df25 -- R scripts`, with the exclusions applied.
- `/code-check branch`: four rounds, ended by an enumeration of the 11 refusals after PUBLISH's first upload. With the plan review, that is five reviewer agents.
- PUBLISH itself was not run against S3. Its first live run is the next republish.

## Owed

- The tracked report's line has no digest, and this branch changes `scripts/`, so PUBLISH would refuse the
      current tree anyway. Until the next BUILD on m4 (about 3.5 h) writes the new line, the vignette data
      scripts refuse. Nothing needs them now; the next republish carries it. Reported, not run.
  (Not urgent, and no BUILD is needed for its own sake: the BUILD that comes with the next republish writes both md5s, and from then on PUBLISH keeps the line current. Run one sooner only to regenerate the vignette data before that republish; its parts are byte-identical to live b4bbc50, so its report passes `vd_published()` with no upload.)

Closed by: PR for #117 and #94 (see `git log`)
