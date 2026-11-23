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
