# Task: wb_fit_accept.R cannot accept the next refit: the shipped fit is scored with its pooled variant fixed (#83)

## Problem

`scripts/wb_fit_accept.R:35` refuses a fit whose scores were made with the pooled variant fixed:

```r
if (!identical(x$cv_variant, "nested")) stop("fit ", r, " was scored with the pooled variant fixed; the rule uses the nested CV")
```

#43's rule compares blocked-CV MAE "pooled variant chosen inside each fold". That worked for 20251014 → 20260717 because both fits were scored nested at the time. Afterwards `scripts/wb_pooled_test.R` fixed `fit_20260717`'s pooled variant to `none` (`pooled_variant.txt`). Its `cv_aet-cfu.rds` now has `cv_variant == "none"`, measured 2026-10-15. So the shipped fit cannot be the old side of the next acceptance.

Decisions (user, 2026-10-15):
- **Rule: each fit as it ships.** Compare the held-out error each fit stores under its own decisions. Score the new fit only after its own chain is complete.
- **Scope:** fix the variant refusal and allow an AET switch (report it, don't stop). The publish manifest's hard-coded "cfu" text and the pooled test, which was settled on the old AET, go to a new issue.

Only `wb_fit_accept.R` and docs change. That script is not in `score_files_for()` (`scripts/wb_score_md5.R`), so no fit goes stale and nothing on m4 needs rescoring.

## Phase 1: Restate the rule and fix the script
- [x] Pre-register the rule before any next release is scored. It goes in the `wb_fit_accept.R` header and in a new `research/water_balance_method.md` §0 subsection, "Accepting the next refit (#83)":
  - Metric and gauges stay as in #43: mean |err_pct| of `cv_v`, headwater gauges common to both fits, 1.0-point margin.
  - Each fit is scored as it ships: the headline CV of its shipped AET, under its own `pooled_variant.txt`, `adjust_override.txt` and `aet_decision.txt`.
  - The new fit is compared only after its chain is complete: AET decided, pooled test run, final `wb_validate.R`.
- [x] `old` must be `wb_shipped_release` and `new` must differ from it. This also keeps the script from overwriting #43's tracked `wb_fit_accept_20260717.txt`.
- [x] Replace the nested-only stop (line 35) with a per-fit check that the fit is what would ship:
  - `fits$code_md5` equals that release's `score_code_md5`, decision files included, computed by `sys.source("scripts/wb_score_md5.R")` into a local env with `release` set.
  - `aet_winner.txt[1:2] == c(fits$aet, score_code_md5)`, the same check `discharge_publish.R` and `wb_output.R` make.
  - This replaces the weaker `aet_md5` check, which misses a pooled test written after `fits.rds`.
- [x] Replace the same-AET stop (line 47) with a report line. An AET switch exists only through a user-recorded `aet_decision.txt`.
- [x] Report each fit's pooled variant (`nested`, or `fixed to 'none'`) and AET. The heading changes to "each fit as it ships".

## Phase 2: Verify in a sandbox (m1, scratchpad copy; data/ untouched)
- [x] Build a sandbox tree with `data/wb/<key>/upstream/_complete`, the reduced `fit_20260717`, and a synthetic `fit_20990101`. The synthetic fit is a copy with its `release` fields rewritten, plus `stations_20990101.rds`.
- [x] `wb_fit_accept.R 20260717 20990101`: expect SHIPS, +0.00, and both fits reported as fixed to 'none'.
- [x] Mutations, each expected to refuse or to report as stated:
  - new fit `cv_variant = "nested"`: runs, report says nested
  - new fit with another AET (consistent winner and fits): runs, report names both
  - edited `pooled_variant.txt` on the new fit: refuses, as stale
  - stale winner: refuses
  - `new == 20260717`: refuses
  - `old != shipped`: refuses
  - restore line 35's stop: the base case refuses, which proves the fix is what lets it run

## Phase 3: Docs and follow-ups
- [ ] `CLAUDE.md`: the new-release sequence ends with `wb_fit_accept.R <shipped> <new>`, with the rule named.
- [ ] File a new issue covering the manifest's hard-coded cfu description (`discharge_publish.R:194`) and the pooled test settled on the old AET, which refuses to rerun. Point `discharge_publish.R`'s stop message at it instead of #83.
- [ ] Edit #83's body with the outcome.

## Validation

- [x] Tests pass (sandbox runs; no package tests touch scripts)
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
