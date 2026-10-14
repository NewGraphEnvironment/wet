## Outcome

Added `wet_segment_monthly()`, which reads flow per FWA segment and source in `wet_station_monthly()`'s shape (`linear_feature_id, month, q_m3s, source`; a missing segment is 13 NA rows), and `wet_flow_window()`, which turns monthly (later daily) means into mean flow over month-day windows with a `basis` column. At the plan gate the reader got two stores. The default is the published product: Postgres after `wet_db_load()`, or the parquet parts through duckdb. `from = "fwapg"` is an opt-in for fwapg's routed table, because `scripts/pcic_routed_compare.R` scores that table before a publish and so cannot read the publish. `pcic_gridded` was left out. One internal lookup (`wet_segment_sources()`) maps sources to tables. Callers switched: `routed_annual()` (both the compare and the segment vignette data use it), the monthly vignette data script's recipe check, and the monthly article's read and windows.

What was learned:
- The fixture's parquet parts cannot ship, because their tarball paths exceed 100 bytes, so the reader's example is `\dontrun{}`.
- The article's observed months must stay keyed per window, because each window has its own years. Pooling them per station would have moved "27 %" to 26 % (plan review).
- Twice, a presence check written for its logical result scanned the 100M-row Postgres table: first a `DISTINCT`, then an `EXISTS` whose source sits behind the other source's rows in heap order, since `wet_db_load()` appends parts in catalog order. Only a walk of the primary key's `(forcing, source)` pairs with `ORDER BY … LIMIT 1` seeks is independent of heap order. Code-check round 3 named the mechanism (relying on physical properties of a store the reader neither creates nor checks) and enumerated ten places it reaches.

## Measurement

- **Published parts over HTTPS:** one segment took 3.3 s with its watershed group named and 27 s without. A random ID falls inside about 131 of the 507 row groups' ID ranges, so many IDs with no group read nearly all 1.8 GB. This is why `groups` exists (`research/discharge_publish.md`, "Postgres").
- **Routed month 0, R `mean()` against the old Postgres `avg()`:** equal to within 6.8e-13 m³/s on 20,000 segments, with NA in the same places. The tracked `data/checks/pcic_routed_compare_20260717.txt` reproduced except for its wet-commit line, on two reruns (at 835b12e and 2a3a756). The tracked copy was kept.
- **Monthly bundle:** regenerated on the machine that built it. `segments`, `gauges` and `period` are identical; provenance differs only in `built` and `wet_commit`. Rendered before and after, the article's window table and every inline number are identical.
- **Presence check on a 9.75M-row scratch table** with the same key and load order:

  | check | time | plan |
  |---|---|---|
  | `EXISTS` on scenario and source | 389 ms | seq scan |
  | recursive CTE over forcing, `EXISTS` per forcing | 1,199 ms | inner seq scan |
  | `EXISTS` per forcing, literal values | 894 ms | seq scan |
  | walk of `(forcing, source)` pairs | 1.2 ms | index seeks |
  | walk, unloaded scenario | 0.6 ms | index seeks |

  The walk shipped.
- **Code-check:** three rounds. Round 1 found 1 issue, round 2 found 2 (one inside round 1's fix), and round 3 was clean, with the enumeration. A plan review ran before them and gave 12 findings.

Closed by: PR (see branch `59-per-segment-flow-wet-segment-monthly-and`)
