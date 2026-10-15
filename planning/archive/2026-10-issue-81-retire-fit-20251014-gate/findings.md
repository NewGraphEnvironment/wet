# Findings — Retire fit_20251014 as a gate: re-decide the AET on the shipped release (#81)

## Issue context

**If we do it:** the shipped fit defends its own AET choice on the HYDAT release it uses. A scoring-code change reruns one chain instead of two, and only the shipped release has to sit on the pipeline machine. #15's decision stays reproducible on demand, from a tag and a backed-up release. **If we never do:** every scoring change reruns `fit_20251014` first. The shipped AET (`cfu`) stays defended on a superseded release (2025-10-14, which ECCC no longer serves) and is never re-asked on current data.

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

## Proposed

1. **Freeze #15 as a record.**
   - Tag the commit #15's decision was made at.
   - Back up the 2025-10-14 release once (with #46).
   - `research/water_balance_method.md` §0 already holds the numbers. Add how to reproduce them: the tag, the release and the commands.
2. **Re-decide the AET on the shipped release.**
   - Run every AET variant through `scripts/wb_validate.R` on `fit_20260717`, then `scripts/wb_aet_compare.R` under #15's and #18's pre-set rules, unchanged.
   - Report the winner. If it differs from `cfu`, the switch goes to the user before anything ships.
   - Do the same at each new shipped release.
3. **Retire the gate.**
   - `wb_aet_compare.R` runs on the shipped release, not only 20251014.
   - Drop `WET_AET_CARRY`.
   - Drop the "rerun `fit_20251014` first" rule from CLAUDE.md and the scripts.
   - `scripts/wb_fit_accept.R` needs no HYDAT: it compares the two fits' stored `cv_aet-*.rds`, so it keeps working while the old fit's files exist.
4. **Reports.** The 20251014 reports carry no release suffix (`wb_report()`, `scripts/wb_fit_lib.R:50-52`). Leave them as the frozen record.

## Open question for the plan

Whether `fit_20251014`'s directory on m4 is kept, archived or deleted once nothing reads it.

Relates to #15, #18, #43, #46.


## Exploration (2026-10-15)

- The scoring code is unchanged since 837ac0b (#16), and #16's rerun reproduced #15. m4's `fit_20251014/aet_winner.txt` is current (`cfu`, 363fdc69…). `fit_20260717`'s winner is the three-line "carried" form.
- The HYDAT 2025-10-14 backup already exists (`s3://fresh-bc/hydat/20251014/`, #46). Only a check is needed.
- `wb_aet_compare.R` and `wb_validate.R` are in `score_files_for()` (`scripts/wb_score_md5.R`), so this change stales the shipped fit. `wb_output.R`, `segment_output.R`, `discharge_publish.R` and `pcic_routed_lib.R` all check `score_code_md5`, so the shipped chain reruns through a BUILD, as #16 Phase 6 did (template: `wet-16/data/logs/16/chain*.sh` on m4).
- `wb_fit_accept.R:35` requires `cv_variant == "nested"`, but the shipped fit is fixed to `none`. So the next refit's acceptance (20260717 → next) will refuse. That gap is pre-existing and goes to a follow-up issue, not this one.


## Winner stamp (Phase 2)

Before #81 the AET winner was stamped with `aet_code_md5` (scoring code + stations, no decision files), because the AET was chosen before any per-fit decision existed. Under "as shipped" scoring the comparison depends on `pooled_variant.txt` and `adjust_override.txt`, and it already refused cv files not current under `score_code_md5` (which hashes them). So the winner now carries `score_code_md5`, and every reader checks it. Otherwise a changed decision file would have left a winner made under the old decisions looking current.

## Code-check (branch), 2026-10-15

Five rounds (review-round1..5.md). Round 1: no code bugs; no recorded way to ship a user's AET switch. Rounds 2-5 each found a defect inside the previous fix, all in that decision record. Round 3 named the mechanism: the decision had no record of its own with a lifecycle (create, carry, invalidate). The loop ended on an enumeration of the ways a fit can lack `aet_decision.txt`:

| Route | Handling | Checked |
|---|---|---|
| Never created | #15's cfu ships only if the rule picks it; otherwise DECISION TO USER | logic read (rounds 4-5); m4 run exercises the cfu path |
| Deleted on purpose | `wb_cv_lib.R` refuses while `fits.rds` records a decision; removing `fits.rds` is the way back | sandbox: case 2 |
| Not copied to a new release | `wb_cv_lib.R` refuses when the shipped fit has one and this fit has none | sandbox: cases 6, 7 |
| Not copied to a new key or bundle | `fits.rds` travels with the fit and records the decision, so `wb_cv_lib.R` refuses | sandbox: case 2 |

Malformed files refuse (sandbox cases 4, 5). Residual, accepted: after `wb_shipped_release` is bumped, the old shipped fit's decision stops gating; `wb_fit_accept.R`'s same-AET stop (#83) is the barrier.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `pkill -f "scripts/wb_"` on m4, meant for the #81 chain, also killed the #15 reproduction compare at 353721a after it had unlinked `fit_20251014/aet_winner.txt` | Rewrote the two known lines; md5 b5451e9b… matches the pre-run record. Kill by the chain's own process tree, never by a pattern another run matches |
