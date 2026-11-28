# Plan review: #189 (research files around the current state)

Blockers raised: 6
Owner forks: 1

Plan agent, 2026-11-27, over the draft `task_plan.md`. "Probed" means the planning session checked it against the files.
Phase numbers are the folded plan's.

## Blockers

- **B1, the upstream-area reports' path.** The draft said to move their citations to `data/basin/`. They are tracked in
  `data/checks/`. Probed, confirmed. Folded: instruction removed (Phase 5).
- **B2, the Fraser parity report exists** (`data/basin/100_report.txt`); the SALR tables are in the #1 archive. Probed,
  confirmed. Folded: Phase 5 names the sources, `findings.md` corrected.
- **B3, present-tense numbers already disagree:** routed-day figures, the nested selection since #47's gate, 08EE013's ice
  days, "every year 2023–2026", mixed held-out pools in `chinook_sites.md`. Probed: routed days, nested selection, ice and
  pools confirmed; the 2023–2026 sentence was probed only in part, so Phase 3 checks it row by row. Folded into Phases
  2, 3 and 4 as "known to disagree".
- **B4, `numbers_check.py` cannot see any of B3:** a stale number carried over passes, and whole-README matching is
  vacuous. Accepted. Folded: multisets against added lines only; a claim-by-source row for every kept number; a ledger of
  every old paragraph.
- **B5, `chinook_sites.md`'s comparative prose is false under `covariance_pick`.** Consistent with the file's own
  covariance_pick table (Naver -35, -58..+2). Folded: Phase 3 re-derives every comparison and lists the false ones.
- **B6, Maxan's distance results could lose their home** while `vignettes/short-record-flow.Rmd` publishes them and links
  `station_flow_departure.md`. Probed (the article's link), confirmed. Folded into the one-home rule and Phase 3.

## Gaps, assumptions, ordering, scope, acceptance

- PCIC's gridded run through fwapg has its only record in section 0 (`scripts/pcic_coverage.R` says so). Probed. Folded.
- Current facts under the #11 heading (zone steps, no output, pooled zones, Chapman's figures). Folded: Phase 4.
- Named sources miss several claims (ice, August means, 2016–2025 changes, database timings, per-dataset sizes, window
  claims). Folded: Phases 2 and 3; read-only recomputation counts as a check. Not probed claim by claim.
- Section-level dates must survive, and at most two headings may name an issue. Folded.
- fwapg's `discharge.sh` and the old PCIC host (`pcic_hydrology.md`). Probed. Folded: Phase 5 names both repositories.
- Archive destinations where an issue has two directories; links inside moved blocks. Folded.
- #76 is open (the draft said closed). Probed, confirmed. The upstream archive-unification ask is closed. Probed. Folded.
- An explicit do-not-run list. Folded.
- Ordering: the two departure files trade facts. Folded: one phase, one commit. Cross-pointers re-checked in Phase 6.
- Acceptance: `Closes` lines follow what landed; anchors are checked by claim. Folded.
- **Owner fork:** does `water_balance_method.md` stay in this PR? Not decided here: `## Open decisions` in
  `task_plan.md`.

The review read sections 1–7 of the paper only in part, did not re-read the live manifest, query fwapg or read fwapg's SQL.

## Files the plan names

```
research/water_balance_method.md
research/discharge_publish.md
research/station_flow_departure.md
research/chinook_sites.md
research/fwapg_mad_method.md
research/README.md
research/monthly_error.md
research/station_sources.md
research/station_snap.md
research/segment_group.md
research/pcic_hydrology.md
research/pcic_scenarios.md
planning/archive/
planning/backlog.md
CLAUDE.md
vignettes/short-record-flow.Rmd
vignettes/segment-discharge.Rmd
vignettes/flow-departure-normal.Rmd
vignettes/articles/flow-change-sparse-gauges.Rmd
scripts/wb_score_md5.R
scripts/wb_cv_lib.R
scripts/wb_gate_rule.R
scripts/wb_aet_compare.R
scripts/wb_fit_accept.R
scripts/discharge_publish.R
scripts/discharge_publish_lib.R
scripts/station_departure.R
scripts/departure_site.R
scripts/departure_site_snow.R
scripts/departure_pcic.R
scripts/pcic_coverage.R
scripts/mad_parity.R
scripts/mad_basin.R
scripts/upstream_area_check.R
R/wet_db_load.R
R/wet_catalog.R
R/wet_station_daily.R
R/wet_window_stats.R
R/wet_window_extend.R
R/wet_departure_carry.R
data-raw/chinook_sites_data.R
data-raw/life_history_data.R
inst/vignette-data/
tests/testthat/test-life_history_pin.R
data/checks/
data/basin/100_report.txt
data/basin/100_run.log
```
