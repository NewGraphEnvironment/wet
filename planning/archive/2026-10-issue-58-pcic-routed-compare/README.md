## Outcome

Scored PCIC's routed monthly flow (NewGraphEnvironment/fwapg#6, as rebuilt by fwapg#14 and published by fwapg#9) at the shipped water-balance fit's 315 calibration gauges. `scripts/pcic_routed_compare.R`, with its definitions in `scripts/pcic_routed_lib.R`, writes `data/checks/pcic_routed_compare_20260717.txt`. The report names the fwapg commit and the table's fingerprint, which the database does not record. It attributes each far-low gauge using fwapg's older unrouted table, and scores that table beside routed flow.

The segment vignette now compares the balance with routed PCIC instead of the older annual table, and `research/water_balance_method.md` §0 is revised in place. The data script refuses a table or commit other than the report's.

What was learned:
- Routed PCIC is closer than the balance overall, but not by mean error in the Peace or the Fraser.
- Where the older table also had values, the two PCIC products tie once seven far-low gauges are set aside. What routed adds is coverage: the coast and the order 8+ rivers.
- Eleven gauges sit on segments carrying under 20 % of observed flow. Most are side channels or Nechako reservoir lakes; one (08NE039) is PCIC's runoff.

The routed table moved three times while this issue was open (#11 → #13 tie rule → #14 junction fix), so scoring waited for the published build. The rebuild attempts on m1 died in three forced resets, caused by another session's SSNbler batch, not by this work. Durable verdict: [`research/water_balance_method.md`](../../../research/water_balance_method.md) §0 (the two PCIC bullets).

## Measurement

- **Gauge scores:** at the 290 covered gauges, mean absolute error is 24.1 % for routed against 27.6 % for the balance (held out); median 13.0 against 18.0; within ±20 %, 62 % against 54 %; bias +0.2 % against +9.0 %. Without the 11 far-low gauges: 21.3 against 27.2.
- **By basin, mean error:** Peace 20.5 against 19.2, Fraser 30.8 against 28.4 (7 of the far-low gauges are Fraser's), Columbia 23.7 against 32.7, coast 18.9 against 25.1.
- **Against the older annual table,** at the 178 gauges both PCIC products score: annual 25.3, routed 28.0, balance 30.3. At 171, without the far-low gauges: 25.0, 25.3, 30.5. At the 112 gauges only routed covers: 17.8 against the balance's 23.3.
- **Build sensitivity:** the #11 and #14 builds give identical gauge scores (#14 moved flow at 2 of 604 WSC gauges, none of them calibration gauges).
- **#57's ad hoc query:** this script reproduced its balance side exactly, and its routed side to within 0.3 points. The gap is attributed to an unrecorded earlier build of the table the same day; weighting months by their length does not explain it.
- **Table loaded on m1:** fwapg#9's published `fwa_stream_networks_discharge_monthly.csv.gz`, sha256 b45c5230da1b622e17276592ef17647e1af333c99da22899e659eb02789026b7. Fingerprint 40,524,444 rows, 3,377,037 segments, sum(round(q,6)) 178035348.248310; it matches fwapg PR #21.
- **Vignette bundle:** 469 KB of the 500 KB budget. The routed coverage outline was 544 KB raw because of the coast's islets, and 22 KB after dropping parts under 200 km², snapping to 1 km and buffering 2 km.
- **Wrong turns kept:**
  - The first rebuild plan assumed m1's table predated the merged placement. fwapg#2's rerun showed it reproduced exactly.
  - Three rebuild attempts on m1 died in forced resets. A guessed-commit report (4929c8c) was never committed.

## Evidence

- `data/checks/pcic_routed_compare_20260717.txt` (tracked).
- `planning/archive/2026-10-issue-58-pcic-routed-compare/review-*.md`: the plan review and three code-check rounds.

Closed by: PR (branch `58-score-pcic-routed-flow-at-the-gauges-rep`)
