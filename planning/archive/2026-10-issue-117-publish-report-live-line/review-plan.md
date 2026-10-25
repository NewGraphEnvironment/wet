# Plan review (#117), Plan agent, 2026-10-25 (returned after Phases 1-2 landed)

Written here from the agent's reply (Plan agents cannot write).

- **Blocker, confirmed and fixed:** Phase 2 reopened #94. PUBLISH (`discharge_publish.R` rep_head check) and
  `publish_report_live()` tied the committed report to the on-disk tree only by `wet commit <built_at>` and no
  FAIL, so a tree rebuilt at the report's commit from other untracked inputs, uploaded under the older report,
  got that report certified with the new tree's digest. Fix: BUILD writes `tree parts md5 <digest>` of its own
  tree; PUBLISH refuses before uploading, and `publish_report_live()` before writing, unless the report carries
  the local tree's; `vd_published()` requires the report's tree digest to be the live one.
  Alternative offered (not taken, departs from the issue's mechanism): `vd_published()` compares live digest
  with the BUILD's tree digest and PUBLISH never writes the report.
- **Gap, fixed:** `publish_report_live()` compared md5 vectors; now compares `wet_catalog_digest()`.
- **Gap, noted:** a failed-verify PUBLISH writes nothing, so a BUILD line that already read N of N stands. That
  is correct (a republish of identical bytes) and the callers' `vd_verify()` before and after each read covers a
  read during a publish. Tested ("a republish of identical bytes").
- **Ordering, noted:** the rewrite runs after S3 changed; on a refusal, rerun PUBLISH (every part skipped).
  Said in `publish_report_live()`'s header. The report is left dirty, so another PUBLISH and `vd_commit()`
  refuse until it is committed; the closing message says to commit it.
- **Acceptance, noted:** the new tests skip under R CMD check (scripts/ is build-ignored) and the repo has no
  check workflow, so they run under a local `devtools::test()` only.
- **Scope:** docs named (research :5, :84; CLAUDE.md; script header; comment above `pub_line`) — Phase 4.
- **Owed item:** confirmed. The one BUILD after merge also writes the tree digest; m4's tree will then name
  the merge commit while live names b4bbc50, so a PUBLISH of it re-uploads only the manifest.
