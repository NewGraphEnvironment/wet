# Review: #43 Phase 5 staged diff

Reviewer, 2026-10-06. Method: every number in the research, NEWS and CLAUDE.md hunks checked against `data/checks/*_20260717.txt`, `planning/active/findings.md` and `git show 94a24ac:data/checks/wb_output_20260717.txt`. The vignette was checked by computing from the staged `inst/vignette-data/segment_values.rds` and by rendering the staged tree in a temp copy (`pkgload::load_all()` then `rmarkdown::render()`). The render passed: every `stopifnot`, the named-on-map guard and the 1600-word cap all held.

## What checks out

- Research "Refit" section and NEWS: 336 vs 309, 315 (29 new, 4 dropped), 209 / 30.90 / 31.18, 30.72 / 30.69, override 0.1 and the 0.77 / 0.68 / 0.64 / 0.93 ratios (the 94a24ac report), 110 / 39 / 46.5 / 80.2, bootstrap +9.06 to +62.27, 43.5 / 41.6 / 55.3, 27.5 / 30.7 / 17.6, and every major-river ratio. #47's title matches.
- CLAUDE.md HYDAT bullets: `wb_shipped_release`, the `WET_HYDAT` vs `VERSION` check (`wb_hydat()`), `WET_AET_CARRY`, `wb_aet_compare.R` refusing any release other than 20251014, and the two decision files hashed in `wb_score_md5.R:32`.
- Vignette SALR paragraph. Computed: wb_err +2.3 / +2.7 / +18.0 / +25.8 / +24.3; close = 08JE004 and 08KC003; far = 07ED001 and 08JE001 (wb_share 0.13); outlet share 0.44. Every guard holds and each can fail.
- `ga$far` is safe across the reorder. It is a column, so `order()` carries it, and the prose reads it only through `sum()` and logical indexing on the same frame. `outlet` is a separate frame taken before the reorder. `close` is reassigned after it.
- No "290", "mildly optimistic" or "passes its gate" remains in the vignette.

## Findings

1. **research/water_balance_method.md:66-72 (the SALR bullet under "What the numbers say") contradicts the shipped data.** It says the held-out balance error is "+6 % to +38 %", that at the three large basins "the two share it, with the balance's share 28–52 %", and that at 08KC001 it is "+38 % against −25 %".
   - The staged rds gives +2 % to +26 %. The balance's share is 0.13 and 0.13 at 07ED001 and 08JE001, and 0.44 at the outlet, where it is +26 % against −25 %.
   - The vignette dropped the `0.25 < wb_share[!close] < 0.75` guard because the new fit breaks it, and its prose now says the gap at the two far gauges is fwapg's. The research text still asserts the old claim, with no label saying it is the 2025-10-14 fit.
   - The bullet cites the vignette as its producer, so a reader will expect the two to agree.

2. **research/water_balance_method.md:76-80 (the #39 bullet) is the old fit's numbers, and it still says "mildly optimistic (above)".**
   - Computed from the staged rds: 201 gauges in coverage (not 186). fwapg has a value at 183 (not 168), where the MAE is 30.3 % against 25.3 % (not 30.5 against 25.5).
   - By basin: Peace (23) 20.6 against 20.7, now a tie (stated as 19.6 against 14.2). Fraser (81) 29.7 against 26.9. Columbia (79) 33.7 against 25.0. The 18 dropped gauges score 14.0 % (not 13.3).
   - "out of sample and mildly optimistic (above)" contradicts the caveat this diff retires three paragraphs earlier, at line 59.
   - The gap is 5.03 again, by coincidence, so the rule sentence survives. Everything else needs either a "(2025-10-14 fit)" label or new numbers.

3. **research/water_balance_method.md:3 (header Status) and research/README.md:9 (the index row) still give the shipped model as 27.7 % (31.2 % headwater) at 290 stations.** What ships is 27.5 % (30.7 %) at 315. The index row does not mention #43. The header's Issues list was updated in this diff but its Status sentence was not.

4. **The "headwater gauges this release drops" claim is wrong as worded.** It appears at research/water_balance_method.md, "The old gate had passed through the headwater gauges this release drops", and at findings.md:103.
   - The old fit had 218 headwater gauges and the common headwater set is 209, so 9 old headwater gauges sit outside it. Only 4 gauges were dropped in total.
   - The arithmetic: the new fit has 238 headwater gauges, 28 of them new-only (from `v$skill$nesting` against the accept report's new-only list). That leaves 210 common gauges headwater in the new fit, so 1 common gauge flipped from nested to headwater. Old: 218 = 209 + y + d, with d ≤ 4 dropped headwater gauges, so y ≥ 5.
   - So at least 5 of the 9 gauges behind the old gate's pass are still in the fit, and are now nested under new upstream gauges.
   - Suggested wording: "the 9 old headwater gauges outside the common set: at most 4 dropped, the rest now nested under new gauges".

5. **CLAUDE.md is stale outside the edited hunk, and the diff touches the file.**
   - :36. The vignette paragraph says "maps held-out skill at the 290 gauges" (now 315). It says the article "recommends the open water balance everywhere", but since #42 it compares the two in a table. It says the map script "reads `data/wb/stations.rds`", but `segment_vignette_map.R:95` now reads `stations_<shipped>.rds`.
   - :38. It still refers to "the open pooled-zone decision", which is now settled.
   - :25. It still describes `wb_aet_compare.R` then `wb_validate.R <winner>` as the way "to write the shipped fit". For the shipped 20260717 fit, `wb_aet_compare.R` refuses to run and the AET is carried. The pipeline list also omits `wb_fit_accept.R` and `wb_pooled_test.R`.
   - :26. It gives the output path as `data/wb/<key>/output/`, but `wb_output.R` writes `<key>/fit_<release>/output/`.
   - The new bullets name `WET_HYDAT` but not `WET_HYDAT_RELEASE`, which is what selects `fit_20251014` (`wb_release()`). Without it a reader cannot follow "`wb_aet_compare.R` runs only there".

6. **vignettes/segment-discharge.Rmd:714 and 724-729: the new Limits bullet's main claims have no guard that can fail.**
   - `isTRUE(prov$keep_adjust)` and `identical(prov$pooled_variant, "none")` cover "kept" and "get none". They do not cover "on headwater gauges it ties raw" or "without it the large rivers … read well below their gauges".
   - A future fit whose adjustment passes the gate cleanly would keep `keep_adjust` TRUE, so the "close call" and "kept because" text would render unchallenged.
   - The rds carries neither the gate numbers nor whether an override was used. Recording, say, `prov$adjust_override` (or the headwater adjusted and raw MAE) in `segment_vignette_data.R` and asserting it would make the bullet checkable. The bullet's title says "small basins", but the gate it describes is on headwater gauges, which run past 10,000 km².

7. **README.md:9 and :41 still say the balance is "fitted at 290 HYDAT gauges" and has "out-of-sample skill at 290 gauges".** The article now shows 315.

8. **tests/testthat/test-vignette_data.R:55: the test title still reads "the 290 gauges"** while the assertion is now 315. This is cosmetic, but a failure message would name the wrong count.

Minor: the research "Refit" header cites `planning/archive/2026-10-issue-43-*/findings.md`, which does not exist until `/planning-archive` runs. The "Pooled zones, and an open decision" heading at line 55 still says "open".

Findings "Decision 2" against what shipped: consistent. The 0.1 tolerance, the hashed override, the pooled test running on fit_20260717 and #47 as the follow-up all match the validation report and the scripts. Its "0.86–1.17" is the old fit's range, cited as the evidence at decision time. That is fine as a record; the shipped range is 0.81–1.13.
