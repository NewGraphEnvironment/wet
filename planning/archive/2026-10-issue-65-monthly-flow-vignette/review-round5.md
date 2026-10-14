# Code-check round 5 (#65): branch review

Method: `git archive HEAD` into a scratch directory, `knitr::purl` of `vignettes/monthly-flow.Rmd`, run under `pkgload::load_all` (the run completes, every stopifnot passes), environment saved, and each filter and characterising sentence recomputed from that. No repo file was touched other than this one.

## Findings

- **[bug] vignettes/monthly-flow.Rmd:409, 501, 509, 548–550 (and 649, "reads high in winter")**: the enumeration lists four filters, but it misses a fifth one that feeds the balance's statistics: **routed coverage**. Of the 315 calibration gauges, 290 have routed flow, and the balance is scored only on the 279 that remain after the far cut. The section opens with "Monthly flow is scored at the 315 gauges the water balance is calibrated on". The restriction to routed's set was then judged neutral for the balance without recomputing it.
  - **The filter moves the balance's medians.** Over all 315 held-out gauges, its monthly medians are Jan +8.3, Feb +10.1, Mar +8.5, Apr +16.2, May +7.6, **Dec +1.2**. Over the 279 they are Jan +12.8, Feb +14.6, Mar +10.4, Apr +13.8, May +7.6, Dec +6.0. Over 290 (the far gauges kept), December is +5.7.
  - **The guard fails over the 315.** Over the 315, `min(wb_winter) > 5` is FALSE, because December is +1%, which is inside the ±5% band the bullet reserves for June to November. The sentence "reads high from December to May, by a median of +6% to +15%" holds only on routed's coverage.
  - **The filter is correlated with the balance's error, not neutral.** The 25 gauges routed does not cover (10A/10B/10C Liard 19, 09A 1, 08M/08N 5) carry 33 more zero months: 123 over 315, against 90 over 279. At those 25 the balance's medians are Jan −68%, Feb −89%, Mar −96%: low in winter, the opposite sign to the article's "reads high in winter".
  - **Fix.** Either state that the balance is scored on routed's 279 gauges and that its winter shape differs where routed has no flow, or give the balance's winter claim over its own 315 (Jan–May high, December within ±5%). Separately, the December arm passes its guard by 1.0 pp even on 279 (+6.03 > 5).

- **[bug, small] vignettes/monthly-flow.Rmd:505–508, 555–557**: "at the 211 gauges whose observed **flow** peaks in May or June" is computed on `obs_mm`, which is monthly volume, so 31-day months are favoured.
  - **The peak month changes at 14 gauges.** Taken by flow (`obs_mm / days`), it differs from the volume peak at 14 of the 279 gauges.
  - **The quoted numbers change.** Peaks taken by flow give 212 gauges, 71% below, median −14%. The prose says 211, 72% and −15%.
  - **The article uses both definitions.** The Buck Creek section ("the gauge peaks in May") takes peaks from m³/s (`hyd`).
  - **Fix.** Divide by `days[month + 1]` before `which.max`, or say "monthly volume".

- **[fragile, not reachable with today's bundle] vignettes/monthly-flow.Rmd:269–271, 275, 509–513**: round 4's `one()` wraps `peak_month` and `nse_g`, but not the `hq()` lookups or `smv()`.
  - **Mutation 1, passes vacuously.** Removing 08EE004's observed Jan–Apr rows from `hyd` makes `stopifnot(all(hq("08EE004","wet_balance",1:4) > hq("08EE004","observed",1:4)))` **pass**, because `logical(0)` passes stopifnot.
  - **Mutation 2, fails for the wrong reason.** Removing one month makes it fail only through misaligned recycling (a warning, then a comparison of the wrong months).
  - **`smv()` has the same gap.** An empty `smv()` gives `min(numeric(0)) > 5`, which is TRUE.
  - **Unreachable today.** The data script asserts 13 rows per gauge and 2×13×3 segment rows, so neither case can occur with this bundle. This is the same class round 4 marked as unreachable.

## Checked and clean (recomputed)

**Filters, each with and without:**
- `far` (11 gauges, same list as the routed report's section):
  - routed over 290: spring −21.3, summer +17.3; `r_closer` is unchanged (1 2 4 5 6 7 8 9 10 12, May–Sep in).
  - routed NSE: 0.80 over 290 against 0.81 over 279.
  - group table over 290: routed below the balance only for <100 km² (0.38 vs 0.56); lake outlet balance 0.51, the lowest group; routed at lake outlets 0.91. The prose holds.
  - period over 115 (far kept): −19.4 / +8.9 against own period, −23.2 / +13.8 against 1981–2010. The prose holds.
- Long-record threshold, at 40, 45 and 50 years (113, 78 and 39 gauges):
  - period medians stay at −7 / +6 to +7;
  - routed own-period medians are −18.5…−20.5 (spring) and +9.6…+12.3 (summer);
  - explained is 0.18…0.27 (spring) and 0.28…0.32 (summer);
  - the per-gauge shape shares are low 65–69%, high 63–74%, both 40–51%.

  Every guard and every sign in the prose holds at each threshold.
- Window years (`min_frac`): 0.8 and 1.0 give identical tables. Good and poor windows are unchanged.
- The July reason: replacing the July days in the fry window by the actual Jul 15–31 mean cuts the approximation error from +26.8% to +1.8% (08EE013), and from +24.3% to +1.1% (08EE003). The "because" holds.
- 08EE003 month rule: months with ≥ 10 years are May–Oct (18, 18, 18, 18, 19, 15). April has 7 and November 4. The rule as stated gives May–October.
- Balance zeros: 90 in the 279-gauge set, 34 in January; every one is at a gauge with a positive held-out annual, so "share is zero" is correct.

**Sentences:**
- **Counts and the far list.** 315 → 290 → 279 and 3,348 gauge-months check. The far list matches the report's 11 and its three attribution categories.
- **What a month holds.** Routed month 0 is a plain mean, at most 0.4% from the day-weighted mean. The balance's months sum to month 0 exactly.
- **Buck Creek.** Peaks in May for both the gauge and routed, and routed overshoots. The balance peaks under half the gauge's and in June. The balance is above the gauge from July to March.
- **Quick.** −23.7% and −23.9% in May–June. The balance is high from January to April, and routed in July–August.
- **Shape is not size.** Routed's shape survives normalising each gauge by its annual ratio: spring −17.8%, summer +22.1%. That supports "mostly in size … would not move the median".
- **Period data.** `q_m3s_8110` equals the calibration observed flow exactly. `routed_q` back-converted with `area_km2` equals the published segment q exactly (08EE013, 08EE004).
- **Tests and lib.** The tests, `scripts/vignette_data_lib.R` and the data script raised nothing new.
