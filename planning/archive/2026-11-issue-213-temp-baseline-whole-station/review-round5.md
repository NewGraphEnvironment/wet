# Code-check round 5 of the temperature baseline (#213)

Reviewed at 4e6b9931, 2026-11-25 22:22-22:34 UTC. Scope: round 4's four fixes only.
Nothing in the repo under review was edited, staged or committed except this file. Probes and
planted defects ran in a detached worktree under the session scratchpad (`wt-r5`, removed
afterwards; `wt-guards` was not touched), reading `data/temp_baseline/frame_229ccbefe9.rds` and
`scores_229ccbefe9.rds` from the checkout by absolute path. No script under `scripts/` was run.

## Checklist read

- `code-check.md` (38 H3): the prose of all 14 H3 sections under `## Mechanisms` (table rows
  skipped); under "Rules that stand alone", "Do not edit files a long test run is reading",
  "Documentation Staleness" and "An assertion that matches an interpolated value cannot see the
  claim around it". Not read beyond the index line: 21 headings.
- `code-check-r.md` (132 H3), 23 read (lines over 600-900 characters cut, so some evidence
  blocks are partial): "`paste()` with a zero-length argument returns length ONE, not zero";
  "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent";
  "`identical(-0, 0)` is TRUE in R, and the two still digest differently"; "Never name a durable
  artifact by a hash the library reserves the right to change"; "`unlist()` prefixes a `split()`
  group's name, so reassembling by name silently yields all-NA"; "`expect_false(identical(x, y))`
  cannot fail when the two are different types"; "`deparse(body(f))` excludes formal defaults,
  so a body scan cannot see a default"; "`deparse()` re-encodes non-ASCII, so it answers about
  itself rather than the file"; "`identical()` on two reader results tests the reader, not the
  file"; "Under `R CMD check`, tests run from a temp dir against the INSTALLED package"; "Tests
  that silently do not run"; "A `pkg::` call in a test passes `devtools::test()` and fails
  `R CMD check` if `pkg` is undeclared"; "`c(name = x)` keeps `x`'s own name, so a value from a
  named vector becomes `name.X`"; "Verify a float-formatting fix in its consumer, not through
  `as.numeric()`"; "Read-back shape must match write-back shape"; "`$` on a list
  partial-matches, so a longer sibling key answers for a missing one"; "A `function(...)` mock
  hides arguments the real callee no longer accepts"; "testthat counts an uncaught error under
  `error`, not `failed`"; "A `skip_if_not()` skips only its own `test_that()` block";
  "`expect_gt()` and friends take no `info` argument"; "`data.frame()` recycles a scalar against
  a zero-length column"; "A library call that dispatches on a global option is not a pure
  function"; "`[[` on a named ATOMIC vector with an absent key is an error, not `NULL`". Not read
  beyond the index line: 109 headings.
- `code-check-shell.md` (75 H3): "Git plumbing calls whose default answers a different question"
  and "`git diff a..b` compares TIPS; a change on `a` shows up as the branch's" (first 40 lines
  of each). Not read beyond the index line: 73 headings. Round 4's fixes add no shell.
- `code-check-spatial.md` (98 H3): "Canonicalize geometry before hashing it — ring order and
  orientation are not fixed by topology" (first 45 lines), for the hashing pattern. Not read
  beyond the index line: 97 headings. Round 4's fixes use no terra, sf, bcdata or GDAL call.
