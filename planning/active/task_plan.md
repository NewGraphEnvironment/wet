# Task: Routed PCIC over 1981-2010: switch the pcic run and republish (#103)

**If we do it:** both sources on every segment describe 1981–2010, the period the balance and the gauge scores use, and the period caveat leaves both articles. **If we never do:** routed flow stays 1951–2012 against a 1981–2010 balance and 1981–2010 observations, and part of routed PCIC's error at the gauges stays its period (the monthly-flow article bounds it).

Depends on #101 (merged, v0.4.13). Decided at the plan gate (2026-10-18): #103 publishes on its own, before #102; the upload waits for the user's go.

## Phase 1: Flip the pin
- [x] `R/wet_segment_monthly.R`: `period = "1981-2010"` in `wet_segment_sources()`, and the roxygen text on the run (lines 18–19); `devtools::document()`
- [x] Tests: `test-wet_segment_monthly.R` (the run in the SQL and in the sources row, lines ~130, 158). `test-vignette_data.R:138` moved to Phase 4: it reads the committed rds, which stays 1951-2012 until it is rebuilt
- [x] `scripts/segment_output.R:33` comment
- [x] `devtools::test()` green (1208 passed, 0 failed, 0 errors; `data/logs/103/test_phase1.log`)

## Phase 2: New routed scores and the #67 test (m4)
- [x] `scripts/pcic_routed_compare.R` with `WET_FWAPG_COMMIT=7c30f58`. The report header must read `PNWNAmet historical 1981-2010`, and its fingerprint must match the run's `pcic.runs` row (178918222.786650)
- [x] Record the change against the 1951–2012 report in `findings.md`, using the tracked report's git diff: overall, headwater/nested, by basin, the pick block, the far-low gauges
- [x] By month: a scratchpad probe reading both runs from `pcic.discharge_monthly` at the report's gauge segments, against the held-out observed monthly shares in `cv_aet-cfu.rds`. Does routed's March–April low and July–August high (#67) survive at 1981–2010? The final per-month numbers come from the regenerated vignette data in Phase 4
- [x] Commit the report

## Phase 3: Segment table and BUILD (m4)
- [x] Pull on m4; `WET_FWAPG_COMMIT=7c30f58 Rscript scripts/segment_output.R`. Record how many picks moved, and where. Commit `data/checks/segment_output_20260717.txt`
- [x] `scripts/discharge_publish.R` BUILD. Every value check must pass. Commit `data/checks/discharge_publish_20260717.txt`
- [x] **Stop for the user's go**, then `AWS_PROFILE=airvine WET_PUBLISH=1 Rscript scripts/discharge_publish.R`, which uploads and verifies anonymously (it writes no report)
- [x] Rerun BUILD after the upload, with nothing under R/ or scripts/ changed; its report must read N of N identical to the new live build. Commit it (B1; #77 did the same)
- [ ] Reload m4's `discharge.*` tables from the new build with `wet_db_load()` (S1)

## Phase 4: Vignette data, maps, articles (m1, after the upload; pull first; data scripts with `WET_FWAPG_COMMIT=7c30f58`; commit data-raw edits before running them)
- [x] `data-raw/monthly_vignette_data.R`: remove the observed 1951–2012 block (`long_sel` … `period`), the `period` element of the rds and its header text; update `test-vignette_data.R`'s `expect_named`, the period-table test and the routed period expected (line 138)
- [x] `vignettes/monthly-flow.Rmd`: remove the period paragraph, the `period-check` chunk and the long-record lines of `score-text`, and the `stopifnot(routed_text == "1951–2012")`. Rewrite "The two sources cover different periods" and the "What's next" fwapg#25 item. The #67 attribution stays only if the spring/summer `stopifnot()`s still hold; otherwise rewrite the prose to match the numbers
- [x] `vignettes/segment-discharge.Rmd`: the routed source paragraph (`1951–2012`, held to `prov$routed`), the score-table caption, and any prose the new routed-closer and pick counts change
- [x] Rerun `data-raw/segment_vignette_data.R`, `data-raw/monthly_vignette_data.R`, `data-raw/segment_vignette_map.R` and `data-raw/readme_figure.R`. Check the map and the README figure as rendered images
- [x] README: rerun the Buck Creek example and paste its output, which is hand-pasted in `README.md`. Check the figure caption and alt text still describe the map
- [ ] Both articles build (`devtools::build_vignettes()` or pkgdown article render); `devtools::test()` green

## Phase 5: Docs
- [ ] `research/discharge_publish.md` ("`period` is a column"; the routed row of the value-check table), `research/water_balance_method.md` (the #58/#57 block, lines ~76-111, quotes 1951-2012 results), `research/discharge_publish.md:62`, with Verified/Issues lines
- [ ] `CLAUDE.md`: the routed data source (:63), the monthly article's period and gaps (:49), ("wet reads the 1951–2012 run (#101)", "#103 moves it to 1981–2010") and the `pcic_routed_compare.R` entry
- [ ] Edit the bodies of issues #67 and #103 with the outcome of the period test. Note in #102 that #103 published on its own

## Validation
- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Verification
- Routed report header names 1981–2010; its fingerprint equals `pcic.runs`.
- BUILD report: every value comparison passes, with 0 differing, and the reader and pick counts equal the segment report's; the BUILD after the upload reads N of N identical.
- Live manifest: the `pcic_routed` entry names 1981-2010 and fingerprint 178918222.786650; `SELECT DISTINCT source, period` over the live parts gives routed 1981-2010 only.
- The vignette data scripts' own guards pass (clean tree, routed table matches the tracked report, live build matches the passing publish report).
- Both articles knit with every `stopifnot()` passing; `devtools::test()` reports no failures and no errors.
