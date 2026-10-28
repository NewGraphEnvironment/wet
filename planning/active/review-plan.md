# Plan review (Plan agent, 2026-10-28, against 0307890) and dispositions

| # | finding (short) | kind | disposition |
|---|---|---|---|
| 1 | Swift box has at most 11 extension-pool gauges (Alberta dropped); the pilot refuses below 15 | Blocker | Header already flags instead of stopping (registered efc23f1). The report says the box is below #120's floor |
| 2 | `wet_segment_daily()` returns no `pick`; `wet_flow_window()` has no `basis` arg (inferred from `doy`) | Blocker | Read `pick` from the parts with duckdb (header); record the parts' md5s (header amended) |
| 3 | Parity depends on which DB the bare PG* reaches (leak-free rows) | Blocker | Header: bare PG*, as the pilot. The gate lines exclude leak-free rows; `mx` does not depend on them |
| 4 | Count guards and fixed snow ids have no home | Gap | Maxan's stay in the parity gate; other sites report them, not assert (snow header) |
| 5 | An ungauged target row in `stations` rescales every gauge | Gap | Header amended: the target row joins only its own carry |
| 6 | Mouth segment by min measure; Gosnell drains to the Thautil; assert the area | Gap | Header already uses the min measure; amended to assert the area against chinook_sites_use.txt |
| 7 | The normal-error check needs each gauge's group | Gap | Look it up in fwa_stream_networks_sp (body) |
| 8 | Only the mean has a normal; the carried change has no interval | Gap | Header: mean only; carried bootstrap registered (set.seed(126)) |
| 9 | Compare carried with carried across the four sites | Gap | Phase 6: article compares carried at all four, extended at the three gauged |
| 10 | `first_use[[2]]` crashes with one donor | Gap | Guard in body |
| 11 | Maxan-only strings and objects | Gap | Body |
| 12 | No rule for empty snow_gauges | Gap | Snow header registers it |
| 13 | Leak-free undefined for an ungauged target | Gap | Leak-free stays a held-out sensitivity; the answer does not use it (as the pilot) |
| 14 | Maxan's source for the article | Gap | The site report for maxan (parity-gated equal to the pilot's), so the data script checks departure_site.R's md5 for all four |
| 15 | test-vignette_data.R fails on life_history_morr.csv | Ordering | Fixed |
| 16 | Probe before registering | Ordering | Headers report rather than assert per-site counts, so no number is registered unseen |
| 17 | Rerun maxan's parity last | Ordering | Phase 4 runs maxan again after the last body edit |
| 18 | Glacier cells may sit at the SWE cap at Swift | Assumption | The snow report already says where the cap binds; note in research |
| 19 | Calibration leakage is wider than shares | Assumption | Report wording: the flag marks partly-in-sample gauges, broadly |
| 20 | Gosnell's spawning tie-break is definitional | Assumption | Say so in research/chinook_sites.md |
| 21 | Byte identity at Gosnell needs unchanged parts | Assumption | Parts' md5s in the report (header amended) |
| 23 | Province map would blow the budget | Scope | Map: BC outline, boxes, targets and donors only |
| 24 | Q1 race at Gosnell? | Scope | Yes, it scores the box (header) |
| 25 | pkgdown: `articles/chinook-sites`, `title: internal`; the navbar collapses without `navbar:` | Acceptance | Phase 6 follows it and greps the built index and navbar |
| 26 | Prove the ungauged path against Maxan | Acceptance | Phase 4: run the ungauged carry at 08EE018's coordinates and area and compare with mx$a |
| — | Stale plan text (Owen, env var) | — | Fixed |
