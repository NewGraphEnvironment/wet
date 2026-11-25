# Findings — Backlog move 13: Second sources for the provincial stations (#195)

## Issue context

**If we do it:** `wet_station_daily()` reads the BC Water Tool's third-party gauges beside the province's stations, continues a provincial station from another publisher's earlier record under one registered rule (Hakai's 2013–2020 years at three Calvert and Hecate stations), and reads the province's 2021–2026 years from the copy its own portal says is current. **If we never do:** the 29 Tool gauges beyond the provincial sites stay unread, the three Hakai stations start in 2021, and the provincial years since 2021 stay of unknown standing.

Order: `planning/backlog.md`, move 13. Run `/planning-init <this issue>`: one phase, one PR. It starts once move 8 (#179) has merged, which lands the station registry, the snapshot cache and `wet_station_list()`, and once move 9 (#186) has, whose test changes share the test folder.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 13, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

## Batch 15: second sources for the provincial stations

**Why here:** all three were split from move 8. #144's six shared sites and #192's earlier years ask one question: how a second publisher's record continues a provincial station under its number, which `wet_station_daily()` answers today only for HYDAT numbers. One rule serves both. #190 says whether the pinned provincial snapshot is the current copy before the Tool's copy is set beside it, and a newer snapshot rebuilds the registry this batch extends anyway.

**Touches:** `R/wet_station_daily.R`, `R/wet_station_list.R`, `data-raw/station_sources_snapshot.R`, `inst/extdata/station_sources/`, `research/station_sources.md`, `tests/testthat/test-wet_station_daily.R`, `tests/testthat/test-wet_station_list.R`, and new readers with their tests and a report under `data/checks/`.

**Decided at the gate:** which copy at the six shared sites, and the rule for a second publisher's earlier record under a provincial number (#144 lists the options; move 8's gate recommended provincial only); whether the province's Aquarius portal is read, which needs the owner to accept its click-through disclaimer; Hakai's record from its published data package or by asking Hakai, an outward request that goes through the owner (if it would wait on a reply, #192 is split off again).

| issue | title |
|---|---|
| #144 | Harvest the third-party gauge records the BC Water Tool serves into wet_station_daily() |
| #190 | Tell which copy of the province's 2021–2026 discharge is current, from its Aquarius portal |
| #192 | Hakai's 2013–2020 discharge at its three Calvert and Hecate stations |


## Exploration, 2026-11-23

- Move 8 (#179, PR #194) and move 9 (#186, PR #197) have merged; #195 waits on nothing.
- The survey's Water Tool copy is in the main checkout's gitignored `data/station_sources/raw/bcwatertool/` on the machine that ran the survey (391 entries: 389 CSVs and 2 `.status` files for the stations answering HTTP 500), 34 MB, and `bcwatertool_streamflow_stations_20261028.geojson`. The survey report (`data/checks/station_sources_20260717.txt`, lines 17 and 23) records the list's md5 `4c29e2ad9fd6ea40a8547edca66ea3fc` and the md5 of the per-station md5 list `529b73cf508a7cedc107304b13209028`.
- A Tool CSV (`13915.csv`, Sharp Creek, Tofino) is a `# key,value` header block ("Data Licence Information", Name, Network, Status, Drainage Area, Operation, Latitude, Longitude, Description, QA, Date Range, Elevation), a blank line, then `Analysis,Datetime,Value,Units,QA`, with `Datetime` a date and `Units` `m3/s`.
- The station list holds 9,427 features: BC ENV 6,961, Water Survey of Canada 2,343, then the third-party networks (BC Oil and Gas Commission 30, BC Hydro 20, DFO 14, CRD 12, industry 10, Geoscience BC 8, EAO 7, Delta 6, Tofino 4, BCCF 4, Cowichan 3, UNBC 2, Surrey SCADA 2, Wasa Lake 1). No non-WSC `nid` has HYDAT's shape; two hold a space (`Wasa Lake`, `UC 5`).
- `wet_station_daily()` sends HYDAT-shaped numbers to the federal sources and looks every other number up in the provincial registry (`wet_bcenv_stations()`); a Tool source slots in beside it the same way. `wet_station_list()` refuses any source but `"bcenv"`.
- `wet_bcenv_cap()`/`wet_bcenv_ratio()` give a non-WSC-shaped number the province-wide bound, so the provincial rule applies to Tool numbers unchanged.
- The installed wet is 0.4.38 against main's 0.4.41 (`check_pkg_stale.sh`): reinstall before a data-raw run that reads registries through `system.file()`.
- #190's portal and #192's Hakai record each wait on the owner (a click-through disclaimer; outward contact or a data-package route), so the plan proposes splitting them off (open decision 1).
