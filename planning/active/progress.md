# Progress — Read routed PCIC from fwapg's pcic schema (#101)

## Session 2026-10-18

- Plan-mode exploration — phases approved by user ("go all phases to PR")
- Created branch `101-read-routed-pcic-from-fwapg-s-pcic-schem` off main
- Scaffolded PWF baseline from issue #101 with approved phases
- Next: Phase 1 (load the pcic schema on m1)
- pcic schema loaded on m1 (both runs, 19:36-19:42 UTC); m4 already held both; 0 rows differ from the frozen table on either machine
- Phases 2-4 landed (34c46e6, 7441e18, f0ae0be); plan review folded in
- code-check round 1: routed month 0 follows row order; user decided month order, no upload, republish at #103 (3576301; issue body edited)
- code-check round 2: reader ordered too (2e49dd9); loop ended by enumeration of the 8 routed reductions
- Side question: same class in wet#76 (body updated) and link (link#356 filed)
- pcic_routed_compare.R rerun on m1: report differs only in the wet commit and routed: lines
- m4 segment_output.R (20:08-20:15 UTC, 433d036): report differs only in wet commit and routed: lines; routed month 0 moved in 384,680 of 3,377,037 segments (11.4 %, max 1.81 ulp), every other value identical, 14 of 23 parts byte-identical (m4 `data/logs/101/segcmp.txt`); committed 1d0faf8 from m4
- m4 BUILD (to 20:25 UTC): every check ok, 555,857,796 values compared, 0 differing; 58 of 67 parts identical to acb820f; nothing uploaded; committed 1fc4109 from m4
- Research and issue corrected from 8 % to the measured 11.4 %
