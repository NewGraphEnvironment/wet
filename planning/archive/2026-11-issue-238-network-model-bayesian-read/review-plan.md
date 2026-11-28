# Plan review for #238 (backlog move 22: #218 then #217), 2026-11-26

Blockers raised: 2
Owner forks: 3

A Plan agent reviewed `task_plan.md` against #238, #217, #218, #214, #213, the code and knowledge's review at f0a6cbd0. Each finding was probed before folding (2026-11-26: `-0.49` is in no `data/checks/` file; `grep complete R/wet_temp_gsdd.R` finds nothing; `scripts/temp_baseline_traits.R:228` takes `share_related()` from `scripts/wb_cv_lib.R:223`; wet has no `.lintr`; `tb_code_files` at `scripts/temp_baseline_lib.R:322-324`). The reviewer counted 2 owner forks (S1, S2); G5's fallback was also written under Open decisions, so 3.

## Findings and verdicts

- **B1 (Blocker): the inventory lived in `findings.md`, which the archive moves, and anchors in table cells break on `|`.** Confirmed. Folded: a `choices` list in the script; the table carries id, `file:line`, verdict; the script holds `file:line` to the anchor's line.
- **B2 (Blocker): the figure check had no spec; −0.49 has no tracked report line; printing it from a baseline script would stale the recovery report.** Confirmed. Folded: a `figures` list (text, source, literal); derived and untracked figures held to `research/station_temperature_fill.md`'s sentence; an unlisted-numeral guard; no new figure computed, and no `tb_code_files` edit.
- **G1 (Gap): scope missed `share_related()` and many choices; "every choice has a row" needed a mechanical backstop.** Confirmed. Folded: `scripts/wb_cv_lib.R`'s `share_related()` in scope; the inventory list widened and called a floor; a `registry` requiring a row for every formal with a default and every top-level numeric assignment in scope; `temp_fill_parity.R` and `wet_temp_daily()`'s day rule out, with reasons.
- **G2 (Gap): mutation runs could overwrite the committed log.** Folded: no log for any `MD=` but the known files; mutations on copies only; the committed log checked unchanged.
- **G3 (Gap): #217 items the outline drops were not listed.** Folded into open decision 1, each named with where it goes.
- **G4 (Gap): #217 open after the move closes may be re-batched as build work.** Folded: a comment on #217 at the merge (owed).
- **G5 (Gap): no fallback if decision 1 waits.** Owner fork: open decision 4, recommended hold Phase 1 on the branch.
- **O1 (Ordering): move 20 moves the anchors and nothing makes it run the check.** Folded: a books-free mode, a `CLAUDE.md` line, a comment on #236 (owed). The optional testthat test is declined: the check reads `scripts/`, which the built package does not ship.
- **O2 (Ordering): the `station_temperature_fill.md` pointer is outside the declared Touches and in move 20's and 23's.** Folded: pointer dropped; `CLAUDE.md` named as an added touch.
- **A1 (Assumption): anchors also need `file:line` held.** Same fix as B1.
- **A2 (Assumption): gsdd's `complete = TRUE` has no text in wet.** Folded: inherited choices anchored at the `gsdd::gsdd()` call, gsdd's version recorded.
- **A3 (Assumption): the quote half's setup.** Folded: a preflight naming what is missing; `cred::crd_search()` named; no absolute path in the log.
- **A4 (Assumption): "no count that will move" against figures in #217's file.** Folded: #217's file quotes no score and links the research files; the guard holds it.
- **A5:** verified, no change.
- **S1 (Scope, owner fork): a region with more than one outlet** is #223's and move 23's question too. Open decision 2.
- **S2 (Scope, owner fork): traits per segment have no issue** against #217's first "Done when". Open decision 3.
- **S3 (Scope):** book location listed among the gate's confirmations; decisions 1 and 2 merged; knowledge's header not edited (proposed there). Folded.
- **AC1 (Acceptance): lint threshold.** Folded: no class beyond `scripts/temp_baseline*.R`'s.
- **AC2, AC3:** covered by G1, S2, G3.

## Files the plan names

planning/active/task_plan.md
research/temperature_bayesian_alignment.md
research/temperature_network_model.md
research/README.md
research/station_temperature_fill.md
research/station_water_temperature.md
scripts/temperature_bayesian_alignment_check.R
R/wet_temp_fill.R
R/wet_temp_gsdd.R
R/wet_donor_mean.R
R/wet_cv_folds.R
scripts/wb_cv_lib.R
scripts/temp_fill_validate.R
scripts/temp_fill_parity.R
scripts/temp_baseline.R
scripts/temp_baseline_lib.R
scripts/temp_baseline_rule.R
scripts/temp_baseline_traits.R
scripts/temp_baseline_recover.R
scripts/wb_score_md5.R
data/checks/temp_baseline.txt
data/checks/temp_baseline_recover.txt
data/checks/temp_baseline_frame.txt
data/checks/temp_fill_validate.txt
CLAUDE.md
planning/backlog.md
