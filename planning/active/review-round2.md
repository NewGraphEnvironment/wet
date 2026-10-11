# Review round 2 (#58): branch diff 509419a...HEAD (d46fc87)

Round 1's fixes checked first, against the DB (read-only), the tracked report and the
bundle. Fix 2 (per-gauge attribution) holds: the annual values recomputed from
`fwa_stream_networks_discharge` match the report for all 11 far-low gauges. 08NE039 is
97.28 mm against a cut of 97.98 (0.2 x 489.88), so it is far low by a small margin, but
it is deterministic. 08KH006 has no annual value because its watershed 9040036 maps only
to the order-1 side channel it snapped to, which the annual table does not carry. The
research's lists (not low: 08KG003, 08MH141 and the four 08JA gauges; PCIC runoff:
08NE039; unresolved: 08DB013, 08DB014, 08EE028, 08KH006) match the report's rule row by
row. Fix 1 (BULK) holds: the guard can fail, and the two largest routed errors are
08EE025 (22 km2, +196 %) and 08EE028 (10 km2, -86 %). Without them, routed has 23.6 %
mean absolute error and the balance 26.1 %. Fix 4 matches `scripts/wb_stations.R`
(1981-2010, min_years 10). The fingerprint recomputed today matches the report and the
bundle. `test-vignette_data.R` passes (97). A scratch render of the vignette passes every
guard, and its rendered prose matches the bundle.

## Findings

- **[bug: false claim, fix 3 repeated one level down]** research/water_balance_method.md, #58 bullet, "Coverage" sub-bullet: "Groups with no routed flow at all are the Liard's and also the Yukon and Alsek headwaters (ATLL, JENR, SWIR, TESR, TATR), the Hay (HAYR) and the Skagit (SKGT)." The category names are right, but the group codes are an incomplete list presented as the full one.
  - Four Yukon groups (FWA code 800) with zero routed segments are missing: GLAR (Gladys River, 13,864 segments), KUSR (Kusawa River, 20,500), TUTR (Tutshi River, 30,813) and UJER (Upper Jennings River, 14,406).
  - Two Hay groups (FWA 200-893458, the Hay River's code) with zero routed segments are missing: KCHL (Kotcho Lake, 19,121) and SHEK (Shekilie River, 9,632).
  - So the list names 7 of the 13 non-Liard groups. Every other zero-coverage group is the Liard's (200-692231).
  - Query: per `watershed_group_code`, `count(DISTINCT m.linear_feature_id)` from `fwa_stream_networks_discharge_monthly` joined to `fwa_stream_networks_sp`.
  - This is the same defect as round-1 finding 3, a hand-written enumeration one level down. Either list all 13, or derive the list from the query.
  - The vignette, CLAUDE.md and the report name only categories, so they are correct.

- **[bug: overclaim in research]** research/water_balance_method.md, #58 bullets.
  - (a) The headline "...and ties fwapg's older annual table where that table had values" is not true of the scores where that table had values. At the 178 gauges the report shows annual 25.3 % against routed 28.0 % (median 16.7 against 15.4; annual closer at 54 %). It is a tie only after the 7 far-low gauges are dropped (25.0 against 25.3, 171 left). The vignette states that condition ("once the few gauges ... are set aside"). The research headline drops it.
  - (b) "Routed's whole lead is at the 112 gauges the older table never scored (coast, order 8+ rivers): routed 17.8 %, balance 23.3 %." The numbers that follow compare routed with the balance, so "lead" reads as routed's lead over the balance. That lead is not all at the 112: routed beats the balance at the 178 as well (28.0 against 30.3) and at the 171 (25.3 against 30.5, a wider gap than at the 112). If "lead" means the lead over the older annual table, say so, because the figures quoted are not that comparison.

No code defects found in `scripts/pcic_routed_lib.R`, `scripts/pcic_routed_compare.R`, `data-raw/segment_vignette_data.R`, `data-raw/segment_vignette_map.R` or the tests. Things checked: the dirty-tree guards check `system2` status; the routed-report match is an exact line comparison of commit and fingerprint; `routed_annual()` requires 12 non-null months; the annual join guards against duplicate watersheds; ids are cast to int (all are under 2^31); the coverage query cannot return zero rows unnoticed (a NULL geometry fails `st_is_empty`).
