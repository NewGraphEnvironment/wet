# Review p5 round 2: winner file with md5, wb_output guard (#15)

Scope: unstaged diff_p5.patch (wb_validate.R, wb_aet_compare.R, wb_output.R), read against
wb_cv_lib.R, wb_map.R, R/wet_wb_raw.R and scratchpad/run15c.sh. No wb_*.R run; guard logic simulated
in a scratch R session. State at 18:55: run15c (pid 7280) is gone; fits.rds (18:16) predates the fix
(aet cgiar, no code_md5); no aet_winner.txt; all cv_aet-*.rds predate the edit, so their md5 is stale.

## Walkthrough

(a) Fresh run dir. Loop: no winner file, ship_aet "cgiar"; the cgiar run writes fits.rds WITH code_md5
(saveRDS always stores it) and wb_validation.txt; the other seven write only scores. Compare writes
W + md5. `wb_validate.R W`: md5 matches, ships W. wb_output: aet == W and md5 == w[2]. Correct.

(b) Second cycle after a score-code change. Loop: winner md5 mismatches, ship_aet NA, message;
`aet_v %in% NA` is FALSE (verified), so fits.rds and wb_validation.txt stay old; scores written, so no
deadlock. Compare unlinks, rescores, writes W_new + new md5. Final validate ships. wb_output passes.
Correct IF the compare runs. See Finding 1 for the window before it does.

(c) Compare crashes midway. The winner file was unlinked at the start, so none exists. Cycle 1: fits is
the loop's cgiar under current code, and wb_output ships it: that is the stated "no comparison -> cgiar"
policy. Cycle 2: fits is the old ship. If the old winner was not cgiar, wb_output refuses ("no comparison
chose it"). If it was cgiar, wb_output ships the OLD-code cgiar fit (Finding 1). Rerun is unblocked:
with no winner file the loop's cgiar run rewrites fits.

(d) Final `wb_validate <winner>` skipped. Cycle 1, W != cgiar: fits is cgiar, refused. Cycle 1, W == cgiar:
the loop's fits is cgiar with the current md5, accepted, and it is the same fit. Cycle 2: fits carries the
old md5, the winner the new one, refused even when W_new == W_old. Correct.

(e) Winner is cgiar. The loop's cgiar run stored code_md5 = score_code_md5, and compare writes cgiar + the
same md5 (same code, nothing changed in between), so wb_output accepts without a rerun. Correct.

No-arg `wb_validate.R` with a stale winner: aet_v = NA and `NA %in% NA` is TRUE, but wet_wb_raw(cal, NA)
stops first ("unknown AET variant 'NA'"), before any write. Fails closed. Malformed winner file: every
validate stops, but compare unlinks it before it can fail, so no deadlock.

## Finding 1 (real, guard fails toward pass): wb_output never checks the md5 against the CURRENT code

wb_output compares fits$code_md5 with the winner file's line 2, i.e. two stored values with each other,
and never with the current score_code_md5 (it does not source wb_cv_lib.R). A stale pair that agrees
with itself passes. Simulated: winner "lc"/OLDMD5 with fits "lc"/OLDMD5 is not refused.

Paths that ship an old-code fit:
1. Score code or stations.rds changes, then the loop runs (it deliberately leaves the old fits and the
   old winner in place) and wb_output runs before the compare: the old winner and fits still match.
   This contradicts the new comment in wb_validate.R, which says that for a stale winner "fits.rds then
   stays as it was and scripts/wb_output.R refuses it". It does not.
2. Any code change and no rerun at all: wb_output ships the old fit through the current R/
   (wet_wb_adjust, wet_share_predict, wet_wb_raw), which is a mixed output if those changed.
3. No winner file (compare crashed or never ran) and fits is cgiar: the else branch checks only
   `aet != "cgiar"`, not the md5, so old-code cgiar fits ship. That includes today's 18:16 fits.rds,
   which has no code_md5 at all (the `identical()` on NULL is never reached in that branch).

Fix: compute score_code_md5 in wb_output the way wb_cv_lib.R does. The score_files vector plus
wet_md5_text() is cheap; sourcing the whole lib is not, so move those two lines into a tiny shared file
or duplicate them with a comment. Then refuse unless `identical(fits$code_md5, current_md5)` in BOTH
branches, and in the winner branch also require `w[2] == current_md5`. That closes paths 1 to 3, and
the wb_validate.R comment becomes true.

## Finding 2 (real, breaks the intended cycle; fails closed): run15c.sh reads both lines of the winner file

`w=$(cat data/wb/495b33ec47/aet_winner.txt)` now yields "lc\n<md5>" (verified), so
`Rscript scripts/wb_validate.R "$w"` passes a two-line argument. wet_wb_raw stops with "unknown AET
variant", `set -e` ends the runner, and wb_output and wb_map never run. The log redirect also creates a
file whose name contains a newline and the md5. Nothing wrong ships, but the next unattended rerun stops
at the ship step. Fix: `w=$(head -n 1 .../aet_winner.txt)`, and the same in any other caller that reads
the file.

## Finding 3 (real, stale output): a refused wb_output leaves the previous runoff_annual.tif, and wb_map maps it

wb_output stops before writing anything, but it does not remove the previous
output/*.parquet or runoff_annual.tif. wb_map checks only that the tif exists, and reads fits$calibration
from the current (refused) fits.rds. Run on its own after a refusal, for example by hand or by a runner
without `set -e`, wb_map rewrites the tracked research/wb_runoff_annual.png from the last accepted ship,
with no warning. run15c.sh's `set -e` prevents this inside the runner. A refused fit never reaches a tif,
so what gets mapped is a stale output, not a refused one. Cheapest fix: have wb_output stamp the tif
(metags, or a sidecar holding fits$aet + code_md5), and have wb_map refuse unless the stamp matches the
current fits.rds and winner. Alternatively, wb_output could unlink runoff_annual.tif before its guard.
Not currently triggered: no tif exists in the run dir.

## Note (not a defect of this diff)

The winner md5 covers the scoring code but not wb_aet_compare.R (the decision rule). An edit to the rule
without rerunning the compare leaves the old winner valid. The rule is fixed in planning and the old
winner and report stay consistent with each other, so this is only worth a line in the compare header.

## Verdict

Finding 1 is the substantive one. It reopens round 1's issue in a narrower window (after the loop,
before the compare; or with no winner file), and the new wb_validate.R comment claims a refusal that
does not happen. Finding 2 will stop the next runner invocation. Finding 3 is latent stale output.
No path deadlocks.
