# Progress — Snow predictors for the monthly shares (#16)

## Session 2026-10-14

- Plan-mode exploration; phases approved by user (province key: new layers, new key; keep rule: blocked-CV median share NSE +0.01 overall; publish: build, don't upload)
- Created branch `16-snow-predictors-for-the-monthly-shares` off main
- Scaffolded PWF baseline from issue #16 with approved phases
- Next: start Phase 1
- Phases 1–4 committed: cd checks (6d9a84b), #68 storage (73e9acc), `wet_snow_normals()` (3306477), province layers and share-fit docs (1d530a1)
- Phase 5: `predict_cv()` holds out both share specifications in the same folds; `wb_validate.R` applies the pre-set rule (blocked-CV median share NSE over gauges with both, gain >= 0.01) and stores both; `scripts/wb_share_snow.R` breaks it down from stored months. Smoke-tested on a synthetic fit in a scratch worktree (report renders; the `_pre16` identity guard stops on a 1e-9 change in one `cv_ann`). This commit is the rule's pre-registration: no snow-predictor score existed before it.
- Plan review (Plan agent) folded in before any score: `review-plan.md`. Predictor probe → user capped swe_max at 3,000 mm (2026-10-14). Rule metric made exact (held-out shares directly, paired, unrounded gain ≥ 0.01).
- `/code-check branch`: round 1 (3 fragile, fixed 67b2d6b), round 2 (1 bug: identity gate could never pass; 2 fragile; fixed f550adc), round 3 (mechanism "one fact read twice" enumerated over 15 places; 1 fragile fixed bf84a89). Ended by round 3's enumeration.
- m4 (worktree `~/Projects/repo/wet-16`, branch `16-run`, input dirs and `data/wb`, `data/snow` linked to the main checkout): `wb_inputs.R` (snow grid `snow_19812010_4816dbcca8.tif`, 584 ERA5-Land cells capped), `wb_province.R 4` → key `e675918817` (17:12–17:28 PDT, snow fill 36 passes, 45,879 mask cells), old key set aside as `data/wb/_pre16/962a9cc2c4/`.
- Identity gate first failed on row order (#76, unordered fetch); made tolerant (8b80785) and passed: 24 basins, 3,245,453 watersheds, worst relative 6.6e-14.
- Fit chain started 2026-10-15 00:32 UTC (`data/logs/16/chain.sh` on m4).
