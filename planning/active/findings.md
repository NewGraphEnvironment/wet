# Findings — wb_fit_accept.R cannot accept the next refit: the shipped fit is scored with its pooled variant fixed (#83)

## Issue context

**If we do it:** the next HYDAT release can be accepted or refused by the rule #43 pre-registered, against the fit that actually ships. **If we never do:** `scripts/wb_fit_accept.R 20260717 <next>` stops before scoring anything, and the next refit has no acceptance test.

## Problem

`scripts/wb_fit_accept.R:35` refuses a fit whose scores were made with the pooled variant fixed:

```r
if (!identical(x$cv_variant, "nested")) stop("fit ", r, " was scored with the pooled variant fixed; the rule uses the nested CV")
```

#43's rule compares blocked-CV MAE "pooled variant chosen inside each fold". That worked for 20251014 → 20260717 because both fits were scored nested at the time. Afterwards `scripts/wb_pooled_test.R` fixed `fit_20260717`'s pooled variant to `none` (`pooled_variant.txt`). Its `cv_aet-cfu.rds` now has `cv_variant == "none"`, measured 2026-10-15. So the shipped fit cannot be the old side of the next acceptance.

## Related steps in the new-release sequence

Since #81 the AET is re-decided at each shipped release. These steps interact with that:

