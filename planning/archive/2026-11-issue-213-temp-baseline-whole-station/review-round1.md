# Code-check round 1 of #213 (branch `213-water-temperature-at-stations-with-no-re`, `git diff 60956900...HEAD`)

Reviewed 2026-11-25 (UTC). Nothing in the repo was edited, staged or committed but this file. No
script of the branch was run; two read-only probes ran in memory from the cached frame and wrote
nothing (named where a finding rests on them).

## Checklist read

- `code-check.md` (38 headings): the prose of all 14 H3 under `## Mechanisms` (table rows skipped);
  of the standalone rules, "Documentation Staleness" and "An assertion that matches an interpolated
  value cannot see the claim around it". Not read: 22 (12 standalone, 6 Security, 4 Spreadsheets
  and PDFs).
- `code-check-r.md` (132 headings), read: "`stats::aggregate()` has three separate silent
  behaviours…", "Postgres row order is never fixed unless the query fixes it…",
  "`system2(stdout = TRUE)` warns on a non-zero exit…", "Rscript reads a script as it runs…",
  "`sort()` and `order()` collate by `LC_COLLATE`…", "Numeric routines that err at their edge, and
  `round()`", "`on.exit()` at a script's top level never fires", "A database driver's value is not
  a base R type…", "Regenerated binaries churn git even when nothing changed". Not read: 123
  (checked against the index line only).
- `code-check-spatial.md` (98 headings), read: "FWA lookup area follows watershed codes, so side
  channels get the river's", "A relation between FWA watershed codes is not a place". Not read: 96.
- `code-check-shell.md` (75 headings): none read; the diff holds no shell, and its two git calls go
  through `system2()` (the R rule above).
- index, diff and changed files read from file.

## Findings

No finding moves a published number. Every figure in the new section of
`research/station_temperature_fill.md`, in the `research/README.md` row and in the `CLAUDE.md`
paragraph was held to the three tracked reports or to the cached artifacts and matches, except the
two wordings in finding 5. The rule's statistic, recomputed from `scores_bd5db3bd6b.rds`, gives
97.47 / 412.81 / 293.86 / 308.24 / 414.14 / 297.98 / 319.73; `tb_code_md5()` as the tree stands is
`b8cadd96…`, the one both reports name.

