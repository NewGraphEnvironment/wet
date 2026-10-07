# Code-check round 2: scripts/wb_plateau_p.R (#50)

Reviewer read the rule (Pre-registered rule, Amendment 2, Deviation 1, Correction 1), round 1's
review, the full script, the report and the helpers it calls (`wet_pcic_fetch`, `wet_pcic_index`,
`wet_pcic_annual`, `climr::get_bb`, `climr::input_refmap`). Probes were read-only against the
`data/plateau_p/` caches and raw snapshots, run from the scratchpad. The script itself was not run.

Round 1's fixes, checked:
- The catch factor now counts a year only when every month from October to the peak's month is
  covered (`oct_to_peak_covered`, lines 271-278). This is correct.
- `cmed` drops NA (line 335).
- The seasonal D uses raw P (lines 625-627, where `site_ratio` defaults to `adj = FALSE`).
- The `cellz` key carries the climr version (lines 436-437).
- A B3 shortfall gets its own verdict string (line 638).

Checked and found consistent with the rule:
- **Product months and water years.** climr maps PERIOD y and PPT_mm to calendar months. PREC is
  fetched per calendar year 1967-2012, and `nlyr == days` holds in leap years, so WY 1968-2012
  are whole. TerraClimate months come from `time()`. All three product caches have no NA and the
  same 226 pids.
- **Hourly PC.** Resets, the 72 h hold that includes the reset reading, UTC-8 days, >= 12 readings,
  the cap on the net and the Deviation 1 floor are as written.
- **Gauge-to-product joins.** All 89 used gauges and all 150 courses map to a pid. Sites sharing
  coordinates (16 gauge/course pairs, plus 1F04P/1F04P2) collapse to one pid only when lon, lat
  and elevation all match, which is correct.
- **T3 window.** It runs from 1 Sep of WY-1 through the survey month, with the survey month
  weighted by (day - 1)/days.
- **T1.** Leave-one-out covers both groups. The flagged-years, era, |dz| <= 200 and PRISM checks,
  their status strings, and the `pn_stable` and attribution branches are all as written. My
  independent recomputation of D from `plateau_p.rds` reproduces the report: 1.0915, unflagged
  1.1889, era <= 2011 1.0058, PNWNAmet 0.9148.
- **PRISM list.** The HTML has 23 hrefs and the regex yields all 23.
- **Cache keys.** The obs, climr, PNWNAmet, TerraClimate and cellz keys each cover the inputs
  that cache depends on. A changed gauge set changes `site_key` and so the pids.

## Findings

- **[severity: fragile]** scripts/wb_plateau_p.R:219-220. Daily-archive P is used signed. The
  only filters are code `M*` and `> 100`, so reset artefacts in the archive enter gauge P as large
  negative days. That follows Amendment 2's text ("valid where the code does not start with M").
  But it contradicts Deviation 1's premise that the archive's P is max(0, ΔAccumP), which is the
  reason the hourly era is now floored at 0. Over the whole archive, 419 non-M P values are
  negative (minimum -872).
  - In the site-years and covered months T1 actually uses, there are 186 negative days summing to
    -3,314 mm. All are at contrast and "other" gauges in WY 2008-2009, and none at dry gauges.
  - 1A14P (Hedrick Lake, contrast), WY 2008: gauge P is 459 mm, with -1,602 mm of negatives in it
    (-872 on 2008-05-15, -566 on 2008-01-23). Its floored total would be about 2,061 mm.
  - 1D15P WY 2009 has -698 mm, 1E08P WY 2009 -455 mm, 1A01P WY 2008 -166 mm and 1F06P WY 2009
    -140 mm. These gauge P values are wrong at the site level, and so is 1A14P's printed
    product/gauge ratio.
  - Measured effect of flooring them at 0, recomputed from `plateau_p.rds`. The verdict does not
    change.

    | D | As run | Floored |
    |---|---|---|
    | climr | 1.0915 | 1.0916 |
    | climr, unflagged | 1.1889 | 1.1890 |
    | climr, era <= 2011 | 1.0058 | 1.0105 |
    | PNWNAmet | 0.9148 | 0.9148 |
    | PNWNAmet, unflagged | 0.8333 | 0.8333 |

  - Check (a) also includes these years.
  - The two eras still measure different quantities at these gauges. A rerun on other gauges, or a
    newer archive, could move a decision.
  - Either floor the archive's P too (`pmax(value, 0)`, keeping the signed value for the Jun-Sep
    flag) and record it as a deviation with the numbers above, or record explicitly that the
    archive's negatives are kept as registered.

- **[severity: bug]** planning/active/findings.md:241 (Correction 1, "Effect"). The text says "It
  can only lower c." That is false. Dropping years from a per-site median can raise it whenever the
  dropped ratios sat below that site's median.
  - Measured by comparing `obs_7839f4f088.rds` (before) with `obs_334940405e.rds` (after): c_raw
    rose at 8 gauges and fell at 79. c itself rose at one gauge: 1E11P (contrast, zone 14) went
    from 1.17 to 1.39.
  - The next sentence's conclusion still holds, but only by measurement. The current run's group
    medians are 1.00 / 1.00 (report line 19), so `use_adj` is FALSE. It does not follow from the
    stated argument.
  - This is the deviation record that O1 requires. Replace the claim with the measured change
    (c up at 1, down at the rest, group medians unchanged at 1.00, G1 off).

## Notes (not bugs; for the author)

- The tracked report (`data/checks/wb_plateau_p.txt`, lines 3-4) names Amendment 2 and Deviation 1
  but not Correction 1. Correction 1 changed stage 2 after stage 2 had run, and O1 asks for such a
  change to be "reported as such".
- Hourly increments that bridge a gap of more than 24 h are 0.4 % of floored hourly P: 8,567 of
  2,014,400 mm on 466 days. 2,018 mm of that crosses a month boundary into a covered month. This
  is negligible, so it is not a finding.
- 1F04P and 1F04P2 are two gauge ids at one location. Only 1F04P enters the tests today. If both
  ever had complete years, one site would count twice in the contrast group.
- The PNWNAmet "low" threshold is the literal 0.83, as Amendment 2 writes it. The original rule
  defined it as 1/1.20 (0.8333). PNWNAmet's unflagged D is 0.8333, which falls between the two.
  It decides nothing here: the PRISM check reads "fails" either way.
