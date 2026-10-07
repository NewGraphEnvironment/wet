# Code review, round 2 (#43, staged diff): the round-1 fixes and scenarios A-D

## Findings

- **[severity: bug, a cgiar fit can ship]** `scripts/wb_aet_compare.R:26-36` with `scripts/wb_validate.R:49` and `scripts/wb_output.R:43-45`.
  - **What happens.** `wb_aet_compare.R` unlinks `aet_winner.txt` at :29. That is before it checks that all ten `cv_aet-*.rds` exist (:36) and before the #15 reproduction (:159). It refuses only a fit that has `pooled_variant.txt`; it does not refuse a fit whose release is not 20251014, or one whose winner was carried.
  - Once the winner is gone, `wb_validate.R` falls back to `ship_aet <- "cgiar"` (:49). The next `wb_validate.R cgiar` then does three things: it writes a current-md5 cgiar `fits.rds`, deletes `output/`, and overwrites the tracked `wb_validation*.txt`. `wb_output.R` accepts a cgiar fit when no winner exists (:43-45).
  - **Path 1 (Scenario D, or C after any scoring edit).** Start from 20260717 with a carried winner and no `pooled_variant.txt`, and leave `WET_AET_CARRY` unset.
    - `wb_validate.R` prints "rerun scripts/wb_aet_compare.R" (:54).
    - Compare deletes the carried winner, then stops with "no cv_aet-cgiar.rds: run scripts/wb_validate.R cgiar".
    - Doing what that message says ships cgiar on 20260717, a fit whose AET the rule fixes at cfu.
    - With `pooled_variant.txt` present (Scenario B), compare refuses before the unlink, so B is safe here.
  - **Path 2 (Scenario A).** If compare is run before all ten variants are scored, or stops on the #15 reproduction, the copied old winner is already gone. This happens, for example, after the Phase 3 rebuild proof when fwapg has moved.
    - The next pass of the documented loop (`for v in cgiar ...`, cgiar first) writes `fit_20251014/fits.rds` as cgiar.
    - It also overwrites the published `data/checks/wb_validation.txt` with the cgiar report.
    - In the stated order (ten variants, then a compare that succeeds, then cfu), this does not happen; see Scenario A below.
  - **Fix**, either of these:
    - In compare, refuse when `release != "20251014"` or the winner's line 3 starts with "carried". Do that and check that all ten cv files exist before the unlink.
    - Or drop the cgiar default in `wb_validate.R`, so that no winner means nothing ships, and require a winner in `wb_output.R`.
  - Also make `wb_validate.R`'s stale message say "rerun with WET_AET_CARRY=<ref>" when the winner was carried.

- **[severity: fragile]** `scripts/wb_validate.R:37`. The carry checks that the reference fit is consistent (`rw[2] == rf$aet_md5`) but not that it is current.
  - After a scoring edit (Scenario D), `WET_AET_CARRY=20251014 wb_validate.R cfu` re-carries from a 20251014 fit whose winner and fits are both stale. It works because both are stale in the same way. It then stamps the carried winner with the current `aet_code_md5`, so `wb_output.R` and `segment_vignette_data.R` cannot tell.
  - The rule carries cfu rather than re-picking it, so the outcome is probably the intended one. But the 20251014 comparison is never re-verified under the new code, even though the carried winner claims that code.
  - Fix: compute the reference's current aet md5 with `release <- carry` and require `rw[2]` to equal it. Otherwise, record in line 3 that the reference was stale.

