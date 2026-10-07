# Chapman, Kerr & Wilford (2018): the BC Water Tools method, and what a reimplementation must decide

**Verified:** 2026-10-06 · **Issues:** #5 (found), #11 (built and validated), #15 (ET experiment), #18 (MOD16 challenger), #39 (scored against fwapg across PCIC's coverage), #43 (refit on HYDAT 2026-07-17; pooled zones settled) · **Produced by:** desk research (sections 1–7), the #11 build and the #15 and #18 experiments (section 0): `scripts/wb_inputs.R`, `wb_stations.R`, `wb_province.R`, `wb_validate.R`, `wb_aet_compare.R`, `wb_output.R`. Reports: `data/checks/wb_*.txt`, `stations_wb.txt` and `climr_eccc.txt`. **Status:** built. The shipped model uses CGIAR AET constrained from below by a Fu–Budyko AET. A rule fixed before scoring chose it (#15). Blocked-CV MAE on annual runoff was 27.7 % (31.2 % headwater) on the 2025-10-14 fit, against 33.1 % (38.1 %) with CGIAR alone (section 0). Since #43 the shipped fit is on HYDAT 2026-07-17: 27.5 % (30.7 % headwater) at 315 gauges, pooled zones settled on gauges no fit uses, and the zone adjustment kept by a recorded decision ("Refit on HYDAT 2026-07-17"). MOD16 was scored against it under a second pre-set rule (#18) and does not replace it.

Legend: **[S]** stated in the source cited · **[I]** inferred · **[U]** unknown or not published. Sources are listed at the end; all are online.

---

## 0. As built in `wet` (#11), and what the validation showed

### Inputs, all on CGIAR's 30″ grid over BC

- **P and T:** climr 1981–2010 monthly normals. The reference map is downscaled onto a Copernicus GLO-90 DEM, shifted by the mean of the MSWX-blend anomalies over 1981–2010.
  - Averaging the anomalies first matches climr's per-year point average within 0.1 %.
  - Against 57 ECCC 1981–2010 WMO normals: MAP ratio median 1.03, MAT difference median about 0 °C (`data/checks/climr_eccc.txt`).
  - The ClimateNA series was tried first. Its 1° anomalies are NA over Haida Gwaii and northern Vancouver Island, which blanked about 160 k land cells.
- **AET:** CGIAR Soil-Water Balance v3 (CC0), annual and monthly. No land-cover ratio. Since #15 the annual AET that ships is `max(CGIAR, Fu–Budyko)` (below, "The ET experiment"). The monthly shares still use CGIAR's monthly AET.
- **Zones:** the extended BC Hydrologic Zones (43 features, 29 in BC).

### Stations

- 352 natural HYDAT stations with ≥ 10 complete years in 1981–2010.
- 309 snapped to FWA within ±10 % area (median ratio 1.000).
- 290 calibrated on: basin ≥ 95 % in BC and on the grid. They fall in 93 blocked folds (WSC sub-sub-drainages); 218 are headwater gauges and 72 nested.

### Choices where the paper is silent (section 7)

The item numbers refer to section 7.

- **2:** the gauge period matches the 1981–2010 normal.
- **3, 5:** a different ET product and land cover, with no land-cover ratio.
- **7:** area-weighted catchment integration on one analysis mask.
- **8:** the residual is fitted as obs − pred and added.
- **9:** zone intercept + P per zone, applied through zone-share-weighted upstream means, so fit and application agree exactly. Zones with fewer than 8 dominant gauges are pooled.
- **10:** cells stay signed; the output is floored at 0.
- **11:** no final adjustment to the gauges.
- **12:** blocked CV and leave-one-out are reported separately from in-sample.
- **13, 14:** OLS on shares, floored at 0 and renormalised.
- **15:** monthly regressions pooled over the province.
- **16:** predictors per watershed, as upstream means.
- **20:** 365.25 days a year, February 28.25, so months sum to the year.

### Skill with CGIAR AET, as built in #11 (`data/checks/wb_validation_aet-cgiar.txt`)

Annual runoff; percentages are mean absolute error. This table is the #11 model. The model that ships since #15 is scored in the next section.

| Model | All 290 | Headwater | Nested | Within ±20 % | Monthly NSE on shares (median) |
|---|---|---|---|---|---|
| Raw P − AET, no fitting | 34.7 % | 39.8 % | 19.4 % | 47 % | — |
| **Adjusted, blocked CV (headline)** | **33.1 %** | **38.1 %** | 17.9 % | 50 % | 0.87 |
| Adjusted, leave-one-out | 32.3 % | 37.8 % | 15.5 % | 54 % | 0.88 |
| Adjusted, in-sample | 22.6 % | 25.5 % | 13.8 % | 58 % | 0.88 |
| (transparency) every fold forced to one fitted "other" level for pooled zones | 39.1 % | 46.4 % | 16.9 % | 52 % | 0.87 |

