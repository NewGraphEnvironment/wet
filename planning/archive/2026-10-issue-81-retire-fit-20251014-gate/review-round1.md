# Code review, round 1 — branch 81-retire-fit-20251014-as-a-gate-re-decide vs main

Scope: scripts/wb_aet_compare.R, wb_validate.R, wb_cv_lib.R, wb_score_md5.R, wb_output.R,
wb_fit_lib.R, wb_pooled_test.R, segment_output.R, discharge_publish.R, pcic_routed_lib.R,
CLAUDE.md, research/water_balance_method.md, research/discharge_publish.md. Read in full; the
consumers of `aet_winner.txt`, `aet_code_md5` and the new `wb_cv_lib.R` globals were grepped
across scripts/, data-raw/, R/ and tests/.

## Findings

- **[severity: fragile]** research/discharge_publish.md:48, research/water_balance_method.md:51,
  CLAUDE.md:72: the docs state outcomes that do not exist yet.
  - discharge_publish.md says cfu was "re-decided on the shipped release by #81".
  - water_balance_method.md says cfu was carried "until #81 re-decided it on this release
    (below)", and there is no such section below.
  - CLAUDE.md:72 says "Tag `aet-15-record` reproduces #15 ... (`research/water_balance_method.md`
    §0)". `git tag -l 'aet*'` and `git ls-remote --tags origin 'aet*'` both return nothing, and
    §0 has no reproduction recipe. The only mention of the tag in research/ is the parenthesis at
    water_balance_method.md:227.

  The same pointer is in code messages: wb_cv_lib.R:16 (the stop text), wb_aet_compare.R:24 and
  wb_fit_lib.R:55. All of this is pending in task_plan.md (lines 34, 36 and 76), so it is not a
  code defect today. If the m4 run of wb_aet_compare.R on 20260717 returns DECISION TO USER, or
  another AET, the two research sentences become false as written. If the branch merges before
  the tag is pushed, the stop message in wb_cv_lib.R points at a tag that does not exist. The
  research text should wait for the run's result, and the tag must be pushed before the PR merges.

- **[severity: fragile]** scripts/wb_aet_compare.R:291-297 and :316-321, with
  scripts/wb_validate.R:49-52: after DECISION TO USER, the user's decision cannot be recorded.
  - The compare deletes `aet_winner.txt` (line 31) and writes none.
  - wb_validate.R's stop message tells the user to "score every variant and run
    scripts/wb_aet_compare.R". That path ends at DECISION TO USER again, deterministically.
  - The only way to ship the user's choice is to hand-write `aet_winner.txt` as
    `<aet>\n<score_code_md5>`. That file then looks exactly like a compare-made winner, and it
    records neither who decided nor why. Contrast `adjust_override.txt`, which requires the
    "who decided, and why" lines (wb_cv_lib.R:101).
  - Once fits.rds is rewritten from such a file, the next compare reads the hand-picked AET as
    `shipped_aet` (line 170) and passes it without comment.

  Nothing fails, and nothing ships by accident, because every consumer fails closed on a missing
  winner. But the "user decides" branch has no recorded mechanism, so the first time it fires it
  will be settled by an unaudited hand edit. Consider a decision file named in the DECISION TO
  USER line, or at least the exact command, before a run can reach it.

No other defects found. Checked and correct:
- Every reader of the winner file was moved from `aet_code_md5` to `score_code_md5`:
  wb_output.R, segment_output.R, discharge_publish.R, pcic_routed_lib.R `shipped_heldout()` (and
  through it data-raw/*_vignette_data.R), and wb_validate.R. wb_share_snow.R reads only line 1.
  None are left on `aet_code_md5`, which now feeds only `fits$aet_md5` and wb_fit_accept.R
  (known gap #83).
- `fixed_variant`, `f_pooled`, `override`, `tie_tol`, `f_override` and `keep_adjust_for()` moved
  into wb_cv_lib.R and still resolve at every use in wb_validate.R (:55, 57, 111, 115, 118, 197,
  205, 236) and wb_aet_compare.R. No other sourcing script defines those names
  (wb_pooled_test.R:30 redefines `f_pooled` to the same path).
- The nested selection's `keep_adjust_for(metrics(...)hw, ...)` matches wb_validate.R's
  `keep_adjust_for(hw(cv_v), hw(raw_v))`. Lines 85-90 assert that the two hw definitions agree.
  The fixed variant is used in both `as_shipped_cv()` and the `nested_select()` refit
  (`m$pv`).
- `winner_raw` matches wb_validate.R:115's refusal condition. `to_user` is evaluated after the
  unlink, so every early stop leaves no winner (fails closed).
- The decision files enter `score_code_md5` (wb_score_md5.R:33-39). A pooled_variant.txt or
  override written after a compare stales the cv files (compare line 41), the winner
  (wb_validate.R:41) and fits.rds (wb_output.R:35), as CLAUDE.md now says.
- The sprintf argument counts in the new report lines match their formats (header line,
  (d) line, adjusted* note, DECISION TO USER line). A `NULL` from an `if` inside `c()` drops
  cleanly.
- The three-line carried `aet_winner.txt` on `fit_20260717` (present on m1:
  `cfu / fc34e32c… / carried from fit_20251014 …`) makes wb_validate.R:40 stop "bad" before it
  scores anything. This is known and handled operationally: review-plan B1, and task_plan line
  63 removes it after the `_pre81` copy.
- The MOD16 gap-fill claim at wb_aet_compare.R:153 is verified at scripts/wb_province.R:139
  (`fr * et_mod16 + (1 - fr) * aet_cfu`).
