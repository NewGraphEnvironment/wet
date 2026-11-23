## Outcome

Backlog move 11 (#188) carried three pieces of its batch and filed the fourth.

- **#185.** `research/monthly_error.md` is arranged by subject: by region and season, by basin size, routed PCIC's seasonal shape, and the Fraser benchmark. No claim number moved.
- **#178, items 1 and 2.** WALLY, the province's water allocation model, is set beside the held-out balance and routed PCIC at the calibration gauges (`scripts/wally_compare.R`, `research/wally.md`). Its 27 zone regressions lean on precipitation, slope and glacier cover. Its published scores are in-sample, and 280 of our 315 gauges are among its training stations.
- **#176.** The small-basin diagnosis ran under a rule registered in `scripts/wb_small_basin.R`'s header before any check computed; check B's thresholds are the owner's.
  - The +14 % bias under 100 km² comes in with the zone adjustment (raw +1.9 %). By zone it is concentrated.
  - Against PCIC the raw terms compensate, so the raw contrast is unresolved.
  - Seven catchment traits held out are undecided: the median falls to +2.7 %, but the interval reaches +15.6 %.
- **Filed as #199.** Scoring zone-line blending (#44) and a trait regression, with slope and solar exposure, which need the DEM, goes to #199. No published value changed, and no scored file changed.

The code review's lesson: a cache named only for its release, read by a second script, cannot be trusted by holding one list to it. Four rounds each found the previous guard too narrow. The approach that held was to evaluate #45's own code from its parsed source and hold the cache to #45's content-keyed caches.

## Measurement

- **Small-basin diagnosis** (`data/checks/wb_small_basin_20260717.txt`; 84 gauges under 100 km², 231 larger, HYDAT 2026-07-17, fit 768876badf):
  - median error, small gauges: raw +1.9 %, adjusted +14.3 %; larger gauges: −15.1 % and −6.7 %. Small minus larger goes from +17.0 points raw to +21.0 points adjusted.
  - Check A: at least +10 points in all three elevation terciles and all three aridity terciles. By zone, only 3 zones hold 5 gauges on each side, and only 1 of them reaches +10 points (08 and 28 do not). Reading: concentrated.
  - Check B, full model:
    - small-gauge median +2.7 % (90 % fold-bootstrap interval −8.8 to +15.6 %);
    - small-gauge MAE 40.4 → 33.7 %, and the larger gauges' MAE +0.2 points;
    - verdict undecided.
  - Check B, area alone: +3.8 % (−5.6 to +19.1 %), MAE 40.4 → 34.9 %, +0.6 points; undecided.
  - Check C, on the 48 PCIC-covered small basins (raw +14.8 %, adjusted +27.7 % there): #45's rule reads "compensating" (sum dP 10,931, sum dA 9,219).
  - Held-out proof: an in-sample fit gives a lower mean absolute log residual (0.231 against 0.244) and different predictions.
  - Glacier cover: 13,648 FWA glaciers, 28,847 km², intersected with the fundamental watersheds with no area lost. 154 of 315 gauges have some glacier upstream.
- **WALLY** (`data/checks/wally_compare_20260717.txt`):
  - its training table holds 534 stations, and its allocation filter keeps 482. HYDAT flags 110 of the 482 regulated.
  - At the 280 shared gauges, WALLY's measured MAR is a median 1.010 times ours.
  - Over the 25 zone classes with 5 or more of our gauges, the median zone R² is 90 % for WALLY (in-sample) and 60 % for the held-out balance; routed PCIC's is 74 % over 23 classes.
  - The median ratio of our RMSE to WALLY's STEYX is 2.16 for the balance and 1.82 for routed PCIC.
  - Province-wide: the balance's R² is 87 % (RMSE 12.5 l/s/km²) and routed PCIC's 90 % (11.2), against WALLY's in-sample XGBoost 96 % (STEYX 5.9).
- **Consolidation:** soul's `research_check.sh` read 1,727 prose words and 3 issue-headed sections (FLAG) before, and 1,782 words with 0 sections (OK) after. Before the #176 revision added its statements, the file's claim-number multiset was identical, with issue numbers and shas stripped.
- **Wrong turns kept:**
  - A first number guard counted issue tags as claim numbers.
  - A first guard-probe extracted only a helper's body, so it "passed" every mutation until the extraction was fixed.
  - This machine's clock read 7 hours early at the session's start, so two commits (ef2e88e, 8864113) and two fetch-log rows carry early times.

## Evidence

`data/logs/188/` in the main checkout:
- `wally_fetch.tsv`, the fetch log;
- `wally_compare_run*`;
- `wb_small_basin_{dev1,run*,insample}.log`;
- `devtools_test*.log`.

The code-check rounds are in this archive (`review-round*.md`, `review-verdict.md`).

Closed by: the pull request for branch `188-backlog-move-11-small-basin-error-and-th`.
