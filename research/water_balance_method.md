# Chapman, Kerr & Wilford (2018): the BC Water Tools method, and what a reimplementation must decide

**Verified:** 2026-09-26 (hydrologic zones layer and PDF access re-checked by hand) · **Issues:** #5 (found; `wet` builds an open reimplementation) · **Produced by:** reading the open-access PDF, the 2012 Geoscience BC precursor, `bcgov/nr-bcwat` (main), a 2022 Kootenay-Boundary Water Tool report, BC news releases, and the BC Data Catalogue API and openmaps WFS. **Status:** desk research. Nothing has been fitted yet.

Legend: **[S]** stated in the source cited · **[I]** inferred · **[U]** unknown or not published. Sources are listed at the end; all are online.

---

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
3. **ET product.** CGIAR soil-water balance "2010" was v1 (Hargreaves, WorldClim 1950–2000). What is available now is Global High-Resolution Soil-Water Balance **v3** (figshare 7707605, CC0, 2019, annual and monthly AET), and Global-AI/PET v3 is Penman–Monteith on WorldClim 2.1 (1970–2000). **[I]** v1 may no longer be obtainable, so matching the published ET exactly is probably impossible.
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
