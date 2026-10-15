# Task: Retire fit_20251014 as a gate: re-decide the AET on the shipped release (#81)

## Problem

The ET experiment (#15) chose the shipped annual AET on `fit_20251014` under a pre-registered rule. #43 made that fit a standing dependency:

- `scripts/wb_aet_compare.R:26` refuses any release but 20251014, because the comparison "reproduces #15".
- `scripts/wb_validate.R:28-79`: every newer fit carries the AET (`WET_AET_CARRY=20251014`). The carry refuses if `fit_20251014`'s winner is stale under the current scoring code, so...
- ...CLAUDE.md: "Any scoring-code change stales every fit, so `fit_20251014`'s chain is rerun first."

The costs:

- **Two full chains per scoring change.**
- **A superseded release as a live input.** ECCC serves only the current release (measured 2026-10-15: the download page lists only `Hydat_sqlite3_20260717.zip`, and the 2025-10-14 file returns 404). The 2025-10-14 file existed only at m4's tidyhydat default path, where one `download_hydat()` would have deleted it. A copy is now in m4's wet cache (md5 `da00052022aa1533b80f9fab7cb8b4d0`).
- **A question never re-asked.** Whether `cfu` still wins on 2026-07-17 has never been tested.

Keeping the 2025-10-14 release so #15 can be reproduced is fine. Requiring it on every change is the problem.

Decisions taken at the plan gate:
1. **Scored form: as the fit ships.** Each variant is scored with `fit_20260717`'s fixed pooled variant (`none`) and its 0.1-point gate override, and the compare's nested selection (d) applies both inside each fold. #15/#18's thresholds stay unchanged.
2. **Tag:** annotated `aet-15-record` on 353721a (v0.4.7), but only after m4 shows that `wb_aet_compare.R` at that commit reproduces `data/checks/wb_aet_compare.txt` byte for byte. research §0 cites 946da43 as where #15 was decided.
3. **`fit_20251014` on m4 stays in place** (2.0 MB). The tag's recipe reads it.

What exploration found:
- The scoring code is unchanged since 837ac0b (#16), and #16's rerun reproduced #15. m4's `fit_20251014/aet_winner.txt` is current (`cfu`, 363fdc69…). `fit_20260717`'s winner is the three-line "carried" form.
- The HYDAT 2025-10-14 backup already exists (`s3://fresh-bc/hydat/20251014/`, #46). Only a check is needed.
- `wb_aet_compare.R` and `wb_validate.R` are in `score_files_for()` (`scripts/wb_score_md5.R`), so this change stales the shipped fit. `wb_output.R`, `segment_output.R`, `discharge_publish.R` and `pcic_routed_lib.R` all check `score_code_md5`, so the shipped chain reruns through a BUILD, as #16 Phase 6 did (template: `wet-16/data/logs/16/chain*.sh` on m4).
- `wb_fit_accept.R:35` requires `cv_variant == "nested"`, but the shipped fit is fixed to `none`. So the next refit's acceptance (20260717 → next) will refuse. That gap is pre-existing and goes to a follow-up issue, not this one.

## Phase 1: Freeze #15 as a record
- [x] m4: back up `fit_20251014/` to `~/wet81/`; then at 353721a run the full recipe (ten `wb_validate.R`, then `wb_aet_compare.R`) and `git diff --exit-code -- data/checks/` (review AC1, O2)
- [x] m4: a detached worktree at 353721a with `data/wb` linked to the main checkout's. Run `WET_HYDAT_RELEASE=20251014 Rscript scripts/wb_aet_compare.R`, then `cmp` its report with the tracked `data/checks/wb_aet_compare.txt` and confirm `fit_20251014/aet_winner.txt` is unchanged. Stop and report if either differs.
- [x] Check the S3 backup is present (`s3api head-object` on `s3://fresh-bc/hydat/20251014/Hydat.sqlite3` and `.md5`, md5 `da00052022aa1533b80f9fab7cb8b4d0`)
- [x] Annotated tag `aet-15-record` on 353721a. Its message names #15, #81, the release and the fit. Push the tag.
- [x] The research paragraph also names what the recipe reads besides the backup: `stations_20251014.rds`, province run `e675918817` and `fit_20251014/` on m4 (review G6)
- [x] `research/water_balance_method.md` §0, under "The ET experiment (#15)": a "Reproducing #15" paragraph covering the tag, the HYDAT backup, the cache copy step, the worktree and the commands (the ten `wb_validate.R` runs, then `wb_aet_compare.R`, on `fit_20251014`). Also say that 946da43 is where #15 was decided, and that current main no longer reproduces it on demand.

## Phase 2: Retire the gate in code
- [x] `scripts/wb_aet_compare.R`:
  - Drop the release refusal (:26) and the refusal of fits with `pooled_variant.txt`/`adjust_override.txt` (:33-35).
  - Drop the #15 reproduction stop (:152-171). The reproduction now lives at the tag.
  - `as_shipped_cv()` uses the fit's fixed variant when there is one. Its keep test mirrors `wb_validate.R`'s `keep_adjust`: pass, or within the override's tolerance.
  - The report adds a line for the HYDAT release and the fit's decisions (fixed variant, override). The stage-1 line drops "(reproduces #15)".
  - Rewrite the header comments to match.
- [x] Put the decision-file reading (pooled variant, override tolerance, with its validation) in one place, `scripts/wb_cv_lib.R`, and use it from both `wb_validate.R` and `wb_aet_compare.R`, so the two cannot disagree on what "as shipped" means.
- [x] `scripts/wb_validate.R`:
  - Remove `WET_AET_CARRY`, `stale_carry` and the carry branch (:27-53).
  - A winner is two lines only.
  - The stale-winner and no-winner messages point at `wb_aet_compare.R`.
  - Rewrite the header comment.
- [x] `scripts/wb_output.R:41,46`: the messages drop "or the carry"
- [x] `scripts/wb_fit_lib.R`: the `wb_report()` comment says the unsuffixed 20251014 reports are the frozen #15 record. Code unchanged.
- [x] `CLAUDE.md`:
  - The `wb_validate.R` bullet: run every variant, then compare, then the winner, on the shipped release.
  - Remove the `WET_AET_CARRY` and "rerun `fit_20251014` first" lines.
  - Add a line: the AET is re-decided at each new shipped release, and `aet-15-record` reproduces #15.
- [x] (added in work) The winner is stamped and checked with `score_code_md5` (the fit's decision files included) instead of `aet_code_md5`: the comparison scores every variant under those decisions, so a changed decision must stale it. Readers updated: `wb_validate.R`, `wb_output.R`, `segment_output.R`, `discharge_publish.R`, `pcic_routed_lib.R`. `aet_code_md5` stays as `fits.rds$aet_md5` for `wb_fit_accept.R`.
- [x] (added in work) `scripts/wb_cv_lib.R` refuses release 20251014, so main never overwrites #15's unsuffixed frozen reports (checked: `WET_HYDAT_RELEASE=20251014` stops with the tag pointer)
- [x] (review G2, G3, G4) No winner file when the winner is not the AET shipped now or would ship raw under a fixed variant (DECISION TO USER); `adjusted*` marks the override in the report; docs flagged by G5
- [x] Grep that nothing outside `planning/archive/` still names `WET_AET_CARRY` or the rerun-first rule

## Phase 3: Re-decide on m4 (worktree of this branch, `data/wb` linked to the main checkout's)
- [x] Copy `fit_20260717` (fits.rds, aet_winner.txt, cv_aet-cfu.rds, output/, runoff_annual.tif, segment/) into `data/wb/_pre81/fit_20260717/` for identity checks. `wb_key_dir()` does not look there. Then remove the live three-line carried `aet_winner.txt`, which the new `wb_validate.R` refuses as bad.
- [x] `WET_HYDAT_RELEASE=20260717`, with `caffeinate -i` and logs in `data/logs/81/`:
  - `wb_validate.R` for cgiar lc tc fu cfu fu15 fu20 fu35 mod16 cmod16
  - then `wb_aet_compare.R`
  - Commit the reports (`wb_validation_aet-*_20260717.txt`, `wb_aet_compare_20260717.txt`).
- [x] **If the winner is not `cfu`: stop here.** Commit, and bring the switch to the user with the numbers (the pooled-variant test was also settled on cfu). Nothing ships.
- [x] If `cfu`:
  - `wb_validate.R cfu` ships. `cv_ann` and `cv_share` must be identical to `_pre81`'s, or stop and report.
  - Then `wb_share_snow.R`, `wb_output.R` (output parquet identical to `_pre81`'s), `segment_output.R`, `pcic_routed_compare.R` (with `WET_FWAPG_COMMIT` as tracked), and `discharge_publish.R` BUILD only. Expect every part identical to the live acb820f build.
  - Commit the reports after each step. No upload.
- [x] Copy the reduced bundle back to m1 (fits.rds, aet_winner.txt, cv_aet-cfu.rds; output/ identical, kept)
- [x] Update the m1/m4 memories (drop "rerun fit_20251014 first")

## Phase 4: Record the outcome
- [x] `research/water_balance_method.md` §0: the re-decision on 2026-07-17 (both stages' tables, winner, nested selection), compared with #15's numbers on 2025-10-14
- [x] Edit the #81 body with the outcome. File the follow-up issue: `wb_fit_accept.R` requires a nested-CV old fit, but the shipped fit is fixed to `none` (#83).

## Validation
- [x] Tests pass (1113, 0 failed) (`devtools::test()`; the scripts carry no unit tests, so the m4 runs are the end-to-end check)
- [x] `/code-check` clean (once over the branch with `/code-check branch`)
- [x] PWF checkboxes match landed work
- [x] `/planning-archive` on completion

