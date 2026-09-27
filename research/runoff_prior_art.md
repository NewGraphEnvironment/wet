# Runoff estimates for BC: inputs, comparison products, validation data and method

**Verified:** 2026-09-26 (climr CRAN status and the Kovacek table row count re-checked by hand) · **Issues:** #5 (found), the planned open water-balance issue (uses) · **Produced by:** web and GitHub reads, plus measurements on the local HYDAT sqlite and the Kovacek tables. **Status:** desk research. Companion to [water_balance_method.md](water_balance_method.md).

Tags: **[S]** the linked source says it · **[M]** measured · **[I]** inferred, not verified.

---

## 0. Findings that change the plan

1. **Chapman 2018 did not use a reference-ET grid. It used an AET product that it then adjusted.** [S] The ET was CGIAR's gridded ET (Trabucco & Zomer 2010): modified-Hargreaves PET from WorldClim 1950–2000 at 1 km, with a soil-water reduction factor. That grid was then "adjusted to better represent the land cover" using a table of measured AET by cover class (their Table 3). Precipitation and temperature came from ClimateWNA, and the analysis ran on a 600 m grid. — [Chapman et al. 2018 PDF](https://www2.gov.bc.ca/assets/gov/environment/air-land-water/water/northeast-water-strategy/chapman_et_al-2018-jawra.pdf), pp. 5–8.
   **climr has no AET** (§1). The nearest like-for-like source is the CGIAR *Global High-Resolution Soil-Water Balance* AET (30″), not climr's Eref.
