# Progress — Articles: bring the three vignettes to soul's current writing convention (#110)

## Session 2026-10-23

- Plan-mode exploration — phases approved by user
- The user asked whether the citation helper belongs in `xciter`, then judged it probably not worth the dependency yet; recorded as gate decision 2
- Created branch `110-articles-bring-the-three-vignettes-to-so` off main
- Scaffolded PWF baseline from issue #110 with approved phases
- Next: start Phase 1
- Rendered all three articles on main (wet 0.4.17 installed) into the session scratchpad as the before copy for the text diff
- Phase 1: `wet_software_cite()` and `wet_software_line()` (internal) with tests; mutation check (any `RemoteSha` printed as a commit) fails 4 expectations; monthly-flow calls the helper; filed NewGraphEnvironment/xciter#6 for the later move
- Plan review (Plan agent) landed with no blockers: `planning/active/review-plan.md`, each finding with what was done. Folded in: install the branch before every render, `Kendall` and `zyp` for station-flow, the balance's inputs on segment's Data line
- Phase 2: segment-discharge edited and rendered against the installed branch; every guard passes. Body prose 899 → 829 words (cap 900, counted to the `## Software and citation` heading); 1,068 with the closing section; file 414 → 447 lines. Rendered-text diff against main read change by change: only the planned prose moved. Score table: one "Table 2" caption, its note in the footer, no `NA` style
