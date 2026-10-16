# Code-check round 1 (#89), branch diff main...HEAD

Reviewer: unnamed subagent, 2026-10-16. Read in full: scripts/wb_aet_compare.R, planning/active/sandbox_89.R,
the diff of research/water_balance_method.md and CLAUDE.md; context from scripts/wb_cv_lib.R,
scripts/wb_score_md5.R, scripts/wb_validate.R (lines 20-154), scripts/wb_fit_lib.R, and
data/checks/wb_aet_compare_20260717.txt.

## Verdict: Clean (code). No bug, security or data-loss issue found. Three minor prose items below, none blocking.

## What was checked and holds

- **Rule logic.** `decide(top, incumbent1, eligible)` with `eligible = cgiar, lc, tc, fu`: the incumbent row is cfu's,
  and only challengers can be `ok`. `winner1 <- if (winner_top != incumbent1 && pass_d) winner_top else incumbent1`,
  and `pass_d` compares against `inc1_row$hw` (cfu as shipped). Stage 2 (`inc <- winner1`), `ns2`, `ns_inc` are untouched;
  `ns12` uses `incumbent1`. `to_user <- ... winner != "cfu"` and the `winner1 != "cfu"` stage-2 note are unchanged, as intended.
- **Order invariants.** `variants_all` is spelled out as `cgiar, lc, tc, fu, cfu, fu15, fu20, fu35, mod16, cmod16`,
  the same as the old `c("cgiar", eligible, transparency, eligible2)`. `cands` (filtered from `variants_all`) is
  `cgiar, lc, tc, fu, cfu`, the same as the old `c("cgiar", eligible)`, so `tab1`/`tab12` levels, report rows and
  `fold_m` row order are unchanged. `which.min` ties in `decide()` resolve by row order of `m` (`top` or `fold_m`), not by
  `eligible`'s order, so the reordering of `eligible` cannot change a tie.
- **sprintf arity.** Rule line: 5 conversions (`%.1f %s %.1f %d %s`), 5 args. (d) line: 9 conversions, 9 args.
  `slack_nes_in20 = 3` (double, integer-valued) is fine for `%d`, as before.
- **Harness, re-stamp.** It sources `wb_fit_lib.R`, sets `release`, then `wb_score_md5.R`, which resolves the decision
  files via `wb_fit_dir(wb_key_dir(), release)`; in the sandbox `wb_key_dir()` finds the one real key dir (its `upstream`
  is a symlink, and `file.exists(".../upstream/_complete")` follows it), and the copied `pooled_variant.txt` and
  `adjust_override.txt` are hashed as `wb_cv_lib.R` will hash them. The stations file is a symlink, and `md5sum` follows it.
  So the stamp equals what `wb_aet_compare.R` will compute in that worktree. A mismatch would stop loudly in
  `wb_aet_compare.R` ("scored by other code"), not pass silently.
- **Harness, safety.** `unlink("data/wb", recursive = TRUE)` runs only when `data/wb` is absent or carries the marker,
  and only from a non-main path. A worktree whose `data` is a symlink to main's would expose main's `data/wb` without
  the marker, and stop. R's `R_unlink` uses `lstat`, so it removes symlinks to directories (`upstream`) without
  descending into them. Nothing the sandbox runs writes outside `fit_dir` except the tracked `data/checks/` reports,
  which the plan restores.
- **Synthetic fu.** It is read after the re-stamp loop, so it carries the new stamp. `x$obs`, `x$nesting`, `x$raw`,
  `x$cv_ann`, `keep_adjust` and the `cv_v`/`raw_v` summaries all exist in `cv_aet-*.rds` (wb_validate.R l.139-147).
  `obs + k(cv_ann - obs)` with `0 < k < 1` and `cv_ann >= 0` stays `>= 0`, so the headwater MAE scales by k exactly, and
  the line-96 consistency check in `wb_aet_compare.R` passes on the recomputed `cv_v` headwater row (fu keeps
  `keep_adjust = TRUE`, so `cv_v` is the summary checked). (b) and (c) cannot bind, as findings.md says.
- **Prose numbers against `data/checks/wb_aet_compare_20260717.txt`.** cfu 30.7, fu 31.6 (0.9), tc 33.0 (2.3),
  cmod16 34.0 (3.3), cgiar 37.4, fu35 27.6 (transparency only), folds fu 26 / cfu 68 of 94, nested selection 31.5,
  cfu alone nested 32.5. All match. "No eligible challenger beats cfu on headwater MAE at all" holds for all six
  (cgiar 37.4, lc 49.4, tc 33.0, fu 31.6, mod16 35.5, cmod16 34.0). "It cannot change the 2026-07-17 result" holds: (a)
  needs <= 28.7, and no eligible variant reaches it. The thresholds stated in research and CLAUDE.md match `margin_hw`,
  `slack_nes_mae`, `slack_nes_in20` and the `decide()` inequalities.

## Minor (prose; not blocking)

- **[fragile, doc] research/water_balance_method.md:321 (the #89 "Rejected" paragraph).** "`aet_winner.txt` is read
  by `wb_output.R`, `discharge_publish.R`, `pcic_routed_lib.R` and `wb_fit_accept.R`" reads as the complete list, and it
  is not: `scripts/wb_validate.R` (l.28-43, the reader that ships it), `scripts/segment_output.R:69` and
  `scripts/wb_share_snow.R:28` read it too. The omission only understates the argument ("a wider change"), but an
  enumeration should be complete or say "among others". The same sentence is in planning/active/findings.md.
- **[doc] scripts/wb_aet_compare.R:252.** The report still prints "Rule (fixed before scoring): a variant replaces cfu
  ...". On the rescore of `fit_20260717` that the issue's Cost section requires, the tracked
  `data/checks/wb_aet_compare_20260717.txt` will say this about a rule chosen after that release's scores were seen.
  The "Disclosed:" line right after it says the incumbent was chosen after cfu and fu were seen to be close, so a reader
  is told. Still, the two lines contradict each other for that release. Something like "fixed before scoring (#15; the
  incumbent since #89, see below)" would make them agree.
- **[doc] research/water_balance_method.md:288 (the #81 paragraph).** "with #15's and #18's rules unchanged (since #89,
  stage 1's incumbent is `cfu` ...)" says unchanged and then changed in one sentence. CLAUDE.md's matching bullet
  dropped "unchanged" for that reason. Consider "with #15's and #18's thresholds".

## Note (not a finding)

- `sandbox_89.R` accepts only `real`, `fu15` and `fu25` (`stopifnot(case %in% ...)`, `gap <- c(fu15 =, fu25 =)`), but
  findings.md pre-declares a `fu40` fallback. Running it needs a harness edit on m4. That is harmless if it is made
  after any in-flight run of the harness has exited, since the harness's own run lasts seconds.
