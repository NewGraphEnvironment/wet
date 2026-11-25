# Code check, the enumeration that ends the loop (#169, 2026-11-25)

Round 4 found two defects inside round 3's fixes (the map key's comment claimed more than the key covers; `run_files()` was still a copy of the fetch's file name), so by the stopping rule only an enumeration ends the loop. The mechanism, named by round 3: **code keeps its own hand-written copy of a set or format another piece of code defines.** Every such copy in the branch's diff, its source of truth, and how it was checked (2026-11-25, at the tree after round 4's fixes):

| # | copy | source of truth | check | verdict |
|---|---|---|---|---|
| 1 | `gcms6` (scenario_basis.R) | the pilot's `gcms` | parsed both, `identical()` | sound |
| 2 | `ssps` | the pilot's `ssp245`, `ssp585` | `identical()` | sound |
| 3 | `cmip5` GCMs and members | PCIC's catalog (169 datasets, read 2026-11-25) | the six RCP 4.5 run names equal the catalog's | sound |
| 4 | `pnw_run`, `vars` | the catalog | `TPS_gridded_obs_init`, RUNOFF and BASEFLOW present | sound |
| 5 | `domain_of()`, `domains` (lib) | the pilot's | `identical()` on every subid prefix | sound |
| 6 | `batch_name()`, the bulk directory name | the pilot's | `identical()` output; reviewers resolved all 74 markers | sound |
| 7 | the crosswalk flag `no_series` | `pcic.fwa_crosswalk` | its flags enumerated: broken_chain, demoted, no_candidate, no_series, NULL | sound |
| 8 | listing columns | hydromosaic's listing | `listing()` refuses a body without them before caching | sound (round 1 fix) |
| 9 | the gridded file name (`run_files()`) | `wet_pcic_fetch()` | now asked of `wet_pcic_fetch()` with a refusing base | fixed in round 4 |
| 10 | request outcomes logged | `wet_pcic_fetch()`'s loop | the hook fires per request; two mutations go red | sound (round 1 fix) |
| 11 | the pilot report's columns: `wet acc` (6), with outlet (3), GCMs (4), verdict (after pass/fail) | the tracked pilot report | header regex for `wet acc`; with-outlet held to the computed 73; GCMs 9/8/9/9 and verdicts read and printed | sound |
| 12 | rule 3's product per domain (pcic_coverage.R) | the pilot's verdict column | now read from it, refused unless a product | fixed in round 4 |
| 13 | scenario_basis's markers `not run: `, `CMIP5 score: not run: `, `verdict: ` and the pass text | scenario_basis.R's report lines | strings compared in both scripts | sound |
| 14 | segment report group columns (routed, balance picks) | `scripts/segment_output.R`'s report | every group's picks held equal to the parts' | sound |
| 15 | publish report rows and picks | `vd_published()` | shared lib; totals held | sound |
| 16 | source names `pcic_routed`, `wet_balance` | the parts | `vd_published()` asserts the set; a rename would fail the row totals | sound |
| 17 | coverage classes (published, scenarios) | pcic_coverage.R | map: both class sets now checked against the registry's | fixed in round 4 (published side) |
| 18 | the gridded subset file pattern and the excluded test box | the cache | `length == 3` | sound for this cache; a new box would stop the script |
| 19 | map layer key | its inputs | covers code and constants; the comment now says it does not cover the data | fixed in round 4 |
| 20 | scripts hashing a changed R file | the repo | grep: only `wb_term_diagnose.R` (and `wb_small_basin.R` through it) | #226 |
| 21 | `discharge_publish_own.R` entries | what the table scripts source and call | reviewers 1 and 3 traced it | sound |
| 22 | CMIP5 inputs named in the report | the files read | per-run count and md5 now printed | fixed in round 4 |

Nothing in the set sits above its source of truth after round 4's fixes.
