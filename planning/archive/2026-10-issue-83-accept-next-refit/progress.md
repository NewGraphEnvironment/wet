# Progress — wb_fit_accept.R cannot accept the next refit: the shipped fit is scored with its pooled variant fixed (#83)

## Session 2026-10-15

- Plan-mode exploration — phases approved by user (rule: each fit as it ships; scope: also allow an AET switch)
- Created branch `83-wb-fit-accept-r-cannot-accept-the-next-r` off main
- Scaffolded PWF baseline from issue #83 with approved phases
- Next: start Phase 1
- Phase 1 (04bec81): `wb_fit_accept.R` compares each fit as it ships; rule pre-registered in research §0
- Phase 2 (bd6ef14): sandbox cases and the line-35 mutant, all as expected (findings.md)
- Phase 3: CLAUDE.md, follow-up #85 filed (publish manifest AET text, pooled test on the old AET), publish stop now points at #85, #83 body edited with the outcome
- Note: any change under `scripts/` makes `discharge_publish.R`'s next build refuse until `wb_output.R` and `segment_output.R` rerun (its code-change guard excludes only the publish code). This branch triggers that like any other scripts change.
- Code-check, 4 rounds: R1 874d9a7, R2 e020e26, R3 ceb28bb, R4 clean. Each of rounds 2 and 3 found a defect inside the previous round's fix. The loop ended by enumeration: round 3's input table, and `keep_adjust` as the one switch, confirmed by round 4.
- #83 body outcome rewritten to match the code as built
