# Findings — Dry-interior runoff: rescore zones 23/24 without regulated or diverted gauges (#53)

## Issue context

**If we do it:** we find out whether the dry-interior overshoot comes from the gauges, from creeks whose measured flow has had water taken out upstream, rather than from our P or AET. **If we never do:** zone 24 (Southern Thompson Plateau) stays at 93 % held-out error, with both climate terms now weakened as explanations and the remaining candidate untested.

## Problem

- #45 found no single climate term off in zones 15/17/23/24.
- #50 then scored climr against plateau-elevation gauges and snow courses. climr runs only about 9 % high there relative to the interior (D 1.09, not decided), and part of #45's climr–PNWNAmet gap is PNWNAmet's.
- A P error of a few percent cannot produce zone 24's overshoot (+93 % held out on the shipped fit).
- #45 left "gauge side (withdrawals or groundwater)" unresolved. Many Okanagan and Thompson plateau creeks carry irrigation diversions and storage above their gauges. A depleted gauge reads low, and the balance then looks like it overpredicts.

## Proposed Solution

1. **Flag** the calibration gauges in zones 23 and 24 (and 15/17 for contrast) whose basins are:
   - marked regulated in HYDAT (`tidyhydat::hy_stn_regulation()`);
   - or hold licensed diversions or storage (BC water rights licences and points of diversion; dams).

   Record the flag rule before any score is computed, as #45 and #50 did.
2. **Rescore** the shipped fit (fit_20260717) without the flagged gauges.
   - Report held-out MAE for the dry zones (baseline 42.8 %) and zone 24 (baseline 92.8 %), with and without the flagged gauges.
   - Report how many gauges each zone keeps.
3. **Decide.** If the error falls substantially once flagged gauges are dropped, the overshoot is on the gauge side. The fix is then in station selection, not in P or AET. Fix the threshold for "substantially" at step 1.

Relates to #45, #50
