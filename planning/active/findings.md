# Findings — Dry-interior precipitation: score climr against plateau-elevation observations (#50)

## Issue context

**If we do it:** we find out whether climr's precipitation is too high on the dry plateaus, which is the leading explanation for the interior runoff overshoot. If it is, we build a precipitation correction and score it under a rule already fixed. **If we never do:** zone 24 (Southern Thompson Plateau) stays at 93 % held-out error and the dry zones at 42.8 %. The cause stays "probably precipitation" with no test behind it.

## Problem

- #45 compared our P (climr) and AET (cfu) with PCIC's PREC and EVAP. Under the rule fixed in advance, no single term was found to be off: zones 15 and 24 read "compensating".
- The evidence gathered after the rule was applied leans to precipitation:
  - climr / PNWNAmet P is 1.36–1.61 in the dry zones, against 1.15 elsewhere, while the AET ratio is about the same everywhere.
  - Across the dry basins, runoff error correlates with ΔP / P at r = 0.32, and with ΔA / P at r = −0.04.
  - In zone 24, the implied Budyko ω is implausibly high (> 5) at 4 of 8 basins.
- ECCC normals can't settle it, because the stations sit in the valleys, well below the gauge basins (median basin elevation is 1,345–1,553 m). Only zone 15 has enough stations, and there the climr / ECCC median is 1.05.

## Proposed Solution

1. Score climr, PNWNAmet (PCIC PREC) and TerraClimate in zones 15, 17, 23 and 24 against:
   - BC River Forecast Centre ASWS precipitation gauges;
   - snow-course SWE, as a lower bound on winter P.
2. Build a P correction only if climr is high at elevation.
3. Score any correction under the rule fixed in #45 (`research/water_balance_method.md` §0). It ships only if all of these hold:
   - dry-zone MAE at least 10 points below 42.8 %;
   - all-station MAE no higher than 27.5 %, with the headwater and nested limits;
   - the seven major-river mouths held within 0.03;
   - a fully nested selection beats the baseline.

   The correction must not be fitted to the gauges it is scored on.

Relates to #45, #5

