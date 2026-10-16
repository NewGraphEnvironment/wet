# Task: Make cfu the incumbent when the AET is re-decided, so a near-tie cannot force a switch (#89)

## Problem

Since #81, `scripts/wb_aet_compare.R` re-decides the AET at every release by #15's and #18's rules as written. Stage 1 starts from **cgiar** as the incumbent every time (`decide(top, "cgiar", eligible)`, lines 92, 143, 184) and ships whichever challenger that passes has the lowest headwater MAE. Two of those challengers are nearly the same estimate:

- On HYDAT 2026-07-17 (`data/checks/wb_aet_compare_20260717.txt`), headwater MAE as shipped: cfu 30.7 %, fu 31.6 %, a 0.9-point gap. Both clear cgiar (37.4 %) by the 2.0-point bar.
- cfu is the cell-wise maximum of CGIAR and fu, so the two differ mainly where CGIAR exceeds fu (zone 17 in the report's detail table).
- In the nested selection, fu already wins 26 of the 94 outer folds; cfu wins 68.

So a later release can rank fu first on a sub-point difference. That winner is not cfu, so the run writes no `aet_winner.txt` and the decision goes to the user (#81). Accepting it then means `aet_decision.txt`, rerunning the pooled-zone test under the new AET (#85), rescoring every variant, and rewriting the `wet_balance` description, README and `research/discharge_publish.md` (#85).

Meanwhile the AET inputs are fixed climatologies. A new HYDAT release changes only revised gauge flows and a few calibration gauges, so it carries little new information about which AET is right.

## Phase 1: Pre-register the rule
- [x] `research/water_balance_method.md` §0: add the subsection "The AET incumbent at later releases (#89)" after "The AET re-decided on HYDAT 2026-07-17 (#81)", with a provenance line. It states the rule, what was rejected and why, the disclosure (changed after seeing cfu ≈ fu; it can't change today's result; it favours the status quo), and that `fit_20251014` / `aet-15-record` stay under cgiar
- [x] `scripts/wb_aet_compare.R` header (l.1–24): stage 1 is cfu against cgiar, lc, tc and fu (#89, registered 2026-10-16 before any later release was scored), and #15's own run had cgiar as incumbent (tag `aet-15-record`)

## Phase 2: cfu as stage 1's incumbent in `wb_aet_compare.R`
- [x] `incumbent1 <- "cfu"`; `eligible <- c("cgiar", "lc", "tc", "fu")`. Spell out `variants_all` and `cands` in today's order, so report rows and tie order don't change. Update the `cands` comment
- [x] Use `incumbent1` in place of `"cgiar"` at the top-level rule, `ns1`, the (d) reference row and `winner1`, and inside the `ns12` transparency run. Rename `cg` → `inc1_row` (or keep the name and fix the comment)
- [x] Threshold comments (l.48–53) say "the incumbent", not cgiar
- [x] Report: the stage 1 heading becomes `"## Stage 1 (#15, incumbent since #89): cfu against cgiar, lc, tc, fu"`; the rule text says "replaces cfu", and the (d) line says "cfu as shipped". Every variant's score is still listed, and the DECISION TO USER and SHIPS lines are unchanged
- [x] `grep -n cgiar scripts/wb_aet_compare.R`: every remaining hit is a variant name or a description, not the incumbent

## Phase 3: Verify in a sandbox on m4
Push the branch first. On m4, make worktree `wet-89` (branch) and `wet-89old` (detached at `origin/main`). Logs go in each worktree's `data/logs/89/`, and get moved into the main checkout's `data/logs/89/` before the worktrees are removed.
- [ ] Harness `planning/active/sandbox_89.R <case>`, run from inside a worktree. It builds the worktree's `data/wb/`: `stations_20260717.rds`, `e675918817/upstream` and `e675918817/ex_filled_cells.txt` are symlinks to the main checkout's (read only). `fit_20260717/` is a real directory with copies of the ten `cv_aet-*.rds` and `pooled_variant.txt`, `adjust_override.txt`, `pooled_test.txt` (no `fits.rds`, no `aet_winner.txt`). It re-stamps each copy's `code_md5` with that worktree's `score_code_md5`, which is valid because no score reads `wb_aet_compare.R`. For a synthetic case it replaces fu with cfu shrunk toward obs: `raw` and `cv_ann` = obs + k·(cfu − obs), cfu's `keep_adjust`, and the headwater rows of `cv_v`/`raw_v$summary` recomputed. k is set so that fu's headwater MAE is 1.5 or 2.5 points below cfu's 30.7 (the MAEs scale by k exactly)
- [ ] Re-stamp check: in `wet-89`, run `wb_validate.R cfu` in the sandbox. Its `cv_aet-cfu.rds` must equal the re-stamped copy in every field (≈5 min). Restore the tracked `data/checks/` the run rewrites
- [ ] Real case, new code: `wb_aet_compare.R` → WINNER cfu, SHIPS cfu, `aet_winner.txt` written
- [ ] fu 1.5 points better, new code: winner cfu, so the incumbent bar holds it
- [ ] fu 2.5 points better, new code: (a)–(c) choose fu, and if (d) passes, DECISION TO USER with no `aet_winner.txt`. If (d) fails for the synthetic fu, report that, and say what the case did and didn't test
- [ ] fu 1.5 points better, old code (`wet-89old`): winner fu → DECISION TO USER. This shows the change is what holds it
- [ ] Copy each sandbox report out of `data/checks/` into `data/logs/89/<case>.txt`, `git checkout` the tracked report in both worktrees, and record the four outcomes (winner, (a)–(d) lines, fold counts) in `findings.md` and the research subsection

## Phase 4: Docs name the incumbent
- [x] `CLAUDE.md` water-balance bullet (the `wb_validate.R [AET]` paragraph): "#15's and #18's pre-set rules … with cfu as stage 1's incumbent since #89"
- [x] `research/water_balance_method.md` #81 subsection: "with #15's and #18's rules unchanged" gains a pointer to the #89 subsection. Grep `research/`, `scripts/` and `CLAUDE.md` for other sentences describing stage 1 as cgiar-incumbent at later releases, and fix those that describe current behaviour; #15's record sentences stay
- [ ] Update the issue body if the work changes what it says (for example, the sandbox outcomes)

## Validation
- [ ] Tests pass (`devtools::test()`; the script isn't under test, so this guards against collateral damage only)
- [ ] `/code-check branch` clean
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` (README with Measurement and Evidence: `data/logs/89/` on m4), then `/gh-pr-push`

