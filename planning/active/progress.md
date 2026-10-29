# Progress — Merge the segment-discharge and monthly-flow articles into one article on the published product (#149)

## Session 2026-10-29

- Plan-mode exploration — phases approved by user (gate: keep the segment-discharge address, score on 279 gauges, Fixes #80, take #74's recipe fix)
- Created branch `149-merge-the-segment-discharge-and-monthly` off origin/main
- Scaffolded PWF baseline from issue #149 with approved phases
- Next: start Phase 1
- Phase 1: rendered both articles from the installed 0.4.29 into the scratchpad. Body prose is 829 + 1,543 = 2,372 words. The Plan review was spawned at 23:22Z.
- Phase 2: wrote the merged `vignettes/segment-discharge.Rmd` and removed `vignettes/monthly-flow.Rmd`. Body prose is 1,740 words by the cap rule (2,372 before, forecast 1,800–2,000); rendered text up to the citation section is 2,296 words (3,203 before). The cap is now 2,000.
  - New guards: both bundles name one build, read date, fit, AET and routed run. The yearly and monthly rows score the same gauges, with the same observed and held-out runoff and the same 11 far-low gauges in both bundles. Month by month the two sources score about the same (median NSE within 0.05, gauge-months within ±20 % within 5 points); this guards the corrected lead sentence of "How good it is".
  - Guards removed with their sentences: #80's `n_both_src > 0.5 * n_with`; monthly-flow's check that `windows` has the shape `wet_flow_window()` and `wet_window_stats()` document (the paragraph about window tables is cut and the windows link to the flow-change article); `r_closer` (the months where routed has more gauges within ±20 %); `n_un`, `n_un_10` and `un_winter` (the balance in winter at the gauges routed PCIC does not reach); and the 12-row month table's and the NSE group table's formatting checks.
  - Corrected during the render: my first lead said the balance is "less precise" month by month, but the table it introduces gives routed 40 % and the balance 42 % of gauge-months within ±20 %, with median NSE 0.82 for both. It now says the two score about the same month by month, and a guard holds that.
  - #74's recipe fix: the duckdb group read runs `INSTALL httpfs; LOAD httpfs;`.
