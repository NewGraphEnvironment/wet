# Progress — Snow predictors for the monthly shares (#16)

## Session 2026-10-14

- Plan-mode exploration; phases approved by user (province key: new layers, new key; keep rule: blocked-CV median share NSE +0.01 overall; publish: build, don't upload)
- Created branch `16-snow-predictors-for-the-monthly-shares` off main
- Scaffolded PWF baseline from issue #16 with approved phases
- Next: start Phase 1
- Phases 1–4 committed: cd checks (6d9a84b), #68 storage (73e9acc), `wet_snow_normals()` (3306477), province layers and share-fit docs (1d530a1)
- Phase 5: `predict_cv()` holds out both share specifications in the same folds; `wb_validate.R` applies the pre-set rule (blocked-CV median share NSE over gauges with both, gain >= 0.01) and stores both; `scripts/wb_share_snow.R` breaks it down from stored months. Smoke-tested on a synthetic fit in a scratch worktree (report renders; the `_pre16` identity guard stops on a 1e-9 change in one `cv_ann`). This commit is the rule's pre-registration: no snow-predictor score existed before it.
