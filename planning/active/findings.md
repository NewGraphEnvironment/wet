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

## Amendment 1 to the rule (2026-10-07, after the blind review in `review-rule.md`, before any licence or dam was joined to a gauge)

**Disclosure (review O2).** The author has no local knowledge of storage or diversions on any named dry-zone creek. What was known is the issue's general claim, that many Okanagan and Thompson plateau creeks carry diversions, plus the per-gauge errors disclosed above. The reviewer saw only the disclosed zone figures and Greata Creek's obs of about 50 mm.

The rule above stands except as changed here.

**Licence accounting** (review B2, G6, G8, S1):
1. **Replaced licences.** A non-current row is dropped as replaced when a Current row shares its `POD_NUMBER`, `PURPOSE_USE_CODE` and `PRIORITY_DATE`. Replaced rows are counted.
   - Bounds, reported: Current only (lower), and no replacement removal (upper).
   - A verdict that differs under either bound is labelled "sensitive to licence history".
2. **Rediversion.** Rows with `REDIVERSION_IND = Y` are left out (counted).
3. **M and no-flag groups** are split over the group's distinct located `POD_NUMBER`s, not its rows.
   - A D or P group whose rows all carry one quantity is treated as M (a repeated total).
   - **Split-sensitive:** where a group has PODs both upstream and not upstream of a gauge, L is also computed with the group at 0 and at its full quantity. A gauge whose flag differs between the two is listed.
4. **In-force weight per gauge.** w is computed over the gauge's own complete years in 1981–2010 (`wet_station_select()`'s `years` attribute, the years `obs` is built from): the share of those years with start ≤ year ≤ end.
   - The 30-year weight is reported for gauges whose flag differs between the two.
5. **Core consumptive** sensitivity, reported: domestic, irrigation, waterworks and stockwatering purposes only (codes 01A, 01A01, WSA01, 03A, 03B, 00A, 00B, 00C, 02I35, 02I31, WSA08).
6. **Groundwater.** L_gw is reported also for rows with `HYDRAULIC_CONNECTIVITY` = Likely.
7. **Status date.** On Current rows, the distribution of status year − priority year is reported (counts only).

**Placement** (review B3):
8. **Own reach.** A point is in a gauge's own reach when its fundamental watershed has the gauge's exact wscode and localcode, on either bank and in any polygon.
   - Own-reach points are indexed (`fwa_indexpoint`, 100 m). They are upstream only if `whse_basemapping.fwa_upstream(gauge blue_line_key, gauge measure, gauge wscode, gauge localcode, point blue_line_key, point measure, point wscode, point localcode)` is true, the form `wet_station_snap()` uses.
   - Own-reach points not indexed within 100 m are kept, and counted.
   - Points elsewhere are upstream by `fwa_upstream()` on codes, as registered.
   - **Placement-sensitive:** a gauge whose flag changes when all own-reach points are dropped is listed.
9. **Dams** are placed at the midpoint of the longest part of the crest line.

**Flags** (review G1):
10. **The deciding flag is D** (L ≥ 0.10 × obs). S (storage ≥ 10 % of annual runoff volume) is a regulation flag.
   - The verdict with D-or-S is reported.
   - Gauges flagged S only are listed as "regulated pattern; annual volume not depleted by the licence data".
11. **D measures "affected", not "explains"** (review A4). A depletion d is an error of d / (1 − d), so zone 24's 92.8 % needs about 48 % depletion. Only the naturalized test measures "explains".

