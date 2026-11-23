## Outcome

`wet_station_daily()` reads the province's non-integrated hydrometric stations (source `"bcenv"`) from a pinned snapshot of the province's hourly files, and the new export `wet_station_list()` lists the 211 stations with the HYDAT station at each one's site. The snapshot (2026-10-28, the survey's) is held to tracked md5s in wet's per-machine cache and backed up privately, because the province rewrites `Discharge.csv` in place. Hours become local-standard-time days (UTC−8; UTC−7 in drainage areas 07 and 10) of at least 20 hours, stored once per manifest and reader version, with the hours rule, status and plausibility bound applied on read. A day with any ungraded hour is `"unchecked"` and `frac_provisional` counts every status but approved. Provincial stations keep their own numbers. Records and held-out tests only: their regulation is unknown, so they are not donors yet (#191). The owner settled seven decisions at the resume and an eighth when the registered bound failed. #144 was split off and carries what moved to it. What is now known lives in `research/station_sources.md`, "The provincial files in wet" and "The plausibility bound for the provincial files".

## Measurement

- **The bound, registered before it was measured** (HYDAT 20260717, the largest ratio of a station's largest daily flow to its median positive daily flow, over 752 BC stations with ten years of days). The province-wide form came out at 2,490.71, set by the Pouce Coupe River (07FD007) alone, nearly twice the next station (1,346.56). It **failed** one registered catch: Amor De Cosmos Creek's (08HD0003) 51 days above 1,000 m³/s have ratios from 402 up, on a median of 2.5 m³/s, with a 90th percentile of 101 m³/s, so the record is broken for years, not spiked. As registered, it did not ship. The owner chose a per-WSC-sub-drainage form, re-registered before it was applied, knowing only the HYDAT sub-drainage maxima (08H: 268.07 over 82 stations) and Amor De Cosmos's smallest ratio. It passes all four catches and drops 208 days at 8 stations.
- **The survey reproduced** under its own rules: 215,300 station-days identical to the probe's own query (flows within 1e-12), all 211 station rows, and 110 passing. Under the shipped rules: 215,168 complete days under local standard time, 214,960 after the bound, one station moved (08NM0005, 12 → 11 window-years, still passing), 66.3 % of days unchecked.
- **Wrong turns kept.** A first "fix" for a mock leaking across test files passed `.local_envir`, which testthat 3.3.2's `local_mocked_bindings()` reads as a binding to mock. The real cause was a bare `on.exit()` inside `test_that()`. A research sentence said no station sat in Mountain time, from a grep that missed `08NK`; round 5 found the 14 Elk Valley stations, which hold one value a day. The harvest first printed a float difference that moves with duckdb's summation order.
- **Review:** `/code-check branch` ran five rounds and ended on an enumeration of 25 places (`review-enumeration.md`, `review-verdict.md`). Round 3 found a defect inside round 2's fix.

## Evidence

`data/checks/station_sources_bound_20260717.txt`, `data/checks/station_sources_harvest_20261028.txt`; the first, failed bound run is in this branch's history at bc8f6457.

## Owed

- Tick move 8 in `planning/backlog.md` (`/gh-pr-merge` step 9c); under decision 1(a), #144 stays open for the next `/backlog-sweep` to place

Closed by: PR (this branch), closing #142 and #179