**Pooled zones (decided in #43).** Zones with fewer than 8 dominant gauges are pooled.
- **The pre-set specification** gave them one fitted "other" level. Under it the gate **fails**: headwater blocked CV 46.4 % against raw 39.8 %. The level's ~+170 mm intercept lands on dry pooled zones (17, 06, 04).
- **The "none" variant** (no adjustment for pooled zones) was added **after** seeing that result. An inner blocked CV on each fold's training stations then chose between the two, and all 93 folds (and the all-station fit) chose "none". The gate passes: 38.1 % against 39.8 %.
- **This was mildly optimistic.** Nesting guards the choice between the candidates, not the decision to offer "none". Which result decides what ships was left to the maintainer; flipping to raw P − AET is one line (`keep_adjust`).
- **Settled in #43 on gauges no fit uses** (see "Refit on HYDAT 2026-07-17" below): "none" is fixed by a pre-registered test on short-record gauges, so the caveat is retired.

**What the numbers say:**
- **The adjustment helps only a little out of sample, and only where a zone has its own coefficients.** Headwater stations under blocked CV (`data/checks/wb_validation.txt`):
  - with their own zone in the fold (n = 118): 34.1 % raw → 30.9 % adjusted;
  - pooled (n = 100): 46.4 % → 46.6 %.

  Most of the in-sample gain (22.6 %) does not transfer to ungauged basins.
- **Chapman's published figures:** MAE 16.1 %, 77.8 % within ±20 %, monthly NSE 0.92. They come from 45 gauges in two plains zones, and are likely in-sample or near it. Our in-sample 22.6 %, over 20 fitted zone levels, is the comparable number.
- **The error is concentrated.** Basins under 100 km² run at about 59 % MAE raw. The semi-arid interior plateaus (zones 15, 17, 23, 24) run +56 % to +234 % raw: CGIAR AET, capped by its own WorldClim P, is far too low next to climr's P there. Example: Greata Creek has P 746 mm and AET 281 mm, against 50 mm observed. The #15 experiment below addresses this.
- **Against PCIC near Prince George, the balance runs high everywhere, and PCIC low in the large basins** (#28, on the 2025-10-14 fit; `data-raw/segment_vignette_data.R`, `vignettes/segment-discharge.Rmd`).
  - *On the shipped 2026-07-17 fit (#43):* median ratio 1.37. The balance runs +2 % to +26 %. At the two large basins off the group (Nation, Stuart) it is within 3 % and the gap is fwapg's: the balance's share is 0.13. At 08KC001 they bracket the observation, +26 % against −25 % (share 0.44). The detail below is the 2025-10-14 fit's.
  - On SALR the balance gives a median 1.47 times PCIC through wet per order ≥ 3 segment.
  - Five calibration gauges are used: those within 30 km of SALR plus its outlet gauge 08KC001.
  - Held-out balance error at those gauges: +6 % to +38 %.
  - fwapg (PCIC) error: −1 % and −2 % at the two small basins (297 and 439 km²), −14 % to −25 % at the three large ones (4,227–14,235 km²).
  - Splitting the gap in log terms, log(wb/fwapg) = log(wb/obs) + log(obs/fwapg): at the two small basins it is 94–98 % the balance's. At the three large ones the two share it, with the balance's share 28–52 %. At 08KC001 they bracket the observation, +38 % against −25 %, and split it about evenly.
  - No gauge measures the SALR median itself: 08KC001's basin is 4,227 km², of which SALR is 1,794.
- **Across PCIC's coverage, fwapg is closer at the gauges both products score** (#39, on the 2025-10-14 fit; `data-raw/segment_vignette_data.R`, `vignettes/segment-discharge.Rmd`; verified 2026-10-06).
  - *On the shipped 2026-07-17 fit (#43):*
    - Coverage: 201 calibration gauges lie in it, and fwapg has a value at 183.
    - MAE 30.3 % for the balance against 25.3 % for fwapg. Within ±20 %: 49 % and 59 %.
    - By basin: Peace (23) 20.6 against 20.7, a tie. Fraser (81) 29.7 against 26.9. Columbia (79) 33.7 against 25.0.
    - The 18 large-river gauges fwapg skips score 14.0 %.
    - The balance's error no longer carries the "mildly optimistic" caveat (pooled zones settled in #43).
    - The article (#42) no longer recommends one product: it compares the two in a table.
  - The rest of this bullet is the 2025-10-14 fit's.
  - Coverage: the 112 watershed groups where at least half of fwapg's discharge rows hold a value. 27 more groups carry only null rows, and 11 Liard groups at the edge of PCIC's grid hold values on 0.02–23 % of rows.
  - Of the 290 calibration gauges, 186 lie in coverage. fwapg has a value at 168. The other 18 (median 11,859 km²) sit on rivers fwapg skips: of 13,883 segments of order 8 and up in coverage, 38 hold a value. The balance scores 13.3 % there.
  - At the 168, mean absolute error is 30.5 % for the balance (held out) and 25.5 % for fwapg; within ±20 %, 48 % and 60 %; median absolute error 22.2 % and 16.7 %. By basin: Peace (21) 19.6 % against 14.2 %, Fraser (73) 29.4 % against 28.8 %, Columbia (74) 34.7 % against 25.4 %.
  - Not like for like: the balance's error is out of sample and mildly optimistic (above); VIC-GL was calibrated over 1985–2005 on gauges not published with fwapg's values, so fwapg's may be partly in sample. The 18 large-river gauges are where the balance does best and fwapg has no value.
  - A rule set before scoring (#39) would hold the recommendation to use the balance everywhere unless the balance were more than 5 points worse. The gap is 5.03; with the grid-edge gauge 10CB001 counted (coverage as any valued row) it was 4.70. The rule fired, and the recommendation was kept on the record (2026-10-06). The same day the article dropped a single recommendation for a table of each model's strengths and limits, with guidance by job: PCIC where fwapg has a value inside the three basins, the balance for a province-wide layer and outside them. A verdict between the two was not what the article needed. The scores above stand. Attribution: theirs where fwapg skips rivers; unresolved for the gap at the gauges both score.
- **Large rivers are good.** Basins over 10,000 km² score 21 % raw MAE. At the major-river mouths (`data/checks/wb_output.txt`) the ratio of modelled to observed flow is 0.86–1.17:
  - Fraser at Hope 1.05 (PCIC through `wet`: 0.93), Thompson 1.17.
  - Columbia at Birchbank 1.05, although only 86 % of its basin is in BC.
  - Stikine 1.05, Peace 0.94, Skeena 0.86, Nass 0.86.
- **Zone steps.** The annual map ([wb_runoff_annual.png](wb_runoff_annual.png)) shows straight-edged steps where hydrologic zones meet. The method applies each zone's coefficients up to a hard boundary (§7 item 9). Blending across boundaries is a candidate refinement.
- **No output.** 22,041 watersheds (0.7 %), on small coastal islands that the 30″ inputs do not cover.

### Refit on HYDAT 2026-07-17 (#43)

**Verified:** 2026-10-06 · **Produced by:** `scripts/wb_stations.R`, `wb_validate.R`, `wb_fit_accept.R`, `wb_pooled_test.R`, `wb_output.R` on m4 (logs `data/logs/43/` there) · **Reports:** `data/checks/*_20260717.txt`; rules pre-registered in `planning/archive/2026-10-issue-43-refit/findings.md`.

Since #43 the pipeline holds one fit per HYDAT release (`data/wb/stations_<release>.rds`, `data/wb/<key>/fit_<release>/`, `scripts/wb_fit_lib.R`). `WET_HYDAT` names the file and is checked against its release, and the shipped fit is `wb_shipped_release`.

- **The 2025-10-14 fit is reproduced exactly under the new layout.** Rebuilt from HYDAT and fwapg, `stations` and `monthly` are identical, and held-out predictions are identical for all ten AETs. #15 reproduces (cfu), and 24 of 24 output basins match. That fit stays as `fit_20251014`.
- **HYDAT 2026-07-17 adds no years.** The window is fixed at 1981–2010. It revises gross drainage areas: 336 stations snap within ±10 % against 309, giving 315 calibration gauges (29 new, 4 dropped). AET cfu is carried, not re-picked.
- **Acceptance** (pre-registered: not more than 1.0 point worse): headwater blocked-CV MAE on the 209 headwater gauges common to both fits, 30.90 against 31.18. Passes.
- **The headwater gate fails by 0.03 point.** Adjusted scores 30.72 against raw 30.69.
  - On the same 209 gauges the old fit's raw (30.67) already beat its adjusted (31.18). The old gate passed on its full headwater set of 218. Nine of those fall outside the common 209: either dropped by this release (4 gauges are dropped in all) or now nested under its new upstream gauges.
  - Without the adjustment the main stems read low: Peace 0.77, Skeena 0.68, Nass 0.64, Fraser at Hope 0.93 of observed.
  - The user kept the adjustment through a recorded per-fit override with a 0.1-point tie tolerance (`adjust_override.txt`). A gate that scores main stems is #47.
- **Pooled zones, settled on short-record gauges** (natural, 1–9 complete years, never in a fit). There were 110 after the screens, each predicted with its sub-sub-drainage's calibration gauges held out.
  - On the 39 whose dominant zone is pooled, "none" scores 46.5 % against "other" 80.2 % (paired bootstrap of the difference +9 to +62 points). "none" is fixed; the variant now sits outside the calibration set, and the caveat is retired.
  - On all 110 test gauges: none 43.5 %, raw 41.6 %, other 55.3 %. On short records the adjustment is no better than raw, the same message as the gate.
- **Shipped (HYDAT 2026-07-17, cfu, adjustment kept, pooled zones "none"):** blocked-CV MAE 27.5 % on 315 gauges (headwater 30.7 %, nested 17.6 %). Major rivers 0.81–1.13 of observed: Peace 0.93, Stikine 0.99, Nass 0.81, Skeena 0.81, Thompson 1.13, Fraser at Hope 1.02, Columbia at Birchbank 1.04.

### The ET experiment (#15): which annual AET to subtract

**Verified:** 2026-09-28 · **Produced by:** `scripts/wb_validate.R <variant>`, `scripts/wb_aet_compare.R` → `data/checks/wb_aet_compare.txt` and `data/checks/wb_validation_aet-*.txt`. Run logs: `data/logs/2026092[78]_*`.

**The question.** CGIAR's AET comes from a soil bucket driven by WorldClim P, so it is capped by that P. In dry country climr's P is higher, and P − AET overshoots. Four alternatives were scored under the same blocked CV:
- **`lc`:** Chapman's land-cover ratio on CGIAR, using the Table 3 class values, NRCan 2020 land cover and nothing fitted;
- **`tc`:** TerraClimate 1981–2010 AET;
- **`fu`:** Fu–Budyko AET from climr P and Hargreaves PET (climr Tmax/Tmin), ω = 2.6;
- **`cfu`:** max(CGIAR, `fu`), i.e. CGIAR constrained from below by the Budyko demand.

MOD16 was deferred here, because it needed an Earthdata login. #18 scored it against the shipped AET; see "MOD16 as a challenger (#18)" below.

**The rule, fixed before any variant was scored** (`planning/archive/…issue-15…/task_plan.md`). Scores are as shipped under blocked CV. A variant replaces CGIAR only if all four hold:
- (a) headwater MAE at least 2.0 points lower;
- (b) all-station MAE no higher;
- (c) nested MAE at most 1.0 point higher, and nested within ±20 % at most 3 points lower;
- (d) a fully nested selection, in which each outer fold picks the variant by the same rule on an inner CV, also beats CGIAR's headwater MAE.

`fu` at ω = 1.5, 2.0 and 3.5 was scored for transparency only.

| AET | Shipped as | Headwater | All 290 | Nested | Nested within ±20 % | Raw headwater |
|---|---|---|---|---|---|---|
| CGIAR (#11) | adjusted | 38.1 % | 33.1 % | 17.9 % | 72 % | 39.8 % |
| `lc` land-cover ratio | adjusted | 44.1 % | 37.1 % | 16.0 % | 76 % | 69.2 % |
| `tc` TerraClimate | adjusted | 33.5 % | 29.0 % | 15.3 % | 82 % | 35.4 % |
| `fu` Fu–Budyko | adjusted | 32.0 % | 28.1 % | 16.3 % | 75 % | 32.8 % |
| **`cfu` max(CGIAR, Fu)** | adjusted | **31.2 %** | **27.7 %** | 17.4 % | 71 % | 31.6 % |
| `fu` ω = 3.5 (transparency) | raw | 28.9 % | 27.6 % | 23.5 % | 39 % | 28.9 % |

**Result.** `cfu` passes (a) to (c) with the lowest headwater error. `tc` and `fu` pass too. Under the fully nested selection it scores 32.3 % headwater against CGIAR's 38.1 %, so it passes (d). 87 of 93 outer folds chose `cfu` and 6 chose `fu`. It ships.

The selected number (31.2 %) is optimistic by about a point; the nested 32.3 % is the honest estimate for an ungauged basin.

**Where it helped** (mean error as shipped; `data/checks/wb_aet_compare.txt`):

| Zone | CGIAR | `cfu` |
|---|---|---|
| 17 | +56 % | +48 % |
| 23 | +57 % | +20 % |
| 24 | +231 % | +102 % |
| Basins < 100 km², MAE | 61 % | 44 % |

Greata Creek (P 743 mm, observed 50 mm) goes from 462 mm to 243 mm.

**What it cost.** At the major-river mouths the modelled-to-observed ratio moves by 0.01–0.05 (`data/checks/wb_output.txt`, the #11 run against this one):

| River | #11 | `cfu` |
|---|---|---|
| Fraser at Hope | 1.05 | 1.04 |
| Thompson | 1.17 | 1.14 |
| Columbia at Birchbank | 1.05 | 1.04 |
| Stikine | 1.05 | 1.00 |
| Peace | 0.94 | 0.93 |
| Skeena | 0.86 | 0.83 |
| Nass | 0.86 | 0.85 |

The Budyko floor raises AET a little in the wet north too, which moves the already-low Skeena and Nass further down.

**What the variants say, and who is wrong where:**
- **The overshoot is a mismatch between two products, not a defect in either.** CGIAR is internally consistent: its AET is capped by its own P, which is lower than climr's in the dry interior. Attribution: ours. The model paired a P with an AET computed from a different P. A Budyko floor, computed from climr's own P and demand, removes much of the mismatch.
- **Chapman's land-cover step makes it worse (`lc`),** everywhere and most in zone 17 (+345 %). The Table 3 values are Canada-wide means from Liu et al. (2003). The majority-cell CGIAR means in BC are higher (conifer 441 mm against 276 mm), so the ratios fall below 1 almost everywhere: conifer 0.63, shrub 0.45, barren 0.31, snow/ice clamped at 0.25. This lowers AET, where the interior needs more. Chapman's ratios were "adjusted within the model" (tuned to gauges) and never published.
  - Attribution: **unresolved.** Table 3 as published cannot reproduce what their calibration did. This is a reason their product cannot be checked without its code.
- **TerraClimate helps (`tc`) but stays P-capped.** Its AET comes from its own bucket on its own P. At the Greata mouth cell that P is 428 mm, against climr's 614 mm.
- **ω = 3.5 wins on headwater raw and loses the nested basins** (23.5 % MAE, 39 % within ±20 %). A per-cell Budyko at high ω over-evaporates large, snow-fed basins, where P and demand are out of phase. The pre-set rule would have refused it, and it was never eligible.
- **Still unresolved.** Zone 24 (Okanagan Highland) remains at +102 %. The candidates are:
  - licensed withdrawals and groundwater losses at "natural" gauges in the Okanagan;
  - climr P possibly high on the interior plateaus (the ECCC check is province-wide, median ratio 1.03);
  - the per-cell Budyko at ω = 2.6 still under-evaporating there.

**Mechanics** (all in `scripts/wb_province.R`; the numbers are in the PWF archive):
- **One analysis mask.** It is taken from the #11 layers only, so no variant moves the CGIAR baseline. The CGIAR report reproduces #11's byte for byte apart from its run-key line. The new run's upstream means match #11's to within 6e-16 relative.
- **Land-cover fractions.** Codes are resampled nearest onto a 1″ grid aligned with the 30″ grid, then block-averaged. A single average warp from NRCan's Lambert grid treats a lon/lat cell as an axis-aligned box. In western BC that put cells off by up to 0.3; the two-step method is within 0.009 on the same 40 cells.
- **Gap fill.** TerraClimate has no cell on 117 coastal cells of the grid; those take CGIAR's AET.

### MOD16 as a challenger (#18)

**Verified:** 2026-09-28 · **Produced by:**
- `wet_mod16_aet()` and `scripts/wb_province.R` (run adc88b19c8, reproduced as 962a9cc2c4 when #19 re-keyed the input caches);
- `scripts/wb_aet_compare.R` stage 2 → `data/checks/wb_aet_compare.txt`;
- `data/checks/wb_validation_aet-{mod16,cmod16}.txt`.

**The question.** MOD16A3GF v061 (NASA LP DAAC; Penman–Monteith on MODIS land cover, LAI and albedo with GMAO meteorology) estimates ET without a precipitation field, so it is the independent AET #15 lacked.
- **mod16:** its 2001–2020 mean per 500 m pixel (a pixel counts with at least 10 valid years), put on the 30″ grid in two steps, as the land cover was.
- **Gaps:** codes 65529–65535 (unclassified, urban, permanent wetland, snow/ice, barren, water) take the shipped `cfu`, weighted by area. MOD16 covers 91.5 % of the analysis grid by area, and the calibration basins are mostly MOD16 (median 0.99 of the basin).
- **cmod16:** max(CGIAR, `mod16`).

**The rule, fixed before scoring** (`planning/archive/…issue-18…/task_plan.md`):
- It is #15's (a)–(d), with `cfu` as the incumbent and `mod16` and `cmod16` as the eligible challengers.
- (d) is judged against `cfu`'s as-shipped headwater MAE.
- #15's stage is re-run first and must reproduce its published result, or the comparison stops. It reproduced exactly.

| AET | Shipped as | Headwater | All 290 | Nested | Nested within ±20 % | Raw headwater |
|---|---|---|---|---|---|---|
| **`cfu` (incumbent)** | adjusted | **31.2 %** | **27.7 %** | 17.4 % | 71 % | 31.6 % |
| `mod16` | adjusted | 36.3 % | 31.4 % | 16.5 % | 75 % | 40.5 % |
| `cmod16` max(CGIAR, MOD16) | adjusted | 34.6 % | 30.4 % | 17.7 % | 69 % | 36.3 % |
| CGIAR (reference) | adjusted | 38.1 % | 33.1 % | 17.9 % | 72 % | 39.8 % |

**Result.** Both challengers fail (a): they are 5.1 and 3.4 points above `cfu`, where the rule needs 2 below. In the nested selection all 93 folds chose `cfu`. **`cfu` stays.**
- **The gap fill does not explain it.** On the 200 headwater basins at least 80 % MOD16, `mod16` scores 37.5 % against `cfu`'s 31.9 %.
- **(d) is strict here.** `cfu` alone scores 33.2 % under the nested procedure, because each fold picks its own gate. A challenger therefore had to beat `cfu`'s nested score by about two points. It did not come close on (a), so this did not decide anything.

| Zone (mean error, as shipped) | CGIAR | `cfu` | `mod16` | `cmod16` |
|---|---|---|---|---|
| 17 | +56 % | +48 % | +108 % | +48 % |
| 23 | +57 % | +20 % | +45 % | +44 % |
| 24 | +231 % | +102 % | +166 % | +165 % |
| Basins < 100 km², MAE | 61 % | 44 % | 55 % | 52 % |

At Greata Creek the upstream AET is 281 mm with CGIAR, 419 mm with MOD16 and 499 mm with `cfu`. P is 743 mm and the gauge reports 50 mm, which implies about 693 mm.

**What it says, and who is wrong where:**
- **MOD16 is better than CGIAR and worse than the Budyko floor on headwater basins.** It is the best of the three on nested basins (16.5 % MAE, 75 % within ±20 %). Where it runs below CGIAR, flooring by CGIAR (`cmod16`) helps.
- **In the dry interior MOD16 leaves most of the overshoot.** Two readings fit:
  - MOD16 under-evaporates water-limited terrain (theirs);
  - climr's P, or the gauges, are off there (ours, or withdrawals).
- **Attribution: unresolved. [I]** The Budyko floor is built from climr's own P, so it absorbs a P bias by construction; MOD16 cannot. That MOD16's advantage over CGIAR, and its independence from P, were not enough is weak evidence that part of the zone 24 residual is on the P or gauge side, not the ET side.

**Mechanics:**
- The two-step reprojection is tested against an exact polygon-overlap oracle on a sheared stripe; a one-step average warp fails that test.
- The tiles are the 9 sinusoidal tiles the grid reaches, not CMR's loose bounding-box match, which returns 12.
- Granules are listed through CMR and downloaded with `curl` and an Earthdata netrc. That is 180 granules, about 3.9 GB, in 14 minutes.
- The province run reproduces #15's layers exactly, and its upstream means within 5.4e-14 after matching by watershed id. Row order is not stable between runs, because the watershed query has no ORDER BY.

### What this says about the BC Water Tools

Their accuracy figures are in-sample, and after the undocumented "final adjustment to measured flows" they are near 0 % at the gauges. They are not a measure of skill at ungauged sites. The open reimplementation suggests that out-of-sample skill of this method family, province-wide, is about 33 % MAE on annual runoff (38 % for headwater basins) with the CGIAR AET Chapman used, and about 28 % (31 %; 32 % under a fully nested selection) with that AET floored by a Fu–Budyko demand (#15). Our release comparison (#5) should score their values at stations held out of *their* fit where possible.

### Follow-ups

- #14: transboundary upstream area.
- #15: the ET experiment. Done; see "The ET experiment" above.
- #18: MOD16 as a challenger. Done; `cfu` stays. See "MOD16 as a challenger (#18)" above.
- The Budyko floor is annual only. The monthly shares still regress on CGIAR's monthly AET (see #16 for the monthly predictors).
- Zone 24 (Okanagan Highland) still runs at +102 % as shipped; the candidates are listed in "The ET experiment" above. MOD16, which is independent of P, left +166 % there (#18).
- The pre-#15 input caches (CGIAR, climr, DEM, zones raster) are keyed on content and parameters but not on their builder code, as #15's two new builders now are (#19).
- #16: snow predictors for the monthly shares.
- An upstream note to climr on the ClimateNA coastal gap: drafted, not posted.
- rspatial/terra#2195: `rasterize(filename = )` with an integer datatype writes NA as 0 (worked around in `scripts/wb_inputs.R`).

## 1. Citation and companion sources

- **[S] Citation.** Chapman, A.R., B. Kerr and D. Wilford. 2018. "A Water Allocation Decision-Support Model and Tool for Predictions in Ungauged Basins in Northeast British Columbia, Canada." *JAWRA* 54(3): 676–693. https://doi.org/10.1111/1752-1688.12643
  - Paper No. JAWRA-17-0084-P. Received 2017-06-21, accepted 2018-02-26.
  - Title as printed in the PDF metadata and on the first page. The `nr-bcwat` knowledge-transfer (KT) doc drops ", Canada" from the title.
- **[S] Open access.** The article is open access under CC BY-NC-ND (footnote 1, p. 1). There is a free PDF at https://www2.gov.bc.ca/assets/gov/environment/air-land-water/water/northeast-water-strategy/chapman_et_al-2018-jawra.pdf (18 pp.; downloaded HTTP 200). The Wiley page returns 403 to scripts.
  - Note: the ND clause forbids adaptations of the text. It says nothing about reimplementing the method.
- **[S] Precursor paper.** Chapman, Kerr & Wilford 2012. "Hydrological Modelling and Decision-Support Tool Development for Water Allocation, Northeastern British Columbia." Geoscience BC *Summary of Activities 2011*, Report 2012-1, pp. 81–86. https://cdn.geosciencebc.com/pdf/SummaryofActivities2011/SoA2011_FullVolume.pdf (PDF pp. 88–93).
  - It gives two details the JAWRA paper omits: how the ET adjustment works, and the monthly predictors (see §2 and §3).
  - It also cites a pilot study: Chapman & Kerr 2011 (Horn River and Liard basins). **[U]** I did not locate it.
- **[S] KWT watershed report.** The Elk River report (2022-02-01) is public as an attachment to an IAAC filing: https://iaac-aeic.gc.ca/050/documents/p80087/155090E.pdf. Its "Accuracy" note (p. 34) reads: "water balance approach … 143 watersheds with hydrometric gauges … calibrated using streamflow measurements from the Water Survey of Canada, and validated using a leave-one-out cross validation … Mean error = 4.3%, Median Error = 0.3%, Mean Absolute Error = 14.8%, Watersheds within +/- 20% = 79%."
  - The report's "Hydrologic Variability" page (pp. 35–36) states that KWT variability percentiles come from **PCIC VIC `hydro_model_out`** (Jan 2014 release, downloaded 2018-01-15).
    - Historical period: 1976–2006.
    - Futures: CGCM3, GFDL 2.1 and HadCM A2.
    - Outside PCIC coverage it uses Livneh et al. 2015 (UC).
    - The percentiles are "scaled using the hydrology estimates on page 3", i.e. the water-balance MAD.
  - **[I]** This is directly relevant to `wet`: KWT already rescales PCIC VIC to the Chapman-style MAD.
- **[S] Tool-specific reports.** No per-region methods report was found for the Omineca, Cariboo, Kootenay or Northwest tools. Each tool's report carries a one-paragraph accuracy note (as in the KWT example). **[U]** Whether Foundry or the Province holds internal methods reports.
- **[S] Independent gauge inventory for the same zones.** Ahmed, A. 2015. *Inventory of Streamflow in the Omineca and Northeast Regions*. BC MoE, EcoCat report 48460: https://a100.gov.bc.ca/pub/acat/public/viewReport.do?reportId=48460
  - It gives 1981–2010 normals per natural (or minor-regulation) WSC station.
  - It comes with per-hydrologic-zone datasheets (zones 3, 4, 6, 7, 8, 12, 13) and a summary `.xlsx`.
  - Obedkoff's regional "Streamflow in …" series (2000–2003) and the newer "Inventory of Streamflow" series (2017–2020) are also on EcoCat. **[U]** I did not locate the Obedkoff 2000 Omineca–Peace PDF itself; the for.gov.bc.ca "bib47546" hit is an unrelated restoration document.

## 2. Annual model

- **[S] Precipitation (P) and temperature.** From ClimateWNA (Wang et al. 2012), which is PRISM-based and "scale-free" (DATA section, p. 6).
  - The paper **does not state the ClimateWNA version or the normal period.**
  - The `nr-bcwat` file `client/src/constants/model-information.js` records it per tool:

    | Tool | ClimateWNA version | Normal period |
    |---|---|---|
    | NEWT | 4.62 | 1961–1990 |
    | KWT | 4.62 | 1961–1990 |
    | Cariboo | 4.62 | 1961–1990 |
    | OWT (Omineca) | 4.72 | 1961–1990 |
    | NWWT (Northwest) | 4.72 | 1971–2000 |

  - **[I]** Those values are partly placeholder (see §6).
- **[S] ET source.** CGIAR-CSI Global Soil-Water Balance (Trabucco & Zomer 2010), p. 6.
  - PET: modified Hargreaves (Droogers & Allen 2002) on WorldClim 1950–2000, 1 km.
  - A monthly soil reduction factor gives AET. It uses a linear stress function with a fixed 350 mm maximum soil water, and the vegetation coefficient is fixed at 1 (an "agronomic crop"), p. 8.
- **[S] Land-cover adjustment of AET.**
  - JAWRA p. 8 says the AET "was adjusted" using measured AET by cover type, collected in Table 3 (26 settings: barren 126±32 mm, coniferous 276±71, deciduous 492±86, shrub 195±51, snow/ice 51±7, water 350–643, etc.).
  - The 2012 paper (p. 83) gives the mechanism: the land cover was rasterised "to values numerically equivalent to the ratio of the actual evapotranspiration for the land cover or vegetation type to that of the estimated agronomic evapotranspiration rate", i.e. **AET_adj = AET_CGIAR × ratio(class)**. The ratios "were adjusted within the model", i.e. tuned during calibration.
  - **[U]** The final ratios per class are not published.
- **[S] Land cover data.** Land Cover Circa 2000 (Canada 2009), with gaps filled by BC VRI and Baseline Thematic Mapping (pp. 8–9).
- **[S] Other inputs.**
  - DEM: Geobase (Canada 2000).
  - Nominal resolution: **600 m**; the inputs range from 100 to 1,000 m (p. 6).
  - Tools: gvSIG/SEXTANTE, Systat 13, and R for leave-one-out cross-validation (LOOCV).
- **[S] Water balance.** RO_pred = P − ET per cell, annual mm (Eq. 1, p. 4). Groundwater is assumed to be net zero. The cell values are integrated over each gauge's FWA-delineated catchment.
- **[S] Residual adjustment** (Eqs. 2–3, p. 5).
  - RO_resid = RO_pred − RO_obs.
  - The residual was regressed on the candidate predictors: mean elevation, drainage area, mean annual T, mean annual P, UTM northing and UTM easting (Table 2 correlation matrices). Tests: p ≤ 0.05, K–S normality, visual check of homoscedasticity.
  - The regression is fitted **separately per Obedkoff (2000) hydrologic zone**:

    | Zone | n | Predictors | Adj. R² | SEE |
    |---|---|---|---|---|
    | Southern Interior Plains (Peace) | 18 | UTM easting + mean annual P | 0.72 | 39 mm |
    | Northern Interior Plains (Liard) | 27 | UTM northing + mean annual P | 0.51 | 32 mm |

  - The coefficients were applied to gridded P, northing and easting, and RO_adj = RO_pred + RO_resid_regress.
  - **[U]** The regression coefficients are not published.
  - The KT doc's instruction "for each region, take the variable with the highest correlation" is a simplification: the paper used two predictors per zone.
  - **[S]** The UTM axes in Fig. 5 are labelled "Z10N" for the whole study area.
- **[S] A third, undocumented step.** The Table 4 note (p. 11) reads: "a final dataset after adjustment to measured flows".
  - After that step, errors at the gauges fall to near zero (mean 0.2%, median 0.0%), with a few outliers remaining: 07FD004 +6.0, 10CC001 +5.6, 10ED004 +6.2.
  - **[U]** The method is not described anywhere.
  - **[I]** Because some residual remains, this looks like a spatial or interpolated correction toward gauges rather than per-station forcing. It also means the delivered grid is gauge-conditioned near gauges.
- **[S] Accuracy** (Table 5, p. 11; the minus signs are lost in text extraction, so read from the rendered page):

  | Stage | MBE | MAE | ME (median) | Within ±20% |
  |---|---|---|---|---|
  | Raw P − ET | 1.2% | 24.9% | −7.1% | 62.5% |
  | Adjusted | 5.5% | 16.1% | 3.7% | 77.8% |

  - Observed vs modelled annual runoff: r² = 0.96.
  - The error is E = 100·(pred − obs)/obs (Eq. 4).
  - **[S]** The prose (p. 9) calls 1.2% and 3.7% "ME", which contradicts Table 5 (1.2 is the MBE; 3.7 is the median). The Eq. 4 text also mislabels the abbreviations. Trust the table: `nr-bcwat` NEWT = mean 5.5 / median 3.7 / MAE 16.1 / 77.8.
  - **[U]** Whether Table 5 is in-sample or LOOCV. LOOCV is described as used "to test" (p. 6), but the table is not labelled.
- **[S] Pattern in the errors.** Under-prediction in high-elevation and high-P basins, attributed to ClimateWNA under-estimating mountain precipitation (p. 9).

## 3. Monthly model

- **[S] Response.** The percentage of mean annual runoff in each month: RO-MONTH = 100·(monthly obs mm / annual obs mm) (Eq. 5, p. 6).
- **[S] Candidate predictors.**
  - 2018: mean watershed elevation, drainage area, mean monthly T, mean monthly P, UTM northing, UTM easting.
  - 2012: **grid cell** elevation, northing, easting, monthly T and monthly P, with no drainage area.
- **[S] Fitting.** One regression per month (12 in total), p ≤ 0.05, with variables kept only where significant. The model is fitted **for the whole study area, not per zone** ("across the study area", p. 6).
- **[S] Fit statistics.**
  - Adjusted R²: August 0.46 (SEE 2.6 "mm") up to January and February 0.82 (SEE 0.3 "mm"). Most months are 0.60–0.82.
  - Fit is judged by Nash–Sutcliffe (NS) and Spearman's rank correlation (rs) between the modelled and observed 12-month series per station: median NS 0.92 (85% ≥ 0.8), median rs 0.98 (91% ≥ 0.9) (p. 9, Table 4).
  - Some stations fit poorly: 07FD004 NS −0.42, 07FD001 0.09, 07FD009 0.25.
  - In 2012 the adjusted R² ranged 0.50–0.76 and the median NS was 0.94.
- **[S] Application.** The coefficients are "applied to the gridded data of adjusted annual runoff (RO_adj)" to give unit runoff for each month.
- **[U] Summing to 100%.** How (or whether) the 12 shares are forced to sum to 100%, and how negative predictions are handled: nothing is stated.
- **[I] Scale.** The regression is fitted on watershed means but applied to cells. That cannot work for drainage area as a cell attribute, so either area was never significant or the monthly split is computed per upstream watershed (see §7).
- **[S] What `nr-bcwat` stores.**
  - Per fundamental watershed: `q01…q12` and `qyr` in mm.
  - MAD m³/s = qyr/1000 × upstream_area_m² / (365.25·86400).
  - Monthly m³/s uses the calendar days of each month, with February = 28 (`database_initialization/queries/bcwat_watershed_data.py`, Cariboo and KWT rollups).
  - The KT doc says fundamental-watershed values are the "average" of the intersected grid, and the upstream value is the "average value of the monthly hydrology of the upstream watershed segments". **[U]** Whether that average is area-weighted.

## 4. Stations

- **[S] Selection rules** (p. 9): unregulated flows, at least 5 years of record. Excluded: large main-stem rivers arising outside the study area (Peace, Liard), lake outlets, and drainages with man-made controls. The same rules appear in the KT doc, Step 1.
- **[S] Record periods.** Each station's full period of record was used; Table 4 gives from/to years, which span 1944–2009 (e.g. 07FB005 1978–2001, 07GD004 1993–2009). The periods are **not aligned to the ClimateWNA normal.**
  - Catchments range from 38 to 43,200 km².
  - Only 2 are under 100 km², and 16 are under 500 km².
  - Catchments were delineated from the 1:20k FWA.
- **[S] The station list is published.** Table 4 (pp. 10–11) lists all 45 stations with area, years, measured mm, raw/adjusted/final mm and % error, NS and rs. They are in BC, Alberta and the NWT.
- **[S] 2012 had more stations.** The 2012 version used **53** stations (Table 1 there, with record lengths).
  - The 8 in 2012 but not 2018: 07FC002, 07FD011, 07FD013, 07GD001, 07GD002, 07GD003, 07JF004, 10BE009.
  - **[U]** Why they were dropped.
- **[S] Station tables in the data release.** For the other tools, `nr-bcwat` migrates `nwwt|owt.fdc_wsc_stations_in_model` (station_number, excluded, exclusion_reason, geometry), so the release should carry per-tool station lists with exclusion reasons.
  - The flow-duration-curve tables (`fdc`, `fdc_distance` with `candidate` and 12 monthly distances, and `fdc_physical`) indicate that OWT and NWWT flow-duration curves come from analogue stations picked by physical similarity. **[I]**

## 5. Region boundaries

- **[S] Provincial layer.** `WHSE_WATER_MANAGEMENT.HYDZ_HYDROLOGICZONE_SP`.
  - Catalogue record: "Hydrology: Hydrologic Zone Boundaries of British Columbia", id `329fd234-8835-4d44-9aaa-97c37bfc8d92`, Open Government Licence – BC. Available through WMS/WFS at openmaps.gov.bc.ca.
  - It has 29 zones, fields `HYDROLOGICZONE_NO` and `HYDROLOGICZONE_NAME`.
  - Zone 6 SOUTHERN INTERIOR PLAINS and zone 4 NORTHERN INTERIOR PLAINS are the two zones Chapman used. Also relevant for the plains: zone 7 Southern Rocky Mountain Foothills and zone 3 Northern Rocky Mountains.
- **[S] Extended version.** Catalogue record "BC Hydrologic Zones", id `481d6d4d-a536-4df9-9e9c-7473cd2ed89e`, OGL-BC. Zip download: `bc_hydrologic_zones.zip`.
  - Contents: shapefile, BC Albers, 43 features, DBF dated 2021-03-19, fields `HYDZN_NO` and `HYDZN_NAME`, plus US HUC6 fields.
  - The record describes the zones as "defined previously by Obedkoff and others" and "extended into the neighbouring province, territories, and states" for the 2020 RFFA project.
  - **[I]** This extended version is the one to use, because the calibration gauges lie in Alberta and the NWT.
- **[S] Also available.** `WHSE_WATER_MANAGEMENT.HYDZ_ANNUAL_RUNOFF_LINE` (Normal Annual Runoff isolines, 1961–1990; OGL-BC), a legacy Obedkoff-era product that makes a useful independent reference surface.

## 6. Coverage by tool

- **[S] Tools and dates** (news releases):
  - NEWT (Northeast), 2012–2016: Chapman & Kerr 2016, water.bcogc.ca/newt.
  - Northwest Water Tool (NWWT), 2014-09-24: "123 hydrometric stations in B.C., the Yukon and Alaska".
  - Omineca (OWT), 2015-06-17: the release gives the **same** "123 stations in B.C., the Yukon and Alaska".
  - Cariboo, 2016-06-14: "119 long-term hydrometric stations".
  - Kootenay-Boundary (KWT), 2018: 143 stations. Variability and futures come from PCIC and UC VIC.
- **[S] Tools in the `nr-bcwat` watershed module.** Regions 3 = Cariboo, 4 = KWT, 5 = NWWT, 6 = OWT (`get_watershed_region_by_id.py`: `region_id IN (3,4,5,6)`). `swp` and `nwp` (regions 1–2) come from a `bcwmd` schema. **[U]** What those two are.
  - **NEWT is not a region in `nr-bcwat`.** It is only the fall-through default in `Methods.vue`. **[I]** The northeast may not be in the new tool's watershed data.
- **[S] Per-tool metrics in `model-information.js`** (n / mean / median / MAE / % within ±20% / climate normal / ClimateWNA version):

  | Tool | n | Mean | Median | MAE | Within ±20% | Normal | ClimateWNA |
  |---|---|---|---|---|---|---|---|
  | OWT | 104 | 0.0 | 0.0 | 13.0 | 76 | 1961–90 | 4.72 |
  | NWWT | 123 | 0.0 | 0.0 | 13.0 | 76 | 1971–2000 | 4.72 |
  | NEWT | 45 | 5.5 | 3.7 | 16.1 | 77.8 | 1961–90 | 4.62 |
  | KWT | 143 | 4.3 | 0.3 | 14.8 | 79 | 1961–90 | 4.62 |
  | Cariboo | 104 | 0.0 | 0.0 | 13 | 76 | 1961–90 | 4.62 |

  - SWP and NWP are copies of NEWT.
  - A `// TODO: update … once we get it` comment covers KWT, SWP, NWP and Cariboo.
  - **[I] Reliability of the table:**
    - KWT matches the Elk report exactly, so it is real.
    - Cariboo is a copy of OWT's numbers, and 104 contradicts the 119 in the release.
    - OWT's 104 contradicts the release's 123.
    - Mean and median of exactly 0.0 alongside MAE 13% is unusual: it is consistent with metrics computed after a bias correction, but that is speculation.
- **[S] A display bug.** `Methods.vue` reads `regionMethodsData.climateDriverYears`, but the constant key is `cwnaDriverYears`. **[I]** The climate years therefore render blank.
- **[S] One method across tools?** Methods.vue says every tool used "similar methods to those described in" Chapman 2018, with ClimateWNA 4.72 drivers. **[U]** Per-tool variants: the zones used, the ET source (the WorldClim-based CGIAR product is global, so probably the same), the number of monthly regressions, and whether each tool had the "final" gauge adjustment. KWT adds PCIC-scaled daily percentiles and OWT/NWWT add analogue-station flow-duration curves; those are extra products, not variants of the MAD model.

## 7. Where the method is silent or ambiguous, and a reimplementation must choose

1. **ClimateWNA version and normal period.** Not in the paper; `nr-bcwat` gives 4.62 or 4.72 and 1961–90 or 1971–2000 by tool. ClimateWNA has since been superseded by ClimateNA (v7+). Choose a version and a normal, and say that the choice shifts P.
2. **Gauge period vs climate normal.** Gauges used their full record (1944–2009) against a 30-year normal. Options: (a) full record, (b) only years inside the normal with a minimum-years rule, (c) the 1981–2010 station normals from Ahmed 2015. This choice alone moves observed mm.
3. **ET product.** CGIAR soil-water balance "2010" was v1 (Hargreaves, WorldClim 1950–2000). What is available now is Global High-Resolution Soil-Water Balance **v3** (figshare 7707605, CC0 confirmed via the figshare API on 2026-09-26, 2019, annual and monthly AET), and Global-AI/PET v3 is Penman–Monteith on WorldClim 2.1 (1970–2000). **[I]** v1 may no longer be obtainable, so matching the published ET exactly is probably impossible.
4. **Land-cover AET ratio per class.** Table 3 gives ranges, not the ratios used, and the ratios were "adjusted within the model". Choose: the class midpoint ÷ the regional mean CGIAR AET, or fit the ratios to gauges (which moves ET calibration into the fit).
5. **Land cover source.** Land Cover Circa 2000 plus BC VRI/BTM infill. A modern equivalent is NRCan 2015/2020 30 m or ESA WorldCover; the class crosswalk to Table 3 is ours to write.
6. **Grid resolution and resampling.** 600 m nominal. How ClimateWNA was generated per cell (DEM-driven at 600 m?) and how the 1 km CGIAR grid was resampled are not stated.
7. **Catchment integration.** Mean of cell values in the FWA catchment: area-weighted, cell-centre, or touches? This is the same question `wet` already answers for PCIC.
8. **Residual sign convention.** Eq. 2 defines resid = pred − obs, but Eq. 3 *adds* the regressed residual. Taken literally that doubles the error. Either the regression was fitted to obs − pred, or Eq. 3 should subtract. Pick obs − pred and add it.
9. **Residual regression specification.**
   - Stepwise or best-subset? Model selection is described only as "p ≤ 0.05".
   - Units of the UTM predictors: a single zone (Z10N) extended across the study area, or zone-correct? Using BC Albers is the saner choice and changes the coefficients.
   - Residual regression in mm or in %?
   - Region assignment of a gauge whose catchment straddles zones: by outlet, centroid or majority area?
   - Zones with too few gauges: pool them, or skip the adjustment?
   - How the adjustment surface is blended across zone boundaries: nothing is said, and a hard step is implied.
10. **Is the adjustment surface clipped?** The regression is applied to gridded P, E and N with no limits stated. Extrapolation beyond the calibration range, and a negative RO_adj in dry cells, are unhandled.
11. **The "final … adjustment to measured flows" step** (Table 4 note). Undocumented. Choose: none (report the Eq. 3 surface); inverse-distance or kriged residual correction; or per-catchment forcing upstream of gauges. This decides whether modelled values at gauges are predictions or restatements of the gauges, which matters for comparing against their release.
12. **Error metric conventions.**
    - Eq. 4 is written with RO_pred even for the adjusted model.
    - MBE and ME are mislabelled in the prose.
    - Whether reported metrics are in-sample, LOOCV, or post-"final".
    - For our evaluation: report LOOCV and in-sample separately, and never post-forcing.
13. **Monthly response and form.** Linear in percent? The SEE is reported in "mm" although the response is a percentage. Also: ordinary least squares on shares, or a compositional/logit transform?
14. **Monthly: forcing the shares to sum to 100.** Not stated. Options: renormalise the 12 predictions, predict 11 months and take the residual, or fit a compositional model. Also a floor for negative winter shares.
15. **Monthly: one regression for the study area, or one per zone?** The paper implies the whole area. With 100+ stations across mixed regimes (coast, interior, plains) a single set of 12 regressions will not hold, and the other tools presumably changed this. **[U]** How.
16. **Monthly: where the predictors are evaluated.** Per grid cell (2012 wording) or per upstream watershed (2018 lists drainage area)? Drainage area forces a per-watershed application. Choose per-watershed (upstream means), since the shares are properties of the catchment rather than of a cell.
17. **Monthly predictor definitions.** Monthly T and P for the same month only, or lagged months (snowmelt depends on winter P)? The paper implies the same month only.
18. **Mean vs median elevation.** The residual analysis lists mean elevation, but Fig. 5 plots median elevation.
19. **Upstream accumulation.** `nr-bcwat` says "average of upstream segments". Area-weighted or not? It must be area-weighted to conserve volume; `wet_upstream_mean()` already does that.
20. **Unit conversion.** Annual uses 365.25 days; monthly uses calendar days with February = 28. The sum of monthly volumes therefore ≠ the annual volume by about 0.07%. Choose one convention.
21. **Lakes, glaciers and groundwater.** "Net zero" groundwater is justified only for plains shale. Lake evaporation (ET for the water class is 350–643 mm) and glacier melt are unaddressed for the NW, Kootenay and Cariboo regimes.
22. **Regulation and diversions.** Excluded from calibration, and the output is "natural". A comparison against their release must use natural flow on both sides.
23. **Station screening details.** "Unregulated" by the HYDAT regulation flag or by judgement? Minimum 5 years complete, or counting partial years? The seasonal-only gauges common in the NE: are they allowed?

## Sources

- Chapman et al. 2018 PDF: https://www2.gov.bc.ca/assets/gov/environment/air-land-water/water/northeast-water-strategy/chapman_et_al-2018-jawra.pdf. Cited pages: Eqs. 1–5 on pp. 4–6, DATA on pp. 6–9, Table 3 on p. 8, Tables 4–5 on pp. 10–11, Limitations on p. 14.
- Chapman et al. 2012, Geoscience BC SoA 2011 pp. 81–86: https://cdn.geosciencebc.com/pdf/SummaryofActivities2011/SoA2011_FullVolume.pdf
- `nr-bcwat` (GitHub `bcgov/nr-bcwat`, main):
  - `documentation/knowledge_transfer_documentation.md`, section "Process for adding a new region to the framework"
  - `client/src/constants/model-information.js`
  - `client/src/components/watershed/report/Methods.vue`
  - `database_initialization/queries/bcwat_watershed_data.py`
  - `database_initialization/queries/bcwat_obs_data.py` (the `region_query`)
  - `backend/queries/watershed/get_watershed_region_by_id.py`
- KWT Elk River report: https://iaac-aeic.gc.ca/050/documents/p80087/155090E.pdf (accuracy note p. 34; PCIC variability pp. 35–36)
- News releases:
  - NWWT: https://news.gov.bc.ca/releases/2014FLNR0228-001419
  - OWT: https://archive.news.gov.bc.ca/releases/news_releases_2013-2017/2015FLNR0127-000891.htm
  - Cariboo: https://archive.news.gov.bc.ca/releases/news_releases_2013-2017/2016FLNR0122-001030.htm
  - KWT: https://news.gov.bc.ca/releases/2018FLNR0205-001541
- BC Data Catalogue:
  - https://catalogue.data.gov.bc.ca/dataset/hydrology-hydrologic-zone-boundaries-of-british-columbia
  - https://catalogue.data.gov.bc.ca/dataset/bc-hydrologic-zones
  - https://catalogue.data.gov.bc.ca/dataset/hydrology-normal-annual-runoff-isolines-1961-1990-historical
- Ahmed 2015, Omineca and Northeast inventory: https://a100.gov.bc.ca/pub/acat/public/viewReport.do?reportId=48460
- CGIAR soil-water balance v3: https://figshare.com/articles/dataset/Global_High-Resolution_Soil-Water_Balance/7707605
