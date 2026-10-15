# Code review, round 2: branch 81-retire-fit-20251014-as-a-gate-re-decide vs main

Scope: branch.diff, plus every changed file read in full (wb_aet_compare.R, wb_validate.R,
wb_cv_lib.R, wb_score_md5.R, wb_output.R, wb_fit_lib.R, wb_pooled_test.R, segment_output.R,
discharge_publish.R, pcic_routed_lib.R, CLAUDE.md, both research files). I also read
wb_fit_accept.R, and grepped every other script that sources wb_cv_lib.R
(pcic_routed_compare.R, wb_term_diagnose.R, wb_gauge_diversion.R,
data-raw/segment_vignette_data.R, data-raw/monthly_vignette_data.R) for collisions with the
globals that moved into it. The main focus was the round-1 fix, `aet_decision.txt`.

## Findings

- **[severity: fragile]** scripts/wb_aet_compare.R:170-175 and :300-305: on the shipped release,
  the anchor `shipped_aet` is read from the same fit's `fits.rds`. `wb_validate.R <winner>`
  rewrites that file (wb_validate.R:121-130) before anything is published. Publishing is a
  separate `WET_PUBLISH=1` step.

  After a decided switch, the sequence is:
  1. The compare writes winner `tc` and reports "a switch from cfu ... recorded in
     aet_decision.txt: <who, why>".
  2. `wb_validate.R tc` rewrites `fit_20260717/fits.rds` with `aet = "tc"`.
  3. CLAUDE.md requires a re-compare after any later pooled test, override or scoring-code
     change. Any such run now reads `shipped_aet == "tc"`, so `switch_decided` is FALSE and
     `to_user` is FALSE. The report says "the AET shipped now (fit_20260717)".

  Three consequences follow:
  - (a) The who/why line drops out of the tracked `wb_aet_compare_20260717.txt` on the very
    next run, although `aet_decision.txt` is still there.
  - (b) "shipped now" is false until a republish. The live build is still cfu, and
    discharge_publish.R's manifest text says cfu (#83).
  - (c) `aet_decision.txt` no longer gates anything. If it is deleted, or missing from a copied
    bundle, the comparison keeps writing `tc` with no record of who decided. Deleting it
    changes `score_code_md5` and forces a rescore, but the rescored compare still passes `tc`
    as "the AET shipped now".

  This is the same hole round 1 named ("the next compare reads the hand-picked AET as
  `shipped_aet` and passes it without comment"). The decision file closes it only for the
  first run after the decision. Suggested minimal fix: print the decision whenever
  `identical(aet_decision[1], winner)`, not only when `winner != shipped_aet`. If the record
  should stay load-bearing, anchor `shipped_aet` on something this pipeline does not write
  before a publish, such as the live manifest or the published build's fits. Otherwise, when
  the winner is not cfu, require `aet_decision.txt` to name it whatever `fits.rds` says.

- **[severity: fragile]** CLAUDE.md:73 and the reduced-bundle copy: `aet_decision.txt` is now
  a third file hashed into `score_code_md5` (wb_score_md5.R:34-36). CLAUDE.md:73 still lists
  the per-fit decision files as "`pooled_variant.txt` and `adjust_override.txt`". The m4-to-m1
  copy that CLAUDE.md prescribes ("Copy reduced bundles rather than rebuilding";
  task_plan.md:73 lists fits.rds, aet_winner.txt, cv_aet-cfu.rds and output/) relies on the
  decision files already being on m1. Today they are: pooled_variant.txt and
  adjust_override.txt are present in m1's fit_20260717.

  After a decided switch, a bundle copied without `aet_decision.txt` gives m1 a different
  `score_code_md5`. Then segment_output.R:70, pcic_routed_lib.R:63-66 (so both data-raw vignette
  scripts) and wb_output.R:35 all refuse with "made under other scoring code". That fails
  closed, but the message points at code rather than at a missing decision file. Listing all
  three files in CLAUDE.md:73, and in the bundle copy, prevents it.

No other defects found. Checked and correct:
- `aet_decision.txt` validation (wb_cv_lib.R:107-112): `NULL[1]` in `identical(aet_decision[1],
  winner)` is safe. A malformed file stops every script that sources wb_cv_lib.R (fail closed),
  and the names checked are the 10 in `wet_wb_aet_cols()`.
- `to_user` precedence: a recorded switch cannot override `winner_raw`, which matches
  wb_validate.R:115's refusal. The early stops all come after the unlink at line 31, so none
  leaves a winner behind.
- Hashing `aet_decision.txt` makes writing it stale every `cv_aet-*.rds`. The rescore is
  deterministic (no RNG on the scoring path), so the rescored compare reproduces the winner and
  writes it, as CLAUDE.md describes.
- The globals moved into wb_cv_lib.R (`fixed_variant`, `f_pooled`, `override`, `tie_tol`,
  `f_override`, `aet_decision`, `f_aet_decision`, `keep_adjust_for`) collide with no name in the
  other scripts that source it. `wb_pooled_test.R:30` reassigns `f_pooled` to the same path.
  m1's adjust_override.txt (0.1, three lines) passes the stricter validation now applied in
  every sourcing script.
- `keep_adjust_for()` gives the same answer in wb_validate.R:111 and in the nested selection
  (wb_aet_compare.R:107), and lines 85-90 assert that the two headwater MAEs agree. `gate_pass`
  is saved in cv_aet-*.rds (wb_validate.R:137), so `top$gate_pass` exists for every current
  file.
- The sprintf argument counts in the new report lines (header, adjusted* note, (d) line,
  WINNER/DECISION block) match their formats.
- wb_fit_accept.R can no longer be made current for 20251014. That is #83's territory and was
  accepted.
