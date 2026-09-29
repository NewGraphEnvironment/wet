# Progress — Flow in date windows at hydrometric stations: daily series, window metrics, departure via cd (#25)

## Session 2026-09-28

- Plan-mode exploration; phases approved by user; instructed to run all phases to PR
- Created branch `25-flow-in-date-windows-at-hydrometric-stat` off main
- Scaffolded PWF baseline from issue #25 with approved phases
- Next: Phase 1
- Phase 1: `wet_station_daily()` HYDAT reader, fixture gains `FLOW_SYMBOL*`; matches tidyhydat exactly on 08EE013
- Plan review (Plan agent) → `review-1.md`; 18 findings, all adopted or answered; task_plan updated. cd PR #94 rejects several series per table, so the id-columns request moved out of cd#92 into cd#95
- Phase 2: provisional (duckdb over water-temp-bc) and real-time readers, per-station cutoffs, seam warnings; HYDAT 2026-07-17 downloaded to `data/hydat/20260717/`; live test green. The cutoff was proven by restoring the bug (FAIL 2)
- Phase 3: `wet_windows_calendar()` and `wet_window_stats()` (series-agnostic; min7 over calendar days; cov_day complete windows only; cd PR #94 anomaly types); 41 tests
- Phase 4: cd round-trip test (passes with cd PR #94 in a scratch lib, skips without). `scripts/station_departure.R` for 08EE013/08EE003 writes the report. Fixed a zero-row data.frame bug in both readers. Provisional winters are dropped (not ice-corrected). Research note `research/station_flow_departure.md`