- index, diff and changed files read from file, with these limits: the index's R section in
  full and every heading of the other three sections (their lead sentences from the copy this
  session's `CLAUDE.md` carries); `round4_fixes.diff` in full; from `changed`, the three reports,
  `review-round4.md`, both research files, the recovery script from its part 2 header on and the
  rule file; `scripts/temp_baseline_lib.R` in full, `scripts/temp_baseline.R` lines 1-30 and
  76-250, `scripts/temp_baseline_traits.R` lines 225-315 and the lib test's lines 1-40 and
  225-458 from the checkout at 4e6b9931; of the branch `diff`, the `CLAUDE.md` hunk. Not read:
  the other planning files, the traits script's first 224 lines, the lib test's lines 41-224,
  the rule test.

## Items (a) to (f)

Mutation runs are `devtools::test(filter = "temp_baseline_lib")` on a patched copy, each planted
text asserted present before the run and the copy restored and checked clean after it. Baseline
at HEAD: 18 tests, 152 expectations, 0 failed, 0 errors, 0 skipped.

| Item | Question | Result | A script reads the affected content? | Finding? |
|---|---|---|---|---|
| a1 | `related`'s dimnames | Row names are not hashed but held equal to `stations$station_number` (lib line 40-41). Column names are neither: reversed or removed, the real frame keeps key 229ccbefe9. | No by name. Both scripts index `related` by position (`tb_cv()`'s `related[i, ]`); the recovery's `identical(up \| t(up), related)` (line 75) compares dimnames too and would stop. | No instance |
| a2 | Data frame row names | Not hashed (changed on `stations` and `fit`: same key). All four tables hold default row names. | No (`rownames<-` on derived objects only). | No instance |
| a3 | Factor levels | No factor column in the frame. A character column turned into a factor with reversed levels keeps the key (labels are hashed, level order is not). | n/a | No instance |
| a4 | A list or matrix column | `stations$n_years` is a 1-d integer array (from `tapply()`); `formatC()` keeps its `dim` and `paste()` takes it; a plain integer vector gives the same key. No list column. | The traits script's own report only. | No instance |
| a5 | `NA` against the string "NA" | A character `NA` and "NA" give one line (`dropped$station_name` holds one `NA`, for 07FA008; set to "NA": same key). A numeric `NA` is `"     NA"`, so it cannot meet a string. | No: `dropped` is read only by the traits script's report. | No instance |
| a6 | A value holding the separator | No character value in the frame holds a vertical bar, a newline or a leading `#` (counted per column). Planted on two adjacent character columns (`fold` "F\|x" with `nesting` "N", against "F" with "x\|N"): the two edited frames share a key. | `fold` yes, `nesting` no. | No instance |
| a7 | Two frames, one set of lines | Same key for: `truth$year` integer or double; `lake` logical or character; `provenance` as a list or a named character vector, or with a `NULL` element added; an attribute added to the frame or to `stations`; the frame's elements in another order (sorted by design). The key moves for: `year` as character (numbers are padded to width 7 by `formatC()`), 0 against -0 (`"     -0"`; none in the frame, and the same build gives the same sign), two columns swapped, an empty element added. A column named `sep` or `collapse` would be taken by `paste()` as its argument (lib line 47); the frame has none. `formatC()` follows `options(OutDec)`; the scripts do not set it, and another value moves the key, which refuses. | Types and order: no behaviour rides on them. | No instance |
| a8 | 6 significant digits on identifiers | By accepted tradeoff (iv). Measured so the reach is on record: `linear_feature_id` (double, up to 7.1e8) and `watershed_feature_id` (integer, up to 1.08e7) enter rounded, so +1 on either keeps the key, and the 209 stations' `linear_feature_id` give 204 distinct texts. `lon` + 0.0001 degrees also keeps it. | No: neither scoring script reads `linear_feature_id`, `watershed_feature_id`, `lon` or `lat`. Every field they read as an identifier (`station_number`, `wscode`, `localcode`, `fold`, `regulated`) is character and enters whole. Worth a look when #223 reads the frame's segment ids. | No instance |
| a9 | Positive controls for the probe | One `wscode` edited, one `rho` times 1.001, one `related` cell flipped, one truth year dropped, one truth year given to another station, one station renamed in every table, one dropped station renamed: the key moves each time. | | |
| b | Stability, and the reader | `tb_frame_key()` on the real file gave 229ccbefe9 in three separate `Rscript` processes (`en_US.UTF-8`, `LC_ALL=C`, `en_CA.UTF-8` with `--vanilla`), and again after `saveRDS()`/`readRDS()` (default, and version 2 uncompressed). `tb_frame_read(dir = <the checkout's data/temp_baseline>)` at HEAD accepts the file against the tracked report. No non-ASCII string in the frame. | | Clean |
| c1 | Objects not made by a top-level `<-` | None exist: `ls(asNamespace("wet"))` less the 256 top-level definitions parsed from `R/*.R` is `.__DEVTOOLS__` alone; no `assign()`, `delayedAssign()`, `R/sysdata.rda`, `.onLoad`, S3 registration (0 `S3method` lines) or package data; the two top-level non-assignments are `NULL` and `"_PACKAGE"`. | | No instance |
| c2 | Names reached by string, or by `wet::`/`wet:::` inside the package | `findGlobals()` returns only `::`/`:::` for `wet:::foo(1)`, so such a call would be invisible. None of the 18 reached functions makes one, holds a string naming a namespace object, or calls `get()`, `match.fun()`, `eval()` or `system.file()`; the two `do.call()`s are `do.call(rbind, ...)`. | | No instance |
| c3 | A constant whose value is built from another object; a function built by a factory | The walk does not follow a non-function's definition. The one reached constant is `wet_air_gap <- 3`; all 18 reached functions are `function` literals. | | No instance |
| c4 | The entry regex | It takes `wet_`-prefixed names only and drops any name not a definition. Dropped today: the four `wet_*.R` file names in `tb_code_files`, nothing in code. The two definitions without the prefix (`%\|\|%`, `cols_load`) are not used by the four scripts or by `gsdd_year`. The scripts source or take from no file outside `tb_code_files`. Reached today: 19 objects, every one but `wet_md5_text` in a named file; `wet_md5_text()` reads no package object. | | No instance |
| d1 | Planted: the fit's columns listed by hand, a column dropped | The exact prior `tb_frame_key()` (from e9929bcd): 10 failed, 1 error, all in the frame-key test, the first four labelled `stations wscode`, `stations localcode`, `stations lon`, `dropped reason`. HEAD's function with `fit` cut to a hand list without `rho`: 1 failed, labelled `fit rho`. | | Fires |
| d2 | Planted: `wet_air_gap <- 3` moved to `R/wet_station_list.R` | 1 failed, in the derived test, its info reading `wet_air_gap wet_station_list.R`. | | Fires |
| d3 | Planted: `tb_code_load()` ends with `tb_code_md5()` | 1 error, in the load test, with the stub's message "a read of the files after the load". A last line spelled `tb_code_md5_of(tools::md5sum(tb_code_files))` stays green (152 passed): the stub covers one function, not "every later read" as the comment at test line 278 says. That spelling differs from HEAD only if a file changes after the second read, which no test input reaches, and it is not in the tree. | | Fires; wording only |
| d4 | Not asked, found on the way: `station_number` left out of the key | 152 passed, 0 failed, for the truth table alone and for every table. | Yes | **Finding 1** |
| e | Amendment 2 against git | `git diff 914259d6 HEAD -- scripts/temp_baseline_rule.R` is empty. `git diff 767aac9f HEAD -- data/checks/temp_baseline.txt` is one hunk of three lines: `frame:`, `code:`, and `wet 0.4.44, gsdd 0.3.0.9007` to `gsdd 0.3.0.9007`. The header (lines 12-17) names the frame, the code and "no longer printing wet's version". 767aac9f is the report's first commit and an ancestor of HEAD. | | Clean |
| f | Keys in prose, reports and files | `research/station_temperature_fill.md` names frame `229ccbefe9` (line 87) and `scores_229ccbefe9.rds` (line 141); `CLAUDE.md` names `frame_<key>.rds` and `scores_<key>.rds` only. The three reports name frame 229ccbefe9; the recovery and scores reports name code d7285e9d875ad8213d6e45802e963544, which is `tb_code_md5()` on the tree at HEAD; the recovery report says PASS twice and the tree is clean. On disk: `frame_229ccbefe9.rds` (its `key` and recomputed key both 229ccbefe9) and `scores_229ccbefe9.rds` (`frame` 229ccbefe9, `code` d7285e9d..., benchmark 97.4663, 6223 scores, 889 paired, the report's seven `gsdd_mae` values). No tracked file outside `planning/` names 1c62e46b83, bd5db3bd6b or either earlier code md5, and neither issue body (#213, #223) names a key. | | Clean |

## Findings

- **[severity: fragile]** `tests/testthat/test-temp_baseline_lib.R:309-321` (the exclusion is line 314) — the test's "every column of every table, walked rather than listed" leaves `station_number` out of all four tables by a hand-written `setdiff()`, and nothing else in the file moves a station number. Planted in a copy: `tb_frame_key()` with `station_number` dropped from the truth table, and again from every table; both runs pass 152 of 152. Under the first, the real frame and the real frame with one truth year given to another station share a key (60cc2ca1ee both), and the scorer reads exactly that (`split(fr$truth$year, factor(fr$truth$station_number, ...))`, `scripts/temp_baseline.R:138`, `scripts/temp_baseline_recover.R:164`); under the second the key no longer says which stations the frame holds, which is what selects the water and air series. The shipped key is right: at HEAD the same edit moves 229ccbefe9 to d4d2623b32, and a station renamed in every table moves it too. So no state in the tree is wrong; the test would not notice this column going missing from the key, and it is the column both scripts read most. The exclusion is needed only in `stations` and `fit`, where a lone edit stops with "not in one order"; `truth` and `dropped` can be walked whole, and one station renamed across `stations`, `fit`, `related`'s dimnames and `truth` covers the other two. Tests are not in `tb_code_files`, so the change stales no report.
  - **Rule:** code-check.md "Restore the bug and prove the guard fires" ; code-check.md "A guard's scope, escape hatches, and remedies"
  - INSIDE round 4 fix 3 (the frame-key test).

## Settled, no finding

- Fix 1 (`tb_frame_key()`): reads every element but `key`, with its name, and every column with its name. A table cut to zero rows still gives a key (aa1114d7b0 with `dropped` emptied), and another one with the table removed (25eaaa6add). What it does not read (rows a1 to a8) has no reader on the scoring path. The key is the one the reports, the file names and the scores file carry.
- Fix 2 (the derived test): cannot pass today with a reached object outside `tb_code_files`; every route by which it could (rows c1 to c4) has no instance in the tree. Its own positive control (`wet_air_gap` reached) and the planted move both hold.
- Fix 3 (the load test): fires on the restoration it was written for.
- Fix 4 (Amendment 2): matches both diffs.
- The file's tests all skip under `R CMD check` (no `scripts/` beside an installed package); that is stated at the top of the test file and predates round 4.
