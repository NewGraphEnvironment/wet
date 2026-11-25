# Code-check round 4 of the temperature baseline (#213)

Reviewed at e9929bcd, 2026-11-25 21:46-21:58 UTC. Scope: round 3's six fixes and its new test.
Nothing in the repo under review was edited, staged or committed; probes ran in a detached
worktree and a clone under the session scratchpad, both removed afterwards. No run of
`scripts/temp_baseline_traits.R` or `scripts/temp_baseline_recover.R`.

## Checklist read

- `code-check.md`: the prose of all 14 H3 sections under `## Mechanisms` (table rows skipped);
  under the other H2s, "Documentation Staleness" and "An assertion that matches an interpolated
  value cannot see the claim around it" in full. Not read beyond the index line: 12 other
  headings under "Rules that stand alone", 6 under "Security", 4 under "Spreadsheets and PDFs".
- `code-check-r.md`, read in full: "`system2(stdout = TRUE)` warns on a non-zero exit instead of
  raising, so a `tryCatch(error =)` around it never fires"; "Never name a durable artifact by a
  hash the library reserves the right to change"; "`deparse(body(f))` excludes formal defaults,
  so a body scan cannot see a default"; "`identical()` on two reader results tests the reader,
  not the file"; "`stats::aggregate()` has three separate silent behaviours, and each fails in a
  different direction"; "A `pkg::` call in a test passes `devtools::test()` and fails
  `R CMD check` if `pkg` is undeclared". Read in part (opening and rule, evidence cut):
  "`paste()` with a zero-length argument returns length ONE, not zero"; "`sort()` and `order()`
  collate by `LC_COLLATE`, so a canonical form is locale-dependent"; "Tests that silently do not
  run"; "Rscript reads a script as it runs, so never edit a script while a run of it is in
  flight"; "`expect_false(identical(x, y))` cannot fail when the two are different types";
  "`on.exit()` at a script's top level never fires"; "Regenerated binaries churn git even when
  nothing changed"; "`identical(-0, 0)` is TRUE in R, and the two still digest differently";
  "Under `R CMD check`, tests run from a temp dir against the INSTALLED package"; "A
  `skip_if_not()` skips only its own `test_that()` block"; "`normalizePath()` renames through a
  symlink and returns a missing path as it was"; "`tempfile()` lives in the session tempdir, so
  a path printed in an error names a file R is about to delete"; "A `function(...)` mock hides
  arguments the real callee no longer accepts". Not read beyond the index line: the other 113
  headings.
- `code-check-shell.md`: "Git plumbing calls whose default answers a different question" in
  full. Not read beyond the index line: the other 74 headings.
- `code-check-spatial.md`: none read beyond the index lines (98 headings); the diff under
  review in this round uses no terra, sf, bcdata or GDAL call.
- index, diff and changed files read from file (the four scripts, the lib test, the three
  reports and the research section were read from the checkout at e9929bcd; the round 3 fixes
  from `/tmp/codecheck.t2QUAT/round3_fixes.diff`).

## The seven rows

