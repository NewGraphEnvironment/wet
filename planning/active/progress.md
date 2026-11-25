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
