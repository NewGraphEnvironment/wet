## Outcome

`scripts/wb_fit_accept.R` can now accept the next HYDAT refit against the fit we ship. The user chose "each fit as it ships": the held-out error of what each fit ships, for its shipped AET and under its own decision files. That is the blocked-CV adjusted prediction (`cv_v`), or raw P − AET (`raw_v`) where the gate dropped the adjustment, the same choice `pcic_routed_lib.R` makes. #43's gauges and 1.0-point margin are kept.

The rule is pre-registered in `research/water_balance_method.md` §0, "Accepting the next refit (#83)". The old nested-only stop and the same-AET stop are gone; a switched AET is reported instead. Neither fit is accepted until its chain is complete. The script checks:
- `score_code_md5`, decision files included
- the winner
- the pooled-zone test's outcome, tied to the tracked report for that release
- the new release is later than the shipped one

The publish manifest's cfu text, and the pooled test staying on the old AET, went to #85.

What was learned: "as it ships" first stood for the adjusted CV, which is what ships only while `keep_adjust` is TRUE. Four code-check rounds, of which rounds 2 and 3 each found a defect inside the previous fix. The loop ended on two enumerations: round 3's table of the 17 inputs the script reads, and `keep_adjust` as the one ships switch, confirmed by grep in round 4.

## Measurement

These are sandbox results on m1: a scratchpad copy of the reduced `fit_20260717` plus a synthetic `fit_20990101`, with real `data/` untouched. 18 cases: 5 accepted, 13 refused as intended (table in `findings.md`).
- Restoring the old line-35 stop refuses the shipped fit, which shows the fix is what lets it run.
- Headwater MAE on the shipped fit: adjusted 30.72 %, raw 30.69 %. The raw figure equals #43's documented 30.688, which confirms the `raw_v` path scores what `wb_output.R` would ship.
- Nothing on m4 was rescored. `wb_fit_accept.R` is not in `score_files_for()`, so no fit went stale. Like any change under `scripts/`, it makes `discharge_publish.R`'s next build require a rerun of `wb_output.R` and `segment_output.R`.

Closed by: PR (this branch, `83-wb-fit-accept-r-cannot-accept-the-next-r`)
