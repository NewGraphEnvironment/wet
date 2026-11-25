# Progress — Water temperature at stations with no record: a whole-station holdout of air2stream parameters predicted from catchment traits and the stream network (#213)

## Session 2026-11-25

- Plan-mode exploration — phases approved by user
- Created branch `213-water-temperature-at-stations-with-no-re` off origin/main
- Scaffolded PWF baseline from issue #213 with approved phases
- Next: start Phase 1

## Phase 1, 2026-11-25
- Completed: #223 filed for kriging, #213 and #214 bodies edited; cd 0.6.11 to 0.6.13; the rule
  file with its tests (49 expectations); the registered header.
- Commits: 914259d6
- Next: Phase 2

## Phase 2, 2026-11-25
- Completed: `scripts/temp_baseline_traits.R` and frame `bd5db3bd6b`: 209 of 257 stations and 889
  of 999 station-years kept; 48 dropped, each with its reason in
  `data/checks/temp_baseline_frame.txt`. The plan review returned after Phase 1; its findings and
  verdicts are in `review-213.md`, and the header's Amendment 1 (before any score) takes them.
- The run: the first pass stopped on 07FA008 (not in the pinned HYDAT), the second where
  designed, listing 237 watersheds; a bundle of the province run's upstream means was cut to
  them where the full run is, and the third pass wrote the frame. Logs `data/logs/213/traits_*`.
- Worktree data: `data/temp_fill` and `data/wb_small_basin` are links to the main checkout;
  `data/wb/768876badf/upstream/` here is the cut bundle (no `WET_DATA_ROOT` was needed).
- The lib and its tests (70 expectations) land in this commit; five planted defects each turned
  a test red (a related station left in training, the network part shared by all, theta not
  inverted, one pool enough to displace, exactly 50 not close).
- Next: the recovery run (Phase 3), then the real scores

## Phase 3, 2026-11-25
- Completed: `scripts/temp_baseline_recover.R` and `data/checks/temp_baseline_recover.txt`
  (frame `bd5db3bd6b`, code `b8cadd96`): leak-free check PASS, intervals cover 0.895 to 0.903,
  the regression exact on the noise-free set. The first run's end-to-end part was mis-simulated
  (findings, "The recovery run"); the committed report is the second run.
- Next: the real scores (Phase 4), which refuse without this commit

## Phase 4, 2026-11-25
- Completed: the real scores. Baseline: regression, 293.9 (blocked) and 298.0 (leak-free)
  °C-days against 97.5 for the benchmark and 412.8 / 414.1 for the population mean; not close.
  Scores in `data/temp_baseline/scores_bd5db3bd6b.rds`.
- Commits: 4deaabc1 (recovery, before any score), then this phase's commit
- Next: write-up

## Phase 5, 2026-11-25
- Completed: the section in `research/station_temperature_fill.md`, the research index row, the
  scripts in `CLAUDE.md`. `NEWS.md` is left to the release commit, as this repo does.
- Next: `/code-check branch`, archive, PR

## Code-check round 1, 2026-11-25
- Eight findings, all `fragile`, none moving a number (`review-round1.md`). Seven fixed:
  the leak-free check now runs 1,600 sets and must also fire in blocked CV (it reads z −7.8 to
  −8.5 there for the donor mean); the code md5 is taken before the code loads and rechecked
  before a report is written; `scripts/temp_baseline.R` is in the md5 and the statistic is one
  function, `tb_statistic()`, used by both scripts; the end-to-end "no error" assertion, which
  compared a series with itself, is removed; the frame report says 141 on the same segment and
  5 rejected by both; the scores report no longer prints wet's version; two wordings in the
  research section.
- Accepted, not changed: the rule compares unrounded scores and prints one decimal, so a gain of
  9.96 would print as 10.0 and not displace. It is the registered rule, no result is near a
  threshold (gains 94 to 119, gaps 196 and 201), and a change would be an amendment for the
  owner.
- Reruns: logs `data/logs/213/*_r1_*`.

