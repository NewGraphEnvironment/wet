# Progress — Publish per-segment discharge (#7)

## Session 2026-10-12

- Plan-mode exploration and discussion: STAC dropped; layout, naming, bucket, `forcing` key and time base settled with the user; phases approved
- Created branch `7-publish-per-segment-discharge-parquet-st` off main
- Scaffolded PWF baseline from issue #7 with approved phases
- Next: start Phase 1
- Phase 1: rewrote #7's body and title; wrote `research/discharge_publish.md` with its index row; filed the bucket-policy issue in the infrastructure repo (private, so not linked here)
- Phase 2: crate#31 filed. Two `schema_only` YAMLs at the dataset-ID paths, the path-rule integrity test, a decision entry; crate suite 419 pass. Committed on crate branch `31-discharge-schemas` (worktree) and pushed; review is folded into this branch's /code-check rounds
- Phase 3: `wet_catalog()` plus internal `wet_manifest_write()` and `wet_part_parse()`; fixture tree built by `data-raw/discharge_fixture.R`; 28 tests pass. The fixture's part paths run to ~120 bytes, over tar's 100-byte portable limit; checked under devtools::check() in Validation
