# Plan review for #168 (carries #9), 2026-11-22

Blockers raised: 3
Owner forks: 5

A Plan agent reviewed the drafted `task_plan.md` against #168, #9, #169, the code it names, fwapg's `load/pcic_schema.sql` and `extras/pcic_crosswalk/README.md`, and HYDAT 20260717. Each finding was probed or reasoned before it was folded; the verdicts follow.

## Blockers

- **B1. The CMIP5 runs end 2099-12-31, so "2071–2100" cannot be fetched.** Confirmed (CLAUDE.md and `research/pcic_hydrology.md` give 1945–2099). Folded: CMIP5 left to move 7 (decision 3 b), which takes 2070–2099 and checks the runs' calendars first; the CMIP6 signal uses 2070–2099 too.
- **B2. 08MF005 fails `wet_station_select()`'s unregulated filter.** Probed: `STN_REGULATION` gives 08MF005 regulated from 1952; the other three gauges are not. Folded: full years counted directly, regulation a column, Hope's HYDAT comparison carries it.
- **B3. Rule 1 was undefined and, at an interior segment, circular.** Agreed (on an outlet's own segment q = q_acc; the published annual is the plain mean of 12 monthly means). Folded: rule 1 on outlet segments with annual taken the same way, a monthly floor of 1e-4 m³/s, the ratio reported; the interior headwater rebuilt from raw series, stated as checking arithmetic only.

## Gaps

- G1 (rule 2 restated as `|median − PNWNAmet| / Q_HYDAT ≤ 0.05`, one historical half, one statistic, `wet:::wet_nse()` on shares): folded. `wet_nse` exists (`R/wet_flow_validate.R:76`).
- G2 (bulk endpoint at every scored outlet-segment gauge): OWNER FORK, added as decision 1 (d), recommended.
- G3 (domain coverage unverified; rule 3's domain logic): folded, a Phase 1 probe and rule 3 by domain.
- G4 (can the crosswalk hold a CMIP6 run): folded as move 7's first check, stated in the verdict.
- G5 (a series revised since fwapg's build reads as a mismatch): folded into rule 1.
- G6 (confluence rule): folded, from fwapg's ~680 junctions (README confirmed).
- G7 (CMIP5 chain incomplete; do not rerun `mad_basin.R`; glacier note): folded for the gridded PNWNAmet accumulation; CMIP5's notes moved to decision 3.
- G8 (caches and cost): folded, `data_root`; the 40 GB CMIP5 cost is in decision 3.
- G9 (water temperature like with like): folded into decision 4.
- G10 (do not source `wb_cv_lib.R`; HYDAT pin; snapped stations): folded.
- G11 (share of outlets by flag): folded into Phase 1.
- G12 (PNWNAmet ends 2012, 23,011 days): probed against the listing, confirmed; `findings.md` corrected.

## Ordering

- O1 (database down; owner starts it): folded as Phase 1's first item. Not a fork: a machine change asked when the build starts.
- O2, O3 (probes and site rules before the rule commit): folded.
- O4 (move `data/logs/168/` before removing the worktree): folded into Phase 5.

## Assumptions

- A1 (sites against HYDAT): folded; 08KC001 is not in SALR, so the plan names it.
- A2 (the portal's downloads are not shown to call hydromosaic): probed; the bundle has no hydromosaic, streamflow or CSV string. Folded: the identity is stated as resting on the shared network, runs and variables, and Phase 1 tries to settle it.

## Scope

- S1 (CMIP5 adds cost and decides nothing): OWNER FORK; recommendation changed to 3 (b).
- S2 (three scope changes listed as decided): OWNER FORK; moved into decision 1.
- S3 (the thresholds' conjunctive form): OWNER FORK; decision 5 added.
- S4 (a CMIP6 verdict builds scenarios on PCIC's routing): OWNER FORK; stated in decision 1.
- S5 (size): with CMIP5 out and temperature trimmed, one PR. Accepted.
- S6: the same as G2.

## Acceptance

- X1–X5: folded (rule provenance in the report, timings from the fetch log, the frozen inputs defined, the site checks and probes printed, the research-to-report check named as `/code-check`'s).

## Files the plan names

planning/backlog.md
CLAUDE.md
scripts/channel_scale_sites.csv
scripts/channel_scale_pilot.R
scripts/departure_sites.csv
scripts/pcic_routed_lib.R
scripts/wb_fit_lib.R
scripts/mad_basin.R
scripts/pcic_routed_compare.R
scripts/gauge_monthly_compare.R
R/wet_segment_monthly.R
R/wet_station_monthly.R
R/wet_station_select.R
R/wet_ws_fetch.R
R/wet_ws_sample.R
R/wet_upstream_mean.R
R/wet_mm_to_m3s.R
R/wet_flow_validate.R
R/wet_temp_daily.R
R/wet_pcic_index.R
research/pcic_channel_scale.md
research/README.md
research/pcic_hydrology.md
research/monthly_error.md
research/water_balance_method.md
data/checks/channel_scale_pilot_20260717.txt
