# Station sources beyond HYDAT: which networks hold BC discharge

**Verified:** 2026-10-28 · **Issues:** #123 (component 4 of #118); spawned wet#142 (provincial harvester) and wet#140 (BC Hydro) · **Produced by:** web and API reads of each source (URLs inline), `scripts/station_sources_probe.R` → `data/checks/station_sources_20260717.txt` against HYDAT 2026-07-17, and an org-wide search of NewGraphEnvironment code and installed packages · **Status:** complete for the bar below; sources not accessed are listed with what blocked them

Tags: **[S]** the linked source says it · **[M]** measured (the probe report, or the command named beside it) · **[I]** inferred, not verified.

## The answer

One source passes the bar: **the province's non-integrated hydrometric network**, published as hourly CSVs under the Open Government Licence – British Columbia. 110 of its 211 stations have at least 3 complete Chinook-window years that HYDAT does not hold [M]. Its harvester is wet#142.

Three more hold usable discharge but fail the bar, so they are **test-only**:
- the third-party networks in the BC Water Tool: 35 more stations pass the station test (6 of them at sites that also pass in the provincial files), but no redistribution licence is stated;
- the Columbia Basin Water Hub: 29 stations pass on the period proxy, all preliminary, and a scripted reader needs Living Lakes Canada's consent;
- two USGS gauges inside BC, below the 5-station threshold.

Everything else is **no** (stage only, a copy of HYDAT, no discharge, or not accessible: BC Hydro's archive by request, wet#140; DataStream, key by request) or a **lead** not yet read (the CRD's ECCC partner feed, Rio Tinto, two DataCite records).

All told, 147 stations at 140 distinct sites pass the station test [M]; listings within 0.5 km of each other on the same stream count as one site. The bar's same-site rule is 1 km on the same stream; counting a same-stream HYDAT gauge out to 3 km as the same site, 4 provincial stations drop out (08HA0024, 08LC0006, 08MG0002, 08NM0006), leaving 143 [M, report "Sensitivity"]. For the Bulkley, where #118's pilot sits, the gain is small: Deep Creek (08EE0001) and McQuarrie Creek (08EE0002) have 2 complete window-years each. The Nechako stations 08JC0001–0006 have 3 or 4 [M].

## The bar

