# Code-check round 2 (#89), branch diff main...HEAD

Reviewer: unnamed subagent, 2026-10-16. Read in full: scripts/wb_aet_compare.R, planning/active/sandbox_89.R,
the #81 and #89 subsections of research/water_balance_method.md, the CLAUDE.md `wb_validate.R` bullet; context from
scripts/wb_cv_lib.R (l.1-209), scripts/wb_score_md5.R, scripts/wb_fit_lib.R, data/checks/wb_aet_compare_20260717.txt,
the #89 issue body, and planning/active/review-round1.md.

## Verdict: Clean (code). One minor prose item, not blocking.

## Round 1's fixes, checked

1. **Winner-file readers (research l.321).** `grep -rn aet_winner` over scripts/, R/, data-raw/, tests/, vignettes/ finds
   exactly seven readers: wb_validate.R:28, wb_output.R:38, segment_output.R:69, discharge_publish.R:187,
   pcic_routed_lib.R:61, wb_fit_accept.R:61, wb_share_snow.R:28 (wb_aet_compare.R only unlinks and writes it). The
   research list names all seven. Complete. (planning/active/findings.md l.24 still has the four-item list, but that
   is the verbatim issue body, which carries the same sentence; excluded by the brief.)
2. **"Fixed before scoring".** The stage 1 report line now reads "Rule (#15's thresholds; incumbent set by #89 on
   2026-10-16)". The remaining hits are correct as they stand: wb_aet_compare.R:289 is stage 2's rule (#18's,
   unchanged, registered with cfu as the incumbent); research l.150 and l.224 describe #15's and #18's own runs;
   NEWS.md l.111/124 describe those releases; the script header l.1-7 says #15/#18 were fixed before scoring and
   then names #89's change and its date. No other "fixed before scoring" describes stage 1 under the new incumbent.
3. **Research l.288.** Now "under #15's and #18's rules (since #89 with `cfu`, not `cgiar`, as stage 1's incumbent
   ...)"; no "unchanged" contradiction. CLAUDE.md's bullet agrees.

## sprintf arity after the edit

- l.251: 2 `%s`, 2 args. l.252: 1 `%s`, 1 arg.
- l.254-257: `%.1f %s %.1f %d %%  %s` = 5 conversions, 5 args (`margin_hw, incumbent1, slack_nes_mae, slack_nes_in20,
  incumbent1`), in matching order.
- l.274-280: `%d %s %.1f %.1f %.1f %.1f %% %s %.1f %s` = 9 conversions, 9 args, in matching order.

## Logic re-checked

- `decide()` only lets `elig` members win; `top`, `fold_m` subsets and `ns12` all pass `incumbent1`; `winner1`, `pass_d`
  against `inc1_row$hw` (cfu as shipped). Stage 2 untouched. `cands` = `cgiar, lc, tc, fu, cfu` and `cands_all` add
  `mod16, cmod16`, the old order, so `tab1`/`tab12` levels and report rows are unchanged; `which.min` ties resolve by
  row order of `m`, not `eligible`'s order.
- "It cannot change the 2026-07-17 result": (a) needs a challenger at <= 28.7 headwater; cgiar 37.4, lc 49.4, tc 33.0,
  fu 31.6. So `winner_top` = cfu = `winner1`, and stage 2 is as before. Holds.
- Every prose number in the #89 subsection matches the tracked report (30.7, 31.6, 37.4, tc +2.3, cmod16 +3.3, fu 26/94,
  32.5 nested cfu alone, z17 fu 114.4 vs cfu 47.5 as the main zone difference).
- Harness: guards and re-stamp as in round 1; `wb_cv_lib.R` l.20/119/131 do not trip in the sandbox (no fits.rds, release
  is the shipped one). Synthetic fu scaling keeps (b)/(c) non-binding as findings.md says.

## Finding

- **[fragile, doc] research/water_balance_method.md:314 ("The rule for every release after 2026-07-17, pre-registered
  here").** The code applies cfu as incumbent to every release `wb_cv_lib.R` accepts, i.e. every release but
  2025-10-14, so 2026-07-17 itself is decided under it at the rescore the issue's Cost section requires. The #81
  paragraph (l.288) already says the shipped release runs "since #89 with `cfu` ... as stage 1's incumbent", and the
  #89 Disclosed paragraph says "a rescore under this rule rewrites data/checks/wb_aet_compare_20260717.txt". So the
  pre-registration states a narrower scope than the code and than its own neighbouring sentences. A reader checking
  the 2026-07-17 report against the registered rule would find it outside the stated scope. Something like "The rule
  for 2026-07-17's rescore and every later release" makes the three agree. (The provenance line's "written before any
  release after 2026-07-17 was scored" is true as written and needs no change.)
