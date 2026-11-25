## Outcome

A whole-station holdout of air2stream parameters, built and scored under a rule registered before
any score (#213). The truth stations of the fill's validation were snapped to the Freshwater
Atlas and given catchment traits; three candidates predict each held-out station's parameters
(the population mean, a regression on traits, the inverse-distance mean of the 5 nearest
stations in trait space) in blocked cross-validation and in a leak-free pool; a recovery run on
simulated stations comes first and the scorer refuses without it. Under the rule the regression
is the baseline and it is not close to a station's own parameters: traits recover about a third
of what a record gives. Network kriging was split to #223 at the plan gate and is scored there
on this frame under this rule. What was learned beyond the scores: a guard that names "the code"
or "the frame" by a short token is only as wide as the list the token is computed from, and five
review rounds kept finding a member a hand-written list lacked until the lists were removed
(the frame key hashes everything the frame holds; the md5's file list is checked by walking the
package's objects). Findings: `research/station_temperature_fill.md`, "A station with no
record".

## Measurement

- **The scores** (`data/checks/temp_baseline.txt`): GSDD mean absolute error, the mean over 209
  held-out stations of each station's mean over its truth years. Own parameters 97.5 °C-days;
  population mean 412.8 (blocked CV) and 414.1 (leak-free); regression 293.9 and 298.0;
  nearest-stations mean 308.2 and 319.7. Daily RMSE 1.25 °C with own parameters, 1.94 to 1.96 for
  the regression. Rule's outcome: baseline regression (it beats the population mean by 118.9 and
  116.2 °C-days against a bar of 10), gap to the benchmark 196.4 and 200.5 against a bar of 50:
  not close. What changed because of it: #214's question (can per-reach degree days separate a
  reach across the 800 to 900 band) has a number for the trait-only case, about twice the band,
  and #223 has the bar it must beat.
- **The frame** (`data/checks/temp_baseline_frame.txt`): 209 of 257 stations and 889 of 999
  station-years kept. Dropped 48: 18 with too little record to fit, 19 not snapped (14 outside
  the 10 % area test, 5 with no gross area), 9 under 95 % inside BC, a stuck sensor (08LG048,
  4.0 °C on 586 days) and a station newer than the pinned HYDAT (07FA008). 461 related pairs
  sit in different folds, so only the leak-free pool removes them.
- **Where traits fail:** lake outlets (regression 408 °C-days leak-free against 278 elsewhere)
  and regulated stations (376 against 260 natural). Glacier-fed stations are not worse (267
  against 324). Held out, the regression explains 30 %, 33 % and 19 % of the variance in the
  three parameters.
- **The recovery** (`data/checks/temp_baseline_recover.txt`), 1,600 simulated sets: the
  regression unbiased and on the floor (1.286 against 1.246); 90 % intervals covering 89.6 to
  90.2 %; the leak-free check passing (largest |z| 1.0) and shown able to fail on three pools
  known to leak (z −4.1 to −8.5).
- **Wrong turns kept.** (1) The first end-to-end recovery drew each station's departure from its
  fitted `rho` and `sigma`; at 19 stations with `rho` at or above 0.99 that implies up to
  17.8 °C where the observed spread is at most 3.1, the refits sent `a1 / a3` into the hundreds
  and the regression's simulated GSDD error read 1,403 °C-days. The simulation now gives the
  departure its observed spread; the real fits hold no such station. (2) The plan's leak-free
  check (replace the network part everywhere) was wrong for the nearest-stations mean; the plan
  review caught it before it was coded. (3) The first leak-free check at 200 sets could not see
  a half-broken pool; at 1,600 with two planted half-broken pools it does. (4) The frame key was
  redefined three times in review (it left out the fits, then two code columns, then rounded
  nine-digit ids); each change renamed the frame and moved no score.
- **No score moved in review:** the scores report differs from its first commit (767aac9f) in
  three lines (frame key, code md5, a dropped package version), and
  `scripts/temp_baseline_rule.R` is byte-identical to its registration (914259d6).
- **Review:** a plan review (5 blockers raised, 0 owner forks, `review-213.md`) and five
  code-check rounds (8, 5, 6, 4 and 1 findings, all `fragile`), ended by enumeration
  (`review-enumeration.md`): 26 of 26 planted defects stop the scoring guard, 20 of 20 and 5 of
  5 turn a lib or rule test red, 43 of 43 columns of the real frame move its key.
- **Cost:** traits 1.5 min from cache (the lake query 4 min once), recovery about 20 min, scores
  4 min; the suite 0 failed, 3,947 passed on the merged tree.

## Evidence

- `data/checks/temp_baseline_frame.txt`, `data/checks/temp_baseline_recover.txt`,
  `data/checks/temp_baseline.txt` (tracked; each byte-identical on a rerun from cache).
- `data/logs/213/traits_*`, `data/logs/213/recover_*`, `data/logs/213/baseline_*`,
  `data/logs/213/tests_*` in the main checkout: every run, the first failing ones and each
  review round's reruns (`*_r1_*` to `*_r5_*`, `*_rerun_*`, `*_merged_*`) included.
- `data/temp_baseline/` in the main checkout: the frame, the scores #223 is scored against, the
  lake cache and the cut bundle of upstream means the frame script reads.
- This directory: `findings.md` (the frame, both recovery runs, the scores), `progress.md` (each
  phase and round), `review-213.md`, `review-round1.md` to `review-round5.md`,
  `review-enumeration.md`, `review-verdict.md`.

## Owed

- Tick item 2 of #214's list by hand once the PR is merged.

Closed by: PR #231
