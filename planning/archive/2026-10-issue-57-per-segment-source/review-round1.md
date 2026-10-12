# Code-check round 1: branch c3f8c69...HEAD (#57)

Reviewer: subagent, 2026-10-11. Read in full: R/wet_source_pick.R, its test, scripts/segment_output.R,
scripts/pcic_routed_compare.R, scripts/pcic_routed_lib.R, scripts/wb_output.R, scripts/wb_fit_lib.R,
scripts/wb_score_md5.R, the consumer lines of data-raw/segment_vignette_data.R, both tracked reports, and the
CLAUDE.md / research / vignette edits.

## Findings

- **[bug, wrong claim] research/water_balance_method.md:91** says flips are "57 % of double-line river
  segments (1100)". In the FWA, 1100 is "Single line blueline, secondary flow", which is a side channel
  (`whse_basemapping.fwa_edge_type_codes`). Double-line river main flow is 1250, and that class flips only
  0.6 % (`data/checks/segment_output_20260717.txt`, edge-type table: 1250 has 143,035 both and 828 flipped).
  So the sentence turns the result around: the double-line main stems almost never flip, while the side
  channels flip 57 %. The same research bullet also calls the 50,280 no-lut 1100 segments "type 1100"
  without saying what they are, which is fine. The double-line wording is the only mislabel.

- **[fragile, wrong numbers by design] vignettes/segment-discharge.Rmd:275-279, and wet_source_pick's
  rationale in R/wet_source_pick.R:5-8.** The guidance says that where routed flow is under a fifth of the
  balance, "a side channel ... There, use the balance". In the per-segment table, the balance reaches a side
  channel through `fwa_streams_watersheds_lut`, so the side channel carries its fundamental watershed's value.
  Usually that value is the main river's whole flow. I sampled 455 type-1100 segments in LFRA, MFRA, UFRA,
  THOM and BULK, and 301 of them share their lut watershed with a 1000 or 1250 main-flow segment on another
  blue_line_key.
  - The evidence offered for the rule is that the balance is closer at 9 of 10 calibration gauges. A gauge
    measures the whole river, so the full-river value is right there. That evidence does not carry to a
    side-channel segment itself. On the 13,859 flipped 1100 segments (and 14,955 flipped 1350 segments),
    `pick` assigns the main stem's full discharge to a secondary channel, which double-counts that flow
    beside the main stem.
  - This is not a code defect, because the rule does what it says. But the vignette and the function
    comment state that the balance is the better choice for side channels, and nothing measured here
    supports that. Either scope the guidance to gauges, reservoirs and misplaced outlets, or exempt
    secondary-flow edge types from the flip.

- **[minor wrong claim] research/water_balance_method.md:91**: "PCIC has 487 outlets there; all but 4 are
  left unplaced (`broken_chain`)". Measured on the local fwapg (`fwapg.pcic_outlets` ∩ the four group
  polygons, joined to `whse_basemapping.pcic_fwa_crosswalk`), 479 are `broken_chain` and 4 (UEUT) are
  `no_candidate`. planning/active/findings.md:63 has this right; the research sentence drops it.

## Checked and found consistent (no action)

- Every count in research §0's #57 bullets agrees with `segment_output_20260717.txt`:
  - 4,907,441 segments; 369,217 without a lut row, and the edge-type breakdown 1400/1450/1100 = 50,280,
    re-queried on the local fwapg.
  - 3,374,133 / 2,904 / 1,155,806 by source; 3,101,619 / 1,431,224 / 275,418 by pick; 8.2 %, 68.4 % and
    22.0 %; GUIC 69 %; 5.1 % at order 1, 7.1 %, 1.0 %.
  - The neither total, 374,598 = 5,381 + 369,217.
  - The routed-unplaced count, 3,377,037 = 3,374,133 + 2,904.
- Every gauge figure agrees with `pcic_routed_compare_20260717.txt`: 290 and 315 gauges; 22.3, 24.1 and
  27.6; 22.6 and 27.5; 10 flips with the balance closer at 9; 08LG056 at 19 against 55 observed.
- The routed monthly/annual depth ratio is 0.928–1.018, median 1.003, re-queried over all 3,309,111
  segments with nonzero routed flow.
- The routed table's primary key (linear_feature_id, month) rules out duplicate months, so `n12 == 12`
  means a complete year. There are 0 null flows, and the minimum q is 0, so the negative-flow stop is safe.
- `wet_source_pick` on zero-length input returns character(). Its test file passes 12 of 12 under
  NOT_CRAN=true.
- segment_vignette_data.R reads the routed report with `grep("^all +")[1]`, which the new
  pick section does not shadow.
- segment_output.R row assembly is consistent: the bm indexing order matches the rep() layout; there is one
  pick per (segment, month); a NULL rows_b or rows_r is handled; and the rename is checked.
