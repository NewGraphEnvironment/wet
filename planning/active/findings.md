# Findings — Score PCIC routed flow at the gauges; replace the vignette's fwapg comparison (#58)

## Issue context

**If we do it:** the comparison behind #57's default pick is reproducible: a committed script, a tracked report, `research/water_balance_method.md` §0 and the segment vignette all score PCIC's routed flow instead of fwapg's old annual table. **If we never do:** the numbers live only in #57's body, and the vignette keeps comparing the balance against a product that fwapg#6 supersedes.

## Problem

On 2026-10-08, routed PCIC monthly flow (`whse_basemapping.fwa_stream_networks_discharge_monthly`, from NewGraphEnvironment/fwapg#6) was scored once, by an ad hoc query, at the shipped fit's 315 calibration gauges. At the 290 it covers:
- mean absolute error 24.4 % against the balance's 27.6 %;
- bias −0.1 % against +9.0 %;
- closer at 58 % of gauges.

The full table is in #57. No script or report produced it. The vignette's "Two estimates" table and `research/water_balance_method.md` §0 still score fwapg's annual table: 183 gauges, no rivers of order 8 and up.

## Proposed

Wait until fwapg#6 merges; its placement SQL is still being revised. Then:
- `scripts/pcic_routed_compare.R` → `data/checks/pcic_routed_compare.txt`:
  - each gauge's annual mean as the mean of the 12 monthly means at its `linear_feature_id`, in mm over wet's upstream area, against observed;
  - mean, median, within ±20 %, bias, and headwater / nested;
  - the uncovered gauges listed by sub-drainage;
  - the fwapg commit and the table's row count in the header.
- Revise `research/water_balance_method.md` §0 in place with the result, its caveats (PCIC partly in-sample; 1951–2012 against 1981–2010) and the coverage edge.
- Replace the vignette's fwapg comparison with the routed one: `data-raw/segment_vignette_data.R` reads the routed table, and the strengths-and-limits table is updated, including "Largest rivers", which routed flow now covers.
- Point #57 at the research section rather than carrying the numbers.

Blocked by NewGraphEnvironment/fwapg#6. Relates to #57, #5, #42.


## Plan-gate exploration (2026-10-09)

- fwapg#6 merged 2026-10-08 22:56 UTC into fwapg's `newgraph` branch (merge b41eb0b); #7's drainage check merged after it (d7191b1); newgraph tip 218a47f at exploration.
- The local routed table `whse_basemapping.fwa_stream_networks_discharge_monthly`: 40,524,612 rows, 3,377,051 segments; columns `linear_feature_id`, `watershed_group_code`, `month`, `q_m3s`. No build commit is recorded anywhere. Last analysed 2026-10-08 18:47 UTC (11:47 PDT), between 4929c8c (10:37 PDT) and 5e3cd07 (side-channel vote, 12:24 PDT), so it probably predates the merged placement. `fwapg.pcic_*` staging tables are still present (`rebuild_7.log`, 21:42 PDT, a #7 rerun).
- A parallel session has the fwapg checkout on branch `2-main-flow-tree-…` with an uncommitted rename (`pcic_crosswalk01_paths.sql` → `extras/blue_line_paths/`). Do not touch that checkout.
- Routed coverage at order >= 3: SALR 2,180 of 2,181 segments, BULK 7,748 of 7,755. BULK's vignette claim "outside PCIC's coverage" is false for routed flow.
- `tests/testthat/test-vignette_data.R` pins the shape of `segment_values.rds` and `segment_map.rds`, including `fwapg_*` provenance and the coverage outline's `cov_share`.
- Gate decisions: rebuild the routed table at a pinned sha from a clean worktree; routed replaces fwapg in every comparison in the vignette, while "How it is built" keeps the annual-table parity.

## Errors Encountered

| Error | Resolution |
|-------|------------|
