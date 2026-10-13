# Progress — Segment-discharge vignette: lead with the published product and read it from the manifest (#64)

## Session 2026-10-13

- Plan-mode exploration; phases approved by user. Decisions: no republish (rebuild on m4 and check md5s against the live manifest); SALR is the one worked basin.
- Created branch `64-segment-discharge-vignette-lead-with-the` off main
- Scaffolded PWF baseline from issue #64 with approved phases
- Next: start Phase 1

- Phase 1 code: `wet_values_compare()` lives in `R/` rather than the publish lib, so the vignette data script uses the same definition. Its tests went red under each of 6 mutations (one-sided keys either way, NA on one side, tolerance, month in the key, duplicate refusal).
- Measured on m1: fwapg's routed fingerprint total is `sum(round(q * 1e6))` over the 40,524,444 values exactly (178035348.248310), so the BUILD's total check can require string equality. Reading the whole table into R took 14 s.
