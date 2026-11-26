# Station sources beyond HYDAT: which networks hold BC discharge

**Verified:** 2026-11-25 · **Issues:** #123 (the survey); #167; #179 (the provincial files, #142); #195 (the Water Tool's gauges, #144); #196 (regulation, #191); #211 (donors, #202); #210 (#190, #192, #207) · **Produced by:** the survey, `scripts/station_sources_probe.R` → `data/checks/station_sources_20260717.txt`; the other scripts and reports each section names · **Status:** current; how each count and rule was reached is in the archive READMEs of #123, #179, #195 and #196 ("History moved from research/station_sources.md").

Tags: **[S]** the linked source says it · **[M]** measured (the report or command named) · **[I]** inferred, not verified.

## The answer

wet reads three sources beyond HYDAT, all through `wet_station_daily()` and `wet_station_list()`:
- **the province's non-integrated network** (OGL-BC): 211 stations, 110 passing the station test below [M];
- **the BC Water Tool's third-party gauges**: 46 stations of their own (29 passing), and seven listings continuing provincial records (six more passing on their own years) [M];
- **Hakai Institute's published package**, continuing three Calvert and Hecate island provincial records with 2014–2019 [M].

The **Columbia Basin Water Hub** is a lead (29 stations pass on listed periods; a scripted reader needs Living Lakes Canada's consent). Two **USGS** gauges are test-only. The rest are **no** or unread **leads** (the inventory).

147 stations at 140 sites pass the station test [M]; listings within 0.5 km on the same stream count as one site. Counting a same-stream HYDAT gauge out to 3 km as the same site drops 4 provincial stations (08HA0024, 08LC0006, 08MG0002, 08NM0006) [M, report "Sensitivity"].

## The bar

Set at #123's plan gate (2026-10-28) before any source was checked; its terms test revised once (2026-10-29). A verdict is a column over the inventory, not a filter on it.

- **harvest**: discharge with a maintained rating; terms that do not forbid use and redistribution of derived values with the source credited (whatever terms a dataset carries, attribution, ShareAlike or non-commercial, carry over to what is published from it); machine-readable access; at least 5 BC stations not in HYDAT, each with at least 3 complete years in a Chinook window, counted per publisher's feed (the Water Tool's networks together).
- **test-only**: discharge usable for scoring that fails the terms, QA or station tests; scored against, never published.
- **no**: stage only, no discharge, a HYDAT duplicate (a station at a HYDAT site whose period overlaps HYDAT's there; one adding years at a discontinued site is "same site, new years"), or no access.

A window is the migration (05-01–08-01) or spawning (08-01–09-15) window of `inst/vignette-data/life_history_bulk.csv`; a complete year is a row `wet_window_stats()` returns at `min_frac = 0.8`. The 3-year and 5-station thresholds are the Maxan pilot's record size (`research/station_flow_departure.md`). A count from a listed period, without daily values, is a proxy [I] and cannot reach harvest.

## Inventory

"Passing" is the station test: a discharge station outside HYDAT's discharge years at its site, with at least 3 complete window-years [M, report "Per network"].

| Source | Asset | Discharge; rating | QA | Licence | Access | Period, stations, not in HYDAT | Verdict |
|---|---|---|---|---|---|---|---|
| Province, non-integrated network | Hourly `Discharge.csv` and 7 archive files, <https://www.env.gov.bc.ca/wsd/data_searches/water/> | Discharge; ratings by the province and its partners (OBWB/ONA, RDN, BCCF, BCER and Treaty 8 Nations, Hakai, City of Surrey), who publish through the provincial database [S] | Grade per hour: Undefined 58.8 %, Unspecified 7.3 %, then RISC A–E/U and older labels; 134 of 211 stations mostly ungraded; no approval field [M] | OGL-BC 2.0 [S] | Bulk CSV, no login [M] | 1998–2026; 211 stations: 153 not in HYDAT, 57 same site with new years, 1 duplicate (08NM0015); **110 passing**, 44 seasonal [M] | **harvested** (#142) |
| Province | Catalogue record <https://catalogue.data.gov.bc.ca/dataset/hydrometric_data> | The same files | | OGL-BC 2.0 | Some archive links stale or 404 [M] | | the files above |
| Province | Aquarius WebPortal (aqrt.nrs.gov.bc.ca → bcmoe-prod.aquaticinformatics.net) | The same database, 15-minute points with grade and approval [M] | | A disclaimer that restricts no use [S] | Export by request URL after the disclaimer [M] | 10 stations read (#190) | a check on the files (below) |
| Province, integrated (federal–provincial) stations | HYDAT | WSC | Approved | | | In HYDAT | no (HYDAT) |
| BC Water Tool (Foundry Spatial), third-party networks | <https://nr-bcwat.bcwatertool.ca/api/streamflow/stations>, then `/{id}/csv` | Daily "Preliminary Discharge"; each operator's rating, not stated [M] | Header flag "1 - Quality Checked, 0 - Unchecked Quality" [M] | Headers name the source and disclaim liability; none restricts use [M] | Open JSON API; robots.txt allows all [M] | Passing: CRD 8, Geoscience BC 7, Oil and Gas Industry Network 7, EAO 5, Tofino 4, BCCF 2, BCER 2 = **35**; the Tofino and BCCF ones sit at provincial sites [M] | **harvested** (#144) |
| BC Water Tool, BC ENV series | The same API | A copy of the provincial files, which parts from them in 2021 (below) | | OGL-BC [M] | | 78 BC ENV listings not in the files; 2 hold discharge (08MH0061, H08KC1015) [M] | no (copy) |
| BC Water Tool, stage-only networks | The same API | DFO 14, Delta 6, Cowichan Valley RD 3, Surrey SCADA 2, Wasa Lake LID 1: no discharge series [M] | | DFO: "personal and public non-commercial" [M] | | | no (stage) |
| Hakai Institute, Calvert and Hecate islands | Published package, DOI 10.21966/J99C-9C14 (GitHub, Git LFS); ERDDAP at <https://catalogue.hakai.org> | Hourly discharge with uncertainty, 7 watersheds [S] | First-tier flags and processing levels [S] | CC-BY 4.0 [S] | Package: open; ERDDAP: robots.txt disallows queries [M] | Package 2014–2019; ERDDAP 2013–2026; three continue provincial stations (below) | **harvested** (package, #192); ERDDAP needs Hakai's consent |
| Living Lakes Canada, Columbia Basin Water Hub | <https://data.cbwaterhub.ca> (CKAN) | 76 datasets list a discharge parameter (43 in Living Lakes' CBWMF network); 20 more carry only a Discharge tag, counted as none [M] | All preliminary; flag column empty [M] | "Amended CC-BY-SA-4.0" 39 (amendment not stated), CC BY-SA 19, CC BY-NC-SA 18 [M] | robots.txt disallows `/api/`; downloads behind a bot check [M]; read once from a stored `package_search` dump | Listed periods only: 54 not in HYDAT, 21 adding years at a HYDAT site, 1 duplicate; **29 passing on the proxy [I]** [M] | **lead** (needs Living Lakes Canada's consent) |
| Skeena Knowledge Trust | Skeena Salmon Data Centre, <https://data.skeenasalmon.info> | No original discharge: HYDAT copies, two regional analyses, links to 08EE0001 and 08EE0002 [M] | | Mostly "other (closed)" [M] | CKAN | | no |
| DataStream hubs | <https://datastream.org>, API `api.datastream.org` | BC holdings mostly water quality, a few level loggers [S] | | ODC-By or ODC-PDDL [S] | Key by form (not requested); robots.txt opts out ClaudeBot and anthropic-ai [M] | Not measured | no (not accessed) |
| UNBC | Northern Hydrometeorology Group request form; Zenodo | No discharge in its own releases [M]; two Kiskatinaw series in the Water Tool | | Zenodo CC BY 4.0 | By request | 0 passing [M] | no |

### Also found

| Source | What was found | Verdict |
|---|---|---|
| USGS gauges in BC | 12355000 Flathead River at Flathead BC adds 2019–2026 beyond 08NP001; 12212390 Bertrand Creek adds 2013–2026 beyond 08MH152 [M]. No robots.txt; public domain | test-only (2 stations) |
| BC Hydro | <https://www.bchydro.com/energy-in-bc/operations/transmission-reservoir-data/hydrometeorologic-data.html>: 220 stations, 4 days, not quality-controlled; 7 carry discharge [S/M]. The Tool's 20 BC Hydro stations (2019–2020): 5 with discharge, none passing [M]. The archive is by request | no (wet#140) |
| Capital Regional District | 12 stations in the Tool. An ECCC partner record describes 22 through ECCC's partner feed [S, search snippet, <https://donnees.iriu.ca/dataset/0f332c2e-22de-4e48-afc0-11ffc4f3f480>] | lead |
| Okanagan Basin Water Board and Okanagan Nation Alliance | About 75 third-party stations; the modernised network publishes "through the provincial web portal" [S, <https://www.obwb.ca/hydromet/>] | in the provincial files |
| Regional District of Nanaimo; BCCF Community Flow Monitoring Network | In the provincial database (08HB0021, 08HB0007, 08HB0031, 08HB0011) [S/M] | in the provincial files |
| BC Energy Regulator and Treaty 8 First Nations | Stations built "to establish a stage-discharge relationship" [S]; 07FC0001, 10CD0001 and others in the files, more in the Tool [M] | in the files and the Tool |
| DFO VI Hydromets (pacfish.ca) | About 25 Vancouver Island stations, level and temperature [S] | no (stage) |
| Pacific Salmon Foundation | Flow indicators quote WSC stations [S] | no (HYDAT) |
| Metro Vancouver | No public station list or flow data found [M] | not found |
| Rio Tinto (Nechako Reservoir) | Flows reported in season [S, 2015 news snippet]; Kenney Dam releases are at WSC 08JA017 [I] | lead |
| Mine and assessment baselines | Consultants' reports, not machine-readable [S] | no |
| River Forecast Centre layers | 522 real-time stations, a crosswalk for 7 provincial and 11 USGS stations [M]; "Access Only" [S] | no (a crosswalk) |
| UBC Malcolm Knapp East Creek; USGS Kootenay selenium study | DataCite records 10.6084/m9.figshare.19735849, 10.5066/p13btvbb [M]; not read | leads |

## At the chinook sites' boxes

Counted on 2026-11-18 (#167) from the survey's "Every station read" table against each donor box in `scripts/departure_sites.csv` [M]. No Water Tool or Hakai station falls in any box.

| site (box) | provincial stations | complete window-years |
|---|---|---|
| Maxan, Gosnell (the boxes overlap) | 08EE0001 (same site as HYDAT 08EE022), 08EE0002 | 2 each |
| Swift | none | |
| Naver | 08JC0001, 08JC0002, 08JC0003, 08JC0005, 08JC0006; 08JC0018, 08JC0020, 08MC0001 | 4, 3, 4, 3, 4; 2 each |

All run 2011–2021, with no year in 1981–2010, so they add no donor at the four sites (a carried departure needs donors with 10 baseline years). Tested province-wide on an estimated baseline (#211), the natural ones made carried departures worse, so they stay out of every donor pool (`research/chinook_sites.md`, "Natural stations outside HYDAT as donors").

## How the counts move under a lower bar

[M] except the proxy row:

| bar | stations | sites |
|---|---|---|
| a daily record with a complete day, not a HYDAT duplicate | 250 | 238 |
| at least one complete window-year outside HYDAT (185 provincial, 51 Water Tool, 2 USGS) | 238 | 227 |
| of those, seasonal only (no day in December–February: window statistics, not annual baselines) | 60 | |
| Water Hub listed periods holding a whole window [I] / passing on the proxy | 72 / 29 | none at a site passing on daily values |

## Access and robots.txt

Each host is read only where its robots.txt allows [M, read 2026-10-28 unless dated]:

| Host | robots.txt | What wet reads |
|---|---|---|
| www.env.gov.bc.ca | Four unrelated paths disallowed | The 8 CSVs, once |
| nr-bcwat.bcwatertool.ca | Allows all | The station list and 391 stations' CSVs, once (2 answer HTTP 500, kept as `.status` files) |
| bcmoe-prod.aquaticinformatics.net | Empty (2026-11-25) | 10 stations' `Discharge.Working` series, once (#190) |
| media.githubusercontent.com (Hakai's package) | None served (2026-11-25); github.com's own disallows `/raw/`, unused | One pinned file, once per machine |
| catalogue.hakai.org | Disallows `/erddap*?` and `/api/` | Nothing (one ERDDAP query in the survey and one `/api/` read on 2026-11-25 were made before the rules were seen) |
| data.cbwaterhub.ca | `Disallow: /api/`; downloads behind a bot check | Nothing; one `package_search` dump taken by hand |
| datastream.org | Opts out ClaudeBot and anthropic-ai | Nothing |
| waterservices.usgs.gov | None served | Daily values for two sites |

Raw copies sit under the gitignored `data/station_sources/raw/`; each report carries their md5s and reruns byte for byte from them.

## Data notes: the provincial files and the Water Tool

Reported as found, not filtered [M, the survey report unless noted]:
- **Units and NaN.** Six Vancouver Island stations report 2016–2019 in `l/s`, divided by 1000. 800,830 hourly values at 121 stations are `NaN` and dropped.
- **Impossible values, graded.** Oliver Creek in Lake Cowichan (08HA0036) reaches 2.1 million m³/s on RISC C and U hours (2021–2024), Amor De Cosmos Creek (08HD0003) about 7,000 m³/s (2021–2025); hence the plausibility bound (below). The Fraser at the Big Bar slide (08MD0002, 08MD0003, up to 9,887 m³/s) is plausible.
- **Two copies that part in 2021.** The Water Tool's copy of the provincial stations matches the files within 0.1 % on at least 99.7 % of days a year to 2020, and on 61–92 % from 2021. The province's Aquarius portal settles it [M, `data/checks/station_sources_portal_20261125.txt`, stations picked before any portal value was read]: from October 2021 to May 2026 the portal's hours equal the pinned files' (99.9–100 % a month), and the Tool's copy matches the portal on 38–83 % of days a year from 2022. For January–September 2021 the portal agrees with neither (0.1–24 % of hours), its series revised since both copies were taken [I]; from June 2026, 80–91 % (provisional revisions) [I]. A newer pin would bring both in (#232).
- **Coordinates and owners.** The Tool places 08JC0002 and 08JC0006 a degree of latitude from the province's coordinates, and files 17 provincial stations under the Regulator, many not the regulator's by name or place [M; I for ownership]; the provincial files are the source for both.

## The provincial files in wet

What `wet_station_daily(sources = "bcenv")` reads [M, `data/checks/station_sources_harvest_20261028.txt` unless noted]:

- **One pinned snapshot**, the survey's (2026-10-28), held to md5s in `inst/extdata/station_sources/bcenv_20261028.csv` and backed up privately: the province rewrites `Discharge.csv` in place, so a newer read is a new pin.
- **Days.** A local-standard-time day of at least 20 hours: UTC−8, or UTC−7 in drainage areas 07 and 10, as a HYDAT day. The East Kootenay and Creston keep Mountain time and are read at UTC−8; the Elk Valley gauges there hold one value a day, so no day moves [M]. `Unusable` and `NaN` hours are left out.
- **Status.** A day with any `Undefined`, `Unspecified` or `Unverified` hour is `"unchecked"` (66.3 % of days), a fully graded day `"provisional"`; none is `"approved"`. A grade outside the 16 the files carry is refused.
- **Once-a-day stations.** 15 stations (the Elk Valley gauges among them) hold one value per day, so the 20-hour rule gives them no day; reading a daily value as a day is open.
- **Identity.** A provincial station keeps its own number; `wet_station_list()` names the HYDAT station at its site (1 km, same stream name: 58 stations). Ten have a second publisher's listing continuing them (seven Tool, three Hakai); six of those add earlier days (below).
- **Against the survey.** Under its rules (UTC days, no bound) the reader returns its 215,300 station-days, 211 station rows and 110 passing stations. Under the shipped rules, 215,168 complete days, 208 dropped by the bound; 110 still pass.
- **Donors.** 52 natural, 101 regulated, 58 unknown (below). `wet_station_select()` stays HYDAT-only: none holds 10 years of 1981–2010, and on an estimated baseline they made carried departures worse (#211; `research/chinook_sites.md`).
- **Still open.** The revised water year 2021 and the months after the snapshot (#232); the once-a-day stations; the four passing stations 1.4–1.9 km from a same-stream HYDAT gauge, which the 1 km match keeps as new sites.

## The Water Tool's gauges in wet

What `wet_station_daily(sources = "bcwatertool")` reads [M, the harvest report]:

- **One pinned snapshot**, the survey's (2026-10-28): the list and all 391 entries, held to md5s in `inst/extdata/station_sources/bcwatertool_20261028.csv` and backed up privately. The Tool serves only current values, so a newer read is a new pin, told apart by its md5s.
- **Terms.** Each header names its source and disclaims liability; wet gives the first part as `credit` and states no licence.
- **What is read.** Of 391 listings outside Water Survey of Canada, the Tool's copy of the provincial network (271), 17 provincial stations under the Regulator and 50 without discharge are left out: **46 stations of their own** (CRD 8, Oil and Gas Industry Network 10, Geoscience BC 7, EAO 7, Regulator 6, BC Hydro 5, UNBC 2, BCCF 1) and 7 at provincial sites remain.
- **A provincial record continued.** A second publisher's listing within 0.5 km of a provincial station on the same stream continues it: its days before the provincial record begins come back under the provincial number, with its own `source`. The record begins on the first day the provincial files hold any usable hour (`continues_before`), so the same gauge never replaces the province's partial first day: Tofino's four add nothing; BC Conservation Foundation's three add 2012–2015 to 08HB0011, 08HB0008 and 08HB0012. The cut is stored in a registry; two publishers continuing one station is refused.
- **Days and status.** One CSV row is one day, likely a UTC day, as the survey matched them to the province's [I]. QA 1 is `"provisional"`, QA 0 `"unchecked"` (22.1 % of 53,821 days); any other unit or QA is refused.
- **The bound** (below) drops 149 of 53,970 days, 145 at four CRD creeks. Under the survey's rules the reader returns its 53,970 rows, 103 station rows and 35 passing stations.
- **Donors.** 23 of the 46 are natural, 9 regulated, 14 unknown; records and held-out tests, as the provincial stations.

## The plausibility bound for the provincial files

Re-registered on 2026-11-22 by the owner's choice, before it was applied to the provincial stations (#179, decision 3). A first, province-wide form, registered the same day before it was measured, failed one of its expected catches; its text and measurement are in #179's archive README.

- **Population and statistic.** Every BC station in HYDAT 20260717 (`STATIONS.PROV_TERR_STATE_LOC = 'BC'`) with at least 3,650 daily flows, regulated or not; per station, the ratio of its largest daily flow to the median of its positive daily flows. Grouped by WSC sub-drainage (the first three characters of the station number), each sub-drainage's bound is the largest ratio among its stations; one with fewer than 10 such stations takes the province-wide largest, 2,490.71. Natural-only bounds are reported beside each and decide nothing.
- **Applied.** A provincial station takes its own sub-drainage's bound (its number's first three characters once leading letters are dropped: `H08KC0626` is `08K`); a number of another shape takes the province-wide one. A complete day is dropped when its flow exceeds the bound times the median of the station's positive complete-day flows over the snapshot; a negative day is dropped; a station with no positive flow has no bound.
- **Expected catches**: every day above 1,000 m³/s at Oliver Creek in Lake Cowichan (08HA0036) and Amor De Cosmos Creek at Hwy 19 (08HD0003) dropped, and no day of the Fraser at Big Bar (08MD0002, 08MD0003).
- **What was seen first.** The HYDAT sub-drainage maxima (`08H` 268.07, over 82 stations) and Amor De Cosmos Creek's smallest ratio above 1,000 m³/s (402), so its catch is not an independent test. The effect on other provincial stations had not been computed; the report lists every station it drops days at.

Produced by `scripts/station_sources_bound.R` → `data/checks/station_sources_bound_20260717.txt`, which holds `wet_bcenv_bound` to it.

## The plausibility bound for the Water Tool's gauges

Registered on 2026-11-23, before it was applied or measured on any Tool series (#195, decision 2). The Tool's gauges take the provincial per-sub-drainage bound, their numbers (`HRB3142`, `ogc_1002`) carrying no sub-drainage:

- **A gauge's sub-drainage** is that of the nearest HYDAT 20260717 station with coordinates (any province, any data type, active or not), by straight-line distance in BC Albers. The registry stores it, the station and its distance.
- **Applied** as for the provincial stations, over the listing's whole pinned record (`.default` for a sub-drainage without its own bound); the seven continuing listings are bounded over their own record before their days are cut.
- **Expected catches:** none stated. **What was seen first:** the HYDAT maxima and the bound's effect on the provincial stations; no Tool series under any bound.

## The Hakai package in wet

Registered on 2026-11-25, before any Hakai day was counted (#192). Hakai Institute's package (Korver, Haughton, Floyd and Giesbrecht, DOI 10.21966/J99C-9C14; CC-BY 4.0; GitHub `HakaiInstitute/essd2021-hydromet-datapackage`, commit 8318556d2baf) holds hourly discharge at seven watersheds for water years 2014–2019 [S]; 626, 703 and 844 are provincial stations H08KC0626, H08KC0703 and H08KC0844. 2019-10-01 to 2021-09-30 waits on Hakai, whose ERDDAP robots.txt disallows queries (a draft ask, unsent, is in #210's archive).

- **What is read.** `2013-2019_Discharge_Hourly.csv` (sha256 the LFS pointer's), rows `WTS626`, `WTS703`, `WTS844`, column `Qrate` (m³/s, the mean of an hour's twelve five-minute values) [S], kept only at the tracked md5.
- **Time.** `Datetime` is the end of its hour in Pacific Standard Time, as the README and data dictionary state [S]; the trailing `Z` the file writes is not read as UTC. Three checks agree [M, the cached copy]: rain at `SSN626` raises discharge at `WTS626` fastest two hours later (correlation 0.37), not ten; the package's hourly radiation peaks at the hour ending 13:00 (solar noon at 128° W is about 12:30 PST); every watershed's last row is `2019-10-01T00:00`, the end of water year 2019 in PST.
- **Days.** Day *d* holds the hours labelled *d* 01:00 to *d*+1 00:00; it needs at least 20 hours, and its flow is their mean. A negative day is dropped.
- **Flags.** The first-tier codes are read from the head of `Qflag` (`AV`, or a mixed hour such as `AV:EV:10/12 AV:2/12 EV`): `AV` accepted, `EV` estimated, `SVC` suspicious value caution, `SVD` suspicious value discard, `MV` missing value [S, README; Korver et al. 2022, §3.2], and `BR`, defined nowhere in the package and seen only in mixed hours beside `EV`. An `SVD` hour is dropped; `MV` appears only in mixed hours that still carry a value. Any other code, or none, is refused.
- **Status.** A day whose every hour is `AV` alone at `Qlevel` 2 (quality controlled; 1 is raw, 3 derived [S]) is `"approved"`, meaning Hakai accepted it, not Water Survey of Canada; every other day is `"provisional"`.
- **The bound.** `wet_bcenv_bound["08K"]` (205.26) times the median of the watershed's positive complete days in the package.
- **Identity.** A watershed continues its provincial station only where the watershed number is the station number's and its coordinates lie within 0.5 km of the station's; the pin refuses otherwise, and refuses a station the Tool already continues. Its days come back under the provincial number with `source = "hakai"`, cut as above ("A provincial record continued").
- **Left out.** Watersheds 693, 708, 819 and 1015, which would be stations of their own needing regulation rows (#233).
- **Expected catches:** none stated; the Hakai report lists the days before the cut, the complete days, the days the bound drops and the status shares.

**Measured on 2026-11-25** [M, `data/checks/station_sources_hakai_8318556d2baf.txt`]: no hour `SVD`, no day negative or above the bound. The package adds 1,885, 1,883 and 1,846 days (from August or September 2014 to 2019-09-30), 93.4–98.5 % `"approved"`. Complete Chinook-window years rise from 5 to 10, 2 to 7 (H08KC0703 now passes the station test) and 4 to 9. The three are `unknown` for regulation (no accepted snap), so not yet donors.

## Regulation per non-HYDAT station

Registered on 2026-11-24, before any station was snapped or placed (#196, carrying #191), with three amendments the same day before any status shipped. The rule's authority is the header and functions of `scripts/station_regulation_rule.R` (Amendments 1–3 included); `scripts/station_regulation.R` records its registering commit and refuses to run if it or `scripts/station_sources_lib.R` has changed.

- **What it says.** One status per station `wet_station_list()` lists (211 provincial, the Tool's 46), for the year as a whole. A station is snapped with `fwa_indexpoint()` on the stream its name gives, within 10 % of a stated drainage area, or by area alone. It is **regulated** when its name says so, an active dam of the register's regulated classes sits upstream (a dam-safety class, not a statement about flow), or licensed consumptive use or storage upstream is at least 10 % of the published `pick` mean annual flow (#53's thresholds and row rules, surface points of diversion of Current licences, a point on the station's own line within 100 m below it counting as upstream). It is **unknown** when not snapped, part of its basin lies outside BC, a power licence or a licence stating no volume draws upstream, or its segment has no published flow; otherwise **natural**.
- **Registers and terms** [S, 2026-11-24]. BC's dam register (OGL-BC) and water rights licences (`WLS_WATER_RIGHTS_LICENCES_SV`, "Access Only"), so wet ships only what it computes from the licences, never a licence record.
- **Amendments.** 1: a shared licence quantity is split over the points of diversion that are not rediversions. 2: a station below a licence stating no volume is unknown unless something else regulates it (and groundwater points were removed from the shares, as the rule says surface). 3: the 100 m margin below a station on its own line.

**Measured on 2026-11-24** [M, `data/checks/station_regulation_20261028.txt`]: 204 of 257 stations placed. 75 natural (52 provincial, 23 Tool), 110 regulated (90 with a regulating dam upstream, 53 licensed use, 44 storage, 11 by name; reasons overlap), 72 unknown (49 not placed, 18 below a licence stating no volume, 4 draining from Alberta, 2 below a power licence). Beside HYDAT's flag at 58 shared sites (deciding nothing): of HYDAT's 30 natural sites, 11 natural, 10 regulated, 9 unknown.

## Already fetched by a New Graph package?

No (2026-10-28). The installed NewGraphEnvironment packages export only federal fetchers (`ngr::ngr_hyd_q_daily()`, `ngr::ngr_hyd_realtime()`, wet's `wet_station_*()`); a code search of the organisation finds these sources only cited, never fetched.
