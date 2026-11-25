# How the review of #213 ended: an enumeration, at e7cb7140

Five code-check rounds ran (`review-round1.md` to `review-round5.md`). Rounds 2, 3 and 4 each
found a defect inside the round before's fix, and round 5 found one in a round 4 test, so a
quiet round could not end the loop. Round 3 named the mechanism: a short token (the frame key,
the code md5, a `: PASS` line, "committed") standing for a sentence with "every" or "as it
stands" in it, computed from a hand-written list in another place. The fixes removed the lists:
the frame key hashes everything the frame holds, the md5's file list is checked by walking the
package's objects, the recovery report is removed when a run starts, "committed" is a blob
comparison. What ends the loop is the set below, run in a detached copy of the branch at
e7cb7140 (never in the working tree): every guard and every key component, each with its
defect planted, and the control with nothing planted.

Every row stops, turns a test red or moves the key: 26 of 26 against the scoring guard, 20 of
20 against the lib's tests, 5 of 5 against the rule's tests, and 43 of 43 columns of the real
frame (41 move the key, and the station numbers of `stations` and `fit` are refused as out of
order). The control scores and reproduces the committed report byte for byte.

Two rows did not hold when first run and are why the last changes were made: "load returns a
later read" and "key skips column names" survived the tests as round 3 and round 4 left them,
and "a segment id plus 1" kept the key until whole numbers entered it exactly.

Not covered by any row, and accepted: `tb_verdict()` compares unrounded scores and prints one
decimal (the registered rule; no result is near a threshold); the running script's md5 is
taken at load, with `tb_code_same()` before each write; the code md5 names neither the gsdd
package nor R; the water and air caches are not hashed themselves, the frame key covering the
truth years and fits derived from them; a file changing and changing back between
`tb_code_load()`'s two reads; and within the key, `NA` against the string "NA", a `|` inside a
character value, row names and factor level order, none of which the scoring path reads.

