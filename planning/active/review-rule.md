# Blind review of the #53 rule (Plan agent, 2026-10-07)

Run before stage 2, with no licence or dam joined to any gauge. The reviewer read the rule, the plan, the stage 2–4 draft (code only; no output existed), `scripts/wb_cv_lib.R`, `R/wet_cv_folds.R`, `R/wet_station_snap.R`, and the #45 and #50 rules and reviews. The full text was returned in the agent's reply; this is its substance.

Blockers
- B1. The drop test cannot separate diversions from low-obs gauges. Both flags have obs in the denominator, MAE is a mean of |%| errors, and the random null does not match on obs. The registered Spearman of L/obs against log(cv/obs) is a spurious ratio correlation. Proposed: an obs-matched null (zone × obs half), and a naturalized rescore (obs + f·L, no gauge removed) with a within-zone permutation null.
- B2. Weighting by licence history double-counts licences that were cancelled and reissued (amendment, apportionment, transfer) with the original priority date. Proposed: drop a non-current row when a Current row shares its POD, purpose and priority date; report the Current-only and no-removal bounds.
- B3. `fwa_upstream()` on codes is true for equal codes, so bank-pair polygons of the gauge's reach escape the below-gauge test, and tributaries joining below the gauge within the reach are counted. Proposed: "own reach" = the gauge's exact wscode and localcode; such points are tested with the blue-line `fwa_upstream()` form `wet_station_snap()` uses; placement-sensitive gauges listed.
- B4. "Too few" (7 or more of 9 zone-24 gauges flagged) is plausible and ends the test; "> p95" on a discrete null can be unattainable. Proposed: p ≤ 0.05 with the minimum attainable p printed; "too few" hands zone 24 to the naturalized test.

Gaps
- G1. Storage does not deplete mean annual flow; S marks regulation. Proposed: D decides, S reported.
- G2. One gauge can carry the result. Proposed: leave-one-out stability (unflag each flagged dry gauge; drop each zone-24 gauge), and median |%| and mean signed log error beside MAE.
- G3. Capacity is lenient as corroboration (L is an upper bound) and passes trivially where cv ≤ obs. Proposed: over cv > obs only, at f = 0.5 and without m3/sec; the naturalized ΔN24 is its aggregate form and decides.
- G4. Verdict mapping misses likely cases. Proposed: drop test, then naturalized test, then verdict (Amendment 8 of the review); per-zone lines.
- G5. Without a refit, zone 15's held-out values depend on flagged training gauges (17/23/24 are pooled to none). Proposed: zone-15 change on raw and held-out; label if the verdict depends on it.
- G6. Rediversion rows double-count; M split by rows, not PODs; D/P groups that repeat one quantity are totals; a "core consumptive" set. Proposed: as stated; split-sensitive gauges listed.
- G7. The author knew the per-gauge errors. Proposed: a threshold sweep (0.05, 0.10, 0.20) and a semi-blind replication in the non-dry zones against obs-matched unflagged gauges.
- G8. obs averages each gauge's own complete years; w spreads over all 30. Proposed: w over the gauge's own years.

Assumptions: status date on Current rows (report status − priority years); D/P semantics; POD coordinates; and that a 10 % depletion is an 11 % error, so the flag measures "affected" and only the naturalized test measures "explains" (zone 24's 92.8 % needs about 48 % depletion).

Ordering: amend and commit before stage 2; after flags are seen, any change is a deviation; record any local knowledge of the named creeks.

Scope: hydraulically connected wells; imports, off-stream storage, unlicensed use and reservoir evaporation are invisible; storage and the monthly shares are out of scope; a province-wide station rule needs the all-315 table with signed error and gauges lost.
