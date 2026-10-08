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
- Validation run 1 stopped at the 2 h background limit (air table re-filtered per job); fixed, 12 min
- Validation run 2: rule PASS, but code-check round 5 found the script's GSDD used gsdd_vctr(complete = FALSE) (403/897 truth NA) and unpaired MAE; also the coverage interval and the sub-sub peer proxy differed from what they claimed
- Round 5's mechanism: the script re-derived what the package computes. Enumerated its reach in the validate script: GSDD (now wet_temp_gsdd()), fill and interval and floor (now wet_fill_values(), shared with wet_temp_fill()), held-station preparation (package internals), peer proxy (a label, now from fitted and observed peers), truth set and pool (script-only by design), open/forward baselines (not package outputs). Parity: A by wet_temp_gsdd(), fill by wet_temp_fill(); B/C deliberately their rule. Nothing left re-derived; loop ended by enumeration
- Validation run 3 (final): pre-registered rule FAIL on criterion 3 (season GSDD MAE 130.4 vs 128.7); criteria 1-2 pass. Ships per the rule's fail branch; short gaps and shoulders win on every measure
- Parity: 17/17 sites in their 95 % PI, r = 0.997; 2024 +191 attributed theirs
- Spend: plan review + 5 code-check rounds = 6 reviewer agents