```
copy at e7cb7140
## A. the scoring guard, one planted defect each
1 recovery report deleted                          exit 1 | Error: data/checks/temp_baseline_recover.txt is missing: run scripts/temp_baseline_recover
2 recovery report modified, uncommitted            exit 1 | Error: data/checks/temp_baseline_recover.txt is not committed as it stands: commit the rec
3 modified and flagged assume-unchanged            exit 1 | Error: data/checks/temp_baseline_recover.txt is not committed as it stands: commit the rec
4 recovery ran on another frame (committed)        exit 1 | Error: the recovery ran on another frame: 0000000000
5 recovery names other code (committed)            exit 1 | Error: the code a score depends on changed since the recovery run: run scripts/temp_baseli
6 leak-free check FAIL (committed)                 exit 1 | Error: the recovery's leak-free check did not pass, or was not shown to be able to fail
7 can-fail check FAIL (committed)                  exit 1 | Error: the recovery's leak-free check did not pass, or was not shown to be able to fail
8 one line added to scripts/temp_baseline_lib.R    exit 1 | Error: the code a score depends on changed since the recovery run: run scripts/temp_baseli
9 one line added to scripts/temp_baseline_rule.R   exit 1 | Error: the code a score depends on changed since the recovery run: run scripts/temp_baseli
10 one line added to scripts/temp_baseline_recover.R exit 1 | Error: the code a score depends on changed since the recovery run: run scripts/temp_base
11 one line added to scripts/temp_baseline.R       exit 1 | Error: the code a score depends on changed since the recovery run: run scripts/temp_baseli
12 one line added to scripts/temp_fill_validate.R  exit 1 | Error: the code a score depends on changed since the recovery run: run scripts/temp_baseli
13 one line added to R/wet_temp_fill.R             exit 1 | Error: the code a score depends on changed since the recovery run: run scripts/temp_baseli
14 one line added to R/wet_temp_gsdd.R             exit 1 | Error: the code a score depends on changed since the recovery run: run scripts/temp_baseli
15 one line added to R/wet_donor_mean.R            exit 1 | Error: the code a score depends on changed since the recovery run: run scripts/temp_baseli
16 one line added to R/wet_cv_folds.R              exit 1 | Error: the code a score depends on changed since the recovery run: run scripts/temp_baseli
17 frame report names a frame not on disk          exit 1 | Error: the frame the report names is not here: data/temp_baseline/frame_1111111111.rds
18 frame: one fit altered                          exit 1 | Error: data/temp_baseline/frame_edfbc29809.rds no longer holds the frame it is named for
19 frame: one trait altered                        exit 1 | Error: data/temp_baseline/frame_edfbc29809.rds no longer holds the frame it is named for
20 frame: a flag altered                           exit 1 | Error: data/temp_baseline/frame_edfbc29809.rds no longer holds the frame it is named for
21 frame: two stations' codes swapped              exit 1 | Error: data/temp_baseline/frame_edfbc29809.rds no longer holds the frame it is named for
22 frame: a truth year altered                     exit 1 | Error: data/temp_baseline/frame_edfbc29809.rds no longer holds the frame it is named for
23 frame: a truth year given to another station    exit 1 | Error: data/temp_baseline/frame_edfbc29809.rds no longer holds the frame it is named for
24 frame: a related pair altered                   exit 1 | Error: data/temp_baseline/frame_edfbc29809.rds no longer holds the frame it is named for
25 frame: a segment id plus 1                      exit 1 | Error: data/temp_baseline/frame_edfbc29809.rds no longer holds the frame it is named for
26 recovery stopped at its first guard: exit 1; its report present: no; git status:  D data/checks/temp_baseline_recover.txt
control (nothing planted): exit 0
control report identical to the committed one

## B. the lib, one planted defect each, against tests/testthat/test-temp_baseline_lib.R
nothing planted                                      failed 0 error 0 skipped 0 passed 160
key drops station_number from the truth table        failed 1 error 0 skipped 0 passed 159
key drops station_number from every table            failed 3 error 0 skipped 0 passed 157
key skips the fit table                              failed 9 error 0 skipped 0 passed 151
key skips column names                               failed 1 error 0 skipped 0 passed 159
key skips table names                                failed 1 error 0 skipped 0 passed 159
key skips the related matrix values                  failed 1 error 0 skipped 0 passed 159
key rounds whole numbers to 6 digits                 failed 1 error 0 skipped 0 passed 159
load returns a later read                            failed 0 error 1 skipped 0 passed 156
load does not recheck the files                      failed 1 error 0 skipped 0 passed 159
load accepts any lib md5                             failed 1 error 0 skipped 0 passed 159
reader does not recompute the key                    failed 1 error 0 skipped 0 passed 159
committed read from git status                       failed 2 error 0 skipped 0 passed 158
a reached file dropped from the md5 list             failed 3 error 0 skipped 0 passed 157
related station left in training                     failed 3 error 0 skipped 0 passed 157
statistic by station-year, not by station            failed 3 error 0 skipped 0 passed 157
statistic keeps unpaired years                       failed 3 error 0 skipped 0 passed 157
theta not inverted                                   failed 1 error 0 skipped 0 passed 159
network part shared by all stations                  failed 4 error 0 skipped 0 passed 156
donor interval ignores spread                        failed 1 error 0 skipped 0 passed 159
a constant the fill reads moved to an unhashed file  failed 1 error 0 skipped 0 passed 159
(the rule, against tests/testthat/test-temp_baseline_rule.R)
nothing planted                                      failed 0 error 0 skipped 0 passed 49
one pool is enough to displace                       failed 11 error 0 skipped 0 passed 38
exactly 50 is not close                              failed 4 error 0 skipped 0 passed 45
exactly 10 does not displace                         failed 2 error 0 skipped 0 passed 47
the donor wins a tie                                 failed 1 error 0 skipped 0 passed 48
close read in one pool                               failed 2 error 0 skipped 0 passed 47

## C. the real frame (data/temp_baseline/frame_edfbc29809.rds), the smallest change to one value per column
elements of the frame: stations, truth, related, dropped, fit, provenance, key 
columns walked (every column of every table): 43 
          
           key changed refused: not in one order
  dropped            4                         0
  fit                7                         1
  stations          28                         1
  truth              2                         0
a related pair altered: key changed TRUE 
each provenance entry altered: key changed TRUE ( 4 entries )
```
