# Progress — Per-segment flow from either source: routed PCIC where placed, open balance elsewhere (#57)

## Session 2026-10-11

- Plan-mode exploration; phases approved by user (pick rule per segment at 0.2, both rows + `pick`, `period` per row)
- Created branch `57-per-segment-flow-from-either-source-rout` off main
- Scaffolded PWF baseline from issue #57 with approved phases
- Next: start Phase 1

- Phase 1: `wet_source_pick()` (internal) with tests written first; they errored before the function existed and pass after (4 blocks, 12 expectations). `far_low` has no default, so `routed_far_low` stays the one definition.
- Mechanism change for Phase 2: m4 holds the same fit (`fits.rds` md5 a780320…) and the same routed table (fingerprint 40,524,444 rows, 3,377,037 segments, total 178035348.248310, as #58's report), plus the full `upstream/` with wet's accumulated areas. The build runs on m4 and only the tracked report comes back, instead of copying 786 MB of output to m1.
- Phase 3: `pcic_routed_compare.R` scores the default pick, deciding against the held-out balance so the pick uses no observed flow. Pick 22.3 % mean abs at the 290 (routed 24.1, balance 27.6), and 22.6 % at all 315 (balance 27.5). 10 gauges fall to the balance, which is closer at 9. The rest of the report is unchanged byte for byte, apart from the commit line and the new per-gauge `pick` column.
- Phase 3: Nechako attributed to fwapg#6 placement (487 PCIC outlets in the four groups, 4 placed; the rest `broken_chain`, anchored in CHES). Filed fwapg#24 (Nechako) and fwapg#25 (model/scenario/period parameters: 1981–2010 first, CMIP6 later).
- Phase 4: CLAUDE.md now says PCIC's routed flow is published, cited and labelled, as the default where it beats the balance; the balance stays the independent yardstick; "model code does not ship" now reads "in place of our own" (plan review G10). Added `segment_output.R` to Architecture. Vignette guidance names the default pick and its exceptions, prose only; it rendered with its word-cap and named-on-map guards passing.
- Phase 2 run on m4 (third attempt; basins 800 and 999 needed guards). Report `data/checks/segment_output_20260717.txt` at 3a204a7: 3,374,133 segments with both sources, 275,418 flips (22 % Nechako), Fraser 123,394 as measured in plan mode. Post-run checks on m4 (scratch `segment_check.R`):
  - 43,901,481 routed rows = 13 × 3,377,037;
  - one picked source per segment (4,532,843), constant over 13 months;
  - balance months sum to the annual exactly; routed months 0.93–1.02 of the annual;
  - routed annual = `routed_annual()` at the 351 gauge segments (max diff 1e-13).
- GUIC (69 % flips) attributed to PCIC's runoff: outlets placed and carrying PCIC's own flow; fwapg's older unrouted table is far low at 08LG056 too.
- Phase 4: research §0 entry for #57; #57 and #7 bodies edited. #57's body was blanked for about a minute by a failed `gh issue view` and restored (findings, Errors).
- Tests: 36 files, 876 passed, 0 failed, 1 skipped.
- `/code-check branch` round 1 (`review-round1.md`): no code defects. Three prose and rule findings, all verified against fwapg before acting:
  - edge type 1100 is secondary flow (side channels), not double-line river;
  - side channels share the main river's lut watershed (301 of 455 sampled), so flipping them to the balance double-counts the main stem;
  - the Nechako outlet counts left out the 4 `no_candidate`.
  Fixed by a rule correction (side channels keep routed: `routed_secondary_edges`, `wet_source_pick(secondary =)`, tests first), then both reports rerun: gauges 22.9 % pick at the 290 (routed 24.1, balance 27.6), 23.2 % at 315; province 244,407 flips, Nechako 24.6 %. The m4 invariants check passed again. Research, CLAUDE.md and the vignette are corrected, and the vignette re-rendered.
- `/code-check branch` round 2 (`review-round2.md`): **a defect inside round 1's fix**. The side-channel edge-type list missed connections through lakes that sit in the receiving river's lut watershed (1410/1450; Deadman River in Kamloops Lake), and the list was a proxy for the property. Fixed with the property itself, `routed_own_line_sql` (`blue_line_key = watershed_key` and the watershed's own code), as `wet_source_pick(own_line =)`, tests first.
  - Enumeration, the terminating step: of 4,538,224 lut segments, 96,431 are off their own line (58,705 secondary, 8,126 another code, 29,600 other connections). The report's cross-tab shows 72,242 of them have both sources and 0 flip.
  - Gauges unchanged (22.9 % / 23.2 %). Province: 224,199 flips, Nechako 26.7 %. The m4 invariants check passed.
  - Prose corrected: Nechako shares are of segments with both sources; 08KH006 is "unresolved" in #58.
- `/code-check branch` round 3 (`review-round3.md`). The mechanism behind rounds 1–3: **treating a segment's lut watershed as the segment's own place on the network**. Round 3 found two more places it reaches:
  - routed `runoff_mm` over the lut watershed's area off the own line, now NA there (72,242 segments, matching the report's off-line count);
  - wrong prose ("connections through a lake": the off-line class is side channels, 1410 network connectors and 1450 waterbody connections).
  Edge-type and order rates now divide by own-line segments only.
  - Enumeration: every use of the lut watershed in the diff:
    1. the balance value: stored, never picked off the line, documented;
    2. the routed runoff area: NA off the line;
    3. the gauge pick's `own_line`: the same lut and the same SQL, verified for all 352 stations by round 3;
    4. basin assignment: top-level only.
  - Residual, accepted and documented: on its own line, a segment upstream within its watershed (localcode differs; 53,833 segments) gets the downstream-end value. Round 3 measured that 46 Fraser flips might owe to it.
