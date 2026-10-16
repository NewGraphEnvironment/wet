## Outcome

The shipped fit `fit_20260717` is current again under #89's scoring code (md5 `a80b045ab7a74678d4dff01dddf77fcb`). On m4 every AET variant was rescored, `wb_aet_compare.R` re-decided with cfu as the incumbent and chose cfu, cfu was shipped, and `wb_share_snow.R`, `wb_output.R`, `pcic_routed_compare.R`, `segment_output.R` and a `discharge_publish.R` BUILD were rerun. Their reports are committed. Nothing changed but the stamps, so nothing was uploaded. `monthly_vignette_data.R` runs and its `.rds` was regenerated (provenance only). `segment_vignette_data.R` still refuses: it requires the live manifest's `segment_commit` (1718a3d) to match the tracked segment report's commit, which has not held since #81. The plan review found this (B1), and the user chose not to republish identical parts for it; the next publish that changes values fixes it. The review also found that `segment_output.R` needs `WET_FWAPG_COMMIT` (B2), which was set for the whole chain. `wb_term_diagnose_20260717.txt` and `wb_gauge_diversion_20260717.txt` still name the old md5 (diagnostics, not rerun). Research: `research/water_balance_method.md` §0, "The AET incumbent since #89", now records the run on the shipped fit.

## Measurement

- Compare on HYDAT 2026-07-17 with cfu the incumbent: the nested selection chose cfu in 94 of 94 outer folds (under cgiar as the incumbent it was cfu 68, fu 26). Headwater MAE: nested 32.5 % against cfu as shipped 30.7 %, so (d) prints fail while cfu wins. The as-shipped table is unchanged. This confirmed the #89 sandbox on the real fit.
- Identity against the set-aside `_pre91` copy:
  - All ten `cv_aet-*.rds` are identical apart from `code_md5`.
  - `fits.rds` is identical apart from `code_md5` and `aet_md5`.
  - `cv_ann` and `cv_share` are identical.
  - The 24 output parquets and the 23 segment parquets are byte-identical.
  - The BUILD matches the live acb820f on 67 of 67 parts.
- Report diffs:
  - Unchanged: the ten per-variant reports, `wb_validation_20260717.txt` and `wb_output_20260717.txt`.
  - One stamp line each: the snow-share, routed, segment and publish reports.
  - Rewritten in substance: `wb_aet_compare_20260717.txt`.
- m4 durations: scoring all ten variants, 2 min 11 s; the compare, 3 min 25 s; the output chain through the BUILD, 17 min.

## Evidence

Logs: `data/logs/91/` in m4's main checkout (moved there from the removed `wet-91` worktree): `chain2.*`, `chain3.*`, `check_ship.*` and per-step `*.log`. On m1, `data/logs/91/m1_*`. Reports: `data/checks/*_20260717.txt` (tracked).

Closed by: PR (branch 91-rescore-fit-20260717-under-89-s-scoring)