## Code-check round 2, 2026-11-25
- Five findings, all `fragile`, four inside round 1's fixes (`review-round2.md`). All fixed:
  the recovery plants two half-broken pools (upstream-only, downstream-only) and requires the
  check to catch each as well as blocked CV (z −4.1 to −5.8, and −7.8 to −8.5); the code md5
  comes from `tb_code_load()`, which hashes every file, loads the package, the rule and
  `gsdd_year`, and hashes again, here and in each worker; `scripts/temp_baseline_recover.R` is
  in the md5, a failing recovery writes its failing report, and the scorer needs both PASS
  lines; two wordings (the donor's bias is 2 to 5 % in the leak-free pool only; "about a
  tenth").
- A defect inside a fix has now appeared, so the loop ends on an enumeration, not a quiet round.
- Rerun: log `data/logs/213/recover_r2_*`; every number of the report but the code md5 and the
  new table is unchanged.

## Code-check round 3, 2026-11-25
- Asked for the mechanism and an enumeration. The mechanism (`review-round3.md`): a short token
  (the frame key, the code md5, a `: PASS` line, "committed") stands for a sentence with "every"
  or "as it stands" in it, and is computed from a hand-written list somewhere else. Its tables:
  88 guards and 64 quantified or numeric claims; 11 and 5 rows wider than the code or report,
  every one inside six findings. All six fixed at the mechanism:
  1. the frame key is one function, `tb_frame_key()`, over the fits and flags as well as the
     traits, folds, truth years and related pairs, and `tb_frame_read()` recomputes it;
  2. the recovery removes its tracked report when it starts, so any stop leaves none;
  3. `tb_code_load()` returns the md5 of the hashes taken before the load, not a third read;
  4. "committed" is the file's blob against HEAD's (`tb_committed()`), not `git status`;
  5. two wordings (97, not 98; neighbours help the donor mean "more than" the regression);
  6. the header records Amendment 2: the guard's paragraph changed in review, after the scores,
     with no score moved.
- The hashed file list is now also checked by derivation: a test walks every wet function the
  scoring path names and requires its source file to be in `tb_code_files`.
- The frame key changes with its definition (it now covers the fits); frame and scores files
  are renamed with it. No score moves.
- Mutation table, run in a scratch copy at 26096074 before these fixes (the guards as round 2
  left them): the scorer stopped on all 16 planted defects (recovery report deleted; modified
  and uncommitted; another frame; another code md5; either PASS line turned to FAIL; one line
  added to each of the nine hashed files; a frame report naming a frame not on disk), and the
  untouched copy reproduced the committed scores report byte for byte. Six lib mutations each
  turned a test red (a related station left in training; the statistic by station-year; unpaired
  years kept; the scoring script dropped from the md5; any lib md5 accepted; the donor interval
  ignoring spread).

## Code-check round 4, 2026-11-25
- Narrow, on round 3's fixes. Four findings, all `fragile`, all inside them (`review-round4.md`):
  the frame key's column list was still by hand and missed `wscode` and `localcode`, which the
  recovery reads for the direction of each related pair; the derived test of the md5's file
  list followed functions and not constants; two round 3 tests stayed green with their defect
  restored; Amendment 2's "differs only in the code and frame it names" left out the dropped
  version line.
- Fixed by removing the lists rather than extending them: `tb_frame_key()` hashes everything the
  frame holds but the key (every column of every table under its name, the related pairs, the
  provenance); the derived test maps every top-level object of `R/` to its file by parsing, and
  walks constants as well as functions; the frame-key test walks every column of every table
  rather than naming some; the load test stubs every later read of the files. The amendment is
  reworded. The key changes with its definition again; no score moves.
- Mutation table at e9929bcd (round 3's guards), in a scratch copy: the scorer stopped on all 20
  planted defects (the 16 of round 2's table, plus a report modified and flagged
  assume-unchanged, and a frame rds with a fit, a trait or a flag altered under its name); the
  untouched copy reproduced the committed scores report byte for byte.
- Lib mutations against the tests as they now stand, each turning a test red: a related station
  left in training; the statistic by station-year; a reached file dropped from the md5 list; the
  load returning a later read; the load not rechecking the files; the frame key skipping the
  fit table, column names, list names, table names, or all but the first table; the reader not
  recomputing the key; "committed" read from `git status`; a constant the fill reads moved to an
  unhashed file. Two of these survived the tests as round 3 left them (the later read, found by
  this table and by round 4; column names, found by this table) and are why the tests changed.
- Reviewer agents so far on this task: one plan review and four code rounds. Rounds 2, 3 and 4
  each found a defect inside the round before's fix, which is why it ran past three.

## Code-check round 5, 2026-11-25
- Narrow, on round 4's fixes. One finding, `fragile`, in a test (`review-round5.md`): the
  frame-key test's walk of "every column" left `station_number` out of all four tables by a
  hand-written `setdiff()`, so the key could have dropped it unnoticed. The shipped key was
  right. The test now walks the station numbers of `truth` and `dropped` and renames one station
  wherever it is named. Round 5's table found no instance of anything else on the scoring path.
- The enumeration that followed (below, "How the review ended") found one gap no round had
  listed as a finding: numbers entered the key at 6 significant digits, so a nine-digit FWA id
  plus 1 kept the key. Whole numbers now enter exactly. That is the last change to the lib; the
  frame, the recovery and the scores were rerun under it (logs `data/logs/213/*_r5_*`).

## How the review ended, 2026-11-25
- By enumeration at e7cb7140 (`review-enumeration.md`, `review-verdict.md`): 26 of 26 planted
  defects stop the scoring guard, 20 of 20 turn a lib test red, 5 of 5 a rule test, 43 of 43
  columns of the real frame move its key or are refused, and the control reproduces the
  committed scores report byte for byte.
- No score moved in any round: `data/checks/temp_baseline.txt` differs from its first commit
  (767aac9f) in three lines, the frame key, the code md5 and the dropped package version, and
  `scripts/temp_baseline_rule.R` is byte-identical to its registration (914259d6).
- Tests on the final tree: 0 failed, 0 errors, 3,737 passed (log `data/logs/213/tests_final_*`).
- Reviewer agents on this task: six (one plan review, five code rounds), one over the usual
  five, because rounds 2 to 5 each found something inside the round before's fix.

## Merge of main, 2026-11-25
- `origin/main` had moved 91 commits (three other branches merged, releases to 0.5.1). Merged,
  not rebased (2f738417). One conflict, in the "Not done" list of
  `research/station_temperature_fill.md`: both additions kept. No file `tb_code_md5()` names
  changed on main, so the code md5 is the recovery report's still (8f553ae2), the scorer ran on
  the merged tree and left all three reports unchanged, and the suite passes there (0 failed,
  3,947 passed; log `data/logs/213/tests_merged_*`). The verdict names the merged head; the
  enumeration ran at e7cb7140, whose hashed files the merge did not touch.
