# Enumeration: every line wb_aet_compare.R's report prints, against what it computes (after P2-3 round 2)

Round 2 found a defect inside round 1's fix: a stale restatement of the relabelled counts in findings.md. So only an enumeration ends the loop. The mechanism is a label restated away from the expression it describes. The candidate set is every printed line of the report (the `writeLines` block, 29 lines), plus the four count lines in wb_province.R and their restatements in planning/.

| Report line | Prints | Computed from | OK |
|---|---|---|---|
| province run / stations / folds | key, n, headwater n, nested n, folds | `nrow(cal)`, `nesting == / != "headwater"`, `unique(cal$fold)` | yes |
| Variants (4 lines) | definitions incl. mod16 fill-by-area, cmod16 = max(CGIAR, mod16) | wb_province.R blend and `max(aet_yr, aet_mod16)` | yes |
| Monthly shares on CGIAR | behaviour | unchanged wb_validate share fit | yes |
| Stage 1 rule (a)-(d) | thresholds, cgiar incumbent | `decide(top, "cgiar", eligible)`, `pass_d` against `cg$hw` | yes |
| As-shipped table + tags | 10 rows; fu15/20/35 "(transparency)", mod16/cmod16 "(stage 2)" | `top`, `top$gate` | yes (tags fixed, round 2) |
| (a)-(c) choose | stage 1 | `winner_top` | yes |
| (d) nested, stage 1 | metrics, cgiar as shipped, pass/fail | `ns1`, `cg$hw`, `pass_d` | yes |
| folds, stage 1 | counts over cgiar, lc, tc, fu, cfu | `tab1` | yes |
| Stage 1 winner (reproduces #15) | winner1 | printed only past the reproduction `stop()` | yes |
| Stage 2 rule | inc, candidates, (d) vs inc as shipped | `decide(top, inc, eligible2)`, `pass_d2` | yes |
| Disclosed | period, gap codes (user guide), post-selection lean | periods: climr/TerraClimate 1981-2010 (their fetchers), CGIAR WorldClim 2.1 ~1970-2000 (research §7.3), MOD16 `years`; codes: MOD16 v6.1 user guide | **no → fixed, round 3** (said "the rest 1981-2010"; it was checked against the plan it was copied from) |
| MOD16 cover counts | mod16_whole, cfu_whole, cfu_part, cfu_cell_equivalents | wb_province.R: `fr == 1`, `fr == 0`, `0 < fr < 1`, `sum(1 - fr)` on the mask | yes (relabelled, round 1) |
| (a)-(c) choose, stage 2 | winner_top2 | `decide(top, inc, eligible2)` | yes |
| (d) nested, stage 2 | ns2 metrics, inc as shipped, pass/fail | `ns2`, `inc_row$hw`, `pass_d2` | yes |
| folds, stage 2 | counts over inc, mod16, cmod16 | `tab2` | yes |
| WINNER | final | `winner` (inc unless stage 2 (a)-(c) and (d) pass) | yes |
| inc alone, nested | ns_inc | `nested_select(function(m) inc)` | yes |
| Two-stage nested + folds | ns12, tab12 over all 7 | `nested_select(v1 then stage 2)` | yes |
| Upstream MOD16 share | min, quartiles, max over 290 | `cal$frac_mod16` (upstream mean of the frac layer) | yes |
| Headwater MAE, basins >= 80 % MOD16 | n, and MAE per inc/mod16/cmod16 | `hi16 & obs >= 10`, same mask for n and mean | yes |
| Detail rows + Greata | zones, < 100 km2, Greata upstream AET/raw/shipped | `zone_mean`, `small_mae`, `wet_wb_aet_cols()` | yes |

Restatements outside the script: `findings.md` smoke bullet (fixed, round 2). `task_plan.md` Phase 2 ("counts of fully and partly filled cells") is consistent with the four counts. The inputs manifest granule row now counts only the granules `wet_mod16_aet()` reads (`wet_mod16_local()` on its tiles × 2001-2020: 180, no NA).
