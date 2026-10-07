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


## Errors Encountered

| Error | Resolution |
|-------|------------|
