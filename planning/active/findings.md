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
