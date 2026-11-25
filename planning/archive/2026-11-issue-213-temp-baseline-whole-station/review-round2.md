# Code-check round 2 of #213 (branch `213-water-temperature-at-stations-with-no-re`, `git diff 60956900...HEAD`, HEAD 3bf50c66)

Reviewed 2026-11-25 (UTC). Nothing in the repo was edited, staged or committed but this file. No
script of the branch was run. Three in-memory probes read the cached frame and scores and wrote
nothing; the two temp_baseline test files and one md5 demonstration ran in a detached worktree
copy (`git worktree add --detach`, removed afterwards; `git status` of the repo clean before and
after). Line numbers are the files' at HEAD 3bf50c66.

## Checklist read

- `code-check.md` (38 headings): the prose of all 14 H3 under `## Mechanisms` (table rows
  skipped). Not read beyond the index line: 24 (14 standalone, 6 Security, 4 Spreadsheets and PDFs).
- `code-check-r.md` (132 headings), read in full: "Rscript reads a script as it runs, so never edit
  a script while a run of it is in flight", "`stats::aggregate()` has three separate silent
  behaviours, and each fails in a different direction", "`system2(stdout = TRUE)` warns on a
  non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires",
  "`clusterApply()` returns `NULL` for no tasks, not an empty list". Not read: 128 (checked
  against the index line only).
- `code-check-spatial.md` (98 headings): none read; the round 1 fixes touch no spatial code, and
  the traits script's one changed line is a count. Not read: 98.
- `code-check-shell.md` (75 headings): none read; the diff holds no shell. Not read: 75.
- index, diff and changed files read from file.

## Findings

No finding moves a published number, and the three tracked reports are sound as they stand. All
five are about what the round 1 fixes guarantee, or say they guarantee.

1. **[severity: fragile]** `scripts/temp_baseline_recover.R:118` (with `:52`, `:243`) — the
   must-fire arm's bar is the bar for a pool that removes nothing; the case round 1 named, a pool
   that removes one direction only, is separated by `n_sim <- 1600` alone, and nothing asserts it.
   - `fires` asks the donor's blocked `leak_z` to be under −3. A leak-free pool that drops only
     the upstream (or only the downstream) neighbours leaves about half the leak, so its z is
     about half the blocked one, and `leak_ok` catches it only when the blocked z is past about
     −6. `fires` passes from −3.
   - Measured by replaying the report's own stream in memory (seed 213, the script's draw order,
     donor weights per pool; the control reproduces the report's donor rows exactly: blocked
     −7.842, −8.184, −8.545, leak-free −0.053, −0.408, −0.705, and at 200 sets the old report's
     −3.13, −2.30, −3.51):
     - 1,600 sets: upstream-only pool −4.13, −4.26, −4.71; downstream-only −5.00, −5.56, −5.80.
       Both would stop the run, so the tracked report does separate them.
     - the first 300 sets of the same stream: blocked −3.37, −3.53, −4.69, so `fires` is PASS;
       upstream-only −1.87, −1.49, −2.69, so `leak_ok` is PASS too. A report written at 300 sets
       would print both lines PASS over a pool that leaves every downstream neighbour in.
   - The expected leak is linear in what the pool leaves (−2·sd_net²·Σ w·shared): upstream-only
     leaves 50 % of the donor's blocked leak, downstream-only 67 %. So the arm that matches the
     claim is the blocked z under about −2·`z_max`, or the two one-direction pools planted in the
     run and each required to fail (the weights depend on traits alone, so they are computed once).
   - **Rule:** code-check.md "Restore the bug and prove the guard fires" ; code-check.md "A fixture that cannot reach the failure mode"
   - INSIDE round 1 fix 1.

