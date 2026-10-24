# Progress — Order wet_ws_fetch() rows so province runs reproduce to the bit (#76)

## Session 2026-10-23

- Plan-mode exploration — phases approved by user
- Created branch `76-order-wet-ws-fetch-rows-so-province-runs` off main
- Scaffolded PWF baseline from issue #76 with approved phases
- Next: start Phase 1
- Phases 1-4 committed (1867a19, 3756962, 6570077, 92286e4); plan review (`review-plan.md`) and fetch sweep folded in (926af23, 7ed6abd, c40bb2b, bfd4a5c). Full suite 1,381 pass.
- `/code-check branch` round 1: Clean (`review-round1.md`); its note on basin 925 reproduced and the findings row corrected.
- Round 2: one fragile finding (`review-round2.md`): `wb_upstream_order.R` summed each run's own codes and areas, so a difference in inputs would read as one of order. Fixed: the second run supplies only the order (`b <- a[match(id_b, ...), ]`); two-way scratch test rerun (branch identical, main's sums stop on basin 100).
