## Outcome

#57 built one per-segment table carrying both estimates, PCIC's routed flow (NewGraphEnvironment/fwapg#6) and wet's open water balance, labelled by `source` and `period`, with a logical `pick`. The pick is routed unless its mean annual flow is under 0.2 × the balance's, and only a segment on its watershed's own line can fall to the balance (`wet_source_pick()`, `routed_own_line_sql`). It is built by `scripts/segment_output.R` (run on the machine with the full province run) and scored at the gauges by `scripts/pcic_routed_compare.R`. CLAUDE.md's "Own estimates first" now publishes routed PCIC as the default where picked, with the balance kept as the independent yardstick.

What was learned:
- Far-low routed flow is systematic rather than a handful of gauges. A quarter of it is the Nechako Reservoir, whose PCIC outlets fwapg's crosswalk leaves unplaced (fwapg#24).
- The balance mapped through `fwa_streams_watersheds_lut` is a segment's own flow only on its watershed's own line. Code review found that in four rounds. Side channels were first flipped to the main river's flow; an edge-type list then missed connectors sitting in other streams' watersheds; routed runoff was taken over another line's area; and the prose overreached twice. It ended with an enumeration of every use of the lut watershed.
- Hydromosaic serves 9 CMIP6 GCMs × two SSPs, and daily PNWNAmet, on the same `subid`s, so a 1981–2010 build and projections are a parameter in fwapg's job (fwapg#25).

The durable verdict is in `research/water_balance_method.md` §0 ("Per-segment flow carries both estimates…").

## Measurement

- **Gauges** (`data/checks/pcic_routed_compare_20260717.txt`, the pick decided against the held-out balance): mean absolute error 22.9 % for the pick at the 290 routed covers (routed 24.1 %, balance 27.6 %). At all 315: pick 23.2 %, balance 27.5 %. 7 gauges fall to the balance, which is closer at 6.
  - The first rule (side channels flipped too) scored 22.3 %. It looked better only because three whole-river gauges sit on side channels; it was wrong for the segments themselves.
- **Province** (`data/checks/segment_output_20260717.txt`):
  - 4,907,441 segments; 369,217 have no lut row and no value; 3,374,133 have both sources.
  - Routed is picked on 3,152,838 (69.6 %); 224,199 segments fall to the balance (6.6 % of those with both), 26.7 % of them in the Nechako groups. Of 72,242 off-line segments with both sources, none flips.
  - Fraser flips went 123,394 (plan-mode measure, the first rule) → 118,119 (side channels kept) → 114,516 (own line).
- **Invariants** (checked on the built table):
  - 43,901,481 routed rows (13 × 3,377,037);
  - one pick per segment over 13 months;
  - balance months sum to the annual exactly; routed months sum to 0.93–1.02 of the annual;
  - routed annual equals `routed_annual()` at 351 gauge segments (1e-13).
- **Wrong turns kept:**
  - "the lut maps tributaries to the parent", disproved in plan mode (99.7 % of low segments were on their own stream);
  - two partial exemptions before the structural predicate.

## Evidence

- Tracked reports: `data/checks/segment_output_20260717.txt`, `data/checks/pcic_routed_compare_20260717.txt`.
- Run logs: `data/logs/57/segment_output*` on the build machine (gitignored).
- Reviews: `review-plan.md`, `review-round*.md` in this directory.

Closed by: PR (this branch, `57-per-segment-flow-from-either-source-rout`)
