# Station source survey, part B: Columbia Basin Water Hub, Skeena Knowledge Trust, DataStream

Desk research for #123, 2026-10-28 (UTC). Tags: [S] the linked page says it (URL, quote); [M] measured here (command, result); [I] inferred.
Scratch outputs (API dumps, scripts) were session-temporary and are not kept.
HYDAT comparisons use the pinned release `20260717` (`wet` cache, opened read-only).

Summary:

- **Columbia Basin Water Hub** is the only one of the three that holds original, gauged, continuous discharge outside HYDAT. It has 96 datasets that carry discharge, and 76 of them list discharge as a parameter in the resource metadata. Of those 76, 43 belong to Living Lakes Canada's Columbia Basin Water Monitoring Framework (CBWMF) network, plus 33 from partner groups. Every hydrometric resource is labelled preliminary. The flag column is empty, and there are no approved or final series. Licences are CC BY-SA or CC BY-NC-SA, with an unexplained "Amended CC-BY-SA-4.0" on the CBWMF datasets. The CKAN action API is open and returns machine-readable site lists with coordinates. The HTML pages and file downloads sit behind an Anubis bot wall. robots.txt disallows `/api/`.
- **Skeena Salmon Data Centre** (the Skeena Knowledge Trust's CKAN) is a catalogue of reports and links. It holds no original continuous discharge series. Its flow content is WSC/HYDAT copies or links, two BC Ministry of Environment regional streamflow analyses built on WSC records, and links to the provincial AQUARIUS portal.
- **DataStream** allows discharge and stage in its vocabulary (`Discharge, River/Stream`, `Water level`, `Water level (probe)`, `Water level elevation`, `Velocity - stream`). BC data-level holdings could not be measured: the API needs a key, which is given on request, and datastream.org's robots.txt opts out of AI agents by name. Metadata suggests a few BC water-level logger datasets (DFO CoSMo, Resilient Waters). No BC dataset found describes a rated discharge series.

---

## 1. Columbia Basin Water Hub (Living Lakes Canada)

### Assets found

| asset | URL | status |
|---|---|---|
| Water Hub CKAN catalogue | https://data.cbwaterhub.ca (also https://cbwaterhub.ca, which redirects there) | HTML is behind an Anubis bot wall; the action API is open |
| CKAN action API | https://data.cbwaterhub.ca/api/3/action/ | open, JSON |
| CKAN DataStore (time series) | `datastore_search`, POST only | open, JSON |
| CBWMF group | https://data.cbwaterhub.ca/group/columbia-basin-water-monitoring-framework | HTML blocked; reachable through the API (`fq=groups:...`) |
| LLC CBWMF programme page | https://livinglakescanada.ca/project/columbia-basin-water-monitoring-framework/ | open |
| LLC Water Hub programme page | https://livinglakescanada.ca/project/columbia-basin-water-hub/ | open |
| columbiabasinwaterhub.ca | https://columbiabasinwaterhub.ca | dead [M: `curl -sL` returned HTTP 000, no connection] |
| Water Hub licence and grade definitions | probably on the CKAN site's own pages | not reached (Anubis); not in the API [M] |

### Platform and access

- [M] CKAN 2.11.6 with the extensions `datastore`, `xloader`, `scheming_datasets`, `wh_doi`, `ingest`, `mapsearch` and others. Command: `curl -sL https://data.cbwaterhub.ca/api/3/action/status_show`.
- [M] 452 datasets in total (`package_list`; `package_search?rows=1000` returned `count: 452`). By `data_type`: Stream 242, Lake 151, Groundwater 35, Climate 10, Wetland 8, Other 4.
- [M] The HTML pages and the resource download URLs (`/dataset/<id>/resource/<id>/download/...csv`) return an Anubis proof-of-work challenge to curl ("Making sure you're not a bot!"), and the download path answered "Oh noes! ... Protected by Anubis". WebFetch got "Access Denied ... Protected by Anubis". I did not try to solve the challenge.
- [M] The action API answers curl normally. `datastore_search` refuses GET ("Please use POST method for your request") and works with `curl -X POST -H 'Content-Type: application/json' -d '{"resource_id":"…","limit":32000,"offset":0}' https://data.cbwaterhub.ca/api/3/action/datastore_search`. `datastore_search_sql` is not enabled ("Action name not known").
- [M] robots.txt at https://data.cbwaterhub.ca/robots.txt reads `User-agent: * … Disallow: /api/ … Crawl-Delay: 10`. A scripted wet reader would be fetching a path the site asks crawlers to avoid, so ask Living Lakes before automating [I].
- [S] Each dataset has a DOI under prefix 10.48511, for example "Living Lakes Canada. (2024). Lillian Lake Level (CKHLIL01L) [Data set]. Columbia Basin Water Hub. https://doi.org/10.48511/5mp89eyw" (`citation` field, API).
- [S] LLC Water Hub page (URL above): "The CKAN platform was chosen for the database"; "adheres to FAIR principles"; "Templates are provided to user groups to ensure that the data is provided in a consistent format."

### 1a. CBWMF hydrometric network (Living Lakes Canada)

- [S] https://livinglakescanada.ca/project/columbia-basin-water-monitoring-framework/: "The Columbia Basin Water Monitoring Framework (CBWMF) is a coordinated network of 118 monitoring sites across Southeast BC"; "piloted this project in 2022 within three areas … expanded the project into two new areas in 2023, for a total of five operational areas covering 25,000 square kilometres"; "Monitoring in the new areas was initiated in Fall 2023 and early 2024"; "This program's data is publicly available on the Columbia Basin Water Hub." The 118 sites include lake, groundwater and climate sites [I, from the group's composition below].
- [M] The CKAN group `columbia-basin-water-monitoring-framework` holds 108 datasets (`package_search?fq=groups:columbia-basin-water-monitoring-framework&rows=0` → 108), of which 52 are tagged Discharge (`fq=groups:… AND tags:Discharge` → 52). Of the hydrometric datasets in the group, 54 are Stream, 33 Groundwater and 11 Lake.
- **Discharge or stage:** both. [M] Of the 54 CBWMF stream datasets, 43 list `Discharge` (unit "metres3 per second") in a resource's `parameter` metadata, and 52 carry the Discharge tag. The other 11 hold stage only or are not yet rated: MacDonald, Kootenay Joe, Gar, Bjerkness, Carlyle, Blueberry, Rock Canyon, Hazel, Hardie, Fairmont and Bugaboo creeks. [M] The Bruce Creek resource (`faa3b969-47b5-416e-b37e-f6f070a42a76`, site CKHBRU01H) has the fields `date_time, site_id, latitude, longitude, notes, discharge, discharge_units, water_level, water_level_units, water_hub_qa_qc`. It holds 89,101 rows at 15-minute intervals, 2022-07-14 to 2025-08-13. Discharge is non-missing in 81,287 rows (2022-09-16 to 2025-08-13), with values from 0.0 to 9.78 m³/s. Command: three POST `datastore_search` pages of 32,000 rows.
- **Rating curve:** [S] the CBWMF resource text (API field `data_collection_info`, Bruce Creek and others) says "Data is collected from hydrometric stations that measure water level (stage). For stream sites, this measured water level is used to calculate discharge". Another variant (`data_processing`, 14 resources) says "Data review, outlier trimming, stage-discharge relationship evaluation, internal computations to convert pressure measurements to stream discharge." The ratings are maintained by Living Lakes Canada and its contractors. [S] An earlier gap analysis was written by MacHydro (`machydro_cbwmfgapanalysisupdate_20231129_final.pdf`, linked from the CBWMF page). [S] The Elk River Alliance sites (`data_processing`) say the corrections were made "using Aquarius … Ice impacted data is removed from discharge curves. Initial data quality assurance and quality control (QA/QC) is conducted in-house by the Elk River Alliance. Further preliminary review of hydrometric data was conducted by MacHydro." No rating tables, gaugings or rating periods are published in the API [M: no resource of that kind found].
- **QA:** provisional only. [S] `data_processing` (26 discharge resources): "Real time water stage data is subject to preliminary correction … Stage data that appears suspect or is impacted by ice within the winter is also removed. Data is finalized once a year, at which time corrections are confirmed and additional corrections (such as data filling and smoothing) may be applied." [S] `description`: "This resource contains preliminary discharge and water level measurements for Bruce Creek … A finalized dataset will be produced annually. Check back for updates." [M] No resource across all 452 datasets has a hydrometric name containing "final" or "approved"; the six "Final" names are reports. Of the 96 discharge datasets, 52 have resource names starting "Preliminary". [M] The per-row flag `water_hub_qa_qc` is "N/A" in all 89,101 Bruce Creek rows, and `notes` is "N/A" in all of them too. [M] The resource-level `waterhub_certified` field reads "Certified" on 288 resources and "Not Certified" on 2. The `waterhub_grade` field takes the values Technical Research Grade, Community Research Grade, People and Perspectives and Not Reviewed. The grade definitions were not reachable (Anubis) [M].
- **Licence:** [M] the 54 CBWMF stream datasets are licensed "Amended CC-BY-SA-4.0" (50), CC-BY-NC-SA-4.0 (3) and CC-BY-SA-4.0 (1). The amendment's text is in neither `license_list`, which lists only the CKAN defaults, nor any dataset field [M]. It is most likely on a Hub page behind Anubis [I]. Redistribution: CC BY-SA allows it with attribution and share-alike, which would bind a derived wet product to share-alike [I]. What the amendment changes is unknown, so it must be confirmed with cbwaterhub@livinglakescanada.ca (the `maintainer_email` field) before anything is redistributed [I]. [S] `data_disclaimer`: "No warranty or guarantee exists that the information is accurate, complete, current, or suitable for any purpose."
- **Period and record length:** [M] CBWMF stream datasets start between 2012-10 (Elk River Alliance sites taken into the network) and 2024-07. Most start 2022–2024. 33 of the 54 have `end_date` on or after 2025-06. Records are short: the CBWMF network's own sites are 1–3 years long [M, from `start_date`/`end_date`].
- **Not in HYDAT:** see section 1c. None of the CBWMF series is a HYDAT record. Bruce Creek, Kelly, Beaver, Akokli, Glacier (lower), Summit, Goose, Harrop, Procter and others sit at discontinued WSC sites, and the CBWMF page says they were chosen for that reason. [S] Bruce Creek's `notes` say it "was selected to build on the historic Water Survey of Canada record available for this location."

### 1b. Partner discharge datasets on the Hub (not CBWMF)

- [M] 42 of the 96 discharge datasets are outside the CBWMF group. Their organizations are the Columbia Basin Water Hub itself (10, historical community data), Slocan River Streamkeepers (8), Elk River Alliance (6), Rossland Streamkeepers (4, including Trail Creek at French Street), Quadra Island Salmon Enhancement Society (4), Slocan Lake Stewardship Society (3), Harrop-Procter (2), SIFCo (2), and one dataset each from City of Nelson (Kootenay Environmental Innovations), CertainTeed, ALESS, Salmo Streamkeepers, Kalesnikoff, Laird Creek Waterusers, Red Mountain Residents and RDCK.
- Of these 42, 20 carry the Discharge tag but no discharge parameter in their resource metadata; they are probably spot or manual measurements [I]. [S] Examples in `data_processing`: "Computed values were divided by 1000 from original Litres per second calculations, based on the speed of filling a 208 L barrel"; "Where several measurements were taken in one day, an average of the values is provided".
- Rating curve, example: [S] Cottonwood Creek (City of Nelson): "The continuous discharge data is calculated using a compound stage-discharge relationship (SDR) developed using onsite flow measurements and computed in Fathom Scientific's Salt Portal software. The average deviation the flow measurements have from the SDR is 6.5%." Its `notes` say "This data is considered PRELIMINARY at this time."
- QA: [S] 18 resources say "The Water Hub has performed a preliminary QA/QC protocol on this data but the individual user must still confirm the accuracy", and 6 more add that values were "flagged … as unexpected".
- Licences: CC-BY-SA-4.0 (27 of all discharge datasets) and CC-BY-NC-SA-4.0 (18). NC forbids commercial redistribution [I].
- Long records: [M] 24 discharge datasets span 5 years or more and 15 span 10 or more. The longest is Bonanza Creek, 1996-06-14 to 2024-12-09 (28.5 years). Others include Cadden Creek at weir (1996–2002), Lizard Creek LIZ001 (2012–2023), and Redfish Creek (1993–2019), a water-quality dataset whose discharge parameter has the method note "WSC site".
- Outside the Columbia: [M] four datasets are on Quadra Island and Vancouver Island coast creeks (Hyacinthe, Drew, Granite Bay and Open Bay creeks; Quadra Island Salmon Enhancement Society). Hyacinthe Creek is 0.15 km from the discontinued WSC 08HD016 (1990–1999).

### 1c. Co-location with HYDAT (all 96 discharge datasets)

[M] Method: each dataset's `latitude`/`longitude` was matched to the nearest station in HYDAT 20260717 `STATIONS` (BC and neighbouring jurisdictions), with the Q period from `STN_DATA_RANGE` (script `hydat_near.py` in scratch). Results:

- 41 datasets lie within 1.5 km of a HYDAT station, and 23 within 0.5 km.
- 30 datasets on 28 distinct HYDAT stations share the stream name (crude test: first word of the dataset name found in the HYDAT name). Of those 28 stations, only one is active (`A`): **08NJ061 Redfish Creek near Harrop**, 0.02 km from the Redfish water-quality dataset, whose discharge is WSC's own. The rest are discontinued (`D`), with records ending between 1926 and 1998. Examples: 08NA060 Bruce Creek near Wilmer (1965–1977), 08NE042 Beaver Creek at Fruitvale (1930–1969), 08NJ027 Harrop Creek near Harrop (1922–1994), 08NJ120 Winlaw Creek near Winlaw (1944–1980), 08NJ164 Cadden Creek above Diversions (1982–1998), and 08NE118 Trail Creek at French Street (1975–1989).
- One false neighbour: Coal Creek COL006 is 0.89 km from the active 08NK002 Elk River at Fernie but is on another stream [M].
- So all 96 are records not held in HYDAT; about 28 extend a discontinued WSC record at or near the old gauge, and one duplicates an active WSC gauge [M/I]. Unique sites: [M] 94 distinct coordinates to 3 decimals (some datasets repeat a site, for example `wolverton-creek-hydrometric` and `wolverton-creek-monitoring`).

### 1d. Per-dataset table (96 datasets carrying discharge)

Built from `package_search` (all 452) [M]. "Q in resource params" Y means a resource's `parameter` list names Discharge; "tag only" means only the Discharge keyword. Licence abbreviations: Amd BY-SA = "Amended CC-BY-SA-4.0".

| dataset (CKAN name) | site id | org | CBWMF | Q in resource params | start | end | yrs | licence | nearest HYDAT (km, status, Q years) |
|---|---|---|---|---|---|---|---|---|---|
| forsyth-creek-hydrometric | FOR001 | elk-river-alliance | Y | Y | 2022-07-27 | 2025-05-05 | 2.8 | BY-NC-SA | >1.5 km |
| lizard-creek-liz001-water-quality | LIZ001 | elk-river-alliance | Y | Y | 2012-10-18 | 2023-10-04 | 11.0 | BY-NC-SA | >1.5 km |
| morrissey-creek-mor001-water-quality | MOR001 | elk-river-alliance | Y | Y | 2020-09-22 | 2025-05-21 | 4.7 | BY-NC-SA | >1.5 km |
| harrop-creek-hydrometric-lckhrp01h | LCKHRP01H | harrop-procter-watershed-protection-society | Y | Y | 2020-01-01 | 2024-09-30 | 4.7 | Amd BY-SA | 08NJ027 Harrop Creek Near Harrop (0.09 km, D, 1922-1994) |
| procter-creek-hydrometric-lckpro01h | LCKPRO01H | harrop-procter-watershed-protection-society | Y | Y | 2021-01-01 | 2024-10-01 | 3.7 | BY-SA | 08NJ021 Procter Creek At Procter (0.45 km, D, 1921-1950) |
| akokli-creek-hydrometric-lckako01h | LCKAKO01H | living-lakes-canada | Y | Y | 2024-01-01 | 2026-08-10 | 2.6 | Amd BY-SA | 08NH102 Akokli Creek Near Boswell (0.58 km, D, 1947-1952) |
| apex-creek-hydrometric-lckapx02h | LCKAPX02H | living-lakes-canada | Y | Y | 2023-12-21 | 2025-08-21 | 1.7 | Amd BY-SA | >1.5 km |
| assiniboine-creek-hydrometric | CKHASB01H | living-lakes-canada | Y | Y | 2022-08-12 | 2025-07-11 | 2.9 | Amd BY-SA | >1.5 km |
| beaver-creek-hydrometric-lckbvr01h | LCKBVR01H | living-lakes-canada | Y | Y | 2023-12-21 | 2025-08-27 | 1.7 | Amd BY-SA | 08NE042 Beaver Creek At Fruitvale (0.22 km, D, 1930-1969) |
| ben-hur-creek-hydrometric-station | MCKBEN01H | living-lakes-canada | Y | Y | 2013-10-19 | 2025-08-28 | 11.9 | Amd BY-SA | >1.5 km |
| bjerkness-creek-hydrometric-station | MCKBJE01H | living-lakes-canada | Y | tag only | 2013-07-25 | 2024-03-31 | 10.7 | Amd BY-SA | 08NH057 Bjerkness Creek At Mirror Lake (0.36 km, D, 1930-1968) |
| blueberry-creek-hydrometric-lckblu01h | LCKBLU01H | living-lakes-canada | Y | tag only | 2024-07-29 | 2025-10-17 | 1.2 | Amd BY-SA | >1.5 km |
| bonanza-creek-hydrometric-mckbon01h | MCKBON01H | living-lakes-canada | Y | Y | 2023-10-06 | 2025-10-02 | 2.0 | Amd BY-SA | 08NJ164 Cadden Creek Above Diversions (1.04 km, D, 1982-1998) |
| bruce-creek-hydrometric | CKHBRU01H | living-lakes-canada | Y | Y | 2022-07-14 | 2025-08-13 | 3.1 | Amd BY-SA | 08NA060 Bruce Creek Near Wilmer (0.4 km, D, 1965-1977) |
| bugaboo-creek-hydrometric | CKHBUG01H | living-lakes-canada | Y | tag only | 2022-08-05 | 2022-11-21 | 0.3 | Amd BY-SA | >1.5 km |
| caribou-creek-hydrometric | MCKCAR01H,MCKCAR02H | living-lakes-canada | Y | Y | 2022-09-08 | 2025-09-02 | 3.0 | Amd BY-SA | >1.5 km |
| carylye-creek-hydrometric-station | MCKCRL01H | living-lakes-canada | Y | tag only | 2012-10-11 | 2025-08-28 | 12.9 | Amd BY-SA | >1.5 km |
| cherry-creek-hydrometric-ukkchr01h | UKKCHR01H | living-lakes-canada | Y | Y | 2024-05-07 | 2025-10-28 | 1.5 | Amd BY-SA | >1.5 km |
| cory-creek-hydrometric-lckcor01h | LCKCOR01H | living-lakes-canada | Y | Y | 2023-10-15 | 2025-08-11 | 1.8 | Amd BY-SA | 08NH045 Sirdar Creek At Sirdar (1.26 km, D, 1928-1930) |
| davis-creek-hydrometric-station | MCKDAV01H | living-lakes-canada | Y | Y | 2013-06-22 | 2024-09-04 | 11.2 | Amd BY-SA | >1.5 km |
| delphine-creek-hydrometric | CKHDEL01H | living-lakes-canada | Y | Y | 2022-08-03 | 2024-08-19 | 2.0 | Amd BY-SA | >1.5 km |
| dumont-creek-hydrometric | MCKDUM01H | living-lakes-canada | Y | Y | 2022-08-30 | 2025-08-18 | 3.0 | Amd BY-SA | 08NJ166 Dumont Creek Near Winlaw (0.15 km, D, 1982-1985) |
| dunbar-creek-hydrometric | CKHDUN01H | living-lakes-canada | Y | Y | 2022-08-08 | 2025-08-14 | 3.0 | Amd BY-SA | >1.5 km |
| fairmont-creek-hydrometric |  | living-lakes-canada | Y | tag only | 2022-08-04 |  |  | Amd BY-SA | 08NA058 Hotspring Creek Near Fairmont Hot Springs (0.75 km, D, 1964-1969) |
| fitzstubbs-creek-hydrometric | MCKFIT01H | living-lakes-canada | Y | Y | 2022-09-03 | 2024-04-14 | 1.6 | Amd BY-SA | >1.5 km |
| gar-creek-hydrometric-station | MCKGAR01H | living-lakes-canada | Y | tag only | 2017-04-16 | 2025-08-29 | 8.4 | Amd BY-SA | >1.5 km |
| glacier-creek-lower-hydrometric | MCKGLA02H | living-lakes-canada | Y | Y |  |  |  | Amd BY-SA | 08NH003 Glacier Creek Near Howser (0.51 km, D, 1915-1966) |
| glacier-creek-upper-hydrometric | MCKGLA01H | living-lakes-canada | Y | Y | 2022-10-03 | 2023-06-27 | 0.7 | Amd BY-SA | >1.5 km |
| goose-creek-hydrometric-lckgos01h | LCKGOS01H | living-lakes-canada | Y | Y | 2023-10-03 | 2025-08-27 | 1.9 | Amd BY-SA | 08NJ159 Goose Creek At Provincial Forest Road (0.55 km, D, 1970-1973) |
| gray-creek-hydrometric | MCKGRA01H | living-lakes-canada | Y | Y | 2022-10-19 | 2025-08-19 | 2.8 | Amd BY-SA | 08NH065 Gray Creek Near Gray Creek (0.6 km, D, 1931-1931) |
| haha-creek-hydrometric-ukkhah01h | UKKHAH01H | living-lakes-canada | Y | Y | 2024-03-25 | 2025-10-28 | 1.6 | Amd BY-SA | >1.5 km |
| hanna-creek-hydrometric-lckhan01h | LCKHAN01H | living-lakes-canada | Y | Y | 2023-11-21 | 2025-09-26 | 1.8 | Amd BY-SA | >1.5 km |
| hardie-creek-hydrometric |  | living-lakes-canada | Y | tag only | 2022-07-15 |  |  | Amd BY-SA | >1.5 km |
| hazel-creek-hydrometric-lckhaz01h |  | living-lakes-canada | Y | tag only |  |  |  | Amd BY-SA | >1.5 km |
| jones-creek-hydrometric | CKHJON01H | living-lakes-canada | Y | Y | 2022-08-10 | 2025-06-16 | 2.9 | Amd BY-SA | >1.5 km |
| kelly-creek-hydrometric-lckkel01h | LCKKEL01H | living-lakes-canada | Y | Y | 2023-08-09 | 2025-08-27 | 2.1 | Amd BY-SA | 08NE071 Kelly Creek Near Fruitvale (0.56 km, D, 1946-1951) |
| kikomun-creek-hydrometric-ukkkmn01h | UKKKMN01H | living-lakes-canada | Y | Y | 2024-03-26 | 2025-10-29 | 1.6 | Amd BY-SA | >1.5 km |
| kindersley-creek-hydrometric | CKHKIN01H | living-lakes-canada | Y | Y | 2022-07-12 | 2025-07-17 | 3.0 | Amd BY-SA | >1.5 km |
| kootenay-joe-creek-hydrometric-station | MCKKOJ01H | living-lakes-canada | Y | tag only | 2018-10-22 | 2025-08-29 | 6.9 | Amd BY-SA | >1.5 km |
| lower-apex-creek-lckapx01h | LCKAPX01H | living-lakes-canada | Y | Y | 2023-10-07 | 2026-08-20 | 2.9 | Amd BY-SA | 08NE115 Apex Creek Near The Mouth (0.23 km, D, 1973-1975) |
| macdonald-creek-hydrometric-station | MCKMDC01H | living-lakes-canada | Y | tag only | 2012-10-13 | 2025-07-31 | 12.8 | Amd BY-SA | 08NH121 Mcdonald Creek Near Kaslo (0.14 km, D, 1965-1974) |
| mcdonald-creek-hydrometric | MCKMDC01H,NEMCD01 | living-lakes-canada | Y | Y | 2022-09-08 | 2023-08-17 | 0.9 | Amd BY-SA | >1.5 km |
| neave-creek-hydrometric-ckhnea01h | CKHNEA01H,Neave Creek | living-lakes-canada | Y | Y | 2024-04-02 | 2024-08-21 | 0.4 | Amd BY-SA | >1.5 km |
| reserve-creek-hydrometric-ukkrsv01h | UKKRSV01H | living-lakes-canada | Y | Y | 2024-03-27 | 2025-10-29 | 1.6 | Amd BY-SA | >1.5 km |
| rock-canyon-creek-hydrometric-ukkroc01h |  | living-lakes-canada | Y | tag only |  |  |  | Amd BY-SA | >1.5 km |
| sandy-creek-hydrometric-lcksan01h | LCKSAN01H | living-lakes-canada | Y | Y | 2023-09-28 | 2024-07-29 | 0.8 | Amd BY-SA | 08NJ167 Sandy Creek Above Relkoff Diversion (0.13 km, D, 1982-1998) |
| shepp-creek-hydrometric-ukkshp01h | UKKSHP01H | living-lakes-canada | Y | Y | 2024-06-19 | 2025-10-27 | 1.4 | Amd BY-SA | >1.5 km |
| silverton-creek-hydrometric | MCKSIL01H | living-lakes-canada | Y | Y | 2022-09-11 | 2025-07-01 | 2.8 | Amd BY-SA | >1.5 km |
| sulphur-creek-hydrometric-ukksul01h | UKKSUL01H | living-lakes-canada | Y | Y | 2024-05-17 | 2025-10-27 | 1.4 | Amd BY-SA | >1.5 km |
| summit-creek-hydrometric-lcksum01h | LCKSUM01H | living-lakes-canada | Y | Y | 2023-10-14 | 2025-10-14 | 2.0 | Amd BY-SA | 08NH100 Summit Creek Near Creston (0.54 km, D, 1946-1955) |
| thunder-creek-hydrometric-ukkthu01h | UKKTHU01H | living-lakes-canada | Y | Y | 2024-05-14 | 2024-08-27 | 0.3 | Amd BY-SA | >1.5 km |
| upper-wilson-creek-hydrometric | MCKWIL01H | living-lakes-canada | Y | Y | 2023-09-03 | 2023-06-26 | -0.2 | Amd BY-SA | >1.5 km |
| willie-phillips-creek-hydrometric | UKWIL01H | living-lakes-canada | Y | Y | 2024-01-01 | 2025-10-29 | 1.8 | Amd BY-SA | >1.5 km |
| wolverton-creek-hydrometric | MCKWOL02H | living-lakes-canada | Y | Y | 2024-06-21 | 2025-10-10 | 1.3 | Amd BY-SA | 08NJ152 Wolverton Creek Near Slocan Park (0.1 km, D, 1965-1971) |
| mcdonald-creek-nemcd01 | NEMCD01 | arrow-lakes-environmental-stewardship-society |  | Y | 2015-04-27 | 2017-10-22 | 2.5 | BY-NC-SA | >1.5 km |
| windermere-creek-ekh01 | EKH_01 | certainteed-canada-inc |  | Y | 2017-05-17 | 2023-03-15 | 5.8 | BY-SA | >1.5 km |
| cottonwood-creek-hydrometric | COT_NEL | city-of-nelson |  | Y | 2023-04-21 | 2025-11-27 | 2.6 | BY-SA | 08NJ122 Dietrich Creek At Nelson (0.54 km, D, 1944-1944) |
| arvid-creek-water-quality-and-discharge | arvid_culvert,arvid_gauge | columbia-basin-water-hub |  | Y | 2009-04-30 | 2009-09-24 | 0.4 | BY-NC-SA | >1.5 km |
| birchlands-creek-nabir01 | NABIR01 | columbia-basin-water-hub |  | Y | 2015-04-30 | 2017-10-31 | 2.5 | BY-NC-SA | 08NA029 Birchlands Creek Near Golden (1.43 km, D, 1930-1930) |
| cadden-creek-at-weir-site | caddencreek_weir | columbia-basin-water-hub |  | Y | 1996-09-13 | 2002-12-26 | 6.3 | BY-NC-SA | 08NJ164 Cadden Creek Above Diversions (0.37 km, D, 1982-1998) |
| crawford-creek-njcra01 | NCRA01,NJCRA01 | columbia-basin-water-hub |  | Y | 2015-04-28 | 2017-10-24 | 2.5 | BY-NC-SA | 08NH052 Burden Creek Near Crawford Bay (1.1 km, D, 1928-1975) |
| dewitt-spring | Dewitt Spring  | columbia-basin-water-hub |  | Y | 2005-07-06 | 2006-10-09 | 1.3 | BY-NC-SA | 08NH051 Argenta Creek Near Argenta (1.3 km, D, 1928-1986) |
| grizzly-creek | grizzly | columbia-basin-water-hub |  | Y | 1999-02-09 | 2003-04-19 | 4.2 | BY-NC-SA | >1.5 km |
| kosiancic-spring-water-quality-and-flow | kosiancic_spring | columbia-basin-water-hub |  | Y | 2009-05-07 | 2009-09-28 | 0.4 | BY-NC-SA | >1.5 km |
| mather-creek-ngmat01 | NGMAT01 | columbia-basin-water-hub |  | Y | 2015-04-20 | 2017-10-18 | 2.5 | BY-NC-SA | >1.5 km |
| radcliffe-creek | radcliffe_creek | columbia-basin-water-hub |  | Y | 2009-04-29 | 2009-09-25 | 0.4 | BY-NC-SA | >1.5 km |
| thomas-brook | thomas_brook | columbia-basin-water-hub |  | Y | 1997-06-15 | 2024-12-15 | 27.5 | BY-NC-SA | 08NH051 Argenta Creek Near Argenta (1.3 km, D, 1928-1986) |
| alexander-creek-alx004 | ALX004 | elk-river-alliance |  | Y | 2023-10-05 | 2025-02-28 | 1.4 | BY-NC-SA | >1.5 km |
| alexander-creek-ngalx03 | ALX003,NGALX03 | elk-river-alliance |  | Y | 2014-10-07 | 2023-09-27 | 9.0 | BY-NC-SA | >1.5 km |
| coal-creek-col006 | COL006 | elk-river-alliance |  | Y | 2023-07-06 | 2025-05-27 | 1.9 | BY-NC-SA | 08NK002 Elk River At Fernie (0.89 km, A, 1925-2025) |
| wolverton-creek-monitoring | wolverton_creek | kalesnikoff |  | Y | 2006-12-31 | 2020-10-10 | 13.8 | BY-SA | 08NJ152 Wolverton Creek Near Slocan Park (0.09 km, D, 1965-1971) |
| redfish-creek-water-quality | RF,RU | laird-creek-waterusers |  | Y | 1993-04-01 | 2019-07-31 | 26.3 | BY-SA | 08NJ061 Redfish Creek Near Harrop (0.02 km, A, 1967-2024) |
| drew-creek-dc_01 | DC_01 | quadra-island-salmon-enhancement-society |  | Y | 2023-12-29 | 2024-12-19 | 1.0 | BY-SA | >1.5 km |
| granite-bay-creek-gb_01 | GB_01 | quadra-island-salmon-enhancement-society |  | Y | 2023-12-23 | 2024-12-20 | 1.0 | BY-SA | >1.5 km |
| hyacinthe-creek-hc-01 | HC_01 | quadra-island-salmon-enhancement-society |  | Y | 2023-12-29 | 2024-12-13 | 1.0 | BY-SA | 08HD016 Hyacinthe Creek On Quadra Island (0.15 km, D, 1990-1999) |
| open-bay-creek-ob_01 | GB_01 | quadra-island-salmon-enhancement-society |  | Y | 2023-12-22 | 2024-12-20 | 1.0 | BY-SA | >1.5 km |
| hasty-creek-at-gauge-site |  | red-mountain-residents-association |  | tag only | 1996-09-13 | 2020-02-03 | 23.4 | BY-SA | >1.5 km |
| quartz-creek-flow-and-water-quality-monitoring |  | regional-district-of-central-kootenay |  | tag only | 2020-10-16 | 2021-01-07 | 0.2 | BY-SA | >1.5 km |
| beaver-creek-bubbles | Beaver Creek Bubbles and Wetland,beavercreek_bubbles | rossland-streamkeepers |  | tag only | 2023-11-18 | 2025-01-04 | 1.1 | BY-SA | 08NE106 Beaver Creek At The Mouth (0.13 km, D, 1969-1978) |
| beaver-creek-wetland | beaver_wetland | rossland-streamkeepers |  | tag only | 2024-09-17 | 2025-04-15 | 0.6 | none | >1.5 km |
| topping-creek-stage-flow | Topping Creek Reposition,topping_creek | rossland-streamkeepers |  | tag only | 2022-09-01 | 2025-04-28 | 2.7 | BY-SA | 08NE111 Little Sheep Creek Near Rossland (1.23 km, D, 1971-1974) |
| trail-creek-at-french-street | Trail Creek at French St Warfield,Trail Creek at French St in Warfield | rossland-streamkeepers |  | tag only | 2023-09-24 | 2026-09-26 | 3.0 | BY-SA | 08NE118 Trail Creek At French Street,Trail (0.09 km, D, 1975-1989) |
| sheep-creek | NESHP01,Sheep_lower,Sheep_upper | salmo-watershed-streamkeepers-society |  | Y | 2003-08-29 | 2021-05-31 | 17.8 | BY-SA | >1.5 km |
| trozzo-creek-stream-flow-water-quality-monitoring |  | sifco |  | tag only | 2020-01-01 | 2022-12-31 | 3.0 | BY-SA | 08NJ108 Trozzo Creek Near Appledale (0.09 km, D, 1931-1966) |
| winlaw-creek-stream-flow-water-quality-monitoring |  | sifco |  | tag only | 2020-01-01 | 2022-12-22 | 3.0 | BY-SA | 08NJ120 Winlaw Creek Near Winlaw (0.07 km, D, 1944-1980) |
| bonanza-creek | bonanza | slocan-lake-stewardship-society |  | Y | 1996-06-14 | 2024-12-09 | 28.5 | BY-SA | >1.5 km |
| harris-creek | Harris Creek,Jerome Creek at Weir Site | slocan-lake-stewardship-society |  | Y | 1994-11-26 | 2002-02-12 | 7.2 | BY-SA | >1.5 km |
| silverton-creek-water-quality-monitoring | NJSLV01,silverton_creek | slocan-lake-stewardship-society |  | Y | 2015-04-20 | 2024-12-31 | 9.7 | BY-NC-SA | >1.5 km |
| airy-creek | airy | slocan-river |  | Y | 1996-04-09 | 2003-03-04 | 6.9 | BY-SA | 08NJ042 Airy Creek Near Passmore (0.91 km, D, 1924-1926) |
| elliot-creek-at-weir-site-e225512 | Elliot Creek at Weir Site | slocan-river |  | Y | 1996-08-31 | 2021-12-31 | 25.3 | BY-SA | 08NJ165 Elliott Creek Above Diversions (0.45 km, D, 1982-1994) |
| jerome-creek | jerome_weir | slocan-river |  | Y | 1996-05-20 | 2003-03-04 | 6.8 | BY-SA | 08NJ016 Jerome Creek Near Appledale (0.28 km, D, 1921-1977) |
| lemon-creek | lemon_creek | slocan-river |  | Y | 2020-08-07 | 2021-04-26 | 0.7 | BY-SA | >1.5 km |
| mcfayden-creek | BC EMS ID E225670,mcfayden_creek | slocan-river |  | Y | 1996-04-09 | 1999-10-15 | 3.5 | BY-SA | 08NJ126 Mcfayden Creek Near Vallican (0.29 km, D, 1944-1994) |
| shook-creek-discharge-e255253 | Shook Brook | slocan-river |  | Y | 2000-08-01 | 2003-09-02 | 3.1 | BY-SA | 08NJ054 Grant Creek Near Slocan (0.94 km, D, 1927-1929) |
| summary-reports-for-slocan-valley-water-monitoring-programs |  | slocan-river |  | tag only | 1994-01-01 | 2021-01-01 | 27.0 | BY-SA | 08NJ014 Slocan River At Slocan City (0.31 km, D, 1916-1968) |
| winlaw-creek-njwin01 | NJWIN01,Winlaw Creek | slocan-river |  | Y | 2004-07-21 | 2021-05-26 | 16.8 | BY-SA | 08NJ120 Winlaw Creek Near Winlaw (0.12 km, D, 1944-1980) |

---

## 2. Skeena Knowledge Trust: Skeena Salmon Data Centre

### Assets found

| asset | URL | status |
|---|---|---|
| Skeena Knowledge Trust website | https://www.skeenatrust.ca/ | open |
| skeenaknowledgetrust.ca | https://skeenaknowledgetrust.ca | dead [M: `curl` exit 6, could not resolve host; `dig @1.1.1.1 +short skeenaknowledgetrust.ca A` returned nothing] |
| Skeena Salmon Data Centre (CKAN) | https://data.skeenasalmon.info | open, HTML and API |
| CKAN action API | https://data.skeenasalmon.info/api/3/action/ | open, JSON |
| Skeena Maps Portal | https://maps.skeenasalmon.info (e.g. /maps/705, "WSC Hydrometric Stations") | not fetched |
| Terms of use | https://www.manula.com/manuals/skeena-knowledge-trust/skeena-knowledge-trust/1/en/topic/terms-of-use | blocked [M: HTTP 403, Cloudflare "Sorry, you have been blocked"; WebFetch also 403] |
| Skeena Salmon Program (PSF) | https://skeenasalmonprogram.ca | redirects to https://salmonwatersheds.ca/ [M] (PSF Pacific Salmon Explorer) |

### Platform

- [M] CKAN 2.11.4 (`status_show`), "Skeena Salmon Data Catalogue". 1,421 datasets (`package_search?rows=0`).
- [S] https://data.skeenasalmon.info/about: "a comprehensive, central repository for credible information related to wild Pacific salmonids in the Skeena watershed, including data on salmon populations, habitat, water quality, hydrology, and climatology"; "The Skeena Knowledge Trust maintains and populates the Skeena Salmon Data Centre with datasets and reports using a prioritization process".
- [M] Licences across all 1,421: other-closed 734, notspecified 429, cc-nc 110, CC-BY-NC-ND 76, blank 38, other-open 20, cc-by 5, and a few others. Most holdings cannot be redistributed, or their licence is unstated [I].

### Flow holdings

- [M] 278 datasets match flow words (stream flow, discharge, hydrometric, water level, stage, hydrology, gauge) in their title or tags. Of these, 199 are PDF only and 46 HTML (link) only, and 14 have any tabular resource (CSV, XLS, XLSX, TXT or ZIP). None of the 14 titles describes an original gauged discharge series [M, by reading the 14 titles and descriptions].
- [M] The HTML links from flow datasets point mostly to BC government sites (a100.gov.bc.ca 33, www2.gov.bc.ca 15, catalogue.data.gov.bc.ca 9), the maps portal (14), wateroffice.ec.gc.ca (6) and aqrt.nrs.gov.bc.ca (2).
- **Water Survey of Canada Hydrometric Station Data** (`water-survey-of-canada-hydrometric-stations`, org government-of-canada, no licence id) [M]: an XLSX "List with HYDAT Stations - Skeena Watershed", a KML of WSC water-temperature stations, and per-station XLSX files of WSC water temperature for 08EB003, 08EB004, 08EB005, 08EC001, 08EC003, 08EC004, 08EC013, 08EC014, 08ED001, 08ED002, 08ED004, 08EE003, 08EE004, 08EE005, 08EE013, 08EE020, 08EF001, 08EF005, 08EF006, 08EG012, 08EG018 and 08EG019, plus links to Wateroffice. All of these are HYDAT stations; the dataset holds no discharge of its own [M]. [S] `notes`: "Water temperature is a Water Survey of Canada output, not a product. The data are provided as-is."
- **AQUARIUS WebPortal** (`aquarius-webportal`, BC MoE, notspecified) [S]: "Portal accessing real-time water-related data … Parameters include snow surveys, surface water discharge … The SSDC houses temperature data extracted from the AQUARIUS WebPortal. For all other data, please use the link provided". It holds provincial temperature XLSX files for 08EE0001 (Deep), 08EE0002 (McQuarrie), 08EE0003 (Owens), KIT001 (Kitwanga) and KLO001 (Kloiyah). The provincial IDs (8 characters, e.g. 08EE0002) are not HYDAT IDs [I].
- **Upper Bulkley Watershed Hydrometric Stations** (`upper-bulkley-roundtable`) [M]: links only, to WSC 08EE003, 08EE013 and 08ED002 real-time pages, and to provincial McQuarrie Creek above Hwy 16 Culvert, 08EE0002 (aqrt.nrs.gov.bc.ca).
- **Streamflow in the Skeena Region** (BC MoE, 2001, other-closed) [S]: "contains summary data and datasheets, graphical procedures used to derive hydrological subzones, and procedures for estimating streamflow at ungauged watersheds" (Obedkoff 2001; XLS files `skeenanorthwestobedkoff2001.xls`, `skeenasoutheastobedkoff2001.xls`). **Streamflow Trends in the Skeena Region** (BC MoE, 2014, other-closed) [S]: an XLSX of low-flow and median-flow statistics. Both are summary statistics derived from WSC records, not new gauges [I].
- **Partner and First Nation organizations** [M]: datasets from Gitanyow Fisheries Authority, Skeena Fisheries Commission (`sfc`), Lake Babine Fisheries, Office of the Wet'suwet'en, Wet'suwet'en First Nation, Gitksan Watershed Authorities, Kitselas, Lax Kw'alaams, Morice and Babine Water Monitoring Trusts, Upper Bulkley Roundtable, and SkeenaWild (SWCC). All of their flow-tagged items are PDFs (reports and assessments) or links; none is a discharge time series. One example: [S] "Indigenous Based Climate Monitoring" (Gitksan Watershed Authorities with SFC, other-closed) describes "164 water temperature monitoring sites and 8 air temperature monitoring sites" from 2020, temperature only, with a PDF update and no data file.
- **Discharge or stage:** none original. **QA, licence, period:** not applicable (no series). **Station-list endpoint:** the HYDAT list XLSX (HYDAT only), and the CKAN API for dataset metadata.

---

## 3. DataStream (datastream.org; Atlantic, Great Lakes, Lake Winnipeg, Mackenzie and Pacific hubs)

### Assets found

| asset | URL | status |
|---|---|---|
| DataStream site | https://datastream.org/en-ca/ | open, but robots.txt opts out of AI agents (below) |
| Pacific DataStream (BC and Yukon) | https://pacificdatastream.ca/ | open; explore and custom download are client-side apps on `/api/` (robots: disallow) |
| Mackenzie DataStream | https://mackenziedatastream.ca/ | not fetched beyond robots.txt |
| Public API (OData v4) | https://api.datastream.org/v1/odata/v4/{Metadata,Locations,Observations,Records} | **API key required, given on request** |
| API docs | https://github.com/datastreamapp/api-docs | open |
| Schema and vocabularies | https://github.com/datastreamapp/schema, https://github.com/datastreamapp/wqx | open |
| R client | https://github.com/datastreamapp/datastreamr | open (needs a key) |
| Dataset DOIs | DataCite, prefix 10.25976 | open (`api.datacite.org`) |

### Access

- [M] `curl -sL 'https://api.datastream.org/v1/odata/v4/Locations?$top=1'` returned HTTP 400 `{"message":null}`, and the API root returned HTTP 401.
- [S] api-docs README (https://github.com/datastreamapp/api-docs/blob/HEAD/docs/README.md): "Requires an API key — free, on request"; "Rate limited — 2 requests/sec, no parallel requests"; "Read-only — only `GET` requests are supported". The key is requested through a Google form (`docs.google.com/forms/d/1SjPVeblz2QFaghpiBZPZKOVNKXgw5UMnAtJLJS1tQYI`). **I did not request a key.** [S] OpenAPI (`docs/openapi/openapischema.json`): `securitySchemes.apiKey` in header `x-api-key`.
- [M] robots.txt at https://datastream.org/robots.txt names `anthropic-ai`, `ClaudeBot` and many other AI agents under `Disallow: /` (section "# Prevent AI Scraping"). I read the home page, one dataset page and its `dcat.json` before I saw this, and then stopped fetching datastream.org pages. https://pacificdatastream.ca/robots.txt has no AI block but disallows `/api/` [M].
- [S] Per-dataset pages offer a whole-dataset CSV download, version history with SHA digests, and alternate metadata formats (`/dcat.json`, `/dcat.xml`, `/iso19115.xml`), e.g. https://datastream.org/en-ca/dataset/4c8d3691-99e5-4fa9-ad09-da077baa37c5. The `dcat.json` has `"variableMeasured": []` [M], so characteristic names are not exposed in the metadata. [S] Pacific hub custom download (https://pacificdatastream.ca/en/download): "Download Limit — 200,000 observations per download"; "Need more data? Use the DataStream API".

### Vocabulary: is discharge or stage representable?

- [M] `schemas/data/src/values/CharacteristicName.primary.json` (1,661 accepted names) includes `Discharge, River/Stream`, `Velocity - stream`, `Velocity-discharge`, `Water level`, `Water level (probe)`, `Water level elevation`, and `Water level in well, depth from a reference point`. The legacy list (23,384 names, WQX) adds `Stream flow`, `Stream flow, instantaneous`, `Stream flow, mean. daily`, `Stream stage`, `Gage height`, `Height, gage` and others, which are not accepted for new uploads [I, from the primary/legacy split in `bin/build-values.js`]. Command: `git clone --depth 1` of `datastreamapp/schema`, then a regex over the enum.
- [M] QA status vocabulary (`subset/ResultStatusID.json`): Accepted, Final, Historical, Preliminary, Provisional, Validated, per observation.
- Rating curve: the schema has no rating-curve object; a discharge value is stored as a result [I].

### Licence

- [S] api-docs README: "Many datasets available through this API are published under licences that require attribution … Each citation must include a link to the dataset's DOI". [M] DataCite `rightsList` across all 517 DataStream DOIs (`curl -g 'https://api.datacite.org/dois?query=publisher.name:DataStream&page[size]=1000'`): BC examples are ODC-By 1.0 (e.g. CoSMo, Resilient Waters, Hakai Kwakshua) and ODC-PDDL 1.0 (BC EMS). Redistribution with attribution is allowed under ODC-By [I].

### BC holdings (what could be measured without a key)

- [S] https://pacificdatastream.ca/: "Pacific DataStream at a Glance … 40 Monitoring Groups, 43M Unique Measurements, 9.1K Monitoring Sites"; "If you collect water quality data in British Columbia or the Yukon".
- [M] DataCite lists 517 DataStream DOIs. 41 are BC candidates (a bounding box intersecting BC, or BC named in the text); many records carry no geolocation, so this undercounts [I]. 38 of the 517 have descriptions that mention discharge, stream flow, water level, hydrometric or gauging; the BC ones are:
  - **DFO PSEC Community Stream Monitoring (CoSMo)**, 10.25976/0gvo-9d12, ODC-By, 2019-05-21 to 2026-06-24, version 28.0.0, southwest BC (Howe Sound to Abbotsford). [S] Keywords (dataset page): "Water quality, temperature, conductivity, water level, flow"; "We also use the HOBO U20L water level logger … and the Solinst Levelogger 5 LTC and Zentra ZL6 loggers (which record water level, temperature, and conductivity)". Water level (logger depth), probably unrated; whether `Discharge, River/Stream` rows exist is unknown without the API [I].
  - **Resilient Waters – Temperature Loggers** (10.25976/vdu8-o597) and **– Dissolved Oxygen loggers** (10.25976/347c-9s36), Watershed Watch and Pearson Ecological, Lower Fraser, ODC-By, 2024. [S] "Water quality data including water level, DO and temperature … We also use the HOBO U20L water level logger". Water level only [I].
  - **Elk River Alliance Community-Based Water Monitoring**, 10.25976/138a-8j41, ODC-By, updated 2026-10-26. [S] "part of Elk River Alliance's Community-based Water Monitoring program (CBWM) and Elk River Alliance's Hydrometric program … The Columbia Basin Water Hub has performed a preliminary QA/QC protocol". The same organization's data as on the Water Hub (section 1b); whether discharge is included here is unknown [I].
  - **Analysis of forestry effects on Pacific salmon in Musgamagw Dzawada'enuxw territory**, 10.25976/qcsx-0960, Ecofish, Salmon Coast Society and MDFGS, ODC-By. [S] Water temperature "as part of a broader hydrometric and water quality monitoring network consisting of eleven stations"; the dataset is temperature, and the hydrometric data are not on DataStream [I].
  - **Hakai Institute Kwakshua grab sampling**, 10.25976/ndlp-wb06. [S] "the seven largest watersheds, which are gauged as part of the Kwakshua Watersheds Observatory"; chemistry only on DataStream.
  - **BC Environmental Monitoring System Data**, 10.25976/yhbt-cb49, ODC-PDDL. EMS can carry flow fields, but no count is possible without the API [I].
  - Unmeasured: the number of BC sites or datasets with `Discharge, River/Stream` or `Water level` observations. **Blocked by the API key requirement and the AI-agent opt-out.** One `Locations` or `Observations` query filtered on `CharacteristicName` and `RegionId` (BC) would answer it once a key is held [I].
- Mackenzie DataStream (NWT, Yukon, northern BC and Alberta): [M] the BC-touching Mackenzie datasets in DataCite (Fort Nelson First Nation, PRRD baseline, CIMP projects, GNWT CBM, Lower Mackenzie long-term WQ) are water quality; none mentions discharge. Lake Winnipeg's CBM network [S, DataCite description] uses WSC discharge ("The discharge data is collected by the Water Survey of Canada"), so it is not an independent network.

---

## 4. Other BC discharge networks met along the way

- BC provincial hydrometric network (ENV, AQUARIUS): open CSVs with RISC grades, licence OGL-BC [M: header `Location ID, Location Name, Status, Latitude, Longitude, Date/Time(UTC), Parameter, Value, Unit, Grade`; first row `07FC0001,Osborn River near Doig River First Nation,Active,…,Discharge,0.000,m^3/s,RISC E`], from https://www.env.gov.bc.ca/wsd/data_searches/water/Discharge.csv, with Stage.csv and archives listed at https://catalogue.data.gov.bc.ca/dataset/hydrometric_data. The portal is http://aqrt.nrs.gov.bc.ca/.
- BC Streamflow Inventory hydrometric station view (ArcGIS FeatureServer): https://services6.arcgis.com/ubm4tcTYICKBpist/ArcGIS/rest/services/BC_Streamflow_Inventory_Hydrometric_Station_View/FeatureServer (seen in search results, not fetched).
- Hakai Institute Kwakshua Watersheds Observatory (seven gauged watersheds, Calvert and Hecate islands): data through Hakai's catalogue, not checked; DataStream holds only its chemistry.
- Ecofish, Salmon Coast Society and MDFGS hydrometric network, Broughton Archipelago (eleven stations): only temperature is public (DataStream 10.25976/qcsx-0960).
- DFO PSEC CoSMo water-level loggers, southwest BC: DataStream 10.25976/0gvo-9d12.
- Quadra Island Salmon Enhancement Society creek discharge (Hyacinthe, Drew, Granite Bay, Open Bay): on the Columbia Basin Water Hub.
- BC River Forecast Centre real-time map of WSC stations: https://bcrfc.env.gov.bc.ca/freshet/map_all_wsc.html (WSC data, not a separate network).
- UNBC Northern Hydrometeorology Group, Nechako: temperature on DataStream (10.25976/wjph-rv03); any discharge was not seen.

---

## 5. Station-list endpoints

| source | URL | method | format | fields |
|---|---|---|---|---|
| Columbia Basin Water Hub, all discharge datasets | `https://data.cbwaterhub.ca/api/3/action/package_search?fq=tags:Discharge&rows=1000` | GET [M, 80 results] | JSON (CKAN) | per dataset: `name`, `title`, `organization`, `latitude`, `longitude`, `start_date`, `end_date`, `license_id`, `doi`, `keywords`, `groups`; per resource: `site[]` (`site_id`, `site_name`, `latitude`, `longitude`, `waterbody`, `datum`), `parameter[]` (`parameter`, `parameter_unit`, instrument), `waterhub_grade`, `waterhub_certified`, `data_processing`, `datastore_active`, `id` |
| Columbia Basin Water Hub, CBWMF network | `https://data.cbwaterhub.ca/api/3/action/package_search?fq=groups:columbia-basin-water-monitoring-framework&rows=1000` | GET [M, 108 results] | JSON | as above |
| Columbia Basin Water Hub, every dataset (to filter on `resources[].parameter`) | `https://data.cbwaterhub.ca/api/3/action/package_search?rows=1000` | GET [M, 452 results, 5.0 MB] | JSON | as above |
| Columbia Basin Water Hub, time series per resource | `https://data.cbwaterhub.ca/api/3/action/datastore_search` with body `{"resource_id": "<id>", "limit": 32000, "offset": n}` | **POST only** [M] | JSON | `date_time`, `site_id`, `latitude`, `longitude`, `notes`, `discharge`, `discharge_units`, `water_level`, `water_level_units`, `water_hub_qa_qc` (Bruce Creek) |
| Skeena Salmon Data Centre, dataset metadata | `https://data.skeenasalmon.info/api/3/action/package_search?rows=1000&start=0` (then `start=1000`) | GET [M, 1,421] | JSON (CKAN) | datasets, not stations: `title`, `tags`, `license_id`, `organization`, `resources[].url` |
| Skeena Salmon Data Centre, HYDAT station list | https://data.skeenasalmon.info/dataset/82652715-6b3e-4400-9e53-e5f74834713e/resource/a6788599-01ff-48fd-9c8a-40a78e9f2f55/download/list-hydat-stations-skeena-watershed.xlsx | GET (not opened) | XLSX | HYDAT stations only |
| DataStream monitoring locations | `https://api.datastream.org/v1/odata/v4/Locations` | GET with header `x-api-key` | JSON (OData) | **blocked: key required, given on request**; fields per OpenAPI (Id, Name, Latitude, Longitude, MonitoringLocationType, …) |
| DataStream dataset DOIs | `https://api.datacite.org/dois?query=publisher.name:DataStream&page[size]=1000` (curl `-g`) | GET [M, 517] | JSON (DataCite) | datasets, not stations: DOI, title, description, `rightsList`, `geoLocations` (often empty), landing `url` |
| BC provincial hydrometric (other network) | https://www.env.gov.bc.ca/wsd/data_searches/water/Discharge.csv | GET [M] | CSV | `Location ID, Location Name, Status, Latitude, Longitude, Date/Time(UTC), Parameter, Value, Unit, Grade` (stations derived from distinct `Location ID`) |
