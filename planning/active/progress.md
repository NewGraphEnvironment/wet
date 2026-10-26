# Progress — PCIC per-year routed flow: keep the years, weight donors by modelled covariance, and score donors, PCIC and a blend at held-out gauges (#122)

## Session 2026-10-26

- Plan-mode exploration; three gate questions asked and answered (sequencing, windows, blend); Plan review run synchronously and folded in (`review-plan.md`)
- Phases approved by user as **parked** (baseline only)
- Created branch `122-pcic-per-year-routed-flow-keep-the-years` off main (fa9b31f)
- Scaffolded PWF baseline from issue #122 with the approved phases
- Next: parked 2026-10-26; resume with the command below, then "start Phase 1"

### Resume

One machine runs the branch at a time: the push at park handed it off, and the resume takes it. The run-to-PR mandate starts at the resume instruction, not at the parked approval.

```bash
cd ~/Projects/repo/wet && git fetch -q origin && git checkout 122-pcic-per-year-routed-flow-keep-the-years && git pull --ff-only && git merge origin/main
```

Then "start Phase 1 of planning/active/task_plan.md". Phase 1 is the rule header alone, committed alone, before any candidate is coded. Phase 3 (fwapg#42) runs in the fwapg checkout under its own `/planning-init fwapg#42` gate and needs this machine (the `pcic` schema in the local fwapg database, the crosswalk staging, the fit bundle).

## Session 2026-10-26 (resume)

- Resumed on instruction; branch current with origin and main; CI green.
- Phase 1: probed `pcic.subbasin_daily`'s precision (float64; findings), wrote the rule header of `scripts/departure_pcic.R`, committed it alone before any candidate.
- Next: Phase 2 (wet reads the years; synthetic fixture).
- Phase 2: `wet_routed_years()` (reads only the named sub-basins through duckdb, refuses a missing, repeated or non-calendar day and an NA flow, routes with `wet_routed_days()`), the synthetic fixture (4 sub-basins, 1951-2012, 400 KB; a losing reach exercises the clamp) and 24 test expectations; exported under a widened "PCIC runoff and routed flow" pkgdown section.
- Phase 2: `wet_departure_carry(weights =, modelled =)` through the internal `wet_donor_weights()`; default byte-identical; mutation table in findings.
- Phase 2: `wet_routed_years()`, its fixture and tests moved to fwapg#42's decided layout (one file per year, `date`, float32; fixture gains a `pcic.series`-shaped catalogue); the fixture regenerates byte-identical.
