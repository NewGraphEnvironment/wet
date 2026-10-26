## Outcome

The Maxan Creek Chinook pilot (#120, component 1 of #118) extended 08EE018's five complete migration and spawning windows (1975–1979) across 1931–2024 from its neighbours, with an interval per year. It also scored donor-carried departures held out at every gauge in a box of natural HYDAT gauges around the Bulkley. Two rules were registered in `scripts/departure_pilot.R`'s header and committed alone (6894c27) before any candidate existed. Under the first, OLS on the nearest covering donor extends Maxan; the incumbent ratio of means lost. Under the second, donor-carried departures are usable for #122. Two exported functions came out of it: `wet_window_extend()` and `wet_departure_carry()`. Nothing is published; the result is the tracked report `data/checks/departure_pilot_20260717.txt`, and the durable verdict is in [`research/station_flow_departure.md`](../../../research/station_flow_departure.md), "Departures at an ungauged site: the Maxan pilot (#120)".

## Measurement

All on HYDAT 20260717, approved daily flows only; scores are for the migration-window mean, the statistic the rules decide on.

- **Pool:** 53 natural box gauges with ≥3 complete migration windows. The extension pool holds 21, the departure pool 31, and the short-record set 13.
- **Record extension:** 220 five-year pseudo-records were cut and 218 had a covering donor. Median held-out log NSE over 21 gauges: OLS 0.50, MOVE.1 0.47, ratio 0.42. OLS ships (margin 0.01). Coverage of the nominal 90 % interval: 85 %, 90 %, 89 %. OLS stays first at k = 3, 8 and leak-free. A regression on up to three donors (0.30 against 0.56) and day-by-day regression (0.36 against 0.52) both lose.
- **Carried departures:** leave-one-gauge-out over the departure pool, centred on the overlap. Median NSE 0.63 (quartiles 0.34 to 0.75) clears the pre-set 0.5, so the method is usable. The short-record gauges score 0.69 (12 of 13 scored) and Maxan 0.92. Leak-free gives 0.57.
- **Maxan, 2011–2025 against before 1981:** migration mean −14 % (90 % interval −33 % to +9 %), spawning mean −56 % (−73 % to −28 %). The carried route gives −3 % and −46 %. The earliest three decades rest on the Bulkley at Quick, which contains Maxan.
- **What changed because of it:** #122 inherits a usable carried-departure method and its threshold. The before/after at Maxan is now a number with an interval rather than an assumption.

Wrong turns kept in `findings.md`:

- The pilot-count guard fired on a correct count, because the counts were named by station rather than role.
- A leave-one-year-out RMSE squared the mean.
- MOVE.1 warned on a target with constant `cov_day`.
- A carry guard proved unreachable and was removed rather than tested.
- Five review rounds found 17 more defects (13 bugs, 4 fragile), almost all in the report and research text. Rounds 2, 4 and 5 each found one inside an earlier fix. They shared one mechanism: a label claiming a wider or different set than the object that computes its number. The loop ended on a noun-against-object enumeration of every numbered research sentence.

Every fix regenerated the report twice, byte-identical, and no value moved after the first full run.

## Evidence

- `data/checks/departure_pilot_20260717.txt` (tracked), and `data/logs/120/20261025_departure_pilot_*` (the final two runs; both empty, no warnings or errors).
- The review record is `review-plan.md` and `review-round*.md` in this directory.

## Owed

- Tick #120 in #118's component task list.

Closed by: PR #125
