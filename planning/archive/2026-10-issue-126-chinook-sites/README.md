## Outcome

The Maxan Chinook method (#120's record extension and carried departures, #121's snow regression) was taken over to a site table (`scripts/departure_sites.csv`) and run, fixed at what shipped for Maxan, at three more Chinook streams: Swift Creek (08KA012, upper Fraser), Naver Creek (08KE014, Cottonwood) and Gosnell Creek (Morice, never gauged). Owen Creek, the issue's first ungauged pick, was dropped at the plan gate: it has no Chinook record. Gosnell was chosen over Lamprey by recorded Chinook use (`scripts/chinook_sites_use.R`). Parity gates make the generalised scripts reproduce Maxan's tracked pilot and snow runs exactly. The spawning-window drop and the flat migration window hold at all three. The method travels less well than at Maxan: record extension fails in the sparse upper Fraser box, and the borrowed departures score below #120's 0.5 bar in the spawning window in every box. The comparison article (`vignettes/articles/chinook-sites.Rmd`) is unlisted under pkgdown's `internal` section. Results and the reasons for each choice are in [research/chinook_sites.md](../../../research/chinook_sites.md).

## Measurement

Change in mean flow, 2011 to the last year on record against before 1981, Bulkley windows, from borrowed (carried) departures, with the 90 % range:

| site | spawning | migration | carried score, migration / spawning | extension (ols) score | extension pool |
|---|---|---|---|---|---|
| Maxan | -46 % (-66..-17) | -3 % | 0.63 / 0.49 | 0.50 | 21 |
| Swift | -12 % (-28..+6) | +2 % | 0.51 / 0.43 | 0.14 (#120's rule would pick ratio) | 11, below the floor of 15 |
| Naver | -41 % (-63..-4) | -3 % | 0.60 / 0.42 | 0.63 (ratio by the margin) | 17 |
| Gosnell | -35 % (-55..-5) | +4 % | 0.65 / 0.45 | 0.48 (box) | 18 |
| Gosnell, Morice windows | -23 % (-47..+11) | -1 % | 0.62 / 0.66 | 0.49 (box) | 18 |

What changed because of them: the article states that the spawning-window carry is below the bar where its headline is. Before review round 3 it claimed "at least 0.5 in every box" from the migration window alone.

- **Snow (#121, unchanged):** the migration-window borrowed departures rise with peak SWE at all four sites (R² 0.41–0.51, ranges above zero). In the spawning window peak SWE gives at most 0.16 and the melt date at most 0.23. The 3,000 mm cap binds nowhere, Swift included.
- **Gosnell's normal (routed PCIC, pick):** its spawning-window error at 29 box gauges is a median of +21 % and an upper quartile of +60 %. The station-set flag does not separate in- from out-of-sample, because 25 of the 29 picks are routed.

Wrong turns kept:
- **Area parse:** it took the wrong column for a two-word stream name.
- **`source` column:** duckdb's `source` is a Hive key, not a column, with Hive partitioning off.
- **Snow-gauge rule:** amended after Naver's second gauge (08KD001) had no accepted snap.
- **Donor order:** the "nearest first" line came from one year's list.
- **The article's own guards:** five review rounds each found sentences broader than their guard checks. Round 3 named the mechanism, and the review ended on an enumeration of every claim against the set it names (`review-enumeration.md`).

## Evidence

`data/logs/126/*` (local, gitignored): `site_*`, `snow_*`, `chinook_sites_use*`, `pkgdown*`, `test.log`. Tracked reports are `data/checks/departure_site*_20260717.txt` and `data/checks/chinook_sites_use.txt`. Review files are `review-plan.md`, `review-round1.md` to `review-round5.md` and `review-enumeration.md` in this directory.

## Owed

- File an issue: move Maxan's five files onto the site table and retire `departure_pilot.R` / `departure_snow.R` as separate code paths.
- File an issue: `covariance_pick` carried departures at the sites, where PCIC covers them.

Closed by: PR #141
