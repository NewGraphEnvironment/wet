# Code-check round 3: scripts/wb_plateau_p.R (#50)

What I read: the rule (the Pre-registered rule, Amendment 2, Deviation 1, Correction 1 and
Deviation 1b), review-rule.md, the round 1 and round 2 reviews, the full script, the report and the
caches. Stage 2 was rebuilt in the scratchpad from the raw snapshots. It is lines 136-308 of the
script, unchanged, run against `data/plateau_p/raw/`, and its `cf` and `check_a` equal
`obs_e6a54f11fb.rds` (checked with `all.equal`). Every probe below runs on that rebuild, or on
`plateau_p.rds` and the obs caches. The script itself was not run, and no repo file was modified
except this one.

## Mechanism

**One fact is derived twice, once per era.** The fact is "the gauge's daily increment of
cumulative precipitation".
- **Hourly era (WY ≥ 2012):** the script derives the increment itself, from `PC` readings.
- **Daily era (WY ≤ 2011):** the script takes the agency's `P` column and assumes it is the same
  quantity.

It is not the same quantity. The agency's `P` is max(0, ΔAccumP), as Deviation 1 found, with
reset artefacts on top. Each consumer of "the daily increment" therefore gets the gap between the
two derivations, unless that consumer was patched on its own:

- **Round 2's instance:** the gauge P sum carried the sign convention differently in the two eras.
- **Round 1's instance:** the same shape, one side of a ratio filtered and the other not. The
  catch factor's denominator was restricted to covered months, but its numerator was not.

Deviation 1 and Deviation 1b repaired the P sum, the two sides of check (a) and the catch-factor
denominator. Nothing changed the representation, so each later consumer has to be found by hand.
The Jun-Sep flag is the consumer still missed (Finding 1).

The rule's own wording carries the assumption. "Per site-year, the Jun-Sep sum of negative daily
increments" presumes that both eras have signed daily increments. Only the hourly era does.

The table below enumerates every ratio, difference and comparison in the script, with the
population of each side.

## Enumeration (table)

"Same" means the two sides cover the same days, months, water years, sites, sign convention and
units, up to the measured residual shown.

