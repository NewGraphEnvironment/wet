# Station sources beyond HYDAT: which networks hold BC discharge

**Verified:** 2026-10-29; regulation per station 2026-11-24; the chinook boxes 2026-11-18; the provincial files in wet 2026-11-22; the Water Tool's gauges in wet 2026-11-23 · **Issues:** #123 (component 4 of #118); spawned wet#142 (provincial harvester), wet#144 (the Water Tool's third-party networks) and wet#140 (BC Hydro); #167 (the chinook boxes); #179 (move 8, which landed #142 and spawned #190, #191, #192); #195 (move 13, which landed #144 and the chain to a provincial record); #196 (move 14, regulation per station, carrying #191; spawned #202) · **Produced by:** web and API reads of each source (URLs inline), `scripts/station_sources_probe.R` → `data/checks/station_sources_20260717.txt` against HYDAT 2026-07-17, an org-wide search of NewGraphEnvironment code and installed packages; for the provincial files in wet, `scripts/station_sources_bound.R` and `scripts/station_sources_harvest.R` (reports beside the survey's); for the Water Tool's gauges, `data-raw/station_sources_bcwatertool.R` and the same harvest report · **Status:** complete for the bar below; sources not accessed are listed with what blocked them

Tags: **[S]** the linked source says it · **[M]** measured (the probe report, or the command named beside it) · **[I]** inferred, not verified.

## The answer

Two sources are harvest candidates:
- **the province's non-integrated hydrometric network**, published as hourly CSVs under the Open Government Licence – British Columbia. 110 of its 211 stations have at least 3 complete Chinook-window years that HYDAT does not hold [M]. Its harvester, wet#142, landed in #179: `wet_station_daily()` reads it (below, "The provincial files in wet").
- **the third-party networks the BC Water Tool serves**: 35 more stations pass the station test, 6 of them at sites that also pass in the provincial files [M]. They pass the terms, access and station tests; each operator's rating is not stated. Their harvester, wet#144, landed in #195: `wet_station_daily()` reads 46 of them, and continues seven provincial records with the Tool's earlier years (below, "The Water Tool's gauges in wet").

The **Columbia Basin Water Hub** is a lead: its discharge datasets carry Creative Commons BY-SA licences (18 of the 76 non-commercial, and 39 "amended" with the amendment not stated) [M], and 29 of its stations pass on the period proxy, but the daily values that would settle the station test have not been read: robots.txt disallows the API, and each dataset's CSV download sits behind a bot check, so a scripted reader needs Living Lakes Canada's consent. Two **USGS** gauges inside BC are test-only, below the 5-station threshold.

Everything else is **no** (stage only, a copy of HYDAT, no discharge, or not accessible: BC Hydro's archive by request, wet#140; DataStream, key by request) or a **lead** not yet read (the CRD's ECCC partner feed, Rio Tinto, two DataCite records).

All told, 147 stations at 140 distinct sites pass the station test [M]; listings within 0.5 km of each other on the same stream count as one site. The bar's same-site rule is 1 km on the same stream; counting a same-stream HYDAT gauge out to 3 km as the same site, 4 provincial stations drop out (08HA0024, 08LC0006, 08MG0002, 08NM0006), leaving 143 [M, report "Sensitivity"]. For the Bulkley, where #118's pilot sits, the gain is small: Deep Creek (08EE0001) and McQuarrie Creek (08EE0002) have 2 complete window-years each. The Nechako stations 08JC0001–0006 have 3 or 4 [M].

## The bar