- `wb_fit_accept.R:47` stops when the two fits ship different AETs. So a release whose re-decision switches the AET cannot be accepted.
- `wb_pooled_test.R` needs a current `fits.rds`, which needs a winner. The variant it fixes then stales that winner (since #81 the winner is stamped with `score_code_md5`), so every variant is rescored and compared again under it. The pooled test itself was decided on the old AET and refuses to rerun.
- If the AET ever switches, `discharge_publish.R` describes the balance's AET as cfu in the manifest, and MOD16's gap fill is cfu (`wb_province.R`).

## Options

1. Score the old fit nested for acceptance only: set its decision files aside for one `wb_validate.R` run into a separate cv file, which `wb_fit_accept.R` reads.
2. Restate the rule as "each fit as it ships" (the old fit's fixed variant, the new fit nested or fixed), and pre-register that change before the next release is scored.

Found while planning #81.

## Exploration (2026-10-15)

- `wb_fit_accept.R` is not in `score_files_for()` (`scripts/wb_score_md5.R`), so editing it stales no fit. Option 1 (nested rescore) would either touch scoring files (staling the shipped fit) or need a separate script.
- `fit_20260717/cv_aet-cfu.rds` on m1's reduced bundle has `cv_variant` "none"; its folds all chose "none" under the nested CV too (#43 findings), so the headline numbers are equal either way for this fit.
- The current per-fit check compares `fits$aet_md5` with `aet_md5_for(r)`: scoring code and stations only. A pooled test or override written after `fits.rds` would not show. `score_code_md5` covers decision files; downstream readers (`discharge_publish.R`, `wb_output.R`) check `fits$code_md5 == score_code_md5` and the winner's two lines.
- #43's acceptance rule named the 2026-07-17 fit specifically, so a rule for the next release had to be stated anyway.
- Running `wb_fit_accept.R ... 20260717` would overwrite #43's tracked report `data/checks/wb_fit_accept_20260717.txt`.

## Sandbox verification (m1, 2026-10-15, after 04bec81)

A `git archive HEAD` copy in the session scratchpad holding the reduced `fit_20260717` (fits, `cv_aet-cfu.rds`, winner, decision files), its stations file, and a synthetic `fit_20990101`: the same files with `release` rewritten and `stations_20990101.rds` copied. Real `data/` untouched. Driver: a throwaway R script that ran each case through `Rscript scripts/wb_fit_accept.R`.

| case | exit | result |
|---|---|---|
| base (copy of shipped) | 0 | SHIPS +0.00; both "fixed to 'none'"; both gates "FAIL (adjustment kept by override)"; 30.72 / 30.72 |
| new fit `cv_variant = "nested"` | 0 | runs; report says "chosen inside each fold" |
| new fit ships `fu` (fits, cv file, winner) | 0 | runs; "AET: 20260717 cfu, 20990101 fu (switched)" |
| `pooled_variant.txt` edited after the fit | 1 | "not current under its code and decision files" |
| winner line 2 stale | 1 | "has no current AET winner for cfu" |
| no winner file | 1 | same |
| new == shipped | 1 | "the new fit must be another release" |
| old not shipped | 1 | "the old fit must be the shipped one" |
| mutant: line 35's nested-only stop restored | 1 | "fit 20260717 was scored with the pooled variant fixed" — the old stop fires on the shipped fit, so the fix is what lets it run |

The shipped fit on m1 is current under the branch's scoring code (its `fits.rds$code_md5` equals the recomputed `score_code_md5`), so the per-fit check works on a real bundle, not only on a synthetic one. The 30.72 headwater MAE is over fit_20260717's own headwater set (the copy shares all of them), not #43's 209 common gauges (30.90).

## Code-check round 1 (fixed in the next commit)

- A new fit whose pooled-zone test never ran passed: `pooled_test.txt` is not hashed and `pooled_variant.txt` exists only when the test fixes a variant. Now required, and its outcome must match `cv_variant` (fixed variant, or `nested` when uninformative). The earlier "new fit nested" case now refuses, because its test fixed `none`. The nested report is exercised by "test uninformative, scores nested", which exits 0.
- Once the shipped release moves on, a reverse run (`<new shipped> 20260717`) would rewrite #43's report. The new release must now be later than the shipped one.
- The `wb_score_md5.R` comments still describe the `aet_md5` cross-release check. Left as is, because editing that file stales every fit; noted on #85.

Sandbox rerun after the fixes: all 13 cases as expected, including "no pooled test", "uninformative with fixed scores" and "older new release" (all refuse).

## Code-check round 2 (fixed in the next commit)

- **Inside round 1's fix:** a `pooled_test.txt` copied from another fit, together with `pooled_variant.txt`, passed the check, because the file is neither hashed nor named for its release. It must now agree with the tracked report the test wrote for that release (`wb_report("wb_pooled_test", r)`). The report's HYDAT line must name the release and its OUTCOME line must match.
- "Each fit as it ships" was not true of a shipped fit that ships raw P − AET (`keep_adjust` FALSE): the MAE compared is the adjusted CV. Such a case now also sends the verdict to the user. This only adds a route to the user and auto-ships nothing new. It cannot happen today, because `fit_20260717` keeps the adjustment by override.
- My own edit dropped a `%s` in the VERDICT format. The sandbox caught it as an R warning (the suffix was not printed), and it is fixed.

Sandbox after the fixes: 17 cases.
- Refused, each with the expected message: the report missing for the release, the report naming another release, and the report's OUTCOME contradicting `pooled_test.txt`.
- The raw-shipping shipped fit gives "... 20260717 ships raw P - AET, so the decision goes to the user".

## Code-check round 3 (fixed in the next commit)

- **Inside round 2's fix:** `old_raw` covered only the shipped side. A new fit shipping raw P − AET (nested after an uninformative test, gate failed, no override) was judged on its adjusted CV, giving an unqualified DOES NOT SHIP for an estimate it does not ship. The mechanism is that "as it ships" was a proxy: `cv_v` is what ships only while `keep_adjust` is TRUE.
- **Enumeration** of what "ships" means: `keep_adjust` is the one switch. `wb_output.R:62`, `:122` and `:138` choose adjusted or raw on it, and `scripts/pcic_routed_lib.R:69` already scores the shipped fit as `if (keep_adjust) cv_v else raw_v`. So the fix scores each fit that way, which makes "as it ships" literal. It replaces round 2's raw-to-user route, and the report names which estimate each fit was scored on.
- The console message now prints the full verdict, user routing included. Before, it said "ships" when the report sent the decision to the user.
- Round 3's input table (`review-round3.md`, 17 inputs) lists what `score_code_md5` does not bind: the province run key, the AET and stations the pooled test ran on, and which release a decision file was decided for. The rule claims none of them. The pooled-test-vs-switched-AET case is #85's.

Sandbox: 18 cases, 5 exit 0 and 13 refuse. Raw-shipping cases score raw: shipped raw gives +0.03, new raw gives −0.03. The raw headwater MAE of 30.69 equals #43's documented raw 30.688.

## Errors Encountered

| Error | Resolution |
|-------|------------|
