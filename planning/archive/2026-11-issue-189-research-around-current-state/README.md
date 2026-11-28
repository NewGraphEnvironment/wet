## Outcome

Four of backlog move 12's five research notes now read as what is true today: `research/discharge_publish.md` (#183),
`station_flow_departure.md` (#184) with `chinook_sites.md` (#181), and `fwapg_mad_method.md` (#206). History moved
verbatim to the READMEs of the issues it came from; method and per-site results each have one home. The fifth,
`water_balance_method.md`, was split to #261 by the owner, asked before its phase. #181 and #189 stay open for the
owner to close or re-scope.

What we learned: every stale number had been carried over from an earlier build or release under a later **Verified:**
date (routed days after #163's republish, Gosnell's normal error after the same rebuild, the ice count after the HYDAT
bump). The change that rebuilt an artifact updated its report and not the sentences that quote it. The code review then
found a second class that matching figures against reports cannot catch: a sentence whose scope (route, window set,
statistic, site, table state) was wider than its figures, usually after being merged away from the heading that had
qualified it. One claim can also change with no commit here: water-temp-bc's provisional values for Buck Creek's
2025–26 winter read 6.6–15 m³/s in the 2026-10-01 bundle and 0.65–0.68 m³/s on 2026-11-27 (cause not traced).

## Measurement

| file | prose words, before to after | issue-headed sections | `research_check.sh` flag after |
|---|---|---|---|
| `discharge_publish.md` | 4,546 to 3,510 | 3 to 0 | words |
| `station_flow_departure.md` | 3,186 to 2,283 | 5 to 0 | none |
| `chinook_sites.md` | 3,221 to 3,647 (took Maxan's results from the method file) | 2 to 0 | words |
| `fwapg_mad_method.md` | 1,037 to 1,296 (dated sections) | 2 to 0 | none |
| total | 11,990 to 10,736 | 12 to 0 | |

Main numbers that disagreed with their source, all ours (the full table is in `findings.md`): routed days clamped
1.092 % read for 1.183 %; days against months 4.614 % for 4.711 %; Gosnell's spawning-normal upper quartile +60 % for
+47 %, and 25 of 29 routed picks for 29 of 29; 08EE013's ice days 7,885 of 18,193 for 8,101 of 18,620; August median
0.73 for 0.75; snow R² quoted from the unshipped route.

On the revise-in-place rule #181 tests, and the 3,000-word line: see "Phase 6" and "Code-check" in `findings.md`. Both
notes still over the line are reference tables and current facts with no history left to move.

## Evidence

`findings.md` (claim-by-source tables, ledgers, disagreements); `numbers_check.py` (candidate finder for numbers that
left or appeared, run from the repo root); `review-plan.md`, `review-round1.md` to `review-round5.md`,
`review-verdict.md`. Tests: `devtools::test()` 4,144 passed, 0 failed, 5 skipped.

Closed by: the PR for branch `189-backlog-move-12-research-files-around-th` (closes #183, #184, #206; relates to #181,
#189, #261)
