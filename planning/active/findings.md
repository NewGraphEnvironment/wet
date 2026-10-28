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

## Phase 1: prior work (2026-10-28)

**Installed NGE packages** (DESCRIPTION URL or BugReports naming NewGraphEnvironment: cd crate cred drift flooded fly fpr fresh gq knowledge link mc ngr rfp roli spacehakr trap wet xciter). Exports matching `hyd|flow|disch|station|gauge|gage|stream|water|level|datastream|hakai|aquarius`: only federal fetchers. `ngr::ngr_hyd_q_daily()` and `ngr::ngr_hyd_realtime()` (the latter is `tidyhydat::realtime_ws()`), and wet's own `wet_station_*`. No package fetches any candidate source.

**Org code search** (`gh api search/code`, `org:NewGraphEnvironment`, default branches):
- `skeenaknowledgetrust`: references only (restoration_wedzin_kwa_2024 cites the SKT "UBR Water Temperature Monitoring Dashboard Draft" on Tableau Public; xciter test fixtures).
- `aquarius` / `aqrt`: one hit, `restoration_wedzin_kwa_2024/data/inputs_extracted/skt_geoserver_info.csv` (2025-03-11). SKT's GeoNode serves `geonode:hydrometric_stns_flnrod_nwbc_2018_09_20`, "Provincial hydrometric and water quality station locations from the Aquarius Time-Series database sourced from http://aqrt.nrs.gov.bc.ca/. Layer created by EGIS on 2018-09-20." This is a lead for the provincial network, not a fetcher.
- `datastream`: a report in one of our private repos, and a closed issue there, proposed (did not build) reading Pacific DataStream's API (`api.datastream.org/v1/odata/v4`) for Skeena water temperature. Also one mention in a private planning note.
- `hakai`: one mention in a private planning note; no code.
- `columbiabasinwaterhub`, `"water hub"`: none.
- `realtime_ws`: ngr, water-temp-bc and wet only (federal).
- `unbc hydrometric`: reporting-template background and methods prose, and bibliographies; no code.
- Local grep across `~/Projects/repo` checkouts (hosts `datastream.org`, `columbiabasinwaterhub`, `skeenaknowledgetrust`, `aqrt.nrs`, `aquarius`, `hakai.org`, `bchydro`, `okanagan basin water board`): the same files, nothing more.

**Open issues and PRs** in wet, water-temp-bc, ngr, fresh and one more of our repos (`hydrometric OR datastream OR hakai OR "living lakes" OR skeena OR unbc OR gauge`): no harvester work in flight. Adjacent: wet#124 (CABIN spot flows), wet#126 (second-region pilots, which would use any new gauges); downstream work on life-stage flow is in progress elsewhere.

**Verdict for point 6, every source:** no NGE package or org code fetches any of them.

## BC Hydro (user, 2026-10-28)

BC Hydro holds a large hydrometric record, released only by individual request. Pointer issue filed: wet#140. It goes into the survey as "by request" with what is publicly known.
