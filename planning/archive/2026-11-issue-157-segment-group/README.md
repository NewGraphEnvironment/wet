## Outcome

Answered #157: a watershed group's balance rows and pick can be rebuilt alone from the shipped fit in about 20 s, where the province run's inputs are, and match the published product. A group's rows need only the polygons `FWA_Upstream` reaches from them (`wet_ws_reach()`), cut from the upstream-closed set under the group's roots (`wet_ws_roots()`, `wet_ws_closure()`); `scripts/segment_group_closure.R` counts both for every group, and `scripts/segment_group.R <WSG>` builds one group over its reach and compares every row with the published parts. The plan-mode measurement that the closure was already the least set was wrong; code-check round 3 found it, and the reach was added. Publishing the fit, needed for a build anywhere, is left as a follow-up. Durable verdict: [`research/segment_group.md`](../../../research/segment_group.md).

## Measurement

- Reach over 246 groups: the group alone for 59, two or three groups for 79, four to ten for 60, more for 48; over 200,000 polygons for 24 (the closure: 53 / 59 / 62 / 72 and 48). The reach equals the closure for 106 groups. SALR 4,589 of 12,481; UFRA 23,358 of 644,770; BULK 35,191, its whole closure. Changed the verdict from "about half the groups" to 138 of 246, and the build's polygon set.
- Time on the machine holding province run `92b893c4da`: BULK 18 s in all (sampling 8 s, accumulation 2 s, published read 3 s), SALR 10 s; the province's sampling and accumulation take about 11 min. The closure table takes 195 s on the development machine's fwapg.
- Parity against live build b4bbc50: SALR 0 rows beyond 1e-9 relative over 59,631 watershed and 117,000 segment rows; BULK 132 watershed and 144 segment rows beyond (11 watersheds, months 1–12, ≤ 5.8e-5 relative), all at calibration gauges where the province run's donor distance is exactly 0 and the group build's about 1e-15 (#158); pick identical in both. Upstream means ≤ 1.4e-12 relative from the province run's (BULK), 4.1e-15 (SALR). Resampled BULK and SALR `identical()` to the province samples.
- Deliberate break (MORR removed from BULK's reach): 3,449 watershed and 4,825 segment rows differ, up to 336 m³/s.
- Wrong turns kept: the 48 largest closures were first described as Fraser/Peace/Columbia groups, then as including Skeena and 915; by the root holding the most polygons they are Fraser 13, Columbia 7, Peace 5, Liard 5, Stikine 4, coastal 910 14. The BULK listing first printed the wrong columns, which read as 1.0 relative differences.

## Evidence

- `data/checks/segment_group_closure.txt`, `data/checks/segment_group_{BULK,SALR}_20260717.txt`
- `data/logs/157/segment_group_closure_m1.log`, `data/logs/157/devtools_test_m1.log` (development machine); `data/logs/157/segment_group_*` in the main checkout of the machine holding the province run, the break's report among them (`segment_group_BULK_drop-MORR_20260717.txt`)
- Review rounds: `review-round[1-4].md` in this directory

## Owed

- File the follow-up issue for publishing the fit, citing Phase 1's table and naming the manifest-format change and the inputs a portable build needs, if the verdict says the build is worth having.
- When `scripts/wb_province.R` or `R/wet_upstream_sums.R` next changes for a province run, move `sample_group()` into the package (one copy, called by both scripts) and amend `wet_upstream_sums()`'s "whole basin" sentence to "upstream-closed set".

Closed by: PR #159
