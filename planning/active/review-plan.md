# Plan review (#77), Plan agent, 2026-10-15 03:2x UTC

Findings in brief; the full reply is in the session transcript. Disposition in brackets.

- **Blockers:** none. PUBLISH, the post-upload BUILD (`:178` diffs 1718a3d..HEAD, empty), `vd_published()` and `vd_commit()` all pass in the phase order. [confirmed by the upload and BUILD runs]
- **O1** Push eb17bca before the m4 BUILD. [done before the BUILD]
- **O3** Keep the load script outside the repo: an untracked file under R/, scripts/ or data-raw/ trips the dirty checks. [it is in m4 `~/wet77/`]
- **O4** No R/ or scripts/ change before the post-upload BUILD. [held]
- **G** Stale prose: monthly-flow.Rmd :460-463 (recomputed), :569-572 ("no snow term"), :674-675 (#68 gap), :721-723 (validation); CLAUDE.md:48 gaps list (#16 and #68); NEWS.md:3 ("until #77"); research/water_balance_method.md:447 ("not yet uploaded"); research/discharge_publish.md:5. [Phase 4]
- **G** More stopifnots the snow shares may break: :522 (Liard winter, within < 50, routed closer May-September), :630 group table, :334/:342 window table. [Phase 4]
- **P3a** Check `cv_share` is `cv_shares[[share_spec]]`; the score check only proves `cv_v` was scored from the stored arrays. [added; fires on a swapped spec]
- **P3b** A NULL `cv_share`/`share_spec` (pre-#16 fit) passes the spec check and fails obscurely in `long()`. [added; fires on NULL]
- **P3c** The header blamed BLAS; `wet_flow_validate()` uses none. [reworded to summation across architectures; all.equal kept]
- **A** Byte identity needs the same arrow 25.0.1 / duckdb 1.4.3 / crate 0.7.0 on m4. [checked: same]
- **A** `wet_db_load()` replaces in one transaction, so the table roughly doubles on disk until VACUUM. [506 GiB free on m4; VACUUM after the load]
- **A** m1's fwapg holds no discharge tables (memory note, 2026-10-14). [nothing to reload there]
- **Acceptance** Stop if the rebuild is not 67 of 67, or fails a check; compare reader lines with a18406a's. Never run `WET_PUBLISH=1` from the rebuilt tree: its manifest names the branch HEAD and would replace the live acb820f manifest. [Phase 2]
