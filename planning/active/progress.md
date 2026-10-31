# Progress — Move the Maxan pilot onto the site table and retire departure_pilot.R and departure_snow.R (#146)

## Session 2026-10-30

- Plan-mode exploration — phases approved by user
- Created branch `146-move-the-maxan-pilot-onto-the-site-table` off origin/main
- Scaffolded PWF baseline from issue #146 with approved phases
- Next: start Phase 1
- Phase 1 (3992872): parity helpers and test; mutation table in findings.md
- Phase 2 (d4fae1f): the site scripts' gates read the tracked reports
- Phase 3 (c644439): pilot scripts retired; comments, research provenance and CLAUDE.md repointed
- Phase 5: `departure_pcic.R` reads its box and target from `site_get("maxan")`; `identical()` to the old literals (checked by Rscript). Its header, the registered rule, is left as written (it states the same values); the comment sits at the assignment instead of a header line. Not rerun.
