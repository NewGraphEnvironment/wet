# Progress — Per-year ERA5-Land snow for a watershed, and the regression of the Maxan window series on peak SWE and melt date (#121)

## Session 2026-10-26

- Plan-mode exploration — phases approved by user, parked (`park` at the gate)
- Created branch `121-per-year-era5-land-snow-for-a-watershed` off main
- Scaffolded PWF baseline from issue #121 with approved phases; Plan review run synchronously, findings in `review-plan.md`, folded into `task_plan.md`
- Next: parked 2026-10-26; resume with the command below, then "start Phase 1"

### Resume

```bash
cd /Users/airvine/Projects/repo/wet && git fetch -q origin && git checkout 121-per-year-era5-land-snow-for-a-watershed && git pull --ff-only && git merge origin/main
```

The approval covered the baseline only; the run-to-PR mandate (`agent-operations.md` §4) starts when the user says to resume. Phase 1 commits `scripts/departure_snow.R`'s header alone before any body code.

## Session 2026-10-26 (resumed, 21:01 UTC)

- Resumed on the user's instruction; branch already current with origin and main.
- Phase 1: `scripts/departure_snow.R` header committed alone. Beyond the plan's wording it fixes three things before any body exists: predictors centred on each watershed's 1981-2010 mean (intercept = departure at normal snow); the parity line checks that the shipped normals were built from the bands read (their cache key reproduced in `tempdir()`); a year with cover below 1 is refused.
- Phase 2: `wet_snow_annual()` with 37 synthetic-layer expectations. The catalog, file, cap and band checks moved out of `wet_snow_normals()` into internal helpers unchanged (its 28 tests pass; its cache key does not involve them). The default `cap` applies only when `swe_max` is asked for. Mutation: without the dissolve, the union-identity and nested-polygon tests fail. The example reads the Phase 3 bundle.
