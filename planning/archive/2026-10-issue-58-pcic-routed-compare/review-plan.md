# Plan review (#58), Plan agent, 2026-10-09

## Review of planning/active/task_plan.md (#58)

Most important first: **a parallel session is rewriting the routed table right now.** At about 15:20 UTC on 2026-10-09, `pg_stat_activity` showed active `INSERT INTO whse_basemapping.fwa_stream_networks_discharge_monthly` and `CREATE TEMP TABLE pcic_segments` queries. `fwapg.blk_paths`, `pcic_candidates` and `pcic_fwa_crosswalk` had been analysed minutes earlier. During my review the table went from 199 groups to 34 with values. My gauge numbers below come from the full table just before it was dropped.

Since the plan was written, Phase 1 and part of Phase 4 have landed (commits 4c32936, 9e46930, 5c3baf3), so I checked that code too.

### Blocker
1. **Phase 2 cannot be isolated by a worktree (task_plan.md:36-38).** Both builds write to the same database: the routed table, `pcic_fwa_crosswalk` and `fwapg.pcic_*`. The job drops the table, then rebuilds it with `xargs -P 4` over all groups (pinned `pcic_crosswalk.sh`:149-157), so for hours it is missing or partial. A one-off `pg_stat_activity` check is not enough. The fix needs the user to agree a write window with the other session. Also:
   - keep the job's `fwa_stream_networks_discharge_monthly.csv.gz` export (with its sha256) so the pinned build can be reloaded after the other session overwrites it;
   - run the map script, the data script and the report back to back.
2. **Phase 1's findings now point at a table that no longer exists.** The 24.1 % run (findings.md, Phase 1 section) cannot be re-run. The untracked `data/checks/pcic_routed_compare_20260717.txt` says "built … at 4929c8c", which is a guess. It must not be committed.
3. **Vignette checks that will break:**
   - `segment-discharge.Rmd:188`: `stopifnot(all(!is.na(both$basin)))` fails. `basin_of` (105-111) only knows Peace, Fraser and Columbia, and 94 of the 290 routed gauges are Coast (08C–08H). The vignette cannot source `scripts/`, so `routed_basin()` cannot be reused there. Store `basin` in `skill` in data-raw.
   - `Rmd:197-201`: `dropped` and `o8 <- prov$fwapg_order8` error out, because `fwapg_order8` no longer exists. `dropped` is now about 5 small 08M/08N gauges, so the median-area and MAE checks will probably fail.
   - `Rmd:483`, `537` and `588` use `mad_pcic_m3s`, which 5c3baf3 removed from `segments`. The ratio, the SALR map and the limits check all error.
4. **A silent trap at `Rmd:612`.** `stopifnot(..., prov$fwapg_discharge_rows[["BULK"]] == 0)` still passes, because it reads the annual table. Meanwhile the prose at 657-658 ("outside PCIC's coverage") becomes false. Replace it with a routed-coverage check on BULK.