| # | Line(s) | Quantity: side A vs side B | A's population | B's population | Verdict |
|---|---|---|---|---|---|
| 1 | 230-233 | check (a): daily ΣP ÷ hourly ΣP | Daily-archive valid days (not M-coded, ≤ 100 mm, floored) in years complete in both sources, WY 2004-2011 | Hourly valid days (≥ 12 h, net ≤ 100, floored), same years | Differs in days: the daily side has a median of 3 more valid days. This is what the rule asks for ("ΣP ÷ the hourly-PC total"). On matched days the ratio is 1.009, against 1.011 as coded, so the residual is negligible. |
| 2 | 218-222, 236 | Gauge P across eras within one site's sum | Agency P = max(0, ΔAccumP), M filter, ≤ 100, floored (Deviation 1b) | Σ hourly increments per UTC−8 day, floored, ≤ 100, script resets | Same after Deviations 1 and 1b. Check (a) is 1.01, and the day alignment is right: daily against hourly day correlates at r 0.85 at lag 0, 0.38 at −1 and 0.28 at +1. Gap-bridging and reset rules differ, as accepted (7). |
| 3 | 469-476, 486 | T1 site ratio: product ÷ gauge | Product over whole calendar months that are covered months of complete years, WY ≤ wy_max | Gauge over the valid days (≥ 27) of the same months | Differs: the product counts every day and the gauge only its valid days. G3c sanctions this. Measured: 0.37 % of covered-month days are missing, with site medians of 0.18 % (dry) and 0.30 % (contrast). Infilling the gauge at the month's mean moves D(climr) from 1.0916 to 1.0925, and unflagged D from 1.1890 to 1.1921. Negligible. |
| 4 | 261-281 | Catch factor: peak SWE ÷ P from Oct 1 to the peak | Pillow peak, Oct-Jun, every day | Gauge valid days in covered months from Oct to the peak's month (Correction 1) | Same after Correction 1. Days missing inside covered months: median 0 % of the days to the peak, 90th percentile 1.0 %, maximum 7.5 %. |
| 5 | 256-257 | Catch factor across eras | Daily-archive SWE (WY ≤ 2011) | Mean of the hourly SW readings per day (WY ≥ 2012) | Same: at the 49 sites with c-years in both eras, the median per-site ratio of hourly-era to daily-era c is 1.005. |
| 6 | 475 | adj = obs + (c − 1) × p_to_peak | obs: covered months, WY ≤ wy_max | p_to_peak: covered-month days to that year's peak, or to the site's median peak day | Same months. Using the median peak day is accepted (5). |
| 7 | 490-495 | T1 D: median over dry ÷ median over contrast | Dry gauges, each over its own eligible years | Primary-contrast gauges, each over its own eligible years | Differs in years, as the rule intends: the per-site statistic is taken over the site's eligible years, and the era condition is the guard. |
| 8 | 517-519 | T1 leave-one-out | Both groups, one site dropped | Same | Same |
| 9 | 247-252, 520-522 | **T1 with flagged years removed.** Flag = Jun-Sep Σ negative daily increments > 25 mm | **Daily era: the agency's signed P, which is ≥ 0 by construction apart from reset artefacts** | **Hourly era: the signed day net from cumulative readings** | **Differs: BUG (Finding 1).** On the 285 gauge-years present in both sources, the as-coded daily-era flag fires 0 times, the hourly flag 196 times, and a flag computed from the daily ΔAccumP 195 times (189 years in common with the hourly flag). |
| 10 | 523-531 | T1 by era | wy ≤ 2011 = the daily source | wy ≥ 2012 = the hourly source | Same: one split for both |
| 11 | 532-537 | T1, \|dz\| ≤ 200 m | One filter applied to both groups | Same | Same |
| 12 | 538-542 | T1, PRISM-unflagged | Removed from both groups | Same | Same |
| 13 | 336-337, 498-499 | G1: median c (dry) ÷ median c (contrast) | All in-use gauges with c, including those with fewer than 3 years | T1's sites (the D it switches) | Differs in sites. The rule does not specify which. Measured: 1.00 and 1.00 on either set, so G1 stays off either way. |
| 14 | 554-562 | B3: climr ÷ PNWNAmet per site | climr over gm rows with WY ≤ 2012 in the PNWNAmet T1 years | PNWNAmet over the identical (pid, ym) | Same |
| 15 | 563 | B3 R: dry ÷ contrast | As #7 | As #7 | Same as T1 |
| 16 | 656-662 | Attribution: D(climr) against D(PNWNAmet) | climr WY ≤ 2024: 13 dry, 46 contrast | PNWNAmet WY ≤ 2012: 7 dry, 29 contrast | Differs, as Amendment 2 is written; accepted (4) |
| 17 | 570-576 | T2: climr ÷ catch-adjusted gauge P | climr over the same rows as #6 | adj over the same rows | Same |
| 18 | 580-597 | T3: product winter P ÷ survey SWE | From 1 Sep of WY−1 to the survey date (whole months plus the (day − 1) / days fraction), for the same surveys in all products, WY 1982-2010 | SWE of the surveys in the 20 Mar-10 Apr window | Same. The measured quantities differ (P against SWE), which is the lower bound the rule names. |
| 19 | 605-610 | T3, PNWNAmet cell no more than 100 m below the course | Dry courses with dz ≥ −100 | Same rule on the same set | Same |
| 20 | 602 | T3 dry ÷ contrast factor | Dry courses | Contrast courses | Differs in melt and sublimation, a confound the rule names; reported only |
| 21 | 627-629 | Seasonal D | Product over the season's covered months | Raw gauge P over the same months | Same |
| 22 | 630, 633-634 | Full and elevation-matched contrast | Dry | Contrast + other, or contrast within the dry gauges' IQR | Same (as the rule defines them) |
| 23 | 619-625 | Bootstrap | Sites resampled within each group | Same | Same |
| 24 | 362-433 | Product against site | climr at the site's point and elevation | PNWNAmet and TerraClimate at the cell | Differs, as intended (2); Δz is reported |
| 25 | 441-456 | Δz: cell − site | climr: DEM at the point. PNWNAmet and TC: mean DEM over the cell | Published site elevation | As Amendment 2 G4 specifies |

## Findings

