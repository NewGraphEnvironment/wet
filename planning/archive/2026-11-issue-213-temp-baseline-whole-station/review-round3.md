# Code-check round 3 of #213 (branch `213-water-temperature-at-stations-with-no-re`, `git diff 60956900...HEAD`, HEAD 26096074)

Reviewed 2026-11-25 (21:14Z at the last probe). Nothing in the repo was edited, staged or committed
but this file. No script of the branch was run. Five in-memory probes ran in a detached worktree
copy under the session scratchpad (`git worktree add --detach`, removed afterwards; `git status`
of the repo empty before and after) and one in a throwaway `git init` directory; they read the
cached frame and scores by absolute path and wrote only to `tempdir()` and to the copy's own
files. Line numbers are the files' at HEAD 26096074.

## Checklist read

- `code-check.md` (38 headings): the prose of all 14 H3 under `## Mechanisms` (table rows
  skipped); of the standalone rules, "Documentation Staleness" and "An assertion that matches an
  interpolated value cannot see the claim around it". Not read beyond the index line: 22.
- `code-check-r.md` (132 headings), read in full: "Rscript reads a script as it runs, so never
  edit a script while a run of it is in flight", "`system2(stdout = TRUE)` warns on a non-zero
  exit instead of raising, so a `tryCatch(error =)` around it never fires", "`stats::aggregate()`
  has three separate silent behaviours, and each fails in a different direction", "`sort()` and
  `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent", "A `data-raw/`
  script must load the source tree, not the installed package", "`clusterApply()` returns `NULL`
  for no tasks, not an empty list", "`identical()` on two reader results tests the reader, not the
  file", "Numeric routines that err at their edge, and `round()`". Read in part (the rule and its
  first evidence): "Postgres row order is never fixed unless the query fixes it…", "A database
  driver's value is not a base R type…", "Never name a durable artifact by a hash the library
  reserves the right to change". Not read: 121 (index line only).
- `code-check-shell.md` (75 headings), read: "Git plumbing calls whose default answers a different
  question". Not read: 74 (the diff holds no shell; its two git calls go through `system2()`).
- `code-check-spatial.md` (98 headings): none read this round; the round 2 fixes touch no spatial
  code, and round 1 read the two FWA rules against the traits script. Not read: 98.
- index, diff and changed files read from file.

## The mechanism

**A short token stands for a sentence with "every" or "as it stands" in it, and the token is
computed from a list somebody wrote by hand, in another place from the sentence.** Each guard on
this branch accepts a token (a 10-hex frame key, a 32-hex code md5, a line ending `: PASS`,
"committed") as proof of a property of everything a run reads or every way it can end. The token
covers the members its author had in mind when writing it. Rounds 1 and 2 each found a member the
list lacked (the scoring script, the recovery script, the workers' load, a half-broken pool, a
failing run), and each fix added that member to the list. The list is still written by hand, so
the next missing member waits for the next reader. Three pairs of lists have to agree and nothing
derives one from the other:

| the sentence quantifies over | the token is computed from | derived, or by hand |
|---|---|---|
| everything a score or the recovery reads | `tb_code_files` (code) and `canon` (frame) | by hand, both |
| every way a recovery run can end | the two `PASS`/`FAIL` lines | by hand: the two verdicts write, ten other stops do not |
| the population a prose sentence names | the rows the report prints | by hand, per sentence |

Every place it reaches in this branch, with where it stands now:

| # | token | stands for | state at HEAD |
|---|---|---|---|
| 1 | `tb_code_files`, 9 names (`temp_baseline_lib.R:284-286`) | "the code a score depends on" | complete today: a `codetools` walk from the seven `wet:::` entry points reaches 11 package objects, all in the four hashed `R/` files except `wet_md5_text` (its change moves the md5 itself, so it fails safe). Nothing tests that walk, so the list stays by hand. Not named by any token: the gsdd package (printed in the scores report only) and R itself |
| 2 | `canon` → the frame key (`temp_baseline_traits.R:261-264`) | "what a score depends on", "the frame as it stands" | **finding 1**: 4 of the 6 things a score reads |
| 3 | the two `PASS` lines (`temp_baseline.R:105`) | "the recovery passed"; "a failing run writes a failing report" | **finding 2**: true of the two leak verdicts, not of the run's other stops |
| 4 | `pre`/post hashes in `tb_code_load()` (`temp_baseline_lib.R:298-309`) | "the md5 returned is of exactly what was loaded" | **finding 3**: the value returned is a third read |
| 5 | `git status --porcelain` being empty (`temp_baseline.R:94-95`) | "committed as it stands" | **finding 4** |
| 6 | the two planted pools and blocked CV (`temp_baseline_recover.R:94,130-138`) | "the check can fail, on a half-broken pool too" | holds: each direction is planted, asserted in the run (`fires`), and `n_sim` sits in a hashed file |
| 7 | `all.equal(own, fr$fit)` (`temp_baseline.R:124`) | "the fits the recovery took its scale from" | part of finding 1 |
| 8 | report line "every one on the same segment: 141" | the 146 stations in both snaps | fixed in round 1; the line now says 141 and 5 |
| 9 | prose numbers and quantifiers | the three reports | Table B: 64 rows, 5 wider (**findings 2, 5, 6**) |
| 10 | "(A1) … before any real score" (`temp_baseline.R:9-11,69-71`) | every sentence marked (A1) | **finding 6** |

The mechanical cure is the same in each row: make the reader recompute the token from what it
reads, in the function the writer used. One key function called by the frame's writer and its
reader; the md5 returned taken from the hashes already held; the recovery report removed when a
run starts, so only a finished run leaves one; the file's blob compared with HEAD's.

## Findings

No finding moves a published number. The rule's statistic, recomputed from
`scores_bd5db3bd6b.rds` both through `tb_statistic()` and by a separate `tapply()`, is 97.4663 /
412.8059 / 293.8574 / 308.2378 / 414.1402 / 297.9776 / 319.7348, `all.equal` to the stored summary
and equal to the report's lines; `tb_verdict()` on them returns the report's five lines word for
word. `tb_code_load()` in the copy returns `9b2ebd59…`, the md5 both reports and the scores file
name, in the master and in a worker. The scores report is unchanged since its first commit
(767aac9f) but for its `code:` and version lines.

1. **[severity: fragile]** `scripts/temp_baseline_traits.R:259-264` (read at
   `scripts/temp_baseline_lib.R:37-42`, `scripts/temp_baseline.R:100,123-124`,
   `scripts/temp_baseline_recover.R:77-79,160-161`) — the frame key leaves out the stations' own
   fits, and the reader never recomputes it, so "the frame as it stands" is a name, not a check.
   - The comment says "The key is of what a score depends on". A score reads six things: the
     traits, the folds, the related pairs and the truth years (in `canon`), and each station's own
     theta and its daily series (not in it). Theta is what every candidate is trained on and
     tested against. The frame carries it as `fit`; `canon` does not, nor `area_km2` beyond
     `log_area` at 6 digits, `lake` or `regulated` (the report's breakdown classes).
   - `tb_frame_read()` compares the `key` field stored in the rds with the report's line and
     nothing else. Probe: a copy of the frame with `fit$a1` times 1.5, `rho` set to 0.5,
     `area_km2` reversed, `lake` negated and `regulated` overwritten was accepted as
     `bd5db3bd6b`; so was one with `elev` raised 100 m, a keyed column.
   - The file is rewritten in place under one key: `frame_bd5db3bd6b.rds` is dated 13:04 local
     time today, an hour after the frame report's commit (226ca962, 12:04), which is when round 1
     changed the traits script.
   - The state the guards pass: the water or air cache is read again later (water-temp-bc revises
     provisional values; the cache file is named for 2002–2025, not for the day it was read) with
     the same station-years complete, and `temp_baseline_traits.R` is rerun. Same key, other
     fits. The committed recovery report still names that key and that code, so
     `scripts/temp_baseline.R` scores: line 124 passes because both sides are the new fits, and
     its comment, "the fits the recovery took its scale from", is then false. The scores report
     changes with its `frame:` and `code:` lines unchanged, and `scores_<key>.rds`, which #223 is
     scored against, is replaced under the same name.
   - Two ways to close it. (a) Put `fit` (a1, a2, a3 to 6 significant digits) in `canon`, move
     `canon` into the lib as one function, and have `tb_frame_read()` recompute it. That changes
     the key's recipe, a stored identifier, so it is the owner's call. (b) Leave the key; print a
     `fits:` digest in the frame and recovery reports and have the scorer hold its own fits to
     the recovery's line.
   - **Rule:** code-check.md "Written data outlives the fix" ; code-check.md "A proxy is not the property"
   - OUTSIDE the round 2 fixes.

2. **[severity: fragile]** `scripts/temp_baseline_recover.R:270-276` (claimed at `CLAUDE.md:58`,
   "A failing run writes a failing report", and in the comment at `:270`, "so nothing scores on a
   stale PASS") — a run writes its failing report for the two leak verdicts only; every other
   stop leaves the last report standing.
   - Two ends write the report: both verdicts PASS, or either FAIL (`:271` then `:273`). Ten
     guards stop above the write: `tb_code_load()` (`:53`), `tb_frame_read()` (`:62`), the
     topology checks (`:70`, `:74`), the row-order check (`:137`), the exact-regression check
     (`:148`, which the header names as a "must"), a station with no series (`:158`), `rho` or
     `sigma` out of range (`:162`), a worker on other code (`:207`), `tb_code_same()` (`:269`).
     So does any error inside part 2's workers. After each, the committed report still says PASS
     twice.
   - Since round 2 the md5 names the recovery script, so with the code and the frame key
     unchanged a seeded run stops only if something neither names has moved. That is finding 1's
     list: the frame's `fit` (`:160-162` read `rho` and `rmse_open` from it), the water and air
     caches (`:157-158`), or an installed package. (The two code checks, `:207` and `:269`, stop
     on a file that moved: if it stays moved the scorer refuses the old report, and if it went
     back the old report is still true.) So the exposure is narrow, and it is the same hole seen
     from the other script.
   - To make the sentence true of every end: remove the report (or write a "did not finish"
     one) right after `tb_code_load()`, so only a run that reaches line 271 leaves a report. Or
     narrow the two sentences to "a run whose leak check fails".
   - **Rule:** code-check.md "A guard that fails toward pass"
   - INSIDE the round 2 fix "a failing recovery writes its failing report".

3. **[severity: fragile]** `scripts/temp_baseline_lib.R:306-309` (claimed at `:292-296`, "return
   the md5 of exactly what was loaded … so the md5 returned is of the code in memory") — the md5
   returned is a third read of the files, taken after the check that they held still.
   - Line 306 compares the hashes taken before the load with a second set; line 309 then calls
     `tb_code_md5()`, which reads every file again. A file saved between the two is hashed into
     the value returned though it was not loaded, and `tb_code_same()` at the end agrees with it.
     Probe in the copy, with one line appended to `scripts/temp_fill_validate.R` at that point:
     loaded `9b2ebd59…`, returned `4ba25f86…`. The window is two adjacent statements, so this is
     about the claim, not a likely event; round 2 found the same shape at a wider window.
   - Take the value from `pre`: `wet:::wet_md5_text(paste(tb_code_files, unname(pre)))`, the
     expression `tb_code_md5()` uses. Then nothing is read after the comparison.
   - The guard at `:307` does fire: with a hashed file changed during the load, the copy stopped
     with "a file tb_code_md5() names changed while it was being loaded". No test in the suite
     reaches `:307` or `tb_code_same()` (`:313`); the two tests of `tb_code_load()` stop at
     `:299` and `:301`.
   - **Rule:** code-check.md "A guard that fails toward pass"
   - INSIDE the round 2 fix `tb_code_load()`.

4. **[severity: fragile]** `scripts/temp_baseline.R:94-95` — "committed as it stands" is read
   from `git status --porcelain` being empty, which is also what a failed `git status` and a
   hidden path return.
   - Line 92 reads `attr(tracked, "status")`; line 94 does not read `attr(dirty, "status")`. A
     `git status` that exits non-zero prints nothing on stdout, so `length(dirty)` is 0 and the
     guard passes with a warning. (The return was measured outside a repo: length 0, status 128.
     There line 92 refuses first, so the state that passes is `git ls-files` working and
     `git status` failing, which is rare.)
   - `git status` skips a path whose index entry is flagged `--assume-unchanged` or
     `--skip-worktree`. In a throwaway repo, a committed report saying FAIL twice, flagged and
     then edited to say PASS twice, passed this guard and both `PASS` greps.
   - Both need an unusual state, and one comparison closes both: `git hash-object -- <f>`
     against `git rev-parse --verify -q HEAD:<f>`, refusing when either call fails.
   - **Rule:** code-check-r.md "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires" ; code-check-shell.md "Git plumbing calls whose default answers a different question"
   - OUTSIDE the round 2 fixes.

5. **[severity: fragile]** `research/station_temperature_fill.md:89` and `:122`,
   `research/README.md:14` — two wordings the report does not carry.
   - Lines 89 and README 14, "the miss is 98" and "against 98 with the station's own". The
     statistic is 97.4663, which the report prints as 97.5 (`data/checks/temp_baseline.txt:11`)
     and the table at line 111 gives as 97.5. 98 is the printed value rounded again; to the
     whole number it is 97. Every other whole number in the section rounds from the unrounded
     value (checked: 413, 408, 278, 376 from 375.503, 260, 267, 324, 119, 130 and the rest).
   - Line 122, "Neighbours on the same stream help the nearest-stations mean, not the
     regression". The next sentence gives the regression's cost as 4.1 °C-days (4.120), against
     11.5 for the nearest-stations mean, and the recovery shows the regression using its
     neighbours faintly (z −1.5 to −3.0, line 132). "About three times as much as the
     regression" is what the two numbers say.
   - **Rule:** none
   - OUTSIDE the round 2 fixes (both sentences predate them).

6. **[severity: fragile]** `scripts/temp_baseline.R:9-11` with `:69-71` (restated at
   `CLAUDE.md:56`, "Amendment 1, also before any score") — a sentence marked (A1), "before any
   real score", was reworded after the scores, and what it points at changed twice.
   - The header lists "the code the recovery guard names" among Amendment 1's items, "each
     marked (A1) below", all before any real score. Amendment 1 landed in 226ca962, before the
     scores (767aac9f). The (A1) sentence at lines 69-71 was reworded in f2eeeec5 ("as it
     stands (`tb_code_md5()`" became "as this run loaded it (`tb_code_load()`"). The code under
     it changed in both review commits: the md5 gained the scoring script in 3fc3208e and the
     recovery script in f2eeeec5, and the guard now needs both PASS lines.
   - Nothing the verdict reads moved: `scripts/temp_baseline_rule.R` is byte-identical to its
     registration (`git diff 914259d6 HEAD` is empty) and the scores are unchanged. This is the
     header's own record, and the owner's other registered rules name each amendment's commit.
     One line would keep it exact: "Amendment 2 (code-check, after the scores; no score moved):
     how the recovery guard takes the code md5, and that it needs both PASS lines."
   - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
   - INSIDE the round 2 fix `tb_code_load()` (its edit to the header), and round 1's change to
     `tb_code_files`.

## The round 2 fixes: the questions asked

- **Can code be loaded that differs from the md5 returned?** Three ways, none of which moved
  anything here. (i) The third read, finding 3. (ii) `devtools::load_all()` loads all of `R/`,
  four files of which are hashed; the walk above shows a score reaches nothing outside them but
  `wet_md5_text`. It also runs the testthat helpers and attaches the package; no name of the lib,
  the rule or `gsdd_year` collides with either script's globals or with what the recovery exports
  to its workers. (iii) The running script is hashed by name, not by what R is executing. Run as
  documented they are one file. Run from a frozen copy, as code-check-r.md prescribes for a long
  run, the md5 names the repo's file; an edit to it during the run is caught by
  `tb_code_same()`, a copy made before an earlier edit is not. This is the accepted family (I
  cannot show a score moving), so it is a table row, not a finding.
- **`sys.source()` into `parent.frame()` from inside `clusterEvalQ`.** On a worker
  `parent.frame()` is the global environment. Probe: after the worker block, `gsdd_year` and
  `tb_verdict` both exist in the worker's global environment, the worker's `wet` namespace is the
  source tree's, and its md5 equals the master's.
- **Is `gsdd_year` found?** Yes in both. In the master `tb_take()` evaluates it into the global
  environment, where the scoring loop reads it. `e2e_one`'s enclosure is the global environment,
  which serialises by reference, so on a worker its free names resolve in the worker's own
  globals: the worker's lib, the worker's `gsdd_year`, the exported data. `gsdd_year`'s one free
  name is `wet_temp_gsdd`, found through the attached package.
- **Do the planted pools remove what their names say?** Yes. `up[i, j]` is "j is upstream of i",
  and the pool drops `related[i, ]` from station i's training set. With `up`, station i loses the
  stations upstream of it; with `t(up)`, whose `[i, j]` is `up[j, i]`, it loses those downstream.
  On the frame each drops 461 directed cross-fold pairs: 27 stations have a cross-fold upstream
  neighbour and 82 a downstream one; no pair is related both ways.
- **Can the two PASS greps match a FAIL report?** No. Each anchors a line's start and its end on
  `: PASS`, `rec` is one element per line, and the two lines are the only ones with those
  openings. A failing run's report is also uncommitted until someone commits it, and line 96
  refuses that first (subject to finding 4).
- **Do `tb_statistic()` and the report agree?** Yes, to every printed digit; see the head of the
  findings.

## Table A: every guard in the five scripts

88 rows. 73 cover the 70 `stop()` and `stopifnot()` calls of the five scripts (a few sharing a
row), the scripts' calls into the lib's guards, the two computed verdicts and three header
claims with no assertion; 15 are refusals described in prose. 11 rows are marked in bold as
passing with the defect or wider than the code, all inside findings 1 to 4 and 6.

"Passes with the defect?" asks whether a state exists in which the thing the guard claims to
exclude is present and the guard does not fire.

### `scripts/temp_baseline_rule.R` (byte-identical to its registration)

| line | claims | fires when | passes with the defect? |
|---|---|---|---|
| 28 | scores is a data frame with candidate, pool, gsdd_mae | not a data frame, a column missing | no |
| 31 | the benchmark is one finite score, not negative | length not 1, NA, Inf, negative | no |
| 34 | scores has rows, each keyed | 0 rows, NA candidate or pool | no |
| 36 | every pool is blocked or leakfree | another label | no |
| 37 | one score per candidate and pool | a repeated pair | no |
| 39 | every score finite, not negative | NA, Inf, negative | no |
| 46 | mean, regression, donor in both pools | one absent or NA | no |
| 48 | any other candidate in both pools | a later candidate in one pool | no |
| 53, 62 | 10 displaces, 50 is close | unrounded comparison | accepted tradeoff, not re-examined |

### `scripts/temp_baseline_lib.R`

| line | claims | fires when | passes with the defect? |
|---|---|---|---|
| 21 | the name is assigned exactly once at the script's top level | 0 or 2+ top-level `<-` or `=` to the bare name | narrowly: a second definition by `assign()`, `->`, `<<-` or inside a top-level `if` is not counted. None exists in the three scripts read (each of the 8 names taken is assigned once). Matches the claim as worded |
| 35 | the frame report exists | absent | no |
| 38 | it names one 10-hex key | 0 or 2 `frame:` lines, another shape | no |
| 40 | the frame file exists | absent | no |
| 42 | the file holds the frame the report names | the stored `key` field differs | **yes: content is never rehashed (finding 1)** |
| 52, 55 | par has a1, a2, a3; finite; a3 in (0, 1) | else | no |
| 63 | theta's columns, in order | else | no |
| 89, 91 | x, th, x_new line up and are finite | else | no |
| 95, 107, 121 | enough training stations for each candidate | n < 2; n ≤ p; k < 2 | no (a singular design errors in `solve()`, an abort) |
| 153, 155 | x, th, fold, related line up; complete; logical | else | no |
| 164 | a held-out station is not in its own training set | `tr[te]` TRUE | cannot fire as the two pools are built: `te` and `tr` both come from `fold` two lines up. Fires only if the fold term is dropped from `parts`. No claim rests on it |
| 202 | the simulation's inputs line up | else | no |
| 233, 237 | the series is on the calendar; a season has an observed day | else | no |
| 262, 263 | scores have their columns, rows and keys | else | no |
| 266 | every station-year has each run once | missing, repeated or unknown run | no (tested three ways) |
| 270 | some station-year is paired | none | no |
| 289, 299 | the hashed files exist | one missing | no |
| 301 | the lib is the one hashed before `source()` | its md5 differs | no (a change made and undone between the two reads aside) |
| 307 | no hashed file moved during the load | a hash differs after | fires (probe). **The value returned is read after it (finding 3)**; code loaded but not hashed reaches a score only through `wet_md5_text`; the file run is named, not identified (accepted family) |
| 313 | no hashed file changed since the load | a change still on disk at the write | a change made and undone during the run, in the master only; accepted family |

### `scripts/temp_baseline_traits.R`

| line | claims | fires when | passes with the defect? |
|---|---|---|---|
| 54 | the water and air caches exist | either absent | no token names their content; see finding 1 |
| 65 | truth years exist, none repeated | else | no |
| 74 | every truth year's season sd is finite | a season with under 2 observed days | no |
| 93 | one HYDAT row per station | the regulation join repeats one | no |
| 116 | a station is calibration or test in the water balance, not both | else | no |
| 125 | a station the water balance snapped gets the same segment | accepted flags differ, or ids differ where accepted | for the 5 rejected by both, only the flag is compared; the report line says so since round 1 |
| 138, 163 | the cache moved into place | `file.rename()` FALSE | no. (Both caches are keyed on the query and the lake or glacier table, not on the watershed polygons: the existing recipe of `wb_small_basin.R`, not a guard) |
| 180 | every station's watershed is in the province run | one missing | no |
| 183 | one upstream row per watershed | repeated | no |
| 201 | glacier and lake cover lie in 0 to 1.01 | outside, or NA | a wrong cover inside the range (lakes and manmade waterbodies overlapping, say); nothing claims more than the range |
| 217 | every station has a reason or is kept | NA reason | no |
| 220 | some station is kept; kept traits finite | else | no |
| 225 | folds come back in station order | else | no |
| 231 | related is symmetric with a FALSE diagonal | else | true by construction of `share_related()`; a contract on another script's function |
| 258 | fits in station order; a3 in (0, 1) | else | no |
| header 23-26 | "Every other station is listed with its reason" | no assertion | holds in the report: 209 + 48 = 257, and 889 + 109 + 1 stuck year = 999. `wet_station_snap()` returns a row per station, so the merge at 108 drops none |

### `scripts/temp_baseline_recover.R`

| line | claims | fires when | passes with the defect? |
|---|---|---|---|
| 53 | the code loaded is the code hashed | see lib 299-309 | finding 3 |
| 62 | the frame is the one the report names | see lib 35-42 | finding 1 |
| 70 | related is the frame's stations' upstream-or-downstream matrix | the frame's `related` differs from one rebuilt from its codes | both sides use `wet_fwa_upstream()`, so it cannot see that function being wrong about the network; it does see a frame out of step with the code |
| 74 | the network part is shared by related stations only, unit variance | a shared draw between unrelated stations | no |
| 127 | `leak_ok`: \|z\| under 3 in all 9 leak-free cells | a cell at 3 or more | a pool that leaks too little to reach 3 at 1,600 sets; bounded by the planted pools at −4.1 or beyond |
| 137 | the blocked donor rows are in theta's order | else | no |
| 138 | `fires`: z below −3 in all 9 cells of the three leaking pools | a cell above −3 | no |
| 148 | the regression is exact with no network part or noise | error over 1e-8 of the spread | no. **Stops without a report (finding 2)** |
| 158 | every station has a series | a station the caches no longer give one | no. Stops without a report |
| 162 | rho in (0, 1), sigma positive | else | no. Stops without a report |
| 207 | every worker loaded the master's code | a worker's md5 differs | no |
| 269 | no hashed file changed during the run | see lib 313 | accepted family |
| 271-276 | the report is written either way, then a FAIL stops the run | either verdict FALSE | **"either way" is the two verdicts only (finding 2)** |
| header 48 | byte-identical on a rerun | no assertion | holds by seeding: one seed for part 1, one per set inside each worker, so the worker count does not matter |

### `scripts/temp_baseline.R`

| line | claims | fires when | passes with the defect? |
|---|---|---|---|
| 83 | the code loaded is the code hashed | see lib 299-309 | finding 3 |
| 86 | gsdd is installed | absent | its version is printed, not held to the recovery's |
| 89 | the frame is the one the report names | see lib 35-42 | finding 1 |
| 91 | the recovery report exists | absent | no |
| 96 | the recovery report is committed as it stands | untracked; or `git status` prints a line | **yes: `git status` failing, or the path flagged assume-unchanged (finding 4)** |
| 100 | the recovery ran on this frame | key differs, or 0 or 2 `frame:` lines | the key is finding 1's |
| 102 | the recovery ran this code | md5 differs, or 0 or 2 `code:` lines | no |
| 106 | the leak check passed and was shown able to fail | either `: PASS` line absent | a run that stopped elsewhere left the old lines (finding 2) |
| 120 | every frame station still has a fit | one lost from the caches | no |
| 124 | the fits are "the fits the recovery took its scale from" | own fits differ from the frame file's by about 3e-10 or more | **compares with the frame file as it is now, not as the recovery read it (finding 1)** |
| 139-140 | the benchmark run is the fit `wet_temp_fill()` made | its RMSE differs from the stored one; names out of step | no; has a true branch (wrong series or parameter order) |
| 154 | every paired station-year has every run | never: `tb_statistic()` line 266 already holds it | cannot fire; harmless |
| 217 | no hashed file changed during the run | see lib 313 | accepted family |
| header 77 | byte-identical on a rerun | no assertion | holds on these caches; the context line reads `validate_scores.rds`, which no token names |

### Refusals described in a header, `CLAUDE.md` or the research section

| where | says | code that carries it | wider than the code? |
|---|---|---|---|
| `temp_baseline.R:69-73` | refuses unless the recovery report is committed and names the code as loaded and the frame | 91-107 | no (the code asks more: both PASS lines). Findings 1 and 4 bound "frame" and "committed" |
| `temp_baseline_recover.R:45-48` | the scorer refuses unless it is committed, says PASS twice and names both as they stand | `temp_baseline.R:91-107` | no |
| `temp_baseline_recover.R:24-30` | each leaking pool must read z below −3; the report is written either way | 138, 271-276 | no, read as the leak check's paragraph |
| `temp_baseline_recover.R:31-32` | the regression must return theta exactly | 148 | no (to 1e-8 of the spread) |
| `temp_baseline_recover.R:270` | "so nothing scores on a stale PASS" | 271 | **yes (finding 2)** |
| `temp_baseline_lib.R:278-282` | both scripts stop if a file has changed by the time they write | `recover.R:269`, `temp_baseline.R:217` | no |
| `temp_baseline_lib.R:292-296` | the md5 returned is of the code in memory | 306-309 | **yes (finding 3)** |
| `temp_baseline_traits.R:9` | a station the water balance snapped must get the same segment | 120-127 | no for the 141; the 5 rejected by both are stated |
| `temp_baseline_traits.R:259-260` | the key is of what a score depends on | 261-264 | **yes (finding 1)** |
| `temp_baseline_rule.R:17-19` | any other candidate is reported beside the baseline and never becomes it | 44-60, 72 | no |
| `temp_baseline.R:9-11` | every (A1) item predates any real score | git history | **yes for one sentence (finding 6)** |
| `CLAUDE.md:58` | a failing run writes a failing report | `recover.R:271-276` | **yes (finding 2)** |
| `CLAUDE.md:58` | `tb_code_load()` stops if a file moves while it loads them | `lib.R:306-308` | no (fired in the copy) |
| `CLAUDE.md:59` | refused unless the recovery report is committed and names the frame and code as they stand | `temp_baseline.R:91-107` | bounded by findings 1 and 4 |
| `CLAUDE.md:60` | any change to a file `tb_code_md5()` names stales the recovery report | `temp_baseline.R:101` | no (the test mutates one of the nine) |

## Table B: every sentence with a quantifier, a scope word or a number

`R` is `data/checks/temp_baseline_recover.txt`, `S` is `data/checks/temp_baseline.txt`, `F` is
`data/checks/temp_baseline_frame.txt`; numbers after a colon are lines. "frame" and "scores" mean
recomputed in this round from the cached rds files.

### `research/station_temperature_fill.md`, "A station with no record"

| line | claim | carried by | verdict |
|---|---|---|---|
| 87 | HYDAT 2026-07-17, run `768876badf`, frame `bd5db3bd6b` | F:2-3 | holds |
| 89 | "three" parameters; "best of three" misses by "about 295" | S:13,16 (293.9, 298.0) | holds |
| 89 | own parameters: "98" | S:11 prints 97.5; 97.4663 | **97 (finding 5)** |
| 89 | population mean: "413" | S:12 (412.8; leak-free 414.1) | holds, blocked |
| 89 | "Each figure is the mean, over 209 held-out stations, of the station's mean absolute GSDD error" | S:5,8; `lib.R:272-273` | holds |
| 89 | traits "recover about a third of what a record gives" | no line; (412.8 − 293.9) / (412.8 − 97.5) is 37.7 %, leak-free 36.7 % | approximate; not reported |
| 89 | the gap, "about 200", is "twice the width of the band" (800 to 900) | S:23 (196.4, 200.5) | holds |
| 89 | "cannot place a reach on one side of that band" | inference from the line above | judgement, no line |
| 91 | 257 stations, 999 station-years, less 48 | F:6,44 | holds |
| 92 | 18 with fewer than 365 observed days | F: 18 rows "too little record to fit" | holds (336 to 352 days each, round 1) |
| 93 | 19 not snapped within 10 %, or with no gross area | F: 14 + 5 rows | holds |
| 94 | 9 under 95 % inside BC | F: 9 rows, 33 to 94 % | holds |
| 95 | 08LG048 reads 4.0 °C "on all 586 days" | F:7,68 for the drop; the days from the water cache (rounds 1, 2) | holds; no report line carries 586 |
| 96 | 07FA008, a 2024 station | F:46; start date from the cache (rounds 1, 2) | holds |
| 98 | 209 and 889; 136 / 67 / 6; 135 / 74; 32; 96 | F:6,9,11 | holds |
| 100 | "Three candidates"; theta "turned back before the run" | `lib.R:57,61-68`; `temp_baseline.R:143` | holds |
| 102 | "eight traits" | `lib.R:29` | holds |
| 103 | inverse-distance mean of "the 5 nearest" | `lib.R:72,126` | holds |
| 105 | one sub-sub-drainage held out "together" | `lib.R:157`; `wet_cv_folds()` | holds |
| 105 | leak-free removes "every" station upstream or downstream; 461 pairs at 97 stations | F:12; `lib.R:159`; frame: 461, 97 | holds ("every" rests on `wet_fwa_upstream()`'s codes) |
| 107 | the rule "fixed before any score" | 914259d6 precedes 767aac9f; rule file unchanged since | holds |
| 107 | at least 10 in "both" pools; within 50 in "both" | `rule.R:8-9,53,62` | holds |
| 111-114 | the table's 12 numbers | S:11-17 | holds |
| 116 | mean over stations; RMSE the mean over station-years | `lib.R:272-273`; `temp_baseline.R:164` | holds |
| 118 | 118.9 / 116.2 / 104.6 / 94.4; "both displace it"; 196.4 / 200.5; "about twice" | S:20-24 (201 %, 206 %) | holds |
| 121 | "about a third of the signal"; 30 / 33 / 19 % leak-free | S:43-45 (0.3018, 0.3319, 0.1853) | holds |
| 121 | runs cold "by 118 to 122"; regression "within 8" | S:12,15 (−117.67, −122.48); S:13,16 (−7.09, 1.22) | holds |
| 122 | neighbours help the nearest-stations mean, "not the regression"; 11.5 and 4.1 | S:13-17 (11.497, 4.120) | **numbers hold; "not" is wider (finding 5)** |
| 123 | 32 lake outlets; 408 against 278; benchmark "the same" (102 and 97) | S:71-72 (407.53, 278.17, 101.81, 96.68) | holds; "the same" is 5 apart, both given |
| 124 | 376 against 260; "the same benchmark" (96 and 99) | S:87-88 (375.503, 260.32, 96.34, 99.05) | holds |
| 125 | "not worse": 267 and 324; benchmark 111 against 86 | S:82-83 | holds |
| 126 | 159 (08O, 3) to 398 (08J, 9); loses in 07F (7) and 08G (16): 344 / 145, 326 / 291 | S:52-67 | holds; those are the only two of 16 |
| 128 | 822; 119; 130; "about 11" | S:27 (118.8, 130.3) | holds |
| 130 | "1,600 times" | R:4 | holds |
| 131 | regression "unbiased"; 1.286 against 1.246 | R:20-22,29-31 (each within 1 se); R:29 | holds |
| 131 | nearest-stations mean 2 to 5 % leak-free, 0.5 to 4 % blocked; mean under 1 % "in both" | R:17-19,23-28,32-34 (1.99 / 2.79 / 5.04; 1.63 / 0.45 / 3.79; at most 0.91) | holds |
| 131 | "Each candidate's" interval holds 89.6 to 90.2 % | R:17-34, cover | holds |
| 132 | changes "no candidate's" leak-free error; largest \|z\| 1.0 | R:26-34 (0.97), R:36 | holds |
| 132 | "three pools": −7.8 to −8.5; −4.1 to −4.7; −5.0 to −5.8 | R:40-48 | holds |
| 132 | "the check can fail, on a half-broken pool too" | R:50; `recover.R:138` | holds for the two planted |
| 132 | regression −1.5 to −3.0; the mean "not at all" | R:20-22; R:17-19 (−0.3 to −0.9) | holds |
| 133 | "five" sets; "about a tenth" at the median station | R:4; R:102-104 (0.102, 0.082, 0.097) | holds |
| 134 | 19 stations at rho ≥ 0.99; up to 17.8 °C; at most 3.1; "no such station" (−2.2 to 7.5) | no report line; frame: 19, 17.84, 3.06, −2.16 to 7.49 | holds |
| 136 | "each candidate's" interval holds 87 to 94 %; "none is carried" further | S:31-48 (0.871 to 0.943); code | holds |
| 139 | the 48 dropped "are not a random draw" | F:45-93 | holds |
| 140 | correlation −0.49 | no report line; frame: −0.491 | holds |
| 141 | kriging "is scored on this frame under this rule in #223"; the scores file | the file exists (gitignored); #223 is not built | forward statement |
| 155 | "no network model, no interval on GSDD, and no small-stream loggers" | code; F | holds |

### `research/README.md:14`

| claim | carried by | verdict |
|---|---|---|
| 209 held-out stations; about 295; "not close" | S:5,13,16,24 | holds |
| "against 98 with the station's own" | S:11 (97.5; 97.4663) | **97 (finding 5)** |

### `CLAUDE.md:56-60`

| line | claim | carried by | verdict |
|---|---|---|---|
| 56 | registered at 914259d6 "before any real score" | git: 11:50 against 12:47 | holds |
| 56 | "Amendment 1, also before any score" | 226ca962; one (A1) sentence reworded after | **finding 6** |
| 57 | five province-run traits; glacier query "taken by `parse()`"; lake cover "by the same recipe" | `traits.R:133,141-164,168` | holds |
| 57 | the report names the frame and "every dropped station with its reason" | F:44-93 (48 rows) | holds |
| 57 | "a bundle cut to the watersheds it lists when it stops" | `traits.R:177-181` | holds |
| 58 | "every candidate"; "five end-to-end sets" | R:4,16-34 | holds |
| 58 | the leak check "must pass and must be shown able to fail"; "no candidate's"; "three pools" | `recover.R:127,138`; `temp_baseline.R:105` | holds |
| 58 | "A failing run writes a failing report." | `recover.R:271-276` | **the two leak verdicts only (finding 2)** |
| 58 | "one md5 over the lib, the rule, the recovery and scoring scripts and the code they call" | `lib.R:284-286`; the walk in the mechanism table | holds |
| 58 | `tb_code_load()` "stops if a file moves while it loads them" | `lib.R:306-308` | holds (fired in the copy) |
| 59 | "refused unless the recovery report is committed and names the frame and code as they stand" | `temp_baseline.R:91-107` | holds, bounded by findings 1 and 4 |
| 59 | scored "against the station's own parameters" | `temp_baseline.R:128,137-146` | holds: scored against the observed water, set beside the own-parameter run |
| 59 | the scores file, "which network kriging (#223) is scored against under the same rule" | not built | forward statement |
| 60 | "Any change to a file `tb_code_md5()` names stales the recovery report" | `temp_baseline.R:101` | holds |

## Checked, nothing to report

- Round 2's planted pools: same statistic as the real pools, no random draw of their own (so
  part 1's stream is the one round 2 replayed), labelled as they remove.
- `tb_code_load()` in the master and in a worker: same md5, source-tree namespace, the rule and
  `gsdd_year` in the global environment of each.
- The frame: the key recomputed from the cached frame's own columns is `bd5db3bd6b`;
  `up | t(up)` rebuilt from its codes is `identical()` to its `related`; 640 pairs, 461
  cross-fold, 97 stations.
- Guards that cannot fire as built (`lib.R:164`, `temp_baseline.R:154`, `traits.R:231`): each
  would fire only after an edit elsewhere, and no report line or sentence rests on any of them.
- `planning/active/progress.md` and `task_plan.md` were read as working notes and not checked
  sentence by sentence.
