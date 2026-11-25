# Findings — Backlog move 10: Swift and Naver creeks under their own chinook windows (#187)

## Issue context

**If we do it:** Swift Creek and Naver Creek are scored in their own stocks' cited chinook salmon life history timing windows, beside the Bulkley's, and wet reads the life history table at a commit that holds the upper Fraser and Cottonwood rows. **If we never do:** the two Fraser streams stay under the Bulkley's windows, so a difference in run timing can read as a difference in flow.

Order: `planning/backlog.md`, move 10. Run `/planning-init <this issue>`: one phase, one PR.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 10, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

## Batch 12: Swift and Naver creeks under their own windows

**Why here:** #182 alone moves wet's one pin on the knowledge life history table, and every Bulkley and Morice reader follows that pin; it rewrites the site reports, the comparison article and `research/chinook_sites.md`, so it runs before the research consolidation (move 12).

**Touches:** `data-raw/life_history_data.R`, `scripts/departure_sites.csv`, `inst/vignette-data/life_history_*.csv`, `data/checks/departure_site*`, `data-raw/chinook_sites_data.R`, `vignettes/articles/flow-change-sparse-gauges.Rmd` and its `.bib`, `research/chinook_sites.md`.

**Decided at the gate:** the knowledge commit to pin; a guard that the Bulkley and Morice chinook rows at that commit equal those at `c97c4d0` (or differ only in their notes), so the Maxan parity gate cannot break silently. Open work in the knowledge repository reviews the Skeena timing rows: it keeps the Bulkley spawning row with a note and may revise the Morice rows (search its open issues for "Life history timing, Skeena"). The upper Fraser and Cottonwood windows rest on NuSEDS medians, and a NuSEDS start or end of spawning is mostly an estimate made from a few visits, with no empty survey before or after it; NewGraphEnvironment/knowledge#256 sets how those dates are read, so the gate also decides whether to adopt the windows now, noting that their edges are estimates, or wait for it.

| issue | title |
|---|---|
| #182 | Run Swift and Naver creeks under their own cited chinook windows (UFRA, COTR) |



## #182 (carried)

**If we do it:** Swift Creek and Naver Creek are scored in their own stocks' cited chinook salmon life history timing windows, as Gosnell Creek already is under the Morice's, and the comparison article reports both window sets there. **If we never do:** the two Fraser streams stay under the Bulkley's windows, so a difference in run timing between stocks can read as a difference in flow.

## What is known

Cited chinook migration and spawning windows for both groups are now in New Graph's life history table (`data/life_history_timing.csv` in the knowledge repository, at commit 4e2d8a0c of 2026-11-17), from NuSEDS release 2026-06-01 and the literature:

| group | stream | migration | spawning | sources |
|---|---|---|---|---|
| UFRA | Swift Creek | 04-01 to 08-10 | 08-11 to 09-05 | NuSEDS (median spawn dates, 123–126 population-years, 1967–2000; Swift Creek alone 08-09 to 09-05); Bradford and Taylor (2023), citing COSEWIC (2018), for Fraser entry from April; Candy et al. (2002) for 2001 peak spawning weeks |
| COTR | Naver Creek | 04-01 to 08-09 | 08-10 to 09-06 | NuSEDS (35–36 population-years, 1953–2009; Naver Creek alone 08-13 to 09-10); Candy et al. (2002) for the Cottonwood's early lower-Fraser passage and 2001 peak spawning |

Against the Bulkley's (migration 05-01 to 08-01, spawning 08-01 to 09-15), both start migration a month earlier and spawn in a shorter window starting about ten days later. Every migration window ends the day before NuSEDS's median start of spawning, as the Bulkley's does.

wet does not read them yet: `data-raw/life_history_data.R` reads the table at an older commit (c97c4d0) and for MORR only, and `scripts/departure_sites.csv` runs Swift and Naver under BULK alone.

## How firm the windows are

Their spawning windows rest on NuSEDS median start and end dates. A NuSEDS start or end of spawning is mostly an estimate: at the upper Bulkley, records before 1992 carry round dates with no count of inspections, later ones ten-day bins from one to four visits a year, and none shows an empty survey before the start or after the end. So the windows are good evidence for the bulk of spawning and weak evidence for its edges. NewGraphEnvironment/knowledge#256 sets how those dates are read; decide at this issue's gate whether to adopt the windows now, saying in the article and the site reports that their edges are estimates, or to wait for it.

## The work

