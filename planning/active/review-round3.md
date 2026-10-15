# Code-check round 3 — branch 83-wb-fit-accept-r-cannot-accept-the-next-r (#83)

Reviewer: subagent, 2026-10-15. Probes ran in a fresh copy of the sandbox
(`scratchpad/sb4`), with the branch's `scripts/wb_fit_accept.R` copied in.
`wb_score_md5.R`, `wb_fit_lib.R`, `wb_cv_lib.R`, `wb_validate.R`, `wb_pooled_test.R` and
`data/checks/wb_pooled_test_20260717.txt` were confirmed byte-identical to the repo with
`/usr/bin/cmp`. The 17-case driver (`accept_cases.R`, copied as `sb4/ac.R`) reproduces the
expected exit for every case. The extra probes are in `sb4/p3.R`. The repo's `data/`,
`sb` and the driver were not touched.

## Mechanism

The shared assumption behind R1 and R2 is narrower than "per-fit inputs are not bound".
**`score_code_md5` is the only binding the pipeline has**, and it covers only what is
inside the hash:

- the scoring code, from the current tree;
- `stations_<r>.rds`, which carries `release` inside it, so it binds a fit to its release;
- the three decision files present in the fit.

Everything outside the hash is trusted as found. R1 and R2 were the first two such inputs
to be found: `pooled_test.txt`, and then the tracked report that vouches for it. Each fix
bolted one more out-of-hash input onto the check. The remaining out-of-hash inputs are in
the table below. The ones that matter are:

- the province run;
- the AET and the stations the pooled test ran on;
- whether a decision file was decided for this release.

A second mechanism produced R2's raw-P − AET finding: "as it ships" is a proxy. The script
compares `cv_v`, the adjusted held-out CV, and that equals the shipped estimate only while
`keep_adjust` is TRUE. R2 handled the old side. The new side still has the gap (finding 1).

## Findings

- **[bug] scripts/wb_fit_accept.R:105-106, 126-133 (also research/water_balance_method.md "Each fit as it ships", CLAUDE.md "compares each fit as it ships")**: a new fit that ships raw P − AET can get an unqualified DOES NOT SHIP, scored on an estimate it does not ship.
  - **How it is reachable.** The new fit's pooled test is uninformative, so it is nested and `wb_validate.R:116` does not stop. Its gate then fails beyond any override, so `keep_adjust` is FALSE and `wb_output.R` ships `pmax(raw, 0)`.
  - **What the script does.** It still compares that fit's *adjusted* `cv_v`. Because the gate failed, raw beats adjusted on the headwater gauges.
  - **What the verdict says.** Only `ships && !gate_ok` routes to the user. A DOES NOT SHIP verdict carries no qualifier, and the report prints "each fit is scored as it ships" and "each fit as it ships" unconditionally.
  - **Reproduced** (`sb4/p3.R`, P1). The new fit is nested, with `gate_pass = keep_adjust = FALSE` and the adjusted errors raised 1.5 points; its `raw_v` is left at the shipped fit's. Exit 0, and the report reads `VERDICT: DOES NOT SHIP (+1.50 points)`, under the line "each fit is scored as it ships".
  - **What it should have read.** The fit as it would ship is raw, with a headwater MAE about 30.7 against the old 30.72. That is a pass.
  - **Why it matters.** This is the mirror of R2's old-side finding. It is a refusal of a fit that might pass, and the report says something the code does not do.
  - **Fix.** Either route `!isTRUE(new$keep_adjust[1])` to the user whatever the verdict, as `old_raw` already is, or say in the rule text and the report line that a raw-shipping new fit is scored on its adjusted balance. Both change the pre-registered wording, so it is the user's call. The routing fix is a one-line extension of R2's `old_raw` clause.

- **[fragile] scripts/wb_fit_accept.R:136**: the console line drops the user routing.
  - In R2's new `old_raw` case, and in the existing failed-gate case, the report says "the decision goes to the user" while the console prints `fit 20990101 ships (+0.00 points)` (P2; the sandbox base case).
  - The script decides nothing on disk, and `wb_shipped_release` is "set by hand from this report". An operator who reads the console rather than the report is told the fit ships.
  - The failed-gate half predates this branch (main:78). R2 widened it to a new case.
  - Fix: append the same qualifier to the `message()`, or print the VERDICT line.

No other defect found. R2's fixes (the report matching, `old_raw`, the VERDICT format) behave as documented:

- an empty `pooled_test.txt` gives `OUTCOME: fixed 'NA'` and refuses;
- a report with two OUTCOME lines refuses, because `identical()` gets length 2;
- "nothing fixed" and "fixed '<v>'" match `wb_pooled_test.R:126` exactly;
- the HYDAT string matches `s$hydat_release`'s `YYYY-MM-DD …` form, which `wet_hydat_release()` derives the release name from.

## Every input wb_fit_accept.R reads

"Release" means what ties the input to the release it claims. "State" means what ties it to the current code and decision state.

