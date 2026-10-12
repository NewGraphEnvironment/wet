# Review round 3 (#57): branch c3f8c69...HEAD (40c70b5)

Reviewed: R/wet_source_pick.R, its test, scripts/segment_output.R, scripts/pcic_routed_compare.R,
scripts/pcic_routed_lib.R, scripts/wb_output.R, the vignette list, CLAUDE.md, research §0 bullet.
Probes against local fwapg and the m1 bundle's month-0 balance output for basins 100 and 400
(scratch scripts in the session scratchpad; nothing in the repo edited).

## The mechanism

Every defect so far comes from one assumption: **that a segment's lut watershed stands for the
segment's own position on the network.** The balance is defined at a watershed's
(wscode, localcode), its downstream end. fwapg builds `fwa_streams_watersheds_lut` by matching a
segment's (wscode, localcode) to a watershed's, and where none matches it falls back to the
watershed under the segment's midpoint (`fwapg/load/fwa_streams_watersheds_lut.sql`). So the
watershed is the segment's position only when the segment's blue line is the main line and its
wscode *and* localcode equal the watershed's. Side channels (blue line) and other-code connections
(wscode) were the round-1 and round-2 instances. `routed_own_line_sql` now tests blue line and
wscode but not localcode.

Lut segments by blue line / wscode / localcode match (DB, 4,538,224 total, which matches the
report): own line with localcode equal 4,387,945; **own line with localcode different 53,848**;
off line 96,431 (88,839 by blue line, 7,592 by wscode only). Research's 58,705 / 8,126 / 29,600
split reproduces exactly. No lut-joined segment has a NULL wscode, blue_line_key or watershed_key,
so `coalesce(..., false)` only touches segments with no lut row, which have no balance. It cannot
exempt or include a wrong segment.

Where the assumption reaches:

1. **The pick.** Fixed for blue line and wscode. The localcode residual is small: 53,833 own-line
   segments have their watershed downstream of them on the same line. In the Fraser, 1,911 of
   these flip (16 % against 11.4 % for localcode-equal segments). Of those 1,911, only 46 carry
   routed flow under 0.2 x PCIC's own routed flow at the watershed's code-matched segments, so at
   most about 46 flips come from the mapping, and 28 of them would not flip against the
   watershed's position. Basin 400: 45 such flips, none from the mapping. This falls inside the
   accepted downstream-end mapping. Not reported as a finding.
2. **`runoff_mm` on routed rows: not fixed** (finding 1).
3. **Balance rows on off-line segments.** They carry another line's flow under source
   `wet_balance`, with pick FALSE. This is the accepted, documented mapping.
4. **The gauge pick.** It uses the same lut. `wet_station_snap()` takes `watershed_feature_id`
   from the lut of the snapped segment, and over all 352 stations the station watershed equals
   the lut watershed of its `linear_feature_id` (0 mismatches). 5 gauges are off line: 08KG003,
   08KH006 and 08MH141 (type 1100), and 10BB002 and 10BC001 (type 1450, no routed). So the
   research claim about the three type-1100 gauges is right.
5. **The report's tallies.** Reproduced exactly from the m1 balance and the DB: basin 100 has
   1,010,759 segments with both sources and 114,516 flips; basin 400 has 263,087 and 10,988. No
   code changed in R/ or scripts/ between the report commits (b92b1b0, fefe367) and HEAD.

## Findings

- **[severity: bug]** scripts/segment_output.R:138,174. The routed `runoff_mm` is the segment's
  own routed flow divided by `up$upstream_area_m2` of the segment's **lut watershed**. That is the
  same assumption the pick just dropped. Off a watershed's own line, the area is another line's
  accumulated area, for example the main river's under a side channel or a tributary connection.
  Because the pick keeps routed there, these are the **picked** rows. Measured in the Fraser: of
  12,020 off-line segments with both sources, 8,878 have a routed `runoff_mm` under 0.2 x the
  watershed's balance depth and 7,516 under 0.05 x, with a median of 1.4 %. (The ratio of the two
  `runoff_mm` values equals q_routed / q_balance, because both use the same area.) The province
  has 72,242 such segments, plus any routed-only ones off their line. A reader who maps the picked
  `runoff_mm` sees near-zero runoff depth on every side channel and connection.
  - The report's line "routed segments with no accumulated area (runoff_mm NA): 0" counts only
    that an area is present, not that it is the right one.
  - CLAUDE.md and research define the column as "over wet's accumulated area of the segment's
    watershed". That is literally true, but neither says the value is meaningless off the line.
  - Fix: `runoff_mm = NA` for routed rows where `own_line` is FALSE, or document it as not a
    depth there.
- **[severity: bug, wrong claim]** vignettes/segment-discharge.Rmd:278 ("A side channel, or a
  connection through a lake, keeps routed flow"). Research line 83 repeats it ("side channels
  and connections through lakes keep routed"), and so do CLAUDE.md:36 and
  scripts/segment_output.R:27 ("off a watershed's own line (… side channels, connections through
  lakes)"). The pick does not key on "through a lake", and in-lake connections flip.
  - Edge type 1450 in a lake on its watershed's own line: 29,383 such segments in the Fraser alone
    have both sources, and **2,046 of them flip** outside the Nechako groups. Province-wide about
    166,565 own-line 1450 segments have routed rows, and the report shows 8,877 type-1450 flips.
  - Conversely, the off-line "another code" class is mostly type 1410 network connectors (7,218
    of 8,126), and **none of the 1410s sit in a lake** (1410: 72,846 with no waterbody and 4,624
    in wetlands; DB). Only 283 of the 8,126 are in a lake.
  - So research:93's "mostly connections through a lake (1410, 1450)" is wrong. So are the code
    comments' "tributary connections through a lake" (R/wet_source_pick.R:12,
    scripts/pcic_routed_lib.R:85) as a description of the class, and the vignette's reader
    guidance. The Deadman example may still hold as one instance.
- **[severity: fragile, wrong number label]** research/water_balance_method.md:104 says "11 % of
  own-line connectors (1400, 1410)" and "4.7 % of 1450". Those are the report's edge-type rates,
  whose denominator is every segment with both sources, **on or off its own line**
  (segment_output.R:234, `k <- seg$both & !nechako`). Off-line segments cannot flip, so the
  quoted rate is not a rate over own-line connectors. Approximate own-line-only rates, from
  routed-row counts outside the Nechako groups: 1410 is 5,764 / ~47,345, about 12.2 %; 1450 is
  8,877 / ~166,565, about 5.3 %. Either drop "own-line" or compute the table over own-line
  segments.

Nothing else found. The NULL handling of `wet_source_pick()` and `own_line` is correct, and the
gauge script's `own_line` comes from the same lut mapping as the segment table. Every other
number checked against the reports and the DB matches:
- 4,907,441 segments, 369,217 with no lut row (1400 207,970; 1450 72,100; 1100 50,280);
- 3,374,133 / 2,904 / 1,155,806 by source;
- 3,152,838 picked routed (69.6 %), 224,199 flips (6.6 %), Fraser 114,516;
- Nechako 26.7 %, GUIC 68.8 %;
- 7 of 290 gauges flip, the balance closer at 6;
- mean absolute error 22.9 / 24.1 / 27.6 and 23.2 / 27.5;
- order 1 at 5.4 %, falling to 0.9 % at order 7.
