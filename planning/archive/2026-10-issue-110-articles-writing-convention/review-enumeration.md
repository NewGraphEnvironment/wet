# Closing enumeration of the #110 branch review (session, 2026-10-23 23:25 UTC)

Round 4 enumerated every claim sentence the branch added (47 sentences: 40 hold, 4 fail, 3 judgement; `review-round4.md`). The fix commit after it changed seven sentences: six rendered, one an unrendered comment. Each was checked here against its evidence:

| sentence (file) | evidence | verdict |
|---|---|---|
| Routed PCIC's and the balance's flows are the published product's, read on the bundle date from the build at `wet` commit (monthly-flow) | `prov$built`, `prov$published$wet_commit`; the bundle script reads the published parts | holds |
| Routed PCIC's months were held equal to the routed table in `fwapg` (monthly-flow) | `prov$published_check` row 1: 3,480 compared, 0 differ | holds |
| Its days were routed again from the sub-basin days there (monthly-flow) | row 6: 1,095 compared (3 segments × 365), 0 differ | holds |
| The balance's months and days were made again from the fit at `prov$shape_stations` (monthly-flow) | rows 5 and 7: 26 = 2 × 13 and 730 = 2 × 365; `shape_stations` = 08EE004, 08EE013 | holds |
| The build's own check of its published flows covers the rest (monthly-flow) | round 4: the report's compared counts equal the published rows of every dataset | holds |
| The gauges' daily flows are HYDAT's (monthly-flow) | monthly-flow.Rmd:204, `dh <- daily[daily$source == "hydat", ]`; every later use goes through `dh` | holds |
| The scores compare routed PCIC as published, and the balance held out by its fit, with HYDAT's observed runoff (monthly-flow) | data-raw/monthly_vignette_data.R:21-24, 88-99 | holds |
| Place names from BC Geographic Names (monthly-flow Data line) | data-raw/monthly_vignette_map.R:14, 41 | holds |
| `PostgreSQL` in code font (monthly-flow, for CLAUDE.md:50's claim) | rendered text | holds |
| These are the calls that produced the window statistics (station-flow) | the recipe chunk: `wet_window_stats()`, then `cd_baseline()`, `cd_anomaly()`, `cd_trend()` | holds |
| Load-chunk comment: routed values, and the balance's at `shape_stations`, were checked; the rest rest on the publish report (monthly-flow, not rendered) | as rows 1, 5, 6, 7 | holds |

Of round 4's three judgement calls, station-flow's "flow statistics" became "window statistics", and monthly-flow's "The scores compare them" was rewritten in the paragraph above. CLAUDE.md:50's description of the balance's remade days is unchanged text and outside this branch. Rendered after the fix: no backwards apostrophe (`‘s`) in any article. That stray quote appeared after "`fwapg`'s," and was rephrased away.

The loop ends on this enumeration: every claim sentence the branch adds has a row, and none fails.