### Gap
5. **11 of the 290 gauges read at least 80 % low on their snapped segment.** They are about 3.5 points of the routed MAE.
   - Side channels: 08KG003 and 08MH141 (taking the maximum flow in the gauge's watershed fixes both) and 08KH006 Quesnel (`edge_type` 1100; the maximum does not fix it).
   - Nechako-reservoir lakes: 08JA014, 08JA015, 08JA016 and 08JA028 (Eutsuk outlet, 2,554 km² reading 0.02 m³/s).
   - Ansedagan 08DB013 (a known fwapg#8 case), plus 08DB014, 08EE028 and 08NE039.
   - wet's snap (`R/wet_station_snap.R`) picks a candidate by its lookup watershed area, and the fwapg README:105 says a side channel gets its main river's area. So snapping to a side channel is a built-in risk, and the README:161 says a side channel carries only its own flow.
   - The plan has no rule for this. Before reading the pinned numbers, decide to keep the snapped segment as the headline (that is what #57 did). Then list these gauges in the report and give a sensitivity line, either a main-stem rule or excluding them. `fwapg.pcic_qa_gauges` can separate crosswalk error from PCIC model error.
6. **BULK gets a routed column (plan line 70), and its gauges include the routed table's extremes in BULK.** 08EE028 reads −86 % and 08EE025 reads +196 %, the largest positive routed error anywhere. The BULK prose has to deal with them.
7. **Phase 4 (plan line 53) says "routed coverage counts in place of `fwapg_*`", but `fwapg_discharge_rows` must stay** for the parity checks: test:65, Rmd:744, data-raw:213. 5c3baf3 does keep it; fix the plan's wording.
8. **Score set mismatch.** The report scores every gauge whose segment has routed flow (290). If the vignette keeps the `in_routed & !is.na(...)` pattern from Rmd:185, it scores 289: 08OB002 is in MORI, a group with less than half its segments routed. Score on `!is.na(routed_mm)` so the vignette, research and report all say 290.
9. **The map script has no fingerprint guard (`segment_vignette_map.R`:120-127).** If the table is rebuilt between the two data-raw runs, the outline drifts, and the test at test:103 only catches that at group level. Record and assert the fingerprint there too.
10. **The plan does not list these vignette lines:**
    - glossary 155-160: PCIC "covers the Peace, Fraser and Columbia", and the link goes to smnorris/fwapg while the routed table is in the NewGraphEnvironment fork;
    - the intro "over 1981–2010" (117);
    - the table rows "What it is", "Grid" (routed values are on PCIC sub-basins, not the 0.0625° grid) and "Open to rebuild" (213-221);
    - the `models` caption (251-252), the axis and annotation labels (284, 287);
    - the guidance (258-263), `cap_prov` (342-344), the Limits "Coverage" bullet (720-721) and "Cached inputs" (815-821).
11. **"fwapg" will mean two things.** "How it is built" keeps "fwapg" for the annual table, and the glossary (plan line 71) gives it to the routed table. Use a separate name, such as "routed PCIC".
12. **CLAUDE.md:54-55 still describe PCIC coverage as Peace/Fraser/Columbia and channel-scale as "Coast + Fraser now".** Phase 6 only touches line 42.

### Ordering
13. Phase 3 needs SALR routed numbers "from Phase 5's data" (plan line 45), but it comes before the Phase 4 rebuild. Move the SALR bullet after Phase 4.
14. data-raw calls `routed_commit()` (around line 67) only after `mad_parity.R`, which takes minutes. Check `WET_FWAPG_COMMIT` and the fingerprint first.
15. The pinned job needs `DATABASE_URL` (script:7). It also calls the PCIC API for `numberMatched` on every run (script:20), so a "cached" run still needs network access and can fetch new pages.

### Assumption
16. **The fingerprint may not compare reliably.** `sum(q_m3s)` over 40.5 M float8 rows, printed `%.3f` and compared as a string (data-raw around line 195), can change in the last digits under parallel aggregation. Use `sum(round(q_m3s::numeric, 6))` or fewer decimals.
17. Nothing checks `WET_FWAPG_COMMIT`. Tie it to the export's sha256, or to a `git rev-parse` of the worktree.
18. **Units are fine.** Observed and routed are both divided by the same `upstream_area_m2` (wb_cv_lib.R:43-45, pcic_routed_lib.R:51), so the error is just q_routed / q_obs − 1 and the area choice cancels. Weighting months by their length changes q by 0.996–1.009 (median 1.003; MAE 24.07 against 24.08), so the "unweighted" caveat is enough. The real non-like-for-like parts are the period (1951–2012 against each gauge's 1981–2010 record) and PCIC being partly in-sample.
19. **The gauge's segment is in the right place.** For all 315 gauges, the segment's lookup watershed equals `sk$watershed_feature_id`. Routed q on a segment is at the downstream end of its watershed area (README:72-80), the same area observed runoff is spread over. The exception is side channels (item 5).

### Scope
20. The plan and Phase 6 still name `data/checks/pcic_routed_compare.txt` (plan lines 39 and 75). The report is now `pcic_routed_compare_20260717.txt`.
21. The guidance will steer users to routed PCIC. CLAUDE.md:80 ("yardsticks, not inputs to publish") is #57's to change, but the vignette's wording should not get ahead of it.

### Acceptance
22. **"Largest rivers is now covered" (plan line 66) is unchecked.** 5c3baf3 only asserts `routed_large$segments > 0`, with no lower bound on how many are valued. Order-10 segments had 0 routed values in the partial table, and the README caveats (Okanagan/Kettle flow missing from the BC Columbia, Spillimacheen +54 %) limit the claim. Add an explicit assertion, such as valued share > 0.9.
23. **The station-naming guard (Rmd:824-835) blocks naming outliers in prose.** If the prose names a failing gauge such as 08KH006 or 08JA028, which no map draws, the build stops.
24. **The 1,600-word prose cap (Rmd:846) is a real risk** once routed columns and caveats are added. Put "word count under cap" in Validation.
25. **#57 does not reproduce exactly** (24.1 against 24.4 MAE; bias +0.2 against −0.1). The plan's "should reproduce" (line 33) had no tolerance. Set one, for example ±0.5 points, and state that the table changed.

### Critical files
- /Users/airvine/Projects/repo/wet/vignettes/segment-discharge.Rmd (lines 105-262, 483-541, 588, 612, 657, 720, 815)
- /Users/airvine/Projects/repo/wet/data-raw/segment_vignette_data.R
- /Users/airvine/Projects/repo/wet/data-raw/segment_vignette_map.R
- /Users/airvine/Projects/repo/wet/scripts/pcic_routed_lib.R
- /Users/airvine/Projects/repo/wet/tests/testthat/test-vignette_data.R
