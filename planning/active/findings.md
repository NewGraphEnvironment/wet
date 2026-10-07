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


## Pre-registered scoring rule (fixed 2026-10-07, before any product value was computed at any site)

Committed before `scripts/wb_plateau_p.R` existed. Nothing below may change after the first product value is computed at an observation site (climr, PNWNAmet or TerraClimate at a gauge or a course). A change after that point is reported as a deviation, with the as-registered verdict alongside.

**Known when this was written (disclosure):**
- #45's medians: climr / PNWNAmet P is 1.43 in zone 15, 1.61 in zone 24 and 1.15 in other zones. TerraClimate / PNWNAmet is 1.20, 1.15 and 0.93.
- From the source search, counts only: about 38 dry-zone snow courses with ≥ 20 April 1 surveys in 1981–2010, and about 7 dry-zone ASWS gauges with multi-year daily P before 2012.
- The file layouts:
  - `allmss_archive.csv` has one row per survey, with a `Survey Period` column (`01-Apr`);
  - the daily archive is long, with columns `Pillow_ID, Date, variable, value, code`;
  - `PC_Archive.csv` is wide, hourly and cumulative, with one column per station;
  - the PCDS ENV-ASP climatology list holds 23 ids.
- No observed value and no product value had been looked at.

**Sites and groups.**
- **Zone:** hydrologic zone by point intersection with `data/hydz/bc_hydrologic_zones.zip`, as #45.
- **Dry:** zones 15, 17, 23 and 24.
- **Contrast:** every other zone. A site is in the contrast group only if its PNWNAmet cell has data (PCIC's domain).
- **Elevation band:** both groups are held to sites at 900–2,100 m (the site's own published elevation).
- **PRISM-input flag:** a gauge is flagged if it is on PCDS's ENV-ASP climatology list (`services.pacificclimate.org/data/pcds/lister/climo/ENV-ASP/`). climr's BC reference map is BC PRISM, so it is probably anchored there.

**Water year** y runs from 1 October of y−1 to 30 September of y.

**Products at a site:**
- climr: monthly PPT from `climr::downscale()` at the site's lon/lat/elevation, with `refmap_climr`, `obs_ts_dataset = "mswx.blend"` and the year in `obs_years` (to 2024). This is the configuration the water balance uses.
- PNWNAmet: PCIC VIC-GL `PREC` (`TPS_gridded_obs_init`), daily, at the 1/16° cell containing the site (to water year 2012).
- TerraClimate: monthly `ppt` at the 1/24° cell containing the site (to 2024).

Each product is compared only over the water years it covers. Product cells are not elevation-matched to the site; the cell's offset is a stated limitation, not a correction.

**Observations:**
- **Gauge P, by water year.**
  - The ASWS daily archive variable for daily precipitation, through water year 2011. After that, the hourly `PC_Archive`/`PC`, turned into a daily series by daily-mean cumulative P.
  - Day-to-day increments below −50 mm are resets and count 0; increments above 200 mm/day are invalid days; other increments are kept with their sign, so noise cancels.
  - A water year is **complete** with a valid value on ≥ 330 days. Where both sources cover a year, the daily archive wins.
  - A gauge enters a test with ≥ 3 complete water years in the product's years.
- **In-situ catch factor** (gauges with a pillow):
  - per water year: peak SWE (Oct–Jun) ÷ gauge P from 1 October to the day of the peak;
  - the site's factor c = max(1, median over its complete years with peak SWE ≥ 100 mm);
  - catch-adjusted gauge P = gauge P + (c − 1) × gauge P to the peak.
  - This is still a lower bound: pillow SWE loses melt and sublimation.
- **Snow course:**
  - the survey whose `Survey Period` is `01-Apr`, valid SWE (including 0);
  - the course needs ≥ 10 such surveys in the product's water years;
  - product winter P = October–March of that water year.

**Per-site statistic:** a ratio of sums over the site's eligible years, product ÷ observation. **Group statistic:** the median over sites.

**Tests:**
- **T1, gauges, relative (primary).** D(product) = median over dry gauges of product/gauge, ÷ median over contrast gauges.
  - **climr high relative to the rest** if all of these hold:
    - D(climr) ≥ 1.20;
    - ≥ 4 gauges in each group;
    - D(climr) stays ≥ 1.20 with each dry gauge left out in turn (otherwise "unstable");
    - it still holds with the PRISM-flagged gauges removed from both groups; if fewer than 4 dry gauges then remain, this check is "unavailable" and does not fail.
  - The threshold 1.20 is the low end of what #45's pattern implies if PNWNAmet were right everywhere: (1.43…1.61) / 1.15 = 1.24…1.40.
  - D for PNWNAmet and TerraClimate is reported. D(PNWNAmet) ≤ 0.83 (= 1 / 1.20) is reported as "PNWNAmet low, relative" but does not decide.
- **T2, gauges, absolute (corroboration).** Over dry gauges with a catch factor:
  - **holds** if climr ÷ catch-adjusted gauge P ≥ 1.25 at ≥ half of them;
  - **unavailable** with fewer than 3 such gauges.
- **T3, snow courses, lower bound.** For each product, the share of dry courses where product winter P ÷ April 1 SWE < 1.00 (a ratio of sums).
  - A product is **"low there"** if that share is ≥ ½. T3 never names a product high.
  - Also reported, not deciding: each product's dry ÷ contrast ratio of the median P/SWE. Melt and sublimation differ between groups, so it is confounded.

**Verdict:**
- **climr high (ours):** T1 holds, and T2 holds or is unavailable.
- **PNWNAmet low (theirs):** T3 names PNWNAmet low.
- Both can hold. "climr low" from T3 is reported if it occurs.
- **Attribution of #45's climr–PNWNAmet gap:**
  - "ours" if only climr is high;
  - "theirs" if only PNWNAmet is low;
  - "both" if both;
  - "unresolved" if neither.
- If neither holds, name the evidence that would decide it.

**Per zone** (15, 17, 23, 24) every statistic is reported. Zones with fewer than 4 gauges show counts, not verdicts. The verdict is on the pooled dry group.

**What follows:**
- "climr high" → draft the correction issue: candidate layer, independence from the scored gauges, scored under #45's rule (a)–(e).
- Otherwise no correction issue.

## Amendment 2 to the rule (2026-10-07, after a blind plan review, before any product value was computed at any site)

The review is `review-rule.md` in this directory: 4 blockers, 6 gaps, 3 ordering points, 2 assumptions and 2 scope points. Every finding was accepted, some with the changes stated below. Where this amendment and the rule conflict, this amendment wins.

**Firewall.**
- Before this amendment, the raw observation files were downloaded (13:57–13:58), and only their structure was read: headers, variable names, codes, date spans, row counts.
- A first run of the observation stage was started under the old processing. It was stopped before it wrote any cache or printed anything.
- No gauge P, SWE or product value has been looked at.
- A one-cell PCIC fetch was timed at (−122.3, 51.3), which is not a site. Only its dimensions were read.

**Disclosure, added to the rule's:**
- From #45's Amendment 1: TerraClimate ÷ climr per dry zone is 0.80 / 1.14 / 0.91 / 0.76 (zones 15/17/23/24).
- From #45's ECCC check:
  - zone 15 climr ÷ ECCC is 1.05, from 6 stations;
  - at valley stations: Princeton 1.37, Spences Bridge 1.26, Beaverdell North 1.18, Hedley 1.17.
- **PRISM inputs** (A1):
  - PCIC's page confirms only that BC PRISM "integrates data from thousands of temperature and precipitation stations".
  - A secondary page says the BC climatology "was adjusted against snow course measurements and glacier coverage". That was not confirmed at PCIC's own page. If it is true, T3 is partly circular for climr as well.
  - Whether the ASP precipitation was undercatch-adjusted before entering PRISM is not documented anywhere found.
- The ASWS hourly files label their time column `DATE(UTC)`.

**Time.**
- Water years by product:
  - climr: WY 1968–2024, from calendar periods y−1 (Oct–Dec) and y (Jan–Sep);
  - PNWNAmet: WY 1968–2012, daily PREC aggregated to months, with calendar 1967–2012 fetched;
  - TerraClimate: WY 1968–2024, months taken from its time units, not by index.
- The script asserts 12 months per water year for every product.

**Masks and groups:**
- **PCIC domain** (O3): the non-missing mask of one PREC day (1 January 1981). Only `is.na()` is read.
- **Primary contrast** (G6): the interior zones east of the Coast Mountains divide: 2–9, 12–14, 16 and 18–22. Coastal and windward zones (1, 10, 11, 25–29) are excluded. Zone 25 (Eastern South Coast Mountains) is excluded as transitional. The full contrast, every non-dry zone, is reported alongside.
- Both groups are held to PCIC's domain and to the 900–2,100 m band.

**Gauge processing** (G2, G3), replacing the rule's:
- Hourly PC:
  - a reset is an hourly drop ≥ 25 mm, or a fall to below 10 % of the previous reading;
  - increments are zeroed for 72 h after a reset;
  - hourly increments are summed into local-standard-time days (UTC−8), a day valid with ≥ 12 hourly readings;
  - a day whose sum is > 100 mm is invalid.
- Per site-year, the Jun–Sep sum of negative daily increments is reported; site-years above 25 mm are **flagged**.
- Daily archive (WY ≤ 2011): variable `P`, valid where the code does not start with `M`. A day > 100 mm is invalid.
- **Check (a), before stage 3:** over gauge-years complete in both sources (WY 2004–2011), ΣP from the daily archive ÷ the hourly-PC total must be within 0.95–1.05 at the median. Only the ratio is printed. A failure stops the run.
- **Covered months** (G3c): a month is covered with ≥ 27 valid days. A water year is complete with ≥ 330 valid days. The gauge and every product are summed over the covered months of that year only.
- **Catch factor:** c is as registered, but uses peak SWE ≥ 100 mm. G1:
  - c is reported as a median by group;
  - if the group medians differ by > 10 %, the primary D uses catch-adjusted P in both groups.

**Stage 2 prints no magnitude** (O1): counts, years, flags and medians of c only. Any change to a processing parameter after stage 2 has run is a deviation and is reported as such.

**T1, replaced** (B4, S1, S2, G1, G3b, G4, A1). D(product) = median over dry gauges of product ÷ gauge, divided by the median over primary-contrast gauges.
- **Outcomes:**
  - "climr high, relative": D(climr) ≥ 1.15;
  - "climr not high, relative": D(climr) ≤ 1.05;
  - in between: "inconclusive".
- **Conditions on any outcome** (if one fails, the outcome is "unavailable" or "unstable", as named):
  - ≥ 4 gauges in each group, and the dry gauges from ≥ 2 zones;
  - leave-one-out on **both** groups keeps the same outcome ("unstable" otherwise);
  - the flagged site-years removed: same outcome;
  - by era (WY ≤ 2011 / ≥ 2012), in each era with ≥ 4 gauges per group: "climr high" needs D ≥ 1.00 there, and "not high" needs D ≤ 1.10 there. Otherwise "era-dependent";
  - on sites with |Δz| ≤ 200 m between the site and climr's reference-map cell (climr's `dem2_WNA`): same outcome, or "unavailable" below 4 per group;
  - on unflagged gauges (not in the PCDS ENV-ASP climatology list): same outcome. Below 4 dry gauges this is "unavailable". **"climr not high" needs it available.**
- **Reported, not deciding:**
  - a bootstrap 90 % interval on D (2,000 draws resampling sites within each group, seed 50);
  - D by season (Oct–Apr, May–Sep);
  - D against the full contrast;
  - D against an elevation-matched contrast (within the dry gauges' elevation IQR);
  - the zone mix, stating plainly if zone 15 has < 2 gauges;
  - Δz per product (PNWNAmet and TerraClimate cells as the mean of `dem2_WNA` over the cell).

**B3 precondition (product against product, no observation):**
- R = median over dry gauge sites of climr ÷ PNWNAmet, divided by the same over primary-contrast gauge sites.
- Both are taken on the gauge-years used for T1 with WY ≤ 2012.
- If R < 1.10, the verdict is "unresolved: the gauge sites do not show #45's gap", whatever T1 says.
- R is reported per zone.

**T2, replaced (B1): a veto.** Over dry gauges with a catch factor, if climr ÷ catch-adjusted gauge P < 1.00 at ≥ half of them (≥ 3 needed, else not applied), "climr high" is vetoed.

**T3, replaced (G5, G4):**
- the survey dated 20 March–10 April in its water year;
- product winter P runs from 1 September to the survey date: whole months, plus the survey month's fraction (day − 1) / days in month;
- all three products over WY 1982–2010;
- courses enter with ≥ 10 surveys in that window and a median SWE ≥ 100 mm; courses with a zero SWE sum are dropped and counted;
- a product is "low there" if its winter P ÷ SWE (a ratio of sums) is < 1.00 at ≥ half the dry courses;
- "PNWNAmet low" must also hold on the courses whose PNWNAmet cell is no more than 100 m below the course (≥ 4 needed, else that check is "unavailable" and does not fail).

**Verdict, replaced (B1, B2):**
- **climr high** = B3 precondition met, T1 "climr high", and no T2 veto.
  - If T3 names climr low, it becomes "conflicted", and no correction issue follows.
- **climr not high** = B3 precondition met and T1 "climr not high". This revises #45's "leaning ours".
- **Attribution of #45's gap**, on gauge-relative D for both products, under the same conditions:
  - **ours:** climr high, and D(PNWNAmet) > 0.90;
  - **theirs:** D(PNWNAmet) ≤ 0.83 and D(climr) < 1.10;
  - **both:** climr high and D(PNWNAmet) ≤ 0.83;
  - **unresolved:** otherwise.
- **T3** stands as a separate absolute finding: "<product> below the lower bound".
- **What follows:** "climr high" with attribution "ours" or "both" → draft the correction issue. Otherwise there is no correction issue, and the write-up names the evidence that would decide it.

## Deviation 1 (2026-10-07): gauge P from hourly PC is floored at 0 per day, as the daily archive defines it

**As registered, the run stops at check (a).**
- Over 285 gauge-years at 50 sites complete in both sources (WY 2004–2011), daily-archive ΣP ÷ hourly-PC total had a median of **1.156**. The limit was 0.95–1.05.
- No product value had been computed. Stage 2 printed only that ratio and counts.

**Cause, from QA on every daily-archive gauge-year in WY 2004–2011, ratios only** (`scratchpad` script, logged in `progress.md`):
- **The archive's daily `P` is the positive part of the day's change in its own `AccumP`.**
  - P = max(0, ΔAccumP) within 0.5 mm on 79 % of days; P = ΔAccumP on 61 %.
  - Over a gauge-year (331 of them), ΣP ÷ Σ max(0, ΔAccumP) has a median of 0.97, and ΣP ÷ Σ ΔAccumP a median of 1.08.
- The registered hourly processing kept negative day sums "with their sign, so noise cancels". The two eras therefore measured different quantities, which check (a) existed to catch.

**Change.**
- In the hourly era each valid day's P is max(0, day net), the agency's own definition. Days and resets are otherwise as registered.
- The Jun–Sep flag still reads the signed day net in the hourly era. In the daily era it read the archive's P, which is ≥ 0 by construction, so it fired almost never there. Corrected in Deviation 1c.
- `obs_method` is bumped. Check (a) is rerun unchanged and must pass.

**Bound.**
- The as-registered outcome is "no verdict: stopped by check (a)".
- T1's era condition reports D on WY ≤ 2011 alone. As first written, this said that era was untouched and that a verdict depending on the change would show as "era-dependent". Code-check round 3 showed both were asserted, not measured:
  - Deviation 1b later changed that era (D 1.0058 → 1.0105);
  - the era test only checks D ≥ 1.00 (or ≤ 1.10), so a "high" that existed only because of the floor would pass it.
  The era D is reported, and the reader compares it.
- The direction is known: flooring raises gauge P where days are noisy, which lowers product ÷ gauge. If noise is larger at the dry gauges (low P, warm summers), this works against "climr high".

## Correction 1 (2026-10-07, code-check round 1): the catch factor counts only years covered from October to the peak

**The defect.** The registered catch factor is peak SWE ÷ gauge P "from 1 October to the day of the peak". The script summed that gauge P over covered months only, while the pillow's peak builds up over every day.
- 337 of 1,616 catch-factor years (21 %) had 1–3 uncovered months before the peak.
- Their ratios were too high by a median ×1.21 (reviewer's estimate, weighting the missing months by climr).

**Fix.** A year counts toward c only when every month from October to the peak's month is covered. This implements the rule as written. Because stage 2 had already run, it is recorded here, as O1 requires.

**Effect, measured** (the obs caches before and after, compared by code-check round 2). Dropping years from a site's median can move c either way:
- c_raw fell at 79 gauges and rose at 8;
- c itself rose at one gauge, 1E11P (contrast), from 1.17 to 1.39;
- the group medians of c stayed 1.00 / 1.00, so the G1 switch stays off;
- the T2 share stayed 0.23.

Also fixed in the same round:
- the group medians of c now drop NA;
- the seasonal D uses raw gauge P;
- the cell-elevation cache is keyed on the climr version;
- a B3 shortfall of gauges is reported as that, not as "the gauge sites do not show #45's gap".

## Deviation 1b (2026-10-07, code-check round 2): the daily archive's negative P is floored too

**The inconsistency.** Deviation 1 floored hourly-era days at 0 because the archive defines P as max(0, ΔAccumP). The archive's own negative P values were still used with their sign, as Amendment 2's text had it.
- There are 419 negative values; the lowest is −872 mm.
- In T1's site-years and covered months: 186 negative days summing to −3,314 mm.
- Almost all are at contrast or "other" gauges in WY 2008–2009. One is at a dry gauge (3A24P, −1 mm, WY 2008), and six are in WY 2007 (1A03P −6 mm, 1D06P −17 mm). The original sentence said "none dry" and was copied from round 2 without recomputing; round 3 corrected it.
- Worst: 1A14P WY 2008, with −1,602 mm of negatives against 459 mm net.

**Change.** The archive's P is floored at 0 as well. The Jun–Sep flag still reads the signed value.

**Effect** (reviewer's recomputation before the change):
- D(climr): 1.0915 → 1.0916;
- unflagged: 1.1889 → 1.1890;
- era ≤ 2011: 1.0058 → 1.0105;
- D(PNWNAmet): unchanged at 0.9148.
- Also: check (a) 1.0093 → 1.0110; c changed at 3 gauges (1A01P, 1D15P, 4B16P); the group medians of c stay 1.00 / 1.00 and the T2 share 0.23 (round 3).

## Deviation 1c (2026-10-07, code-check round 3): the daily era's Jun–Sep flag reads the archive's AccumP

**Mechanism** (named by round 3, which enumerated every ratio and comparison in the script: 25 rows, the table in `review-round3.md`). The gauge's daily increment is derived twice, once per era:
- hourly era: from the cumulative PC;
- daily era: the agency's P, taken to be the same quantity.

It is not: the agency's P is max(0, ΔAccumP). Deviation 1 and 1b aligned the P sums. The flag was the remaining place the difference reached. Every other row of the enumeration is the same population on both sides, or differs as the rule intends.

**The defect.**
- On the 285 overlap gauge-years, the daily-era flag as coded fired 0 times, where the hourly flag fired 196.
- Over all years: 1 of 465 daily-era site-years flagged, against 282 of 825 hourly ones.
- So "flagged years removed" removed mostly hourly years.

**Change.**
- The daily-era signed increments are taken from the archive's `AccumP`: day-to-day changes, with the hourly reset rule (a drop ≥ 25 mm, or a fall below 10 % of the previous value; 72 h, i.e. 3 days, zeroed after).
- The report prints both sources' flag counts on the overlap years.

**Expected effect** (round 3's recomputation):
- climr D with flagged years removed: 1.1427 → about 1.20, which crosses 1.15, so T1 gains "unstable (flagged years)";
- the verdict stays "not decided".
