# Progress — Simplify the segment-discharge article (#71)

## Session 2026-10-14

- Plan-mode exploration — phases approved by user
- Created branch `71-simplify-the-segment-discharge-article-d` off main
- Scaffolded PWF baseline from issue #71 with approved phases
- Next: start Phase 1
- Phase 1: `data-raw/segment_vignette_map.R` rewritten and run (log `data/logs/71/`). Picks read from the live parts in 17 s; drawn main-flow order >= 5: routed 212,681, balance 70,315, none 1,557 segments. Liard basin: 0 routed, 716,213 balance, 38,270 none; Nechako Reservoir groups: 1,046 routed, 59,821 balance, 7,047 none. `segment_map.rds` 104 KB (was 147). Registry: `pick_source` and `gauge` added; the old layers go with the article rewrite (Phase 4), since the current article still reads them.
- Phase 2: `data-raw/segment_vignette_data.R` trimmed and run. Province counts from `data/checks/segment_output_20260717.txt`, held to the reader counts and fwapg: FWA 4,907,441; neither 374,598 (369,217 with no lut watershed); picked routed 3,152,838, balance 1,380,005, 224,199 of them because routed is far low. Routed check at the gauges' 289 segments: none differing. Bundle 129 KB of 500.
- Phase 3: segment tests rewritten for the new shapes; the file passes. Mutation table in a scratch copy: a fourth class, a map from another build, counts that do not add up, picks off the reader's, a missing region: each turns one test red; restored, none red.
