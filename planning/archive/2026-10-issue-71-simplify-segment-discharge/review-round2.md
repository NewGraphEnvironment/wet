# Code-check round 2 (#71), branch diff 6be3e11...HEAD

Reviewer: subagent, read-only on the repo (findings file excepted). Probes ran against local fwapg (127.0.0.1) and the bundled `.rds` files. The article was rendered from a copy in the scratchpad under `load_all()`, and `tests/testthat/test-vignette_data.R` was run with `NOT_CRAN=true` (7 blocks, 0 failed, 0 error).

## Findings

- **[severity: bug, the article states what its data do not support]** vignettes/segment-discharge.Rmd:155-157, "Off that line, on a side channel, routed PCIC is kept however low it is". The sentence equates "off its watershed's own line" with side channels. The data say otherwise. I probed the 72,242 segments that have both sources and lie off their own line (`routed_own_line_sql`), which is the report's own `own_line FALSE` count (data/checks/segment_output_20260717.txt:57):
  - 43,869 (61 %) are secondary-flow lines (edge types 1100, 1150, 1300, 1350, 2300).
  - 28,373 (39 %) are connection lines: 1450 (21,677), 1410 network connectors (4,616), 1475 lake arms (2,012), plus a few 1200, 1400, 1000 and 1050.

  `R/wet_source_pick.R:10-14`, `scripts/pcic_routed_lib.R:84-86`, the segment report (:7-8) and CLAUDE.md all list side channels and connectors. So the article's definition of the default leaves out two in five of the segments the exception covers. A reader with a lake connector whose routed flow is far low would expect the balance there and gets routed. Nothing guards this sentence. It is round 1's second finding one axis over: the same kind of segment, a connection line, now left out of the definition of the exception instead of being misnamed among the gaps.

  The line this branch rewrote in research/water_balance_method.md:83 has the same narrowing ("a side channel keeps routed").

  Fix: name both, e.g. "Off that line (side channels and connection lines, which take another line's balance through the lookup), routed PCIC is kept however low it is". If a count is wanted, it can come from the report's `own_line FALSE` row.

## Checked and clean (no finding)

- **Round-1 fix 1:** the cause clause is gone. The Nechako sentence ("routed flow is far below the balance's", fwapg#24) is measured: 98 % from the map's region counts, and the report's flip rate is 97-99 % per group. fwapg#24's title is about the Nechako Reservoir outlets being unplaced.
- **Round-1 fix 2:** the edge types in `connector_edges` (1100, 1150, 1300, 1350, 1400, 1450) are all secondary-flow or connection construction lines (`fwa_edge_type_codes`). By edge type, the no-lut segments are 1400 207,970, 1450 72,100, 1100 50,280, 1350 33,152, 1300 1,810 and 1150 1,050. That totals 366,362, which equals the bundled `no_lut_connector`. That is 97.8 % of `neither`, so both the prose and the guard hold on the property itself, not on a proxy.
- **Round-1 fix 3:** `published$built` comes from the manifest's `built` (`wet_catalog()` attribute), which `wet_manifest_write()` stamps on every publish. Both bundles carry 2026-10-13T03:28:20Z. Both the vignette (:44) and the test (:115) compare it.
- **The map bundle's recorded commit:** it records 5024265. Since then the map script has changed only in comments and braces, so that commit rebuilds the bundle. The values bundle records e7aea30, and HEAD differs from it only in the `.rds` and the review file.
- **Liard:** fwapg's routed table has 0 segments under the Liard River's wscode, so "routed PCIC has none" holds. 19 of the 25 gauges without routed flow are 10A/10B/10C, all Liard basin.
- **Counts:** `n_both_src` = 3,374,133, which equals the report's "both sources". The picks, `neither` and `far_low` match the report and the reader rows.
- **The rendered article:** it builds, with no guard failing. The map shows the Liard and the Nechako in the balance's colour, the legend covers every drawn class, and the caption's 6 % rounds the same with or without the 1,557 undrawn `none` segments.
- **Registry and other readers:** the removed registry layers are referenced nowhere else. No other file reads `gauges_salr`, and monthly-flow.Rmd reads only `flow_source`. The chunk labels are unique. The `gh()` link targets are tracked on main.
- **`wet_db_load(conn, cat)`:** matches the signature, with `scenario = "historical"` as the default.
