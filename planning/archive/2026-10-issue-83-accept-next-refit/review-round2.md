# Code-check round 2 — branch 83-wb-fit-accept-r-cannot-accept-the-next-r (#83)

Reviewer: subagent, 2026-10-15. Probes ran in a fresh copy of the sandbox
(`scratchpad/sb3`, the branch's `scripts/wb_fit_accept.R`; `wb_score_md5.R`,
`wb_fit_lib.R`, `wb_cv_lib.R` and `wb_validate.R` confirmed byte-identical to the
repo with `/usr/bin/cmp`). Driver `scratchpad/sb3/r2.R`, using the setup and run
functions from `accept_cases.R`. The repo's `data/` and the original `sb` were not
touched.

## Findings

- **[fragile] scripts/wb_fit_accept.R:65-73 (research/water_balance_method.md:316, CLAUDE.md wb_fit_accept bullet)**: the pooled-test check can be passed by a `pooled_test.txt` copied from another fit. Nothing ties the file to the fit it sits in.
  - The file is not hashed, and it carries no release: line 1 is the outcome, then two lines of text.
  - If it is copied into a new fit's directory together with `pooled_variant.txt`, the new fit is scored under the copied fixed variant. Its `fits.rds`, cv file and winner are then all current under `score_code_md5`, and the copied line 1 equals `x$cv_variant`. The fit is accepted although its own pooled-zone test never ran. That is the state round 1's fix was meant to refuse.
  - Reproduced: the sandbox's base case copies every file from `fit_20260717`, including `pooled_test.txt`. It exits 0 with "SHIPS (+0.00 points)" and the pooled variant reported as "fixed to 'none'".
  - The copy is a plausible slip. CLAUDE.md tells the user to copy `aet_decision.txt` into each later release's fit, and the other `.txt` files sit beside it. `wb_pooled_test.R:31` then refuses to run ("has run: it is not remade"), but only if someone tries to run it.
  - Discriminating evidence already exists: `wb_pooled_test.R:106` writes the tracked report `wb_report("wb_pooled_test", release)`, which names the HYDAT release on its "fit:" line, and only a run of the test on that release writes it. Fix sketch: also require `data/checks/wb_pooled_test_<r>.txt` to exist, with its OUTCOME line agreeing with `pooled_test.txt` line 1. That touches no hashed file. Otherwise, narrow the research text "refuses either fit ... whose scores do not use its pooled-zone test's outcome" to say the file is trusted as found.

- **[fragile, docs] research/water_balance_method.md:314 ("Each fit as it ships"), scripts/wb_fit_accept.R:6-13**: for a fit whose adjustment is dropped, the compared MAE is not "as it ships".
  - When `fits$keep_adjust` is FALSE (gate failed, no override; possible whenever the pooled variant is nested), `wb_output.R:62` ships `pmax(raw, 0)`. `cv_v` is still the adjusted held-out CV, so the MAE compared is not the shipped estimate's.
  - For the new side this is caught: a failed gate routes the verdict to the user.
  - For the old side nothing routes it. If a future shipped fit ships raw, its adjusted `cv_v` sets the bar. The report's gate line shows "FAIL", but the verdict stays an unqualified SHIPS or DOES NOT SHIP.
  - This is not reachable today, because `fit_20260717` keeps the adjustment by override. It becomes reachable once a release is accepted with its gate failing and the user ships it raw.
  - Either qualify "as it ships" in the rule text, or extend the user-routing to `!isTRUE(old$keep_adjust[1])`. The second changes the pre-registered rule, so it is the user's call.

## Checked and found sound (round-1 fixes)

Per-state probes of the pooled-test check (`r2.R`), each run through `Rscript scripts/wb_fit_accept.R 20260717 20990101`:

| state | exit | result |
|---|---|---|
| empty `pooled_test.txt` | 1 | refuses ("its pooled-zone test gave NA"): `readLines()[1]` is `NA`, which matches neither branch |
| line 1 `"none "` (trailing space) | 1 | refuses: toward refusal, acceptable |
| `pooled_variant.txt` present, no `pooled_test.txt` | 1 | "has no pooled-zone test" |
| nested fit current, test never run | 1 | "has no pooled-zone test" |
| nested fit, test uninformative | 0 | runs; reports "chosen inside each fold" |
| test fixed `none` (both files written), `wb_validate.R` not rerun | 1 | refused earlier by the md5 check: the new `pooled_variant.txt` changes `score_code_md5` |
| 9-digit new release | 1 | "must be a release after the shipped one" |

- **Shipped fit as the old side:** `fit_20260717/pooled_test.txt` line 1 is `none`. That equals its `pooled_variant.txt` and its `cv_variant`, so it passes, and the base case shows it.
- **`wb_pooled_test.R` write order:** it writes `pooled_variant.txt` (line 99) before `pooled_test.txt` (line 101), with the same first line. The test can never fix `nested`.
- **Other paths:**
  - An uninformative test after a copied `pooled_variant.txt` leaves the copy in place. The check then refuses, because `cv_variant` is fixed while `nested` is expected. Correct.
  - Deleting `pooled_variant.txt` after a fixing test refuses, by md5 and by variant. Correct.
- **Release ordering:**
  - `args[1]` must be identical to `wb_shipped_release`, which is 8 digits.
  - `args[2]` must be 8 digits and compare greater. Equal-length digit strings compare the same as the numbers.
  - So `wb_report()` can never pick the unsuffixed 20251014 name. It can never write the report of the shipped release, or of any earlier one, #43's `wb_fit_accept_20260717.txt` included.
  - After a bump to N, "N N" and "N <older>" refuse. Only a release newer than the current shipped one can be rewritten, which is intended.
- **`discharge_publish.R`:** the `#83` to `#85` re-pointing is correct, and the stop still fires for any non-cfu fit.
- **The md5 check subsumes the removed `aet_md5_for()` check.** `score_code_md5` hashes the same `score_files` plus the decision files, and `wb_score_md5.R`'s stale comments are tracked on #85.
