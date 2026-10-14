# Code-check enumeration (#65), after round 2

Rounds 1 and 2 found one mechanism: a number or claim in the article's prose computed over a different set than its sentence names, or not asserted. The candidate set is every inline `` `r ...` `` value in `vignettes/monthly-flow.Rmd` (72 after round 2's fixes, extracted by script) and the factual sentences around them. Each was walked to the computation behind it and the guard that holds it:

| Section | Values | Set it is over | Guard |
|---|---|---|---|
| What a month holds | `routed_text`, `wtd_diff`, `base_text` | the three Bulkley segments; the product's `period` | `period_of()` checks |
| Bulkley | Buck and Quick flows, peaks, areas | `hyd` per gauge | peak months, overshoot in May, half-peak, Jul–Mar, Jan–Apr, Jul–Aug, Quick −20…−33 % |
| Windows | `good_w`, `poor_w`, approx maxima, `worst()` | per window; worst over the poor window | approximation and source error in poor window, late-July reason |
| Scores: counts | 315, 290, 11, 279, 3,348, 33, 89, 3,226 | calibration gauges → routed → scored | `n_routed - far == n_both_gauges`; `12n - 33 - 89 == nrow(both)`; `n_zero_r == 0` |
| Scores: balance | winter range, summer bound, within | `both`'s gauge-months | `min(winter) > max abs(summer)`; `within < 50` |
| Scores: routed | spring, summer (pooled medians), `r_closer`, NSE | `both`; NSE over `both`'s gauges | `season_med` signs; May–Sep in `r_closer` |
| Period | `n_long`, `n_long_far`, period and long medians, `explained` | long-record gauges with routed flow, less far | period < 10 %, spring < −10, summer > 5, explained in (0, 0.5) |
| Limits | `m003_text`, `n003` | 08EE003 months with ≥ 10 years | contiguous months |
| Validation | provenance fields | the bundle | read from `prov`; report path from `prov$published$report` (was hardcoded) |

Prose outside inline values, fixed here: "skip every part" (duckdb skips row groups, not parts); the recipe's "seconds" (measured: 2.5 s cold, 1.1 s warm); 08EE003's windows rest on the window table's years (18), not all 19 years with months. Nothing in the set is left without a guard or a set-correct computation.
