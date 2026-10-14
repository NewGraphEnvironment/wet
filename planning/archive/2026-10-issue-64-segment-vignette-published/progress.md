# Progress — Segment-discharge vignette: lead with the published product and read it from the manifest (#64)

## Session 2026-10-13

- Plan-mode exploration; phases approved by user. Decisions: no republish (rebuild on m4 and check md5s against the live manifest); SALR is the one worked basin.
- Created branch `64-segment-discharge-vignette-lead-with-the` off main
- Scaffolded PWF baseline from issue #64 with approved phases
- Next: start Phase 1

- Phase 1 code: `wet_values_compare()` lives in `R/` rather than the publish lib, so the vignette data script uses the same definition. Its tests went red under each of 6 mutations (one-sided keys either way, NA on one side, tolerance, month in the key, duplicate refusal).
- Measured on m1: fwapg's routed fingerprint total is `sum(round(q * 1e6))` over the 40,524,444 values exactly (178035348.248310), so the BUILD's total check can require string equality. Reading the whole table into R took 14 s.
- First m4 BUILD (6998c00, started 22:52 UTC) stopped by hand: the plan review's B1 showed it would crash at code 800 (no routed part). Fixed in 032242f.
- m4 BUILD at 032242f in worktree `wet-64` (`data/wb` linked to the main checkout's), 22:59:00 to 23:06:55 UTC (about 8 min, against 5 min without the value checks). 555,857,796 values compared, 0 differing. Every check is exact except routed month 0 against the mean of its 12 months (largest difference 9.09e-13 m³/s, R `mean()` against a sum over 12). Routed total 178035348.248310 equals the fingerprint. All 67 parts are byte-identical to the published build 7c62b9e (arrow 25.0.1, duckdb 1.4.3 on m4), so per the plan-gate decision there is no republish. Log: m4 `~/Projects/repo/wet-64/data/logs/64_build.log`.
- Phase 2 on m1: `data-raw/segment_vignette_map.R` cut to SALR (segment_map.rds 300 KB → 147 KB). `data-raw/segment_vignette_data.R` at 9e3ee30 read the published parts in 28 s (SALR from part 100; gauges from the routed parts). 2,180 SALR balance values were exact; 2,469 routed values (SALR and gauges) were within 1.1e-13. The published routed values reproduce the routed report's gauge MAE. Restore-the-bug: one SALR routed value scaled by 1.001 gives differing = 1 and a refusal, with the bundle unchanged (a first attempt perturbed a row outside the checked set and proved nothing; redone).
- Phase 3: vignette rewritten around the product, SALR the one basin, 1,093 words (cap now 1,200). Renders with `pkgdown::build_article()` once the branch's package is installed. Palette CSV trimmed: `segment_map/key`, `skill_nesting/mae`, `product`, `parity/segment` dropped; `parity` renamed `guide`.
- Phase 4: README, CLAUDE.md, `research/fwapg_mad_method.md` (the parity and sampling tables are now the record), `research/discharge_publish.md` (value checks). NEWS is written by the release step (`/gh-pr-merge`), as every NEWS commit in git log shows.
- Tests: full suite has 1 failure, an assumption in the new test (that SALR picks both sources; it picks routed on all 2,180), fixed.
- `/code-check branch`: three rounds plus an enumeration. Round 1: Inf counted as equal in `wet_values_compare()` (fixed, mutation-tested); two routed queries could give one segment two values (fixed, bundle rebuilt at 7b83959); the routed-total text comparison was accepted. Round 2: prose said every value or column is checked (narrowed). Round 3: five prose overclaims, one inside round 2's fix (a wrapped sentence the one-line grep missed). That ended the loop on an enumeration of all 116 added quantifier lines, which found two more. Full suite: 965 pass, 0 fail.
