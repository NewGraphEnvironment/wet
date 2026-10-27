# Progress — PCIC per-year routed flow: keep the years, weight donors by modelled covariance, and score donors, PCIC and a blend at held-out gauges (#122)

## Session 2026-10-26

- Plan-mode exploration; three gate questions asked and answered (sequencing, windows, blend); Plan review run synchronously and folded in (`review-plan.md`)
- Phases approved by user as **parked** (baseline only)
- Created branch `122-pcic-per-year-routed-flow-keep-the-years` off main (fa9b31f)
- Scaffolded PWF baseline from issue #122 with the approved phases
- Next: parked 2026-10-26; resume with the command below, then "start Phase 1"

### Resume

One machine runs the branch at a time: the push at park handed it off, and the resume takes it. The run-to-PR mandate starts at the resume instruction, not at the parked approval.

```bash
cd ~/Projects/repo/wet && git fetch -q origin && git checkout 122-pcic-per-year-routed-flow-keep-the-years && git pull --ff-only && git merge origin/main
```

Then "start Phase 1 of planning/active/task_plan.md". Phase 1 is the rule header alone, committed alone, before any candidate is coded. Phase 3 (fwapg#42) runs in the fwapg checkout under its own `/planning-init fwapg#42` gate and needs this machine (the `pcic` schema in the local fwapg database, the crosswalk staging, the fit bundle).

## Session 2026-10-26 (resume)

- Resumed on instruction; branch current with origin and main; CI green.
- Phase 1: probed `pcic.subbasin_daily`'s precision (float64; findings), wrote the rule header of `scripts/departure_pcic.R`, committed it alone before any candidate.
- Next: Phase 2 (wet reads the years; synthetic fixture).
- Phase 2: `wet_routed_years()` (reads only the named sub-basins through duckdb, refuses a missing, repeated or non-calendar day and an NA flow, routes with `wet_routed_days()`), the synthetic fixture (4 sub-basins, 1951-2012, 400 KB; a losing reach exercises the clamp) and 24 test expectations; exported under a widened "PCIC runoff and routed flow" pkgdown section.
- Phase 2: `wet_departure_carry(weights =, modelled =)` through the internal `wet_donor_weights()`; default byte-identical; mutation table in findings.
- Phase 2: `wet_routed_years()`, its fixture and tests moved to fwapg#42's decided layout (one file per year, `date`, float32; fixture gains a `pcic.series`-shaped catalogue); the fixture regenerates byte-identical.
- Phase 2 done: full suite 1554 pass, 7 skip, 0 fail (23:57-23:58 UTC, `data/logs/122/test_phase2.log`); no lints in the new files; the pilot and routed reports regenerate identical.
- `/code-check branch`: four rounds (00:14 to 00:56 UTC), 3, 1, 4 and 3 findings, all fixed; rounds 2 to 4 each found a defect inside the previous fix; ended on round 4's 59-row enumeration (`review-round4.md`, Closure). Full suite after: 1573 pass, 7 skip, 0 fail (`data/logs/122/test_review.log`). The harness on the final body reports what it did before the review but for the commit and md5 line.
- Next: the user resumes fwapg#42 (Phase 3). Once its files and `pcic.series` exist, run Phase 4 from a frozen copy:
  `cp scripts/departure_pcic.R "$TMPDIR/d.R" && WET_HYDAT_RELEASE=20260717 WET_FWAPG_COMMIT=7c30f58 WET_PCIC_YEARS=<dir> Rscript "$TMPDIR/d.R"`
  twice (byte-identical), then the mutation table, then Phase 5.

## Session 2026-10-27
- fwapg#42 merged (fwapg PR #44, 14:36 UTC) with a `commit` column in `pcic.series`; 63 files built at ea9b199, local copy `~/Projects/repo/fwapg/extras/pcic_crosswalk/data/days/PNWNAmet_historical/`.
- Loaded fwapg's `load/pcic_schema.sql` and `load/pcic.sql` into the local fwapg database (17:28–17:31 UTC). Before: both runs' fingerprints equal the published ones; after: unchanged, `pcic.series` 63 rows (1950–2012), one commit, one crosswalk md5.
- Header amended at b518ebc (interface section, before any run on the product): the files' commit is read from `pcic.series`; `WET_FWAPG_DAYS_COMMIT` dropped.
- The "fingerprints" compared above were `pcic.runs` rows, not the tables: that database holds no 1951-2012 rows in `pcic.subbasin_daily`, which the run guard needs. Run 1 (18:09 UTC) read the localhost database through `WET_PG*` defaults, another fwapg build, and its guard refused it at 19:52 (`data/logs/122/run1.log`). Next: load `pcic.subbasin_daily.pnwnamet_historical_1951-2012.csv.gz` with fwapg's `load/pcic_run.sql`, then run with `WET_PG*` set from `PG*`.
- Loaded fwapg's published 1951-2012 `pcic.subbasin_daily` (13,786,122 rows) with `load/pcic_run.sql` into the `PG*` database, 20:22–20:28 UTC (`data/logs/122/load_daily_1951-2012.log`); `routed_daily_fingerprint()` passes for both periods.
- Run 1 (20:30–20:46 UTC) and run 2 (20:53–21:09 UTC) at 42fdd45 with `WET_PG*` set from `PG*`: exit 0, report byte-identical, series `identical()`. Stage 1 ships `covariance_pick` (+0.054 held out, +0.047 leak-free), stage 2 ships `donors` (pcic 0.48 against 0.72; blend −0.009 / +0.008).
- Phase 5 research written: `research/pcic_hydrology.md` section, pointer in `station_flow_departure.md`, README row. NEWS is written by `/gh-pr-merge` at release, as for every entry since 0.4.18.