2. **[severity: fragile]** `scripts/temp_baseline_recover.R:47-49` and `scripts/temp_baseline.R:80-83`
   (claimed at `CLAUDE.md:58`, `scripts/temp_baseline_lib.R:279-280`,
   `scripts/temp_baseline_recover.R:43`, `planning/active/progress.md:53`) — the md5 is taken after
   the code is loaded, not before, and the workers' later load is never held to it.
   - Both scripts run `devtools::load_all()`, then `source()`, then `code <- tb_code_md5()`. It
     cannot be otherwise as written: `tb_code_md5()` is defined in the lib and calls
     `wet:::wet_md5_text()`. Three comments and the progress note say "before the code is loaded".
   - The window that is left: a hashed file saved while `load_all()` and the two `source()` calls
     run. Shown in a worktree copy: after the load, a redefinition appended to
     `R/wet_donor_mean.R` changed `tb_code_md5()`, the loaded function was still the old one, and
     `tb_code_same(code)` passed. The report would name code that did not run.
   - The recovery's workers load `R/` and the lib again at `:181`, after part 1, and parse
     `scripts/temp_fill_validate.R` inside each worker. `tb_code_same()` at `:242` sees a change
     only if it is still on disk then: a branch switch and back, or a stash and pop, during
     part 1 gives part 2 other code under the same md5.
   - To close both: hash the files with `tools::md5sum()` before `load_all()` and compare with
     `tb_code_md5()` after it; have each worker return `tb_code_md5()` after its own load and stop
     unless all equal `code`. Or keep the code and say "right after it is loaded".
   - **Rule:** code-check.md "A guard that fails toward pass"
   - INSIDE round 1 fix 2.

3. **[severity: fragile]** `scripts/temp_baseline_recover.R:242-248` with
   `scripts/temp_baseline_lib.R:281-283` and `scripts/temp_baseline.R:88-105` — a recovery run that
   fails now leaves the last passing report in place, and the scoring guard cannot tell.
   - Before round 1 a failing run wrote the report with its FAIL line and then stopped, so the
     tracked file was modified and `scripts/temp_baseline.R` refused twice over (not committed as
     it stands; no PASS line). Now a failing run writes nothing. The committed report still says
     PASS and still names the frame and `tb_code_md5()`.
   - With the frame and the hashed files unchanged the run is seeded, so it fails only when
     something unhashed moved, and the one such file that decides the check is
     `scripts/temp_baseline_recover.R` itself (`n_sim`, `seed`, `share`, `z_max`, both arms). It is
     not in `tb_code_files` (in the worktree copy an edit to it left `tb_code_md5()` unchanged).
     So: edit the recovery, it fails, "no report written", and `scripts/temp_baseline.R` scores on
     the stale PASS. `CLAUDE.md:60`, "Any change to a file `tb_code_md5()` names stales the
     recovery report", is true and does not reach this.
   - Either write the failing report before stopping, as before (the guard's `PASS` grep at
     `scripts/temp_baseline.R:105` is otherwise unreachable), or name
     `scripts/temp_baseline_recover.R` in `tb_code_files`, which also pins round 1's 1,600 sets
     and must-fire arm to the report the scorer accepts.
   - **Rule:** code-check.md "A guard that fails toward pass" ; code-check.md "A guard's scope, escape hatches, and remedies"
   - INSIDE round 1 fix 1 (the "or no report is written" half), touching fix 3's file list.

4. **[severity: fragile]** `research/station_temperature_fill.md:131` — "The nearest-stations mean
   is biased by 2 to 5 % of each parameter's spread" holds in the leak-free pool only.
   - From `data/checks/temp_baseline_recover.txt` (bias over `null`): leak-free 2.0 %, 2.8 %,
     5.0 %; blocked 1.6 %, 0.5 %, 3.8 %. The sentences either side of it are true of both pools
     (the population mean's is under 1 % in both, at most 0.9 %; coverage 89.6 to 90.2 % is over
     all 18 rows), and only the regression's clause is marked "leak-free". Over both pools the
     range is 0.5 to 5 %; or mark this clause leak-free too.
   - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
   - INSIDE round 1 fix 5 (the rewording of "every candidate's error is unbiased").

