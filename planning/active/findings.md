# Findings — Make cfu the incumbent when the AET is re-decided (#89)

## Issue context

**If we do this:** a new HYDAT release switches the annual AET only when a challenger beats cfu by a real margin (2.0 points headwater, #15's own bar), so the switch path (#81's user decision, #85's pooled-test rerun, rescoring every variant, rewriting the publish texts) becomes rare insurance instead of a likely event. **If we never do:** each release can flip cfu to fu on noise, and nothing ships until someone works through that path for a difference that means nothing.

## Problem

Since #81, `scripts/wb_aet_compare.R` re-decides the AET at every release by #15's and #18's rules as written. Stage 1 starts from **cgiar** as the incumbent every time (`decide(top, "cgiar", eligible)`, lines 92, 143, 184) and ships whichever challenger that passes has the lowest headwater MAE. Two of those challengers are nearly the same estimate:

- On HYDAT 2026-07-17 (`data/checks/wb_aet_compare_20260717.txt`), headwater MAE as shipped: cfu 30.7 %, fu 31.6 %, a 0.9-point gap. Both clear cgiar (37.4 %) by the 2.0-point bar.
- cfu is the cell-wise maximum of CGIAR and fu, so the two differ mainly where CGIAR exceeds fu (zone 17 in the report's detail table).
- In the nested selection, fu already wins 26 of the 94 outer folds; cfu wins 68.

So a later release can rank fu first on a sub-point difference. That winner is not cfu, so the run writes no `aet_winner.txt` and the decision goes to the user (#81). Accepting it then means `aet_decision.txt`, rerunning the pooled-zone test under the new AET (#85), rescoring every variant, and rewriting the `wet_balance` description, README and `research/discharge_publish.md` (#85).

Meanwhile the AET inputs are fixed climatologies. A new HYDAT release changes only revised gauge flows and a few calibration gauges, so it carries little new information about which AET is right.

## Decision (2026-10-16)

**The shipped AET, cfu, is the incumbent in stage 1.** Stage 1 becomes cfu against cgiar, lc, tc and fu, with #15's thresholds unchanged: (a) headwater MAE at least 2.0 points below the incumbent, (b) all-station MAE no higher, (c) nested MAE at most 1.0 point higher and nested within ±20 % at most 3 points lower, and (d) a fully nested selection beating the incumbent's as-shipped headwater MAE. Stage 2 (cfu against mod16 and cmod16, #18) is unchanged: its incumbent is stage 1's winner, which stays cfu unless something clears that bar.

Rejected:
- **Freeze cfu and stop re-deciding per release.** It saves compute, but it drops the check that runs at each release we refit on, and `aet_winner.txt` is read by `wb_output.R`, `discharge_publish.R`, `pcic_routed_lib.R` and `wb_fit_accept.R`, so removing it is a wider change than this one.
- **A bigger margin for fu alone.** That is a special case for one pair; an incumbent bar covers every pair the same way.

Disclosed: this rule is changed after seeing that cfu and fu are close. It cannot change today's result: no eligible challenger beats cfu on headwater MAE at all (fu is 0.9 points behind, tc 2.3, cmod16 3.3; the transparency-only fu35 is never eligible), and it favours the status quo, which is the direction that needs no defence. It is recorded before any later release is scored.

`fit_20251014` and tag `aet-15-record` stay #15's record under cgiar as the incumbent; they are not rerun.

## Plan

1. **Pre-register** the rule in `research/water_balance_method.md` §0 (a short subsection, "The AET incumbent at later releases") and in `wb_aet_compare.R`'s header, before any later release is scored.
2. **`scripts/wb_aet_compare.R`**: stage 1's incumbent becomes `"cfu"`, with `cgiar` moving from incumbent to challenger, at all three places it is named (the top-level rule, the nested selection, the two-stage transparency run), and the report's stage 1 heading and rule text say so. The report still lists every variant's score. The `winner != "cfu"` → DECISION TO USER logic is unchanged: a challenger that clears the bar is a real gap worth a human decision.
3. **Verify in a sandbox** (copy of the reduced shipped fit): the shipped fit still picks cfu; a synthetic fit with fu 1.5 points better than cfu keeps cfu; one with fu 2.5 points better (and passing (b)-(d)) goes to the user. Restore the old incumbent and confirm the 1.5-point case flips, so the change is what holds it.
4. **Docs**: `CLAUDE.md`'s water-balance bullet and the #81 description in research name the incumbent.

## Cost

`wb_aet_compare.R` is in `score_files_for()` (`scripts/wb_score_md5.R`), so the edit stales every fit, the shipped `fit_20260717` included. Before the next publish, on the machine with the full province run: rescore every variant (`wb_validate.R <v>`), `wb_aet_compare.R`, `wb_validate.R cfu`, then `wb_output.R` and `segment_output.R`. The last two are already owed since #83. The values do not change (same AET, same pooled variant, same gate); the stamps do, and `data/checks/wb_aet_compare_20260717.txt` is rewritten.

Related: #15, #18, #81, #85 (PR #87, whose guards stay as insurance).



## Errors Encountered

| Error | Resolution |
|-------|------------|