- `data-raw/life_history_data.R`: read the table at the commit holding these rows, and write `inst/vignette-data/life_history_ufra.csv` and `life_history_cotr.csv`, asserting the chinook rows and sources as MORR's are.
- `scripts/departure_sites.csv`: Swift's windows `BULK UFRA`, Naver's `BULK COTR`.
- Run `scripts/departure_site.R` and `scripts/departure_site_snow.R` for both sites: new reports `data/checks/departure_site[_snow]_swift_ufra_20260717.txt` and `..._naver_cotr_...`. #147's rule gives one verdict per site and window set, so each new window set gets its own.
- `data-raw/chinook_sites_data.R` and `vignettes/articles/flow-change-sparse-gauges.Rmd`: report the second window set at both streams, as Gosnell's Morice windows are; rewrite the limit "The windows are the Bulkley's at all four streams. Only the Morice has its own cited windows"; add Bradford and Taylor (2023), COSEWIC (2018) and Candy et al. (2002) to the article's `.bib` through `data-raw/vignette_bib.R`.
- `research/chinook_sites.md`: the results under each stream's own windows.

After #180 merges (it rewrites the same site reports, bundle and article). #181 also rewrites `research/chinook_sites.md`; whichever lands second folds the other's section in.

Relates to #126, #147, #118.



## Exploration, 2026-11-22

- knowledge `data/life_history_timing.csv`: commits touching it are fed33d48, c97c4d0e (wet's pin), 0fea1f47 (BULK CO migration note) and 4e2d8a0c (UFRA, COTR rows). `main` (b07ce5a) is byte-identical to 4e2d8a0c for this file.
- diff c97c4d0..4e2d8a0c: the BULK CO migration note rewritten (row has no end, dropped by every reader), four rows added (UFRA CH migration, spawning; COTR CH migration, spawning). No BULK or MORR start, end or source changed.
- wet reads the table at two places, both pinned at c97c4d0: `data-raw/life_history_data.R` (MORR) and `data-raw/station_vignette_data.R` (BULK; `knowledge_sha` is printed by `vignettes/flow-departure-normal.Rmd:718`).
- `site_windows()` (`scripts/departure_site_lib.R:78`) reads `life_history_<group>.csv` for each group in the site row's `windows` (BULK first); both site scripts loop over window sets and name reports per group. The Maxan parity gate runs only for `maxan` under BULK.
- The article's Morice paragraph is `vignettes/articles/flow-change-sparse-gauges.Rmd:519`; the limit at `:629`; the word cap 1140 at `:694`. `flow-change-sparse-gauges.bib` holds none of `bradford_taylor2023Diversityfreshwater`, `cosewic2018COSEWICAssessment`, `candy_etal2002discussionpaper`.
- knowledge open issues: #241 (Skeena timing review), #242 (Fraser and Thompson), #243 (every group), #256 (how NuSEDS spawning dates are read).

## Errors Encountered

| Error | Resolution |
|-------|------------|

## Phase 2 runs, 2026-11-25 (m1, worktree wet-187)

Logs: `data/logs/187/site_runs_20261125.log` and `{site,snow}_{swift,naver}_20261125.log` in the main checkout (14:31–14:44Z). Pre-run: cd's three ERA5-Land layers still CD_RUN_TIME 2026-10-10T22:36:36Z, CD_SHA 349f9d7 (as the BULK snow reports name); pcic.series rows md5 53c39c4e unchanged (every report prints it). All four `*_bulk_*` Swift and Naver reports rewrote byte-identical. Target complete migration years under the April-start windows: 08KA012 14 (1985–1998), 08KE014 18, as under BULK.

| site, windows | section 6 verdict | carried spawning mean, 1951–1980 → 2016–2025 (90 %, cover) | carried migration mean | held-out carried NSE migration / spawning (section 3) |
|---|---|---|---|---|
| Swift, UFRA | distance (gain −0.021) | −15.5 % (−33.1..+5.5, 1.000) | −6.1 % | 0.55 / 0.42 |
| Swift, BULK | distance | −15.3 % (−32.0..+5.1) | −4.8 % | (as tracked) |
| Naver, COTR | covariance_pick (gain 0.139 / 0.159 leak-free) | covariance_pick −34.8 % (−59.4..+8.9, 0.952); distance −58.9 % (−77.6..−22.6) | covariance_pick −11.0 % | distance 0.63 / 0.41; covariance_pick 0.74 / 0.56 (section 6) |
| Naver, BULK | covariance_pick | covariance_pick −35.2 % (−58.5..+2.0) | −13.0 % | |

- Same verdicts as each stream's BULK run; the spawning-window change barely moves under its own windows at either stream (Swift −15 % both; Naver −35 % both), and neither range clears no change on the shipped route.
- Swift's extended (filled-in) spawning mean: −31.7 % (−49.4..−6.1) under UFRA, against −27.5 % under BULK; ols scores stay poor there.
- Swift UFRA's snow gauges are 08LB038 and 08KA007 (BULK's: 08LB038 and 08KA001): the header's rule (nearest two with long records) depends on the windows' complete years. Every migration-window SWE slope's range stays above zero (observed and carried, both new window sets).
- Every new cover is ≥ 0.87 on mean and min7.