5. **[severity: fragile]** `research/station_temperature_fill.md:133` — "the refit returns the
   simulated parameters to within a tenth of their spread at the median station" is over a tenth
   for the intercept.
   - `temp_baseline_recover.txt`, last table: median absolute error over spread is
     0.1795 / 1.763 = 0.102 (eq0), 0.0159 / 0.195 = 0.082 (eq1), 0.0730 / 0.752 = 0.097 (rate).
     "About a tenth" is what the table says. The median is over every station of the five sets
     (1,045 values), not one station.
   - **Rule:** none
   - OUTSIDE the round 1 fixes (the sentence and its table row are unchanged by them).

## Checked, nothing to report

- `tb_statistic()` against the header of `scripts/temp_baseline.R` and the report: it pairs a
  station-year only when the observed year and every run hold a GSDD, takes each station's mean
  absolute error and then the mean over stations, which is the registered statistic and (A1).
  Recomputed from `scores_bd5db3bd6b.rds` by a separate `tapply()` (not through the function):
  97.466 / 412.806 / 293.857 / 308.238 / 414.140 / 297.978 / 319.735, `all.equal` to the stored
  summary and to the report's line; 889 pairs at 209 stations, no NA on either side. The recovery
  calls the same function with the same run set per set. The scores report changed only in its
  `code:` and version lines between the two rounds.
- `tb_code_md5()` as the tree stands is `1be90a9f…`, the value both reports and the scores rds
  name; the frame is `bd5db3bd6b` in all three.
- The must-fire arm cannot fail on a sound pool at these numbers (−7.8 to −8.5 against −3), and
  it reads blocked CV only, so no state of the leak-free pool can make it pass or fail; what it
  does not bound is finding 1.
- The removed assertion: no code, report, research file or `CLAUDE.md` line cites it.
  `planning/active/task_plan.md:150` still describes it inside Phase 3's ticked box (and `:143`
  says 200 sets), with the Validation note at `:214-216` recording its removal; a working note,
  not reported.
- Every other number in the new research section, the `research/README.md` row and the
  `CLAUDE.md` paragraph, held to the three reports as they stand: 257 / 999 / 48 (18 + 19 + 9 + 1
  + 1) / 209 / 889; 136 / 67 / 6; 135 / 74 / 32 / 96; 461 pairs at 97 stations; the score table;
  118.9 / 116.2 / 104.6 / 94.4; 196.4 / 200.5; r² 30 / 33 / 19 %; bias −118 to −122 and within 8;
  11.5 and 4.1 (11.497 and 4.120 unrounded); 408 / 278 / 102 / 97; 376 / 260 / 96 / 99; 267 / 324
  / 111 / 86; 159 (08O) to 398 (08J), and 07F and 08G the only two sub-drainages where the
  regression loses; 822 / 119 / 130; 1,600; 1.286 against 1.246; largest leak-free |z| 0.97;
  −7.8 to −8.5 and −1.5 to −3.0; 87 to 94 %. From the caches: 08LG048 reads 4.0 on all 586 days;
  07FA008's record starts 2024-09-27; 19 stations at rho ≥ 0.99, 17.8 °C against 3.1 °C;
  intercepts −2.2 to 7.5; correlation −0.49; 146 stations in both snaps, 141 accepted.
- `scripts/temp_baseline_traits.R:125`: `n_both` is counted before the `stop()` that holds the
  two snaps' `accepted` flags equal, so after it "accepted by both" and "rejected by both" are
  what the counts are; the tracked line is the `sprintf()`'s output byte for byte.
- The code-md5 test's copy-and-append arm and the `tb_statistic()` test: 20 tests, 136
  expectations, failed 0, error 0, skipped 0 (`NOT_CRAN=true`, both temp_baseline test files, in
  the worktree copy).
- `tb_code_files` against what the scripts call: `wet_fill_prepare`, `wet_a2s_run`, `wet_a2s_fit`
  (`R/wet_temp_fill.R`), `wet_donor_mean`, `wet_fwa_upstream` (`R/wet_cv_folds.R`),
  `wet_temp_gsdd` through `gsdd_year`; none of the four `R/` files calls a function defined in
  another `R/` file. `wet_md5_text` (`R/wet_climr_normals.R`) hashes and moves no score.
