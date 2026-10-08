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

## What was seen before the rule was fixed (disclosure)

- **Per-gauge held-out errors in the dry zones are already public.** #45's report lists ours, PCIC and obs per dry basin, and the plan-mode exploration printed `cv_ann` and `obs` for the 40 dry gauges. Whoever set the thresholds below knew which gauges overshoot (Greata, Camp, Beak and Whipsaw in zone 24 most).
- **No licence or dam value has been joined to any gauge.** Only the layers' vocabularies were read, from the snapshot `scripts/wb_gauge_diversion.R` stage 1 took on 2026-10-07: purposes, units, quantity flags, statuses, and geometry presence. The thresholds were set from hydrology (what share of runoff matters), not from which gauges they flag.

**Facts about the snapshot that shaped the rule** (vocabularies only):
- 117,945 points of diversion (POD 103,763 surface; PWD 11,777 and PG 2,405 groundwater) in 78,276 licence-purposes. Licence status: Current 94,717, Abandoned 14,985, Cancelled 7,883, Expired 360. 22,412 non-current rows have a status date ≥ 1981, so they may have been in force during 1981–2010.
- `QUANTITY_FLAG`:
  - T: total demand for the purpose, one POD (78,830);
  - M: maximum licensed demand, multiple PODs, quantity at each unknown (26,723; the quantity repeats on each POD row, and is the same within a licence-purpose in all but 3 of 7,326 groups);
  - D and P: multiple PODs, quantities at each known (1,023);
  - none (11,369).
- `QUANTITY_UNITS` carry trailing spaces: m3/day, m3/year and m3/sec, plus Total Flow (1,728), Hectares (2), Select (1) and none (18), which have no volume.
- 10,434 rows have no location: 10,247 abandoned, cancelled or expired, 166 current.
- Dams (2,490) are crest lines with function, height and regulation class, and **no reservoir volume**. So storage volume comes from licences, and dams are reported, not deciding.
- HYDAT: `wet_station_select()` keeps only `REGULATED = 0`, so the regulated flag is 0 for every calibration gauge by construction. `STN_REMARKS` for the dry gauges are operational (ice, missing record).

## Pre-registered rule (fixed 2026-10-07, before any licence or dam was joined to a gauge)

**Gauges.** The shipped fit's calibration gauges (`scripts/wb_cv_lib.R` `cal`, 315), with held-out `cv_ann` and `obs` from `fit_20260717/cv_aet-cfu.rds` (aet cfu, release 20260717, this scoring code). Dry = hydrologic zones 15/17/23/24 (40 gauges). Baseline, asserted: dry 42.8 %, zone 24 92.8 %, all 27.5 %.

**Licences counted** (one row = one POD of one licence-purpose):
1. **Surface water only:** `POD_SUBTYPE` = POD. Groundwater (PWD, PG) is reported, not counted.
2. **In force during 1981–2010**, weighted by the share of those 30 years:
   - start = max(1981, priority year);
   - end = 2010 if `LICENCE_STATUS` is Current, else min(2010, status-date year);
   - weight w = max(0, end − start + 1) / 30.
   - A row without a priority date has w = 0, counted and reported.
3. **Located:** a row without a location cannot be placed. Counted and reported, by status, as a limit (undercounting historic licences).
4. **Volume per year:** units trimmed. m3/year × 1; m3/day × 365.25; m3/sec × 31,557,600 (a rate held all year: the entitlement's upper bound). Total Flow, Hectares, Select or none have no volume, so they are counted and left out.
5. **Purpose classes** (by `PURPOSE_USE_CODE`):
   - **storage:** 08A Stream Storage: Non-Power; 12A Stream Storage: Power; 11A Conservation: Storage;
   - **instream or flow-through, not counted:** 07A/07B/07C Power; 11B Conservation: Use of Water; 11C Conservation: Construct Works; 02E Pond & Aquaculture; 02I38 Fish Hatchery; 02I26 River Improvement; 08B Aquifer Storage;
   - **consumptive:** every other purpose.
6. **Deduplication per licence-purpose** by `QUANTITY_FLAG`:
   - T, D, P: each row's quantity is its POD's own;
   - M, or none: the licence-purpose's quantity (its maximum, if the rows disagree) counts once and is split equally over its located PODs, so a gauge gets the share of PODs upstream of it.

**Placement.** Each located POD, and each dam (at its crest line's midpoint, `ST_LineInterpolatePoint(ST_LineMerge(…), 0.5)`), goes into the FWA fundamental watershed that contains it. It is upstream of a gauge when:
- it lies in another polygon and `whse_basemapping.fwa_upstream(gauge wscode, gauge localcode, its wscode, its localcode)` is true; or
- it lies in the gauge's own polygon, unless it indexes (`fwa_indexpoint`, 100 m) to the gauge's own blue line at a measure below the gauge's. This is the same polygon convention the upstream area uses, less the diversions plainly below the gauge.

Points outside every polygon are counted and dropped.

**Per gauge** (A = FWA upstream area, the area `obs` is in mm over):
- **L** = Σ w × consumptive m³/yr ÷ A, in mm/yr;
- **S** = Σ w × storage m³ ÷ (obs × A), the share of mean annual runoff volume licensed into storage;
- dams upstream: count, by function and regulation class (reported).

**Flags:**
- **diverted:** L ≥ 0.10 × obs;
- **storage:** S ≥ 0.10;
- **flagged** = diverted or storage;
- HYDAT regulated: reported (0 by construction).

**Decision**, dry zones, held-out MAE (`scripts/wb_cv_lib.R` `mae()`) on unflagged gauges (kept) against all 40:
- Δdry = 42.8 − MAE(kept dry); Δ24 = 92.8 − MAE(kept zone 24).
- **Null:** remove the same number of gauges from each dry zone at random (10,000 draws, seed 53) and take Δdry for each draw. p95 is its 95th percentile.
- **Too few:** fewer than 3 zone-24 gauges kept.
- **Gauge side:** Δdry ≥ 10 points, and Δ24 ≥ 0.5 × 92.8 (zone 24 at most 46.4 %), and Δdry > p95.
- **Not gauge side:** Δdry < 5 points and Δ24 < 0.25 × 92.8. This includes nothing being flagged.
- **Inconclusive:** anything else.
- **Capacity (corroboration, applied to "gauge side"):** at each flagged zone-24 gauge, overshoot = cv_ann − obs (mm). Capacity holds if L ≥ 0.5 × overshoot at ≥ half of them. If capacity fails, or no zone-24 gauge is flagged, "gauge side" becomes "flags select the bad gauges, but licensed water cannot account for the overshoot: unresolved".

**Reported, not deciding:**
- raw (P − AET, no zone adjustment) error, with and without flagged gauges;
- Spearman correlation of L / obs against the log held-out error over the dry gauges;
- the decision recomputed at a 50 % consumptive fraction (L halved) and without m3/sec licences;
- every other zone's flags and MAE change, and all 315 gauges;
- gauges kept per zone;
- groundwater licences upstream;
- limits: imports into a basin from another one cannot be seen from PODs; licensed quantities are entitlements, not use.
