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

## After round 3: the enumeration above was itself incomplete

Round 3 found the mechanism one level down: each sentence's set is chosen twice, in the prose and in the code's filter, and a guard checked only the direction of a claim on the code's set. The table above asked "is the set right?" and never "does the set's own filter move the answer?", and it walked only inline values.

1. **Filter neutrality.** Every filter feeding a statistic, and whether it is correlated with the statistic:
   - `both`: dropped the balance's zero months (−100 % errors, 62 of 89 in Dec–Mar). January moved from +23 % to +11.5 %, and the winter peak from January to April. **Fixed**: scores are medians of modelled over observed, which rank a zero. The zeros are kept and counted in the prose (89, 34 in January).
   - `lp`: dropped routed zero months the same way. **Fixed** the same way.
   - `obs_mm < 1 mm`: drops 33 months. It is a property of the gauge, not of either model, so it moves both sources alike. Kept and counted.
   - `far`: the routed report's own rule. Kept, with the prose now saying the report attributes each one (no unguarded "most").
2. **Sentences with no inline value**, walked one by one:
   - "every FWA segment": now "per source it covers".
   - "freshet in the right months": removed (66 % vs 64 % peak-month match does not separate the sources).
   - "hardly a freshet": now "under half the gauge's and a month late", asserted (peak under half; peak month +1).
   - "its shares know nothing of the lake, and routing does": the lake-outlet comparison is now asserted.
   - "months add up to month 0" (balance) and "do not" (routed): both asserted.
   - "08EE003 has no complete years in 1981–2010": asserted from the daily record.
   - "monthly precipitation, temperature and evapotranspiration": `wet_share_fit()` also uses elevation and location. Corrected.
   - "a misplaced outlet scales every month alike": overstated; a wrong segment can carry another regime. Reworded to the median argument.
   - "checked every bundled published value": now "the bundled values". The data script also checks routed month 0 on the gauge segments (290, 0 differing).
   - "the fit's output held month 0 only": now written from `provenance$output_months`.

## After round 4: decide neutrality by recomputing, never by reasoning

Round 4 found that round 3 had judged the 1 mm cut neutral by argument ("moves both sources alike"). Recomputed, it moved the balance's winter medians by up to 4.5 points and its highest month from February to April, and moved routed's much less. The same reasoning-not-computing gave "moves its water into the months after it", which is true at Buck Creek but backwards for the median gauge, and "a shape error shared across the gauges", which no computation produced.

Fixes, each now a computation over the named set:
- **The 1 mm cut is removed.** No observed month is zero (the smallest is 0.08 mm, asserted `all(obs_mm > 0)`), so every ratio is defined. The scores use all 3,348 gauge-months.
- **The balance's winter claim** is stated in the words the guard checks: Dec–May each above +5 %, Jun–Nov each within ±5 %. "Highest in …" is dropped, because the top two months are 0.8 points apart.
- **Flattening** is computed at the 211 gauges that peak in May or June: the balance is below the gauge in the peak month at 72 % of them, median −15 %. The "months after it" clause is dropped.
- **Routed's shape** is given gauge by gauge over its own period: low in spring at 66 % of the 113 gauges, high in summer at 63 %, both at 40 %. The placement argument now refers to those 113 gauges.
- **`one()`** wraps the lookups that could come back empty, because `stopifnot(logical(0))` passes.

The candidate set is now every filter that feeds a statistic and every sentence that characterises one. The four filters (`far`; balance zeros, kept; routed zeros, kept; the 1 mm cut, removed) were each recomputed with and without. Each characterising sentence now quotes a number computed over the set it names, and that number is asserted.

## After round 5: every filter, with and without it (terminal)

Round 5 found a fifth filter: routed coverage. Scoring the balance only on routed's 279 gauges hid the 25 it does not reach (19 in WSC area 10, the Liard), where the balance reads −67 % to −96 % in January–March. Over all 315 gauges, "high December to May" failed (December +1.2 %). It also found that the peak month was taken from monthly volume, not flow, and that `hq()` and `smv()` could return empty or misaligned results.

Fixes:
- **Each source is scored on its own gauges.** The balance uses all 315 (3,780 gauge-months); routed uses its 279. The figure, the table and the NSE use those sets. The head-to-head ("more gauges within ±20 %") and the group table use the shared 279, and say so.
- **The balance's claim is restated as computed and asserted:** January–May +8 % to +16 %, June–December within ±5 %. The northern gauges are named, with an asserted count and winter medians.
- **Peaks are taken from flow** (mm divided by days): 243 gauges, 69 % below, median −15 %.
- **`hq()` and `smv()` assert their length**, so `stopifnot(logical(0))` cannot pass.

The complete set of filters feeding a statistic in the article, each computed with and without (round 5's measurements plus the recomputes above):

| Filter | Without it | Decision |
|---|---|---|
| far-low (11 gauges, routed only) | routed spring −21.3, summer +17.3, NSE 0.80: every claim holds | kept; the routed report's rule |
| routed coverage, applied to the balance | balance Dec +1.2, north −67 to −96 % | **removed**: the balance is scored on all 315 |
| balance zero months | Jan +23 against +11.5 | **removed**: zeros kept |
| observed < 1 mm | top month February against April | **removed**: no cut |
| peak by volume vs flow | 211 / 72 % / −15 against 243 / 69 % / −15 (now by flow) | flow |
| long-record threshold 40 / 45 / 50 years | every sign and guard holds | 40 |
| window `min_frac` 0.8 / 1.0 | identical tables | default |
| 08EE003 month rule (≥ 10 years) | May–Oct; April has 7 years, Nov 4 | kept, stated |
| shared set for head-to-head and the group table | not applicable: a comparison needs one set | kept, labelled |

No filter is left whose removal changes a sentence the article states. Every characterising sentence now quotes a number computed over the set it names, and that number is asserted. The loop ends here, on this enumeration, after five rounds.
