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

## From research/chinook_sites.md (moved by #189)

## 1951–1980 against 2016–2025 (#152)

The comparison article now measures change from 1951–1980 to 2016–2025. 1951–1980 comes before global warming sped up (Hansen et al. 2012, who chose it for that reason), and ERA5-Land's snow reaches back to 1950. Section 5 of each site report (registered at b66b577 before any body code) gives both routes over those periods, computed after #126's draws and outside the parity gate's `mx_core`. The rerun changed every report by additions only. Each period has 20–30 years of 1951–1980 and 9 or 10 of 2016–2025: approved HYDAT ends in 2024 for most series, and in 2025 for every Swift series and some of Naver's filled-in ones.

**The intervals hold their coverage.** Each interval was put through 1000 simulated no-change series, normal with the series' own SD in each period and the same residual pool. They covered 0.904–1.000. The article calls a change interval a 90 % range only above 0.87, so every change range it draws on qualifies; it does not call the years figure's OLS band a 90 % range, because its held-out coverage in the site reports is 83–85 %. Not tested: autocorrelated years, and donor sets that differ between the periods. The measured article's percentile bootstrap of a ratio of means has no residual. It covers only 0.834–0.867 at its 9 or 10 recent years (`data/checks/departure_interval_coverage.txt`), so that article does not call its range a 90 % range.

Change, Bulkley windows unless named, carried / extended, with the 90 % range:

| site | spawning mean | migration mean | spawning min7 | migration min7 |
|---|---|---|---|---|
| Maxan | -45 % (-67..-11) / -57 % (-76..-28) | -16 % (-35..+7) / -28 % (-46..-5) | -40 % (-63..-2) / -58 % (-78..-21) | -17 % / +4 % |
| Swift | -15 % (-32..+5) / -27 % (-47..0) | -5 % / -4 % | +1 % / -18 % | +49 % (-2..+123) / +55 % (+8..+125) |
| Naver | -46 % (-69..-5) / -40 % (-67..+6) | -11 % / 0 % | -33 % (-56..+5) / -25 % | -20 % / +14 % |
| Gosnell | -35 % (-56..-3) | -4 % | -26 % (-49..+13) | +38 % |
| Gosnell, Morice windows | -23 % (-50..+15) | -8 % | -31 % (-57..+10) | +12 % |

- **The spawning-window drop holds** on the earlier reference: it is largest at Maxan and Naver and smallest at Swift. The carried range clears no change at Maxan, Naver and Gosnell, as against before 1981.
- **The migration window** shows no clear change on the carried route at any site. Maxan's extended route, whose 1951–1980 years rest on the Bulkley at Quick (08EE004) and Goathorn Creek near Telkwa (08EE008), falls by 28 %, with a range below zero.
- **The lowest seven-day flow** in the spawning window, carried, falls at Maxan, Naver and Gosnell (the range clears no change only at Maxan) and holds at Swift (+1 %; extended, -18 %). Its carried held-out scores are below #120's 0.5 bar in 7 of the 8 site-windows (0.23–0.59), so it is the weakest statistic the article shows.
- **Snow** over each target's watershed, 1951–1980 to 2016–2025:
  - peak SWE fell 6–9 % (Maxan 260 → 235 mm, Swift 555 → 524, Naver 243 → 223, Gosnell 974 → 891);
  - the 50 % melt date came 9–16 days earlier.
  
  At the measured snow gauges, migration-window flow rises with peak SWE at all eight, with a range above zero and R² 0.25–0.62. In the spawning window R² is at most 0.31. The 50 % melt date explains more there at two gauges: 64–66 % of measured spawning-window flow at the Nanika (08ED001) and Morice (08ED002), Gosnell's snow gauges, under the Bulkley windows. Elsewhere it explains at most a third, and 18–19 % at those two gauges under the Morice's later windows.
