# Progress — Per-segment flow from either source: routed PCIC where placed, open balance elsewhere (#57)

## Session 2026-10-11

- Plan-mode exploration; phases approved by user (pick rule per segment at 0.2, both rows + `pick`, `period` per row)
- Created branch `57-per-segment-flow-from-either-source-rout` off main
- Scaffolded PWF baseline from issue #57 with approved phases
- Next: start Phase 1

- Phase 1: `wet_source_pick()` (internal) with tests written first; they errored before the function existed and pass after (4 blocks, 12 expectations). `far_low` has no default, so `routed_far_low` stays the one definition.
- Mechanism change for Phase 2: m4 holds the same fit (`fits.rds` md5 a780320…) and the same routed table (fingerprint 40,524,444 rows, 3,377,037 segments, total 178035348.248310, as #58's report), plus the full `upstream/` with wet's accumulated areas. The build runs on m4 and only the tracked report comes back, instead of copying 786 MB of output to m1.
- Phase 3: `pcic_routed_compare.R` scores the default pick, deciding against the held-out balance so the pick uses no observed flow. Pick 22.3 % mean abs at the 290 (routed 24.1, balance 27.6), and 22.6 % at all 315 (balance 27.5). 10 gauges fall to the balance, which is closer at 9. The rest of the report is unchanged byte for byte, apart from the commit line and the new per-gauge `pick` column.
