# Code-check round 2: #101 branch diff (main...HEAD, planning/ excluded)

Reviewer: subagent, 2026-10-18, on m1 (arm64, long double = double) against the local fwapg (read-only
queries) and the live published routed parts (all 20, downloaded to a scratch dir, 404 MB).

## Findings

- **[severity: fragile (doc)]** research/discharge_publish.md:62, and issue #101's "Routed month 0" paragraph
  ("a rebuild differs from the live parts in about 8 % of routed segments' month 0"): the 8 % is the Fraser
  part's rate, generalised to the province. Measured over every live routed part (months 1-12 sorted by
  segment and month, `stats::aggregate(q_m3s ~ linear_feature_id, ., mean)` exactly as segment_output.R now
  does, compared with the published month 0 bit for bit):

  | part | routed segments | month 0 differing |
  |---|---|---|
  | 100 | 1,010,776 | 82,681 (8.2 %) |
  | 200 | 603,993 | 92,373 (15.3 %) |
  | 300 | 367,645 | 67,600 (18.4 %) |
  | 400 | 263,089 | 45,196 (17.2 %) |
  | 500 | 129,288 | 16,081 (12.4 %) |
  | 600 | 278,655 | 35,515 (12.7 %) |
  | 900 | 162,730 | 17,725 (10.9 %) |
  | 910 | 254,409 | 27,506 (10.8 %) |
  | 915 | 27,230 | 3 |
  | the other 11 (700, 905, 920-970) | 278,222 | 0 |
  | **province** | **3,377,037** | **384,680 (11.4 %)** |

  The Fraser count (82,681 of 1,010,776) is exactly right; the province-wide share is 11.4 %, not about 8 %,
  and it reaches 18 % in part 300. Largest difference 1.81 x eps relative (so "about one ulp" holds). For
  Phase 5's expectation: 9 routed parts should differ from the live build and the other 11 routed parts (with
  every balance and watershed part) stay byte-identical, i.e. "parts identical ... 58 of 67" if nothing else
  moves. Restate the share as "about 11 % of routed segments (384,680 of 3,377,037; 82,681 of 1,010,776 in the
  Fraser part), in 9 of the 20 routed parts".

- **[severity: fragile]** R/wet_segment_monthly.R:263-268 (`wet_segment_fwapg()`): the SELECT has no
  `ORDER BY`, and `wet_segment_annual()` takes `mean(v)` over each segment's months in arrival order
  (`split()` keeps row order). That is the same order dependence segment_output.R just removed, left in the
  reader whose roxygen says month 0 is "computed by the same rule as the published one", which the research
  doc now defines as summed in month order. It feeds `routed_annual()` (pcic_routed_compare.R's scores,
  segment_vignette_data.R's `src_r`). No failure today: on m1 the planner chose the primary-key index scan for
  300, 3,000 and 30,000 random ids and returned every segment's months ascending (0 out of order), and every
  consumer compares within 1e-9 or prints rounded values. But the order is a plan choice, not a guarantee (a
  bitmap heap scan or a seq scan returns heap order). `ORDER BY 1, 2` on that query makes it month order by
  construction and makes the reader's month 0 equal the published one bit for bit.

- **[severity: fragile (doc)]** research/discharge_publish.md:5 (Status): "The build report is
  `data/checks/discharge_publish_20260717.txt`: the value-checked rebuild at wet 71af15a ..., whose 67 parts
  are byte-identical to the acb820f upload." Phase 5 commits a new BUILD report to that same path whose
  identical-parts line will read about 58 of 67 (above). Phase 5 lists no update to this paragraph, so once that
  report lands the Status sentence describes a report that no longer exists at that path. (Also the reason both
  vignette data scripts will refuse, via `vd_published()`, which is the accepted #103 wait; worth saying there.)

## Checked and clean

- **aggregate() sums in row order within each group.** `aggregate.formula` -> `model.frame` (keeps rows) ->
  `aggregate.data.frame` -> `split()` (keeps within-group order) -> `mean()`. Measured: on 20,000 synthetic
  segments, `aggregate()` equals `vapply(split(q, id), mean)` in arrival order bit for bit (sorted input: equal
  to the month-ordered mean; shuffled input: differs in 5,416 of 20,000 and still equals the arrival-order mean).
  The subset at segment_output.R:155 (`rt[rt$linear_feature_id %in% ...]`) keeps order.
- **The ORDER BY is deterministic.** `(linear_feature_id, month)` is unique within a run (PK
  `(model, scenario, period, linear_feature_id, month)`), `month` is `integer`, so the sort is total and numeric.
- **Nothing else in segment_output.R depends on arrival order:** `n12` (`tabulate`), routed `runoff_mm`
  (element-wise from each row's own `q_m3s`, so month 0's `runoff_mm` moves with month 0's `q_m3s`, as the
  "routed month 0" wording covers), `order(linear_feature_id, source, month)` before writing (total key),
  `n_routed_unplaced` (count).
- **Nothing in discharge_publish.R does either:** `rt_all` (unordered) is used only through
  `wet_values_compare()`, which matches by key; `routed_micro` sums integer-valued doubles (about 1.8e14, below
  2^53, exact in any order); the derived month 0 (`rowsum()/12`) is compared within the default relative 1e-9.
- **BUILD still passes:** `routed_values` (months 1-12, tol 0, unchanged values), `routed_annual` (tol 1e-9
  relative vs a largest move of 1.81 eps), `routed_total` (months 1-12 only), `parts_as_table` (parts vs the
  rebuilt segment table, tol 0, both carry the new month 0), `balance_values`, `watershed_values`, row and pick
  counts. "parts identical to the published build" is reported, not checked (`pub_line`), so the moved routed
  parts do not fail the BUILD. The segment-table code guard (git diff since the segment report's commit over
  `R/` and `scripts/`) forces the segment_output.R rerun, since pcic_routed_lib.R and segment_output.R changed.
- **Fingerprint guard fails closed:** no `pcic.runs` row, a NULL total (empty run) or any mismatch stops;
  m1's `pcic.runs` 1951-2012 row is 40,524,444 / 3,377,037 / 178035348.248310.
- **Routed month 0 can flip a pick only at the 0.2 x boundary** within ~2 eps; not measured (needs every
  balance value), negligible, and the BUILD's pick checks compare against the rebuilt table, so they would pass
  either way.
