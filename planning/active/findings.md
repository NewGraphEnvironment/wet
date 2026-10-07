# Findings — Dry-interior runoff: find which term is off, then fix that one (#45)

## Issue context

**If we do it:** we learn whether the weak semi-arid interior is a precipitation problem or an evapotranspiration problem, and test a fix for the right one. **If we never do:** zone 24 (Southern Thompson Plateau) stays at 102 % held-out error, and zones 15, 17 and 23 near 30–47 %. These remain the main limit the article names, after two AET experiments (#15, #18) that did not close the gap.

## Problem

- In the semi-arid interior, runoff is a small remainder of precipitation, so a small error in either term is a large one in runoff.
- #15 and #18 tried alternative AET products. Neither tested the precipitation side, ERA5-Land evaporation, or a diagnosis of which term is off.
- PCIC's VIC-GL output includes PREC and EVAP (`research/pcic_hydrology.md`). Inside its domain it gives an independent split to compare against, used as a reference, not an input (CLAUDE.md, "Own estimates first").

## Proposed Solution

1. **Diagnose.**
   - Per zone, inside PCIC's domain: our P (climr) and AET (cfu) against PCIC's PREC and EVAP, and against the gauge-implied AET (P − observed runoff) at the calibration gauges.
   - Attribute each zone's gap: ours, theirs or unresolved.
   - Also extend #5 with the gauge-level PCIC score from #39: 25.5 % against 30.5 % MAE at 168 gauges, Columbia 25.4 against 34.7.
2. **Pick the lever** the diagnosis points to, before scoring:
   - **P side:** a precipitation correction where climr departs from gauge-implied totals.
   - **AET side:** ERA5-Land total evaporation through cd. cd's catalogue has `total_precipitation` but no evaporation yet, which is a cd issue to file if this branch is taken.
3. **Pre-register and score** under a rule in the style of #15, against the #43 baseline.

Order: phase 1 can start now on the current fit; phases 2–3 after #43.

Relates to #5, #15, #18


## Pre-registered attribution rule (fixed 2026-10-07, before any PCIC PREC/EVAP value was computed)

Committed before `scripts/wb_term_diagnose.R` existed. Nothing below may change after the first PCIC PREC or EVAP number is seen. A change after that point is reported as a deviation, with the as-registered verdict alongside.

**Per gauge** (calibration gauges of fit_20260717, as `scripts/wb_cv_lib.R` builds `cal`; upstream area-weighted means, mm/yr, 1981–2010):
- Q = observed runoff (`cal$obs`).
- Ours: P_o = `p_yr` (climr), A_o = `aet_cfu` (shipped), PET = `pet_yr` (Hargreaves), R_o = P_o − A_o (raw, no zone adjustment).
- PCIC (TPS_gridded_obs_init): P_c = PREC, E_c = EVAP, R_c = RUNOFF + BASEFLOW.
- A gauge is in the diagnosis only if PCIC has a value over ≥ 95 % of its basin area.
- Zone = the gauge's dominant hydrologic zone (`cal$zone`).

**Per zone**, over its gauges in the diagnosis, in this order:

1. **Material gap.** Our median log(R_o / Q) ≥ 0.10. Otherwise the verdict is "no material gap".
2. **Gauge side.** PCIC also overshoots: median log(R_c / Q) ≥ 0.10 and ≥ half of ours. Then the verdict is "gauge side (unresolved: withdrawals, groundwater or a shared P bias)". Two models with independent P and ET both running high at the same gauges point at the gauge, or at something both share.
3. **Reference usable.** PCIC's median |log(R_c / Q)| ≤ 0.25, and its median closure |P_c − E_c − R_c| / P_c ≤ 0.10. Otherwise "unresolved: PCIC not a usable reference here".
4. **Decompose** the gap against PCIC, summed over the zone's gauges so the terms add: G = Σ[(P_o − A_o) − (P_c − E_c)] = ΣΔP − ΣΔA, with ΔP = P_o − P_c and ΔA = A_o − E_c.
   - **P side (ours)** if ΣΔP ≥ ⅔·G, and at least one independent test agrees:
     - (i) the implied AET under our P, P_o − Q, exceeds PET at ≥ half the zone's gauges (physically impossible unless P is high or the gauge loses water);
     - (ii) the median climr / ECCC MAP ratio at ECCC 1981–2010 normal stations in the zone (any normal code) is ≥ 1.10.
   - **AET side (ours)** if −ΣΔA ≥ ⅔·G and P_o − Q ≤ PET at ≥ half the zone's gauges (the larger AET the gauges imply is physically possible).
   - **Mixed** if both shares are < ⅔. Name the larger term.
   - A share test that passes while its corroboration fails is reported as "unresolved: <term> by decomposition, not corroborated".
5. **Disagreement with PCIC** (the CLAUDE.md attribution): in each zone, whichever of R_o and R_c has the larger median |log(R / Q)| is the one that is off. That is ours or theirs, and it is reported alongside the verdict.

**Lever (phase 2), mapped from the verdicts in zones 17, 23 and 24:**
- The lever is the term (P or AET) that is the verdict in the majority of the three. If there is no majority, zone 24's verdict decides (largest error).
- If the majority is gauge side, unresolved or mixed without a majority term, there is no lever. Phase 2 then names the evidence that would decide it.
- Zone 15 (the balance is already near PCIC there) and the wet zones are contrast only.

## Errors Encountered

| Error | Resolution |
|-------|------------|
