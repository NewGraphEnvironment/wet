# Findings — Station source survey (#123)

## Issue context

**If we do it:** every network beyond HYDAT that holds BC discharge is known for what it is: discharge or stage only, rated or not, its QA, licence, access, period and stations, and which ones are worth a harvester. **If we never do:** donor and test gauges stay the HYDAT set, and the biggest accuracy lever in #118 is never pulled.

Component 4 of #118. Research only: no harvester is written here. Each source that passes gets its own issue.

## Problem

More gauges is the biggest accuracy lever for departures at ungauged sites: short and seasonal records serve as local donors and as held-out tests. HYDAT, ECCC real-time and the provisional archive wet already reads (`wet_station_daily()`) are federal. Nothing is known yet about the others.

## Candidates, none checked

- Living Lakes Canada's Columbia Basin Water Hub
- The Skeena Knowledge Trust
- Mackenzie DataStream and the other DataStream hubs (thought to be mostly water quality)
- The province's own hydrometric stations (which may already be in HYDAT under the federal–provincial agreement; check, do not assume)
- UNBC's stations

## For each source, establish

1. Discharge or stage only; whether a rating curve stands behind the discharge, and who maintains it.
2. QA: approved, provisional, or none; flags.
3. Licence, and whether redistribution is allowed.
4. Access: API, bulk download, or a request; machine-readable or not.
5. Period, station count, record lengths, and how many stations are not in HYDAT.
6. Whether a New Graph package already fetches it: enumerate the installed packages' exports and search the organisation's code before anything is written.

## Outputs

`research/station_sources.md` with one row per source and a verdict: harvest (file an issue), test-only, or no, with the reason. Its header carries the date checked and what was read.

Relates to #118, #25.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| duckdb `read_csv` refuses the provincial files (CRLF line ends; byte 0x96 in one station name) | Read a temp copy with 0x96 made `-`, `strict_mode = false`, and hold each file's row count to its line count |
| Tool against province read NA, then 91.9 % agreement instead of 99.9 % | 800,830 NaN hourly values (121 stations) made means NaN: dropped and counted. The remaining gap is real and starts in 2021 (below) |
| A "values above 2,000 m³/s" profile counted the NaN hours again | duckdb orders NaN above every number, so `NaN > 2000` is true; test `NOT isnan(value)` first |

## Phase 1: prior work (2026-10-28)

**Installed NGE packages** (the 19 whose DESCRIPTION URL or BugReports names NewGraphEnvironment, public and private). Exports matching `hyd|flow|disch|station|gauge|gage|stream|water|level|datastream|hakai|aquarius`: only federal fetchers. `ngr::ngr_hyd_q_daily()` and `ngr::ngr_hyd_realtime()` (the latter is `tidyhydat::realtime_ws()`), and wet's own `wet_station_*`. No package fetches any candidate source.

**Org code search** (`gh api search/code`, `org:NewGraphEnvironment`, default branches):
- `skeenaknowledgetrust`: references only (restoration_wedzin_kwa_2024 cites the SKT "UBR Water Temperature Monitoring Dashboard Draft" on Tableau Public; xciter test fixtures).
- `aquarius` / `aqrt`: one hit, `restoration_wedzin_kwa_2024/data/inputs_extracted/skt_geoserver_info.csv` (2025-03-11). SKT's GeoNode serves `geonode:hydrometric_stns_flnrod_nwbc_2018_09_20`, "Provincial hydrometric and water quality station locations from the Aquarius Time-Series database sourced from http://aqrt.nrs.gov.bc.ca/. Layer created by EGIS on 2018-09-20." This is a lead for the provincial network, not a fetcher.
- `datastream`: a report in one of our private repos, and a closed issue there, proposed (did not build) reading Pacific DataStream's API (`api.datastream.org/v1/odata/v4`) for Skeena water temperature. Also one mention in a private planning note.
- `hakai`: one mention in a private planning note; no code.
- `columbiabasinwaterhub`, `"water hub"`: none.
- `realtime_ws`: ngr, water-temp-bc and wet only (federal).
- `unbc hydrometric`: reporting-template background and methods prose, and bibliographies; no code.
- Local grep across the local checkouts of our repos (hosts `datastream.org`, `columbiabasinwaterhub`, `skeenaknowledgetrust`, `aqrt.nrs`, `aquarius`, `hakai.org`, `bchydro`, `okanagan basin water board`): the same files, nothing more.