- **[severity: bug]** scripts/wb_plateau_p.R:222 with 247-252: the Jun-Sep flag measures different
  quantities in the two eras. For WY ≤ 2011, `net` is the agency's signed `P`. Deviation 1
  established that this is max(0, ΔAccumP), so it is negative only at reset artefacts. For
  WY ≥ 2012, `net` is the signed day net from cumulative readings. The rule's flag is "the Jun-Sep
  sum of negative daily increments", which exists in the daily era only as ΔAccumP. `daily.csv`
  carries `AccumP` (450,712 rows), but the script reads only `P` and `SWE`. This is the third
  consumer of the assumption behind rounds 1 and 2, and Deviations 1 and 1b did not reach it.
  - **Overlap:** on the 285 gauge-years present in both sources (WY 2004-2011), the flag as coded
    from the daily `P` fires 0 times. The hourly flag on the same years fires 196 times. A daily
    flag from consecutive-day ΔAccumP (increments ≤ −25 mm dropped as resets) fires 195 times,
    with 189 years in common with the hourly flag.
  - **As coded:** 1 of 465 daily-era site-years at used gauges is flagged, against 282 of 825
    hourly ones (report line 21: 283 of 1290). For PNWNAmet (WY ≤ 2012), 27 of 500 rows are
    flagged, nearly all of them WY 2012. "Flagged years removed" is therefore mostly "a third of
    the hourly years removed", and for PNWNAmet the check is close to vacuous.
  - **Effect.** Replacing the daily-era flag with the ΔAccumP flag (387-393 of 560 daily-era
    site-years flagged, depending on the reset handling) gives:

    | | As coded | With the ΔAccumP flag |
    |---|---|---|
    | climr D, flagged years removed | 1.1427 (dry 12, contrast 44) | 1.1986 (dry 10, contrast 42) |
    | PNWNAmet D, flagged years removed | 0.9373 | 0.888-0.912 |

    - climr: 1.1986 is "high" against a primary class of "inconclusive", so T1's status gains
      "unstable (flagged years)".
    - PNWNAmet: its value falls into "between", so its status gains "unstable (flagged years)" too.
    - The verdict's decision is unchanged ("not decided"), but its printed T1 status changes. The
      condition sits across the 1.15 threshold, so a run on other gauges could turn on it.
  - **Fix:** derive the daily-era flag from the day-to-day ΔAccumP (consecutive days, with the
    hourly reset rule), or record in a deviation that the flag is effectively hourly-era only.
    Bump `obs_method`. Since stage 2 and the tests have run, record the change as O1 requires,
    with the numbers above.

- **[severity: bug]** planning/active/findings.md:225: Deviation 1's "Change" says the flag reads
  "the signed day net (and daily-archive P < 0 before WY 2012), so it still marks
  evaporation-prone site-years". For the daily era this is false: see the overlap figures above
  (0 of 285 as coded, against 196 hourly). Deviation 1b repeats it at line 261. These are the
  deviation records O1 requires, so they should state what the flag actually marks.

- **[severity: bug]** planning/active/findings.md:230: Deviation 1's "Bound" says "The WY ≤ 2011
  era is untouched by this change. T1's era condition reports D on it alone, so a verdict that
  depends on the change shows up as 'era-dependent'." This fails in two ways.
  - **No longer true.** Deviation 1b floors the daily era too, and its own Effect lists era ≤ 2011
    moving from 1.0058 to 1.0105. The report's line 4 says "floored at 0 in both eras".
  - **Never true by construction.** The era condition tests only D ≥ 1.00 (for "high") or D ≤ 1.10
    (for "not high") in each era. A "high" verdict that existed only because of the floor (overall
    D 1.16, era ≤ 2011 D 1.02) would pass it. The bound was asserted, not measured: the same defect
    as round 2's "can only lower c". It should be replaced with the measured as-registered against
    floored D, or removed.

- **[severity: bug]** planning/active/findings.md:258: Deviation 1b says "All are at contrast or
  'other' gauges in WY 2008-2009; none is at a dry gauge." Two parts are false. Of the 186
  negative days in T1's site-years and covered months:
  - one is at dry gauge 3A24P (−1 mm, 2007-11-02, WY 2008);
  - six are in WY 2007: 1A03P (contrast, −6 mm) and 1D06P (other, −17 mm over 5 days).

  The magnitude is trivial, but the sentence is the deviation's scope statement. It was copied
  from round 2's text rather than derived. The other numbers in Deviation 1b check out against the
  rebuild: 419 negatives, minimum −872, 186 days summing to −3,314 mm, 1A14P WY 2008 at −1,602
  against 459, and the D values 1.0916, 1.1890, 1.0105 and 0.9148.

