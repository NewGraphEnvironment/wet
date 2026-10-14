# Code-check round 4 (#65): branch review

Method: ran the vignette's code from a `git archive HEAD` copy (`pkgload::load_all`, `knitr::purl`), evaluated all inline values, and recomputed each claim under other definitions of its set. No repo file was touched other than this one.

## Mechanism (new)

Round 3's filter-neutrality pass settled neutrality **by argument rather than by recomputing without the filter**. The enumeration keeps `obs_mm < 1 mm` because it "is a property of the gauge, not of either model, so it moves both sources alike". That is the same unmeasured assumption round 3 found behind the zero-month filter, and recomputing without the filter shows it is false (finding 1). A second form of the same gap: some characterisations are **generalised from the worked example to a named set** ("snowmelt gauges such as Buck Creek", "shared across the gauges"). No computation runs over that set, and when one is run it contradicts the sentence (findings 2 and 4).

## Findings

- **[bug] vignettes/monthly-flow.Rmd:398, 403, 536 (`min_mm`, "highest in April")**: the 1 mm filter is not neutral, and it decides the balance's peak month. There is no observed zero among the 3,348 gauge-months, so every ratio is defined without the filter. Keeping the 33 low months (obs > 0) gives these balance medians: Jan +11.5 → +12.8, **Feb +10.1 → +14.6**, Apr +13.5 → +13.8, Dec +4.9 → +6.0. The highest month becomes **February, not April**, and the winter range becomes +6% to +15%, not +5% to +13%. Routed moves much less (Feb −6.6 → −5.8, Dec −4.2 → −2.3), so the enumeration's "moves both sources alike" is measured false. April leads January by only 2 pp even with the filter, so the parenthetical rests on the filter choice. Fix: drop "(highest in …)", or report the medians with and without the 1 mm cut. If the cut is kept, the enumeration should not call it neutral.

- **[bug] vignettes/monthly-flow.Rmd:542–543**: "That flattens the freshet at snowmelt gauges such as Buck Creek and moves its water into the months after it" gets the direction wrong over its named set. The "flattens" half holds. Among the 279 scored gauges, 211 have their observed peak in May or June. At those 211:
  - The balance is below the gauge in the peak month at 72% of them (median ratio 0.85).
  - The balance's peak month equals the gauge's at 78% and is later at only 11%. Buck Creek, peaking a month late, is in that 11%.
  - The median balance/observed ratio is **1.04 over the three months after** the observed peak, against **1.19 over the three months before** it.

  So the balance moves the water mainly into the months *before* the freshet. That is also what the pooled figure in the same bullet shows: high December–May, within ±5% June–November. It is also what a share model without a snow term would do. "After" is Buck Creek's pattern, not the snowmelt gauges'. Fix: "moves its water into winter and early spring", or confine the "after" clause to Buck Creek.

- **[fragile] vignettes/monthly-flow.Rmd:535–537, guard 502–504**: the guard's threshold does not support the qualitative split "reads high from December to May … within ±5% from June to November". December's median is +4.89% and September's is +4.46%, so `min(wb_winter) > max(abs(wb_summer))` passes by 0.43 pp. The error table then prints Dec "+5%" beside Aug "+4%" and Sep "+4%", and the prose calls the first "high" and the others "within ±5%". Under the obs > 0 definition December is +6.0%, so the split there also depends on finding 1's filter. Fix: name January–May as high and leave December out, or assert a margin between the two sets that the wording implies.

- **[fragile] vignettes/monthly-flow.Rmd:564–566**: "What is left is a shape error shared across the gauges" is a claim over the gauges that nothing computes, and a per-gauge measure does not support "shared across". At the 113 period gauges, against their own 1951–2012 means:
  - routed's March–April median ratio is below 1 at 66% of gauges;
  - its July–August median ratio is above 1 at 63%;
  - only **40%** show both.

  At the 279 scored gauges against 1981–2010 the shares are 69%, 69% and 48%. The pattern is a property of the median, not of most gauges. The next sentence argues from "the median of 279 gauges", but the residual it explains ("what is left", after the period) is measured over the 113. Fix: "a shape error in the median gauge", and use the 113 (or the set the residual is over) in the placement sentence.

- **[fragile, not reachable with today's bundle] vignettes/monthly-flow.Rmd:226, 595–598**: `stopifnot()` passes on `logical(0)` (R 4.5.2, measured). Two guards can therefore pass vacuously if their subset comes back empty:
  - `peak_month(src) == 5` returns `integer(0) == 5` when a source has no rows at Buck Creek.
  - `nse_g(gr, …)` returns `numeric(0)` for a group missing from the routed summary. `!anyNA(gt$Group)` checks `gw`'s keys only.

  Neither is empty today: the data script asserts 2 × 13 × 3 segment rows, and `gw` and `gr` share `grp`. No change needed unless the bundle's shape changes.

## Checked and clean

- Every inline value was evaluated, and the counts reconcile: 315 → 290 → 11 far → 279; 3,348 − 33 = 3,315; 89 zeros, 34 in January, all at gauges with a positive held-out annual.
- `far` equals the routed report's 11 gauges exactly. The report's attribution categories match the reworded parenthetical.
- The period set: 122 long-record gauges, less 7 without routed flow and 2 far, gives 113. `q_m3s_8110` equals `obs_mm` converted to m³/s (ratio exactly 1). Including the 10 low-observed months in `lp` moves the period medians by at most 0.2 pp. `lp` holds no routed zeros.
- In the window table, every month of every window has exactly the window's years in `my`, so "the same years' observed monthly means" holds. 08EE013 and 08EE003 late-July ratios are 0.67 and 0.70.
- Under obs > 0, `r_closer` is still 10 months including May–September.
- Data script:
  - `wet_values_compare()` counts one-sided keys as differing.
  - The `compared` guard ties each check to its source's row count.
  - `src_r0` now covers the gauge segments (NA where fwapg has fewer than 12 months, which then differs).
  - `output_months` is recorded from the Bulkley watersheds' rows and drives the validation sentence.
- The `vd_*` refactor of `data-raw/segment_vignette_data.R` keeps `release` and the same env vars. The tests, `CLAUDE.md` and the cartography CSV raised nothing.
