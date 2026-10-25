# Progress — Have PUBLISH update the publish report's live-build line (#117)

## Session 2026-10-24

- Plan-mode exploration — phases approved by user
- Created branch `117-have-publish-update-the-publish-report-s` off main
- Scaffolded PWF baseline from issue #117 with approved phases
- Next: start Phase 1

## Session 2026-10-25 (UTC)

- Phase 1 (10125e1): `wet:::wet_catalog_digest()`; `publish_live_line()` shared by BUILD; `vd_published()` checks the live digest
- Phase 2 (2f1833b): `publish_report_live()`, called by PUBLISH after its verify
- Plan review returned after Phase 2 (`review-plan.md`): blocker confirmed (PUBLISH could certify a report for another tree at the same commit); fixed with `tree parts md5` in the report, required by PUBLISH, `publish_report_live()` and `vd_published()` (d59c77f), with tests and the mutation table
- Phase 4 docs (a5ef3d3); lint fixes (83da9fe). `devtools::test()`: 1411 pass, 0 fail
- `vd_published("20260717")` against live b4bbc50 refuses the tracked report (no digests yet), as expected
- `/code-check branch` round 1 spawned 04:47:48 UTC
