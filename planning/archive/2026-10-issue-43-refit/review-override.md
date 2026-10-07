# Review: headwater-gate override (#43, staged diff)

Reviewer: subagent, 2026-10-06. Read in full: scripts/wb_validate.R, wb_score_md5.R, wb_cv_lib.R,
wb_fit_lib.R, wb_output.R, wb_fit_accept.R, wb_pooled_test.R, data-raw/segment_vignette_data.R,
findings.md "Decision 2". m1 holds only fit_20251014/cv_aet-cfu.rds, so the walk is by reading, not by run.

## 1. HIGH (blocks the sequence at step 2): the diff stales fit_20251014's AET winner, so the carry refuses

`scripts/wb_validate.R` and `scripts/wb_score_md5.R` are both in `score_files_for()` (wb_score_md5.R:14),
so `aet_md5_for()` changes for EVERY release once this diff is committed, fit_20251014 included.

- fit_20260717's `aet_winner.txt` is a carried one (3 lines), so `stale_carry` is TRUE (wb_validate.R:26-29).
- **Without WET_AET_CARRY:** `ship_aet` is NA (wb_validate.R:59). `fits.rds` is NOT rewritten (line 123), so it
  keeps the old `code_md5` and `keep_adjust = FALSE`. Only `cv_aet-cfu.rds` and the per-AET report are written.
  `wb_pooled_test.R:36` then stops ("fits.rds was made under other scoring code").
- **With WET_AET_CARRY=20251014:** the carry branch checks `rw[2] == aet_md5_for("20251014")`
  (wb_validate.R:41-43). fit_20251014's winner is a compared one (2 lines), written by wb_aet_compare.R under
  the old md5, so this check fails: `stop("fit 20251014 ships no current, consistent AET to carry: rerun its chain first")`.

So "write override -> wb_validate.R cfu" cannot produce a `fits.rds` with `keep_adjust = TRUE`. First fit_20251014's
whole chain has to be rerun on m4 under the committed code:
1. `wb_validate.R <every AET variant>`, because wb_aet_compare.R:46 needs each cv_aet current.
2. `wb_aet_compare.R`, which includes the #15 reproduction.
3. `wb_validate.R cfu`, which writes `fits.rds` with the new `aet_md5`.

Only then does the 20260717 carry run. task_plan.md's new Phase 4 item ("Record the gate override ... and rerun
`wb_validate.R cfu`") omits this step. The design works as intended (a code change stales every fit). The defect is
that the plan and the expected sequence miss the step.

Once that prerequisite is done, the rest of the walk is correct:
- **Step 2.** `wb_validate.R cfu` with `WET_AET_CARRY=20251014` re-carries. With no fixed variant,
  `keep_adjust = FALSE || (30.716 - 30.688 = 0.028 <= 0.1) = TRUE`. `fits.rds` is written with
  `code_md5 = score_code_md5`, which includes adjust_override.txt, and `aet_md5` excludes it.
- **Step 3.** In `wb_pooled_test.R`, `score_code_md5` hashes the same override file, so it equals `fits$code_md5`
  and the test runs.
- **Step 4.** If the test writes pooled_variant.txt, `score_code_md5` changes and the old fits.rds goes stale.
  `aet_code_md5` does not change, so a rerun of `wb_validate.R cfu` ships without a carry. At line 119, `keep_adjust`
  includes the override. A fixed variant that fails by no more than 0.1 ships adjusted. One that fails by more stops
  before `fits.rds` or cv_aet is written, and the stale fits.rds is then refused by wb_output.R:32. This is the
  intended behaviour (Decision 2, amendment 6).
- **Step 5.** `wb_output.R` checks the md5, applies `wet_wb_adjust` (line 59) and the raster adjustment (line 119), and
  reports "adjustment applied". Correct.

## 2. MEDIUM: wb_fit_accept.R would mislabel the overridden gate as PASS

wb_fit_accept.R:42 takes `gate = fits$keep_adjust`, and lines 69-70 print it as "headwater gate (adjusted beats raw
P - AET): ... PASS". Line 76 drops "its gate FAILS, so the decision goes to the user".

- Between step 2 and step 4 (override written, no fixed variant, cv_variant "nested"), the script still runs. A rerun
  would overwrite the tracked data/checks/wb_fit_accept_20260717.txt, which today correctly says
  `20260717 FAIL`, with `20260717 PASS`. That is a false gate result in a published report.
- After a pooled variant is fixed, the script stops at line 35-37 (cv_variant not "nested"), so it is no longer
  runnable on this fit. That is harmless because its verdict is already recorded.

Fix: store `gate_pass` in fits.rds and cv_aet-*.rds beside `keep_adjust`, and have wb_fit_accept.R read
`gate_pass` (with an "override" label when they differ). Or simply never rerun it on 20260717. As things stand,
nothing downstream can tell an override from a pass, because only `keep_adjust` is persisted.

## 3. MEDIUM: vignette prose claims the adjustment passes its gate

vignettes/segment-discharge.Rmd:721-723 says: "The zone adjustment passes its gate only under a variant offered
after the pre-set one failed, so all the skill figures here are mildly optimistic". Under the override, the shipped
fit's adjustment FAILS its gate by 0.03 and is kept by decision. If the pooled-zone test fixes a variant, the
"mildly optimistic" caveat also goes, because the variant is chosen outside the calibration gauges. The prose is
hard-coded and not driven by `provenance$keep_adjust`, so the vignette would misstate this.

The data side is right. segment_vignette_data.R:84/94 picks `cv$cv_v` and the "### Adjusted, blocked CV" report
block when `keep_adjust` is TRUE, and that is the skill that ships. `provenance$keep_adjust` is TRUE with no override
flag, so the Rmd cannot tell a pass from an override.

## 4. LOW: wb_aet_compare.R scores per-variant gates with the override, but the winner it writes is not keyed on it

wb_aet_compare.R:81/84/92 use `x$keep_adjust`, which now reflects the override, to pick the winner. It checks
cv_aet against `score_code_md5` (includes the override) but writes `aet_winner.txt` with `aet_code_md5` (excludes it,
line 298). On a fit where the comparison runs and an override is then added or changed, the winner stays "current"
even though the override could have changed which AET wins. This does not affect #43: the 20260717 AET is carried and
fit_20251014 has no override. It only matters if an override is ever written to a fit whose AET is compared. The
wb_score_md5.R comment ("made, or carried, before any per-fit decision file") states the assumption, but nothing
enforces it.

## 5. LOW: tolerance parsing and "badly failing"

- **Parsing is safe.** An empty file gives `override[1]` NA, then NA, then stop. "0.1 pts" or "0,1" give NA and stop.
  "Inf" or a negative value stop on the bounds. Leading or trailing whitespace parses. The 0.5 cap bounds how far the
  override can carry a failing adjustment, and the report and stamp say "kept by override". So the override cannot
  keep a badly failing adjustment, and it cannot do so silently.
- **The reason is not enforced.** A file holding only "0.1" is accepted, and the report prints
  "override (adjust_override.txt): " with no who or why. Consider `length(override) >= 2 && nzchar(...)`.
- **The stop message can read as a tie.** wb_validate.R:120-121 still rounds to 1 decimal and does not mention the
  tolerance. A fixed variant failing by 0.12 would stop with "(30.7 % vs raw 30.7 %)", which reads as a tie. Print 2
  decimals and the tolerance so the user can decide from the message.

## Note (planning file, not code)

task_plan.md's new pooled-test line was garbled by the edit. It duplicates ", only if the refit is accepted ...
a gate failure stops for the user." after "beyond the tolerance stops for the user.", so it states both the old and
the new stop rule.
