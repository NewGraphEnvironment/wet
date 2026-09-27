# Progress — Open province-wide runoff estimate: water balance after Chapman et al. 2018 (#11)

## Session 2026-09-26

- Plan-mode exploration; phases and decisions approved by the user
- Created branch `11-open-province-wide-runoff-estimate-water` off main
- Scaffolded PWF baseline from issue #11 with the approved phases
- Next: start Phase 1
- User: "go all phases to pr".
- Plan review (Plan agent): 12 findings, 3 blockers, all adopted; plan revised (planning/active/review-plan.md). Phases renumbered 1-8: province topology and sampling now precede the fits.
- Phase 1 committed: CGIAR AET, GLO-90 DEM, climr 1981-2010 normals, zones, manifest, ECCC check. /code-check ran 5 rounds (R1 7 findings, R2 2 inside R1 fixes, R3 4, R4 5, R5 enumeration + 1); ended by a content-as-function-of-key enumeration over every cache.
- Phase 2: 352 stations selected (251 regulated, 118 with no complete year (seasonal or gappy), 137 short dropped), 309 snapped within 10 % (median ratio 1.000), 97 sub-sub-drainages. Snapping is one fwa_indexpoint() LATERAL query (8 s), not fresh per station.
- Phase 2 /code-check, 4 rounds: R1 bigint id as integer64 (SQL cast; a typeof() guard proved unable to fail, replaced by a class check); R2 "seasonal" mislabel; R3 label enumeration: lake flag was "any lake within 500 m", "sub-drainage" was sub-sub-drainage, HYDAT named by tidyhydat version; R4 (inside R3 fix) 6 of 27 flagged were tributary lakes or an FWA-fault inlet. Now 21 lake outlets: a lake of at least 100 ha within 3 km, upstream on the network, draining 50-110 % of the gauge's area measured at the lake outlet. Ended by the R4 enumeration of all 27 flagged stations.
- Phases 3-8 committed (3658923, 67b2be3, f300710). Code-check on Phases 3-7: 4 rounds (R1 pooling structure / adjust crash; R2 zone-07 collapse inside the R1 fix, unfinished-run guard; R3 gate failure traced to the pooled "other" level; R4 post-hoc variant claims). Ended by R4 reproducing every report byte for byte and enumerating the research section 0 numbers against the tracked reports.
- Agents spawned on #11: 17 (2 research, 1 plan review, 14 code-check rounds), well past the ~5 budget; each round found real defects.
