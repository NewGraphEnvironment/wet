# Code-check round 3: branch 76-order-wet-ws-fetch-rows-so-province-runs vs 47ed65e

## Checklist read

- `code-check.md`: read the prose of all 14 H3s under `## Mechanisms` (table rows skipped). Did not read the other 23 H3s in full (Rules that stand alone, Security, Spreadsheets and PDFs); checked them against the index only, and none applies to this diff.
- `code-check-r.md`: read 7 sections in full: "Postgres row order is never fixed unless the query fixes it…", "A range total taken as the difference of two large running totals…", "`sort()` and `order()` collate by `LC_COLLATE`…", "`identical(-0, 0)` is TRUE…", "`expect_false(identical(x, y))` cannot fail…", "A database driver's value is not a base R type…", "`identical()` on two reader results tests the reader…". Did not read the other 104 in full.
- `code-check-shell.md`: read 0 sections in full. The diff has no shell code, and the only Rscript entry point is `commandArgs(trailingOnly = TRUE)`, not `-e`. Did not read 67.
- `code-check-spatial.md`: read 3 sections in full: "A Freshwater Atlas main stem's downstream end…", "FWA `upstream_route_measure` misses the next segment's start", "A name is not a key…". Did not read 90.

## Findings

- **[severity: fragile]** `R/wet_station_snap.R:126-128` and `research/water_balance_method.md:229`: the new tie-break on `linear_feature_id` cannot see the tie it is written for, because fwapg resolves it first by row order.
  - The new comment says "a tie (two segments meeting at the nearest node, in one watershed) does not fall to the candidates' fetch order". The research line says "an exact tie between two candidate segments goes to the lower `linear_feature_id` since #76, no longer to the database's row order".
  - The candidates come from `whse_basemapping.fwa_indexpoint()`. Its body (read from the live fwapg) is `SELECT DISTINCT ON (blue_line_key) … ORDER BY blue_line_key, distance_to_stream`, which ends on a column that is not unique within a blue line. When two consecutive segments of one stream meet at the node nearest the gauge, they share `blue_line_key` and have bit-identical `ST_Distance`. That is the common form of the tie the comment names. DISTINCT ON keeps whichever of the two the plan reaches first, so only one ever reaches `wet_snap_pick()`.
  - Measured on the live fwapg against `data/wb/stations_20260717.rds`: for 2 of the 352 calibration stations, the picked segment's blue line has exactly that tie, and the two segments lie in different watersheds:
    - 08EC013: blue line 360886970, segments 5086038 and 5086970, both at 39.330232870264837 m. Kept: 5086970, watershed 7660693, 6726.895 km², ratio 0.99969. Dropped: 5086038, watershed 7660731, 6731.004 km², ratio about 1.00030.
    - 08KD006: blue line 356360570, segments 703862843 and 703862887, both at 67.563694090612884 m. Watersheds 8483126 and 7713002.
  - For 08EC013 the dropped segment scores better: |log ratio| is 3.0e-4 against 3.1e-4. If both reached R, `wet_snap_pick()` would choose it on score alone, before any tie-break. So under another physical row order, a stations rebuild can snap this gauge to a different watershed.
  - So the research sentence overstates what #76 fixed: the stations rebuild still depends on PostgreSQL row order, and the cause sits inside fwapg's function, not in wet.
  - This is the convention's first Postgres row-order shape (`code-check-r.md`): "Before trusting a 'deterministic tiebreak' comment, check that its column can actually differ between the candidates it has to separate."
  - Remedy:
    - Surface it in fwapg (end the DISTINCT ON ordering on `linear_feature_id`, and the outer `ORDER BY distance_to_stream LIMIT $3` too, whose rounded distances can tie at the cut) rather than working around it in wet.
    - Meanwhile, narrow the wet comment and the research sentence to ties between segments that are both returned as candidates, and name the in-fwapg pick as unresolved.
  - No current output is wrong. The shipped stations file is what it is; only a rebuild is affected.

## The round-2 mechanism and where it reaches

Mechanism: a comparison between two runs that assumed the same `watershed_feature_id` set means the same rows. Id equality was taken for content equality, so the A/B varied more than the one input it claimed to vary (order), and an input difference could read as an order difference.

Every place in this diff where that assumption could act:

- **`scripts/wb_upstream_order.R` (the round-2 fix).** Correct now. `b <- a[match(id_b, a$watershed_feature_id), ]` carries only run 2's order, and codes, areas and `s` all come from run 1. The irregular pairs come from a third source (live fwapg), but the same `irr` object goes to both sides, so it cannot confound the comparison. Two consequences, neither a defect:
  - It fails loudly, with a message that does not name the cause, when the live fwapg's polygons no longer match run 1's or when it is given a reduced bundle. Measured on this machine's reduced bundles (`_pre16/962a9cc2c4` against `e675918817`): it stops in 4 s with `irregular_pairs$id_up must be irregular polygons in ws`. The header already says it needs whole basins.
  - Since `wet_upstream_sums()` now sorts internally, the replay passes by construction unless that sort regresses. It is a regression check of the current code on real orders, which is how CLAUDE.md and the research note word it ("replays … through the current sums"). It is not evidence that two runs agree, and neither file claims that.
- **`scripts/wb_upstream_identity.R`.** Compares a set-aside run with a new one, under tolerance, on purpose: inputs are meant to differ there. Only comments changed, and they are accurate. (It can only compare a pre-snow run with a snow run, so it cannot itself compare two post-#76 runs; the docs do not claim it does.)
- **The `"925"` fwapg test.** `ws` and `irr` both come from one fetch and are permuted, so the rows are identical by construction. Sound.
- **The `wet_ws_sample()` order test and the snap tie test.** Both permute one fixture with ids carried along. Sound.
- **The stations-rebuild sentence in research.** This is where a version of the assumption survives: "the candidate set is fixed, so only the R-side order mattered". It is the finding above.

## Verified (no issue)

- **Restored the defects in a scratch copy** (old R/ at 47ed65e with the new tests):
  - Old code fails the ws-order test (2), the irregular-pairs-order test (2), the fwapg 925 test (1) and the snap tie test (1).
  - New code passes all three files: 81, 20 and 22 expectations, 0 failed, 0 errors, 0 skipped. The fwapg test ran against the live database.
- **Mutated each ordering line of the new code separately:**
  - Removing the `keep` reorder reddens only "row order of irregular_pairs".
  - Dropping the id tie-break in `order(kb, …)` reddens "row order of ws" and the 925 test.
  - So each line has a named red arm.
- **Every new `ORDER BY` ends on a unique key** (counted on the live fwapg):
  - `fwa_bcboundary.bcboundary_id` exists: 28,001 rows, 28,001 distinct.
  - `fwa_streams_watersheds_lut`, `fwa_stream_networks_sp` and `fwa_stream_networks_discharge` are unique on `linear_feature_id`, so the mad scripts' `ORDER BY s.linear_feature_id` is unique.
  - The pair queries order on (a, b) ids, which are unique pairs.
- **The rest of the province path holds no other row-order dependence:**
  - The `codes` and `groups` queries are ordered or are aggregates.
  - `need` is sorted, so the column order of `vals` is fixed.
  - `wet_upstream_means()` is elementwise.
  - The segment-tree build and queries depend only on the sorted keys.

## Clean otherwise

No other bugs, security issues or data-loss risks found in the diff.