1. **[severity: fragile]** `scripts/temp_baseline_recover.R:47,51,111` (and
   `data/checks/temp_baseline_recover.txt` line 36, `research/station_temperature_fill.md:132`) —
   the leak-free check cannot tell a half-broken pool from a sound one at 200 sets, so "the
   leak-free pool removes what it claims to" rests on less than it reads.
   - Only the donor mean can show a leak at all: in blocked CV, with all 461 cross-fold pairs left
     in, the mean's and the regression's `leak_z` are noise (−1.6 to 0.8), and the donor's are
     −3.13, −2.30, −3.51. A leak-free pool that ignored `related` entirely has the same training
     sets as blocked CV, so those three are what the check would have read: it fails by 0.13 and
     0.51 standard errors on two cells, and passes on the third.
   - Planted in memory (the report's part 1 reproduced first: same 4 coefficients over |z| 2, same
     max 3.17 at seed 213): a leak-free pool that removes only the upstream neighbours gave donor
     `leak_z` −0.62, −1.66, −1.99 (seed 1) and −1.91, −2.31, −2.09 (seed 2); only the downstream
     ones, −1.04, −2.73, −2.44 and −1.94, −2.56, −2.57. Every one is inside 3, so the report would
     have printed PASS each time.
   - The pool's code is right as written (`tb_cv()` drops `related[i, ]`, the lib test proves both
     directions on a toy, and the script asserts `related` equals `up | t(up)`). What is weak is
     the tracked check and the sentence drawn from it. `leak_z` grows with the square root of the
     number of sets: about 800 sets would put the full leak near −6 and a one-direction leak past
     −3; or print a must-fire arm (the donor's blocked `leak_z` under −3 in every component)
     beside the must-not-fire one.
   - **Rule:** code-check.md "A fixture that cannot reach the failure mode" ; code-check.md "Restore the bug and prove the guard fires"

2. **[severity: fragile]** `scripts/temp_baseline_recover.R:215` (and
   `scripts/temp_baseline.R:216,222`) — the code md5 the report names is read when the report is
   written, about 10 minutes after the code it describes was loaded.
   - The recovery sources the lib and loads `R/` at line 43–44, its workers load both again at
     line 179–180 (after part 1), `gsdd_year` is parsed from `scripts/temp_fill_validate.R` inside
     each worker at line 139, and `tb_code_md5()` is first called at line 215. A hashed file saved
     at any point in the run puts an md5 in the report for code that did not make part 1 (or
     either part), and `scripts/temp_baseline.R`'s guard then accepts that code as recovered.
   - `scripts/temp_baseline.R` compares at line 100 and reads the md5 again for the scores rds
     and the report line; the same window, 4 minutes wide.
   - Capture the md5 once, right after `source()`, write that value, and stop if a second read
     before the write differs.
   - **Rule:** code-check.md "A guard that fails toward pass"

3. **[severity: fragile]** `scripts/temp_baseline_lib.R:256-257` (claimed at `CLAUDE.md:58`, in the
   lib's comment above it, and by the test title at
   `tests/testthat/test-temp_baseline_lib.R:206`) — "one md5 over every file a score depends on"
   does not cover the file that computes the score.
   - `tb_code_files` names the lib, the rule, `scripts/temp_fill_validate.R` and four `R/` files.
     `scripts/temp_baseline.R` is not among them, and it holds the rule's statistic: which
     station-years are paired (`paired`), the per-station mean, the summary handed to
     `tb_verdict()`. A change there moves a score and leaves the recovery report current.
   - The recovery never runs that code: `scripts/temp_baseline_recover.R:188-199` carries its own
     copy of the pairing and the per-station mean. The two agree today; nothing holds them
     together, and #223 is the next change to this path.
   - Move the statistic (pairing, per-station mean, the `scores` frame) into the lib so both
     scripts call one function and the md5 covers it, or name `scripts/temp_baseline.R` in
     `tb_code_files` and narrow the sentence. The test at line 206 asserts only that the listed
     files exist, so its title is the same claim unexecuted.
   - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" ; code-check.md "A fix lands in one of two callers that share a harness"

4. **[severity: fragile]** `scripts/temp_baseline_recover.R:151-153` (report's last line, "no error
   at any station-year (asserted)") — the assertion compares a series with itself and cannot fail.
   - `clean$y <- s0`, then `tb_score(clean, s0, …)`: the error is `s0 - s0`, so `rmse == 0` and
     `bias == 0` hold whatever `tb_run()`, `tb_theta_inv()` or `wet_a2s_run()` do. The third arm
     calls `gsdd_year(clean$date, s0, y)` twice, once inside `tb_score()` and once inside
     `tb_gsdd_observed()` (every day of `clean` is observed), so it is `identical()` by
     construction.
   - The plan lists this as the proof that "scores are the model's". It proves that two functions
     make the same call. A check that could fire would score a run rebuilt from the simulated
     theta against a series made by another route, or drop the report line.
   - **Rule:** code-check.md "Restore the bug and prove the guard fires" ; code-check.md "Verification that reads its own output"

5. **[severity: fragile]** `research/station_temperature_fill.md:131` and `:103` — two wordings the
   report and the code do not carry.
   - Line 131, "Every candidate's error is unbiased". `data/checks/temp_baseline_recover.txt`
     shows it for the regression alone (bias within 2.2 of its `bias_se` in all six rows). The
     donor mean's leak-free bias is −0.034, −0.0062 and −0.036 against `bias_se` 0.0039, 0.00048
     and 0.0018: 9, 13 and 20 standard errors from zero, and 1.9 %, 3.2 % and 4.7 % of theta's
     spread. The population mean's is tiny (under 1 % of the spread) and 57 standard errors out
     in blocked CV, because unequal folds make it a constant. "Bias under 5 % of theta's spread;
     none for the regression" is what the table says.
   - Line 103, "the mean of the 5 nearest stations in trait space": `wet_donor_mean()` is the
     inverse-distance mean of those five (`R/wet_donor_mean.R`), not their mean.
   - **Rule:** none

6. **[severity: fragile]** `scripts/temp_baseline_traits.R:120-122,297` (tracked line
   "already snapped by the water balance (stations_20260717.rds), every one on the same segment:
   146") — the segment was compared for 141 of the 146.
   - `same` holds the segment and watershed ids equal only where the new snap is accepted; for a
     station not accepted on both sides it compares the `accepted` flag alone. Five of the 146 are
     such (08HA016, 08HA068, 08MA003, 08MH029, 08NM242, measured from the cached
     `stations_20260717.rds` against the frame's dropped list). All five are dropped stations, so
     no score reads them; the tracked sentence is wider than its guard. Compare the ids wherever
     both sides hold one, or print "141 on the same segment, 5 not accepted by either".
   - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

7. **[severity: fragile]** `scripts/temp_baseline.R:223` — the report prints
   `utils::packageVersion("wet")`, so `data/checks/temp_baseline.txt` stops being byte-identical
   on a rerun at the next release.
   - Line 4 reads "wet 0.4.44, gsdd 0.3.0.9007". The merge of this branch bumps `DESCRIPTION`, and
     the first rerun after it writes "wet 0.4.45" with no score moved, against the header's
     "(byte-identical on a rerun)" at line 77. The `code:` line already names wet's scoring code;
     the gsdd version is the one a score depends on and the code md5 does not cover. The other two
     reports of the branch print no wet version.
   - **Rule:** none

8. **[severity: fragile]** `scripts/temp_baseline_rule.R:53,62` — the thresholds are compared on
   unrounded scores while the verdict is printed, and the tie is taken, at one decimal.
   - A gain of 9.96 prints "beats the population mean by 10.0 … does not displace it (needs 10 in
     both)", and a gap of 50.04 prints "50.0" beside "not close", under a rule whose point 3 says
     a difference exactly on a threshold counts. The tie between the two trait candidates is
     already taken on `round(…, tb_digits)` (line 58), so the rule holds two precisions.
   - No effect on this result (gains 94 to 119, gaps 196 and 201). It is the registered rule, so
     a change is an amendment and the owner's; noted because the next frame or #223's rerun reads
     the same function.
   - **Rule:** code-check.md "One fact derived twice"

## Checked, nothing to report

- The guard in `scripts/temp_baseline.R` (lines 88–104): an untracked, staged-only or modified
  recovery report refuses (`ls-files --error-unmatch` status read off the result, `status
  --porcelain` non-empty); another frame, another code md5, two `frame:` or `code:` lines, and a
  FAIL line each refuse. The one way through is finding 2's window.
- `tb_cv()`'s leak-free training set, `tb_net_weights()` (the script asserts no unrelated pair
  shares a draw and unit variance on the real frame), `theta_alt` (only the held-out station's
  network part differs), `tb_interval()` with a per-station `df`, the donor weights through
  `wet_donor_mean(…, diag(n), k)`, the regression against `lm` (tested).
- The statistic in `scripts/temp_baseline.R`: pairing, per-station mean, `tb_verdict()`'s inputs,
  the breakdown classes (no NA class; counts sum to 209 in each), the hidden-season context
  (one row per station-year in `validate_scores.rds`, 822 in common, the two truths `all.equal`,
  no NA).
- The frame: 18 + 19 + 9 + 2 = 48 dropped; the 18 short records hold 336 to 352 observed days and
  none is an air-gap station mislabelled; 08LG048 reads 4 on all 586 days; 07FA008's record starts
  2024-09-27; the simulation's quoted scale (19 stations at rho ≥ 0.99, 17.8 °C, 3.1 °C,
  intercepts −2.2 to 7.5, correlation −0.49) reproduces from `fr$fit`.
- `lk_table`'s `sum(ST_Area(geom))` has no fixed order and its `%.0f` goes into the lake cache
  key, as `scripts/wb_small_basin.R`'s glacier key does; a last-bits difference could move the key
  only across a half-metre boundary of a 22,479 km² total. Not reported.
- Tests: `data/logs/213/tests_20261125T194853Z.log` ends "failed 0 error 0 skipped 5 passed 3647".
