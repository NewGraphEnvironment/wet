# Review p5 round 1: winner file drives the shipped AET (#15)

Scope: unstaged diff to scripts/wb_validate.R and scripts/wb_aet_compare.R (diff_p5.patch), read against
scripts/wb_cv_lib.R, scripts/wb_output.R, scripts/wb_map.R and the run in flight. Read only; no script run.

## The run in flight is consistent

- Runner run15c.sh (pid 7280) started 18:51:23; both scripts were last written 18:51:13, so every
  Rscript in it reads the edited code. Do not edit scripts/wb_*.R, wb_cv_lib.R or R/ until it exits.
- data/wb/495b33ec47/aet_winner.txt does not exist, so the loop's cgiar run ships cgiar (writes fits.rds
  and wb_validation.txt), and the other seven do not. That is the intended bootstrap.
- The runner uses `set -euo pipefail` and `w=$(cat .../aet_winner.txt)`, so a failed compare or a
  missing winner file stops it before wb_validate <winner> / wb_output. For THIS run, fits.rds ends up
  holding the winner. No stale/mixed output from this run.

## Finding 1 (real, guard fails toward pass): aet_winner.txt carries no provenance, and nothing downstream checks it

The winner file is plain text with no score_code_md5, and wb_validate.R trusts it unconditionally.
The compare refuses mixed-code variants, but the winner file itself is never checked. Failure path on
the next cycle (any change to a score file: wb_cv_lib.R, wb_validate.R, stations.rds, R/wet_wb_*.R ...):

1. The loop re-runs all 8 variants. Each run reads the OLD aet_winner.txt (chosen under the old code),
   so the old winner's run writes fits.rds and the tracked data/checks/wb_validation.txt under the new
   code, with a choice the new scores never made.
2. If the compare then stops (md5 or station mismatch, the stop at line 72, a missing variant, a crash
   before line 177), or the operator skips the final `wb_validate.R <winner>`, fits.rds and
   wb_validation.txt keep the stale winner. wb_output.R reads `fits$aet` and ships it; its report
   prints "annual AET: <stale>" with no warning, while wb_aet_compare.txt (if it was rewritten) names a
   different winner.
3. Same outcome if the compare picks a new winner and the final step is skipped: fits.rds holds the
   previous ship (cgiar on a first cycle, the old winner afterwards), and wb_output ships it.

wb_output.R has no check that fits$aet matches the current decision, and fits.rds carries no code md5,
so it cannot tell fits written by old code either.

Suggested fix (small, after the run exits):
- Compare writes the winner with its md5, e.g. `writeLines(c(winner, score_code_md5), f)`, and
  `unlink(f)` at the top of the compare so a failed compare leaves no winner.
- wb_validate.R ships from the file only when line 2 == score_code_md5 (else stop, or fall back to cgiar
  with a message; stop is the safer direction), and stores `code_md5 = score_code_md5` in fits.rds.
- wb_output.R stops unless `fits$aet == winner` (winner = file line 1, or "cgiar" if absent) and
  `fits$code_md5 == ` the file's md5. That makes "final step skipped" and "stale winner" both loud.

## Question (3): score_code_md5 does not depend on the winner file. Clean.

score_files (wb_cv_lib.R lines 127-129) lists code and stations.rds only; aet_winner.txt is not hashed,
and ship_aet only gates the fits.rds / wb_validation.txt writes, not any score. Note this diff itself
changed wb_validate.R's md5, invalidating the 18:16-18:43 cv_aet-*.rds; the in-flight run regenerates
all 8, so the compare will match.

## Question (4): readLines edge cases. Clean (all fail closed).

- writeLines adds a trailing newline; readLines returns one element. No final newline: warning only.
- Empty file: character(0), `length != 1` short-circuits to stop.
- Extra blank line / trailing space / unknown name: length != 1 or not in wet_wb_aet_cols() names -> stop.
- decide() only returns cgiar or an `eligible` name, all of which are in wet_wb_aet_cols().

## wb_map.R

Reads only fits$calibration (identical across variants: same cal) and runoff_annual.tif from
wb_output.R, so it inherits Finding 1 and adds nothing new.

## Verdict

One real issue (Finding 1), latent: not triggered by the run now in flight, triggered by the next
re-run after any score-file change or by skipping the final ship step.
