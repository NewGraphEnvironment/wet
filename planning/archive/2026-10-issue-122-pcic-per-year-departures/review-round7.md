# Code-check round 7: 72e9556..HEAD (6f7bc15, 88062f8)

## Checklist read

- I read all four indexes in full: index-code-check.md (37 H3), index-code-check-r.md (111), index-code-check-shell.md (67) and index-code-check-spatial.md (93).
- code-check.md: I read the prose of all 14 H3s under `## Mechanisms`, skipping the table rows. I did not read the 23 other H3s, which are the stand-alone, security and spreadsheet rules. None of them names a tool or shape this diff uses.
- code-check-r.md: I read 4 sections in full and did not read the other 107:
  - "`$` on a list partial-matches", because of `b$n`;
  - "`[[` on a named ATOMIC vector with an absent key", because of `sc_t2[[g]]`;
  - "`paste()` with a zero-length argument returns length ONE", because a NULL argument to `sprintf()` gives a zero-length line;
  - "Rscript reads a script as it runs".
- code-check-shell.md: I read no section in full, because the diff has no shell code. 67 not read.
- code-check-spatial.md: I read no section in full, because the diff touches no spatial call. 93 not read.

## What was checked and holds

- **The new `n` columns (`scripts/departure_pcic.R:763-770`, `:794-803`).**
  - Arity and widths: the §4 header has 10 `%s` for 10 arguments. Each row has 11 specifiers (`%s %s %d %s %s %s %d %s %s %s%s`) for 11 arguments. §6 has 12 in the header and 12 in each row. Each new `%3d` sits under a `%3s` header cell.
  - `score()` always returns `n`, as `length(yrs)`, an integer, including when fewer than 3 years leave `nse` all NA. So `b$n` is never NULL.
  - `b$n` matches exactly, so the partial-match trap toward `nse` does not apply.
  - `sc_t2` is keyed by `run_set(targets = test$station_number)`. In `series_run1.rds`, `identical(names(x$test), x$test_stations$station_number)` is TRUE (63 gauges).
  - `sc2_main` is keyed by `names(main)`, which is `mig_pool`.
  - No `[[g]]` returns NULL, so no row comes out zero-length.
  - Recomputed stage-2 `n` over the test set ranges from 2 to 10 (08EE009 has 2), and over the pool from 10 to 62. Both fit `%3d`.
- **The header parenthetical (:241-245).** b518ebc did edit the usage lines (:9-10) and the refusals list (:265-268) as well as the interface section, and nothing else. The parenthetical now says so.
- **Research, `research/pcic_hydrology.md` #122 section, checked against the committed report and `series_run1.rds`.**
  - Stage 1: the table, 0.054/0.047, 84 against 81 km, and "0.01 to 0.02" all hold.
  - Stage 2: −0.242/−0.208 and −0.009/+0.008 hold.
  - The test set: "ranks them as the held-out pool does" holds. Held out it is cov_pick > covariance > distance and donors > blend > pcic; the test set gives 0.66 > 0.56 > 0.50 and 0.65 > 0.60 > 0.41. The 60 and the 62 are right, and the 62 is printed only by the rerun, which is accepted under round 6 finding 6.
  - Maxan: "five years" is stage 1's `n`, and the figures it is attached to are stage-1 figures.
  - The skill table: the basins sum to 94+78+90+28 = 290. "Correlation well above its NSE everywhere" holds over the group medians, and r ≥ NSE also holds at every one of the 290 gauges (recomputed: 0 gauges with r < NSE).
  - Sensitivities: pcic is below donors in every §5 row. "Largest gain among the report's medians" holds: +0.024 at blend 0.75; the leak-free result is +0.008; k = 8 is under 0.01 at two decimals; every other median has the blend at or below donors.
- **`research/station_flow_departure.md:117`.** 290; 0.72 against 0.67; 0.48; blend 0.71 held out; "in either pool" (−0.009 and +0.008). All hold.

## Findings

- **[severity: fragile]** scripts/departure_pcic.R:279-280. The banner's new sentence says that after the first runs the body "was edited only in what the report prints (code-check rounds 5 and 6)". That is false for one of the body's changes since 42fdd45.
  - **What else changed.** Round 5 (72e9556) moved `years_run`/`period_run` up to :311-312 so that `routed_commit(period_run)` (:313; `scripts/pcic_routed_lib.R:34-38`) could pass the period. That changes the wording of the WET_FWAPG_COMMIT refusal, from "… historical 1981-2010" to "… 1951-2012". The commit's own title is "the commit refusal names the run read". That text goes to stderr on a refusal and never into the report.
  - **What did not change.** Neither change alters a computed value, an input read, a guard's condition, or the rds. The rds differs only in `code_md5` and `wet_commit`, as any commit does. So "moved no score" holds, and so does "nothing here changes [the rule]".
  - **Why it matters.** This is round 6's mechanism again. A claim written for one member of the set of post-run edits (the report-text ones) is placed where it reads as covering all of them, in the pre-registration record.
  - **A second weak point.** The closed list "(code-check rounds 5 and 6)" goes stale if any later round touches the body.
  - **Suggested wording.** "After the first runs on the product it was edited only in what it prints: the report's counts (code-check rounds 5 and 6) and the wording of the WET_FWAPG_COMMIT refusal, with the two assignments it needs moved up (round 5). No computed value, input or guard changed, and no score moved."

- **[severity: fragile]** research/pcic_hydrology.md:49. "#122 (component 2 of #118 …)" contradicts the script's header, `scripts/departure_pcic.R:1-2` ("#122, component 3 of #118"). The repo's own numbering gives #120 component 1 (`scripts/departure_pilot.R:1`) and #121 component 2 (`scripts/departure_snow.R:1`, `research/station_flow_departure.md:121`). So #122 is component 3, and the research provenance line names the slot that #121 holds. This line was added on this branch at 6b42331, outside the 72e9556..HEAD range, and no report supports it. Fix: "component 3 of #118".

The mechanism does not reach anywhere else I checked:
- The two-count summary line and the two `n` columns now carry each stage's own count.
- The research quantifiers above hold over their stated sets.
- The report's opening rule line names every header amendment.

## Triage and the enumeration that ends the loop (main session)

Both findings confirmed and fixed: the banner names every kind of post-run edit (09e72f1, alone); the research line says component 3.

Rounds 5, 6 and 7 each found a defect inside the previous round's fix, all one mechanism: a count or claim for one member of a set placed where it reads as covering the set. The candidate set is every line of `scripts/departure_pcic.R`'s report that prints a count (`awk 'NR>=640 && /%[0-9]*d/'`, 22 lines). Each was checked against the values beside it:

- same table or same set: the stage tables' `n` and "not scored" (from the one `tab_of()` result they sit in), the sensitivities' `n` and `n2`, the files, parity, windows, pool and candidate lines, the short-record summary (two counts since round 5), the per-gauge tables (two counts since round 6);
- from one pool but printed under a line that scores both: the fallback, short-r and donor-distance lines, and the PCIC-skill heading, all from the leave-one-out run. Now labelled "Leave-one-out" in the report.

Nothing else in the report prints a count from another set. The research quantifiers were walked by round 7 (every one holds against the report and the series).

