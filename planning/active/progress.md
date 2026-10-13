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