| # | Round 3 fix | What the token now claims | The list it is computed from | A state where the defect is present and the guard passes? |
|---|---|---|---|---|
| 1 | `tb_frame_key()` is the one key; `tb_frame_read()` recomputes it | `frame: 1c62e46b83` = "what a score or the recovery reads from the frame" (lib comment, line 31) | stations' `station_number, fold, lake, regulated, area_km2` + 8 traits; fit's 7 columns; truth `station_number year`; `which(related)` (lib lines 45-47) | **Yes: Finding 1.** The recovery also reads `wscode` and `localcode` (`tb_upstream(st)`, recover line 74), which the key leaves out. The scorer reads nothing unkeyed. Key is stable across `saveRDS`/`readRDS` and across integer/double (`n_obs`, `year`) and character/factor (`fold`, `regulated`): all gave 1c62e46b83. The test covers 2 of 7 fit columns and 1 of 8 traits: Finding 3. |
| 2 | The recovery removes its tracked report after `tb_code_load()` and writes one only when it finishes | A report at HEAD saying PASS twice = the last recovery on this code and frame finished and passed | `unlink(f_report)` at recover line 58; `writeLines()` at line 276 | No. A stop in the three statements before the `unlink()` (`md5sum`, `source(lib)`, `tb_code_load()`) leaves the earlier report, so the header's "a run that stops anywhere" is loose, but that report names the earlier code md5 and the scorer's code check judges it; nothing was simulated. `unlink()`'s return is not read; it fails only where the final write would too. Rerun identity: the report's lines other than `frame:` and `code:` have one md5 at 26096074 and at e9929bcd. |
| 3 | `tb_code_load()` returns `tb_code_md5_of(pre)` | `code: e302db7b...` = the md5 of the files as loaded | `tools::md5sum(tb_code_files)` taken before `load()`, held equal to a second read after it | No, short of a file changing and changing back between the two reads. `tb_code_md5()` on the tree at e9929bcd is e302db7b1897c09b4ff74db3557c3156, the value both reports and the scores rds name. The test cannot tell this fix from the code it replaced: Finding 3. |
| 4 | `tb_committed()` compares `git hash-object -- f` with `git rev-parse --verify -q HEAD:./f` | "is HEAD's copy" | the two git calls, each NA unless exit 0, one line, 40-64 hex | No. TRUE for the recovery report from the linked worktree's root; FALSE for an absolute path, an untracked, staged-only, modified, or assume-unchanged-and-modified file, and outside a repository. Plain `hash-object` applies the clean conversion, as the checklist prescribes; the repo has no `.gitattributes` and `core.autocrlf` is unset. A failing or missing git gives FALSE. |
| 5 | "97, not 98"; "more than" | the prose figures | `data/checks/temp_baseline.txt`, `scores_1c62e46b83.rds` | No. Benchmark 97.466; the nearest-stations mean loses 11.50 and the regression 4.12 between pools. |
| 6 | Header records Amendment 2 | "no score moved ... `temp_baseline.txt` differs from its first commit only in the code and frame it names" | the header sentence, lines 12-16 | **Wording: Finding 4.** No score moved (lines 1 and 5-90 have one md5 at 767aac9f, 3bf50c66, 26096074 and e9929bcd; the rule file is unchanged since 914259d6), but three lines differ from the first commit, not two. |
| 7 | New test: every wet function the scoring path reaches lives in a file the md5 names | "the code a score depends on" is inside `tb_code_files` | `codetools::findGlobals()` from the `wet_*(` names in the four scripts and `gsdd_year`, kept where `is.function()` | **Yes: Finding 2.** Fires when a file is dropped (`R/wet_cv_folds.R` removed from the list: 1 failed, this test). Not vacuous today: 9 entries, 18 functions reached in 5 files, 0 skipped under `load_all()`; an empty `entry` fails its own `expect_true`. It does not follow a package object that is not a function. |

## Findings

- **[severity: fragile]** `scripts/temp_baseline_lib.R:45` (with `:197-201` and `scripts/temp_baseline_recover.R:74`) — the frame key leaves out `wscode` and `localcode`, which the recovery reads. `tb_upstream(st)` builds `up` from those two columns; `up` sets the simulated network part (`tb_net_weights()`, `tb_simulate()`) and the two planted pools (`up`, `t(up)`). The recovery's own assert, `identical(up | t(up), related)`, holds the pairs but not their direction. Probe on `frame_1c62e46b83.rds`, in memory: swapping `wscode` and `localcode` between 08DA005 and 08DB001 (related only to each other, 221 and 18,295 km2; 10 such pairs exist) leaves `tb_frame_key()` at 1c62e46b83, passes that assert and the shared-only-when-related assert, and moves the network weights by up to 0.707. Saved under the frame's name, that file also passes `tb_frame_read()` (the scorer reached its first data read). So a recovery report naming `frame: 1c62e46b83` is not a function of what the key covers, and the comment's "what a score or the recovery reads from it" is false for these two columns. The scorer itself reads no unkeyed field (`fr$`/`st$` reads enumerated in both scripts). Either key the two columns (the key, the frame and scores file names, the three reports and the prose that names them all move), or have the recovery take direction from keyed fields.
  - **Rule:** code-check.md "Written data outlives the fix" ; code-check.md "A guard's scope, escape hatches, and remedies"
  - INSIDE round 3 fix 1 (the frame key).

- **[severity: fragile]** `tests/testthat/test-temp_baseline_lib.R:396-397` — the derived test follows only functions (`is.function(get(x, ns))`), so a package constant a reached function reads is not held to `tb_code_files`. Planted in a clone: `wet_air_gap <- 3` moved from `R/wet_temp_fill.R` to `R/wet_climr_normals.R` (not in the list); the file's 18 tests pass, 0 failed, 0 skipped, while `wet_fill_prepare()` reads that constant on the scoring path and the code md5 would no longer see a change to it. Today the tree is covered: `wet_air_gap` is the only non-function namespace object the 18 reached functions read, and it lives in a named file; no reached function calls through `wet::`, `do.call("...")`, `match.fun` or `get()`. The test's title says "function", so it is accurate; the md5's claim ("the files whose change could move a score") is the wider one it stands for.
  - **Rule:** code-check.md "A proxy is not the property"
  - INSIDE the new test added in round 3.

