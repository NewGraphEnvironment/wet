# Plan review of #213 (Plan agent, returned 2026-11-25, after Phase 1 was committed)

Blockers raised: 5 · Owner forks: 0. Each finding with what a probe showed and what was done.

## Blockers

1. **Truth-set counts.** `truth_years.rds` holds 1,006 station-years at 259 stations; 999 at 257
   is after the air filter. And `wet_fill_prepare(min_days = 365)` does not fit every truth
   station. **Confirmed in part:** the traits script computes the truth set from the cached
   water after the air filter (999 at 257 in its log) and never reads the rds; the plan's
   "held to `truth_years.rds`" was wrong and is dropped. The 365-day rule was already a
   drop reason in the script; it is now in the registered header (Amendment 1).
2. **A stuck sensor is a truth station.** **Confirmed:** 08LG048 reads 4.0 °C on all 586 days
   of 2024-2025 (sd 0); the next lowest season sd among station-years is 1.09 °C. A truth year
   with a season sd under 0.1 °C is dropped (Amendment 1); 08LG048 has no other truth year.
3. **Phase 2 cannot run from the reduced bundle.** **Confirmed, and handled:** the script stops
   with the list of watersheds it needs, and a bundle of the province run's upstream means is
   cut to them on the machine that holds the full run.
4. **The leak-free check as worded is wrong for the donor mean:** replacing the network part
   everywhere also removes the correlation among training stations. **Accepted on the
   argument:** each candidate's prediction is a weighted sum of training theta with weights
   that depend on traits alone, so replacing only the held-out station's network part leaves
   the leak-free error's distribution unchanged exactly, and lowers nothing. The recovery
   replaces the held-out station's part only.
5. **The end-to-end assertion contradicts itself:** the simulated truth carries an AR(1)
   departure, so GSDD error with the true theta is not 0. **Accepted:** the assertion is
   against the departure-free run.

## Gaps taken

- `gsdd` is in Suggests: the lib test skips without it.
- Regulated stations (about a third) stay in the truth set unsaid: the frame carries HYDAT's
  flag and the report breaks scores down by it. It decides nothing.
- Ten truth stations sit in the water balance's `$test` set, which the same-segment check now
  reads too.
- Candidates and the benchmark must run on the series `rmse_open` was fitted on, from its first
  day (a slow station keeps start-up error for months): registered (Amendment 1). The proof
  "equals `rmse_open`" holds over every observed day, not the Mar-Nov days.
- #40's 129 °C-days is over 897 station-years: the context line pairs on the common set.
- The simulated network part's variance must be equal per station: `tb_net_weights()` scales
  each row to unit variance. The tree property (no unrelated pair shares an upstream station)
  is asserted on the real frame.
- The simulation needs the scale of theta and of the departure: the frame carries each
  station's own fit, and the header says fitting is not a score.
- The guard hashes every file a score depends on (`tb_code_md5()`), not the lib and rule alone.
- GSDD missing for one candidate and not another: the statistic reads the station-years where
  every series has one (Amendment 1).

## Not taken

- Recording `optim()`'s convergence code: `wet_a2s_fit()` does not return it, and the review's
  own check found both starts agree at every fitted station. No change to `R/`.
- "Drop the cd upgrade": already done, and harmless.

## Found by the first run, not the review

- 07FA008 (Cameron River, a 2024 station) is not in HYDAT 2026-07-17, so it has no gross
  drainage area to snap against. Dropped with that reason (Amendment 1).

## Left open

- How many stations the snap's 10 % area test and the 95 % inside-BC rule drop: the frame
  report counts them, and the research section says what kind of basin that removes.
- The simulated network part is tail-up; the leak-free pool removes flow-connected pairs. That
  says nothing about tail-down covariance, which is #223's to cover.
