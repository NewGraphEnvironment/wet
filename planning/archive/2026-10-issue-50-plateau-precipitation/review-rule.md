# Blind review of the #50 pre-registered rule (Plan agent, 2026-10-07)

Run blind: the reviewer read the plan, the rule, the #45 subsection and Amendment 1, `scripts/wb_term_diagnose.R`, and the draft `scripts/wb_plateau_p.R` (observation stages only). It looked at no precipitation or SWE value. The Plan agent cannot write files, so this is its reply as returned, recorded here. Amendment 2 in `findings.md` is the response.

**Ordering, disclosed:** the raw observation files were downloaded at 13:57–13:58, before the review. They are observations only, with no product value.

## Blocker

- **B1. T2 can pass when climr is right.**
  - Catch-adjusted gauge P is still a lower bound, so climr ÷ obs ≥ climr ÷ truth, and ≥ 1.25 fits an accurate climr with a gauge about 20 % low. A lower bound can only show "too low".
  - Amend: make T2 a veto. "climr high" is vetoed if climr ÷ catch-adjusted P < 1.00 at ≥ half the dry gauges with a catch factor. Also from T3: if T3 names climr low, a T1 "climr high" becomes "conflicted", with no correction issue.
- **B2. The attribution is lopsided.**
  - "Theirs" can come only from T3. Rain, melt and sublimation keep SWE well below P on the dry plateaus, so T3 is close to unreachable.
  - "Ours" fires on D(climr) ≥ 1.20 even when D(PNWNAmet) ≈ 1.2.
  - Amend: decide attribution on gauge-relative D for both products, on the same site-years and with the same conditions:
    - ours: climr high and D(PNWNAmet) > 0.90;
    - theirs: D(PNWNAmet) ≤ 0.83 and D(climr) < 1.10;
    - both: both of the above;
    - unresolved: otherwise.
- **B3. Nothing checks that the gauge sites show #45's gap.** PRISM is anchored at stations, so a basin-scale excess may be absent at the points.
  - Amend: a product-against-product precondition R on common site-years (WY ≤ 2012). If R < 1.10, the verdict is "unresolved: the gauge sites do not show #45's gap". Report R per zone.
- **B4. The 1.20 threshold disagrees with #45, and there is no "not high" outcome.**
  - (1.36…1.61) ÷ 1.15 = 1.18…1.40, and the dry gauges sit mostly in zones 23 and 24 (zone 23: no material gap).
  - If TerraClimate were the truth, D(climr) ≈ 0.96…1.13.
  - Amend: D ≥ 1.15 high; D ≤ 1.05 "climr not high relative" (a registered negative); in between, inconclusive. Leave-one-out on the contrast gauges too.

## Gap

- **G1. Undercatch need not cancel in D.** The dry plateaus get more summer rain, which gauges catch well.
  - Amend: report the catch factor c by group. If the group medians differ by > 10 %, the primary D uses catch-adjusted P in both groups. Report D by season (Oct–Apr, May–Sep).
- **G2. Hourly PC failure modes bias gauge P low.**
  - A reset seen in daily means is split across two days of about −40 mm each, and both are kept.
  - The recharge after a drain counts as P.
  - Summer evaporation is kept.
  - A 200 mm/day spike cannot trip on a plateau.
  - Amend:
    - resets on the hourly series (a drop ≥ 25 mm, or a fall below 10 % of the previous value), with increments zeroed for 72 h after;
    - a positive day > 100 mm invalid;
    - the Jun–Sep sum of negative increments flagged above 25 mm, and D must hold with and without the flagged site-years.
  - Confirm the timestamps' time zone.
- **G3. Two pipelines and two eras.**
  - Amend:
    - (a) check that daily-archive P is a daily increment: ΣP against the PC end-minus-start over WY 2004–2011, within 5 %;
    - (b) D by era; "climr high" needs D ≥ 1.0 in each era with ≥ 4 gauges per group, else "era-dependent";
    - (c) sum products only over months the gauge fully covers.
- **G4. Cell elevation against site elevation; climr P has no lapse rate.**
  - Amend:
    - report Δz per site and product;
    - "climr high" must hold on sites with |Δz| ≤ 200 m, or the check is "unavailable" below 4 per group;
    - an elevation-matched contrast (the dry group's elevation IQR);
    - T3's "PNWNAmet low" must hold on courses whose PNWNAmet cell is no more than 100 m below the course.
- **G5. T3 mechanics.**
  - Amend:
    - survey window 20 Mar–10 Apr;
    - product winter P from 1 Sep to the survey date (monthly: whole months plus a day fraction);
    - denominator: courses with median SWE ≥ 100 mm; zero-sum courses dropped and counted;
    - all three products over 1982–2010.
- **G6. Contrast heterogeneity.**
  - Amend: the primary contrast is the interior zones east of the Coast Mountains divide, listed by number before any value. The full contrast is reported alongside.

## Ordering

- **O1.** Gauge-processing parameters could be tuned toward a roughly known answer.
  - Amend: stage 2 prints counts, years, flags and c only, with no P or SWE magnitudes before stage 3.
  - A parameter change after that is a deviation. QA inspection of raw traces only on all gauges, or on gauges picked by a stated rule, and logged.
- **O2.** Disclose:
  - #45's TerraClimate ÷ climr per dry zone (0.80 / 1.14 / 0.91 / 0.76);
  - the ECCC figures;
  - the raw downloads.
- **O3.** Contrast membership reads a product field. Amend: a non-missing mask of one PREC day, registered as a mask only.

## Assumption

- **A1. The PRISM flag points the wrong way, and its escape clause is likely to fire.** 2B06P is flagged, and the flagged gauges pull D toward 1 if PRISM was anchored on raw ASP P.
  - Amend: record from PCIC's BC PRISM documentation whether ASP P was undercatch-adjusted and whether snow courses were inputs. Always report unflagged D with n. "climr not high" needs the unflagged check available.
- **A2. Time alignment.** climr periods are calendar years; `wet_pcic_annual()` sums calendar years; the cached PCIC years lack Oct–Dec 1980.
  - Check the PREC calendar.
  - Map TerraClimate months from its time units.
  - Assert 12 months per water year.
  - Register the water-year range per product.

## Scope

- **S1. The dry gauges are concentrated in zones 23 and 24.**
  - Amend: the pooled verdict needs dry gauges from ≥ 2 zones. Report the zone mix. If zone 15 has < 2 gauges, say the gauge verdict does not cover it.
- **S2. Inconclusive is wide.** Amend: report D with a bootstrap 90 % interval (resampling sites in both groups), stating what excess the data can rule out.
