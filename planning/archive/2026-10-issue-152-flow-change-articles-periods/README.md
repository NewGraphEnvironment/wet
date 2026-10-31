## Outcome

The two listed flow-change articles now each say what they do.

- **"Measured Stream Flow Against Its 1981–2010 Normal: Two Long-Record Gauges"** (`vignettes/flow-departure-normal.Rmd`) compares 2016–2025 with a 1981–2010 normal. It cites that normal as a WMO standard normal and as the period wet's published flows are normals of.
- **"Rebuilding Stream Flow History Where Gauges Are Few"** (`vignettes/articles/flow-change-sparse-gauges.Rmd`) compares 1951–1980, the decades before warming sped up (Hansen et al. 2012), with 2016–2025. It adds the lowest seven-day flow and snow at the measured snow gauges.

All three articles now take their references from `data-raw/vignette_bib.R`.

What was learned:
- **The two articles' intervals behave differently at ten recent years.** The measured article's percentile bootstrap undercovers, so it is labelled as resamples. The rebuilt article's year resampling with held-out residuals holds its coverage.
- **The review's recurring defect was one mechanism:** a sentence's population (statistic, route, window set) widening past its guard's data-frame filter. Four rounds ended only on an enumeration of every claim against its guard.

Durable results are in [research/chinook_sites.md](../../../research/chinook_sites.md) and [research/station_flow_departure.md](../../../research/station_flow_departure.md), in their #152 sections.

## Measurement

- **Part A count:** every stream reaches 1951–1980, with 20–28 borrowed and 27–30 filled-in years. 2016–2025 has 9 years where approved HYDAT ends in 2024, and 10 at Swift.
- **Interval coverage, on simulated no-change series:**
  - rebuilt article's change intervals: 0.904–1.000 at every site;
  - measured article's percentile bootstrap: 0.834–0.867 (`data/checks/departure_interval_coverage.txt`).
  
  Against the registered 0.87 bar, the rebuilt article keeps "90% range" and the measured article does not.
- **Rebuilt article, borrowed spawning-window mean, 1951–1980 to 2016–2025:**
  - Maxan −45% (−67..−11);
  - Swift −15% (−32..+5);
  - Naver −46% (−69..−5);
  - Gosnell −35% (−56..−3), or −23% under the Morice windows.
- **Snow over each target's catchment:** peak SWE fell 6–9%, and the 50% melt date came 9–16 days earlier. The melt date explains 64–66% of measured spawning-window flow on the Nanika and Morice, a finding the article now states.
- **Measured article, 2016–2025 against 1981–2010:**
  - Bulkley at Houston: −7% (migration), −8% (spawning);
  - Buck Creek: −5% (migration), −48% (spawning);
  - every window below normal in each year from 2023.
- **The years figure's OLS band** covers 83–85% of held-out years in the site reports, so the article no longer calls it a 90% range.

Wrong turns kept:
- I planned the rebuilt article's coverage for a standalone script. It moved into the site runs, because the residual pools it needs exist only inside a run.
- I guessed Werner et al.'s citation key; Better BibTeX lower-cases it.
- I first wrote "Morice gauges" for 08ED001; it is the Nanika.
- The m4 reruns started before the plan review's "code-check the site scripts first" arrived. No review finding touched those scripts.

## Evidence

- `data/logs/152/*` on m4: the site, snow and bundle runs.
- Tracked reports: `data/checks/departure_site*_20260717.txt` (section 5 and the #152 snow block) and `data/checks/departure_interval_coverage.txt`.
- Review files in this directory: `review-plan.md` and `review-round1.md` to `review-round4.md`. Round 4 holds the 97-row claim enumeration.
- Reviewer agents in this task: 5 (one plan review, four code-check rounds).

## Owed

- Check the live site shows both new titles and the article addresses unchanged.

Closed by: PR (to be opened from branch `152-next-pass-on-the-two-flow-change-article`)
