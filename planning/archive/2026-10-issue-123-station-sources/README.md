## Outcome

#123 surveyed the networks beyond HYDAT that might hold BC discharge, against a bar set at the plan gate before any source was checked, and recorded every source and asset found, accessed or not. The durable verdict is [`research/station_sources.md`](../../../research/station_sources.md). One source passes: the province's non-integrated hydrometric network (hourly CSVs, OGL-BC 2.0), whose harvester is wet#142. Three are test-only: the BC Water Tool's third-party networks (no redistribution licence), the Columbia Basin Water Hub (preliminary, listed periods only, and its robots.txt disallows `/api/`, so a scripted reader waits on Living Lakes Canada) and two USGS gauges. Everything else is no or a lead not yet read. BC Hydro's archive is released only by request (wet#140). What was learned beyond the verdicts: the province's files carry mixed units, NaN values and impossible graded values; the Water Tool's copy of the provincial stations parts from the province's files from 2021; and three hosts opt out of scripted or AI readers, so the probe fetches nothing from them. Three code-check rounds found 21 real defects, nearly all prose numbers copied from a report line whose selector counted a different population. Round 3 enumerated every number and quantifier across the research file, README, CLAUDE.md and the two issue bodies, and that ended the loop.

## Measurement

From `scripts/station_sources_probe.R` against HYDAT 2026-07-17; report `data/checks/station_sources_20260717.txt`, byte-identical across reruns and under `LC_COLLATE=C`:

- 147 stations at 140 sites pass the station test (≥ 3 complete Chinook-window years outside HYDAT's discharge years at the site): 110 provincial, 35 in the Water Tool's third-party networks (6 of them at sites that also pass provincially), and 2 USGS. If a same-stream HYDAT gauge within 3 km counts as the same site, 143 pass.
- Lower bars: 238 stations at 227 sites have at least one complete window-year on daily values, and 60 of them are seasonal-only. The Water Hub has 76 discharge datasets, of which 29 pass on the period proxy [I].
- In the Bulkley the gain is two provincial stations with 2 window-years each, which changed the expectation for #118's pilot area from "more donors" to "few".
- Wrong turns kept:
  - NaN hours first made the Tool-against-province comparison read NA, then 91.9 % agreement. Dropping NaN showed the gap is real and starts in 2021.
  - A duckdb profile of values above 2,000 m³/s counted NaN, because duckdb orders NaN above every number.
  - The first lower-bar and proxy counts mixed listed-period datasets, tag-only datasets and stations with no complete day into the daily populations (rounds 1–3).

## Owed

- Tick #123 in #118's component list (`/gh-pr-merge` step 3b).

Closed by: PR (this branch, `123-station-source-survey-which-networks-bey`)
