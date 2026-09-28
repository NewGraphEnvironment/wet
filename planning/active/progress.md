# Progress — Key the pre-#15 input caches on their builder code (#19)

## Session 2026-09-28

- Plan-mode exploration — phases approved by user ("go all phases to PR")
- Created branch `19-key-the-pre-15-input-caches-on-their-b` off main
- Scaffolded PWF baseline from issue #19 with approved phases
- Next: start Phase 1
- Phase 1: stale-name tests per builder; red on HEAD because the old-name file is returned
- Phase 2: `wet_cgiar_method`, `wet_dem_method` (replaces the `glo90v3_` literal), `wet_climr_method` hashed into the cache names
- Plan review (`review-plan.md`) folded in: zones keyed on grid key + zip md5 + `hz_method` (no longer derived from the CGIAR name), climr version in the normals key, `code_files` comment, Phase 4 acceptance made concrete
- Phase 3: zones and province script; `/code-check` 3 rounds, all Clean (`review-round1..3.md`)
- Tests: FAIL 0 PASS 464
- Next: Phase 4 re-run
