## Outcome

Set up pkgdown for wet and added its first vignette. The scaffold is `_pkgdown.yml`, drift's pkgdown workflow (which removes CLAUDE.md before the build and gates on an allowlist of root pages), `VignetteBuilder` and the vignette packages in Suggests. The vignette is `vignettes/station-flow.Rmd`, flow in species windows at 08EE013 and 08EE003.

- **Inputs.** It runs on a 61 KB bundle from `data-raw/station_vignette_data.R`: the daily series (HYDAT, provisional, real-time) with provenance, and the BULK windows from knowledge at a pinned commit. Window statistics, cd departures and trends run live, in 0.4 s.
- **Figures.** There are four: the record by source, the hydrograph against its 1981–2010 median with the species windows beneath, a departure heat strip, and Theil-Sen trends.
- **Colours** come from a gq custom registry. Every claim in the prose is computed and guarded.
- **Plan gate.** The user kept the script's provisional-winter drop rule, and the vignette lists everything it drops.
- **What was learned.** The defects that mattered were all one mechanism: prose computed from a different object than the figure or statistic it describes. The cases were:
  - "year-round" from a day count;
  - a dropped list from a column the figure overrides;
  - a trend start from the wrong table;
  - "normal" for a line that is the median.
- **How the review loop ended.** Four rounds: a plan review and three code-check rounds. Round 2 found defects inside round 1's fixes, so the loop ended only on an enumeration of every computed claim against its source (`findings.md`).
- **Planning-time error.** The "two duplicate CSV rows" claim was a misread, corrected in Phase 2.

## Measurement

- **Bundle size:** 61 KB, against the issue's 500 KB cap (rds xz 60 KB). `wet_window_stats()` takes 0.41 s on 32,312 days × 11 windows, which is why the stats are computed live rather than bundled.
- **`devtools::check()`:** 0 errors, 0 warnings. The 3 NOTEs (CITATION.cff, empty NEWS, timestamp) predate the branch. The vignette rebuilds under check.
- **Tests:** 590 + 14 pass. The pkgdown site builds locally with the article.
- **Vignette:** 511 words of prose, against a 600-word cap that was shown to fire at 400.
- **Results now in `research/station_flow_departure.md` § Species windows:**
  - CH spawning is 58–81% below its 1981–2010 mean at both stations in every year 2023–2026.
  - 5 of 68 distinct trend slopes are significant (about 3 expected by chance), all negative.
  - 08EE003 is winter-gauged only in 1971 and 2011–2026.
- **Reviews:** `review-27.md` (plan) and `review-round1..3.md`.

Closed by: PR (see `git log`), Relates to #27
