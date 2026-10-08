# Progress — Daily water temperature with gaps filled at stations: wet_temp_fill() (#40)

## Session 2026-10-07

- Plan-mode exploration — phases approved by user (Kalman smoother engine; anomaly pool = stations in the call)
- Created branch `40-daily-water-temperature-with-gaps-filled` off main
- Scaffolded PWF baseline from issue #40 with approved phases
- Next: start Phase 1
- Phase 1 committed (218b0a7): gsdd in Suggests/Remotes, synthetic fixture
- Plan review (Plan agent): 3 blockers, triage in review-plan.md
- 08E spike: form 1 (one Kalman state on air2stream) tied open-loop on whole seasons; switched to S + u (findings.md)
- /code-check: 4 rounds. R1 empty input, one air row, re-fed output; R2 from/to cut the fit, NA dates; R3 named the mechanism (one complete calendar per station) and enumerated it: NA from/to, air holes, gsdd NA dates, 29 Feb; R4 found the air-hole check missed holes across an end (inside R3's fix), closed by testing every hole position
- Refactor into wet_fill_prepare/station/swap so validation scores a held-out station without refitting its peers (swap = public function, max diff 5e-10 °C)
- Phases 2 and 3 committed together: the wet_temp_fill() docs link wet_temp_gsdd()
