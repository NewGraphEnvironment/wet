# Code review, round 2 (#57): branch c3f8c69...HEAD

Reviewed in full: R/wet_source_pick.R, tests/testthat/test-wet_source_pick.R, scripts/segment_output.R,
scripts/pcic_routed_compare.R, scripts/pcic_routed_lib.R, scripts/wb_output.R, the vignette prose, CLAUDE.md,
research/water_balance_method.md §0 (#57 bullet), against data/checks/segment_output_20260717.txt,
data/checks/pcic_routed_compare_20260717.txt and the local fwapg (read-only queries).

## What the round-1 fixes got right (verified)

- `routed_secondary_edges` = 1100, 1150, 1300, 1350, 2300 is exactly the set of secondary-flow codes in
  `whse_basemapping.fwa_edge_type_codes`. It is used at both places the pick is made (segment_output.R:148-149,
  pcic_routed_compare.R:74). No R/script code changed after either report's recorded commit.
- Side channels do get the main river's watershed. Their wscode equals the main river's (only 3 of 83,642
  type-1100 segments differ from their lut watershed's wscode), and the "301 of 455 / 203 of 390" figures
  reproduce when main flow is taken as edge types 1000 and 1250.
- Checked against the DB or the reports, and correct: 369,217 segments without a lut row (the edge-type
  breakdown, including 50,280 type-1100, sums exactly); every routed segment has a lut row (3,374,133 + 2,904 =
  3,377,037); 7.2 % flipped of both; 24.6 % Nechako; the gauge pick at 22.9 / 24.1 / 27.6 and 23.2 / 27.5;
  7 flips, 6 closer; monthly depth sums 0.928-1.018, median 1.003; 487 PCIC outlets in the four Nechako groups.
- segment_output.R's row assembly (balance rows indexed month-major, routed rows with month 0 at 365.25 days,
  the one-pick-per-segment-and-month assertion) is consistent. The vignette data script's parse of the routed
  report (`^all +`) still hits the intended line.

## Findings

- **[bug] scripts/pcic_routed_lib.R:83 / R/wet_source_pick.R:28 / scripts/segment_output.R:148-149: the
  side-channel exemption is incomplete.** The same mechanism (the lut gives a segment the receiving river's
  watershed, so the balance there is the whole receiving river's flow) also hits tributary *connectors* through
  a lake or a river polygon, and those are not secondary edge types.
  - Province-wide, segments whose lut watershed has a wscode different from their own: 7,218 of 77,470 type-1410
    (network connector, 9.3 %; 6,853 of them mapped to an *ancestor*, i.e. downstream river's, watershed) and
    803 of type-1450 (connection; 745 to an ancestor). Every other edge type has under 60.
  - Examples, all mapped to a lake watershed of the receiving river (`waterbody_key` set): 703310082, the Deadman
    River's connection in THOM (wscode 100.190442.712025), lut watershed wscode 100.190442 (Thompson), routed
    3.1 m3/s. The pick then flips it to the balance, the Thompson's flow. 703112422 (Necoslie River, STUL) and
    702685370 (QUES, routed 16.8 m3/s, mapped to 100.458399) are the same.
  - Size (proxy: the routed flow of the mapped watershed's own-wscode segments stands in for the balance, which
    is not in the DB): 489 type-1410 and 234 type-1450 ancestor-mapped segments carry routed flow under
    0.2 x their watershed's own river. Their median ratios are 13x and 58x, so the pick writes the receiving river's
    flow onto them, an order of magnitude or more too high. Another ~1,260 have routed flow but no own-wscode
    routed segment to compare with. That is a few hundred to ~1,000 of the 244,407 flips. It also inflates the 13.5 %
    and 14.4 % "flip %" for 1410 and 1450 in the report, which research §0 cites as "11-14 % of connectors"
    without attribution.
  - Adding 1410 and 1450 to `routed_secondary_edges` would be wrong: about 90 % of them map to their own
    watershed. The discriminator that catches these is the segment's wscode differing from its lut watershed's
    wscode (`s.wscode_ltree <> w.wscode_ltree`). Side channels share the main river's wscode, so that test misses
    them, and both conditions are needed.
  - Docs that claim the exemption covers the mechanism (CLAUDE.md:36, research §0 "Why side channels keep
    routed", the segment_output.R header lines 25-28, and the wet_source_pick.R comment) would need to follow
    whichever way this is settled.

- **[wrong number in prose] research/water_balance_method.md:97 (the "Nechako Reservoir groups" bullet).** It
  says "(LEUT 99.8 %, UEUT 99.4 %, UNRS 98.8 %, LNRS 97.2 % of their segments)". The report's flip % is of
  segments *with both sources*. Of all their segments the shares are 81 % (LEUT 6,939 / 8,536), 86 % (UEUT),
  93 % (UNRS) and 90 % (LNRS). It should read "of their segments with both sources".

- **[minor claim mismatch] research/water_balance_method.md:92.** It says "Three far-low gauges keep routed
  (08KH006, 08KG003, 08MH141): whole-river gauges snapped to a side channel, the snap #58 already attributes."
  #58's report attributes 08KH006 as "unresolved", not to placement or snap (no annual-table value). All three
  are on edge type 1100, so the side-channel description holds. Only "#58 already attributes" overstates the
  case for 08KH006. The pick keeps the -99.9 % routed error there against the balance's -25.1 %, which is
  accepted and reported in the 22.9 %.

No security issues found.