- **[severity: fragile]** planning/active/findings.md:263-267: Deviation 1b's "Effect" lists D
  only. The change also moved:
  - check (a) from 1.0093 to 1.0110 (obs_334940405e against obs_e6a54f11fb);
  - c at 3 gauges: 1A01P 1.028 → 1.020, 1D15P 1.266 → 1.266 (barely), and 4B16P 1.061 → 1.000.

  The group medians of c stay at 1.00 and 1.00, and T2's share stays at 0.23. O1 asks that a
  stage-2 change be reported, so these belong in the record.

## Written claims checked (Deviation 1, Correction 1, Deviation 1b)

| Claim | Check | Result |
|---|---|---|
| D1: 285 gauge-years, 50 sites, as-registered median 1.156 | obs_cddc38772c check_a | 285, 50, 1.1562: true |
| D1: P = max(0, ΔAccumP) within 0.5 mm on 79 % of days; P = ΔAccumP on 61 % | rebuild, and scratchpad diag_a.R | 0.792, 0.609: true |
| D1: 331 gauge-years; ΣP ÷ Σmax(0, Δ) 0.97; ΣP ÷ ΣΔ 1.08 | diag_a.R rerun | 331, 0.969, 1.08: true |
| D1: hourly days floored; days and resets otherwise as registered | code 193-203 | true |
| D1: the flag "still marks evaporation-prone site-years" | overlap: 0 of 285 as coded, against 196 | **false for the daily era** (Finding 2) |
| D1: check (a) rerun must pass | obs_334940405e 1.0093; current 1.0110 | true |
| D1 Bound: WY ≤ 2011 era untouched; dependence shows as era-dependent | Deviation 1b and the era-condition logic | **false** (Finding 3) |
| D1 Bound: flooring lowers product ÷ gauge | by construction, per site | true (direction only) |
| C1: 337 of 1,616 years affected | pk: 1,616 rows, 1,279 full | true |
| C1: ×1.21 median inflation | round 1's estimate | not re-derived (labelled an estimate) |
| C1: c_raw fell at 79, rose at 8 | obs_7839 against obs_3349 | true |
| C1: c rose only at 1E11P, 1.17 → 1.39 | same | true (1.1727 → 1.3867) |
| C1: group medians 1.00 / 1.00; G1 off; T2 share 0.23 | current cache | true (also 1.00 / 1.00 on T1's sites) |
| C1: NA-dropping cmed, raw seasonal D, cellz key, B3 shortfall string | code 337, 627-628, 438-439, 640-641 | true |
| D1b: 419 negatives, minimum −872 | raw daily.csv (non-M; also any code) | true |
| D1b: 186 days, −3,314 mm in T1's site-years and covered months | rebuild | true |
| D1b: all at contrast or other, WY 2008-2009, none dry | rebuild | **false** (Finding 4) |
| D1b: 1A14P WY 2008 −1,602 against 459 net | rebuild | true (floored total 2,061) |
| D1b: D 1.0915 → 1.0916; unflagged 1.1889 → 1.1890; era ≤ 2011 1.0058 → 1.0105; PNWNAmet 0.9148 | plateau_p.rds | true (1.0916, 1.1890, 1.0105, 0.9148) |

## Report header (data/checks/wb_plateau_p.txt) checked

| Line | Value | Result |
|---|---|---|
| 4 | as-registered check (a) 1.156 | true (1.1562) |
| 6 | snapshot 2026-10-07 | true (raw mtimes) |
| 7-16 | ten md5s | all ten match `md5 -r` of `data/plateau_p/raw/` |
| 17 | climr 0.2.2 | true (installed) |
| 19 | check (a): 285 gauge-years, 50 sites, 1.01 | true (1.0110) |
| 20 | c medians dry 1.00, contrast 1.00; raw | true; `use_adj` FALSE |
| 21 | flagged 283 of 1290 | true as computed, but 282 of the 283 are hourly-era (Finding 1) |
| 22 | 4A29P 1984, 1985, 1989, 1990; 722 rows | true. 4A29P has no rows at all in 1986-1988, so no ambiguous year-day-month year escapes the drop. |

/Users/airvine/Projects/repo/wet/planning/active/review-round3.md
