# Plan review of #188 (backlog move 11), 2026-11-23

Blockers raised: 2
Owner forks: 1

One synchronous Plan-agent review of `task_plan.md` against the four issue bodies and the code, before the baseline. The owner fork is the plan's own Open decision 1, which the review confirmed is the owner's and asked to be re-posed; the review raised no other. Verdicts are the planning session's, after a probe where one was cheap.

## Findings and verdicts

1. **Blocker: check A's outcome was already in a tracked report.** Reproduced: `data/checks/wb_validation_20260717.txt:63,106` read raw +1.9 % and adjusted +14.3 % at 84 gauges under 100 km². Folded: the header discloses the known values, A describes the small-minus-larger contrast and registers only its unseen reading (general or concentrated), and the attribution says the adjustment's lift is known. The larger-class pair (raw −15.1, adjusted −6.7) is the reviewer's reading, not reproduced here; the script reprints it.
2. **Blocker: check C covers another population.** Reproduced: `basins` has 192 rows, 48 under 100 km². Folded: C prints A's medians on its own 48, names its population, and says #45's rule diagnoses overshoot only. The zone gaps (01, 28, 29) and the merged two-gauge row are the reviewer's reading.
3. **Gap: "#45's rule as written" was not appliable.** Columns confirmed present (`le_o`, `le_c`, `closure`, `dp`, `da`, `gap`, `area_km2`, `zone`). Folded: copy `verdict()` verbatim, assert it reproduces the stored 21 zone verdicts, pass the class's dominant zones for the ECCC corroboration, drop step 6 and say so, keep "4 distinct basins". Line numbers 226–269 and 282 are the reviewer's; the build confirms them.
4. **Gap: check B was not decidable.** `mae()` is a mean (`scripts/wb_cv_lib.R:149`), reproduced. Folded: mean absolute percent error named, the corrected-value formula, standardizing inside folds, an area-only model beside the full one, a bootstrap interval with an "undecided" verdict, `lake` dropped, the leakage stated as a caveat, the all-gauges fit registered as a deviation from #176, a glacier method.
5. **Acceptance: the in-sample mutation's "(better)" could fail spuriously.** Folded: require different predictions and a lower overall mean absolute log residual. Not probed (a statistical argument).
6. **Acceptance: Phase 1's guard failed on its own edit.** Reproduced: `grep -c 185 research/monthly_error.md` is 0. Folded: header exempt, zero issue-headed sections asserted, the word-count tool named.
7. **Acceptance: Phase 4's reproduce-first guard was loose and miscited.** Folded: one decimal against the validation report, and `cv$code_md5` against `score_code_md5`.
8. **Ordering: data setup was prose.** Reproduced: the main checkout has no `data/logs/188/`. Folded as Phase 0, with `data/wally` in the symlinks.
9. **Scope: items between this pull request and the follow-up.** Folded as a Phase 5 task: untested traits carried unconditionally, the map re-render, the known ±5 % number disclosed.
10. **Assumption: `planning.md` is not in the repo.** Folded: the header is modelled on `research/monthly_error.md:3`.

Open decisions: the review held that decision 1 (thresholds) is the owner's but was not askable as posed; it is re-posed on check B alone. It held that decision 2 (which candidates the follow-up scores) is mechanism; it moved to the plan's decisions.

Not checked by the review: lintr (no `.lintr` found; the plan's lint line is inferred).

## Files the plan names

research/monthly_error.md
research/README.md
research/wally.md
research/water_balance_method.md
CLAUDE.md
data/checks/gauge_monthly_compare_20260717.txt
data/checks/wb_validation_20260717.txt
data/checks/wally_compare_20260717.txt
data/checks/wb_small_basin_20260717.txt
scripts/wally_compare.R
scripts/wally_zone_scores.csv
scripts/wb_small_basin.R
scripts/wb_small_basin_rule.R
tests/testthat/test-wb_small_basin_rule.R
tests/testthat/test-wb_gate_rule.R
scripts/wb_cv_lib.R
scripts/wb_fit_lib.R
scripts/wb_gate_rule.R
scripts/wb_score_md5.R
scripts/wb_term_diagnose.R
scripts/wb_province.R
scripts/gauge_monthly_compare.R
scripts/wb_validate.R
scripts/wb_aet_compare.R
R/wet_station_select.R
R/wet_wb_fit.R
R/wet_wb_adjust.R
R/wet_share_fit.R
R/wet_share_predict.R
R/wet_donor_mean.R
R/wet_flow_validate.R
R/wet_cv_folds.R
R/wet_wb_raw.R
R/wet_mm_to_m3s.R
inst/vignette-data/monthly_values.rds
planning/archive/2026-10-issue-45-dry-interior-term/findings.md
planning/backlog.md