Written before any source was checked (#123's plan gate, 2026-10-28), and revised once (2026-10-29, below). Every source and every asset found is recorded below, accessed or not, so the bar can be revisited. A verdict is a column over the inventory, not a filter on it.

- **harvest**: all four of these:
  - discharge (not only stage), with a maintained rating;
  - terms that do not forbid use and redistribution of derived values, with the source credited;
  - machine-readable access (API or bulk download);
  - at least 5 BC stations not in HYDAT, each with at least 3 complete years in a Chinook window. Stations are counted per publisher's feed: the Water Tool's seven third-party networks, served by one API, count together.

  The terms test first read "a licence that allows use and redistribution of derived values". It was revised on 2026-10-29, once the survey had read the Water Tool's headers (389 of 391 stations; 2 answer HTTP 500: 08HB0020, a BC ENV listing, and 08NM0072, a provincial-file station): the passing networks' headers name their source and disclaim liability for the data and derived information, and none restricts use. That moved those networks from test-only to harvest, with each operator's rating to confirm. Whatever terms come with a dataset carry over to what is published from it: attribution always, and ShareAlike or non-commercial terms where a licence carries them.

  The station threshold is the size of record the Maxan pilot used (`research/station_flow_departure.md`). A window is the migration window (05-01–08-01) or the spawning window (08-01–09-15) of `inst/vignette-data/life_history_bulk.csv`. A complete year is a row that `wet_window_stats()` returns at `min_frac = 0.8`. A count taken from a listed period of record, without daily values, is a proxy tagged [I], and a proxy alone cannot reach harvest.
- **test-only**: discharge that can be used for scoring but fails the terms, QA or station tests. We score against it and never publish from it.
- **no**: stage only, no discharge, a duplicate of HYDAT, or no access. A station at a HYDAT site is a duplicate only where its period overlaps HYDAT's there. One that adds years at a discontinued HYDAT site is counted as "same site, new years".

Regulation is recorded for each station (natural, regulated or unknown), because the pilot's donor pool was natural only. The probe can flag regulation only from station names: 10 provincial stations (4 of them passing) and 15 Water Tool listings (none passing) read as regulated by name, and every other station is unknown [M, report "Regulation"]. Since #196 every station wet reads carries a status from what sits upstream of it (below, "Regulation per non-HYDAT station").

## Inventory

"Passing" means the station test of the bar: a discharge station outside HYDAT's discharge years at its site, with at least 3 complete window-years [M, report "Per network"].

| Source | Asset | Discharge; rating | QA | Licence | Access | Period, stations, not in HYDAT | Verdict |
|---|---|---|---|---|---|---|---|
| Province, non-integrated network | Hourly `Discharge.csv` and 7 archive files, <https://www.env.gov.bc.ca/wsd/data_searches/water/> | Discharge; ratings by the province and its partners (OBWB/ONA, RDN, BCCF, BCER and Treaty 8 Nations, Hakai, City of Surrey), who publish through the provincial database [S, "Also found"] | Grade per hour: Undefined 58.8 %, Unspecified 7.3 %, then RISC A–E/U and older labels; 134 of 211 stations mostly ungraded; no approval field [M]. Impossible values (below) | OGL-BC 2.0 [S] | Bulk CSV, no login [M] | 1998–2026; 211 stations: 153 not in HYDAT, 57 same site with new years, 1 duplicate (08NM0015); **110 passing**, 44 seasonal [M] | **harvest** (wet#142) |
| Province | Catalogue record <https://catalogue.data.gov.bc.ca/dataset/hydrometric_data> | The same files | | OGL-BC 2.0 | Some archive links stale or 404 [M] | | the files above |
| Province | Aquarius WebPortal (aqrt.nrs.gov.bc.ca → bcmoe-prod.aquaticinformatics.net) | The same database | | | Click-through disclaimer, not accepted [M] | Not read | the files above |
| Province, integrated (federal–provincial) stations | HYDAT | WSC | Approved | | | In HYDAT | no (HYDAT) |
| BC Water Tool (Foundry Spatial), third-party networks | <https://nr-bcwat.bcwatertool.ca/api/streamflow/stations>, then `/{id}/csv` | Daily "Preliminary Discharge"; each operator's rating, not stated [M] | Header flag "1 - Quality Checked, 0 - Unchecked Quality" [M] | Headers name the source ("submitted as condition of permit", "provided under Memorandum of Understanding") and disclaim liability for the data and derived information; none restricts use [M, report "headers whose licence text restricts use"] | Open JSON API; robots.txt allows all [M] | Passing: CRD 8, Geoscience BC 7, Oil and Gas Industry Network 7, EAO 5, Tofino 4, BCCF 2, BCER 2 = **35**; the 4 Tofino and 2 BCCF stations sit at sites that also pass in the provincial files (08HC000x, 08HB0011, 08HB0008), so 29 are beyond them [M] | **harvested** (wet#144, #195), rating not stated |
| BC Water Tool, BC ENV series | The same API | A copy of the provincial files | | OGL-BC (report JSON) [M] | | 78 BC ENV listings not in the files; 2 of them hold a discharge series (08MH0061, H08KC1015) [M] | no (copy) |
| BC Water Tool, stage-only networks | The same API | DFO 14, Delta 6, Cowichan Valley RD 3, Surrey SCADA 2, Wasa Lake LID 1: no discharge series [M] | | DFO: "personal and public non-commercial" [M] | | | no (stage) |
| Living Lakes Canada, Columbia Basin Water Hub | <https://data.cbwaterhub.ca> (CKAN) | 96 datasets tagged or listing discharge: 76 list a discharge parameter (43 of them in Living Lakes' CBWMF network), and 20 carry only a Discharge tag (stage-only streams, spot measurements, a reports dataset), counted as no discharge [M] | All preliminary; flag column empty [M] | Of the 76: "Amended CC-BY-SA-4.0" 39 (amendment text not in the dataset records), CC BY-SA 19, CC BY-NC-SA 18 [M, report "Licences of the Water Hub's discharge datasets"] | robots.txt disallows `/api/`; HTML pages and each dataset's CSV download (all 76 discharge datasets have one, by the resource URLs in the stored dump) sit behind a bot check [M]. Read once from a stored `package_search` dump | Listed periods only. Of the 76: 54 not in HYDAT, 21 adding years at a HYDAT site, and Redfish Creek a duplicate of active 08NJ061; **29 passing on the proxy [I]** at 29 sites [M] | **lead**: daily values need a scripted reader, which needs Living Lakes Canada's consent (cbwaterhub@livinglakescanada.ca) |
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

## At the chinook sites' boxes

Counted on 2026-11-18 (#167's plan gate) from the report's "Every station read" table against each
donor box in `scripts/departure_sites.csv` [M]. No Water Tool third-party station falls in any box.
The provincial stations with daily discharge:

| site (box) | stations | complete window-years |
|---|---|---|
| Maxan, Gosnell (the two boxes overlap) | 08EE0001 (same site as HYDAT 08EE022), 08EE0002 | 2 each |
| Swift | none | |
| Naver | 08JC0001, 08JC0002, 08JC0003, 08JC0005, 08JC0006; 08JC0018, 08JC0020, 08MC0001 | 4, 3, 4, 3, 4; 2 each |

Every one of these records runs 2011–2021, so none has a year inside 1981–2010. A carried departure
needs donors with at least 10 baseline years and extension donors with at least 30
(`scripts/departure_site.R`), so these networks add no donor at the four sites; at most the five
Naver stations with 3–4 years could join that box's short-record test set. Their value is
province-wide (#118), and the harvest moved to its own backlog move, #179.

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
| data.cbwaterhub.ca | `Disallow: /api/` for every agent (and three unrelated paths); the CSV downloads are allowed but sit behind a bot check | Fetches nothing. Reads one `package_search` dump taken by hand during the survey |
| catalogue.hakai.org | Disallows `/erddap*?` | Fetches nothing |
| datastream.org | Opts out ClaudeBot and anthropic-ai by name | Fetches nothing |
| waterservices.usgs.gov | None served | Reads daily values for two sites; the OGC API's `items` path, disallowed on its own host, is not used |

Snapshots are cached under the gitignored `data/station_sources/raw/`, and the report carries their md5s. A rerun on the same snapshots gives a byte-identical report.

## Data notes: the provincial files and the Water Tool

Reported as found, not filtered:
- **Units.** Six Vancouver Island stations report 2016–2019 in `l/s` and the rest in `m^3/s`. The probe divides `l/s` by 1000 [M].
- **NaN.** 800,830 hourly values at 121 stations are `NaN`. The probe drops them; a day needs 20 real hours [M].
- **Impossible values, graded.** Oliver Creek in Lake Cowichan (08HA0036) reaches 2.1 million m³/s on RISC C and U hours in 2021–2024. Amor De Cosmos Creek (08HD0003) reaches about 7,000 m³/s on RISC C, U and Unspecified hours in 2021–2025 [M]. Complete days do not depend on magnitude, so the counts stand. A harvester needs a plausibility rule (wet#142). The Fraser at the Big Bar slide (08MD0002 and 08MD0003, up to 9,887 m³/s) is plausible.
- **Two copies that part in 2021.** The Water Tool's daily values for the provincial stations match the files to within 0.1 % on at least 99.7 % of days in every year with data from 1998 to 2020 (none in 2004–2005). From 2021 they match on only 61–92 % of days [M, report "by year"]. One copy has been revised since the other was taken. Which one is unresolved, because the Aquarius portal was not read.
- **Coordinates.** The Water Tool places 08JC0002 and 08JC0006 111.6 km from the province's coordinates, a degree of latitude [M]. It also lists 17 provincial stations under "Regulator – BC Oil and Gas Commission": BCER's own (07FA0001, 07FC0001, 10CD0001 and others) beside Okanagan, Shuswap, Nicola, Kootenay and Lower Mainland stations (08NM00xx, 08LC000x, 08LG0019, 08NJ0001, 08MH0062) that are not the regulator's by name or place [M, report; I for ownership]. Where a station is in both, the provincial files are the source for its location and owner.

## The provincial files in wet

What `wet_station_daily(sources = "bcenv")` reads, and how it stands against the survey [M, `data/checks/station_sources_harvest_20261028.txt` unless noted]:

- **One pinned snapshot**, the survey's (2026-10-28), held to md5s tracked in `inst/extdata/station_sources/bcenv_20261028.csv` and backed up privately: the province rewrites `Discharge.csv` in place, so the snapshot cannot be fetched again. A newer snapshot is a new pin.
- **Days.** A day is a local-standard-time day with at least 20 hours: UTC−8, or UTC−7 in drainage areas 07 and 10, so a provincial day means what a HYDAT day means. The East Kootenay and Creston also keep Mountain time and are read at UTC−8, an hour off. The 14 Elk Valley stations near Elkford and Sparwood (08NK0001–08NK0014, mine-site gauges, 2018–2020) sit there, but no day of theirs is affected, because the files hold one value a day for them [M, the cached snapshot]. `Unusable` and `NaN` hours are left out; an hour two files hold is taken from the newer.
- **Status.** A day with any `Undefined`, `Unspecified` or `Unverified` hour is `"unchecked"` (66.3 % of shipped days), a fully graded day `"provisional"`; none is `"approved"`, since the files carry no approval. `frac_provisional` counts both. The files carry 16 grades; a grade not among them is refused, not read as graded.
- **Once-a-day stations.** 15 stations, the 14 Elk Valley gauges among them, hold one value per day (stamped 08:00 UTC) rather than hourly values, so the 20-hour rule gives them no complete day and `wet_station_daily()` returns nothing for them, as in the survey. Reading a daily value as a day is still open.
- **Identity.** A provincial station keeps its own number. `wet_station_list()` names the HYDAT station at the same site (1 km, same stream name: 58 stations, the survey's 57 same-site and 1 duplicate), so a caller can join the two; no HYDAT record is continued across numbers. Seven provincial records are continued backwards by a Water Tool gauge at the site (below).
- **The survey reproduced.** Under the survey's own rules (UTC days, no bound) the reader returns the probe's 215,300 station-days exactly (flows within 1e-12 relative; duckdb sums a day's hours in no fixed order, so the last bits vary), all 211 of its provincial station rows, and its 110 passing stations.
- **What the shipped rules move.** Local-standard-time days give 215,168 complete days; the bound drops 208 of them, leaving 214,960; no day is negative. One station's count moves: 08NM0005 has 11 window-years outside HYDAT instead of 12, and still passes. 110 stations pass.
- **Donors.** 52 provincial stations are natural under #196's rule (below, "Regulation per non-HYDAT station"), 101 regulated and 58 unknown [M, `data/checks/station_regulation_20261028.txt`]. `wet_station_select()` stays HYDAT-only, so they are records and held-out tests until a donor pool reads `wet_station_list()`'s `regulation` (wet#202).
- **Still open.** Natural stations as donors (wet#202); which copy is current for 2021–2026 (wet#190); Hakai's 2013–2020 record (wet#192, which the chain in "The Water Tool's gauges in wet" will carry); the 15 once-a-day stations (above); the four passing stations 1.4–1.9 km from a same-stream HYDAT gauge (above), which the 1 km match keeps as new sites.

## The Water Tool's gauges in wet

What `wet_station_daily(sources = "bcwatertool")` reads, and how it stands against the survey [M, `data/checks/station_sources_harvest_20261028.txt` unless noted]:

- **One pinned snapshot**, the survey's (2026-10-28): the station list and all 391 per-station entries (389 CSVs, 2 HTTP 500 records), held to md5s tracked in `inst/extdata/station_sources/bcwatertool_20261028.csv`, cached per machine and backed up privately with every entry, the Tool's copy of the provincial stations among them, which wet#190's comparison reads. The Tool serves only its current values, so a newer read is a new pin.
- **How to fetch one of your own.** The station list is `https://nr-bcwat.bcwatertool.ca/api/streamflow/stations` (GeoJSON) and a listing's daily values `https://nr-bcwat.bcwatertool.ca/api/streamflow/stations/<id>/csv`, `<id>` being the list's numeric `id` (`scripts/station_sources_probe.R` reads both; robots.txt allows them). Comparing each file's md5 with the tracked manifest tells a fresh read from the pinned one; `data-raw/station_sources_bcwatertool.R` says how a read becomes a pin.
- **Terms.** Each CSV's header names its source and disclaims liability; wet gives the first part as the station's `credit` and states no licence. One file in the backup, Fisheries and Oceans' New Westminster listing (19197, stage only, never read), states "personal and public non-commercial use only. Reproduction for commercial redistribution is prohibited"; the backup is private and nothing republishes it.
- **What is read.** Of 9,427 listings, 391 have a record outside Water Survey of Canada once each `nid` keeps its first listing (Geoscience BC's `HRB5454`, id 47738, is left behind the industry network's). Left out: the Tool's copy of the provincial network (271 listings, among them 08MH0061 and H08KC1015, which hold discharge the provincial files lack and are not read, #195 decision 3), 17 provincial stations it files under the Regulator, and 50 third-party listings with no discharge series. 53 remain: **46 stations of their own** (Capital Regional District 8, Oil and Gas Industry Network 10, Geoscience BC 7, EAO 7, Regulator 6, BC Hydro 5 (two of them HYDAT duplicates), UNBC 2, BCCF 1) and 7 at provincial sites.
- **A provincial record continued.** The seven Tool listings within 0.5 km of a provincial station on the same stream (the survey's same-site set) are not stations of their own: their days before the provincial record begins come back under the provincial number, `source = "bcwatertool"`. The record begins on the first day the provincial files hold any usable hour of the station, complete or not (the registry's `continues_before`), not on its first complete day: Tofino's four listings are the same gauges, and their one day "before" the province's first complete day is the province's own partial first day (10–15 hours), so they add nothing. BC Conservation Foundation's three add 2012–2015 to Grandon Creek (08HB0011, 1,181 days), Rosewall Creek (08HB0008, 1,081) and the Tsolum River (08HB0012, 856), whose provincial records begin on 2021-09-30. The cut is stored in the registry, so it is the same whichever sources are asked. A second publisher's earlier record for any provincial station (Hakai's, wet#192) is a row of the same kind.
- **Days and status.** One row of a CSV is one day. The survey matched the Tool's copy of the provincial stations to the province's UTC days, so a Tool day may be a UTC day rather than a local-standard-time one [I]. Quality-checked days (QA 1) are `"provisional"`, unchecked days (QA 0) `"unchecked"`: 22.1 % of the 53,821 shipped days. Every unit is m³/s and every QA 0 or 1; anything else is refused.
- **The bound** (registered below, before it was applied): no day is negative; it drops 149 of 53,970 days, 145 of them at four Capital Regional District creeks on Vancouver Island (`08H`): Colwood Creek's 70, most flat at 45.22 m³/s on a median of 0.13, Cecelia Creek's 65, Hospital Creek's 9 and Bowker Creek's 1; the other 4 are at Stewart Creek (07FB0001). The sub-drainages read are `07F` 11, `08D` 7, `08G` 1, `08H` 18, `08M` 2, `10C` 8, `10D` 5, `10F` 1; the farthest nearest HYDAT station is 127 km away (the Petitot River gauge, `ogc_1004`).
- **The survey reproduced.** Under its own rules the reader returns its 53,970 Tool daily rows exactly, all 103 third-party station rows, its 14 network lines, its 35 passing stations and its seven shared-site listings.
- **Donors.** 23 of the Tool's 46 stations are natural under #196's rule, 9 regulated and 14 unknown [M, same report]; like the provincial stations, they are records and held-out tests until a donor pool reads the status (wet#202).
- **Still open.** Each operator's rating, which no file states; natural stations as donors (wet#202).

## The plausibility bound for the provincial files

Registered on 2026-11-22, before the bound was measured (#179, decision 3). The provincial files hold flows no stream could carry (above), so `wet_station_daily()` drops a provincial day whose flow exceeds a bound measured on HYDAT:

- **Population.** Every BC station in HYDAT 20260717 (`STATIONS.PROV_TERR_STATE_LOC = 'BC'`) with at least 3,650 daily flows in `DLY_FLOWS`, regulated or not. The bound is set on all of them; the same statistic over the natural stations alone (no `STN_REGULATION` row with `REGULATED = 1`) is reported beside it and decides nothing.
- **Statistic.** For each station, the ratio of its largest daily flow to the median of its positive daily flows. The bound is the largest such ratio in the population: no provincial day may sit further above its station's typical flow than any day Water Survey of Canada has published in BC. The report lists the ten stations with the largest ratios, so a single station that sets the bound is visible.
- **Applied.** A provincial day (a complete day as `wet_bcenv_daily()` reads it) is dropped when its flow exceeds the bound times the median of that station's positive complete-day flows over the whole snapshot. A negative daily flow is dropped. A station with no positive flow has no bound.
- **Expected catches**, stated before measuring: the bound must drop every day above 1,000 m³/s at Oliver Creek in Lake Cowichan (08HA0036) and Amor De Cosmos Creek at Hwy 19 (08HD0003), and must drop no day of the Fraser upstream of and below the Big Bar slide (08MD0002, 08MD0003). If it fails any of these, the rule fails: no bound ships, and the choice goes back to the owner.

Produced by `scripts/station_sources_bound.R` → `data/checks/station_sources_bound_20260717.txt`.

**Measured on 2026-11-22: the rule failed one expected catch** [M, first run of the report]. The bound came out at 2,490.71, set by the Pouce Coupe River below Henderson Creek (07FD007) alone; the next largest ratio is 1,346.56 (07FC003). It drops Oliver Creek's 24 impossible days and 4 days at 08HB0022, and no Big Bar day, but none of Amor De Cosmos Creek's 51 days above 1,000 m³/s: on a median of 2.5 m³/s their ratios start at 402. That record is not a few spikes: its 90th percentile is 101 m³/s. As registered, no bound shipped, and the choice went to the owner.

**Re-registered on 2026-11-22, by the owner's choice, before it was applied to the provincial stations.** The same statistic, taken per WSC sub-drainage:

- **Population and statistic.** As above, grouped by sub-drainage, the first three characters of the HYDAT station number (`08H`, Vancouver Island). Each sub-drainage's bound is the largest ratio among its stations. A sub-drainage with fewer than 10 such stations takes the province-wide bound, 2,490.71. Natural-only bounds are reported beside each and decide nothing.
- **Applied.** A provincial station takes the bound of its own sub-drainage, the first three characters of its number once any leading letters are dropped (`H08KC0626` is `08K`); a number of another shape takes the province-wide bound. Otherwise as above.
- **Expected catches**: the same four.
- **What was seen first.** This form was chosen after the HYDAT sub-drainage maxima had been computed (`08H`'s is 268.07, over 82 stations) and Amor De Cosmos Creek's smallest ratio above 1,000 m³/s (402) was known, so its catch is not an independent test of the rule. Its effect on the other provincial stations had not been computed; the report lists every station it drops days at.

## The plausibility bound for the Water Tool's gauges

Registered on 2026-11-23, before it was applied or measured on any Tool series (#195, the owner's decision 2). The Tool's third-party gauges take the provincial rule's per-sub-drainage bound (above), with the sub-drainage taken from where the gauge sits, since their numbers (`HRB3142`, `ogc_1002`, `UC 5`) carry none:

- **The sub-drainage of a gauge** is that of the HYDAT station nearest to it: every station in HYDAT 20260717's `STATIONS` with coordinates (any province, any data type, active or discontinued), by straight-line distance in BC Albers, its number's first three characters. The registry stores it, the nearest station and its distance, so a gauge far from any HYDAT station, or near a divide, is visible.
- **Applied.** As for the provincial stations: a Tool day is dropped when its flow exceeds its sub-drainage's bound (`wet_bcenv_bound`; `.default`, 2,490.71, for a sub-drainage without one of its own) times the median of the listing's positive daily flows over its whole pinned record. A negative daily flow is dropped. A listing with no positive flow has no bound. The seven listings that continue a provincial station's record are bounded the same way, over their own record, before their days are cut.
- **Expected catches:** none stated. The harvest report lists every station and day the bound drops.
- **What was seen first.** The HYDAT sub-drainage maxima (`08H` 268.07) and the bound's effect on the provincial stations were known; no Tool series had been read under any bound, and no Tool station's ratio had been computed.

## Regulation per non-HYDAT station

Registered on 2026-11-24, before any station was snapped or placed (#196, carrying #191; the owner's decisions at #196's plan gate). The rule's authority is the header and functions of `scripts/station_regulation_rule.R`, committed with this section and its tests; `scripts/station_regulation.R` records that commit and refuses to run if the file has changed since.

- **Population.** Every station `wet_station_list()` lists: the 211 provincial stations and the Water Tool's 46 own listings (the 7 listings that continue a provincial record are that provincial station). One status per station for the year as a whole: the licence layer states no season of use.
- **Registers and their terms** [S, catalogue records read 2026-11-24]. BC's dam register, `WHSE_WATER_MANAGEMENT.WRIS_DAMS_PUBLIC_SVW` (record `bc-dams`), under the Open Government Licence – British Columbia. Water rights licences, `WHSE_WATER_MANAGEMENT.WLS_WATER_RIGHTS_LICENCES_SV` (record `water-rights-licences-public`), whose licence is "Access Only": the province's copyright page says such material is "access only and reproduction is not permitted without written permission". So wet ships only what it computes from the licences (each station's status, its reason, and the licensed use and storage as shares of flow), never a licence record. The record's state is "pending archive"; its successor, `WLS_WATER_RIGHTS_LICENCES_SP` (record `water-rights-licences`, also "Access Only"), is not served on the public WFS (an empty `DescribeFeatureType`, 2026-11-24) [M], so the `_SV` layer (118,717 rows that day) stays the source until it is withdrawn. Reservoirs enter through the dam register and storage licences; FWA man-made waterbodies upstream are reported and decide nothing.
- **Snap.** `fwa_indexpoint()` (1 km, 5 candidates, as `wet_station_snap()`). A candidate is accepted when it is on the stream the station's name gives (the survey's `stream_of()` fold on both names), and, where the station's drainage area is known, its upstream area is within 10 % of it; nearest first, then the smaller segment id. A station that names no candidate's stream but states an area takes `wet_station_snap()`'s own area pick. Otherwise it is not snapped. The area is the Tool file's `Drainage Area` header, in km² [M: Beatton River at Tommy Lakes Road reads 1,852.0 against HYDAT 07FC008's 1,851.7, 0.04 km away], or HYDAT's gross area at the station's HYDAT site.
- **Regulated** when the name says so; or an active dam in the register's "Regulated" or "Regulated - Part 3 Exempt" classes sits upstream on the network (a dam-safety class, by size and consequence of failure, not a statement about flow); or licensed consumptive use or licensed storage upstream is at least 10 % of the mean annual flow (#53's thresholds, licences "Current" in the snapshot, #53's row rules). The mean annual flow is wet's published `pick` at the snapped segment, since most of these records are short or seasonal.
- **Unknown** when not snapped; or, with no dam and use and storage under 10 %, when part of the upstream area lies outside BC (a stream upstream crosses the Alberta, US or Yukon–NWT border line), a power licence draws upstream, a licence that states no volume draws upstream (Amendment 2, below), or the segment has no published flow. **Natural** otherwise. Licensed use and storage count surface points of diversion only, as #53 counted them.
- **Outside check.** At the provincial stations at a HYDAT site, the status beside HYDAT's regulation flag there. It decides nothing.
- **What was seen first.** The code values of #53's cached snapshot (2026-10-07), which became the rule's closed code sets; the Tool's areas against HYDAT; the registries' counts. No new snapshot had been taken.
- **Amendment 1, 2026-11-24, by the owner's choice, before any station was placed.** The first run stopped on #53's check that every POD a shared licence quantity is split over is counted: one licence splits its quantity over its diversion point and a rediversion point, which is never counted, so the diversion point carried half. A shared quantity is now split over the PODs that are not rediversions, since a rediversion moves water already diverted. No status exists under the registered version.
- **Amendment 2, 2026-11-24, by the owner's choice, after review and before any status shipped.** 1,646 Current surface licence rows that would count state no volume: 880 "Total Flow" (the whole flow of the source) and 766 a zero or missing quantity. They cannot enter the shares, so a station below one could read natural with its licensed use unknown; such a station is now unknown unless something else regulates it. The same review found the script counting groundwater points of diversion in the shares, against the rule's "surface"; that was corrected in the script. Under the registered rule with Amendment 1 alone, 92 stations had read natural; 17 of them are unknown under Amendment 2, and the surface correction makes 2 regulated stations natural (licensed use 44.5 % and 18.3 % with groundwater, 3.8 % and 9.1 % without).
- **Amendment 3, 2026-11-24, by the owner's choice, after review and before any status shipped.** #53's stream-position test dropped a point on the station's own reach that indexed even 1 mm below it, so a licence indexed exactly at a gauge (West Line Creek, 08NK0006: licensed use 36 % of its flow) did not count. A point on the station's own line within 100 m below it now counts as upstream: closer than a gauge's and a point of diversion's positions can be told apart. It moves 08NK0006 and 08HC0004 (a regulating dam 44 m below) from natural to regulated.

**Measured on 2026-11-24** [M, `data/checks/station_regulation_20261028.txt`, WFS snapshot of that day: 118,717 licence rows, 95,422 of them Current; 2,485 dams, 1,838 of them regulating for the rule]:

- **Snap.** 204 of the 257 stations are placed: 119 on their named stream with no stated area, 73 on their named stream within 10 % of a stated area, 12 by area alone. Of the 53 not placed, 43 name no candidate's stream within 1 km and state no area, 8 are on their named stream outside 10 % of their area, and 2 have no stream within 1 km.
- **Status.** 75 natural (52 provincial, 23 Tool), 110 regulated, 72 unknown. Of the regulated, 90 have a regulating dam upstream, 53 licensed use of at least 10 %, 44 licensed storage of at least 10 % (reasons overlap), and 11 are regulated by name, as the registries had them. Of the unknown, 49 are not placed, 18 have a licence with no volume upstream, 4 drain from Alberta (the Doig, the Osborn and two Petitot stations), and 2 have a power licence upstream and nothing that regulates.
- **Against HYDAT's flag**, at the 58 provincial stations at a HYDAT site (decides nothing): of HYDAT's 30 natural sites the rule calls 11 natural, 10 regulated and 9 unknown; of its 28 regulated sites, 21 regulated, 4 natural and 3 unknown. The 4 HYDAT calls regulated and the rule natural (Deep Creek, Shorts Creek twice, Whiteman Creek) have no regulating dam and licensed use of 1 to 4 % of their flow.
- **Reproducible.** A rerun from the cached snapshot, snap, placement and flows writes the report and the status file byte for byte.

## Already fetched by a New Graph package?

No (2026-10-28). The installed NewGraphEnvironment packages export only federal fetchers: `ngr::ngr_hyd_q_daily()`, `ngr::ngr_hyd_realtime()` (`tidyhydat::realtime_ws()`) and wet's `wet_station_*()`. A code search of the organisation finds these sources only cited, never fetched.