Written before any source was checked (#123's plan gate, 2026-10-28). Every source and every asset found is recorded below, accessed or not, so the bar can be revisited. A verdict is a column over the inventory, not a filter on it.

- **harvest**: all four of these:
  - discharge (not only stage), with a maintained rating;
  - a licence that allows use and redistribution of derived values;
  - machine-readable access (API or bulk download);
  - at least 5 BC stations not in HYDAT, each with at least 3 complete years in a Chinook window.

  That is the size of record the Maxan pilot used (`research/station_flow_departure.md`). A window is the migration window (05-01–08-01) or the spawning window (08-01–09-15) of `inst/vignette-data/life_history_bulk.csv`. A complete year is a row that `wet_window_stats()` returns at `min_frac = 0.8`. A count taken from a listed period of record, without daily values, is a proxy tagged [I], and a proxy alone cannot reach harvest.
- **test-only**: discharge that can be used for scoring but fails the redistribution, QA or station tests. We score against it and never publish from it.
- **no**: stage only, no discharge, a duplicate of HYDAT, or no access. A station at a HYDAT site is a duplicate only where its period overlaps HYDAT's there. One that adds years at a discontinued HYDAT site is counted as "same site, new years".

Regulation is recorded for each station (natural, regulated or unknown), because the pilot's donor pool was natural only. The probe can flag regulation only from station names: 10 provincial stations (4 of them passing) and 15 Water Tool listings (none passing) read as regulated by name, and every other station is unknown [M, report "Regulation"]. Establishing it is part of wet#142.

## Inventory

"Passing" means the station test of the bar: a discharge station outside HYDAT's discharge years at its site, with at least 3 complete window-years [M, report "Per network"].

| Source | Asset | Discharge; rating | QA | Licence | Access | Period, stations, not in HYDAT | Verdict |
|---|---|---|---|---|---|---|---|
| Province, non-integrated network | Hourly `Discharge.csv` and 7 archive files, <https://www.env.gov.bc.ca/wsd/data_searches/water/> | Discharge; ratings by the province and its partners (OBWB/ONA, RDN, BCCF, BCER and Treaty 8 Nations, Hakai, City of Surrey), who publish through the provincial database [S, "Also found"] | Grade per hour: Undefined 58.8 %, Unspecified 7.3 %, then RISC A–E/U and older labels; 134 of 211 stations mostly ungraded; no approval field [M]. Impossible values (below) | OGL-BC 2.0 [S] | Bulk CSV, no login [M] | 1998–2026; 211 stations: 153 not in HYDAT, 57 same site with new years, 1 duplicate (08NM0015); **110 passing**, 44 seasonal [M] | **harvest** (wet#142) |
| Province | Catalogue record <https://catalogue.data.gov.bc.ca/dataset/hydrometric_data> | The same files | | OGL-BC 2.0 | Some archive links stale or 404 [M] | | the files above |
| Province | Aquarius WebPortal (aqrt.nrs.gov.bc.ca → bcmoe-prod.aquaticinformatics.net) | The same database | | | Click-through disclaimer, not accepted [M] | Not read | the files above |
| Province, integrated (federal–provincial) stations | HYDAT | WSC | Approved | | | In HYDAT | no (HYDAT) |
| BC Water Tool (Foundry Spatial), third-party networks | <https://nr-bcwat.bcwatertool.ca/api/streamflow/stations>, then `/{id}/csv` | Daily "Preliminary Discharge"; each operator's rating, not stated [M] | Header flag "1 - Quality Checked, 0 - Unchecked Quality" [M] | Headers carry attributions and disclaimers ("submitted as condition of permit", "provided under Memorandum of Understanding"), no redistribution licence [M] | Open JSON API; robots.txt allows all [M] | Passing: CRD 8, Geoscience BC 7, Oil and Gas Industry Network 7, EAO 5, Tofino 4, BCCF 2, BCER 2 = **35**; the 4 Tofino and 2 BCCF stations sit at sites that also pass in the provincial files (08HC000x, 08HB0011, 08HB0008), so 29 are beyond them [M] | **test-only** (no licence) |
| BC Water Tool, BC ENV series | The same API | A copy of the provincial files | | OGL-BC (report JSON) [M] | | 78 BC ENV listings not in the files; 2 of them hold a discharge series (08MH0061, H08KC1015) [M] | no (copy) |
| BC Water Tool, stage-only networks | The same API | DFO 14, Delta 6, Cowichan Valley RD 3, Surrey SCADA 2, Wasa Lake LID 1: no discharge series [M] | | DFO: "personal and public non-commercial" [M] | | | no (stage) |
| Living Lakes Canada, Columbia Basin Water Hub | <https://data.cbwaterhub.ca> (CKAN) | 96 datasets tagged or listing discharge: 76 list a discharge parameter (43 of them in Living Lakes' CBWMF network), and 20 carry only a Discharge tag (stage-only streams, spot measurements, a reports dataset), counted as no discharge [M] | All preliminary; flag column empty [M] | "Amended CC-BY-SA-4.0" (amendment text unreachable), CC BY-NC-SA, CC BY-SA [M] | robots.txt disallows `/api/`; HTML behind an Anubis bot wall [M]. Read once from a stored `package_search` dump | Listed periods only. Of the 76: 54 not in HYDAT, 21 adding years at a HYDAT site, and Redfish Creek a duplicate of active 08NJ061; **29 passing on the proxy [I]** at 29 sites [M] | **test-only**, once Living Lakes agrees to a scripted reader (cbwaterhub@livinglakescanada.ca) |
| Skeena Knowledge Trust | Skeena Salmon Data Centre, <https://data.skeenasalmon.info> (CKAN; the trust's site is skeenatrust.ca) | No original discharge: HYDAT copies, two provincial regional streamflow analyses, links to provincial 08EE0001 and 08EE0002 [M] | | Mostly "other (closed)" [M] | CKAN | | no (no discharge of its own) |
| DataStream hubs | <https://datastream.org>, API `api.datastream.org` | Vocabulary includes discharge and water level [M]; BC holdings mostly water quality, a few water-level loggers (DFO CoSMo, Resilient Waters) [S] | | BC datasets ODC-By or ODC-PDDL [S] | API key given by Google form (not requested); robots.txt opts out ClaudeBot and anthropic-ai [M] | Not measured | no (not accessed; one `Locations` query with a key would answer it) |
| UNBC | Northern Hydrometeorology Group request form <https://nhgdatareq.unbc.ca/>; Zenodo datasets | No discharge in its own releases: 68 request-form sites are water temperature, weather and one level logger [M]. Its only discharge found is two Kiskatinaw series in the BC Water Tool | | Zenodo CC BY 4.0 | By request form | Two Kiskatinaw stations (2010–2012) in the BC Water Tool, 0 passing [M] | no |

### Also found

Networks met along the way, each with what was read and a one-line verdict.

| Source | What was found | Verdict |
|---|---|---|
| Hakai Institute, Calvert and Hecate islands | ERDDAP at <https://catalogue.hakai.org>: 7 stations, 2013–2026, rated, with QL/QC flags, CC BY 4.0 [S/M]. robots.txt disallows `/erddap*?` queries, so the probe reads none (one manual query was made before that was seen). The province carries three of them from 2021 (H08KC0626, 0703, 0844), and the Tool a fourth (H08KC1015) [M]. A published ESSD data package is another route [S] | Covered by the provincial harvest from 2021; the 2013–2020 record needs Hakai's consent (wet#142) |
| USGS gauges in BC | 12355000 Flathead River at Flathead BC adds 2019–2026 beyond HYDAT 08NP001; 12212390 Bertrand Creek adds 2013–2026 beyond 08MH152 [M]. waterservices.usgs.gov serves no robots.txt; public domain | test-only (2 stations) |
| BC Hydro | <https://www.bchydro.com/energy-in-bc/operations/transmission-reservoir-data/hydrometeorologic-data.html> (answers 403 to `curl` on 2026-10-29 UTC; read earlier the same day): 220 stations, 4 days only, not quality-controlled; 7 BC Hydro-operated stations carry discharge [S/M]. The Tool lists 20 BC Hydro stations for 2019–2020; 5 hold a discharge series, none passing [M]. The archive is released by individual request | no (by request; wet#140) |
| Capital Regional District | 12 stations in the Tool (above). An ECCC partner record describes 22 stations through ECCC's partner feed [S, search snippet, <https://donnees.iriu.ca/dataset/0f332c2e-22de-4e48-afc0-11ffc4f3f480>] | lead: the partner feed not read |
| Okanagan Basin Water Board and Okanagan Nation Alliance | An ad hoc network of about 75 third-party stations [S, <https://www.obwb.ca/hydromet/>]; the modernised network publishes "through the provincial web portal" [S] | in the provincial files |
| Regional District of Nanaimo; BCCF Community Flow Monitoring Network | Stations sit in the provincial database (08HB0021, 08HB0007, 08HB0031, 08HB0011) [S/M] | in the provincial files |
| BC Energy Regulator and Treaty 8 First Nations | Stations built "to establish a stage-discharge relationship" [S]; 07FC0001, 10CD0001 and others in the provincial files, more in the Tool [M] | in the provincial files and the Tool |
| DFO VI Hydromets (pacfish.ca) | About 25 Vancouver Island stations, water level and temperature; "should be assumed to be a general guideline" [S] | no (stage) |
| Pacific Salmon Foundation | Flow indicators in the Pacific Salmon Explorer quote WSC stations [S] | no (HYDAT) |
| Metro Vancouver | No public station list or flow data found [M] | not found |
| Rio Tinto (Nechako Reservoir) | Flows reported in season [S, 2015 news snippet]; no current page found. Kenney Dam releases are at WSC 08JA017 [I] | lead |
| Mine and assessment baselines | In consultants' reports (for example eight 2006 stations), not machine-readable [S] | no |
| River Forecast Centre layers | 522 real-time stations; names give a crosswalk for 7 provincial and 11 USGS stations [M]. Licence "Access Only" [S] | no (a crosswalk, not a source) |
| UBC Malcolm Knapp East Creek; USGS Kootenay selenium study | DataCite records (10.6084/m9.figshare.19735849; 10.5066/p13btvbb) [M]; not read | leads |

## How the counts move under a lower bar

The bar's 3 window-years and 5 stations come from the Maxan pilot. Lower bars [M]:
- 250 stations at 238 sites hold a daily record with a complete day and are not HYDAT duplicates.
- 238 of them, at 227 sites, have at least one complete window-year outside HYDAT's discharge years: 185 provincial, 51 Water Tool, 2 USGS.
- 60 of those are seasonal-only: a daily record with no day in December–February. Seasonal gauges serve window statistics but not annual baselines.
- The Water Hub's 75 listed-period discharge datasets that are not duplicates have no daily values to read; 72 list a period holding at least one whole window [I], and 29 pass the station test on that proxy alone. None of the 29 is at a site that passes on daily values.

## Access and robots.txt

The probe reads only what each host allows its agents to read [M, each host's `/robots.txt` on 2026-10-28]:

| Host | robots.txt | What the probe does |
|---|---|---|
| www.env.gov.bc.ca | Disallows four unrelated paths; `/wsd/data_searches/water/` allowed | Downloads the 8 CSVs once |
| nr-bcwat.bcwatertool.ca | Allows all | Reads the station list and each of 391 stations' CSVs once: 389 files, and 2 stations that answer HTTP 500 every time, kept as `.status` files |
| data.cbwaterhub.ca | `Disallow: /api/` for every agent | Fetches nothing. Reads one `package_search` dump taken by hand during the survey |
| catalogue.hakai.org | Disallows `/erddap*?` | Fetches nothing |
| datastream.org | Opts out ClaudeBot and anthropic-ai by name | Fetches nothing |
| waterservices.usgs.gov | None served | Reads daily values for two sites; the OGC API's `items` path, disallowed on its own host, is not used |

Snapshots are cached under the gitignored `data/station_sources/raw/`, and the report carries their md5s. A rerun on the same snapshots gives a byte-identical report.

## What the provincial files and the Water Tool get wrong

These are the publishers' defects, reported as found and not filtered:
- **Units.** Six Vancouver Island stations report 2016–2019 in `l/s` and the rest in `m^3/s`. The probe divides `l/s` by 1000 [M].
- **NaN.** 800,830 hourly values at 121 stations are `NaN`. The probe drops them; a day needs 20 real hours [M].
- **Impossible values, graded.** Oliver Creek in Lake Cowichan (08HA0036) reaches 2.1 million m³/s on RISC C and U hours in 2021–2024. Amor De Cosmos Creek (08HD0003) reaches about 7,000 m³/s on RISC C, U and Unspecified hours in 2021–2025 [M]. Complete days do not depend on magnitude, so the counts stand. A harvester needs a plausibility rule (wet#142). The Fraser at the Big Bar slide (08MD0002 and 08MD0003, up to 9,887 m³/s) is plausible.
- **Two copies that part in 2021.** The Water Tool's daily values for the provincial stations match the files to within 0.1 % on at least 99.7 % of days in every year with data from 1998 to 2020 (none in 2004–2005). From 2021 they match on only 61–92 % of days [M, report "by year"]. One copy has been revised since the other was taken. Which one is unresolved, because the Aquarius portal was not read.
- **Coordinates.** The Water Tool places 08JC0002 and 08JC0006 111.6 km from the province's coordinates, a degree of latitude [M]. It also lists 17 provincial stations under "Regulator – BC Oil and Gas Commission": BCER's own (07FA0001, 07FC0001, 10CD0001 and others) beside Okanagan, Shuswap, Nicola, Kootenay and Lower Mainland stations (08NM00xx, 08LC000x, 08LG0019, 08NJ0001, 08MH0062) that are not the regulator's by name or place [M, report; I for ownership]. Take location and owner from the province.

## Already fetched by a New Graph package?

No (2026-10-28). The installed NewGraphEnvironment packages export only federal fetchers: `ngr::ngr_hyd_q_daily()`, `ngr::ngr_hyd_realtime()` (`tidyhydat::realtime_ws()`) and wet's `wet_station_*()`. A code search of the organisation finds these sources only cited, never fetched.
