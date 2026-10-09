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

## Phase 1: the script against #57 (2026-10-09)

`WET_FWAPG_COMMIT=4929c8c Rscript scripts/pcic_routed_compare.R` (4929c8c is a guess at the pre-rebuild table's build; report not committed), at wet 4c32936, table 40,524,612 rows / 3,377,051 segments / total 178,169,881.212 m3/s:

| at the 290 gauges | #57 routed | script routed | #57 balance | script balance |
|---|---|---|---|---|
| MAE | 24.4 | 24.1 | 27.6 | 27.6 |
| median AE | 13.2 | 13.0 | 18.0 | 18.0 |
| within ±20 % | 62 | 62 | 54 | 54 |
| bias | −0.1 | +0.2 | +9.0 | +9.0 |
| headwater / nested | 28.8 / 11.3 | 28.3 / 11.3 | 31.0 / 17.2 | 31.0 / 17.2 |
| routed closer | 58 % | 59 % | | |

- The balance side reproduces exactly, and so do coverage (290 of 315) and the uncovered sub-drainages (10A–10C, 08M, 08N, 09A).
- The routed side is within 0.3 points. Weighting the months by their length does not explain the gap: weighted MAE is 24.08 and bias +0.5. #57 does not record which build of the table it read, and the table was rebuilt several times on 2026-10-08 (build13 11:40, build14 11:47 PDT). Attribution: unresolved. Most likely an earlier build, not the definitions.
- The report is named `pcic_routed_compare_<release>.txt` through `wb_report()`, as every report scored against a fit since #43 is, not the issue's `pcic_routed_compare.txt`.

## Coordinating the rebuild with the fwapg#2 session (2026-10-09)

- fwapg-56 (the fwapg#2 session) asked me to wait until its PCIC rerun finishes and it has compared the result against its snapshot (`fwapg.snap_crosswalk`, `fwapg.snap_monthly`). After that the rebuild can go ahead without waiting for the merge.
- Tables that are its and must not be touched: `fwapg.blk_parents`, `fwapg.blk_paths`, `fwapg.mainflow_tree_*`, `whse_basemapping.fwa_stream_networks_mainflow_tree`, `fwapg.snap_*`. A run at 218a47f uses `fwapg.pcic_blk_parents` and `fwapg.pcic_blk_paths` and the other `pcic_*` staging tables, and drops them. Those do not collide.
- It reports that its branch's parents and paths are identical to 218a47f's (1,570,499 lines, 0 differences).
- Timing: the 01_paths step at 218a47f took about 35 minutes on m1.

## m1 reboots during the rebuild (2026-10-09)

- m1 reset three times: about 09:07, about 09:50 and 13:05 PDT. `/Library/Logs/DiagnosticReports/forceReset-full-2026-10-09-130516` shows a forced reset. The pinned crosswalk run died each time: twice in the paths step and once at the outlets step. The routed table was never reached; its fingerprint was unchanged after each reset (40,524,612 rows, sum 178169881.209890).
- Cause, as diagnosed and relayed by the user: memory pressure from the fwapg#2 session's SSNbler R batch (`xargs -P 3`, each worker 20–50 GB) on top of colima reserving its full 32 GiB VM. Attribution: not this job. The fixes (`-P 1`, stopping or shrinking colima during the batch, or running it on m4/cypher) belong to the fwapg session.
- Decision (user, 2026-10-09): hold #58 until the fwapg work finishes, and possibly move the rebuild to m4.

## Errors Encountered

| Error | Resolution |
|-------|------------|
