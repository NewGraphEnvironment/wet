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
