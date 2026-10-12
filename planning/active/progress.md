# Progress — Publish per-segment discharge (#7)

## Session 2026-10-12

- Plan-mode exploration and discussion: STAC dropped; layout, naming, bucket, `forcing` key and time base settled with the user; phases approved
- Created branch `7-publish-per-segment-discharge-parquet-st` off main
- Scaffolded PWF baseline from issue #7 with approved phases
- Next: start Phase 1
- Phase 1: rewrote #7's body and title; wrote `research/discharge_publish.md` with its index row; filed the bucket-policy issue in the infrastructure repo (private, so not linked here)
- Phase 2: crate#31 filed. Two `schema_only` YAMLs at the dataset-ID paths, the path-rule integrity test, a decision entry; crate suite 419 pass. Committed on crate branch `31-discharge-schemas` (worktree) and pushed; review is folded into this branch's /code-check rounds
- Phase 3: `wet_catalog()` plus internal `wet_manifest_write()` and `wet_part_parse()`; fixture tree built by `data-raw/discharge_fixture.R`; 28 tests pass. The fixture's part paths run to ~120 bytes, over tar's 100-byte portable limit; checked under devtools::check() in Validation
- Phase 4: `wet_db_load()`: md5-checked fetch into a cache, a duckdb read with `hive_partitioning = false` (it otherwise doubled the key columns), and a load in one transaction; 26 tests on local fwapg in a `wet_test_*` schema. A mutation with the transaction removed turns the rollback test red
- Plan review returned (`review-plan.md`, 29 findings). Triage: B1 was already handled (tests rewrite the dataset ID into a throwaway schema); B2, G1–G4, G6–G8, G11, G12, G14 and G15 were taken into Phases 4b and 5; G16 dropped the pkgdown task; O3 moved `watershed_group_code` into the publish step so the segment table needs no rebuild; A3 (partitioned Postgres) was not taken: the load size and time are measured in Phase 6 instead
- Phase 4b: only a manifest ships (`inst/extdata/discharge_manifest.json`) and tests build the tree from `helper-discharge.R`; per-source provenance and crate schema refs in the manifest; `wet_catalog_verify()`; `wet_db_load()` refuses two picks per feature and month. Tests: catalog 34, db_load all pass
