# Progress — Backlog move 4: Monthly error at the gauges (#166)

## Session 2026-11-17

- Plan-mode exploration — phases approved by user (gate: tracked report; hydrologic zone + major basin; DFO Mean columns for both sources plus routed Min from fwapg#42's per-year files)
- Created branch `166-backlog-move-4-monthly-error-at-the-gaug` off origin/main; claimed move #166 (in-flight)
- Scaffolded PWF baseline from issue #166 with approved phases
- Next: start Phase 1
- Phase 1–2: `scripts/gauge_monthly_compare.R` frame and #6 sections. Dev run (frozen copy with the clean-tree guard off, scratchpad) on 5d50cc1: gauge table `all.equal` the article bundle's at all 315 gauges; 290 routed, 283 shared (matches the article). #67's shape on 5d50cc1 at 283 gauges: Mar −11.1, Apr −12.2, Jul +19.7, Aug +12.3 %; size NSE routed 0.44/0.80/0.92/0.95 against #67's 0.43/0.80/0.92/0.95 on 7c30f58 (279 gauges): the Nechako rebuild did not move the shape.
