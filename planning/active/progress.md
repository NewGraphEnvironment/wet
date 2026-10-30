# Progress — station-flow article: retitle to stream flow, cite from a Zotero .bib, apply the writing conventions (#145)

## Session 2026-10-30

- Plan-mode exploration — phases approved by user
- Created branch `145-station-flow-article-retitle-to-stream-f` off origin/main
- Scaffolded PWF baseline from issue #145 with approved phases
- Next: start Phase 0
- Phase 0: four trend works added to the group library through the Web API (key from cyclops' materialized file); BBT keys from `data.citationKey`. "Zotero empty reply" was `~/.curlrc`'s browser user agent; soul#590 filed (stale key path in `/zotero-api`, and the UA).
- Phase 1 (601e0b9), Phase 2 (f4a0387), plan review folded in (70c6891; `planning/active/review-plan.md`).
- Phase 3 and 4: article rewritten against every `writing.md` rule; `data-raw/vignette_bib.R` writes `vignettes/flow-departure-normal.bib` (20 entries). `knitr::write_bib()` was measured to take the DESCRIPTION entry (wet without its DOI, ggplot2's manual), so packages come from `utils::citation(pkg)[[1]]`; Zotero `@software` entries become `@misc` titled by the repository name.
- Measurement (writing.md "Measure the simplification"): body prose 581 → 700 words (cap raised 600 → 700 at the gate), file 704 → 756 lines. The forecast was "under 700 with the additions"; the first draft came to 751, and cuts to captions' restatements and the recipe's repeated software list brought it to the cap. What set the floor: the answer-first opening, the timing-window section, the place sentence and 23 inline citations (each `[@key]` counts as a word).
- Rendered with `pkgdown::build_article()`: every guard passes; 23 citations, 20 references, no `???`, no footnotes.
