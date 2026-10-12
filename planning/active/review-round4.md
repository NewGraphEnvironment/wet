# Review round 4 (#57): fixes 1b6167e and 8e94d15, in the branch c3f8c69...HEAD

Reviewed: scripts/segment_output.R, R/wet_source_pick.R, scripts/pcic_routed_lib.R,
scripts/pcic_routed_compare.R, tests/testthat/test-wet_source_pick.R, research §0 #57 bullet,
CLAUDE.md:36, vignettes/segment-discharge.Rmd:272-283, data/checks/segment_output_20260717.txt.
Probes were read-only queries against local fwapg. Nothing in the repo was edited except this file.

## Findings

- **[severity: bug, wrong claim]** vignettes/segment-discharge.Rmd:278 ("A side channel or a connector
  line keeps routed flow, which is its own water"). The same unqualified "connectors" appears in
  research/water_balance_method.md:83 ("side channels and connector lines keep routed"), CLAUDE.md:36
  ("off a watershed's own line (`routed_own_line_sql`: side channels, connectors)"),
  scripts/segment_output.R:30 and :260, and so in the tracked report's line 7. Round 3's fix swapped
  "connection through a lake" for "connector", and the new word has the same defect in the other
  direction: most connectors are **on** their own line, so the pick can flip them.
  - DB: of the segments with all 12 routed months and a lut row, type 1410 is 47,664 on its own line
    and 4,616 off it. 91 % of routed network connectors can fall to the balance.
  - The tracked report's own-line table (outside the Nechako groups) shows 1410: 47,326 with both
    sources, **5,764 flipped (12.2 %)**. That is the highest rate of any large edge type. Type 1400
    flips at 11.5 % and type 1450 at 5.3 %.
  - research:104 itself states "12.2 % of network connectors (1410)" flip, which contradicts research:83
    and the vignette.
  - The qualified wording in R/wet_source_pick.R:12 and scripts/pcic_routed_lib.R:85-86 ("network
    connectors that sit in another stream's watershed") is correct.
  - Fix: say "a side channel, or a connector that sits in another stream's watershed" (or name only
    side channels in the reader guidance), and qualify the CLAUDE.md, script-comment and report-label
    wording the same way.

- **[severity: fragile, wrong number in tracked report]** scripts/segment_output.R:205,272 →
  data/checks/segment_output_20260717.txt:15 says "routed segments with no accumulated area (runoff_mm
  NA): 0". Since 1b6167e, routed `runoff_mm` is also NA on every routed segment off its own line.
  - DB: 72,242 routed segments are off their own line (67,626 + 4,616 of type 1410, equal to the
    report's off-line "both" count), so 72,242 × 13 routed rows carry NA `runoff_mm`.
  - The line now reads as "no routed runoff_mm is NA", which is false for the table it describes.
  - `routed_no_area` counts only a missing area. Either count `!own_line` as well, or relabel the line
    so it no longer implies the NA total.

## Checked and correct

- **runoff_mm NA off the line** (segment_output.R:177). `j` indexes every row of `rq`: month 0, which
  comes from `sr$q_routed`, and months 1-12 from `rt`. So `ifelse(sr$own_line[j], 1, NA)` applies per
  row, for all 13 months. `own_line` is never NA (coalesce, and the stopifnot at :109). NA × numeric
  gives NA_real_, so the column type holds. On the own line the value is unchanged.
- **Own-line rate tables.** `by_class` (:237) now filters `seg$own_line`. The report's tables
  reconcile:
  - Edge-type "both" sums to 3,241,814, and so do the stream-order rows.
  - Flips outside the Nechako groups are 164,385 in both tables. With the Nechako groups' 59,814,
    that makes 224,199.
  - The own-line and off-line rows give 3,301,891 + 72,242 = 3,374,133, and 224,199 / 3,301,891 is
    6.8 %.
- **Enumeration of lut-watershed uses.** Grepped the diff for watershed_feature_id, area_m2,
  upstream_area, own_line, _lut, watershed_key and wscode. The uses are:
  - `seg` SQL (:102-108) and the gauge `edge` SQL (pcic_routed_compare.R:51-56): own_line, item 3.
  - basin assignment (:129-131): item 4.
  - the balance value (:139-140): item 1.
  - area_m2 (:141, :177): item 2.
  - `routed_no_area` (:205): the report finding above.
  - n_no_ws and n_ws_no_basin (:248-249): counts only.
  - by_class and the own-line table: own_line as a filter.

  The gauge script's `routed_mm` (pcic_routed_compare.R:69) divides by the gauge's upstream area. That
  area is the station's own catchment, compared against observed flow, so it is not a lut-as-position
  error. Its pick compares two depths over one area, so the result is the same as comparing flows.
  Every other use is covered by the list, and none is still wrong.
- **Off-line split** (DB, by edge type × blue-line match × wscode match). The split reproduces:
  - secondary types 1100, 1150, 1300, 1350 and 2300: 58,705;
  - non-secondary with another wscode: 8,126, of which 7,218 are 1410 and only 1,024 are in any
    waterbody;
  - the rest: 29,600, which is 26,660 of type 1450, 2,901 of 1475 and 39 of 1410.
  - The sum is 96,431. The Deadman River example holds: linear_feature_id 703310082, type 1450,
    blue line on main, wscode is the Thompson's.
- **Research bullet against the report.** These all match: 4,907,441; 4,538,224; 369,217;
  3,374,133 / 2,904 / 1,155,806; 3,152,838 (69.6 %) / 1,380,005; 224,199 (6.6 % of segments with both);
  Fraser 114,516; Nechako 26.7 % (LEUT 97.4, UEUT 99.1, UNRS 98.3, LNRS 97.1); GUIC 68.8; 72,242 off
  line with 0 flips; edge rates 5.1 / 5.1 / 0.6 / 12.2 / 11.5 / 5.3; order 1 5.5 % and order 7
  0.9 %. The 1410 contradiction is the vignette and line-83 finding above.
