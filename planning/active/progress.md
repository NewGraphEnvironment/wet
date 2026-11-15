# Progress — Backlog move 2: The published build's record (#164)

## Session 2026-11-15

- Plan-mode exploration — phases approved by user (gate: receipt beside the manifest; `discharge.wet_load`; fits.rds + group samples as parquet; move-1 owed items carried to #165)
- Created branch `164-backlog-move-2-the-published-build-s-rec` off origin/main (797a5d4); claimed #164 (`in-flight`)
- Scaffolded PWF baseline from issue #164 with approved phases
- Next: start Phase 1
- Phase 1 (#108): the manifest's `pcic_routed` description names the February fold beside the clamp; `wet_segment_daily()`'s roxygen gave the clamp alone and now gives both. `research/discharge_publish.md` and crate's `segment_daily.yaml` already gave both; no test or report reads the text. Byte-identity of the parts is proved by Phase 5's BUILD.
- Phase 2 (#88): `wet_db_load()` writes `<schema>.wet_load` (columns from `cols_load`, PK dataset/scenario/key) in its transaction; comment unchanged. Three new tests (record, failed load leaves it, recipe_id from `attr(catalog, "receipt")`); 11 of 11 pass against m1's fwapg. Mutations: no DELETE → 2 tests fail; DELETE without the dataset filter → 1 fails.
- Phase 3 (#161): `inst/receipt/discharge_fwa_v1.yaml`, `wet_receipt_write()` (crate's writer, recipe_id read back from the file since the installed crate ecadfc6 returns the write's value, not the receipt), `wet_manifest_write(fit =, receipt =)` (parquet under `fit/` is not a part), `wet_catalog()` attributes `receipt` and `fit`, internal `wet_catalog_files()`. Digest kept parts-only (see the corrected checkbox). crate in Suggests (>= 0.16.0) and Remotes. test-wet_catalog.R: 4 new tests pass; mutations (no `fit/` exclusion → 3 fail; no duplicate-key check → 1 fails).
