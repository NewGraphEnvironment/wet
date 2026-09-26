# Issue drafts — split of #5 (not filed; awaiting approval)

## NEW — Open province-wide runoff estimate: water balance after Chapman et al. 2018

**If we do it:** `wet` gets mean annual and monthly runoff for every FWA fundamental watershed in BC, from open code, validated out-of-sample on HYDAT. The north and interior gap is filled, and there is a yardstick for PCIC and the BC Water Tools. **If we never do:** the north and interior stay without estimates, or depend on a product whose model code does not ship and whose accuracy cannot be checked independently.

## Problem

PCIC gridded hydrology covers only the Peace, Fraser and Columbia. The BC Water Tools (Foundry, now `bcgov/nr-bcwat`) will release per-watershed discharge, but their model code does not ship. Their published accuracy may be in-sample, and after an undocumented "adjustment to measured flows" step their values sit at about 0 % error at the gauges. Adopting any single product leaves us unable to tell whether it is right.

## Proposed

Build our own estimate, in the open, with the method the BC Water Tools use (Chapman, Kerr & Wilford 2018, JAWRA 54:676). Because the method is the same, a disagreement with their release points at a specific step.

- **Annual:** gridded P − AET per fundamental watershed, accumulated upstream with `wet_upstream_mean()`. A gauge-residual regression by hydrologic zone (`WHSE_WATER_MANAGEMENT.HYDZ_HYDROLOGICZONE_SP`, or the extended BC Hydrologic Zones layer, which reaches the Alberta, Yukon and NWT gauges).
- **Monthly:** share-of-annual regressions per month, fitted to unregulated HYDAT stations, with the shares constrained to sum to 1.
- **Stations:** `wet_station_select()`, `wet_station_snap()` (fresh snapping plus a drainage-area check) and `wet_station_monthly()`, shared with #6.
- **Validation:** blocked cross-validation by watershed group or WSC sub-drainage, with headwater and nested gauges reported separately and an incremental-area check on nested pairs. Plain leave-one-out is reported alongside, for comparability with Chapman.
- **Every choice where the paper is silent** (23 are listed in `research/water_balance_method.md` §7) is recorded with its reason.

Research: [`research/water_balance_method.md`](../../research/water_balance_method.md), [`research/runoff_prior_art.md`](../../research/runoff_prior_art.md).

## Done when

- Annual and monthly runoff exist for every fundamental watershed in BC.
- Blocked-CV skill is reported by region, drainage-area class and nesting class, with the MAE % and within-±20 % metrics.

Relates to #5, #6.

---

## EDIT #5 — retitle: "Coverage and comparison: our estimate vs PCIC, BC Water Tool and others"

**If we do it:** each watershed group shows which products exist, and each other group's product is scored against ours and HYDAT, with every disagreement attributed (ours, theirs or unresolved). **If we never do:** other products get used without being checked, and their errors or inconsistencies stay invisible.

## Problem

PCIC gridded VIC-GL covers the Peace, Fraser and Columbia. PCIC Raven covers the coast and the Fraser, with the Peace and Upper Columbia expected in about a year. The BC Water Tool data release is pending. Our own estimate (NEW issue) is province-wide. What is missing is a way to see which product serves where, and how far they agree.

## Proposed

- **Coverage map per watershed group:** PCIC gridded (domain mask), Raven (26,662 reaches from the `bbox-server` OGC API), BC Water Tool (when released) and ours. Tracked report plus map.
- **BC Water Tool ingest when released:** `wet_bcwt_read()` on `fund_rollup_report`; check whether IDs are FWA or Foundry `watershed_feature_id`.
- **Compare against ours and HYDAT:** PCIC-`wet` in the three basins; Raven at the #9 pilot sites; BC Water Tool wherever it has coverage.
  - Their accuracy numbers are treated as in-sample; ours are out-of-sample.
  - Metadata inconsistencies already found go in the log. For example, Cariboo's accuracy numbers are a copy of Omineca's, and the station counts do not match the news releases.
- **Disagreement log:** each material difference attributed as ours, theirs or unresolved, with evidence.
- **Independent references**, ranked in `research/runoff_prior_art.md`: GEOGLOWS v2, TerraClimate runoff and the BC 1961–1990 runoff isolines, as cheap extra checks.

## Done when

- The coverage map is published.
- Each available product is scored against ours and HYDAT, with its disagreement log.

Blocked for the comparison part by NEW. Relates to #6, #9.
