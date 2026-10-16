# Code-check round 3 (#89), branch diff main...HEAD

Reviewer: unnamed subagent, 2026-10-16. I read these in full: scripts/wb_aet_compare.R, planning/active/sandbox_89.R, research/water_balance_method.md l.284-330 (the #81, #89 and #83 subsections) and the CLAUDE.md `wb_validate.R` bullet. For context I read data/checks/wb_aet_compare_20260717.txt (l.1-30), scripts/wb_cv_lib.R (l.61-107), the scripts/wb_validate.R header (l.8-20), the scripts/wb_fit_accept.R header, NEWS.md (top), research/README.md row 9, and review rounds 1 and 2. I grepped research/, CLAUDE.md, README.md, vignettes/, NEWS.md, R/, data-raw/ and scripts/*.R for incumbent, pre-regist, pre-set, fixed before, unchanged and stage 1.

## Verdict

The code is clean. One prose finding remains and one minor item, both instances of the mechanism below.

## The mechanism

The #89 subsection follows the pattern of the #83 subsection right after it ("Accepting the next refit"). Its provenance line, "rule written before any release after 2026-07-17 was scored", is the same as #83's l.327. Its "The rule for every later release, pre-registered here" was #83's l.329, and its heading also scopes the rule to "later releases". #83's rule really is forward-only and really was pre-registered. #89's rule is neither:

- It also re-decides 2026-07-17, a release whose scores were seen before it was written.
- The research text discloses that it was chosen because of those scores.

The underlying assumption is that #89 is one more forward-only pre-registration, like #15, #18 and #83, so their provenance and scope wording carries over. Rounds 1 and 2 each removed one copy of that wording:

- Round 1 (2): "fixed before scoring".
- Round 1 (3): "unchanged".
- Round 2 (4): "every release after 2026-07-17".

Round 1's finding (1), the incomplete list of winner-file readers, is a different class (an enumeration quantifier). Round 2 checked that list against a grep and found it complete, and it still is.

Round 2's own fix reproduced the defect: it widened the scope sentence to cover 2026-07-17 and kept "pre-registered" (finding 1 below).

## Findings

- **[fragile, doc] research/water_balance_method.md:314.** The sentence reads "The rule for 2026-07-17's rescore and every later release, pre-registered here:". For 2026-07-17, "pre-registered" is false. That release's scores were seen before the rule was written, and the Disclosed paragraph nine lines below (l.323) says so: "the rule was changed after seeing that `cfu` and `fu` are close". So the subsection contradicts itself. That is exactly what round 1 (2) fixed in the report header (`wb_aet_compare.R:252`) and round 1 (3) fixed in l.288.
  - Why it matters: the tracked `wb_aet_compare_20260717.txt` will be rewritten under this rule at the rescore. A reader who checks that report against "pre-registered here" is told the opposite of the disclosure.
  - Fix: separate the two scopes. For example: "The rule, registered here before any release after 2026-07-17 was scored, and applied also to 2026-07-17's rescore (Disclosed, below):".

- **[minor, doc] research/water_balance_method.md:308, and the cross-reference at l.288.** The heading "The AET incumbent at later releases (#89)" still has the scope that round 2 (4) corrected in the body. l.288 sends the reader to the #89 subsection by this title, as the place for the incumbent of the shipped release's own comparison. Retitle it "The AET incumbent since #89" or similar, and change the cross-reference to match.

## Enumeration: every place the mechanism reaches

Every statement about stage 1, its incumbent, "pre-registered" or "pre-set", "fixed before" or "unchanged" in the AET decision:

| place | statement | verdict |
|---|---|---|
| research l.314 | "2026-07-17's rescore and every later release, pre-registered here" | **wrong for 2026-07-17** (finding 1) |
| research l.308, l.288 | heading "at later releases"; l.288 cites it | **narrower than the code** (finding 2) |
| research l.310 | "rule written before any release after 2026-07-17 was scored" | correct as written. It gives the date of writing and claims nothing about 2026-07-17. Fine once l.314 separates the scopes. |
| research l.288 | "under #15's and #18's rules (since #89 with `cfu`, not `cgiar`, as stage 1's incumbent …)" | correct |
| research l.302 | "With `cgiar` as the incumbent (the rule until #89)" | correct |
| research l.316 | "#15's thresholds are unchanged, now measured from `cfu`" | correct (`margin_hw` 2.0, `slack_nes_mae` 1.0, `slack_nes_in20` 3, and `decide()`'s inequalities are unchanged) |
| research l.317 | "Stage 2 is unchanged … #18 registered it with `cfu` as the incumbent" | correct (stage-2 code is untouched) |
| research l.318 | "What ships is unchanged" | correct (`to_user`, l.181, is untouched) |
| research l.319 | #15's record keeps `cgiar` | correct (`wb_cv_lib.R` refuses 20251014) |
| research l.323 | Disclosed paragraph | correct. Its numbers match the tracked report. "Cannot change the 2026-07-17 result" holds: (a) needs ≤ 28.7 headwater, and the best challenger is fu at 31.6. |
| research l.3 (Status), l.138-260; research/README.md row 9 | "A rule fixed before scoring chose it (#15)", "pre-set rule" | correct. These are historical statements about #15 and #18. |
| CLAUDE.md l.28 | "#15's and #18's pre-set rules, with cfu as stage 1's incumbent since #89, so a near-tie keeps it" | correct. The change is attributed to #89, not to the pre-set rules. |
| wb_aet_compare.R l.1-7 (header) | "rules fixed in planning before any variant was scored: #15 … #18 …" followed by "#89, registered 2026-10-16 before any release after 2026-07-17 was scored), so a later release cannot switch on a near-tie" | correct as written. The incumbent is attributed to #89 with its date, and the date clause is true. It does not mention 2026-07-17's rescore but does not exclude it either. |
| wb_aet_compare.R l.22-24 | "under the rules as #15 and #18 fixed them, with stage 1's incumbent from #89" | correct |
| wb_aet_compare.R l.37, l.41, l.117 (comments) | "cgiar in #15"; "in #15's order" | correct (`variants_all` and `cands` order are as before) |
| wb_aet_compare.R l.251-261 (report) | "Rule (#15's thresholds; incumbent set by #89 on 2026-10-16)" + Disclosed | correct (round 1's fix) |
| wb_aet_compare.R l.283-285 | "Stage 1 did not choose cfu: stage 2 … not the comparison #18 registered" | correct under the new incumbent (a winner other than cfu means a challenger cleared the bar) |
| wb_aet_compare.R l.289 (report) | stage 2 "Rule (fixed before scoring)" | correct. This is #18's rule, unchanged, registered with cfu as the incumbent. |
| wb_aet_compare.R l.168-178, l.185-186, l.308, l.310 | "#15's cfu", "as #15's rule was" | correct |
| scripts/wb_validate.R l.13-14 (unchanged) | "chose for this fit by the #15 and #18 decision rules" | acceptable. Stages and thresholds are #15's and #18's. It names no incumbent and no provenance. |
| scripts/wb_cv_lib.R l.103-107 (unchanged) | "Without it the fit ships #15's cfu, and only if the rule picks it" | correct |
| scripts/wb_fit_accept.R l.2 (unchanged) | "pre-registered for #43 and restated for #83" | correct. It is #83's own rule, which really is forward-only. |
| NEWS.md l.111, l.124 | #15 and #18 "rule fixed before scoring" | correct (historical). There is no #89 entry yet; that is release bookkeeping. |
| README.md, vignettes/, R/, data-raw/ | nothing about stage 1 or the incumbent | n/a |

## Code re-checked (clean)

- **The rule.** `decide()` lets only `elig` members win. Stage 1 passes `incumbent1` at l.98, l.149 and l.190. `pass_d` compares with cfu's as-shipped headwater MAE.
- **Winners.** `winner1` falls back to `incumbent1`. Stage 2 (`inc <- winner1`), `ns2` and `ns_inc` are untouched.
- **Order.** `cands` is `cgiar, lc, tc, fu, cfu`, as before, so the `tab1` and `tab12` levels and the report rows are unchanged.
- **sprintf arity.**
  - l.251: 2/2.
  - l.252: 1/1.
  - l.254-257: 5/5.
  - l.274-280: 9/9.
- **Harness.**
  - `cal` excludes NA `obs` (`wb_cv_lib.R:61`), so the synthetic `raw = obs + k(raw - obs)` has no NA.
  - `stopifnot(x$keep_adjust)` matches the tracked report (cfu is "adjusted*").
  - The guards on `unlink("data/wb")` are as rounds 1 and 2 checked them.
