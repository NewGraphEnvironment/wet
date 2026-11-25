# Plan review for #208 (Backlog move 15: re-run the segment chain and a publish BUILD)

Blockers raised: 0
Owner forks: 0

Review by a Plan agent, 2026-11-25, probed against the code where cheap. All folded into `task_plan.md`.

- Gap, folded: `WET_FWAPG_COMMIT` is read by the two segment scripts only, not the BUILD. Confirmed.
- Gap, folded: `git diff` cannot compare gitignored parquet; `tools::md5sum` with an `identical()` fallback. Set-aside is `mv`, since `segment_output.R:64` unlinks both tables (probed); disk check added.
- Gap, folded: run from the main checkout, not a worktree with `data/` symlinked; `wb_key_dir()` reads relative `data/wb` (probed, `scripts/wb_fit_lib.R:44`).
- Gap, folded: HEAD is v0.4.44 (probed), not 0.4.40; about 40 files changed since 66cf795; extra BUILD refusal probes (crate 0.16.0, arrow 25.0.1, S3 manifest, aet cfu, wb_output).
- Assumption, folded: byte identity assumes the same arrow and duckdb; the live manifest and receipt keep the old commit under "no upload", accepted.
- Scope, folded: the Phase 3 vignette-data run was creep (it rewrites `segment_values.rds`); dropped, as was the memory bullet.
- Acceptance, folded: exact pass line; the report has no `--` lines, only `ok`/`FAIL`.

## Files the plan names

scripts/segment_output.R
scripts/segment_daily_output.R
scripts/discharge_publish.R
scripts/discharge_publish_own.R
scripts/discharge_publish_lib.R
scripts/vignette_data_lib.R
scripts/wb_fit_lib.R
scripts/pcic_routed_lib.R
data/checks/segment_output_20260717.txt
data/checks/segment_daily_output_20260717.txt
data/checks/discharge_publish_20260717.txt
