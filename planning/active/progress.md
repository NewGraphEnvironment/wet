# Progress — Segment discharge article: reorder for readers, define terms, recommend an estimate, map every named gauge (#39)

## Session 2026-10-06

- Plan-mode exploration; the draft parked in the issue body was re-verified against the code and approved
- Created branch `39-segment-discharge-article-reorder-for-re` off main
- Scaffolded PWF baseline from issue #39 with approved phases
- Next: start Phase 1
- Phase 1 scripts: fwapg scored at every calibration gauge, gauge lon/lat and snapped segment, parity as a one-row summary; map layers for the Salmon River context (rivers incl. the gauges' own, lakes, towns), PCIC coverage outline (groups with >= 50 % valued rows) and hydrologic zones with names; registry rows
- Plan review (review-plan.md) and /code-check rounds 1-4 (review-round1..4.md): edge-type filter dropped the large rivers; invalid lakes after simplify+snap; "covered" let 11 grid-edge Liard groups in; 08KC003's order-5 river missing; then guards that tell the coverage rule apart. Round 4 enumerated every layer and value against its purpose.
- Rebuilt both bundles (456 KB of 500); tests 94 pass. **Pre-set rule fired** (5.03-point gap at 168 gauges, findings.md); recommendation held for the user, other phases continue. Old vignette shimmed to the one-row parity summary.
- Phase 2 article reordered (1,427 words, cap 1,600): units example and terms with checked links; scored comparison figure and table; province map, error histogram; Salmon River two-panel map framed to all five gauges and the towns they are named for; Bulkley map, table and worked example (full fit vs held out); limits; how it is built. Greedy label placer (gauges first, avoids points, labels, scale bar, frame). Named-station guard proven to fire (mutation: dropping 08KC001 from the frame record stops the build).
- Provenance gained fwapg_order8 (13,883 segments of order >= 8 in coverage, 38 valued); research/water_balance_method.md gained the in-coverage score and the rule outcome.
- Waiting on the user: the recommendation (rule fired). The vignette records rule_gap and does not assert the rule until decided.
