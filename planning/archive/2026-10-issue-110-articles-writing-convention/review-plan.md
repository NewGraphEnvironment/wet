# Plan review for #110 (Plan agent, spawned 2026-10-23 22:29 UTC, delivered as reply text)

No blockers. Findings, most severe first, with what was done:

1. Ordering: branch install is in Phase 4 but Phases 2–3 render. -> Install the branch before every render (local install, as main's before-render was).
2. Gap: station-flow's software list lacks `Kendall` and `zyp`, which `cd::cd_trend()` calls at render; `tidyhydat` runs only in the bundle script and the unevaluated recipe. -> Add `Kendall` and `zyp`; keep `tidyhydat` (it produced the bundled flows).
3. Gap: segment Data line omits the balance's inputs (climr normals, the AET product). -> Added.
4. Gap: word guard cut must refuse a missing or duplicated heading. -> Already `stopifnot(length(cite) == 1)`.
5. Gap: the helper prints the version without checking a release tag is at or before the commit. -> Accepted limit: the site builds from main after release, where version and tag agree; recorded in findings.
6. Gap: decision 4 rewrite must keep the "too few gauges ... get none" clause its guard backs. -> Kept.
7–9. Assumptions confirmed (`wet:::` precedent; kableExtra footnote proven in monthly-flow; date and commit already printed).
10. Rename the "# Cached inputs." comment in segment's provenance chunk. -> Done.
11. `gh()` stays in use (build-report and method links).
12. research/water_balance_method.md:86 cites fwapg#24 as the cause of the Nechako share; still true (issue open) and research may cite issues, so left. CLAUDE.md:50 updated in Phase 4.
13. `fwapg` first mention: now links the repository, with the fork's placement PR beside it.
14. The reader-pass rules' items 1–3, per article: added a read step at render (terms from sibling articles, prose repeating a table, statistics defined).
15. "The latest years are provisional": relative to the five years shown, computed; kept as a judgement call.