**Tests and verdict** (review B1, B4, G2, G3, G4, G5, G7). Thresholds are relative to the baseline of the data in hand, so leave-one-out runs use their own baselines. The 10-point Δdry and ΔNdry thresholds stay absolute.
12. **Drop test (step 1)**, held-out MAE on the D-unflagged gauges:
   - Δdry = base_dry − MAE(kept dry), and Δ24 likewise.
   - **Null, obs-matched:** strata are zone × obs half (below or at, or above, the zone's median obs). The same number of gauges is removed per stratum as were flagged in it. 10,000 draws, seed 53.
     - p_dry and p24 are the shares of draws with Δ ≥ observed, ties included.
     - The minimum attainable p is 1 / Π C(n_s, k_s) over strata. Where it exceeds 0.05, that p is "uninformative".
     - The as-registered zone-only null is reported.
   - **select** = Δdry ≥ 10, Δ24 ≥ 0.5 × base24, p_dry ≤ 0.05 and p24 ≤ 0.05.
   - **no** = Δdry < 5 and Δ24 < 0.25 × base24.
   - **too few** = fewer than 3 zone-24 gauges kept (checked first).
   - **uninformative** = a minimum attainable p above 0.05 where select would otherwise hold.
   - **inconclusive** = otherwise.
13. **Naturalized test (step 2):**
   - No gauge is removed. Each dry gauge is rescored against obs_n = obs + f·L.
   - ΔN24 = base24 − MAE(obs_n, cv) over every zone-24 gauge. ΔNdry is the same over every dry gauge.
   - **Null:** L (mm) is permuted among the gauges of each zone, 10,000 draws, seed 53. pN24 and pNdry are the shares with ΔN ≥ observed.
   - **accounts** = at f = 0.5, ΔN24 ≥ 0.5 × base24, ΔNdry ≥ 10, pN24 ≤ 0.05 and pNdry ≤ 0.05.
   - **cannot** = ΔN24 < 0.25 × base24 even at f = 1.
   - **neither** = otherwise.
14. **Verdict:**
   - **not gauge side** = step 2 "cannot", whatever step 1 says;
   - **gauge side** = step 1 "select" or "too few", and step 2 "accounts";
   - **flags select the bad gauges, but licensed water cannot account for the overshoot: unresolved** = step 1 "select" and step 2 not "accounts";
   - **inconclusive** = otherwise.
15. **Stability.** The verdict is recomputed:
   - with each D-flagged dry gauge unflagged in turn;
   - with each zone-24 gauge removed from the data in turn.

   If any of these differs, the verdict is "unstable (<verdict>)".
16. **Capacity (reported, no longer deciding).** Over the flagged zone-24 gauges with cv > obs only: does 0.5 × L without m3/sec licences reach 0.5 × (cv − obs)? Each such gauge is listed. "Cannot account even at full entitlement" is reported where L < 0.5 × (cv − obs).

**Reported, not deciding** (replacing the registered list where they differ):
17. Verdicts under:
   - D thresholds of 0.05 and 0.20 (with the 0.10 primary). "Threshold-dependent" if gauge side holds only at 0.10;
   - D-or-S flags;
   - core consumptive;
   - without m3/sec;
   - the two licence-history bounds;
   - zone 15 scored on raw error, labelled "depends on the zone-15 fit (not refit)" if it differs.
18. **Per-zone lines** for every zone and for all 315 gauges:
   - n, D, S, kept;
   - held-out and raw MAE, all and kept;
   - median |%|;
   - mean signed log error, all and kept.
19. **Spearman.** L (mm) against cv − obs (mm) over the dry gauges. The registered L/obs against log(cv/obs) is printed with the note that it shares 1/obs on both sides. The proposed partial Spearman is not adopted, because the naturalized test covers it.
20. **Semi-blind replication** in the 275 non-dry gauges:
   - the median signed log(cv/obs) of the D-flagged gauges, minus that of their obs-matched unflagged partners (nearest log obs, same zone where one exists, without replacement);
   - "not replicated outside the dry zones" if ≥ 10 are flagged and the difference is ≤ 0.

**Ordering (review O1).**
- The script runs once after this amendment is committed.
- Any later change to accounting, placement, purpose classes or tests is a deviation. Each is reported with the as-amended verdict beside it.
- No licence is reclassified because of what the per-gauge listing shows.

**Not adopted:**
- The 500 m point counts (review A3), since placement-sensitivity covers the consequence.
- Per-fold pooling status (G5), since the CV object does not store it; the raw-error scoring of zone 15 covers it.
