# Review p5, round 4

Scope: the working-tree scripts after round 3's fixes (scripts/wb_output.R, wb_validate.R,
wb_aet_compare.R, wb_cv_lib.R, the untracked wb_score_md5.R), and round 3's enumeration table
re-walked against them. Read only. Nothing under data/wb was touched and no wb_*.R was run.

The in-flight runner (run15c.sh, PID 8575 `wb_validate.R cgiar`, started 19:00:18) is running the
reviewed files. Every script's mtime is at or before 19:00:02, so the run and this review read the
same bytes.

## (1) wb_output.R, top to bottom

`git diff scripts/wb_output.R` has 0 removed lines, which confirms +19 −0: HEAD's body is intact and
the only change is the guard block (lines 22 to 40) plus the unlink at line 26.

- Line 13 `load_all` precedes line 27 `source(wb_score_md5.R)`, so `wet_md5_text()` (internal) is in
  scope.
- `key_dir` (19), `fits` (20) and `aet` (21) are all defined before the guard uses them.
- Line 26 unlinks the tif and output/. That comes before the guard (28 to 40), and the guard comes
  before `dir.create(output)` (41).
- `days` (42) is defined before the loop uses it (62). `tally` is initialised at 45, filled in the
  loop and bound at 75. `g` is defined at 81 and merged at 98, before 99 to 107 and the report.
- The loop uses `aet` (49) and the exported `wet_wb_adjust`, `wet_share_predict`, `wet_mm_to_m3s`
  and `wet_month_days`. Line 96 uses the exported `wet_station_snap`.
- Every write comes after the guard: the parquets (67 and 68), the tif (125) and the report (128).
- The guard fails closed on every malformed input. `fits$code_md5` NULL from a pre-#15 fits gives
  `identical(NULL, md5)` FALSE, so it stops. A one-line winner file gives `w[2]` NA, which also
  stops. A missing score file stops inside wb_score_md5.R.

The script runs end to end.

## (2) Round 3's table, re-walked

| Row | Round 3 | Now |
|---|---|---|
| `aet_winner.txt` line 2 (wb_validate.R, wb_output.R) | stale rule could pass (F3) | **No.** wb_aet_compare.R is in `score_files`, so a rule edit changes `score_code_md5`, both gates refuse the old winner, and the compare refuses every old cv_aet-*.rds |
| fits.rds read by wb_map.R | yes (F2) | **No** in the direction that mattered. wb_validate.R unlinks the tif and output/ in the same branch that writes fits.rds (validate.R:61 to 67), so a tif exists only if wb_output accepted and ran after the last fit write. One residual: a winner stale under new code leaves the old fits.rds, the old tif and the old output/ in place. They are mutually consistent, so wb_map redraws exactly the old map, and wb_output refuses and unlinks. That is stale relative to the code, not a mismatch, so it is not a finding |
| runoff_annual.tif (wb_map.R:14) | yes (F2) | **No** (same reason) |
| output/<CODE>.parquet | yes (F1) | **No.** It is unlinked before the guard in wb_output and on every fit write in wb_validate. A crash mid-loop leaves a partial output/ with no completion marker, but that is pre-existing in HEAD and was strictly worse there (old and new mixed). No script consumes output/ except wb_output's own HYDAT block (grep) |
| province key / `wet_upstream_irregular()` | partly (note) | **No.** It is defined at R/wet_ws_fetch.R:52, and R/wet_ws_fetch.R is in wb_province.R's `code_files`. Round 3's note was wrong, as the caller said |
| all other rows | No | unchanged, No |

## (3) wb_aet_compare.R hashing itself: no circularity, no deadlock

`score_code_md5` hashes source text, once, when wb_cv_lib.R sources wb_score_md5.R at script start.
The compare never writes to any file in `score_files`. It writes aet_winner.txt and
data/checks/wb_aet_compare.txt, neither of which is hashed. Every wb_validate.R <v> stamps the
same md5 that the compare recomputes, provided the files do not change in between, so the compare
can pass.

The cost is the one round 3 predicted: any edit to wb_aet_compare.R, including its report text,
invalidates all eight cv_aet-*.rds. That means a full rescore, about 27 min judging by the 18:16 to
18:43 run. It fails closed, so it is not a defect.

**Operational consequence for the run in flight (not a code finding).** run15c.sh re-sources
wb_score_md5.R in each of its 8 + 1 + 1 Rscript calls, hashing the files live each time. Editing
any `score_files` entry before the compare starts gives the variants mixed md5s: the compare stops
("scored by other code") and set -e ends the run, about 30 min lost. That includes wb_aet_compare.R
now, as well as wb_validate.R, wb_cv_lib.R and wb_score_md5.R. An edit after the compare but
before the ship step does the same: `wb_validate.R $w` sees the winner under other code and does
not ship. wb_output then refuses (fits.rds md5 ≠ current) and set -e stops the run. Everything
fails closed, but nothing in those files should be touched until run15c finishes.

## (4) wb_validate.R's unlink

It fires only when `aet_v %in% ship_aet`, and `ship_aet` is NA for a stale winner, so there is no
match. Here is how it plays out in run15c:

- There is currently no aet_winner.txt, so the loop's first iteration (cgiar) ships. It unlinks the
  tif and output/ and writes a cgiar fits.rds under the current md5.
- The compare then unlinks the winner file and writes a new one.
- `wb_validate.R $w` unlinks again and writes the winner's fits.
- wb_output rebuilds both.

No step between the unlink and wb_output reads the tif or output/. The only consumers are wb_map
(the tif, and it runs last) and wb_output itself. The runner's own logs go to data/logs/ and
data/wb/output_run_15.log, both outside `key_dir/output`, so nothing is deleted out from under a
concurrent or later step.

## Note (by design, not a finding)

Run by hand, outside set -e: if the compare aborts after unlinking the winner (a stale variant),
the cgiar fits.rds written by the loop's first iteration carries the current md5. wb_output then
ships cgiar with no comparison behind it. That is the documented fallback ("without a comparison,
cgiar"), and the runner's set -e prevents it. It is worth knowing if the chain is ever run step by
step.

## Verdict

Clean. Round 3's F1, F2 and F3 are fixed and none of the fixes introduces a new defect. The one
live hazard is operational: do not edit any `score_files` entry, which now includes
scripts/wb_aet_compare.R, while run15c.sh is running.