**Open issues and PRs** in wet, water-temp-bc, ngr, fresh and one more of our repos (`hydrometric OR datastream OR hakai OR "living lakes" OR skeena OR unbc OR gauge`): no harvester work in flight. Adjacent: wet#124 (CABIN spot flows), wet#126 (second-region pilots, which would use any new gauges); downstream work on life-stage flow is in progress elsewhere.

**Verdict for point 6, every source:** no NGE package or org code fetches any of them.

## BC Hydro (user, 2026-10-28)

BC Hydro holds a large hydrometric record, released only by individual request. Pointer issue filed: wet#140. It goes into the survey as "by request" with what is publicly known.

## Phase 2: part B delivered (2026-10-28)

`sources-b.md` (research agent B): Columbia Basin Water Hub, Skeena Salmon Data Centre, DataStream, plus networks met along the way. Spot-checked by the parent: the Water Hub robots.txt (`User-agent: *`, `Disallow: /api/`, `Crawl-Delay: 10`); datastream.org robots.txt naming `anthropic-ai` and `ClaudeBot`; the provincial `Discharge.csv` header and first row; and HYDAT 20260717 periods for 08NA060 (Q 1965–1977), 08NJ061 (Q 1967–2024, active) and 08EE018 (Q 1974–1979). All agree with the file.

**Decision (agent, mechanism): the probe respects robots.txt.** The Water Hub disallows `/api/` for every agent, and datastream.org opts out AI agents by name. So `scripts/station_sources_probe.R` fetches neither. For the Water Hub it reads agent B's one-off `package_search` dump as a snapshot (copied into `data/station_sources/raw/`, md5 reported) and has no fetch code for that host. Its window-year counts are the `[I]` period proxy, because the daily values sit behind `datastore_search` on `/api/`. A Water Hub harvester therefore starts by asking Living Lakes (cbwaterhub@livinglakescanada.ca) whether a scripted reader is welcome, and what the "Amended CC-BY-SA-4.0" amends. DataStream: not accessed (key by request; AI opt-out). One `Locations` query with a key would answer it.

## Phase 2: part A delivered (2026-10-28)

`sources-a.md` (research agent A): province, UNBC, Hakai, USGS, BC Hydro (public page only), CRD, OBWB/ONA, BCCF, RDN, DFO VI Hydromets, BCER/Treaty 8, industry, municipal. Main claims spot-checked by the parent against the provincial CSVs, the BC Water Tool API and HYDAT 20260717. Both notes files have their scratch paths removed and are kept in the archive as the survey's working record.

## Phase 3: the probe (2026-10-28)

`scripts/station_sources_probe.R` → `data/checks/station_sources_20260717.txt`, byte-identical across two runs from scratch (code_md5 8918d04a). Beyond the counts:

- Provincial units: 6 Vancouver Island stations (2016–2019) report `l/s`, the rest `m^3/s`; the probe divides `l/s` by 1000 and refuses any other unit.
- Provincial values that cannot be right, published with grades: Oliver Creek in Lake Cowichan (08HA0036) up to 2.1 million m³/s (RISC U hours, median 1,693), Amor De Cosmos Creek (08HD0003) about 7,000 m³/s on RISC C and Unspecified hours in 2021–2024. No plausibility filter: complete days do not depend on magnitude, and the defect is the province's to fix. Fraser at Big Bar (08MD0002/3, to 9,887 m³/s) is plausible.
- The BC Water Tool against the province, same station and UTC day: ≥ 99.7 % within 0.1 % every year 1998–2020, then 91.7, 71.4, 77.6, 92.2, 85.8 and 61.1 % for 2021–2026. One copy was revised after the other was taken; which one is unresolved (the Aquarius portal is behind a disclaimer that was not accepted).
- USGS rdb: 20 days carry `Eqp` in place of a value; read as no value.
- Dropping NaN hours lowered some stations' complete days (Deep Creek 08EE0001 now 2 window-years, not 3) but left the totals unchanged: 147 stations pass, 110 provincial.

