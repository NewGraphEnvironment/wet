# Progress — Backlog move 3: Article bundles and maps that rebuild identically, and the docs (#165)

## Session 2026-11-15

- Plan-mode exploration — phases approved by user (gate: drop the Nechako from the article; lakes and streams onto fresh's fetchers; second-database comparison reports only)
- Created branch `165-backlog-move-3-article-bundles-and-maps` off origin/main; move #165 claimed (in-flight label)
- Scaffolded PWF baseline from issue #165 with approved phases
- Next: start Phase 1
- fresh upgraded to 0.53.0 (no fetcher changes in its NEWS); pcic reload from fwapg 5d50cc1 running in the background (`data/logs/165/pcic_load.log`)
- #55 committed (7bbeda0)
- #97: Ecosystem block rendered from soul's `ecosystem.yml` (`ecosystem_registry.py render --readme README.md --member wet`), gq on a line below it; every link on newgraphenvironment.com or the upstream site (fwapg: smnorris.github.io/fwapg); R CMD check badge added first (the convention since 2026-11-10; the workflow runs on every push to main). All 29 URLs answer 200. Body prose 402 -> 408 words (the gq sentence); the table has 10 rows (was 5). README tagline ("Stream flow and water temperature for BC's Freshwater Atlas") differs from the registry's wet tagline ("Typical flow in nearly every stream, tested against gauges; station flow and temperature"): reported, not changed (readme.md rule 2 is the registry's and soul#835's to settle).
