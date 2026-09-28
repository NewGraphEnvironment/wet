# Progress — MOD16 AET as a challenger to the shipped annual AET (#18)

## Session 2026-09-27

- Plan-mode exploration — phases and the pre-set decision rule approved by user
- Created branch `18-mod16-aet-as-a-challenger-to-the-shipped` off main
- Scaffolded PWF baseline from issue #18 with approved phases
- Next: start Phase 1 (probe a MOD16 tile)
- Phase 1 probe: MOD16A3GF uint16, fill codes 65529–65535, terra scales on read. CMR search is public, and curl with the earthdatalogin netrc downloads (findings).
- Plan review (Plan agent) folded in: `review-plan.md`. The rule was clarified before scoring: the (d) threshold, the frozen knobs, the transparency rows, and the stop if stage 1 does not return cfu.
- `wet_mod16_aet()` and 37 tests. The mutation checks fire: one-step average, fill-code mask, min_years, download validation, plausibility cap, and the great-circle densify.
- Real build started 04:43 UTC (180 granules, 9 tiles); log in data/logs/20260928_mod16_build.log (gitignored).
- /code-check on Phase 1, three rounds. Round 1: an empty extra tile row at 40/50/60 N edges (fixed with a 1 m tile shrink). Round 2: a projected grid was not refused (fixed with a lon/lat check). Round 3: Clean, and it named the shared mechanism (tile choice derived from the extent, not from what is sampled) and cleared every place it reaches.
- Phase 2–3 script edits: wb_province layers and counts, the wb_inputs manifest, wet_wb_aet_cols, and the two-stage wb_aet_compare.
  - A smoke run (SALR, OKAN) reproduced every old column.
  - Two compare dry runs against the #15 run reproduced #15 exactly and ran stage 2 end to end.
- /code-check, three rounds on the scripts. Round 1: the "full" count label was inverted. Round 2: untagged stage-2 rows, a loose granule manifest, and a stale "full" restatement in findings (a defect inside round 1's fix). Round 3: the period disclosure had been copied from the plan and was wrong for CGIAR.
  - It ended by enumerating all 29 report lines against their sources (`review-p23-enumeration.md`).

## Session 2026-09-28 (UTC)
- Full province run adc88b19c8 (13.5 min). It reproduces #15 (53 layers identical; upstream means within 5.4e-14 after matching by id; row order is not stable between runs).
- Scored all 10 variants and compared. Stage 1 reproduced #15. Stage 2: mod16 36.3 and cmod16 34.6 headwater against cfu 31.2, so **cfu stays**. Shipped fit, output and map re-run.