| # | input (where read) | bound to its release by | bound to current state by | passes while wrong? |
|---|---|---|---|---|
| 1 | `args[1]` (:37) | must be `identical()` to `wb_shipped_release` | — | no |
| 2 | `args[2]` (:40) | 8 digits and `> args[1]` as equal-length digit strings; the fit dir and `stations_<r>.rds` must exist (md5 recipe stops on a missing file) | — | no; the report path can then never be the shipped or an earlier release's (#43's report safe) |
| 3 | `wb_shipped_release` (wb_fit_lib.R:20) | hand-set; deliberately outside `score_files` | nothing ties it to what is published (`discharge_publish.R` has its own checks) | only by an operator bumping it without acceptance; out of this script's reach |
| 4 | `wb_key_dir()` (:42) | — | exactly one complete province run; a fit is tied to it **by location only**, since `score_code_md5` excludes the province run ("besides the province run itself") | yes, by design: a fit dir copied into a new key stays md5-current with CV from the old run's predictors (`wb_cv_lib.R:115` anticipates "fits.rds travels with the fit (a new key …)"). The shipped fit is itself such a carry: it lives in `e675918817`, and its pooled test ran in `962a9cc2c4`. Shared with `wb_output.R`; predates this branch |
| 5 | `score_md5_for(r)` (:45-50, sourcing the current tree's `wb_score_md5.R`) | `stations_<r>.rds` (path and content; it carries `release`, checked at scoring by `wb_cv_lib.R:25`) | the current scoring code plus the decision files present in `fit_r` | not for anything inside the hash |
| 6 | `fits.rds$code_md5`, `$release` (:59, :66) | `$release == r` | `== score_md5_for(r)` | no (only by hand-editing fields) |
| 7 | `fits.rds$aet` (:54, :63) | via the winner | winner line 1 must equal it, and the winner is stamped with the md5 | no |
| 8 | `fits.rds$gate_pass`, `$keep_adjust` (:93-94, :106, :109) | content trusted under the stamp | same | no, but see finding 1: `keep_adjust = FALSE` on the new side is not acted on |
| 9 | `cv_aet-<aet>.rds$code_md5`, `$release` (:59, :66) | `$release == r` | `== md5` | no |
| 10 | `cv_aet-<aet>.rds$cv_variant` (:84) | — | must equal pooled_test line 1 (or `nested` for uninformative); also derived from the hashed `pooled_variant.txt` | no |
| 11 | `cv_aet-<aet>.rds$cv_v$stations$err_pct`, `$station_number`, `$nesting` (:87-89) | content under the stamp; `err_pct` is NA below 10 mm (`wet_flow_validate.R:47`) | same | no. fits.rds and cv could come from two runs under one md5 that differ only by #76's rounding: benign |
| 12 | `aet_winner.txt` lines 1-2 (:62-65) | via the md5, which includes the release's stations | `== c(fits$aet, md5)` | no |
| 13 | `pooled_test.txt` line 1 (:72-77) | via the report (row 14) | must match `cv_variant` | only through row 14's gaps |
| 14 | `data/checks/wb_pooled_test_<r>.txt`, its HYDAT and OUTCOME lines (:73-83) | filename plus "HYDAT release YYYY-MM-DD"; only `wb_pooled_test.R` on release r writes it | OUTCOME must equal pooled_test line 1 | **province run**: named on the "fit:" line, not checked; requiring it would refuse the shipped fit today (row 4). **AET**: named, not checked; driver case "new fit ships another AET" passes with a report saying `cfu`. **Stations at test time**: if `wb_stations.R` reruns release r afterwards, the chain is rescored, but `wb_pooled_test.R:31` will not rerun, so the outcome from the earlier stations is accepted. All three follow from "runs once per fit" (#43). None is a defect of this branch, and the rule text claims none of these bindings |
| 15 | `pooled_variant.txt`, `adjust_override.txt`, `aet_decision.txt` (via md5 only) | hashed, but **not** tied to the release they were decided for | hashed | `pooled_variant.txt` copied in is refused through rows 13-14. `aet_decision.txt` is copied by design (CLAUDE.md). An `adjust_override.txt` copied from the shipped fit (its text names #43 and 2026-10-06) is hashed and used: on the new side, a failed gate then reads "FAIL (adjustment kept by override)", and a SHIPS verdict routes to the user, so acceptance is safe. Upstream, though, `wb_aet_compare.R` applies the copied override inside each fold, which can change the new fit's AET winner unseen. That is #81's surface, not this script's |
| 16 | `margin` (:41) | constant | — | no |
| 17 | output `wb_report("wb_fit_accept", args[2])` (:114) | `args[2]` is later than shipped, so never 20251014's unsuffixed name and never #43's `_20260717` | written only after every check | rerunning on the same new release overwrites its own report: intended |

## For the user (not defects of this diff)

- **Row 14, AET.** The documented chain lets the AET change after the pooled test ("a decision file written later (`wb_pooled_test.R` …) stales the winner: rescore every variant and compare again"). A fit can therefore ship an AET other than the one its pooled-zone test ran with (`wb_pooled_test.R` header: "with this fit's AET"). The #83 rule asks only that the scores use the test's outcome, which holds. Whether the test must also have run on the shipped AET is a rule question.
- **Row 15, override provenance.** Nothing checks that `adjust_override.txt` was decided for the fit it sits in. Acceptance surfaces it; the AET comparison does not.

/Users/airvine/Projects/repo/wet/planning/active/review-round3.md
