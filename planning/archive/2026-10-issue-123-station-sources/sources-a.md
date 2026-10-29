# Sources A: provincial, UNBC and other BC discharge networks beyond HYDAT (#123)

**Verified:** 2026-10-28 (all [M] measurements taken that day, UTC 21:34 to 21:57) · **Issue:** #123 · **Produced by:** desk research with `curl`, the CKAN, ArcGIS REST, ERDDAP, DataCite, Zenodo and USGS APIs, and read-only queries of the local HYDAT 2026-07-17 copy (`wet:::wet_hydat()` cache). Scratch files were session-temporary and are not kept.

Tags: **[S]** the linked page says it (URL and a short quote); **[M]** measured here (command and result); **[I]** inferred.

## Summary

- **The province's own discharge record is the main non-HYDAT source, and it is bulk-downloadable without login.** The BC Data Catalogue's "Hydrometric data" dataset publishes hourly discharge for every non-integrated station in the provincial Aquarius database as CSV files (OGL-BC 2.0). Across all eight discharge files there are **211 stations, 1998-05-28 to 2026-10-28** [M]; two more stations with discharge appear only in the BC Water Tool (213 total) [M]. None is in HYDAT for its period: provincial IDs (`08NM0002`) look like HYDAT IDs (`08NM002`) with a fourth digit, but the dropped-zero form is a **different HYDAT station** in every case checked, and the 44 provincial stations within 250 m of a HYDAT station all start after that HYDAT record ends [M]. There is no published ID crosswalk; location is the only link [M/I].
- **The records are short and mostly ungraded.** Median 2.6 years of days with data; 43 stations have 5 or more years, 7 have 10 or more [M]. 61 % of rows carry grade `Undefined`, and only some carry a RISC grade (A/B/C/E/U) [M]. No approval field is published [M].
- **UNBC publishes no streamflow.** The Northern Hydrometeorology Group's data-request form lists 68 sites (38 water temperature, 18 weather, 6 tipping bucket, 5 gravel bed, 1 water-level logger) and no discharge [M]; its Zenodo datasets are water temperature and weather [M]. Two UNBC Kiskatinaw stations (2010 to 2012, discharge) are in the BC Water Tool [M].
- **Other networks with BC discharge outside HYDAT:** Hakai Institute (7 stations, CC BY 4.0, ERDDAP, 5-minute discharge with QC flags) [M]; USGS Flathead River at Flathead BC (12355000, to 2026, HYDAT `08NP001` ends 2018) and Bertrand Creek at the boundary (12212390, to 2026, HYDAT `08MH152` ends 2012) [M]; BC Hydro's own discharge at about 7 stations, 4-day window only, not QC'd [M]; and the third-party stations that the BC Water Tool lists (BC Energy Regulator, Geoscience BC, oil and gas industry, EAO, DFO, CRD, Delta, Tofino, Cowichan Valley RD, BC Conservation Foundation, Surrey, Wasa Lake LID) [M]. Most regional and community networks (OBWB and Okanagan Nation Alliance, RDN, BCCF's Vancouver Island community network, Hakai, CRD) publish **through** the provincial Aquarius database rather than separately [S/M].
- **Blocked:** the Aquarius WebPortal sits behind a click-through disclaimer (not accepted here; the harness refused the POST) [M]; the Columbia Basin Water Hub data host (CanWIN) sits behind an Anubis proof-of-work bot wall [M]; the NHG data are by request form [M]; Pacific DataStream's API needs a key requested by form [S].

## 1. Province of British Columbia

### 1.1 Provincial Hydrology Program and the network split

- [S] <https://www2.gov.bc.ca/gov/content/environment/air-land-water/water/water-science-data/water-data-tools/provincial-hydrology-program>: the program "manages the collection, review, publication and standards and training of provincial surface water quantity data". Hydrometric data are "stage (calibrated water level height) and discharge (volume of flow) as the core parameters."
- [S] Two kinds of station. **Integrated** (Canada–BC Hydrometric Program, CBCHP): <https://www2.gov.bc.ca/gov/content/environment/air-land-water/water/water-science-data/water-data-tools/provincial-hydrology-program/canada-british-columbia-hydrometric-program>, "the formal network of hydrometric stations co-managed by the Province of British Columbia and the Federal Government ... over 460 stations", "Approved final data for all stations is available from the National Water Data Archive as a downloadable database (HYDAT)". **Non-integrated**: <https://www2.gov.bc.ca/gov/content/environment/air-land-water/water/water-science-data/water-data-tools/provincial-hydrology-program/non-integrated-hydrometric-data>, "data from monitoring sites outside of the Canada-British Columbia Program ... produced by hydrometric stations operated by provincial staff or third-parties", "captured by the Aquarius Time Series Database and distributed through the Real-time Water Data website."
- [M] HYDAT 2026-07-17 has 466 BC stations with `HYD_STATUS = 'A'` (458 operated by WSC, 4 by BC Hydro, 2 by Alcan, 1 West Kootenay Power, 1 USGS), and 2,048 BC stations with any daily flow (`sqlite3` read-only on `Hydat.sqlite3`, `STATIONS` joined to `AGENCY_LIST` and `DLY_FLOWS`). [I] So "over 460 stations" in the CBCHP is the active HYDAT BC set: cost-shared means in HYDAT.
- [S] The agreement itself: Canada–B.C. Agreement on Hydrometric Monitoring (2013), full text at <https://www.bclaws.gov.bc.ca/civix/document/id/oic/arc_oic/0047_2013> (linked from the "About the agreement" page). Not read here (10.5 MB PDF); it does not list stations [I].
- [S] Third parties: "Third-party data includes measurements made by First Nations, stewardship groups, industry, consultants, municipalities and others ... a standard data sharing agreement signed by the data owner is required ... you will be provided a provincial station ID" (non-integrated page). FAQ <https://www2.gov.bc.ca/gov/content/environment/air-land-water/water/water-science-data/water-data-tools/real-time-water-data-reporting/water-data-submission/water-sharing-data-licence-and-agreement>: "The ID will be assigned provincially as per the Water Survey of Canada sub-basins"; "hourly data is the highest resolution being processed".
- [S] Provincial Hydrometric Network (the province's own stations): <https://www2.gov.bc.ca/gov/content/environment/air-land-water/water/water-science-data/water-data-tools/provincial-hydrology-program/non-integrated-hydrometric-data/provincial-hydrometric-network>, "Data is reviewed and published according to provincial RISC standards on an approximately bi-annual basis." Its data link is an Aquarius dashboard, `https://bcmoe-prod.aquaticinformatics.net/Data/Dashboard/142` (behind the disclaimer, 1.2).

### 1.2 Real-time Water Data Tool (Aquarius WebPortal)

- **Asset:** <https://aqrt.nrs.gov.bc.ca/> redirects to <https://bcmoe-prod.aquaticinformatics.net/Disclaimer> [M: `curl -sL` returned HTTP 200 at that URL]. [S] <https://www2.gov.bc.ca/gov/content/environment/air-land-water/water/water-science-data/water-data-tools/real-time-water-data-reporting>: "the province's primary repository of continuous surface, groundwater and snow data"; users can "Download data in various formats".
- **Blocked:** [M] every data URL (`/Data/Dashboard/142`, `/Data/DataSet/Summary/Location/08HA0022/...`) answers 302 to `/Disclaimer?returnUrl=...`. Accepting is a POST to `/AcceptDisclaimer`; the harness refused that request here, so nothing behind the disclaimer was read. The portal also offers an account sign-in; none was used. A maintenance window is set in the page: `window.maintenanceTimeFrame = "2026-10-29 23:00:00,2026-10-30 05:00:00"` [M].
- **Discharge and rating:** [S] Quick Start Guide <https://bcmoe-prod.aquaticinformatics.net/Data/GetFile/GettingStartedGuide> (public PDF, ver. 2020.3, June 2021): "The river stage is related to discharge but not equivalent and more information (i.e. a ratings curve) is required to calculate discharge from river stage." The province maintains ratings for its own stations and helps third parties: the program publishes the Hydrometric Rating Application (HydRA) [S, resources page], and for the Vancouver Island community network "Ministry staff help with ... developing rating curves, and giving final approval" [S via search snippet of waterbucket.ca; the BCCF slide deck below says the same in outline].
- **QA:** [S] Guide: "The Grid View allows you to view the data in a tabular format with the grade and approval level showing." So the portal carries approval levels; the bulk CSVs (1.3) do not. Grades follow the RISC manual, <https://www2.gov.bc.ca/assets/gov/environment/natural-resource-stewardship/nr-laws-policy/risc/man_bc_hydrometric_stand_v2.pdf> (December 2018): A/RS, A, B, C, BP ("Best Practice"), E ("Estimated ... instrument anomalies, shift correction, missing data, or rating-curve extrapolation"), U ("data of an unknown quality that cannot be assigned to a standard grade").
- **Licence:** [S] catalogue record `real-time-water-data`: licence field "Access Only", but its description says "export data, create & view charts & reports under the Open Government Licence - British Columbia." Disclaimer text: "The Government of British Columbia accepts no liability for the accuracy ... of the data".
- **Access:** web UI exports (CSV, Excel, PDF) per the guide [S]. AQUARIUS WebPortal products usually expose export URLs, but none was tested past the disclaimer [I].

### 1.3 BC Data Catalogue "Hydrometric data": bulk CSV of all non-integrated stations

- **Asset:** <https://catalogue.data.gov.bc.ca/dataset/hydrometric_data> (CKAN id `9d9daae1-b379-4c92-b96d-6a81455caa74`), files in the open directory <https://www.env.gov.bc.ca/wsd/data_searches/water/> [M: Apache index, listed 2026-10-28]. Same directory also holds `Stage*.csv`, `WaterTemperature*.csv`, groundwater, snow and weather files.
- **Licence:** [S] CKAN `package_show`: "Open Government Licence - British Columbia 2" (`OGL-BC-2.0`): redistribution allowed with attribution [I from the licence's standard terms]. Data-quality statement: "collected from various sources and may contain omissions, errors etc." Purpose: "The Province collects this automated and continuous data from a number of sources including federal, provincial, regional and municipal governments as well as non-government organi[zations]".
- **Discharge:** yes, `Parameter = Discharge`, `m^3/s`, hourly, UTC [M]. Header: `Location ID, Location Name, Status, Latitude, Longitude, Date/Time(UTC), Parameter, Value, Unit, Grade` [M]. Rating curves stand behind it at stations run to RISC standards [S, 1.2]; which ones is not in the file [M].
- **Files** [M: `curl -sI` and the directory index; sizes as served]:

  | File | Covers | Size | Rows | Stations |
  |---|---|---|---|---|
  | `Discharge.csv` | current water year (from 2026-10-01) | 4.2 MB | 34,535 | 57 |
  | `Discharge_Archive_Post_20251001.csv` | 2025-10-01 on | 68 MB | 561,733 | 80 |
  | `Discharge_Archive_2023Oct_2025Oct.csv` | WY 2024–2025 | 150 MB | 1,238,512 | 93 |
  | `Discharge_Archive_2021Oct_2023Oct.csv` | WY 2022–2023 | 145 MB | 1,186,240 | 96 |
  | `Discharge_Archive_2019Oct_2021Oct.csv` | WY 2020–2021 | 102 MB | 832,857 | 77 |
  | `Discharge_Archive_2017Oct_2019Oct.csv` | WY 2018–2019 | 114 MB | 933,457 | 109 |
  | `Discharge_Archive_2015Oct_2017Oct.csv` | WY 2016–2017 | 98 MB | 780,328 | 84 |
  | `Discharge_Archive_Pre_20151001.csv` | to 2015-09-30 | 57 MB | 454,602 | 30 |

  Dead links in the catalogue [M]: the resources "Discharge Archive 20231001 to 20250930" and "Stage Archive 20231001 to 20250930" point to `Discharge_Archive_Post_20231001.csv` and `Stage_Archive_Post_20231001.csv`, which answer 404; the live files are `Discharge_Archive_2023Oct_2025Oct.csv` and `Stage_Archive_2023Oct_2025Oct.csv`, and `Discharge_Archive_Post_20251001.csv` is not in the catalogue at all.
- **Inventory** [M: `scratchpad/scripts/inv.py` over all eight files]: **211 stations**; first value 1998-05-28 (`1AHA040`, Ayum Creek), last 2026-10-28. `Status`: 149 Active, 62 Inactive, but only 58 reported in the 30 days before 2026-10-28. Days with data per station: under 1 year 35, 1–3 years 80, 3–5 years 53, 5–10 years 36, 10 years or more 7 (`08LC0001` Duteau, `08MG0001` Lillooet at FSR, `08MG0002` Fitzsimmons, `08NH0001` Five Mile, `08NM0002` Equesis, `08NM0005` and `08NM0032` Vernon Creek); median 2.6 years. By sub-drainage prefix: `08NM` (Okanagan) 54, `08MH` (Lower Fraser) 31, `08HB` 27, `08HA` 20 (Vancouver Island), `08NK` (Elk) 14, `08LG` (Nicola) 10, others fewer. ID patterns: 206 `99AA9999`, 3 `H08KC####` (Hakai), 2 `1AHA0##` (CRD-era Goldstream and Ayum, 1998–2003).
- **QA in the CSV** [M]: grade shares over all rows: `Undefined` 60.9 %, `Unspecified` 8.2 %, `Very Good` 7.2 %, `Good` 6.9 %, `RISC C` 4.4 %, `Estimated` 3.4 %, `RISC U` 2.4 %, `RISC A` 1.8 %, `Excellent` 1.5 %, `RISC B` 1.2 %, `RISC E` 1.1 %, `Unusable` 0.5 %, then `Poor`, `EXCELLENT - RATED STRUCTURE`, `Best Practice`, `Unverified`. Two vocabularies coexist (older Excellent/Very Good/Good/Poor/Unusable, newer RISC letters). `Undefined`+`Unspecified` falls from 87 % in the current-year file to 60–75 % in the archives [M], consistent with grading after review [I]. There is no approved/provisional field [M]; values may be revised when a water year is re-exported (`Discharge_Archive_2021Oct_2023Oct.csv` was rewritten 2026-09-22) [M/I].
- **Owners** [I from station names]: Hakai Institute (`H08KC*`), City of Surrey (names "- City of Surrey"), Teck's Elk Valley mine sites (`(EV_EC1)`, `(LC_LC2)`, `(FR_HC1)`, `(CM_CC1)`, `(GH_GH1)`), Nicola and Louis Creek stewardship codes (`CLP2`, `UNR1`, `LOU1`, `MCG1`), A Rocha (`08MH0041`), Treaty 8 First Nations sites (`07FC0001`, `07FA0001`, `10CD0001`), Okanagan EFN sites (1.5, OBWB). The CSV has no owner field [M].

### 1.4 How many are not in HYDAT, and the ID crosswalk

[M] `scratchpad/scripts/xwalk.py` against HYDAT 2026-07-17 (read-only):

- **Identifier:** of 206 IDs shaped `99AA0999`, 175 drop to an existing HYDAT ID when the fourth digit (a zero) is removed, but the names never agree (for example `08NM0002` Equesis Creek near the Mouth vs HYDAT `08NM002` Okanagan River at Okanagan Falls; `08HA0045` Goldstream River vs `08HA045` Koksilah River). The provincial number is its own sequence within the WSC sub-sub-drainage [S, FAQ: "assigned provincially as per the Water Survey of Canada sub-basins"]. **No published crosswalk** was found [M].
- **Location:** nearest HYDAT station within 0.1 km: 16; 0.25 km: 44; 0.5 km: 53; 1 km: 82. For all 44 within 0.25 km, the HYDAT station's daily flow ends before the provincial record starts (for example `08LG0015` 2021– at HYDAT `08LG004` 1911–2018; `08NH0001` "Five Mile Creek at WSC Station 08NJ168" 2016– at `08NJ168` 1983–2015; `08NM0003` 2017– at `08NM246` 2006–2010). So **all 211 records are outside HYDAT for their periods**, and about 44 extend a discontinued HYDAT record at the same site [M/I].
- **Not in the CSVs but in the portal:** the BC Water Tool (1.6) lists 271 BC ENV station IDs with data years; 193 are in the CSVs, and of the other 78, 75 have only `Primary Water Level` and 2 have discharge (`08MH0061` Waechter Creek, `H08KC1015` Hakai 1015) [M: BC Water Tool CSV endpoint per station]. Total provincial discharge stations found: **213**.

### 1.5 Other provincial assets

| Asset | What it is | Tag and evidence |
|---|---|---|
| Hydrometric Stations - Active and Discontinued, <https://catalogue.data.gov.bc.ca/dataset/hydrometric-stations-active-and-discontinued>, WFS `pub:WHSE_ENVIRONMENTAL_MONITORING.ENVCAN_HYDROMETRIC_STN_SP` | WSC (HYDAT) stations only, 2,317 features, OGL-BC 2.0 | [S] "part of the provincial hydrometric network managed under a national program jointly administered under a federal-provincial cost-sharing agreement"; [M] `resultType=hits` 2,317, IDs `STATION_NUMBER` like `07FA003` |
| River Forecast Centre "Current Streamflow Conditions", ArcGIS `StationInformation` layer (from <https://bcrfc.env.gov.bc.ca/freshet/map_all_wsc.html>) | 522 real-time stations: WSC, 7 provincial (pseudo-IDs such as `08MG00A` named "(BC 08MG0001)"), 11 USGS (`124015U` "(USGS 12401500)"), WSC auxiliary `X` gauges | [M] query returned 522; licence "Access Only" on the catalogue records `current-streamflow-conditions-data`, `7-day-streamflow-data` [S]. This is a crosswalk for 7 provincial and 11 USGS stations [M] |
| Drought portal layers: "Drought Portal Aquarius and USGS Station Discharge" (18 stations) and "West Coast Water Authorizations Station Discharge" (5) | Daily min/mean/max of selected Aquarius and USGS stations | [M] feature counts; [S] catalogue `west-coast-water-authorizations-station-discharge`: "collects records of discharge during the drought season and stops collecting during high precipitation seasons"; licence "Access Only" |
| B.C. Streamflow Inventory (`BC_Streamflow_Inventory_Hydrometric_Station_View`) and Regional Flood Frequency Analysis station CSV | Statistics for WSC and 5 USGS stations | [M] 467 rows, IDs `99AA999` (462) and 8-digit (5); [S] inventory page: "The standard discharge data used are published by the Water Survey of Canada". Not a non-HYDAT source |
| EnMoDS (Environmental Monitoring Data System) | Discrete water-quality sampling; replaced EMS on 2026-03-05 | [S] catalogue `bc-environmental-monitoring-locations`. May hold spot flow measurements; not checked [I] |
| South Coast / West Coast water authorizations stations | Drought-season stations of the regional water authorizations office (`08HA0022`, `08HA0023`, `08HA0037`, `08HA0038`, `08HB0037`), in Aquarius | [M] ArcGIS layer; [S] more-info link points to Aquarius `08HA0022` |

### 1.6 BC Water Tool (Foundry Spatial) and the BC Energy Regulator water portal

- **Asset:** <https://nr-bcwat.bcwatertool.ca/> ("BC Water Tool (Consolidated)", combining the Omineca, Skeena, Cariboo and Kootenay-Boundary tools) [S, <https://www.bcwatertool.ca/>]; and <https://water.bc-er.ca/> (NEWT and the BC Energy Regulator water portal), same software ("Powered by Foundry Spatial") [S/M].
- **Access:** an unauthenticated JSON API [M: `curl` returned HTTP 200, `application/json`]. Station list: `https://nr-bcwat.bcwatertool.ca/api/streamflow/stations` (GeoJSON, 3.3 MB, 9,427 features, properties `id, nid, name, net, status, ty, yr, area, hasStage, hasSevenDay`). Per station: `/api/streamflow/stations/{id}/csv` and `/report`. The BCER copy `https://water.bc-er.ca/api/streamflow/stations` returns 94 northeast stations [M].
- **Content** [M]: 9,427 rows but 287 unique BC ENV IDs (the `HRB*` rows repeat; 6,721 rows are "Active, Real-time, Not responding" with no years). By network, unique IDs with data years: Water Survey of Canada 2,341; BC ENV Real-time Water Data Reporting 271; "Regulator – BC Oil and Gas Commission" 28; BC Hydro 20; DFO 14; Capital Regional District 12; Oil and Gas Industry Network 10; Geoscience BC 8; BC EAO 7; Delta 6; Tofino 4; BC Conservation Foundation (Vancouver Island) 4; Cowichan Valley RD 3; UNBC 2; Surrey SCADA 2; Wasa Lake Land Improvement District 1. 210 of the 211 CSV stations are in it (missing `08LG0020`).
- **Discharge vs stage:** the per-station CSV separates `Preliminary Discharge` (daily) from `Primary Water Level` [M, `08EE0001`]. Third-party networks with discharge (from `hasStage` and names; not checked per station): BCER/OGC, Oil and Gas Industry Network, Geoscience BC (Montney, 2012–2016), EAO (KSM/Brucejack baseline, 2007–2012), UNBC (Kiskatinaw, 2010–2012), Wasa Lake LID (1996–2017) [M list; I for discharge at each].
- **Labels to distrust** [M/I]: the BC Water Tool files many 2025–2026 Okanagan and Lower Mainland provincial stations (`08NM0073`, `08LC0006`, `08MH0062`) under "Regulator – BC Oil and Gas Commission", which they are not by name or location; take the owner from the province, not this field.
- **QA:** CSV header `# QA,"1 - Quality Checked, 0 - Unchecked Quality"`, and the discharge series is called "Preliminary" [M].
- **Licence:** [M] CSV header: "Data from BC ENV - Real-time Water Data Reporting has been acquired from Ministry of Environment ... and DataBC (https://www.env.gov.bc.ca/wsd/data_searches/water/)", with a no-liability clause; report JSON `licence_link` is the OGL-BC page. Licences of the third-party series (BC Hydro, DFO, industry) are not stated in what was read [M]. [I] The provincial series are a copy of 1.3; the tool's value is the third-party stations and a single station list.

## 2. UNBC

| Asset | Discharge? | Access | Tag |
|---|---|---|---|
| Northern Hydrometeorology Group site, <https://web.unbc.ca/~sdery/> | No discharge found. "network of 18 active weather stations" | Web | [S] |
| NHG data request form, <https://nhgdatareq.unbc.ca/> (site list in `https://nhgdatareq.unbc.ca/script.js`) | 68 sites: 38 water temperature (`01FW001` ... Nechako, `01MF00x` Horsefly and McKinley), 18 weather, 6 tipping bucket, 5 gravel bed, 1 water-level logger (`05NE001` Rhine Creek); **no discharge** | **By request form** (not submitted) | [M] parsed `script.js` |
| Zenodo 10.5281/zenodo.15053907 | No: sub-hourly water temperature, 32 Nechako sites, CC BY 4.0 | Download | [M] Zenodo API |
| Zenodo 10.5281/zenodo.16097586 (and 18961694, 46 sites) | No: modelled water temperature. Calibrated "with observed streamflow and water temperature data from the Water Survey of Canada (WSC), Rio Tinto, and UNBC" | Download | [S] record text |
| CAMnet, 10.5281/zenodo.1195042 | No: 11 meteorological stations | Download, CC BY 4.0 | [M] |
| UNBC Kiskatinaw stations `ogc_1001` West Kiskatinaw Confluence, `ogc_1003` East Kiskatinaw Confluence | Yes, 2010–2012, "Collected for academic research project" | BC Water Tool API (1.6) | [M] |
| Quesnel River Research Centre, <https://www.unbc.ca/quesnel-river-research-centre/introduction> | No station list or data page found; the NHG sites near Likely are weather and temperature | Web | [M] web search; [I] |
| Integrated Watershed Research Group, Nechako Phase 4 (announced 2026-09-23 on the NHG page) | "will collect baseline data before the construction of the NeToo Hydropower Project"; parameters not stated | Not yet published | [S] |
| DataCite search for UNBC streamflow datasets | `api.datacite.org/dois?query=(streamflow OR discharge OR hydrometric) AND "University of Northern British Columbia"` returned **0** | — | [M] |
| FRDR | `frdr-dfdr.ca/repo/discover` answers 404 / a JavaScript wait page to `curl`; not searched | **Blocked** for scripted search | [M] |

[I] UNBC is a water-temperature and weather source, not a discharge one; its only discharge found is two short Kiskatinaw records.

## 3. Also found

### 3.1 Hakai Institute, Kwakshua Watersheds Observatory (Calvert and Hecate islands)

- **Assets** (catalogue <https://catalogue.hakai.org/>, CKAN): "Watersheds Stream Stations Timeseries ... (Research)" doi 10.21966/47m7-ev69; "(Provisional)" doi 10.21966/c6xs-y324; "High-resolution hydrometeorological data from seven small coastal watersheds ... 2013-2019" doi 10.21966/J99C-9C14 (ESSD data package, GitHub `HakaiInstitute/essd2021-hydromet-datapackage`); older "Observed stream flow from seven small coastal watersheds" and "Stage-Discharge Time Series - Calvert Island - Archived" [M: CKAN `package_search`, 8 hits].
- **Discharge and rating:** [S] Research record: "Discharge is derived from stage-discharge rating curves, with gaugings collected by the autosalt dilution method"; rating and editing code are public (`HakaiInstitute/RatingCurve`, `HakaiInstitute/Discharge-editing`). Hakai maintains the ratings [S].
- **QA:** [S] Research: "data from reviewed rating periods with a confirmed (non-provisional) rating, assigned a quality level of 2 or greater ... 'AV' (Accepted Value), 'EV' (Estimated Value) ... 'SVC' (Suspicious Value Caution)"; Provisional: "the full unreviewed record". [M] values carry `discharge_rate_ql` (2) and `discharge_rate_qc` (`AV: QC'd by EH`).
- **Licence:** CC BY 4.0 [S, CKAN and ERDDAP `license` attribute].
- **Access:** ERDDAP, machine-readable [M]. Station list: `https://catalogue.hakai.org/erddap/tabledap/HakaiWatershedsStreamStationsResearch.csv?station,station_id,station_description,latitude,longitude,elevation&distinct()`.
- **Stations and periods** [M: `orderByMinMax("station_id,time")` where `discharge_rate!=NaN`]: 7 stations, 5-minute data. Research grade: `H08KC0626` 2014-08-02 to 2024-08-19, `H08KC0693` 2014–2020, `H08KC0703` 2014–2022, `H08KC0708` 2013-09-08 to 2020-06-15, `H08KC0819` 2014–2019, `H08KC0844` 2014–2022, `H08KC1015` 2014–2021. Provisional runs to 2026-10-28 at 0626, 0703, 0844 and to 2025-09-05 at 1015. [S] "Watersheds 708, 819, and 693 were decommissioned in 2020".
- **HYDAT and crosswalk:** none in HYDAT [I: no HYDAT station shares these IDs or sites; the provincial CSV carries them]. Hakai's `station_id` equals the provincial Aquarius ID (`H08KC0626`), so the two join directly [M]. The provincial copy starts 2021-10-01 and is graded `RISC U` [M], so Hakai's ERDDAP is the better copy (longer, 5-minute, QC flags).

### 3.2 BC Hydro

- **Asset:** <https://www.bchydro.com/energy-in-bc/operations/transmission-reservoir-data/hydrometeorologic-data.html>. [S] "a network of more than 200 automated stations ... The data posted here includes up to four days of historic data. The data is based on automated readings and is not quality-controlled".
- **Station list and data:** the page's HTML table, 220 stations with per-station text files `https://www.bchydro.com/info/res_hydromet/data/<code>.txt` (fixed-width text, 5-minute, PST) [M]. 113 rows carry a WSC ID, 42 a BC snow ID, 65 neither [M]. File headers name the operator: 110 "ECCC Water Survey of Canada", 108 "BC Hydro Hydrometeorological Monitoring Program", 1 USGS [M].
- **Discharge:** 93 files have a Discharge column; of BC Hydro-operated stations only 7 do (`blc` Boulder Ck above the Diversion, `bdi` Boulder Ck Diversion, `trz` Bridge R below Terzaghi Dam, `cad` Cayoosh Ck Diversion, `cdi`, `jca` Jones Ck above Laidlaw Rd, `nal`); the rest are water level, reservoir elevation and climate [M].
- **QA, licence:** not QC'd, "for information only" [S]; no licence or redistribution terms stated [M].
- **Period:** 4 days only [S]; no BC Hydro archive is public [I]. The BC Water Tool holds 20 BC Hydro station records for 2019–2020 only [M], and cites "BC Hydro. Lower Mainland/Interior Hydrometric Data" and "Vancouver Island Hydrometric Data" [S via search snippets; the citation pages answered 404 to `curl`].
- **HYDAT:** HYDAT lists 4 active BC stations operated by BC Hydro [M]; many BC Hydro-funded WSC stations are in HYDAT [I]. The `X` IDs in BC Hydro's list (`08MHX05`, `08HDX35`) are WSC auxiliary gauges [S, RFC layer names "(AUXILIARY GAUGE)"].

### 3.3 USGS gauges inside BC

- **Asset:** USGS Water Data OGC API, `https://api.waterdata.usgs.gov/ogcapi/v0/collections/monitoring-locations/items?f=json&country_code=CA&limit=500` [M: 468 Canadian sites, 234 in BC: 87 streams, 130 wells, 12 lakes]. Discharge series from `https://waterservices.usgs.gov/nwis/site/?format=rdb&sites=<list>&seriesCatalogOutput=true&parameterCd=00060` [M].
- **Daily discharge (`00060`, `dv`) at BC sites** [M], against the nearest HYDAT station [M]:

  | USGS site | Name | USGS period | Nearest HYDAT (km) | HYDAT flow years | Not in HYDAT |
  |---|---|---|---|---|---|
  | 12355000 | Flathead River at Flathead BC | 1929-04-01 to 2026-10-27 | `08NP001` (0.0) | 1929–2018 | **2019–2026** |
  | 12212390 | Bertrand Creek at International Boundary | 2007-05-04 to 2026-10-27 | `08MH152` (0.02) | 1984–2012 | **2013–2026** |
  | 12300000 | Kootenay River at Newgate | 1930–1972 | `08NG042` (0.13) | 1930–1972 | none |
  | 12323000 | Columbia River at Birchbank | 1982–2022 | `08NE049` (0.02) | 1937–2025 | none |
  | 12438700 | Okanagan River near Oliver | 1961–2022 | `08NM085` (0.13) | 1944–2025 | none |
  | 11 `CAX01` sites (Stikine, Iskut, Unuk, Tuya, Tanzilla, More, Forrest Kerr) | copies of WSC records | 1954–1999 | same sites (0.05–0.6) | same years | none |

- **QA:** USGS approval codes (A approved, P provisional) on each value [I, standard USGS practice; not read here]. **Licence:** US federal public domain [I]. The other ~70 BC "stream" sites are water-quality points (Elk River, Flathead, Lake Koocanusa) without discharge [M].

### 3.4 Capital Regional District (CRD)

- [M] 12 CRD stations in the BC Water Tool with data years, `HRB*` IDs (Colwood Creek 2012–2026, Colquitz Creek, Cecelia Creek, Millstream Creek, Bowker Creek, Hospital Creek, Florence and Langford lakes...), mostly stage plus discharge. `1AHA040`/`1AHA045` (Ayum Creek, Goldstream, 1998–2003) are in the provincial CSV [M].
- [S via search snippet] an ECCC/MSC partner metadata record (<https://donnees.iriu.ca/dataset/0f332c2e-22de-4e48-afc0-11ffc4f3f480>) describes the CRD network with "22 hydrometric stations", real-time for 15 and "Manual data feed for 18 Hydrometric stations", published through ECCC's partner feed and PCIC's met data portal. Not read directly.
- No CRD station list endpoint of its own found [M].

### 3.5 Metro Vancouver

- No public hydrometric station list or flow data found [M: ArcGIS Online search `(hydrometric OR streamflow OR "stream flow") AND "Metro Vancouver"` returned 0; one web search found none]. Water-supply watershed gauges (Capilano, Seymour, Coquitlam) are in HYDAT where they exist [I]. Recorded as **not found**, not as absent.

### 3.6 Okanagan Basin Water Board (OBWB) and Okanagan Nation Alliance (ONA)

- [S] <https://www.obwb.ca/hydromet/>: "there now exists an informal ad hoc network of 75 stations operated by a range of third-parties. Data derived from this informal network is not coordinated into a single database". [S] <https://obwb.ca/hydrometrics/>: "Only 15 of the 79 drainages in the Okanagan Basin are now being monitored by the Water Survey of Canada." Grant projects listed (District of Peachland, Westbank ID, BMID, Greater Vernon Water, City of Penticton, ONA EFN framework).
- [S] CWRA 2025 abstract (<https://cwra2025.sched.com/speaker/gwang10>): "Since 2020, the Okanagan Nation Alliance (ONA) and Okanagan Basin Water Board (OBWB) have jointly led and managed efforts to expand and modernize the network ... Data collected and reviewed adheres to BC provincial and WSC standards and is made publicly accessible through the provincial web portal."
- [M/I] So the 54 `08NM00xx` stations in the provincial CSV are mostly this network (Peachland `08NM0054`, Trepanier `08NM0053`, Powers `08NM0052`, Mission Creek sites). A separate ArcGIS layer `HydrometricStns_Okanagan` (owner JuanCReyes1) and an IJC Osoyoos dashboard exist [M: ArcGIS search]; not read.

### 3.7 Columbia Basin Trust, Living Lakes Canada and the Columbia Basin Water Hub

- [S via search snippet] Living Lakes Canada's Columbia Basin Water Monitoring Framework: "26 hydrometric stations, eight lake level stations and three climate stations" in the North Kootenay Lake/Slocan, Columbia Valley and Elk Valley pilot areas; data in the Columbia Basin Water Hub, "over 400 datasets ... from over 50 contributors". Station records such as Upper Wilson Creek (`MCKWIL01H`), Summit Creek (`LCKSUM01H`), Ben Hur Creek (`MCKBEN01H`), Dunbar Creek (`CKHDUN01H`) list discharge and water temperature with a DOI. [S, ourlivingwaters.ca/open_access_water_data]: the Hub is "a central repository for water-related data relevant to the region", facilitated by Living Lakes Canada.
- **Blocked:** the dataset pages are hosted at `canwin-datahub.ad.umanitoba.ca/data/...` (CKAN), which returns an Anubis proof-of-work page ("Making sure you're not a bot!") to `curl` and "Access Denied" to WebFetch [M]; the CKAN API returned the same page [M]. `columbiabasinwaterhub.ca` and `data.columbiabasinwaterhub.ca` did not resolve [M: curl status 000]. Not circumvented. Station count, periods, QA and licence are therefore unverified; [I] CKAN dataset metadata would give them to a browser.
- [I] Columbia Basin Trust funds this work; no CBT-operated network was found.

### 3.8 Pacific Salmon Foundation, BC Conservation Foundation and community flow networks

- [S] <https://psf.ca/freshwater-monitoring-protocols/>: protocols for water level and discharge monitoring that "support data contributions to PSF's Stream Temperature Database and PSF's Pacific Salmon Explorer (PSE), consolidating stream temperature and flow records from over 1,500 monitoring sites". No flow download endpoint found [M: `data.salmonwatersheds.ca/api/3/...` answered 404]. [S via search snippet] PSE's stream-flow indicator pages quote WSC stations (Fraser River at Hope); [I] PSE flow is WSC-derived, not a new network.
- [S] BCCF slide deck (RDN, July 2023, `.../BC Conservation Foundation Hydrometrics for CWMN July 12, 2023_reduced.pdf`): the Community Flow Monitoring Network – Vancouver Island (CFMN-VI) is "delivered through a partnership with the British Columbia Conservation Foundation (BCCF) and the BC Ministry of Environment", with "Support to share data directly with the Province of BC & house data on their central hydrometric database - AQUARIUS". [M/I] its stations (Beach Creek `08HB0031`, Grandon Creek `08HB0011`) are in the provincial CSV with Good/Excellent grades. Four older BCCF stations (2012–2015) are in the BC Water Tool [M].
- Fraser Basin Council: no hydrometric network or data found [M: one web search].

### 3.9 Regional District of Nanaimo (RDN)

- [S] <https://rdn.bc.ca/hydrometric-and-climate-monitoring>: priority stations French Creek (2018), Nanoose Creek (2017), Haslam Creek (2016), "Streamflow, Level, Temperature", partners "DFO, MFLNR, RDN". Links go to the provincial Aquarius (`08HB0010`) and to DFO's VI Hydromets. [M] French Creek `08HB0021` and Haslam Creek `08HB0007` are in the provincial CSV; VI Hydromets status page says both "Site taken over by provincial program" (2024-05-09).

### 3.10 DFO "VI Hydromets" (PACFish)

- [M] <http://www.pacfish.ca/wcviweather/>: about 25 Vancouver Island salmon-river stations with partners (Nuu-chah-nulth/Maa-nulth, 'Namgis, Hupacasath, A-Tlegay, West Coast Aquatic, Western Forest Products, BC Forests, RDN). Pages show water level, water temperature, rain and air temperature; no discharge found on the Stamp River page [M]. [S] "This data should be assumed to be a general guideline, but not scientifically accurate." No download or licence [M]. The BC Water Tool holds 14 DFO "Hobo" stage records, 2013–2017 [M]. **Stage only.**

### 3.11 BC Energy Regulator and Treaty 8 First Nations

- [S] <https://www.bc-er.ca/stories/commission-and-treaty-8-first-nations-install-hydrometric-stations-in-area-streams/>: stations with Prophet River, Saulteau and Doig River First Nations, funded by BC OGRIS, "to establish a stage-discharge relationship". [M] in the provincial CSV as `10CD0001` Martin Creek, `07FA0001` Le Bleu Creek, `07FC0001` Osborn River (2021–2026, `RISC E`), and further BCER stations (`07FC0002` Upper Aitken Creek, `07FA0003`, `07FC0003`, `07FC0004`, `10CD0002`) in the BC Water Tool [M]. Data through the province and the BCER water portal (1.6).

### 3.12 Industry and assessment baselines

- [M] BC Water Tool: "Oil and Gas Industry Network" 10 stations (Nexen Tsea River, Quicksilver Emile Creek and Petitot, Progress Cameron River, Black Swan, 2009–2025); Geoscience BC 8 (northeast Montney, 2012–2016, plus `HRB5454` 2025); BC EAO 7 (Unuk/Sulphurets/Bowser baselines, 2007–2012). [I] Teck's Elk Valley sites are in the provincial CSV (1.3). Mine and EA baselines elsewhere sit in consultants' reports (for example Rescan's eight stations, 2006, in the BC Water Tool's literature catalogue [S via search snippet]), not machine-readable.

### 3.13 Municipal and local

- [M] BC Water Tool: Delta 6 stations (2015–2023), Surrey SCADA 2 (2001–2018), Tofino 4 (Meares Island, 2013–2016, also in the provincial CSV as `08HC000x`), Cowichan Valley RD 3 (2015–2017), Wasa Lake LID 1 (1996–2017). City of Surrey creek stations in the provincial CSV ("- City of Surrey", 2014–2023) [M].

### 3.14 Leads not verified

- **Rio Tinto** (Nechako Reservoir, Skins Lake Spillway): flows are reported publicly in season [S via search snippet, 2015 news: "data reported online by Rio Tinto"]; current page not found. Kenney Dam releases are measured at WSC `08JA017` in HYDAT [I].
- **Pacific DataStream** (<https://datastream.org>): community water data; API "Requires an API key — free, on request" via a Google form [S, <https://github.com/datastreamapp/api-docs>]; unauthenticated call returned HTTP 400 [M]. **Blocked** without a key. Mostly water quality [I].
- **UBC research watersheds**: DataCite lists "Long-term observation dataset of sediment dynamics and bed stability in East Creek" (figshare 10.6084/m9.figshare.19735849, Malcolm Knapp Research Forest) [M]; whether it carries discharge was not checked.
- **USGS Kootenay selenium study**: "Streamflow and total selenium concentration data for six Canadian sites in the Kootenay and Columbia River Basins" (10.5066/p13btvbb) [M: DataCite]; not read.

## Station-list endpoints

Every URL below returned a machine-readable station list on 2026-10-28 [M], without login.

| URL | Format | Fields | Rows | Notes |
|---|---|---|---|---|
| `https://www.env.gov.bc.ca/wsd/data_searches/water/Discharge.csv` and the seven `Discharge_Archive_*.csv` files in the same directory | CSV, one row per station-hour | `Location ID, Location Name, Status, Latitude, Longitude, Date/Time(UTC), Parameter, Value, Unit, Grade` | 211 distinct stations across all files | The list is the distinct IDs; no separate station file. OGL-BC 2.0 |
| `https://www.env.gov.bc.ca/wsd/data_searches/water/` | Apache directory index (HTML) | file name, modified, size | 73 files | Lists the current archive names; the catalogue's are partly stale |
| `https://nr-bcwat.bcwatertool.ca/api/streamflow/stations` | GeoJSON | `id, nid, name, net, status, ty, yr` (years with data), `area, hasStage, hasSevenDay`; point geometry | 9,427 features (2,343 WSC; 407 other unique IDs) | Per station: `/api/streamflow/stations/{id}/csv`, `/report`. Also `/api/surface-water/stations`, `/api/groundwater/level/stations`, `/api/climate/stations` |
| `https://water.bc-er.ca/api/streamflow/stations` | GeoJSON | as above | 94 | Northeast BC subset |
| `https://catalogue.hakai.org/erddap/tabledap/HakaiWatershedsStreamStationsResearch.csv?station,station_id,station_description,latitude,longitude,elevation&distinct()` (also `...Provisional`) | CSV (any ERDDAP format) | `station, station_id, station_description, latitude, longitude, elevation` | 7 | Data in the same dataset; CC BY 4.0 |
| `https://services6.arcgis.com/ubm4tcTYICKBpist/arcgis/rest/services/StationInformation/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=false&f=json` | Esri JSON | `Station_ID, Station_Name, LATITUDE, LONGITUDE, Current_Reading_, Return_Period, PCT_of_Mean_Ann_Disch_, WSC_Real_Time_Data, Updated_at` | 522 | RFC real-time; links give provincial and USGS IDs |
| `https://services6.arcgis.com/ubm4tcTYICKBpist/arcgis/rest/services/Drought_Portal_Aquarius_and_USGS_Station_Discharge_view/FeatureServer/0/query?where=1%3D1&outFields=*&f=json` | Esri JSON | `Location_ID, Location_Name, Latitude, Longitude, Mean, Maximum, Minimum, Update_Date` | 18 | Daily summary of selected stations |
| `https://services1.arcgis.com/xeMpV7tU1t4KD3Ei/arcgis/rest/services/WestCoast_Hydrometric_Stations/FeatureServer/0/query?where=1%3D1&outFields=*&f=json` | Esri JSON | `StationID, Name, Latitude, Longitude, LatestDischarge, Maximum, Minimum, Median, DateOfRecord, URL` | 5 | West Coast water authorizations |
| `https://openmaps.gov.bc.ca/geo/pub/wfs?service=WFS&version=2.0.0&request=GetFeature&typeNames=pub:WHSE_ENVIRONMENTAL_MONITORING.ENVCAN_HYDROMETRIC_STN_SP&outputFormat=json` | GeoJSON (WFS) | `STATION_NUMBER, STATION_NAME, FLOW_TYPE, STATION_OPERATING_STATUS, START_DATE, END_DATE, WATERSHED_GROUP_CODE, ARCHIVE_URL, REALTIME_URL` | 2,317 | WSC (HYDAT) stations only |
| `https://services6.arcgis.com/ubm4tcTYICKBpist/arcgis/rest/services/BC_Streamflow_Inventory_Hydrometric_Station_View/FeatureServer/0/query?where=1%3D1&outFields=*&returnGeometry=false&f=json` | Esri JSON | `Hydrometric_Station_ID, Station_Name, DrainageArea, NormalRunoff_mm, n_yrs`, monthly shares | 467 | WSC + 5 USGS |
| `https://www.bchydro.com/energy-in-bc/operations/transmission-reservoir-data/hydrometeorologic-data.html` | HTML table (parseable) | station name (code), WSC ID or BC snow ID, region; link to `/info/res_hydromet/data/<code>.txt` | 220 | Text files hold 4 days only |
| `https://api.waterdata.usgs.gov/ogcapi/v0/collections/monitoring-locations/items?f=json&country_code=CA&limit=500` | GeoJSON (OGC API) | `id, monitoring_location_name, state_name, site_type, agency_code, drainage_area, ...` | 468 (234 BC) | Pair with `waterservices.usgs.gov/nwis/site/?seriesCatalogOutput=true&parameterCd=00060` (RDB) for periods |
| `https://nhgdatareq.unbc.ca/script.js` | JavaScript array (parseable) | `id, code, name, type` (WT, WX, TB, GB, WL) | 68 | No coordinates, no discharge; data by request form |

Not machine-readable or blocked: Aquarius WebPortal (disclaimer gate), Columbia Basin Water Hub on CanWIN (Anubis bot wall), Pacific DataStream API (key by form), FRDR search (JavaScript page), DFO VI Hydromets (HTML only), OBWB (PDF map only).

## Appendix: provincial discharge stations in the BC Data Catalogue CSVs

All 211 stations in `Discharge*.csv` (2026-10-28) [M]. First and last are the first and last hourly value; days with data counts distinct UTC dates; main grade is the commonest `Grade`; the last column gives the nearest HYDAT station where it is within 0.5 km (no HYDAT flow overlaps any provincial period, 1.4). `08MH0061` Waechter Creek and `H08KC1015` have discharge in the BC Water Tool but not in these files.

| ID | Name | Status | Lat | Lon | First | Last | Days with data | Main grade | Nearest HYDAT (km) |
|---|---|---|---|---|---|---|---|---|---|
| 07FA0001 | Le Bleu Creek north side of Moberly Lake | Active | 55.8305 | -121.8053 | 2021-06-22 | 2021-09-29 | 100 | Estimated |  |
| 07FC0001 | Osborn River near Doig River First Nation | Active | 56.5891 | -120.4256 | 2021-04-15 | 2026-10-02 | 823 | Estimated |  |
| 07FC0002 | Upper Aitken Creek at Mile 98 Road | Active | 56.8592 | -121.5138 | 2021-04-07 | 2025-10-09 | 797 | RISC E |  |
| 08EE0001 | Deep Creek at Farewell Bridge | Active | 54.5923 | -126.8364 | 2016-05-03 | 2018-11-24 | 936 | Estimated | 08EE022 (0.145) |
| 08EE0002 | McQuarrie Creek above Hwy 16 Culvert | Active | 54.5157 | -126.4661 | 2016-06-23 | 2018-10-19 | 849 | Estimated |  |
| 08GA0005 | Soames Creek | Active | 49.4142 | -123.4933 | 2023-02-17 | 2026-09-14 | 1306 | Undefined |  |
| 08GB0001 | Gray Creek at the Intake | Inactive | 49.5440 | -123.7336 | 2022-09-27 | 2024-10-01 | 736 | Undefined |  |
| 08HA0001 | Bonsall Creek at HWY 1 | Inactive | 48.8497 | -123.7224 | 2016-08-05 | 2019-10-29 | 1181 | Undefined |  |
| 08HA0003 | Handysen Creek near HWY 1 & Deloume Rd Crossing | Inactive | 48.6532 | -123.5635 | 2016-08-17 | 2016-10-12 | 57 | Undefined |  |
| 08HA0005 | O'Donnel Creek near Bear Hill Rd Crossing | Inactive | 48.5413 | -123.4122 | 2014-05-15 | 2015-05-06 | 357 | Undefined |  |
| 08HA0006 | Colquitz River near Beaver Lake Dam | Active | 48.5075 | -123.3940 | 2014-05-15 | 2015-05-06 | 357 | Undefined |  |
| 08HA0019 | Cusheon Creek at Outlet of Cusheon Lake | Inactive | 48.8113 | -123.4546 | 2017-05-25 | 2017-10-19 | 148 | Good | 08HA026 (0.043) |
| 08HA0020 | Fulford Creek near Fulford Harbour | Inactive | 48.7733 | -123.4684 | 2018-02-16 | 2024-12-02 | 1667 | Unspecified | 08HA055 (0.206) |
| 08HA0021 | Goudie Creek at French Beach Park | Inactive | 48.3913 | -123.9418 | 2017-06-26 | 2017-10-25 | 122 | Estimated |  |
| 08HA0022 | Koksilah River at Trestle | Active | 48.7553 | -123.6831 | 2021-10-01 | 2026-10-03 | 695 | RISC C | 08HA045 (0.062) |
| 08HA0023 | Chemainus River Upstream of Bannon Creek | Active | 48.9039 | -123.7573 | 2019-06-12 | 2021-09-30 | 547 | Undefined |  |
| 08HA0024 | Chemainus River ds of Chemainus Rd Bridge | Inactive | 48.8840 | -123.6873 | 2019-05-31 | 2021-10-04 | 557 | Undefined |  |
| 08HA0026 | Tetayut Creek at Pat Bay Highway | Inactive | 48.5797 | -123.3987 | 2020-05-21 | 2025-03-14 | 1588 | Undefined | 08HA060 (0.128) |
| 08HA0027 | Patrolas Creek at Moss Road | Inactive | 48.7240 | -123.6604 | 2018-07-04 | 2019-09-12 | 436 | Undefined | 08HA019 (0.197) |
| 08HA0029 | Wilkin Creek behind Keir Rd | Inactive | 48.6472 | -123.5518 | 2018-07-25 | 2019-09-30 | 433 | EXCELLENT - RATED STRUCTURE |  |
| 08HA0032 | Handysen Creek behind Kinnoull Creek | Inactive | 48.6435 | -123.5725 | 2018-08-01 | 2018-10-25 | 86 | EXCELLENT - RATED STRUCTURE | 08HA067 (0.239) |
| 08HA0033 | Handysen Creek above Hollings Creek | Inactive | 48.6486 | -123.5700 | 2018-07-25 | 2018-10-25 | 93 | EXCELLENT - RATED STRUCTURE | 08HA067 (0.491) |
| 08HA0036 | Oliver Creek in Lake Cowichan | Inactive | 48.8285 | -124.0499 | 2020-06-18 | 2024-09-12 | 1548 | RISC C | 08HA002 (0.375) |
| 08HA0037 | Koksilah River upstream of Kingburne Park | Active | 48.6781 | -123.6657 | 2021-10-01 | 2025-09-25 | 512 | RISC C |  |
| 08HA0038 | Tsolum River at Fitzgerald Rd bridge | Active | 49.7556 | -125.1054 | 2022-07-13 | 2026-10-15 | 751 | RISC C |  |
| 08HA0039 | Averill Creek Upstream of HWY 19 Crossing | Inactive | 48.7968 | -123.7175 | 2021-04-22 | 2022-10-26 | 265 | Unspecified | 08HA015 (0.186) |
| 08HA0045 | Goldstream River at Goldstream Provincial Park | Active | 48.4614 | -123.5525 | 2023-06-27 | 2026-10-28 | 1220 | RISC A | 08HA039 (0.031) |
| 08HB0002 | Roy Creek at HWY 19A | Active | 49.6457 | -124.9443 | 2016-06-16 | 2019-08-09 | 186 | Very Good |  |
| 08HB0003 | Annie Creek near HWY 19A | Inactive | 49.3852 | -124.5910 | 2016-07-21 | 2019-11-07 | 1205 | Undefined |  |
| 08HB0006 | North Haslam Creek near Rd crossing | Active | 49.0474 | -123.9096 | 2016-08-15 | 2016-10-11 | 58 | Undefined |  |
| 08HB0007 | Haslam Creek near Rail Bridge | Active | 49.0610 | -123.8801 | 2016-05-16 | 2026-10-28 | 3127 | Undefined |  |
| 08HB0008 | Rosewall Creek near HWY 19A Bridge | Active | 49.4554 | -124.7758 | 2021-10-01 | 2026-10-28 | 839 | RISC A |  |
| 08HB0010 | Nanoose Creek near HWY 19 Crossing | Inactive | 49.2648 | -124.2048 | 2017-03-23 | 2021-09-30 | 1653 | Undefined | 08HB039 (0.09) |
| 08HB0011 | Grandon Creek at Crescent Rd W | Active | 49.3572 | -124.4673 | 2021-10-01 | 2026-10-09 | 1835 | Excellent |  |
| 08HB0012 | Tsolum River near end of Michaels Dr | Active | 49.7470 | -125.0760 | 2021-10-01 | 2026-05-15 | 1403 | RISC C |  |
| 08HB0013 | Stamp River at Robertson Creek Hatchery | Active | 49.3394 | -124.9871 | 2014-10-02 | 2017-12-22 | 1139 | Very Good |  |
| 08HB0015 | Chase River at Seventh St. Bridge | Inactive | 49.1476 | -123.9454 | 2017-05-29 | 2017-12-07 | 193 | Very Good | 08HB054 (0.148) |
| 08HB0016 | Cherry Creek at Cherry Creek Rd. Bridge | Active | 49.2729 | -124.7860 | 2021-05-28 | 2025-05-01 | 1432 | RISC C | 08HB035 (0.174) |
| 08HB0017 | Bonell Creek d/s of Hwy 19 Bridge | Inactive | 49.2635 | -124.1983 | 2017-06-01 | 2018-07-19 | 414 | Unspecified | 08HB039 (0.419) |
| 08HB0018 | Morrison Creek near the Mouth | Inactive | 49.6878 | -125.0167 | 2018-11-15 | 2024-09-19 | 1780 | Undefined |  |
| 08HB0019 | Upper Qualicum River Upstream of Horne Lake | Inactive | 49.3448 | -124.7510 | 2018-09-12 | 2024-09-19 | 2077 | Undefined |  |
| 08HB0021 | French Creek ds of Barclay Cres | Active | 49.3442 | -124.3709 | 2021-10-01 | 2026-10-28 | 1747 | Undefined |  |
| 08HB0022 | Black Creek at Miracle Beach Drive | Active | 49.8501 | -125.1004 | 2018-06-27 | 2021-09-30 | 1192 | Undefined |  |
| 08HB0023 | Taylor River below Sutton Creek | Inactive | 49.2941 | -125.3002 | 2019-05-27 | 2024-09-09 | 1932 | Unspecified |  |
| 08HB0024 | Wilfred Creek at Highway 19A | Active | 49.4874 | -124.8080 | 2021-10-01 | 2026-07-24 | 1758 | RISC C |  |
| 08HB0025 | Beck Creek downstream of Cedar Rd | Inactive | 49.1253 | -123.9144 | 2019-07-02 | 2019-10-29 | 120 | EXCELLENT - RATED STRUCTURE |  |
| 08HB0027 | Shelley Creek upstream of Hamilton Avenue | Inactive | 49.3069 | -124.3038 | 2018-06-19 | 2019-11-26 | 526 | Undefined |  |
| 08HB0030 | Portuguese Creek at Headquarters Rd | Inactive | 49.7208 | -125.0093 | 2021-06-15 | 2021-10-07 | 115 | Unspecified |  |
| 08HB0031 | Beach Creek at Hemsworth Rd | Active | 49.3491 | -124.4283 | 2021-10-01 | 2026-10-09 | 1835 | Good |  |
| 08HB0032 | Cook Creek at Hwy 19A | Active | 49.4467 | -124.7583 | 2021-10-01 | 2026-07-24 | 1756 | Excellent |  |
| 08HB0033 | Departure Creek at Woodstream Park | Active | 49.2063 | -123.9738 | 2023-08-10 | 2026-07-23 | 1076 | RISC C |  |
| 08HB0034 | Morrison Creek at Arden Road | Active | 49.6800 | -125.0229 | 2023-09-20 | 2026-04-09 | 849 | RISC C |  |
| 08HB0037 | Headquarters Creek Upstream of Tsolum River | Active | 49.7648 | -125.1229 | 2024-06-06 | 2026-09-30 | 399 | Undefined | 08HB090 (0.208) |
| 08HB0040 | Cottle Creek at Hammond Bay Road | Active | 49.2139 | -123.9559 | 2024-09-19 | 2026-07-23 | 673 | RISC C |  |
| 08HC0001 | Sharp Creek at V-Notch Weir on Meare's Island | Active | 49.1840 | -125.8619 | 2013-06-28 | 2018-10-23 | 1285 | Unusable | 08HC003 (0.453) |
| 08HC0002 | No 1 Creek at V-Notch Weir on Meare's Island | Active | 49.1732 | -125.8625 | 2013-06-27 | 2018-10-24 | 1288 | Undefined |  |
| 08HC0003 | Close Creek on Meare's Island | Active | 49.1562 | -125.8560 | 2013-06-27 | 2024-04-21 | 2468 | Undefined |  |
| 08HC0004 | Ginnard Creek at V-Notch Weir on Meare's Island | Active | 49.1334 | -125.8387 | 2013-06-28 | 2018-10-23 | 1284 | Undefined |  |
| 08HD0003 | Amor De Cosmos Creek at Hwy 19 | Active | 50.2546 | -125.6597 | 2020-05-28 | 2025-05-13 | 1802 | RISC C |  |
| 08HF0001 | Cluxewe River at Rupert Main FSR | Inactive | 50.6051 | -127.1711 | 2023-04-19 | 2023-09-11 | 146 | RISC B |  |
| 08JC0001 | Clear Creek Upstream of Hwy 27 Crossing | Active | 54.1085 | -124.1383 | 2016-07-01 | 2019-11-14 | 1232 | Good | 08JC007 (0.23) |
| 08JC0002 | Corkscrew Creek Downstream of Edwards Rd. Bridge Crossing | Active | 53.8969 | -124.1976 | 2016-09-01 | 2020-06-04 | 1373 | Good | 08JC017 (0.026) |
| 08JC0003 | Murray Creek Upstream of Erickson Rd Bridge Crossing | Active | 54.0354 | -124.0471 | 2016-07-01 | 2019-11-14 | 1232 | Good |  |
| 08JC0005 | Stony Creek at Tachick Lake Outlet | Active | 53.9807 | -124.1297 | 2016-08-30 | 2019-11-14 | 1172 | Good |  |
| 08JC0006 | Stony Creek Upstream of Stony Creek Rd Bridge Crossing | Active | 53.9424 | -124.1073 | 2016-03-08 | 2019-11-13 | 1346 | Estimated | 08JC013 (0.145) |
| 08JC0018 | McMillan Creek us of storm water outfall | Inactive | 53.9382 | -122.7584 | 2018-09-21 | 2021-10-19 | 1125 | Good |  |
| 08JC0020 | McMillan Creek ds of storm water outfall | Inactive | 53.9379 | -122.7580 | 2018-10-04 | 2021-10-19 | 1112 | Good |  |
| 08LB0001 | Louis Creek above McGillivray Creek (LOU1) | Active | 50.8592 | -119.9731 | 2014-06-19 | 2016-11-17 | 296 | Good | 08LB081 (0.116) |
| 08LB0002 | Louis Creek below McGillivray Fan (LOU2) | Inactive | 50.8671 | -119.9772 | 2014-07-11 | 2016-11-17 | 313 | Very Good |  |
| 08LB0003 | McGillivray Creek at Louis Creek (MCG1) | Inactive | 50.8597 | -119.9727 | 2014-06-19 | 2016-11-17 | 300 | Very Good | 08LB081 (0.08) |
| 08LC0001 | Duteau at Whitevale Road (DUT1) | Active | 50.2200 | -119.0289 | 2014-06-25 | 2026-10-28 | 3884 | Good |  |
| 08LC0002 | Nicklen Creek at outlet of Nicklen Dam (NIK1) | Active | 50.1390 | -119.0148 | 2018-07-19 | 2025-10-16 | 2385 | Very Good | 08LC010 (0.298) |
| 08LC0005 | Bessette Creek near Horner Road | Active | 50.2074 | -119.0058 | 2021-10-01 | 2026-10-28 | 1850 | Undefined |  |
| 08LC0006 | Bessette Creek at Whitevale RoadShuswap Ave | Active | 50.2361 | -118.9660 | 2021-10-01 | 2026-10-28 | 1657 | Undefined | 08LC005 (0.21) |
| 08LE0001 | John Frank Creek at John Frank Lake Outlet | Inactive | 50.4709 | -120.1382 | 2016-02-17 | 2016-11-21 | 279 | Good |  |
| 08LE0002 | John Frank Creek at Roche Lake Outlet | Active | 50.4894 | -120.1500 | 2016-04-05 | 2016-11-21 | 231 | Good |  |
| 08LE0006 | Salmon River Above Bolean Creek at HW97 | Active | 50.4893 | -119.6006 | 2024-05-16 | 2026-10-28 | 896 | RISC A |  |
| 08LF0011 | Fiftyseven Creek at the end of Hooke Rd | Active | 51.1877 | -121.6722 | 2018-07-27 | 2018-10-10 | 76 | Good |  |
| 08LG0003 | Coldwater River at Coldwater Indian Reserve (CLD1) | Active | 50.0440 | -120.8585 | 2016-08-04 | 2017-10-31 | 454 | Unspecified |  |
| 08LG0004 | Coldwater River at Houston Street (CLD2) | Active | 50.0959 | -120.7781 | 2016-08-04 | 2017-10-31 | 454 | Excellent |  |
| 08LG0006 | Clapperton Creek near the Mouth (CLP2) | Active | 50.1636 | -120.6695 | 2008-03-14 | 2026-10-28 | 2292 | Very Good | 08LG015 (0.037) |
| 08LG0007 | Upper Nicola River near the mouth (UNR1) | Inactive | 50.2021 | -120.4741 | 2015-08-14 | 2015-10-12 | 60 | Very Good |  |
| 08LG0008 | Nicola River at Spius UREP | Active | 50.1452 | -121.0195 | 2015-07-02 | 2017-11-17 | 870 | Very Good |  |
| 08LG0009 | Chapperon Creek at Lake Outlet (CHPC) | Active | 50.2103 | -120.0709 | 2021-10-01 | 2026-08-29 | 1670 | Very Good |  |
| 08LG0013 | Clapperton Creek at Mill Creek Rd. (CLP3) | Inactive | 50.2020 | -120.6467 | 2006-05-31 | 2007-10-17 | 505 | Estimated |  |
| 08LG0015 | Guichon Creek at the mouth | Active | 50.1499 | -120.8781 | 2021-04-14 | 2026-10-28 | 920 | RISC A | 08LG004 (0.02) |
| 08LG0019 | Spaxmn Creek above S Douglas Lake St | Active | 50.1347 | -120.2772 | 2021-10-01 | 2026-10-28 | 1771 | Undefined | 08LG060 (0.187) |
| 08LG0020 | Upper Nicola River at Ward Bridge | Active | 50.1673 | -120.2069 | 2021-10-01 | 2024-09-16 | 1028 | Undefined |  |
| 08MB0001 | Twinflower Creek near Gaspard-Mons Sideroad | Active | 51.6453 | -122.9460 | 2016-05-05 | 2018-11-22 | 341 | Good |  |
| 08MB0002 | Mons Creek near Gaspard-Mons Sideroad | Active | 51.6143 | -122.9857 | 2016-05-05 | 2018-11-22 | 932 | Good |  |
| 08MB0003 | Puntzi Creek Headwaters at Historic Ranch | Active | 52.2177 | -124.1464 | 2017-06-21 | 2017-10-02 | 104 | Good |  |
| 08MC0001 | Mackin Creek at West Fraser Road | Active | 52.3767 | -122.3789 | 2011-02-03 | 2012-09-20 | 596 | Good |  |
| 08MD0002 | Fraser River Upstream of Big Bar Slide | Active | 51.2264 | -122.1569 | 2021-10-01 | 2026-10-28 | 1485 | Undefined |  |
| 08MD0003 | Fraser River Eddy Below Big Bar Slide | Active | 51.2175 | -122.1522 | 2021-10-01 | 2026-04-24 | 1221 | Undefined |  |
| 08MF0004 | Elk Creek adjacent to Patterson Road | Active | 49.1439 | -121.8341 | 2020-09-30 | 2025-12-11 | 1897 | Very Good | 08MF048 (0.248) |
| 08MG0001 | Lillooet River at FSR | Active | 50.5025 | -122.9675 | 2014-06-18 | 2026-10-28 | 4516 | Undefined |  |
| 08MG0002 | Fitzsimmons Creek | Active | 50.1078 | -122.9500 | 2014-11-06 | 2026-10-28 | 4122 | Undefined |  |
| 08MG0003 | Green River at Nairn Falls | Active | 50.2929 | -122.8131 | 2021-03-31 | 2026-10-28 | 1878 | Undefined |  |
| 08MG0004 | Miller Creek Basin | Active | 50.3513 | -122.8553 | 2021-10-01 | 2026-10-28 | 1503 | Undefined |  |
| 08MG0005 | Birkenhead River ds of Owl Creek | Active | 50.3325 | -122.7256 | 2021-10-01 | 2026-10-28 | 1822 | Undefined |  |
| 08MH0009 | Archibald Creek at 142 Street - City of Surrey | Inactive | 49.1199 | -122.8289 | 2014-06-01 | 2023-08-28 | 3376 | Undefined |  |
| 08MH0014 | Latimer Creek at 192nd - City of Surrey | Inactive | 49.1586 | -122.6905 | 2014-07-29 | 2023-08-28 | 3149 | Undefined |  |
| 08MH0016 | Little Campbell Creek at 12 Avenue - City of Surrey | Inactive | 49.0240 | -122.7194 | 2014-06-01 | 2023-08-28 | 3362 | Undefined | 08MH123 (0.123) |
| 08MH0020 | Nicomekl River Upstream of Sea Dam - City of Surrey | Active | 49.0694 | -122.8251 | 2013-09-17 | 2021-07-16 | 2848 | Undefined |  |
| 08MH0022 | Quibble Creek at 88 Avenue - City of Surrey | Inactive | 49.1626 | -122.8447 | 2016-06-27 | 2023-08-28 | 2619 | Undefined |  |
| 08MH0027 | Anderson Creek at Colebrook Road - City of Surrey | Active | 49.0924 | -122.6844 | 2015-11-05 | 2017-01-18 | 441 | Undefined | 08MH104 (0.128) |
| 08MH0028 | Barker (Bolivar) Creek at 114 Avenue - City of Surrey | Active | 49.2097 | -122.8536 | 2017-05-31 | 2018-10-25 | 513 | Undefined | 08MH134 (0.122) |
| 08MH0029 | Bon Accord Creek at Surrey Road - City of Surrey | Active | 49.2138 | -122.8165 | 2017-05-31 | 2017-10-18 | 141 | Undefined |  |
| 08MH0031 | Cougar Creek at 120 Street - City of Surrey | Active | 49.1286 | -122.8906 | 2016-05-13 | 2017-07-19 | 433 | Undefined |  |
| 08MH0032 | Erikson Ditch at 180 Street - City of Surrey | Active | 49.0610 | -122.7243 | 2015-10-31 | 2017-01-31 | 459 | Undefined |  |
| 08MH0033 | Upper Eugene Creek at Delta-South Surrey Regional Greenway - | Active | 49.0997 | -122.8866 | 2016-05-14 | 2017-07-19 | 432 | Undefined |  |
| 08MH0034 | Fergus Creek at 168 Street - City of Surrey | Active | 49.0229 | -122.7575 | 2015-12-02 | 2017-01-18 | 414 | Undefined |  |
| 08MH0035 | Leoran Brook at 99A Avenue - City of Surrey | Active | 49.1834 | -122.7206 | 2018-05-31 | 2019-07-17 | 413 | Undefined |  |
| 08MH0036 | Peacock Brook at 54A Avenue - City of Surrey | Active | 49.1016 | -122.8628 | 2016-05-13 | 2017-07-19 | 433 | Undefined |  |
| 08MH0037 | Robson Creek at 103A Avenue - City of Surrey | Active | 49.1908 | -122.8807 | 2017-05-31 | 2018-10-25 | 513 | Undefined |  |
| 08MH0038 | Sam Hill Creek at 172nd Street - City of Surrey | Active | 49.0276 | -122.7462 | 2015-10-30 | 2017-01-18 | 447 | Undefined |  |
| 08MH0039 | Upper McLellan at 64th Avenue - City of Surrey | Active | 49.1191 | -122.6855 | 2018-05-31 | 2021-01-08 | 696 | Undefined |  |
| 08MH0040 | Walnut Creek at 80 Avenue - City of Surrey | Active | 49.1481 | -122.7716 | 2018-05-31 | 2019-07-17 | 413 | Undefined |  |
| 08MH0041 | Little Campbell River (A Rocha) at 16 Ave | Active | 49.0316 | -122.6873 | 2019-02-08 | 2026-10-28 | 2820 | RISC C |  |
| 08MH0042 | Little Campbell River at 232 St | Inactive | 49.0134 | -122.5822 | 2019-02-08 | 2026-07-03 | 2100 | Very Good |  |
| 08MH0048 | Bertrand Creek at Otter Park (HS2) | Active | 49.0376 | -122.5342 | 2019-05-09 | 2026-03-23 | 2279 | Good |  |
| 08MH0049 | Bertrand Creek at Otter Park (HS5) | Inactive | 49.0369 | -122.5365 | 2019-05-09 | 2026-08-05 | 2476 | Unspecified |  |
| 08MH0051 | Clayburn Creek at Wright St | Active | 49.0797 | -122.2608 | 2019-06-19 | 2026-08-25 | 2576 | Very Good |  |
| 08MH0052 | Partington Creek adjacent to Gilleys Trail | Active | 49.2967 | -122.7171 | 2019-11-21 | 2026-10-27 | 2327 | Undefined |  |
| 08MH0053 | Silverdale Creek at Silverdale Ave | Inactive | 49.1409 | -122.3549 | 2020-02-20 | 2022-02-25 | 735 | Very Good |  |
| 08MH0054 | Nathan Creek at Nathan Avenue | Inactive | 49.1144 | -122.4527 | 2020-07-01 | 2026-09-02 | 2089 | Unspecified |  |
| 08MH0056 | Silverdale Creek at Tyler and Wren | Active | 49.1482 | -122.3383 | 2020-09-28 | 2026-10-27 | 2214 | RISC B | 08MH091 (0.081) |
| 08MH0057 | Clayburn Creek on the south side of Straiton Road | Inactive | 49.0777 | -122.2416 | 2020-09-29 | 2021-11-03 | 401 | Good |  |
| 08MH0058 | McLennan Creek at Vitalus | Active | 49.0743 | -122.3820 | 2020-12-10 | 2026-01-22 | 1870 | Unspecified |  |
| 08MH0060 | Blaney Creek in MKRF | Active | 49.2940 | -122.5809 | 2021-09-14 | 2026-08-08 | 1385 | RISC C |  |
| 08MH0062 | Gold Creek at Golden Ears Provincial Park | Active | 49.3319 | -122.4584 | 2026-02-12 | 2026-10-28 | 259 | RISC A |  |
| 08NE0001 | Illecillewaet River at A.O. Wheeler Hut | Active | 51.2627 | -117.4915 | 2024-09-11 | 2026-10-28 | 778 | RISC A |  |
| 08NH0001 | Five Mile Creek at WSC Station 08NJ168 | Active | 49.5186 | -117.2108 | 2016-07-28 | 2026-10-20 | 3688 | Very Good | 08NJ168 (0.059) |
| 08NH0003 | Bird Creek at MAA Intake | Inactive | 49.4476 | -117.4522 | 2017-10-05 | 2021-10-18 | 1475 | Unspecified |  |
| 08NJ0001 | Gwillim Creek at Slocan West Rd | Active | 49.7548 | -117.4825 | 2025-07-30 | 2026-10-28 | 454 | RISC A | 08NJ132 (0.093) |
| 08NK0001 | Henretta Creek (FR_HC1) | Active | 50.2308 | -114.8657 | 2018-01-08 | 2020-12-31 | 1089 | Undefined |  |
| 08NK0002 | Kilmarnock Creek (FR_HC1) | Active | 50.1691 | -114.8629 | 2018-01-01 | 2020-08-21 | 964 | Undefined | 08NK029 (0.153) |
| 08NK0003 | Fording River (FR_KC1) | Active | 50.1880 | -114.8830 | 2018-03-13 | 2020-12-31 | 1015 | Undefined |  |
| 08NK0004 | Line Creek (LC_LC3) | Active | 49.9191 | -114.7698 | 2018-01-03 | 2020-12-31 | 737 | Undefined |  |
| 08NK0005 | Line Creek (LC_LC2) | Active | 49.9587 | -114.7472 | 2018-01-01 | 2020-12-31 | 1096 | Undefined |  |
| 08NK0006 | West Line Creek (LC_WLC) | Active | 49.9208 | -114.7710 | 2018-01-01 | 2020-12-31 | 1096 | Undefined |  |
| 08NK0007 | Line Creek (LC_LCDSSLCC) | Active | 49.9059 | -114.7826 | 2018-03-13 | 2020-12-31 | 1022 | Undefined |  |
| 08NK0008 | Erickson Creek (EV_EC1) | Active | 49.6778 | -114.7840 | 2018-01-02 | 2019-12-31 | 729 | Undefined |  |
| 08NK0009 | Dry Creek (EV_DC1) | Active | 49.7891 | -114.7854 | 2018-03-19 | 2019-11-15 | 607 | Undefined |  |
| 08NK0010 | Michel Creek (EV_MC2) | Active | 49.7303 | -114.8578 | 2018-03-13 | 2020-12-21 | 1015 | Undefined | 08NK020 (0.079) |
| 08NK0011 | Harmer Creek (EV_HC1) | Active | 49.8314 | -114.8164 | 2018-06-27 | 2020-12-31 | 919 | Undefined |  |
| 08NK0012 | Corbin Creek (CM_CC1) | Active | 49.5155 | -114.6718 | 2018-01-01 | 2020-12-31 | 1096 | Undefined | 08NK028 (0.463) |
| 08NK0013 | Michel Creek (CM_MC1) | Active | 49.4754 | -114.6785 | 2018-01-01 | 2020-12-31 | 1096 | Undefined |  |
| 08NK0014 | Greenhills Creek (GH_GH1) | Active | 50.0453 | -114.8550 | 2018-01-02 | 2020-12-31 | 1093 | Undefined |  |
| 08NL0001 | Summers Creek at Outlet of Missezula Lake | Active | 49.7665 | -120.4976 | 2016-06-30 | 2017-03-31 | 275 | Undefined | 08NL043 (0.133) |
| 08NL0002 | Summers Creek at Mouth | Active | 49.5346 | -120.5186 | 2016-07-07 | 2017-03-31 | 268 | Undefined | 08NL056 (0.142) |
| 08NM0002 | Equesis Creek near the Mouth | Active | 50.2882 | -119.4137 | 2016-09-07 | 2026-10-28 | 3704 | Undefined | 08NM161 (0.126) |
| 08NM0003 | Vaseux Creek near the Mouth | Active | 49.2455 | -119.5247 | 2017-05-06 | 2026-10-28 | 3462 | Undefined | 08NM246 (0.022) |
| 08NM0004 | Shorts Creek at the Canyon | Inactive | 50.1329 | -119.5157 | 2014-10-17 | 2023-11-10 | 3124 | Undefined | 08NM151 (0.196) |
| 08NM0005 | Upper Vernon Creek below Swalwell Lake | Active | 50.0409 | -119.2451 | 2012-06-13 | 2026-10-28 | 4131 | Undefined | 08NM022 (0.281) |
| 08NM0006 | Coldstream Creek Near McClounie Road | Inactive | 50.2251 | -119.2469 | 2016-08-30 | 2023-04-04 | 1387 | Undefined | 08NM154 (0.263) |
| 08NM0008 | Equesis Creek at Bonneau Road | Inactive | 50.2943 | -119.4234 | 2017-05-06 | 2017-11-23 | 202 | Undefined |  |
| 08NM0009 | Lower Vernon Creek near Okanagan Landing Road | Inactive | 50.2457 | -119.3242 | 2016-08-29 | 2017-12-07 | 466 | Undefined |  |
| 08NM0010 | McDougall Creek near the Mouth | Active | 49.8224 | -119.5952 | 2017-05-05 | 2026-10-28 | 2357 | Undefined |  |
| 08NM0011 | McDougall Creek at Bartley Road | Active | 49.8872 | -119.5891 | 2017-06-10 | 2018-01-16 | 221 | Undefined |  |
| 08NM0012 | Mission Creek above Gordon Drive | Active | 49.8426 | -119.4759 | 2016-07-28 | 2026-10-28 | 2554 | Undefined |  |
| 08NM0013 | Mission Creek at Casorso Road | Active | 49.8455 | -119.4677 | 2016-03-22 | 2017-12-14 | 633 | Undefined |  |
| 08NM0014 | Mission Creek upstream of KLO Road | Inactive | 49.8631 | -119.4426 | 2016-04-01 | 2017-12-04 | 613 | Undefined |  |
| 08NM0015 | Mission Creek at Ziprick Road | Active | 49.8798 | -119.4219 | 2016-07-13 | 2017-12-04 | 510 | Undefined |  |
| 08NM0017 | Mission Creek at Hollywood Road | Active | 49.8729 | -119.3979 | 2016-04-01 | 2017-12-04 | 613 | Undefined |  |
| 08NM0018 | Mission Creek at 12km Bridge | Active | 49.8508 | -119.3832 | 2016-03-23 | 2017-12-04 | 622 | Undefined |  |
| 08NM0019 | Mission Creek below KLO Creek | Active | 49.8449 | -119.3643 | 2016-04-01 | 2017-12-04 | 613 | Undefined |  |
| 08NM0020 | Mission Creek above BMID Intake | Inactive | 49.8536 | -119.2655 | 2016-04-01 | 2017-12-04 | 613 | Undefined |  |
| 08NM0021 | Mission Creek Upstream of East Kelowna Road | Inactive | 49.8642 | -119.3897 | 2016-08-23 | 2017-12-04 | 469 | Undefined |  |
| 08NM0022 | Benvoulin WUC Diversion Channel | Active | 49.8799 | -119.4176 | 2016-08-23 | 2017-11-06 | 441 | Undefined | 08NM116 (0.364) |
| 08NM0023 | Mission Creek Downstream of KLO Road | Inactive | 49.8603 | -119.4437 | 2016-08-24 | 2017-12-05 | 469 | Undefined |  |
| 08NM0024 | Priest Creek at the Mouth | Inactive | 49.8457 | -119.4667 | 2016-08-24 | 2017-12-05 | 469 | Undefined |  |
| 08NM0025 | KLO Creek Near the Mouth | Inactive | 49.8426 | -119.3641 | 2016-08-25 | 2017-12-05 | 468 | Undefined |  |
| 08NM0026 | Naswhito Creek near Mouth | Active | 50.2748 | -119.4351 | 2016-08-30 | 2026-10-28 | 2578 | Undefined |  |
| 08NM0028 | Upper Vernon Creek below Clark Creek | Inactive | 50.0146 | -119.3604 | 2012-06-20 | 2014-11-19 | 883 | Undefined |  |
| 08NM0029 | Middle Vernon Creek at Lodge Road | Inactive | 50.0344 | -119.3978 | 2012-05-23 | 2014-11-19 | 911 | Undefined |  |
| 08NM0030 | Middle Vernon Creek below Ellison Lake | Inactive | 50.0155 | -119.4026 | 2012-05-23 | 2017-02-01 | 1716 | Undefined | 08NM182 (0.075) |
| 08NM0032 | Middle Vernon Creek at Reimche Road | Active | 50.0494 | -119.4061 | 2012-05-23 | 2025-04-17 | 3945 | Undefined | 08NM009 (0.04) |
| 08NM0033 | Whiteman Creek near Mouth | Active | 50.2336 | -119.4431 | 2017-05-12 | 2026-10-28 | 842 | Undefined |  |
| 08NM0043 | Middle Vernon Creek at Beaver Lake Road | Inactive | 50.0203 | -119.4025 | 2018-06-13 | 2018-12-05 | 176 | Good | 08NM008 (0.109) |
| 08NM0046 | Shingle Creek at Gabriel Fields | Active | 49.5062 | -119.7510 | 2016-08-06 | 2018-10-17 | 803 | Undefined |  |
| 08NM0047 | Shuttleworth Creek at Maple St | Active | 49.3421 | -119.5689 | 2017-04-01 | 2026-10-28 | 2414 | Undefined |  |
| 08NM0048 | Shingle Creek at Lower Irrigation Dam | Active | 49.4782 | -119.6311 | 2021-10-01 | 2026-02-11 | 1560 | Undefined |  |
| 08NM0049 | Naramata Creek at 3rd Street | Active | 49.5962 | -119.6002 | 2021-10-01 | 2026-10-28 | 1712 | Undefined |  |
| 08NM0050 | Deep Creek at Antoine Road | Active | 50.3467 | -119.2964 | 2022-04-29 | 2026-10-28 | 1642 | Undefined | 08NM153 (0.224) |
| 08NM0051 | McLean Creek at Devon Drive | Active | 49.3802 | -119.5642 | 2021-11-18 | 2026-10-28 | 1601 | Undefined |  |
| 08NM0052 | Powers Creek near Mouth | Active | 49.8134 | -119.6281 | 2021-10-01 | 2026-10-28 | 1854 | Undefined | 08NM157 (0.181) |
| 08NM0053 | Trepanier Creek near Mouth | Active | 49.7844 | -119.7145 | 2021-10-01 | 2026-10-28 | 1477 | Undefined | 08NM155 (0.165) |
| 08NM0054 | Peachland Creek near Mouth | Active | 49.7420 | -119.7634 | 2021-10-01 | 2026-10-28 | 1814 | Undefined | 08NM159 (0.093) |
| 08NM0055 | Brandt's Creek at Brant Ave | Active | 49.8945 | -119.4747 | 2023-09-22 | 2026-10-28 | 1120 | Undefined |  |
| 08NM0056 | Brandt's Creek at Clement Ave | Inactive | 49.8933 | -119.4731 | 2021-10-01 | 2022-03-27 | 178 | Undefined |  |
| 08NM0057 | Scotty Creek at Old Vernon Road | Inactive | 49.9410 | -119.3647 | 2021-10-01 | 2024-08-05 | 1040 | Undefined |  |
| 08NM0058 | Mill Creek at Sutherland Bridge | Active | 49.8803 | -119.4674 | 2021-10-01 | 2026-10-28 | 1853 | Undefined |  |
| 08NM0059 | Mill Creek at Regional Park | Active | 49.9725 | -119.3635 | 2021-10-01 | 2026-10-28 | 1854 | Undefined |  |
| 08NM0060 | Mill Creek at Fenwick Road | Active | 49.9054 | -119.4062 | 2021-10-01 | 2026-10-28 | 1841 | Undefined |  |
| 08NM0064 | Mill Creek at Parkinson Recreation Centre | Inactive | 49.8847 | -119.4573 | 2023-08-28 | 2023-11-17 | 82 | Undefined |  |
| 08NM0065 | Shorts Creek at Fintry Bridge | Active | 50.1362 | -119.5029 | 2023-09-20 | 2026-10-28 | 875 | Undefined |  |
| 08NM0066 | Vaseux Creek at the Canyon | Active | 49.2575 | -119.5090 | 2021-10-01 | 2026-10-28 | 1817 | Undefined |  |
| 08NM0069 | Shingle Creek at Gabriel Fields | Active | 49.5062 | -119.7510 | 2021-10-01 | 2026-06-29 | 1733 | Undefined |  |
| 08NM0072 | Kefee Creek at Spland Rd | Active | 49.8802 | -119.5449 | 2025-11-19 | 2026-07-20 | 187 | Undefined |  |
| 08NM0073 | Scotty Creek at Sunset Ranch | Active | 49.9402 | -119.3528 | 2025-04-24 | 2026-10-28 | 553 | Undefined |  |
| 08NM0074 | Naswhito Creek at Jealous Fruits Pumphouse | Active | 50.2957 | -119.4717 | 2024-04-22 | 2026-10-28 | 875 | Undefined |  |
| 08NM0075 | Irish Creek at Westside Road | Active | 50.3555 | -119.3194 | 2024-06-18 | 2026-10-28 | 863 | Undefined |  |
| 08NM0076 | Equesis Creek at Six Mile Creek Bridge | Active | 50.3574 | -119.4796 | 2024-04-23 | 2026-10-28 | 898 | Undefined |  |
| 08NM0077 | Ewer Creek at Siwash Rock Main Bridge | Active | 50.3659 | -119.5059 | 2023-11-13 | 2026-10-28 | 920 | Undefined | 08NM176 (0.161) |
| 10CD0001 | Martin Creek north of Prophet River First Nation | Active | 58.1996 | -122.7645 | 2019-06-25 | 2019-10-01 | 99 | Undefined |  |
| 1AHA040 | AYUM CREEK NEAR MOUTH | Inactive | 48.3944 | -123.6611 | 1998-05-28 | 2003-01-10 | 1689 | Unspecified |  |
| 1AHA045 | GOLDSTREAM RIVER BELOW FISH WEIR | Inactive | 48.4308 | -123.3142 | 1999-02-05 | 2002-01-10 | 1071 | Unspecified |  |
| H08KC0626 | Hakai Institute - Calvert Island Watershed 626 | Active | 51.6411 | -128.1206 | 2021-10-01 | 2026-10-28 | 1845 | RISC U |  |
| H08KC0703 | Hakai Institute - Calvert Island Watershed 703 | Active | 51.6466 | -128.0257 | 2021-10-01 | 2026-10-28 | 799 | RISC U |  |
| H08KC0844 | Hakai Institute - Hecate Island Watershed 844 | Active | 51.6608 | -128.0025 | 2021-10-01 | 2026-10-28 | 1772 | RISC U |  |
