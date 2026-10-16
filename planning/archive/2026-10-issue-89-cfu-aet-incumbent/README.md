## Outcome

`scripts/wb_aet_compare.R` now re-decides the annual AET at each HYDAT release with `cfu`, the shipped AET, as stage 1's incumbent, and `cgiar` as one of its challengers alongside `lc`, `tc` and `fu`. #15's thresholds, stage 2 (#18) and the DECISION TO USER path (#81) are unchanged. A challenger now has to beat `cfu` by 2.0 headwater points, plus (b)-(d), before a release can send the AET to the user, so the 0.9-point cfu/fu gap on 2026-07-17 can no longer force the switch path (#81, #85) on noise. The rule is recorded in `research/water_balance_method.md` §0, "The AET incumbent since #89", in the script header and in the report's stage 1 lines. They disclose that the rule was set after the 2026-07-17 scores were seen, and that (d) against `cfu`'s post-selection as-shipped score leans toward keeping it, as #18's stage 2 already did.

The plan review predicted that the real report changes in substance, not only in its stamps: every outer fold picks `cfu`, and (d) prints fail while `cfu` wins. Code-check took three rounds, with no code defects; the findings were wording. Round 3 found a defect inside round 2's fix and named the mechanism: the #89 text copied #83's forward-only pre-registration wording, but #89 also re-decides 2026-07-17. The loop ended on an enumeration of every scope and provenance phrase about the rule. The real rescore of `fit_20260717` (ten variants, compare, `wb_validate.R cfu`, then `wb_output.R` and `segment_output.R`) stays owed before the next publish, as the issue's Cost section says. Until it runs, the scripts that check the stamps refuse.

## Measurement

Sandbox on m4, built from copies of `fit_20260717`'s ten held-out score files, re-stamped for each worktree's code. Synthetic `fu` = `cfu`'s held-out predictions shrunk toward the observed runoff by k, so its headwater MAE sits a set gap below `cfu`'s 30.72 %:

| case | rule | (d): nested headwater vs incumbent as shipped | result |
|---|---|---|---|
| shipped scores | new | 32.5 vs `cfu` 30.7, fail | `cfu` ships (94 of 94 folds `cfu`) |
| `fu` 1.5 better (k 0.9512) | new | 32.5 vs 30.7, fail | `cfu` ships |
| `fu` 2.5 better (k 0.9186) | new | 29.8 vs 30.7, pass | DECISION TO USER, no winner file |
| `fu` 1.5 better | old | 31.5 vs `cgiar` 37.4, pass | DECISION TO USER (`fu` 69 folds, `tc` 25) |
| shipped scores | old | as tracked | report byte-identical to the tracked one |

So the incumbent change is what holds the 1.5-point case. The sandbox was validated three ways. The old-code reproduction matched the tracked report. All ten source stamps equal the winner's (49ab5f38…). And a re-stamp check: `wb_validate.R cfu` rewrote the file, all 22 non-stamp fields are identical, and it ran in 6 s against about 4 min in the September logs, so the rewrite was checked by file time rather than assumed. A synthetic `fu` never makes (b) or (c) the binding condition. The fu40 fallback, declared before any result was read, was not needed.

## Evidence

m4 main checkout: `data/logs/89/new/*` (new code; `head_real_report.txt` is the final commit 9cb02d9) and `data/logs/89/old/*` (origin/main daf64aa). The harness is `sandbox_89.R` in this directory.

Closed by: PR (see `gh pr list --search 89`)
