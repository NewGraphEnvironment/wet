# Progress — Pinned HYDAT releases (#46)

## Session 2026-10-15

- Plan-mode exploration — phases approved by user ("go all phases to pr")
- Created branch `46-pinned-hydat-releases-one-resolver-a-per` off main
- Scaffolded PWF baseline from issue #46 with approved phases
- Next: start Phase 1
- Phase 1: `wet:::wet_hydat()` in `R/wet_hydat.R` (partial dir + rename, VERSION on every return), 23 expectations green. Four restored defects (no return VERSION check, no superseded refusal, no download VERSION check, download straight into place) each turn a test red, run in a tree copy
- Phase 2: `wb_hydat()` resolves through `wet:::wet_hydat()` and refuses a set `WET_HYDAT`; run lines stripped; the three station scripts source `wb_fit_lib.R` and record the release (departure report, `station_daily.rds` via `wet_hydat_release()`, new `station_map.rds` provenance). The grep box waits for Phase 3 (the live test still names `data/hydat/`)
