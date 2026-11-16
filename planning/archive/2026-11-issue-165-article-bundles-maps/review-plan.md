# Plan review — #165 (Plan agent, 2026-11-16)

Findings returned as reply text and recorded here; disposition in brackets.

## Blockers
- B1. `tests/testthat/test-vignette_data.R:124` expects regions Liard and Nechako Reservoir. [fixed: Liard only; committed with the article, map and bundle]
- B2. The article holds the segment map's `built` equal to the values' (`segment-discharge.Rmd:57,65`); the keep rule with `drop = c("built", "wet_commit")` would keep an older read date. [fixed: the segment map drops nothing, so it is kept only on a same-day rerun at the same commit; the vm_* maps carry no date]

## Gaps
- G1. Recipe must come from the article's text, the comparison read independent, perturbations named. [already done: the chunk is parsed out of the committed .Rmd and evaluated; the comparison picks parts by catalog column, `hive_partitioning = false`; perturbations month = 1, no `pick`, MORR to be run in a worktree copy. `scenario = 'historical'` cannot be told apart while one scenario is published]
- G2. Streams via fresh: per-key calls, include_all, st_zm, NA-ignoring max, R's GEOS, AOI WKT digits. [done in code; sf's GEOS and PROJ added to provenance]
- G3. m4 rebuild needs an output override; the segment map creates a temp table. [WET_MAP_OUT_DIR; the m4 comparison covers the four vm_* map scripts]
- G4. `map_asp` attribute not compared. [fixed: vm_write compares every list attribute]
- G5. Receipt keys unguarded. [fixed: article and test hold recipe_id equal across the three bundles; recorded from the manifest's copy, which `wet_catalog()` validates]
- G6. WET_FWAPG_COMMIT belongs on the data scripts. [noted]

## Ordering
- O1. Run the three dated bundles at one HEAD on one day, committing after. [adopted]
- O2. readme_figure.R last. [adopted]
- O3. Map order free; commit code before vd_commit() scripts. [adopted]

## Assumptions
- A1. Determinism evidence is run 2's vm_compare table and run 3's mtime, not md5. [adopted]
- A2. chinook article prints the Gosnell report's whole-build digest, no longer the live one; its values hold (parts unchanged). [accepted; reported]
- A3. README word count 582 counted differently; measured 402 -> 408 body words. [noted]
- A4. ST_Normalize on rivers may reverse direction; drawing only. [comment added]

## Scope
- S1. research/discharge_publish.md:5 and research/water_balance_method.md:86 say the bundles hold the older build. [to update in Phase 5]
- S2. NEWS. [left to /gh-pr-merge]

## Acceptance
- C1. Visual check of map figures and readme-pick.png against main. [added to Phase 6]
- C2. First run is the baseline and is expected to write. [adopted]