2. **Chapman validated with leave-one-out CV over 45 WSC stations**, "following Moore et al. (2011)". The stations were unregulated with at least 5 years of record. The published result is MAE 16 %, with 78 % of stations within ±20 %; the monthly median NSE is 0.92 [S] (same PDF: abstract and p. 5). That LOO is *not* blocked against nested gauges (§4).
3. **climr's default reference map is a 1981–2010 mosaic, but the roxygen still says 1961–1990.** [S]/[I] The mosaic vignette says it compiled "source climatologies exclusively of the 1981-2010 period" at 2.5 km ([methods_mosaic](https://bcgov.github.io/climr/articles/methods_mosaic.html)). Meanwhile `downscale()` documents `which_refmap` and `return_refperiod` as "1961-1990" ([R/downscale.R](https://github.com/bcgov/climr/blob/main/R/downscale.R)). **Probe before relying on the period:** run `downscale()` on one point and read its `PERIOD` label.
4. **BC Water Tool stores results per FWA fundamental watershed** (`bcwat_ws.fwa_fund.watershed_feature_id`, with `fund_rollup_report`, monthly `fdc`, and `fdc_wsc_station_in_model`) [S, schema in [bcwat_watershed_erd_diagram.py](https://github.com/bcgov/nr-bcwat/blob/main/database_initialization/queries/bcwat_watershed_erd_diagram.py)]. It joins to `wet` on the same key, but it is **the same method**, so it is a parity check, not an independent one.

---

## 1. Inputs: `climr` and ET sources

### climr ([bcgov/climr](https://github.com/bcgov/climr))
| Item | Answer |
|---|---|
| CRAN | **No.** `cran.r-project.org/package=climr` returns 404 [M]. GitHub only: `remotes::install_github("bcgov/climr")`. DESCRIPTION is v0.2.2, dated 12-06-2025 [S, [DESCRIPTION](https://github.com/bcgov/climr/blob/main/DESCRIPTION)]. The repo was last pushed 2026-05-12 [M]. |
| Licence | Apache 2.0 [S, DESCRIPTION] |
| Access | A remote PostGIS database with optional local cache. The package ships a built-in read-only client profile (`climr_client` at a fixed host in `R/database.R`), so no user database or credentials are needed, only network access [S, [R/database.R](https://github.com/bcgov/climr/blob/main/R/database.R)]. `pre_cache()` pre-downloads an AOI [S, NEWS 0.2.2]. `db_option = "auto"/"database"/"local"` [S]. |
| Reference maps | `list_refmaps()` gives `refmap_climr` (a composite of BC PRISM, adjusted US PRISM and Daymet, **1981–2010, 2.5 km**, aggregated from the 800 m BC PRISM) and `refmap_climatena` (ClimateNA 1961–1990, about 4 km) [S, [data-lists.R](https://github.com/bcgov/climr/blob/main/R/data-lists.R), [methods_mosaic](https://bcgov.github.io/climr/articles/methods_mosaic.html)]. Temperature is elevation-adjusted by lapse rate to the elevation you supply, so it is "scale-free" [S]. |
| Normal periods | Only the reference map period plus `list_obs_periods()` = **"2001_2020"** [S, data-lists.R]. There is **no direct 1991–2020 normal.** Annual observed years run 1901–2023/24 across three series (CRU/GPCC, ClimateNA, MSWX/MSWEP) [S, [README](https://github.com/bcgov/climr)]. A 1991–2020 normal could be built by averaging `obs_years = 1991:2020` [I]. Averaging nonlinear derived variables (Eref, CMD, PAS) over years is not the same as deriving them from mean monthly values [I]. |
| Variables | 247 codes [M, [variables.csv](https://github.com/bcgov/climr/blob/main/data-raw/derivedVariables/variables.csv)]. **Monthly, seasonal and annual:** PPT, Tmax, Tmin, Tave, **Eref (Hargreaves reference evaporation), CMD (Hargreaves climatic moisture deficit)**, PAS (precip as snow), RH, NFFD, DD5, DD18, DDsub0, DDsub18. CMI is annual and monthly. **Annual only:** MAP, MSP, MAT, MWMT, MCMT, TD, AHM, SHM, FFP, bFFP, eFFP, EMT, EXT. |
| AET / runoff | **None** [M, variables.csv]. Eref is Hargreaves 1985 computed from monthly Tmax and Tmin, and CMD = max(0, Eref − PPT) [S, [R/calc_Eref_CMD.R](https://github.com/bcgov/climr/blob/main/R/calc_Eref_CMD.R)]. |
| Points and polygons | `downscale(xyz)` takes a data.frame of `id, lon, lat, elev` **or** a single-layer elevation `SpatRaster`, which returns a raster stack [S, [downscale ref](https://bcgov.github.io/climr/reference/downscale.html), NEWS 0.2.0]. There is no polygon method. The raster vignette samples cells inside polygons and warns against using centroids for large polygons [S, [climr_with_rasters](https://bcgov.github.io/climr/articles/climr_with_rasters.html)]. For `wet`, the fit is to downscale on a DEM raster and then area-weight per fundamental watershed with `wet_ws_sample()` [I]. |
| Local status | Not installed on this Mac [M]. |

### ET alternatives for BC
| Source | Variable | Resolution / period | Licence | Notes |
|---|---|---|---|---|
| CGIAR Global High-Resolution Soil-Water Balance (Trabucco & Zomer) — [figshare 7707605](https://figshare.com/articles/dataset/Global_High-Resolution_Soil-Water_Balance/7707605) | **AET**, soil water deficit | 30″ (about 1 km), climatology (WorldClim-based) [S, search snippet] | figshare page returned 403; licence **unverified** | **Chapman's actual ET source** (the earlier version) [S, Chapman p. 5]. This is the like-for-like choice. |
| CGIAR Global-AI / ET0 v3 — [Zomer et al. 2022](https://www.nature.com/articles/s41597-022-01493-1), [figshare](https://figshare.com/articles/dataset/Global_Aridity_Index_and_Potential_Evapotranspiration_ET0_Climate_Database_v2/7504448/5) | PET (FAO-56 Penman–Monteith) | 30″, 1970–2000 [S] | Sources conflict (CC0 vs non-commercial); **verify** | Reference ET only |
| TerraClimate — [climatologylab](https://www.climatologylab.org/terraclimate.html), [Abatzoglou 2018](https://www.nature.com/articles/sdata2017191) | **AET**, PET, **runoff (q)**, deficit, SWE | 1/24° (about 4 km), monthly, 1958– [S] | **CC0** [S] | Also a runoff comparator (§2) |
| MODIS MOD16A3GF v061 — [Earthdata](https://www.earthdata.nasa.gov/data/catalog/lpcloud-mod16a3gf-061) | ET, PET (Penman–Monteith) | 500 m, yearly (8-day A2), 2000– [S] | Open, no restrictions (EOSDIS) [S] | Gaps over non-vegetated, snow and ice, and urban cells, which matters in alpine BC [I, known MOD16 limitation] |
| GLEAM4 — [Miralles et al. 2025](https://www.nature.com/articles/s41597-025-04610-y), [gleam.eu](https://www.gleam.eu/) | Actual E | 0.1°, daily, 1980–2023 [S] | **CC BY-NC-ND 4.0** [S], registration required | NC-ND is a blocker for redistribution |
| ClimateNA / AdaptWest grids — [ualberta](https://sites.ualberta.ca/~ahamann/data/climatena.html) | Eref, CMD (Hargreaves), PAS | 1 km, normals 1961–90, 1971–2000, 1981–2010, **1991–2020** [S] | Terms in the bundled Citation.txt, **unverified** | Same Hargreaves formulation as climr [S, climr DESCRIPTION cites Wang 2016]. The only source of a ready-made 1991–2020 grid. |
| Hamon / Hargreaves computed in-house | PET | Any resolution | — | Needs only climr Tmax/Tmin plus latitude [I]. PET is not AET, so it needs a Budyko/Zhang step or Chapman's land-cover AET adjustment. |

---

## 2. Prior art and comparison products (ranked by value as an independent check)

Independence here means how little the product shares with our method and with our validation gauges. **Anything calibrated to WSC gauges is not independent of a HYDAT validation.** Report its HYDAT skill only as context.

| Rank | Product | Coverage | Variable | Resolution / unit | Access / licence | Code | Why this rank |
|---|---|---|---|---|---|---|---|
| 1 | **PCIC VIC-GL-Raven channel-scale CMIP6** (already in `research/pcic_hydrology.md`) | Coast + Fraser now; Peace and Upper Columbia later | Daily routed Q per reach, historical and CMIP6 | Reach on an FWA-derived network | PCIC OPeNDAP | — | Process-based and routed on an FWA-like network, so a per-segment comparison is direct. It differs from our method at every step. |
| 2 | **PCIC VIC-GL gridded** (in `wet` now) | Peace, Fraser, Columbia | Daily runoff + baseflow | 1/16° | PCIC OPeNDAP | `wet` | Independent process model, already accumulated per segment by `wet`. |
| 3 | **GEOGLOWS v2 retrospective** — [AWS registry](https://registry.opendata.aws/geoglows-v2/) | Global incl. BC | Daily Q, 1940–present (ERA5-driven) [S] | About 7 M TDX-Hydro reaches [S] | **CC BY 4.0** [S] (return-period store NC [S, secondary]) | Open model config | Open, per-reach and long. Coarse forcing in mountains [I]. Needs a TDX-to-FWA reach match. |
| 4 | **GloFAS v4 / v5 reanalysis** (LISFLOOD) — [EWDS](https://ewds.climate.copernicus.eu/datasets/cems-glofas-historical) | Global | Daily Q and runoff, 1979– [S] | 0.05° grid [S] | "CEMS-FLOODS datasets licence" [S] | LISFLOOD is open source [S, [ECMWF news](https://www.ecmwf.int/en/about/media-centre/news/2022/copernicus-emergency-management-service-releases-glofas-v40)] | Calibrated at 1996 gauges ≥ 500 km² [S], so it is partly in-sample for large BC rivers and unreliable for small ones [I]. |
| 5 | **TerraClimate runoff (q)** — [climatologylab](https://www.climatologylab.org/terraclimate.html) | Global | Monthly runoff (bucket model) | 4 km, 1958– [S] | CC0 [S] | — | Uncalibrated and gauge-free, so it is truly independent of HYDAT. A simple water balance with no glacier or groundwater terms [I], so expect biases. A good "naive P − AET" baseline for the monthly shape. |
| 6 | **BC Normal Annual Runoff isolines 1961–1990** (Obedkoff) — [open.canada](https://open.canada.ca/data/en/dataset/d6f6ddc7-fbc2-4264-aa30-fc3d5138a6b3), [BC catalogue](https://catalogue.data.gov.bc.ca/dataset/hydrology-normal-annual-runoff-isolines-1961-1990-historical) | BC | Annual runoff, mm | Isolines, "historical" status [S] | OGL-BC; KML/WMS/BCGW [S] | — | The province's own hand-drawn MAR surface and the basis of the hydrologic-zone approach in the [Streamflow Inventory reports](https://www2.gov.bc.ca/gov/content/environment/air-land-water/water/water-science-data/water-data-tools/provincial-hydrology-program/resources/streamflow-inventory) (six regional reports, 2013–2020) [S]. Drawn from the same gauges and annual only. May also supply the Obedkoff region boundaries the plan needs [I]. |
| 7 | **RiverATLAS `dis_m3_pyr`** (HydroATLAS v1) — [Linke et al. 2019](https://www.nature.com/articles/s41597-019-0300-6), [hydrosheds](https://www.hydrosheds.org/hydroatlas) | Global | Long-term natural Q: annual mean, plus min/max month [S/I] | WaterGAP 2.2 0.5°, downscaled to 15″ reaches [S] | CC BY 4.0 [S] | — | Easy and open, but 0.5° runoff in BC mountains is weak. sMAPE is 35 % globally [S]. |
| 8 | **GRADES-hydroDL** — [reachhydro](https://www.reachhydro.org/home/records/grades-hydrodl) | Global | Daily Q, 1980–NRT [S] | 2.94 M MERIT-Basins reaches; 0.25° LSTM runoff [S] | **CC BY-NC-SA 4.0** [S] | — | A useful skill reference. The NC licence limits redistribution. The original GRADES (VIC) is deprecated [S, [grades](https://www.reachhydro.org/home/records/grades)]. |
| 9 | **GRUN** — [Ghiggi et al. 2019](https://essd.copernicus.org/articles/11/1655/2019/), [figshare](https://figshare.com/articles/dataset/GRUN_Global_Runoff_Reconstruction/9228176) | Global | Monthly runoff, 1902–2014 | 0.5° [S] | Article is CC BY 4.0; data licence not confirmed [I] | — | ML trained on gauges ≤ 2,500 km² [S]. Too coarse for BC headwaters. Regional context only. |
| 10 | **Moore, Trubilowicz & Buttle 2012** — [JAWRA 48(1):32](https://onlinelibrary.wiley.com/doi/10.1111/j.1752-1688.2011.00595.x) | BC | Monthly water-balance runoff and regime class | ClimateBC normals, 400 m [S] | Paywalled; no data release found [I] | — | The **methodological** ancestor of Chapman's LOO CV. It adds canopy interception, glacier melt and lake evaporation to a monthly WB [S]. Useful for design choices, not as a comparison layer. |
| 11 | **Eaton & Moore 2010, "Regional hydrology"** — [Compendium ch. 4](https://a100.gov.bc.ca/pub/eirs/finishDownloadDocument.do?subdocumentId=12558) | BC | Regime descriptions | — | BC gov PDF | — | Background for choosing regression regions and regimes. Not a product. |
| 12 | **Canada1Water** (GSC + Aquanty, HydroGeoSphere + CLM5 + WRF) — [canada1water.ca](https://www.canada1water.ca/), [data framework (Zenodo)](https://zenodo.org/records/17779795) | Canada | Integrated SW/GW simulations | Portal tiles at 1°×1° [S] | "Free of charge" for research and decision-making [S]; formal licence **unverified** | — | Interesting but heavy. How to extract per-reach outputs is unclear [I]. |
| 13 | **ECCC NSRPS / GEM-Hydro (SVS + WATROUTE), DHPS / EHPS** — [MSC open data](https://eccc-msc.github.io/open-data/readme_en/), [CaLDAS-NSRPS](https://open.canada.ca/data/en/dataset/3959c86b-b555-4ad8-9fcc-8fecfb79918c), [Gaborit 2017](https://hess.copernicus.org/articles/21/4825/2017/) | Canada | Operational forecast and analysis streamflow | Gridded river network | MSC Datamart / GeoMet, free [S] | — | Forecast system, not a published climatology or long reanalysis [I]. Low value for mean annual/monthly. **Not HYDROGFD:** HydroGFD is SMHI's global forcing dataset, not an ECCC runoff product [I]. |
| — | **BC Water Tool (bcgov/nr-bcwat)** — [repo](https://github.com/bcgov/nr-bcwat) | BC regions (NEWT, KWT, …) | MAD, monthly, FDC per FWA fundamental watershed [S, schema] | FWA funds | Code Apache-2.0 [M]. Data release pending (per plan). | App and ETL; the model fits are not in the repo [M] | **Top priority for parity, lowest independence.** It is the same method, so a disagreement localises a step. |

**Kovacek & Weijs** are not a runoff product. Their recent BC work (EGU26-15888, [abstract](https://meetingorganizer.copernicus.org/EGU26/EGU26-15888.html)) compares FDC prediction on **712 BC catchments** [S] with log-normal parametric, kNN and LSTM methods. It finds the neural network "provided little performance advantage over a simpler nearest-neighbour ensemble" [S]. Code is on [Zenodo 17756086](https://zenodo.org/records/17756086) (CC BY 4.0) [S]. The repo ships a ready gauged-catchment table (§3).

The HESS preprint hess-2024-355 is by other authors and was **withdrawn** [S], so do not cite it.

---

## 3. Gauged basin datasets (polygons + attributes) for validation

| Dataset | BC relevance | Polygons | Attributes / forcing | Licence / access |
|---|---|---|---|---|
| **HYDAT (local)** [M] | **2,324** BC stations. 1,074 have any annual mean Q, 655 have ≥ 10 years, **460 have ≥ 10 years and are never flagged regulated**, 445 of those have a gross drainage area, and 87 are RHBN. | None (areas only) | — | Local `Hydat.sqlite3` |
| **HYSETS** — [Arsenault et al. 2020](https://www.nature.com/articles/s41597-020-00583-2), [OSF rpc3w](https://osf.io/rpc3w) | 14,425 NA basins, including WSC. The BC count was not measured because OSF file listing returned only a wiki folder [M]. | Yes | Physiography, land use, ERA5 / ERA5-Land, Livneh, NRCan gridded, SCDNA, SNODAS; 1950–2018 (the page now says to 2023) [S] | "Free of charge" [S] |
| **Caravan** (HYSETS subset) — [Kratzert et al. 2023](https://www.nature.com/articles/s41597-023-01975-w), [Zenodo csv v1.6](https://zenodo.org/records/15530022) | 4,621 HYSETS basins across NA [S]. The BC count is unknown because the csv tarball is 28.9 GB [M]. | Yes | ERA5-Land forcing, HydroATLAS attributes [S] | CC BY 4.0 [M] |
| **CAMELS-SPAT** — [Knoben et al. 2025, HESS 29:5791](https://hess.copernicus.org/articles/29/5791/2025/), [FRDR](https://www.frdr-dfdr.ca/repo/dataset/fef15147-940a-4a7d-86c3-373ec7d67ec4), [code](https://github.com/CH-Earth/camels_spat) | 1,426 US + Canada basins [S]; BC count not measured | Lumped + semi-distributed (MERIT) | Hourly and daily forcing, 11 geospatial sources [S] | FRDR |
| **BCUB** — [Kovacek & Weijs 2025, ESSD 17:259](https://essd.copernicus.org/articles/17/259/2025/), [data DOI](https://doi.org/10.5683/SP3/JNKZVT), [code](https://github.com/dankovacek/bcub) | 1.2 M **ungauged** BC sub-basins ≥ 1 km² [S] | Yes (own DEM network, **not FWA**) | Terrain, soil, land cover, Daymet climate indices [S] | CC BY 4.0 [S]. **No flow predictions** [S]. |
| **Kovacek gauged table** — [distribution_estimation repo](https://github.com/dankovacek/distribution_estimation/tree/main/docs/notebooks/data) | `catchment_attributes_with_runoff_stats.csv`: **1,017** catchments, 660 with a centroid in the BC bbox. Prefixes 05/07/08/09/10 total 561 Canadian; 12/14/15 are US. `BCUB_watershed_attributes_updated_20250227.csv`: 1,308 [M]. | Updated HYSETS-derived polygons referenced; this table holds centroids only [M] | `q_mean_mm`, record length, BCUB-style attributes, Daymet climate [M] | CC BY 4.0 [S] |

**Practical choice [I]:** delineate validation-station basins ourselves on FWA with fwapg (`FWA_WatershedAtMeasure` / `wet_ws_*`), so the station basin and our accumulation share one topology. Use HYSETS or Kovacek polygons only to QA drainage areas; area mismatches above about 10 % flag bad station snaps. The Kovacek table gives an independent `q_mean_mm` per station to cross-check our HYDAT reduction.

---

## 4. Out-of-sample validation on nested gauges

**The problem [I, reasoning].** Chapman-style models regress gauge residuals on location (UTM E/N) and climate, and the product is accumulated downstream. When an upstream gauge is in training and its downstream partner is held out, the residual surface already "knows" most of the held-out basin. Plain LOO therefore overstates skill, and it does so most for large nested mainstem gauges. Two effects stack: the shared contributing area, and spatial autocorrelation of residuals between neighbours.

**Recommended protocol [I, from the references below]:**
1. **Blocked CV by hydrologic group**, not by station. Hold out all gauges in a block together. A block is an FWA watershed group, or a WSC sub-sub-drainage (e.g. `08LB`; `08L` is a sub-drainage), or a connected nested cluster. This is Roberts et al.'s block/hierarchical CV.
2. **Report skill by nesting class**: headwater (no gauge upstream) vs nested, and by fraction of area gauged upstream. The headwater-only score is the honest "ungauged" number.
3. **Incremental-area check** for nested pairs: (Q_down − Q_up) / (A_down − A_up) against the modelled incremental runoff. It tests the ungauged part directly.
4. **Weight or regress with GLS** so overlapping, cross-correlated basins are not counted as independent (Stedinger & Tasker). For a mean-annual regression, at minimum weight by record length and down-weight nested duplicates.
5. **Match periods.** Compare to a common period (1981–2010 if the climr mosaic is 1981–2010). For short records, adjust to the period with a long-record index station, or restrict to ≥ 10 complete years (655 BC stations, 460 of them unregulated [M]).
6. **Headline metrics:** Chapman's (MAE %, % within ±20 %) for comparability, plus log-ratio bias and spread. For monthly values, NSE/KGE on the 12-month climatology **and** on the monthly *shares*, so annual error does not mask timing error.

**Key references**
- Roberts, D.R. et al. 2017. Cross-validation strategies for data with temporal, spatial, hierarchical, or phylogenetic structure. *Ecography* 40:913–929. [doi:10.1111/ecog.02881](https://nsojournals.onlinelibrary.wiley.com/doi/10.1111/ecog.02881) [S]: random CV "results in serious underestimation of predictive error"; use blocking.
- Parajka, J. et al. 2013. Comparative assessment of predictions in ungauged basins, Part 1. *HESS* 17:1783. [link](https://hess.copernicus.org/articles/17/1783/2013/hess-17-1783-2013.pdf). The PUB-synthesis framing for cross-validated regionalisation. A companion chapter on annual runoff is in Blöschl et al. 2013, *Runoff Prediction in Ungauged Basins* (CUP) [I, not re-read].
- Stedinger, J.R. & Tasker, G.D. 1985. Regional hydrologic analysis 1: OLS, WLS and GLS compared. *WRR* 21(9):1421. doi:10.1029/WR021i009p01421 [I, citation from memory, not re-fetched]. GLS for cross-correlated gauges; the standard for regional regression.
- Arsenault, R. et al. 2023. Continuous streamflow prediction in ungauged basins (LSTM vs hydrological models). *HESS* 27:139. [pdf](https://hess.copernicus.org/articles/27/139/2023/hess-27-139-2023.pdf). A HYSETS-based leave-basin-out comparison; a template for a Canadian PUB benchmark [S title; details I].
- Also: Chapman 2018 and Moore et al. 2012 used plain LOO [S]. To compare with them, report our LOO alongside the blocked score, and state the difference.

---

## Measured after the survey (2026-09-26)

These override the rows above where they conflict.

- **CGIAR Global High-Resolution Soil-Water Balance (figshare 7707605) is CC0.**
  - Read from the figshare API: published 2019-02-12, with files `AET_YR.rar` (0.11 GB), `aet_monthly.rar` (0.46 GB), `swc_fr.rar` and a documentation PDF.
  - Annual and monthly AET are both available.
- **climr 0.2.2** (installed from `bcgov/climr@36edf57`) **does not compute Eref or CMD.**
  - `downscale(vars = "Eref")` and `vars = "CMD"` both print "calculation is not supported yet" and then error.
  - The survey table's Eref and CMD rows describe code the package does not yet run.
- **climr's `refmap_climr` reports its period as `1961_1990`** (`return_refperiod = TRUE`), although the mosaic vignette describes 1981–2010 source climatologies. Label and content disagree.
  - Test point: lon −127.2, lat 54.8, elev 600: MAP 560.5 mm, July PPT 50.7 mm, July Tave 13.9 °C.
- **Getting a 1981–2010 normal from climr's observed series is unresolved.** `obs_years = 1981:2010` alone returned only the reference row; it presumably needs `obs_ts_dataset`, and the helper for listing datasets was not found.
- **ERA5-Land through NGE's `cd` package:**
  - `cd` serves monthly `prcp`, `tmean`/`tmax`/`tmin`, `swe`, `snowmelt`, `snowfall`, `swe_max` and `snowmelt_doy_50` for BC as COGs + STAC.
  - It does **not** yet carry ERA5-Land total evaporation or runoff. Adding them to `cd` would give an ET alternative and a further comparison product.
  - The snow variables are candidate predictors for the monthly shares.

## Open questions (cheap probes)
- climr reference period label: one `downscale()` call after installing climr (not installed yet; installing it changes the machine, so state the plan first).
- Licences to confirm: CGIAR Soil-Water Balance AET (figshare returned 403 here), CGIAR ET0 v3, and AdaptWest/ClimateNA grids.
- BC basin counts in HYSETS, Caravan and CAMELS-SPAT were not measured. HYSETS OSF file listing returned only a wiki folder, and the Caravan csv is 28.9 GB.
