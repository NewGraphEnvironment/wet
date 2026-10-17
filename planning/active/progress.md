# Progress — Sub-monthly flow per segment: a daily climatology for both sources, with weeks and windows derived from it (#70)

## Session 2026-10-17

- Plan-mode exploration (three Explore sweeps, one Plan review) — phases approved by user; scope narrowed to the balance's within-month daily shape, publishing deferred to a follow-up
- Created branch `70-sub-monthly-flow-per-segment-a-daily-cli` off main
- Scaffolded PWF baseline from issue #70 with approved phases
- Next: Phase 1, commit the rule
- Phase 1 rule registered at 44ce054; Phase 2 `wet_station_doy()` 81468ad; Phase 3 `wet_shape_*` dd831b8
- Phase 4 run on m1 (17:18–17:21 UTC first run; two reruns identical): donor ships, +0.083 over flat
