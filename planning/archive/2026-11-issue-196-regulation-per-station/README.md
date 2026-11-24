## Outcome

Every station `wet_station_list()` lists outside HYDAT (211 provincial, 46 BC Water Tool) now carries a regulation status, natural, regulated or unknown, from what sits upstream of it, under a rule registered before it was applied (`scripts/station_regulation_rule.R`, registered at 2d93787f, three amendments at 0c6d31ff and 6c9cb1e5, each the owner's decision). `scripts/station_regulation.R` snaps each station on the stream its name or drainage area gives, places BC's dams and water rights licences upstream as #53 did, reads each segment's published mean annual flow from verified parts, and writes `inst/extdata/station_sources/regulation_20261028.csv`, which `wet_station_list()` reads through `wet_station_regulation()`. `wet_station_select()` stays HYDAT-only; a donor pool of the natural stations is #202. What was learned: the licence layer is "Access Only" (only computed values ship, never a licence record), and "natural" is the rule's fall-through, so every filter that drops evidence (groundwater rows counted as surface, no-volume licences, #53's 1 mm own-reach test, unplaced points, unchecked codes) fails toward natural unless it is counted, routed to unknown or stopped on; four review rounds found and closed each. Findings: `research/station_sources.md`, "Regulation per non-HYDAT station".

## Measurement

WFS snapshot 2026-11-24: 118,717 licence rows (95,422 Current), 2,485 dams (1,838 regulating for the rule). 204 of 257 stations snapped (119 by name, 73 by name and area, 12 by area). Statuses: 75 natural (52 provincial, 23 Tool), 110 regulated, 72 unknown. Under Amendment 1 alone 94 read natural; Amendment 2 (no-volume licences) moved 17 to unknown; Amendment 3 (a 100 m own-reach margin) moved 08NK0006 (licensed use 36 % at the gauge) and 08HC0004 (a regulating dam 44 m below) to regulated. The surface correction from review moved 08GA0005 (44.5 % to 3.8 %) and 08HA0027 (18.3 % to 9.1 %) from regulated to natural. Against HYDAT's flag at the 58 provincial stations at a HYDAT site (deciding nothing): HYDAT natural 11/10/9 (natural/regulated/unknown), HYDAT regulated 4/21/3. A rerun from cache writes the report and the status file byte for byte (`cmp`). Report: `data/checks/station_regulation_20261028.txt`.

## Evidence

`data/logs/196/station_regulation_run*` (in the main checkout; `run1` is the stop at the shared licence, `run2` the first full run, `run7` after review round 1, `run10` after Amendment 3); `data/logs/196/devtools_test*`.

## Owed

- Tick move 14 in `planning/backlog.md` (`/gh-pr-merge`); #191 closes with the PR

Closed by: the PR for #196 (opened from branch `196-backlog-move-14-regulation-per-non-hydat`)
