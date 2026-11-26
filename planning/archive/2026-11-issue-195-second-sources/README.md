## Outcome

Backlog move 13 (#195) landed #144: `wet_station_daily(sources = "bcwatertool")` reads 46 third-party gauges the BC Water Tool serves, from a pinned snapshot of the Tool's daily CSVs (a tracked manifest of all 391 entries and the station list, wet's per-machine cache, a private backup), and `wet_station_list()` lists them beside the 211 provincial stations. At the owner's choice (decision 1b), seven Tool listings at provincial sites continue those stations' records under the provincial number for the days before the provincial record begins, the rule #192 will extend to Hakai's record. #190 and #192 were split back out with their owner questions. What was learned: the chain must cut where the provincial record begins (its first usable hour), not at its first complete day. Tofino's four listings are the same gauges as 08HC0001–0004, and the one day they seemed to add was the province's own partial first day, so they add nothing, while BC Conservation Foundation's three add 2012–2015. And a registry of values derived from another artifact must name that artifact at its finest key (snapshot and provincial days: manifest md5 and reader version), with every consumer refusing a mismatch. The durable findings are in [`research/station_sources.md`](../../../research/station_sources.md), "The Water Tool's gauges in wet" and "The plausibility bound for the Water Tool's gauges".

## Measurement

- Selection on the pinned list: 9,427 listings → 398 with a record outside Water Survey of Canada → 391 one per `nid` → 103 third-party (271 BC ENV and 17 provincial copies left out) → 53 with discharge → 46 stations of their own and 7 continuing a provincial station. As the plan review forecast.
- Under the survey's rules the reader reproduces the survey: 53,970 daily rows identical, 103 station rows, 14 network lines, 35 passing stations, 7 shared sites.
- Under the shipped rules: 53,821 days, 22.1 % unchecked (QA 0); no negative day; the bound drops 149 days, 145 at four Capital Regional District creeks (Colwood Creek's 70, mostly flat at 45.22 m³/s on a median of 0.13).
- The chain: 0 days at Tofino's four (cut at the first provincial hour; at the first complete day it would have added one partial day each); 1,181, 1,081 and 856 days (2012–2015) at Grandon Creek, Rosewall Creek and the Tsolum River, cut at 2021-09-30.
- Sub-drainage from the nearest HYDAT station: 08H 18, 07F 11, 10C 8, 08D 7, 10D 5, 08M 2, 08G 1, 10F 1; farthest nearest station 127 km (`ogc_1004`).
- `/code-check branch`: three rounds, two of them finding a defect inside the previous fix; ended on the enumeration in `review-enumeration.md` (22 registry and manifest values, 4 consumers).

## Evidence

`data/checks/station_sources_harvest_20261028.txt` (the harvest's Tool tier, byte-identical on rerun).

## Owed

- #190 and #192, split off, wait for the next `/backlog-sweep` to place them, with their owner questions in their bodies.

Closed by: PR for #195 (branch `195-backlog-move-13-second-sources-for-the-p`)

## History moved from research/station_sources.md (#207, 2026-11-25)

The research file now states only the current rule and counts; the passages below, as they stood there on 2026-11-25, record how they were reached.

### The Water Tool's gauges in wet

What `wet_station_daily(sources = "bcwatertool")` reads, and how it stands against the survey [M, `data/checks/station_sources_harvest_20261028.txt` unless noted]:

- **One pinned snapshot**, the survey's (2026-10-28): the station list and all 391 per-station entries (389 CSVs, 2 HTTP 500 records), held to md5s tracked in `inst/extdata/station_sources/bcwatertool_20261028.csv`, cached per machine and backed up privately with every entry, the Tool's copy of the provincial stations among them, which wet#190's comparison reads. The Tool serves only its current values, so a newer read is a new pin.
- **How to fetch one of your own.** The station list is `https://nr-bcwat.bcwatertool.ca/api/streamflow/stations` (GeoJSON) and a listing's daily values `https://nr-bcwat.bcwatertool.ca/api/streamflow/stations/<id>/csv`, `<id>` being the list's numeric `id` (`scripts/station_sources_probe.R` reads both; robots.txt allows them). Comparing each file's md5 with the tracked manifest tells a fresh read from the pinned one; `data-raw/station_sources_bcwatertool.R` says how a read becomes a pin.
- **Terms.** Each CSV's header names its source and disclaims liability; wet gives the first part as the station's `credit` and states no licence. One file in the backup, Fisheries and Oceans' New Westminster listing (19197, stage only, never read), states "personal and public non-commercial use only. Reproduction for commercial redistribution is prohibited"; the backup is private and nothing republishes it.
- **What is read.** Of 9,427 listings, 391 have a record outside Water Survey of Canada once each `nid` keeps its first listing (Geoscience BC's `HRB5454`, id 47738, is left behind the industry network's). Left out: the Tool's copy of the provincial network (271 listings, among them 08MH0061 and H08KC1015, which hold discharge the provincial files lack and are not read, #195 decision 3), 17 provincial stations it files under the Regulator, and 50 third-party listings with no discharge series. 53 remain: **46 stations of their own** (Capital Regional District 8, Oil and Gas Industry Network 10, Geoscience BC 7, EAO 7, Regulator 6, BC Hydro 5 (two of them HYDAT duplicates), UNBC 2, BCCF 1) and 7 at provincial sites.
- **A provincial record continued.** The seven Tool listings within 0.5 km of a provincial station on the same stream (the survey's same-site set) are not stations of their own: their days before the provincial record begins come back under the provincial number, `source = "bcwatertool"`. The record begins on the first day the provincial files hold any usable hour of the station, complete or not (the registry's `continues_before`), not on its first complete day: Tofino's four listings are the same gauges, and their one day "before" the province's first complete day is the province's own partial first day (10–15 hours), so they add nothing. BC Conservation Foundation's three add 2012–2015 to Grandon Creek (08HB0011, 1,181 days), Rosewall Creek (08HB0008, 1,081) and the Tsolum River (08HB0012, 856), whose provincial records begin on 2021-09-30. The cut is stored in the registry, so it is the same whichever sources are asked. A second publisher's earlier record for any provincial station (Hakai's, wet#192) is a row of the same kind.
- **Days and status.** One row of a CSV is one day. The survey matched the Tool's copy of the provincial stations to the province's UTC days, so a Tool day may be a UTC day rather than a local-standard-time one [I]. Quality-checked days (QA 1) are `"provisional"`, unchecked days (QA 0) `"unchecked"`: 22.1 % of the 53,821 shipped days. Every unit is m³/s and every QA 0 or 1; anything else is refused.
- **The bound** (registered below, before it was applied): no day is negative; it drops 149 of 53,970 days, 145 of them at four Capital Regional District creeks on Vancouver Island (`08H`): Colwood Creek's 70, most flat at 45.22 m³/s on a median of 0.13, Cecelia Creek's 65, Hospital Creek's 9 and Bowker Creek's 1; the other 4 are at Stewart Creek (07FB0001). The sub-drainages read are `07F` 11, `08D` 7, `08G` 1, `08H` 18, `08M` 2, `10C` 8, `10D` 5, `10F` 1; the farthest nearest HYDAT station is 127 km away (the Petitot River gauge, `ogc_1004`).
- **The survey reproduced.** Under its own rules the reader returns its 53,970 Tool daily rows exactly, all 103 third-party station rows, its 14 network lines, its 35 passing stations and its seven shared-site listings.
- **Donors.** 23 of the Tool's 46 stations are natural under #196's rule, 9 regulated and 14 unknown [M, same report]; like the provincial stations, they are records and held-out tests, not donors (#202, tested in #211, above).
- **Still open.** Each operator's rating, which no file states.