- **[severity: dead end, conditional on the plan's wording]** `task_plan.md` Phase 4, "`wb_pooled_test.R` on the shipped fit".
  - The test runs before `wb_shipped_release` is switched. Run without `WET_HYDAT_RELEASE=20260717`, it tests 20251014 and writes `fit_20251014/pooled_variant.txt`. That is the wrong release.
  - From then on `wb_aet_compare.R` refuses 20251014 (:26). After any later scoring edit, 20251014's compared winner goes stale (`wb_validate.R:53`), and the only remedy offered is a compare that refuses. That is round 1's "cannot be recovered" case, still open for a fit whose winner was compared rather than carried.
  - Fix: write `WET_HYDAT_RELEASE=20260717` into the plan step. Optionally, have `wb_pooled_test.R` refuse `release == "20251014"`.

- **[severity: minor, can't be re-run]** `scripts/wb_fit_accept.R:31-33`.
  - Once `pooled_variant.txt` is fixed and `wb_validate.R cfu` is rerun, `cv_aet-cfu.rds` carries `cv_variant = "none"`/`"other"`. `wb_fit_accept.R` then refuses that fit for good.
  - So acceptance cannot be re-applied after any later scoring edit (Scenario D) unless `pooled_variant.txt` is moved aside by hand.
  - The first pass works, because the plan runs acceptance before the pooled test. The round-1 point "neither fit is checked current with the present code" is also still open: acceptance can compare a stale 20251014 cv file.

- **[severity: minor, report text]** Scenario C.
  - When the test is uninformative, `pooled_test.txt` is written but `score_code_md5` does not change (correct). Nothing tells the operator to rerun `wb_validate.R`: the plan says to rerun only "if it fixes a variant", and the script's stamp says only "nothing fixed".
  - So the tracked `wb_validation_20260717.txt` keeps the unsoftened caveat. Amendment 4 requires the softened wording, which `wb_validate.R:188-190` produces correctly on a rerun.
  - Fix: add "rerun scripts/wb_validate.R <aet> to name the test in the report" to the uninformative branch, and to the plan.

## Scenarios walked

**A (Phase 3, `fit_20251014` holding the old two-line winner).**
- Each of the ten `wb_validate.R <v>` runs works as follows:
  - There is no carry, and the winner has two lines, so `stale_carry` is FALSE.
  - `w[2]` (the old md5) differs from `aet_code_md5`, because the scoring scripts and the stations path changed. So `ship_aet = NA`.
  - `aet_v %in% NA` is FALSE, so the run writes no `fits.rds`, no tracked `wb_validation.txt`, and no gate stop. It writes only `cv_aet-<v>.rds` (`code_md5 = score_code_md5 = aet_code_md5`) and `wb_validation_aet-<v>.txt`.
- Compare: there is no `pooled_variant.txt`, so it unlinks the winner, reads all ten (the md5s match) and reproduces #15. It writes `c("cfu", aet_code_md5)`.
- `wb_validate.R cfu` then ships. `fits.rds` is written once, with `code_md5 == aet_md5 == aet_code_md5`, and `wb_validation.txt` is copied.
- The cgiar run cannot write `fits.rds` in this order. It can when compare has run and failed first (finding 1).

**B (Phase 4, fixed "none").**
- Carry: there is no winner, so `rw`/`rf` are read from `fit_20251014`. `rf$aet_md5` exists only in a Phase-3 `fits.rds`; a pre-#43 one stops, which is good. The 20260717 winner is written as cfu with that release's `aet_code_md5`, and the nested `fits.rds` ships.
- `wb_fit_accept.R`:
  - It runs the same-AET, fits/cv md5 and `cv_variant == "nested"` checks, and the paired non-NA headwater set.
  - Each release's md5 includes its own stations file, so the two never need to agree, and they don't.
- `wb_pooled_test.R`:
  - `fits$code_md5 == score_code_md5` holds, because there is no `pooled_variant.txt` yet.
  - It writes `pooled_variant.txt` and `pooled_test.txt`, and refuses a rerun.
- `wb_validate.R cfu` rerun, with or without `WET_AET_CARRY`:
  - The winner is not stale, because `aet_code_md5` excludes `pooled_variant.txt`. So `ship_aet = cfu`, `fixed_variant = "none"` and `cv_variant = "none"`.
  - If `keep_adjust` is FALSE, the stop at :99 fires before any write. The old nested `fits.rds` stays, and `wb_output.R` refuses it, since `code_md5` is now different.
  - If `keep_adjust` is TRUE, `fits.rds` is written with the new `score_code_md5` and `aet_md5`.
- `wb_output.R` accepts the result: `fits$code_md5 == score_code_md5`, `w[2] == aet_code_md5`, `w[1] == aet`.
- The report quotes `pooled_test[3]`, the decision-gauge MAEs of both variants.

**C (uninformative).**
- `pooled_test.txt` line 1 is "uninformative", and the md5 does not change.
- A rerun gives "...the test on short-record gauges (#43) was uninformative, so this is mildly optimistic)".
- Nothing prompts that rerun (finding 5).

**D (scoring script edited after Phase 4).**
- 20251014 needs the ten variants, then compare, then cfu. It dead-ends only if it holds `pooled_variant.txt` (finding 3).
- 20260717 needs `WET_AET_CARRY=20251014 wb_validate.R cfu`. That re-carries, from a possibly stale reference (finding 2), and re-ships with the fixed variant.
- Without `WET_AET_CARRY`, the message misleads. It is harmless when `pooled_variant.txt` exists, and it ships cgiar when it does not (finding 1).
- Acceptance cannot be re-run (finding 4). The pooled test is not remade, by design.

## Checked and fine

- `aet_code_md5` and `score_code_md5` are separated correctly.
- `wb_aet_compare.R` compares the cv files against `score_code_md5`, which equals `aet_code_md5` there because it refuses a fixed variant.
- `wb_output.R` sets `release` before sourcing `wb_score_md5.R`, and reads HYDAT through `wb_hydat(release)`.
- `segment_vignette_data.R` checks `release == wb_shipped_release` and `winner[1:2]`. Its `^### Adjusted, blocked CV` parse matches both the nested and the fixed headline labels.
- Amendment 10 matches the code:
  - `wet_wb_pooled(tr)` counts a zone with no gauges in `tr` as pooled (`n_dom = 0`).
  - `wet_wb_fit` gives that zone the `other` coefficients, or 0.
  - `adjust_test` drops only zones absent from `cal` entirely.
  - A test gauge dominated by such an absent zone is not a decision gauge, and both variants give it no adjustment.
- `wb_stations.R` and `wb_output.R` both go through `wb_hydat()`. No reader of the old `stations.rds`, key-dir `fits.rds`, or `wet_hydat_path()` default remains in `scripts/` or `data-raw/`.