- **[severity: fragile]** `tests/testthat/test-temp_baseline_lib.R:264-283` and `:305-313` — two round 3 tests stay green with their defect put back. (a) "…returns the md5 taken before": with `tb_code_load()`'s last line restored to `tb_code_md5()` (round 3's defect 3, the exact prior line), 18 tests, 0 failed. The no-op loader leaves all three reads equal, and the editing loader stops before any return, so nothing in the test separates the first read from a third. (b) "the frame's key covers the fits and the flags": with `a2`, `a3` and `rmse_open` dropped from the key's fit columns, 18 tests, 0 failed. The `changed` list moves `a1` and `rho` of the 7 fit columns and `elev` of the 8 traits; both scripts read `a2` and `a3`, and the recovery reads `rmse_open`. The shipped code is right in both places; the tests would not notice either regression. Tests are not in `tb_code_files`, so changing them stales nothing.
  - **Rule:** code-check.md "Restore the bug and prove the guard fires" ; code-check.md "A fixture that cannot reach the failure mode"
  - INSIDE round 3 fixes 3 and 1 (their tests).

- **[severity: fragile]** `scripts/temp_baseline.R:13-14` — "data/checks/temp_baseline.txt differs from its first commit only in the code and frame it names" does not hold as written. `git diff 767aac9f HEAD -- data/checks/temp_baseline.txt` changes three lines: `frame:`, `code:`, and line 4, `wet 0.4.44, gsdd 0.3.0.9007` to `gsdd 0.3.0.9007` (dropped in round 1, 3bf50c66). The claim it supports is true: every other line is byte-identical across the four commits. The file is in `tb_code_files`, so rewording it changes the code md5 and needs the recovery and the scores run again; it can ride with any rerun Finding 1 causes.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
  - INSIDE round 3 fix 6 (Amendment 2).

## Settled, no finding

- (a) Key against the scripts' reads: scorer reads `stations` (`station_number`, traits, `fold`, `lake`, `lake_cover`, `glacier`, `regulated`), `fit[a1, a2, a3]`, `truth`, `related`, `key`; all keyed. Recovery adds `area_km2`, `fit$rho`, `fit$rmse_open` (keyed) and `wscode`, `localcode` (Finding 1). Frame column types: character, double, logical (`lake`, no NA in keyed columns), integer (`n_obs`, `year`); `formatC(..., "g")` gives one text for an integer and its double.
- (b) No stop after the `unlink()` leaves a report; a FAIL verdict writes its report and then stops. The tree at e9929bcd is clean and the recovery report's body equals the previous run's.
- (c) See row 3.
- (d) See row 4. The test passes on this machine; it makes a real `git commit` in a temp repo, so a machine with `commit.gpgsign=true` and no usable key would fail it loudly, not pass it.
- (e) See row 7 and Finding 2.
- (f) The scorer, run in a clone seeded with the frame file, stopped with its own message on each of: report deleted ("is missing"); modified, uncommitted ("is not committed as it stands"); committed naming frame bd5db3bd6b ("the recovery ran on another frame"); committed naming another code ("the code a score depends on changed"); either PASS line committed as FAIL ("did not pass, or was not shown to be able to fail"); a fit value moved in the frame rds under its name ("no longer holds the frame it is named for"). With nothing altered it passed every guard and stopped at the absent water cache, before scoring.
- Prose against the reports: every figure in the new section of `research/station_temperature_fill.md` was re-derived from the three reports or the scores and frame rds (frame key 1c62e46b83 and `scores_1c62e46b83.rds`; 257/999 less 18 + 19 + 9 + 1 + 1 = 48 to 209/889; 136/67/6; 135/74; 32; 96; 461 pairs at 97 stations; the table's 16 values; 118.9/116.2, 104.6/94.4, 196.4/200.5; 30/33/19 %; 118 to 122; 11.5 and 4.1; 408 (407.53) against 278, 102 and 97; 376 (375.50) against 260, 96 and 99; 267, 324, 111, 86; 159 to 398, 344/145, 326/291; 822, 119, 130; the recovery paragraph's 1.286/1.246, 2 to 5 %, 0.5 to 4 %, 89.6 to 90.2 %, 1.0, the three z ranges, −1.5 to −3.0; 87 to 94 %; 19 stations, 17.8, 3.1, −2.2 to 7.5, −0.49). The `research/README.md` row (295 against 97, 209 stations) and `CLAUDE.md`'s paragraph (registered at 914259d6, `tb_committed()`, PASS twice, `tb_frame_key()` recomputed on every read, the report removed at the start and written at the finish) match the code and reports.
