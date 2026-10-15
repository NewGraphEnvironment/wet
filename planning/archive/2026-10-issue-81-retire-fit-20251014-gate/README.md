## Outcome

`fit_20251014` is no longer a gate. #15 is frozen at tag `aet-15-record` (353721a, v0.4.7). There the full recipe (ten `wb_validate.R` runs, `wb_aet_compare.R`, `wb_validate.R`) reproduces every unsuffixed report and fit file byte for byte, and current code refuses release 20251014. The AET comparison now runs on the fit's own release, scoring each variant as the fit ships it (fixed pooled variant, gate override), and on HYDAT 2026-07-17 it chose cfu again. `WET_AET_CARRY` is gone. The winner is stamped with `score_code_md5`. A winner other than #15's cfu, or one that would ship raw, goes to the user (DECISION TO USER). The user's choice is recorded in `<fit>/aet_decision.txt`, and refused if it is lost on a copy. Five code-check rounds each found the next defect in that decision record, until an enumeration of the ways a fit can lack the file closed it (findings.md). The plan review's G6 stands: the tag recipe also needs m4's stations file, province run and fit directory, not only the HYDAT backup. Research: `research/water_balance_method.md` §0, "Reproducing #15 and #18" and "The AET re-decided on HYDAT 2026-07-17". Follow-up: #83 (`wb_fit_accept.R` cannot accept the next refit).

## Measurement

- 2026-07-17, as shipped, blocked CV, headwater MAE: cfu 30.7 %, fu 31.6 %, tc 33.0 %, cgiar 37.4 %, mod16 35.5 %, cmod16 34.0 %. The nested selection gave 31.5 % (passes against cgiar); its folds chose cfu 68 and fu 26. On 2025-10-14 the split was 87 to 6, so fu is closer on this release. Stage 2 kept cfu (nested 32.5 % against 30.7 %).
- The shipped fit is unchanged. `cv_aet-cfu.rds` and `fits.rds` are identical in every field but the two md5s, and the province output parquet is identical. The publish BUILD matched the live acb820f on 67 of 67 parts; nothing was uploaded.
- At the tag, the #15 recipe took about 61 min on m4 with the pooled variant nested; on the fixed-variant fit, scoring all ten took about 2.5 min.
- Wrong turns:
  - A first chain run under pre-review code was stopped after scoring.
  - An identity check wrongly required `aet_md5` unchanged.
  - An over-broad `pkill` killed the compare-only reproduction after it had deleted `fit_20251014/aet_winner.txt`. The file was restored byte-identical against a checksum taken before the run.

## Evidence

Reports: `data/checks/*_20260717.txt` (tracked). The run logs (`data/logs/81/` in the m4 worktrees `wet-81` and `wet-81rec`) were deleted with those worktrees at cleanup on 2026-10-15 and were not kept; the tracked reports and this archive's findings are the record.

Closed by: PR (this branch, 81-retire-fit-20251014-as-a-gate-re-decide)
