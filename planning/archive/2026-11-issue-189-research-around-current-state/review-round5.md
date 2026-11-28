## Checklist read
- index: read from file (its text is also the session's loaded conventions; the tool output of the file itself was previewed, not re-read line by line).
- code-check-python.md: read in full. code-check.md: 'A guard's scope, escape hatches, and remedies' in full, and the prose of every H3 under `## Mechanisms`, table rows skipped.
- code-check-r.md, -shell.md, -spatial.md: no full sections; the diff is Markdown prose.
- changed files: the four notes and the README rows read whole in the tree; origin/main copies of chinook_sites.md, station_flow_departure.md and fwapg_mad_method.md read for carried text. branch.diff was not read as one file, and planning/ hunks were not reviewed.
- index, diff and changed files read from file (within the scope stated above).

## Candidate set
Script: scratchpad/enum_scope.py (python -I). It splits the four notes and the four research/README.md rows into sentences (rows also at semicolons), skips fenced blocks, headings and table rows, keeps sentences with a scope word or a numeric range, and adds each table's lead-in sentence. It then adds every sentence the four 'Code-check round' commits (d133e416, 8a0bbb9c, 9da6cad6, 0b8845f9; research/ only) added or changed that is still in the tree.
**Count: 306** = 300 scope-word and table-lead members + 6 round-commit sentences not already caught (marked [R]); 1 further round sentence had been superseded by a later round. A sentence with two bold or abbreviation breaks may be split in two (e.g. 103-105), and each piece is a member.
Verdicts: HOLDS 276, HOLDS (limit) 11, NOT CHECKABLE 17, WRONG 2.
Limits: table cells were checked through their lead-in rows. HOLDS rests on the source named; where it names an archive record, a script header or code, no run was repeated. No script under scripts/ or data-raw/ was run and no request went to pacificclimate.org. Read-only reads made: HYDAT 20260717, the water-temp-bc archive, the live manifest, a receipt HEAD and a list probe on fresh-bc, local fwapg (one count), fwapg's files on GitHub.

## Enumeration
| # | where | sentence (cut) | verdict | source read |
|---|---|---|---|---|
| 1 | discharge_publish.md:3 | Each earlier build's history is in its issue's archive README. | HOLDS | header convention; history lives in planning/archive (not enumerated) |
| 2 | discharge_publish.md:17 | The largest part is `wet_balance` SETN in `segment_daily`, 373 MB. | HOLDS | live manifest.json, anonymous GET this round: largest part SETN segment_daily, 372.6 MB |
| 3 | discharge_publish.md:21 | **`pcic_routed`:** `pcic.discharge_monthly`, run PNWNAmet historical 1981–2010, built b... | HOLDS | data/checks/discharge_publish_20260717.txt routed/table lines; live manifest.json, anonymous GET this round sources[0].provenance |
| 4 | discharge_publish.md:24 | A PUBLISH uploads only the parts whose live ETag is not already their md5. | HOLDS | scripts/discharge_publish.R PUBLISH block, wet_catalog_verify(live) skip |
| 5 | discharge_publish.md:28 | Every other name comes from the ID by one rule: | HOLDS | R/wet_segment_monthly.R wet_dataset_table() in R/wet_db_load.R; scripts/discharge_publish.R ds_* ids |
| 6 | discharge_publish.md:39 | Each level means one thing: | HOLDS | naming convention (design statement); wet_dataset_table() regex; table at the note |
| 7 | discharge_publish.md:42 | The network decides the ID columns and the coverage, so two networks can never share a ... | HOLDS | naming convention (design statement); wet_dataset_table() regex; table at the note |
| 8 | discharge_publish.md:43 | It bumps only when a column is renamed or changes meaning, and then v2 lands beside v1. | HOLDS | naming convention (design statement); wet_dataset_table() regex; table at the note |
| 9 | discharge_publish.md:47 | `watershed_monthly`: the same per fundamental watershed. | HOLDS | naming convention (design statement); wet_dataset_table() regex; table at the note |
| 10 | discharge_publish.md:50 | **`segment_daily` (decided in #70, published since #99):** one row per FWA segment, sou... | HOLDS | R/wet_routed_days.R (366 bins folded, 29 Feb into 28); data/checks/segment_daily_output_20260717.txt rows |
| 11 | discharge_publish.md:50 | For the balance the days are the published months laid out with the within-month shape ... | HOLDS | data/checks/segment_daily_output_20260717.txt 'balance's days average to its months' and depth x 28/28.25 |
| 12 | discharge_publish.md:50 | For routed PCIC each day is routed from fwapg#25's sub-basin climatology (`pcic.subbasi... | HOLDS | R/wet_routed_days.R header and wet_routed_fold/raw; manifest source description |
| 13 | discharge_publish.md:50 | Weeks (fixed day-of-year bins, fwapg#25) and month-day windows are derived on read (`we... | HOLDS | R/wet_flow_window.R; no week dataset in live manifest.json, anonymous GET this round |
| 14 | discharge_publish.md:68 | **`climr` names the balance's climate input**, not every input: its actual evapotranspi... | HOLDS | manifest wet_balance description; discharge_publish.R cfu guard; #15/#81 as CLAUDE.md records |
| 15 | discharge_publish.md:69 | In `historical`, routed and balance rows are both 1981–2010. | HOLDS | manifest descriptions (1981-2010); publish_part_prepare period check |
| 16 | discharge_publish.md:70 | **Sources share one dataset**, so one read returns them side by side for the same segme... | HOLDS | publish_part_prepare() drops source; hive_partitioning in wet_segment_parts() |
| 17 | discharge_publish.md:72 | It is computed across every source of a scenario, so it spans `forcing` in `historical`. | HOLDS | R/wet_source_pick.R and the tree-wide rebuild in discharge_publish.R |
| 18 | discharge_publish.md:72 | A rebuild of a scenario therefore rewrites every source's part files, and a new source ... | HOLDS | R/wet_source_pick.R and the tree-wide rebuild in discharge_publish.R |
| 19 | discharge_publish.md:73 | For example 100 is the Fraser, 200 the Mackenzie (Peace and Liard), 300 the Columbia, 9... | HOLDS | read-only query of local fwapg: 999 codes in 246 watershed groups; live manifest.json, anonymous GET this round labels |
| 20 | discharge_publish.md:73 | The manifest labels each code. | HOLDS | live manifest.json, anonymous GET this round drainage on each part |
| 21 | discharge_publish.md:75 | At about 28 times the monthly rows a part per drainage would reach about 6 GB (the bala... | HOLDS | live manifest.json, anonymous GET this round bytes: balance part-200 monthly x 28 = about 6.0 GB; rows ratio 28.08 |
| 22 | discharge_publish.md:75 | A part's rows are sorted by segment and day, in row groups of 2,048 segments' days, so ... | HOLDS | discharge_publish.R rows_per_group = 365*2048; publish_part_prepare sort |
| 23 | discharge_publish.md:75 | `wet_segment_daily()` needs `groups` to read the parts and opens only those groups'; th... | HOLDS | R/wet_segment_monthly.R wet_segment_read stop without groups, wet_parts_groups(); manifest labels |
| 24 | discharge_publish.md:80 | The same doc scopes fresh-bc prefixes by producer (`bcfishpass/`, `fwapg/`) so they do ... | NOT CHECKABLE | bucket's own documentation is outside this repo; carried unchanged |
| 25 | discharge_publish.md:81 | Anonymous `s3:GetObject` on `discharge/*` only, and no `s3:ListBucket`. | HOLDS | anonymous ListObjects of the bucket not granted (probe this round); wet_catalog() reads the manifest |
| 26 | discharge_publish.md:81 | Readers therefore use `manifest.json`, which names every key, rather than globbing. | HOLDS | anonymous ListObjects of the bucket not granted (probe this round); wet_catalog() reads the manifest |
| 27 | discharge_publish.md:82 | **The manifest is rewritten whole by each publish**, from one local tree, so that tree ... | HOLDS | discharge_publish.R: manifest from one local tree, stale keys deleted; manifest sources/datasets entries |
| 28 | discharge_publish.md:82 | Its `sources` entries carry what each source's rows were built from, and each dataset n... | HOLDS | discharge_publish.R: manifest from one local tree, stale keys deleted; manifest sources/datasets entries |
| 29 | discharge_publish.md:83 | Bucket versioning is suspended, so an overwrite is final and a republish replaces bytes... | NOT CHECKABLE | bucket versioning; note dates it 2026-10-24 |
| 30 | discharge_publish.md:83 | That is acceptable because every file is rebuilt from code and inputs, and the manifest... | HOLDS | manifest provenance, fit and routed_fingerprint |
| 31 | discharge_publish.md:87 | A build lists two more kinds of file beside its parts, both written by the BUILD and na... | HOLDS | discharge_publish.R PUBLISH uploads and verifies files_local incl. receipt and fit |
| 32 | discharge_publish.md:89 | **`receipt.json`**, the build's provenance record in crate's shared shape (`crate::crt_... | HOLDS | inst/receipt/discharge_fwa_v1.yaml; wet_receipt_write() call |
| 33 | discharge_publish.md:89 | The manifest's `receipt` entry carries its `recipe_id`, and `wet_db_load()` records tha... | HOLDS | R/wet_db_load.R wet_load_record recipe_id; manifest receipt entry |
| 34 | discharge_publish.md:89 | Compare two builds' receipts with `crate::crt_receipt_compare()`: identical when recipe... | HOLDS | crate crt_receipt_compare() source and NEWS (identical = same recipe and result) |
| 35 | discharge_publish.md:89 | No table is fingerprinted (the daily dataset's 2.9 billion rows are past crate#50's lim... | HOLDS | inst/receipt/discharge_fwa_v1.yaml comment |
| 36 | discharge_publish.md:89 | The receipt's bytes change with every BUILD (its time), so no PUBLISH skips it, and it ... | HOLDS (limit) | discharge_publish.R: receipt put only if live differs, no-cache; true for the first PUBLISH after a BUILD (new time) |
| 37 | discharge_publish.md:90 | **`fit/`**: the shipped fit (`fit/fits.rds`) and each watershed group's sample of the p... | HOLDS | live manifest.json, anonymous GET this round fit: 247 files, 1.44 GB, citation; discharge_publish.R identical() read-back |
| 38 | discharge_publish.md:90 | `scripts/segment_group.R` rebuilds one group's balance rows and pick from them on any m... | HOLDS | scripts/segment_group.R WET_GROUP_FROM=published header (needs the build's commit checked out) |
| 39 | discharge_publish.md:92 | `wet_catalog()` returns both as attributes (`receipt`, `fit`), `NULL` for a build publi... | HOLDS | R/wet_catalog.R receipt/fit NULL when absent |
| 40 | discharge_publish.md:92 | The parts' digest (`tree parts md5`, `wet:::wet_catalog_digest()`) covers the parts alo... | HOLDS | R/wet_catalog.R wet_catalog_digest() over catalog keys only |
| 41 | discharge_publish.md:96 | The BUILD reads every written part back and compares it, value by value, with what it w... | HOLDS | discharge_publish.R value checks, wet_values_compare(), stop on any failed check |
| 42 | discharge_publish.md:96 | It reports compared, differing and largest difference for each check, and fails on any ... | HOLDS | discharge_publish.R value checks, wet_values_compare(), stop on any failed check |
| 43 | discharge_publish.md:96 | Every published flow (`q_m3s`) is checked against its source. | HOLDS | discharge_publish.R: the vc_add() calls enumerate q_m3s and the four columns; no other column compared |
| 44 | discharge_publish.md:96 | Of the other columns, the segment parts' `runoff_mm`, `coverage` and `pick` are checked... | HOLDS | discharge_publish.R: the vc_add() calls enumerate q_m3s and the four columns; no other column compared |
| 45 | discharge_publish.md:112 | Two checks meet within a tolerance (relative 1e-9) because each compares a mean recompu... | HOLDS | discharge_publish.R: the only two calls at default tol=1e-9 are month 0 and balance day means; R/wet_values_compare.R |
| 46 | discharge_publish.md:112 | Every other check is exact (the routed days after rounding, below). | HOLDS | discharge_publish.R: every other call tol=0; row-count and total checks exact |
| 47 | discharge_publish.md:112 | No routed day sat one rounding step from its recomputation at a tie. | HOLDS | data/checks/discharge_publish_20260717.txt 'one 1e-5 step apart ... 0' |
| 48 | discharge_publish.md:114 | The segment-discharge article reads its routed values at the calibration gauges, every ... | HOLDS | CLAUDE.md vignette description and data-raw scripts' vd_published() reads |
| 49 | discharge_publish.md:114 | The three scripts that build them (`data-raw/segment_vignette_data.R`, `segment_vignett... | HOLDS | scripts/vignette_data_lib.R vd_published() |
| 50 | discharge_publish.md:114 | The report records `tree parts md5`, the digest of its own tree (`wet:::wet_catalog_dig... | HOLDS | scripts/vignette_data_lib.R vd_published() |
| 51 | discharge_publish.md:114 | PUBLISH uploads a tree only under a committed report naming that tree's digest, and aft... | HOLDS | publish_report_check() and publish_report_live() call order |
| 52 | discharge_publish.md:114 | A tree rebuilt at the report's commit from other inputs can therefore neither be upload... | HOLDS | publish_report_check() and publish_report_live() call order |
| 53 | discharge_publish.md:114 | `segment_vignette_data.R` also refuses unless each gauge's routed value equals fwapg's ... | HOLDS | vd_segment_report() and data-raw/segment_vignette_data.R lines 101-251 (grep); comment on earlier segment_commit |
| 54 | discharge_publish.md:114 | The live manifest's `segment_commit` can be earlier, because a rerun of `segment_output... | HOLDS | vd_segment_report() and data-raw/segment_vignette_data.R lines 101-251 (grep); comment on earlier segment_commit |
| 55 | discharge_publish.md:118 | Routed PCIC's days are made in wet, not read from fwapg, because fwapg keeps per-segmen... | HOLDS | R/wet_routed_days.R header (per-sub-basin days only) |
| 56 | discharge_publish.md:118 | `scripts/segment_daily_output.R` reads the run's `pcic.subbasin_daily` (13,961,436 rows... | HOLDS | data/checks/segment_daily_output_20260717.txt daily line; scripts/pcic_routed_lib.R routed_daily_fingerprint() vs pcic.runs, inputs read once |
| 57 | discharge_publish.md:118 | It folds 29 February into 28 February by the bins' `n_days` and routes each day as fwap... | HOLDS | R/wet_routed_days.R fold, raw, round |
| 58 | discharge_publish.md:120 | The `n_days`-weighted mean of a month's unclamped days, clamped and rounded, equals `pc... | HOLDS | data/checks/segment_daily_output_20260717.txt rebuilt months: 0 differing, 0 ties, 40524444 |
| 59 | discharge_publish.md:120 | The same held for `pcic.discharge_weekly` in five groups on an earlier fwapg build (#99... | NOT CHECKABLE | #99 probe on earlier build; note says not re-run |
| 60 | discharge_publish.md:121 | 14,577,433 of 1,232,618,505 routed segment-days are clamped at zero (1.183 %), and 53,6... | HOLDS | data/checks/segment_daily_output_20260717.txt clamped rows |
| 61 | discharge_publish.md:122 | A reader's plain mean of a month's days also counts the folded 28 February as one day o... | HOLDS | arithmetic: 30 years x 28 + 7 leap = 847 February day-years, 37 for 28+29 Feb bins |
| 62 | discharge_publish.md:122 | The largest is 197.24528 m³/s above the month, the largest below 0.12366 m³/s. | HOLDS | data/checks/segment_daily_output_20260717.txt largest above/below |
| 63 | discharge_publish.md:122 | Outside February the period holds every day equally often, so a plain mean there can si... | HOLDS | R/wet_routed_days.R clamp-per-day (convexity); data/checks/segment_daily_output_20260717.txt |
| 64 | discharge_publish.md:129 | naming every key, so readers need no listing; | HOLDS | R/wet_catalog.R reads manifest keys |
| 65 | discharge_publish.md:136 | The segment table holds all rows (both sources, 13 months) with `scenario`, `forcing`, ... | HOLDS | R/wet_db_load.R template columns; manifest rows |
| 66 | discharge_publish.md:146 | `wet_segment_monthly()` reads the same table per segment and source, keyed on `linear_f... | HOLDS | R/wet_segment_monthly.R wet_segment_read |
| 67 | discharge_publish.md:146 | It warns on a table whose comment records a subset load, and stops on a scenario or sou... | HOLDS | wet_segment_pg(): by_groups exception |
| 68 | discharge_publish.md:146 | Over HTTPS (2026-10-14), one segment took 3.3 s with its watershed group named and 27 s... | NOT CHECKABLE | HTTPS timing, dated 2026-10-14 (507 row groups matches data/checks/discharge_publish_20260717.txt) |
| 69 | discharge_publish.md:148 | Each load also writes one row per loaded part to `discharge.wet_load` (in the dataset's... | HOLDS | R/wet_db_load.R wet_load_record, cols_load, COMMENT |
| 70 | discharge_publish.md:148 | The table comment is unchanged word for word, because downstream code parses it, but it... | HOLDS | R/wet_db_load.R wet_load_record, cols_load, COMMENT |
| 71 | discharge_publish.md:150 | **Cost of a load** (earlier builds of the same two tables, not re-timed). | NOT CHECKABLE | timings; note says earlier builds, not re-timed |
| 72 | discharge_publish.md:150 | `wet_db_load()` creates that index only when it creates the table. | HOLDS | R/wet_db_load.R: index inside if (created) |
| 73 | discharge_publish.md:157 | `/outlets/4008184/timeseries` lists 19 series per variable: one `historical` (PNWNAmet,... | NOT CHECKABLE | hydromosaic listing dated 2026-10-12, not re-read (robots.txt) |
| 74 | discharge_publish.md:158 | `discharge/*` was added on 2026-10-13 (GetObject only, no ListBucket); an unsigned GET ... | NOT CHECKABLE | bucket policy change and probe, dated 2026-10-13 |
| 75 | discharge_publish.md:9 | TABLE-LEAD(for table at 11): It holds the `historical` scenario in 512 parts, 33.36 GB: | HOLDS | live manifest.json, anonymous GET this round: 512 parts 33.36 GB; table 445/43/24 rows and GB reproduced |
| 76 | discharge_publish.md:28 | TABLE-LEAD(for table at 30): Every other name comes from the ID by one rule: | HOLDS | naming/layout tables vs R/wet_db_load.R and part_path() |
| 77 | discharge_publish.md:58 | TABLE-LEAD(for table at 60): ``` | HOLDS | naming/layout tables vs R/wet_db_load.R and part_path() |
| 78 | discharge_publish.md:98 | TABLE-LEAD(for table at 100): The live build's checks (`data/checks/discharge_publish_2... | HOLDS | data/checks/discharge_publish_20260717.txt value table, all nine rows compared |
| 79 | station_flow_departure.md:3 | **Verified:** 2026-11-27 (re-read: the tracked reports below; the HYDAT 20260717 ice an... | HOLDS (limit) | header re-read list; figures spot re-derived this round (HYDAT, archive, bundle) |
| 80 | station_flow_departure.md:3 | Not re-run: any departure script. | HOLDS | header statement of what was not re-run / re-read |
| 81 | station_flow_departure.md:3 | Not re-read: the real-time feed, GeoMet's approved end, cd's trend message and the lite... | HOLDS | header statement of what was not re-run / re-read |
| 82 | station_flow_departure.md:9 | For a HYDAT station number, `wet_station_daily()` joins three sources, each continuing ... | HOLDS | R/wet_station_daily.R (three federal sources, wet_daily_after) |
| 83 | station_flow_departure.md:17 | A provisional value is never used inside HYDAT's approved record, because a hole there ... | HOLDS | R/wet_station_daily.R (three federal sources, wet_daily_after) |
| 84 | station_flow_departure.md:17 | With the 2026-07-17 HYDAT, 08EE013 and 08EE003 join with no gap (HYDAT to 2025-03-02 an... | HOLDS | HYDAT March 2025 rows (1-2, 1-4); archive 2025 full (wet_provisional_daily this round) |
| 85 | station_flow_departure.md:17 | The archive holds every day of 2024 for both stations, so even a HYDAT that ends on 202... | HOLDS | wet_provisional_daily this round: 2024 366 days both |
| 86 | station_flow_departure.md:17 | The archive has gaps of its own: of 2023 it holds only the last 75 days (from 18 Octobe... | HOLDS | same: 2023 75 days from 10-18 both |
| 87 | station_flow_departure.md:23 | 43.5 % of Buck Creek's (08EE013) approved days are `B`, ice-affected estimates: 8,101 o... | HOLDS | HYDAT 20260717: 8101/18620, 2465/12557 |
| 88 | station_flow_departure.md:24 | Provisional ice days are not marked: the archive's `Symbol` was NA on every row for bot... | HOLDS | archive read this round: PN/PX/SD 3 and 8 rows, none in 2025-12..2026-02 (2026-09-28 part dated) |
| 89 | station_flow_departure.md:24 | Buck Creek's provisional monthly means for December 2025, January and February 2026 wer... | HOLDS | station_daily.rds 6.56/7.75/15.0; archive 0.68/0.65/0.68; HYDAT 131 winter months 0.025..3.94 med 0.554 |
| 90 | station_flow_departure.md:24 | `scripts/station_departure.R` drops any year with provisional days from windows touchin... | HOLDS | data/checks/station_departure_report.txt header |
| 91 | station_flow_departure.md:25 | **Seasonal gauges have no winter baseline. | HOLDS | HYDAT months; report 'No departure: djf' at 08EE003 |
| 92 | station_flow_departure.md:25 | 08EE003 ran April or May to October from 1981 to 1998 (with November days from 1985), l... | WRONG | HYDAT 20260717 DLY_FLOWS: 1982, 1983, 1984 end 30 September (no October day); see finding 1 |
| 93 | station_flow_departure.md:25 | It has 1 December–February year in 1981–2010, and its only complete years are 1971 and ... | HOLDS | report djf baseline 1; HYDAT complete years 1971, 2011-2024 |
| 94 | station_flow_departure.md:25 | The script refuses a departure for a window with fewer than 10 baseline years, and take... | HOLDS | station_departure_report.txt header and 08EE003 MAD line |
| 95 | station_flow_departure.md:26 | Buck Creek's August 1981–2010 monthly means run 0.14 to 4.12 m³/s (29 years, median 0.7... | HOLDS | HYDAT: n 29, 0.138..4.118, median 0.754, mean 0.948 |
| 96 | station_flow_departure.md:30 | `DLY_FLOWS` has no column that states where approval ends. | NOT CHECKABLE | DLY_FLOWS schema statement; carried unchanged |
| 97 | station_flow_departure.md:30 | The March 2025 row for 08EE013 has `NO_DAYS` 31 but values only on the 1st and 2nd. | HOLDS | HYDAT 08EE013 2025-03: NO_DAYS 31, values days 1-2 |
| 98 | station_flow_departure.md:36 | A window-year needs at least 80 % of its days and must lie inside the record. | HOLDS | R/wet_window_stats.R min_frac, a<first/b>last |
| 99 | station_flow_departure.md:39 | Mann-Kendall on a constant series (a share that is 0 every year) prints a Kendall Fortr... | NOT CHECKABLE | cd's message; header keeps earlier date |
| 100 | station_flow_departure.md:43 | The measured article (`vignettes/flow-departure-normal.Rmd`) compares 2016–2025 with 19... | HOLDS | vignettes/flow-departure-normal.Rmd windows and fry stopifnot; month-day arithmetic |
| 101 | station_flow_departure.md:43 | The fry migration window (07-15 to 09-07) falls within them. | HOLDS | vignettes/flow-departure-normal.Rmd windows and fry stopifnot; month-day arithmetic |
| 102 | station_flow_departure.md:43 | Incubation (08-01 to 03-31) and emergence (04-15 to 07-07) touch November–April, so the... | HOLDS | vignettes/flow-departure-normal.Rmd windows and fry stopifnot; month-day arithmetic |
| 103 | station_flow_departure.md:43 | 1981–2010 is cited as a WMO standard normal (Arguez and Vose 2011, p. | NOT CHECKABLE | literature citations; header says not re-read |
| 104 | station_flow_departure.md:43 | 699; WMO-No. | NOT CHECKABLE | literature citations; header says not re-read |
| 105 | station_flow_departure.md:43 | 2012), which is why the comparison article measures from 1951–1980. | NOT CHECKABLE | literature citations; header says not re-read |
| 106 | station_flow_departure.md:50 | Every window at both gauges was below normal in each year from 2023, and 11 of those 12... | HOLDS | station_daily.rds recomputed: 12/12 below from 2023; 11 above >90% of baseline |
| 107 | station_flow_departure.md:50 | Before 2023 the decade swings both ways. | HOLDS | same: 9/9 and 8/9 same side, split 2019 spawning |
| 108 | station_flow_departure.md:50 | The two gauges fall on the same side of normal in 17 of the 18 window-years both record... | HOLDS | same: 9/9 and 8/9 same side, split 2019 spawning |
| 109 | station_flow_departure.md:51 | Buck Creek has no 2016 in either window (no days in the bundle), so it has 9 recent years. | HOLDS | same: 08EE013 recent n 9, no 2016 |
| 110 | station_flow_departure.md:53 | 08EE003's 2025 record has two provisional gaps, 1–8 July and 3–11 August. | HOLDS | same: 2025 gaps 07-01..08, 08-03..11; 85/93, 37/46 |
| 111 | station_flow_departure.md:53 | Its 2025 migration and spawning windows rest on 85 of 93 and 37 of 46 days, which `wet_... | HOLDS | same: 2025 gaps 07-01..08, 08-03..11; 85/93, 37/46 |
| 112 | station_flow_departure.md:55 | At these years it covers 0.834–0.867 of simulated no-change records, under the 0.87 bar... | HOLDS | data/checks/departure_interval_coverage.txt |
| 113 | station_flow_departure.md:55 | The article calls it "the middle 90 % of changes from resampling" and rests no count on... | HOLDS | vignette lines 287/652 'middle 90%'; coverage report OUTCOME |
| 114 | station_flow_departure.md:59 | The method was set by a pilot on Maxan Creek (08EE018, 363 km²), gauged for five comple... | HOLDS | data/checks/departure_pilot_20260717.txt header and section 1; commit 6894c27 exists |
| 115 | station_flow_departure.md:59 | It answers two questions: can a short record be extended across the long record from it... | HOLDS | data/checks/departure_pilot_20260717.txt header and section 1; commit 6894c27 exists |
| 116 | station_flow_departure.md:59 | The rules were registered in `scripts/departure_pilot.R`'s header at 6894c27, before an... | HOLDS | data/checks/departure_pilot_20260717.txt header and section 1; commit 6894c27 exists |
| 117 | station_flow_departure.md:61 | Natural HYDAT gauges in a box over the Bulkley and its neighbours (lon −128.8 to −125.0... | HOLDS | pilot section 1: 53, 21, 31 |
| 118 | station_flow_departure.md:63 | 21 have at least 30 complete migration windows; they are the extension donors and test ... | HOLDS | pilot section 1: 53, 21, 31 |
| 119 | station_flow_departure.md:64 | 31 have at least 10 complete migration windows in 1981–2010; they are the departure don... | HOLDS | pilot section 1: 53, 21, 31 |
| 120 | station_flow_departure.md:64 | Each other statistic and window has its own set. | HOLDS | pilot section 3 per-statistic pools differ |
| 121 | station_flow_departure.md:65 | 13 have 3–10 complete migration windows: the short-record test set, Maxan among them. | HOLDS | pilot section 1: 13 short incl 08EE018 |
| 122 | station_flow_departure.md:69 | Each long gauge's record was cut into 5-year blocks, 220 in all, of which 218 had a don... | HOLDS | pilot section 2 blocks 220/218 and other candidates 0.30/0.56, 0.36/0.52 |
| 123 | station_flow_departure.md:69 | Each block was extended from the other long gauges and scored only on the years it held... | HOLDS | pilot section 2 blocks 220/218 and other candidates 0.30/0.56, 0.36/0.52 |
| 124 | station_flow_departure.md:77 | A regression on up to three donors scores 0.30 against OLS's 0.56 on the same years, an... | HOLDS | pilot section 2 blocks 220/218 and other candidates 0.30/0.56, 0.36/0.52 |
| 125 | station_flow_departure.md:77 | The migration-window 7-day minimum extends badly: every method's median is below 0. | HOLDS | pilot section 2 migration min7 -0.11/-0.42/-0.11 |
| 126 | station_flow_departure.md:77 | A target needs at least 3 years of its own; the pilot's Maxan had 5. | HOLDS | R/wet_window_extend.R length(ty)<3; pilot 5 years |
| 127 | station_flow_departure.md:79 | The sites run since the pilot keep OLS (fixed before those runs), although the same rac... | HOLDS | site reports section 2: ratio picked at Swift and Naver |
| 128 | station_flow_departure.md:83 | Each departure-pool gauge was held out in turn and given its five nearest donors' log d... | HOLDS | R/wet_departure_carry.R; pilot section 3 header |
| 129 | station_flow_departure.md:83 | The score is NSE on the years both series have, each centred on its own mean there, so ... | HOLDS | R/wet_departure_carry.R; pilot section 3 header |
| 130 | station_flow_departure.md:85 | **Median NSE 0.63** over the 31 gauges, quartiles 0.34 to 0.75. | HOLDS | pilot section 3: 0.63 (0.34-0.75), short 0.69 over 12, 08JB006 2 years |
| 131 | station_flow_departure.md:86 | The short-record gauges score a median of 0.69, over 12 of the 13: 08JB006 shares only ... | HOLDS | pilot section 3: 0.63 (0.34-0.75), short 0.69 over 12, 08JB006 2 years |
| 132 | station_flow_departure.md:90 | Held out at the 290 calibration gauges PCIC covers, 1951–2012, donors chosen by how wel... | HOLDS | data/checks/departure_pcic_20260717.txt: 290; 0.67/0.72; 0.48; blend 0.71 |
| 133 | station_flow_departure.md:90 | At a site, `covariance_pick` replaces distance only where it also wins at that box's ga... | HOLDS | scripts/departure_site.R #147 header rule |
| 134 | station_flow_departure.md:94 | Each year's peak snow water equivalent (`swe_max`) and 50 % melt date (`snowmelt_doy_50... | HOLDS | snow reports headers and section 2 (24 pilot fits); commit 81580b5 |
| 135 | station_flow_departure.md:94 | For the observed and extended series the departure is from the series' own 1981–2010 me... | HOLDS | snow reports headers and section 2 (24 pilot fits); commit 81580b5 |
| 136 | station_flow_departure.md:94 | The specification was registered in `scripts/departure_snow.R`'s header at 81580b5, bef... | HOLDS | snow reports headers and section 2 (24 pilot fits); commit 81580b5 |
| 137 | station_flow_departure.md:96 | **More peak snow and a later melt mean more flow in the migration window, at every gaug... | HOLDS | data/checks/departure_snow_20260717.txt section 2 |
| 138 | station_flow_departure.md:96 | In the spawning window, snow explains almost nothing** (R² at most 0.07 in the pilot). | HOLDS | data/checks/departure_snow_20260717.txt section 2 |
| 139 | station_flow_departure.md:98 | Averaged over 1981–2010, the per-year values match the snow normals behind the monthly ... | HOLDS | departure_snow section 4: 0.86 mm, 0.49 d, cache key, cap |
| 140 | station_flow_departure.md:98 | The normals' cache key reproduces from the bands read here, so the two rest on the same... | HOLDS | departure_snow section 4: 0.86 mm, 0.49 d, cache key, cap |
| 141 | station_flow_departure.md:98 | The 3,000 mm glacier cap bound in none of the three watersheds in any year. | HOLDS | departure_snow section 4: 0.86 mm, 0.49 d, cache key, cap |
| 142 | station_flow_departure.md:104 | In the pilot's spawning window the intercepts, over all three models, sit at −0.31 to −... | HOLDS | departure_snow section 2 spawning intercepts |
| 143 | station_flow_departure.md:9 | TABLE-LEAD(for table at 11): For a HYDAT station number, `wet_station_daily()` joins th... | HOLDS | R/wet_station_daily.R (540 days) and archive/HYDAT reads |
| 144 | station_flow_departure.md:43 | TABLE-LEAD(for table at 45): 2012), which is why the comparison article measures from 1... | HOLDS | departure bundle and pilot section 2 tables |
| 145 | station_flow_departure.md:69 | TABLE-LEAD(for table at 71): Each block was extended from the other long gauges and sco... | HOLDS | departure bundle and pilot section 2 tables |
| 146 | chinook_sites.md:3 | **Verified:** 2026-11-27 (re-read: every figure below against `data/checks/chinook_site... | WRONG | header says 'every figure below against' the listed reports: -118.5 is in no listed report, the 1952-1970 gap is HYDAT; box counts of the probes are not in the rule header. See finding 2 |
| 147 | chinook_sites.md:3 | The scripts were not re-run) · **Issues:** #126 (component of #118; after #120, #121), ... | HOLDS | header producer list; files exist in data/checks |
| 148 | chinook_sites.md:19 | Every provincial Chinook record lies within 6 km of the mouth, around this gauge. | HOLDS | chinook_sites_use.txt Swift observations: max 5984 m; 1 major spawning, 8 fry 2012 |
| 149 | chinook_sites.md:19 | 08KA010, above Barrett Creek, is upstream of all of them. | HOLDS (limit) | use report places 08KA010 inside; position above Barrett Creek by HYDAT name, upstream relation not re-derived |
| 150 | chinook_sites.md:19 | 08KA012 has 14 complete migration windows (1985–1998), all inside the 1981–2010 baseline. | HOLDS | swift/naver site report section 1: 14 (1985-1998), 18 (1956-1975) |
| 151 | chinook_sites.md:20 | **Naver Creek: 08KE014, at Hixon,** with 18 windows (1956–1975), all before the baseline. | HOLDS | swift/naver site report section 1: 14 (1985-1998), 18 (1956-1975) |
| 152 | chinook_sites.md:21 | Owen Creek, the issue's first choice, has no provincial Chinook record, and its 11 NuSE... | HOLDS | chinook_sites_use.txt table, Morice rule line, observations 1981-1999 |
| 153 | chinook_sites.md:21 | The user's rule (2026-10-28) took whichever of Gosnell and Lamprey has more use records... | HOLDS | chinook_sites_use.txt table, Morice rule line, observations 1981-1999 |
| 154 | chinook_sites.md:21 | Gosnell's one NuSEDS adult-presence record (2001) is the only spawning record of either... | HOLDS | chinook_sites_use.txt table, Morice rule line, observations 1981-1999 |
| 155 | chinook_sites.md:21 | That tie-break is by definition: a NuSEDS adult-presence record counts as a spawning re... | HOLDS | chinook_sites_use.txt table, Morice rule line, observations 1981-1999 |
| 156 | chinook_sites.md:21 | Its provincial records are inventories from 1981 to 1999. | HOLDS | chinook_sites_use.txt table, Morice rule line, observations 1981-1999 |
| 157 | chinook_sites.md:26 | It ships where it beats inverse distance by 0.01 on the migration-window mean at the bo... | HOLDS | scripts/departure_site.R #147 header; section 6 VERDICT lines; commits 68a983d, 37e0633 |
| 158 | chinook_sites.md:27 | PCIC covers every box, the Morice and upper Fraser included; 2 to 4 gauges per box are ... | HOLDS | section 6 'Covered' lines: 4,3,3,4,2,4,4 |
| 159 | chinook_sites.md:28 | Each site runs under the Bulkley's chinook salmon life history timing windows, and each... | HOLDS | seven site reports; departure_sites.csv windows |
| 160 | chinook_sites.md:37 | `data-raw/life_history_data.R` reads the table at a475dfe7 while `data-raw/station_vign... | HOLDS | data-raw/life_history_data.R lh_pin_guard() |
| 161 | chinook_sites.md:37 | The UFRA and COTR spawning edges are medians of NuSEDS start and end dates, which are e... | NOT CHECKABLE | knowledge's NuSEDS notes (partly quoted in life_history_ufra.csv); private source |
| 162 | chinook_sites.md:37 | The new reports' headers name the migration row's sources only (the site scripts were n... | HOLDS | Windows lines of UFRA, COTR, MORR reports |
| 163 | chinook_sites.md:41 | Carried: median per-gauge centred log NSE at the box's PCIC-covered gauges, both weight... | HOLDS | section 6 header |
| 164 | chinook_sites.md:53 | The shipped route's held-out score for each statistic, on the same covered gauges, with... | HOLDS | section 6 score tables |
| 165 | chinook_sites.md:65 | The migration-window mean clears the 0.5 usable bar in every row. | HOLDS | section 6, both routes, 7 reports |
| 166 | chinook_sites.md:65 | The spawning-window mean falls below it only at Swift. | HOLDS | section 6, both routes, 7 reports |
| 167 | chinook_sites.md:66 | The lowest seven-day flow carries least well at most sites, though not in every site-wi... | HOLDS | sections 6 and 3: 4 of 8; 7 on section 3's pool |
| 168 | chinook_sites.md:66 | Under the Bulkley windows it is below 0.5 in 4 of the 8 site-windows (on inverse distan... | HOLDS | sections 6 and 3: 4 of 8; 7 on section 3's pool |
| 169 | chinook_sites.md:67 | The change intervals carry each route's held-out residuals, so a weaker score widens them. | HOLDS | section 5 interval definition |
| 170 | chinook_sites.md:69 | The pilot's race, rerun at each box on the migration-window mean (median NSE, OLS / rat... | HOLDS | section 2 'rule' lines, 7 reports |
| 171 | chinook_sites.md:69 | In the upper Fraser box, whose eastern part (east of about −118.5°) is mostly Alberta a... | HOLDS (limit) | site reports: extension pool 11/10, floor 15; BC filter at departure_site.R:269; -118.5 only in the #126 archive |
| 172 | chinook_sites.md:73 | 1951–1980 comes before global warming sped up (Hansen et al. | NOT CHECKABLE | Hansen et al. 2012; literature |
| 173 | chinook_sites.md:73 | Each change is a route's mean over its 2016–2025 years less its mean over its 1951–1980... | HOLDS | section 5/6 headers; commit b66b577 |
| 174 | chinook_sites.md:87 | **The extended (filled-in) record**, at the gauged sites (Gosnell has none): | HOLDS | sections 5 and 6 change tables, all cells and ranges recomputed |
| 175 | chinook_sites.md:97 | Lower on the shipped route in every row. | HOLDS | sections 5 and 6 change tables, all cells and ranges recomputed |
| 176 | chinook_sites.md:97 | Under the Bulkley windows the drop runs, largest first, Maxan (−66 %), Naver (−35 %), G... | HOLDS | sections 5 and 6 change tables, all cells and ranges recomputed |
| 177 | chinook_sites.md:97 | Filled in, it falls at every gauged site, with the range below zero at Maxan and at Swi... | HOLDS | sections 5 and 6 change tables, all cells and ranges recomputed |
| 178 | chinook_sites.md:98 | On the shipped route it is lower in every row, by 5 to 30 %; filled in, it is lower at ... | HOLDS | sections 5 and 6 change tables, all cells and ranges recomputed |
| 179 | chinook_sites.md:98 | The range stays below zero only at Maxan, on both routes. | HOLDS | sections 5 and 6 change tables, all cells and ranges recomputed |
| 180 | chinook_sites.md:100 | **Migration-window lowest seven-day flow** has no common sign: it clearly falls only at... | HOLDS | same, migration min7 rows |
| 181 | chinook_sites.md:101 | Each was put through 1000 simulated no-change series, normal with the series' own SD in... | HOLDS | cover columns: min 0.904 distance/extended, min 0.921 covariance_pick |
| 182 | chinook_sites.md:101 | The article calls a change interval a 90 % range only above 0.87, so every change range... | HOLDS | cover columns: min 0.904 distance/extended, min 0.921 covariance_pick |
| 183 | chinook_sites.md:101 | It does not call the years figure's OLS band a 90 % range, because its held-out coverag... | HOLDS | section 2 coverage lines: 85/82.7/85.3 migration, 88/85/86 spawning |
| 184 | chinook_sites.md:102 | **Years behind each period. | HOLDS | label for 185-186 |
| 185 | chinook_sites.md:102 | 2016–2025 has 9 or 10 on every route; the tenth, where there is one, is 2025, which app... | HOLDS | rec columns 9 or 10, sections 5-6 |
| 186 | chinook_sites.md:102 | 1951–1980 has 20–30, with these exceptions on the `covariance_pick` route, which can ch... | HOLDS | section 6 ref columns; HYDAT: 08EE013 and 08JA016 empty 1950-72 bar 08EE013 from 1973; 08EE003 empty 1952-70 |
| 187 | chinook_sites.md:103 | **Naver's filled-in years since 1999** rest, for the migration-window mean, on 08KH006 ... | HOLDS | naver_bulk and naver_cotr per-year donor columns 1999-2025 |
| 188 | chinook_sites.md:103 | The extension's donor rule needs a donor covering every one of the target's 1956–1975 y... | HOLDS | R/wet_window_extend.R covers<-all(ty %in% year) |
| 189 | chinook_sites.md:104 | The stations beyond HYDAT add no donor at these sites ([`station_sources.md`](station_s... | HOLDS | research/station_sources.md 'At the chinook sites' boxes'; donor report verdict |
| 190 | chinook_sites.md:108 | **The carried migration-window departure rises with peak snow at every site**, with a 9... | HOLDS | snow reports sections 2 and 6, swe-only fits: 0.42/0.41/0.53/0.48; spawning 0.01/0.16/0.04/0.20 |
| 191 | chinook_sites.md:108 | The same holds under each site's own windows. | HOLDS | own-window snow reports: 0.43/0.52/0.48 with positive slopes |
| 192 | chinook_sites.md:108 | The 3,000 mm SWE cap binds in no watershed in any year, Swift's glacier-fed basin inclu... | HOLDS | snow reports section 4 cap line |
| 193 | chinook_sites.md:109 | **Snow over each target's watershed, 1951–1980 to 2016–2025:** peak SWE fell 6–9 % (Max... | HOLDS | snow reports section 3, 1951-1980 vs 2016-2025 |
| 194 | chinook_sites.md:110 | **At the measured snow gauges** (Bulkley windows), migration-window flow rises with pea... | HOLDS | eight observed swe-only fits: R2 .25-.62, CIs above 0; spawning max .31 |
| 195 | chinook_sites.md:110 | In the spawning window peak SWE's R² is at most 0.31. | HOLDS | eight observed swe-only fits: R2 .25-.62, CIs above 0; spawning max .31 |
| 196 | chinook_sites.md:110 | The 50 % melt date explains more there at two gauges, 64–66 % of spawning-window flow a... | HOLDS | doy-only spawning R2 .64/.66; others <= .33; MORR .18/.19 |
| 197 | chinook_sites.md:110 | Elsewhere it explains at most a third, and at those two under the Morice's later window... | HOLDS | doy-only spawning R2 .64/.66; others <= .33; MORR .18/.19 |
| 198 | chinook_sites.md:111 | The others are the first two, with at least 10 baseline years in both windows and an ac... | HOLDS | snow report 'Snow gauges' lines |
| 199 | chinook_sites.md:111 | The accepted-snap condition was added after a first Naver run, whose second gauge by th... | HOLDS | naver snow report chain skips 08KD001; section 6 lists it uncovered |
| 200 | chinook_sites.md:115 | The normal's error is measured at the 29 departure-pool gauges of its box with an accep... | HOLDS | gosnell reports normal-error section; 29 rows per window all pcic_routed |
| 201 | chinook_sites.md:115 | Routed PCIC is the pick at all 29 under both, so the report's flag for gauges in the wa... | HOLDS | gosnell reports normal-error section; 29 rows per window all pcic_routed |
| 202 | chinook_sites.md:121 | **1931–2024. | HOLDS | label; pilot section 4 span 1931-2024 |
| 203 | chinook_sites.md:121 | For the migration-window mean three supply years: Buck Creek (08EE013) 1973–1974, 1980–... | HOLDS | pilot section 4 'Years supplied per donor' |
| 204 | chinook_sites.md:121 | In the spawning window Goathorn supplies 1960–1971, 1984 and 2016, Quick 1931–1959 and ... | HOLDS | departure_snow section 5 donor spw column |
| 205 | chinook_sites.md:121 | The Morice and the Nanika supply none, being farther; the Nanika reaches back to 1950, ... | HOLDS | pilot section 4 donor chain and Limit line |
| 206 | chinook_sites.md:121 | Every extended year rests on one donor, through a relation fitted on Maxan's five years. | HOLDS | pilot section 4 donor chain and Limit line |
| 207 | chinook_sites.md:129 | The interval resamples years within each period and adds a held-out residual to each ex... | HOLDS | pilot section 4 before/after: -2.6 %, -46 % carried |
| 208 | chinook_sites.md:129 | The donor-carried route, which needs no Maxan baseline, gives a smaller drop in both me... | HOLDS | pilot section 4 before/after: -2.6 %, -46 % carried |
| 209 | chinook_sites.md:129 | Spawning-window flows are small: in 80 of 94 years the mean is under 0.5 m³/s. | HOLDS | maxan site and pilot per-year spawning: 80 of 94 under 0.5 |
| 210 | chinook_sites.md:129 | From 1951–1980 to 2016–2025, the same inverse-distance route gives −45 % (−67..−11) in ... | HOLDS | maxan site section 5 carried column |
| 211 | chinook_sites.md:131 | Of the 50 years before 1981, Quick supplies 31 in the migration window and 30 in the sp... | HOLDS | pilot section 4 Limit lines and rule |
| 212 | chinook_sites.md:131 | Only the migration-window mean was used to choose a method; the rest is reported and de... | HOLDS | pilot section 4 Limit lines and rule |
| 213 | chinook_sites.md:133 | **Snow and the pilot's window flows** (both predictors, percent change in the migration... | HOLDS | departure_snow section 2: table, 8 intervals, r .50-.57, single-predictor and lag-1 ranges |
| 214 | chinook_sites.md:142 | All eight intervals exclude zero. | HOLDS | departure_snow section 2: table, 8 intervals, r .50-.57, single-predictor and lag-1 ranges |
| 215 | chinook_sites.md:142 | Peak snow and melt date are correlated (r = 0.50 to 0.57 over the migration-window fits... | HOLDS | departure_snow section 2: table, 8 intervals, r .50-.57, single-predictor and lag-1 ranges |
| 216 | chinook_sites.md:142 | In the spawning window R² is at most 0.07 and every slope's interval spans zero. | HOLDS | departure_snow section 2: table, 8 intervals, r .50-.57, single-predictor and lag-1 ranges |
| 217 | chinook_sites.md:142 | The residuals show little year-to-year persistence (lag-1 autocorrelation −0.07 to 0.19). | HOLDS | departure_snow section 2: table, 8 intervals, r .50-.57, single-predictor and lag-1 ranges |
| 218 | chinook_sites.md:142 | In all three watersheds peak snow over 2011–2025 averaged about 10 mm (3 to 4 %) less t... | HOLDS | departure_snow section 3 plus arithmetic -16.8 %, -10.8 % |
| 219 | chinook_sites.md:142 | Applying Maxan's migration-window slopes to that change gives −17 % on the extended ser... | HOLDS | departure_snow section 3 plus arithmetic -16.8 %, -10.8 % |
| 220 | chinook_sites.md:142 | The pilot measured −14 % and −3 % between 2011–2025 and the years before 1981, which re... | HOLDS | pilot section 4; carried pre 29 years incl. pre-1950 (snow report '<1950 8') |
| 221 | chinook_sites.md:144 | In 1950 and 1951 the carried departure equals Houston's, its only donor with a value th... | HOLDS | departure_snow sections 2 (36, <1950 8) and 5 (values, donors) |
| 222 | chinook_sites.md:146 | Houston has 36 fitted years: 8 of its 44 complete migration windows fall before 1950, a... | HOLDS | departure_snow sections 2 (36, <1950 8) and 5 (values, donors) |
| 223 | chinook_sites.md:147 | Of Maxan's extended years since 1950, Buck Creek supplies most since 1973; in the migra... | HOLDS | departure_snow sections 2 (36, <1950 8) and 5 (values, donors) |
| 224 | chinook_sites.md:151 | **Registered:** 2026-11-25, before any score existed. | HOLDS | departure_donors_rule.R header; commit a7455e45 |
| 225 | chinook_sites.md:155 | As seen before registration (2026-11-25, throwaway probes; the report's section 1 resta... | HOLDS (limit) | donor report section 1 (75, 0, 71); box part has no tracked producer, note says probes |
| 226 | chinook_sites.md:155 | They hold 185 complete migration window-years, 179 of them in 2010 or later; 36 station... | HOLDS | donor report section 1: 185, 89+90, 36, 33 |
| 227 | chinook_sites.md:155 | In the four chinook boxes, Maxan and Gosnell hold 2 such stations with 2 window-years e... | NOT CHECKABLE | box counts from throwaway probes; note says so and dates them |
| 228 | chinook_sites.md:157 | The only route open is an estimated baseline: each station is extended into 1981–2010 f... | HOLDS | rule header: estimated baseline route; OLS property |
| 229 | chinook_sites.md:157 | An OLS fit's residuals sum to zero over its fit years, so a station's level over those ... | HOLDS | rule header: estimated baseline route; OLS property |
| 230 | chinook_sites.md:157 | No gain is the likely result today. | HOLDS | rule header: estimated baseline route; OLS property |
| 231 | chinook_sites.md:159 | The test, held out province-wide: every natural HYDAT gauge in its own box's departure ... | HOLDS | departure_donors_rule.R 'per held-out gauge' and 'verdict' |
| 232 | chinook_sites.md:159 | The score is the RMSE of the log departure from the gauge's own 1981–2010 mean over the... | HOLDS | departure_donors_rule.R 'per held-out gauge' and 'verdict' |
| 233 | chinook_sites.md:159 | The route ships if the median paired difference is at most −0.01 leave-one-gauge-out an... | HOLDS | departure_donors_rule.R 'per held-out gauge' and 'verdict' |
| 234 | chinook_sites.md:163 | **The donor pool stays HYDAT-only. | HOLDS | donor report sections 2-3: medians, intervals, cov_day |
| 235 | chinook_sites.md:163 | The 90 % interval on each median lies above zero. | HOLDS | donor report sections 2-3: medians, intervals, cov_day |
| 236 | chinook_sites.md:163 | Every other scored statistic and window has a positive median too, except the migration... | HOLDS | donor report sections 2-3: medians, intervals, cov_day |
| 237 | chinook_sites.md:167 | **The loss is in the year-to-year pattern, not only the level. | HOLDS | donor report section 4: NSE .827/.750, error, slopes -3.55..6.76 |
| 238 | chinook_sites.md:167 | The centred log NSE on the scored years, which removes each series' mean, falls from 0.... | HOLDS | donor report section 4: NSE .827/.750, error, slopes -3.55..6.76 |
| 239 | chinook_sites.md:167 | A station's fit on its 3 to 8 fit years gives slopes from −3.55 to 6.76 on the nearest ... | HOLDS | donor report section 4: NSE .827/.750, error, slopes -3.55..6.76 |
| 240 | chinook_sites.md:168 | Keeping only stations with at least 5 fit years shrinks the loss to +0.013 (23 gauges);... | HOLDS | donor report section 5 |
| 241 | chinook_sites.md:168 | No sensitivity would ship. | HOLDS | donor report section 5 |
| 242 | chinook_sites.md:169 | A station among the five nearest pushes out a HYDAT gauge: 210 of 263 scored gauge-year... | HOLDS | donor report section 4 and 1: 210/263, 0.0014, 225/392, 75, 25 stations |
| 243 | chinook_sites.md:169 | In the 2011–2025 years in which none of the chosen stations has a value, the carry reno... | HOLDS | donor report section 4 and 1: 210/263, 0.0014, 225/392, 75, 25 stations |
| 244 | chinook_sites.md:170 | **Who they are:** 225 of 392 held-out gauges have a candidate in their box, but a stati... | HOLDS | donor report section 4 and 1: 210/263, 0.0014, 225/392, 75, 25 stations |
| 245 | chinook_sites.md:172 | The test found no fault in their day status; the loss comes from estimating a 1981–2010... | HOLDS (limit) | donor report eligible list: 31 of 33 start 2010 or later (other exception 61004, 2008; only 1AHA040 is named, count is right) |
| 246 | chinook_sites.md:172 | At the four chinook boxes nothing moves: Maxan's and Gosnell's two stations hold 2 wind... | HOLDS | donor report section 1/stations; station_sources.md box table |
| 247 | chinook_sites.md:172 | The test can be rerun as the records lengthen; with the most any station holds now at 8... | HOLDS | donor report eligible fit years, max 8 |
| 248 | chinook_sites.md:9 | TABLE-LEAD(for table at 11): A row reading "not inspected" or "none observed" does not ... | HOLDS | table lead-ins: tables checked against use report, life_history csvs, sections 5/6 |
| 249 | chinook_sites.md:28 | TABLE-LEAD(for table at 30): Each site runs under the Bulkley's chinook salmon life his... | HOLDS | table lead-ins: tables checked against use report, life_history csvs, sections 5/6 |
| 250 | chinook_sites.md:41 | TABLE-LEAD(for table at 43): Carried: median per-gauge centred log NSE at the box's PCI... | HOLDS | table lead-ins: tables checked against use report, life_history csvs, sections 5/6 |
| 251 | chinook_sites.md:53 | TABLE-LEAD(for table at 55): The shipped route's held-out score for each statistic, on ... | HOLDS | table lead-ins: tables checked against use report, life_history csvs, sections 5/6 |
| 252 | chinook_sites.md:75 | TABLE-LEAD(for table at 77): **The shipped carried route:** | HOLDS | table lead-ins: tables checked against use report, life_history csvs, sections 5/6 |
| 253 | chinook_sites.md:87 | TABLE-LEAD(for table at 89): **The extended (filled-in) record**, at the gauged sites (... | HOLDS | table lead-ins: tables checked against use report, life_history csvs, sections 5/6 |
| 254 | chinook_sites.md:121 | TABLE-LEAD(for table at 123): Every extended year rests on one donor, through a relatio... | HOLDS | pilot section 4 table; departure_snow section 2 table |
| 255 | chinook_sites.md:133 | TABLE-LEAD(for table at 135): **Snow and the pilot's window flows** (both predictors, p... | HOLDS | pilot section 4 table; departure_snow section 2 table |
| 256 | fwapg_mad_method.md:3 | **Verified:** 2026-11-27 (fwapg's method, read at `6aa6c2d`, the `main` of both `smnorr... | HOLDS (limit) | fwapg files read at 6aa6c2d via gh this round; extras/discharge last commit 2026-07-13; fork's main not re-read |
| 257 | fwapg_mad_method.md:3 | Every parity, sampling and timing figure is a record of the runs of 2026-09-25 and 2026... | HOLDS | note dates every run figure |
| 258 | fwapg_mad_method.md:7 | Download PCIC historical BASEFLOW and RUNOFF (`TPS_gridded_obs_init`, PNWNAmet forcing)... | HOLDS | discharge.sh at 6aa6c2d |
| 259 | fwapg_mad_method.md:7 | `discharge.sh` still requests `data.pacificclimate.org` with `curl` and no `-L`; that h... | HOLDS (limit) | discharge.sh curl without -L; the 301 is dated in pcic_hydrology.md, not requested |
| 260 | fwapg_mad_method.md:8 | `cdo -timmean -yearsum` on each, then `cdo add`, giving mean annual mm per cell. | HOLDS | discharge.sh cdo lines |
| 261 | fwapg_mad_method.md:9 | **Centroid point sample:** `ST_Value(rast, ST_Transform(ST_Centroid(geom), 4326))` per ... | HOLDS | discharge02_load.sql |
| 262 | fwapg_mad_method.md:10 | Both are rounded to 5 decimals. | HOLDS | discharge03_wsd.sql round() and sum() |
| 263 | fwapg_mad_method.md:13 | If no upstream polygon has a value, the result is NULL. | HOLDS | discharge03_wsd.sql round() and sum() |
| 264 | fwapg_mad_method.md:14 | **Mainstems of order ≥ 8 are skipped** (runtime): on each watershed code carrying such ... | HOLDS | discharge03_wsd.sql order8rivs |
| 265 | fwapg_mad_method.md:23 | In SALR, 384 of 9,384 segments (4 %) are absent from `fwa_streams_watersheds_lut`, most... | HOLDS | issue-1 archive findings.md lines 204-209 |
| 266 | fwapg_mad_method.md:23 | All 9,000 segments in the lookup have fwapg MAD. | HOLDS | issue-1 archive findings.md lines 204-209 |
| 267 | fwapg_mad_method.md:29 | Two small LSAL polygons (wscode `100.591289`) sit upstream of two SALR polygons, becaus... | HOLDS | issue-1 archive findings.md lines 204-209 |
| 268 | fwapg_mad_method.md:43 | **Verified:** 2026-09-25 (the same run and record) | HOLDS | section date matches archive record |
| 269 | fwapg_mad_method.md:53 | Centroid sampling gives a small watershed the value of whichever single ~25–30 km² cell... | NOT CHECKABLE | grid-cell description of run; carried unchanged |
| 270 | fwapg_mad_method.md:59 | fwapg, bcfishpass and fresh all compute upstream aggregates with the pairwise `FWA_Upst... | HOLDS (limit) | fwapg half read in discharge03_wsd.sql; bcfishpass and fresh not read, carried |
| 271 | fwapg_mad_method.md:59 | `wet_upstream_sums()` computes the same sets without any pairs: | HOLDS (limit) | R/wet_upstream_sums.R; irregular polygons still use SQL pairs, as the bullet below says |
| 272 | fwapg_mad_method.md:62 | The `FWA_Upstream` set of watershed `(W, L)` is at most two contiguous ranges of the `(... | HOLDS | R/wet_upstream_sums.R two ranges, segment tree |
| 273 | fwapg_mad_method.md:65 | Computed with a segment tree, so there is no cancellation against basin-scale totals. | HOLDS | R/wet_upstream_sums.R two ranges, segment tree |
| 274 | fwapg_mad_method.md:66 | Since #76 the fetches return polygons and pairs in id order and the sums add polygons t... | HOLDS | R/wet_upstream_sums.R id ordering; ORDER BY in R/wet_ws_fetch.R |
| 275 | fwapg_mad_method.md:66 | Before it, a shuffled Fraser moved the sums by at most 4.4e-16 relative (#76's measurem... | HOLDS | NEWS.md:135 and #76 archive README |
| 276 | fwapg_mad_method.md:69 | The whole Fraser (644,710 polygons) took about 13 s (fetch 1.5 s, pairs 1.2 s, sums 4.2... | HOLDS | issue-2 archive findings.md:68; data/checks/upstream_area_100_{full,sample}.txt timings |
| 277 | fwapg_mad_method.md:72 | A live `FWA_Upstream` re-check of **all 1,731** found wet = live on every one (maximum ... | HOLDS | data/checks/upstream_area_100_full.txt and _sample.txt (3.1 h from archive record) |
| 278 | fwapg_mad_method.md:72 | A 401-polygon sample gives the same result in minutes (`data/checks/upstream_area_100_s... | HOLDS | data/checks/upstream_area_100_full.txt and _sample.txt (3.1 h from archive record) |
| 279 | fwapg_mad_method.md:74 | Every other use should take accumulated area. | HOLDS | follows from upstream_area reports |
| 280 | fwapg_mad_method.md:82 | PCIC historical, 1981–2010, fetched one year at a time: 60 files, 24 min on the first f... | NOT CHECKABLE | 24 min first fetch: archive record only (issue-2 findings:100); note dates section |
| 281 | fwapg_mad_method.md:82 | The subset has 21,648 cells; the 6,694 NA cells lie outside the PCIC model domain (NA o... | HOLDS | data/basin/100_report.txt |
| 282 | fwapg_mad_method.md:91 | Segments that pass differ by at most 1.8e-8 relative beyond rounding; those that fail s... | HOLDS | issue-2 archive review-p4-round3.md:87 |
| 283 | fwapg_mad_method.md:91 | There is nothing between 2e-8 and 1e-6, so any threshold in that gap gives the same count. | HOLDS | issue-2 archive review-p4-round3.md:87 |
| 284 | fwapg_mad_method.md:93 | **Every one of the 2,189 remaining differences is attributed. | HOLDS | 100_report.txt cause table |
| 285 | fwapg_mad_method.md:93 | A cause counts as reproduced only when rebuilding with it applied makes the segment mat... | HOLDS | 100_report.txt cause table |
| 286 | fwapg_mad_method.md:103 | So the flip, never-valued and lookup causes (1,403 segments) are shown to be fwapg-side... | HOLDS | 100_report.txt cause table |
| 287 | fwapg_mad_method.md:107 | wet gives 2,476 m³/s (centroid) or 2,477 m³/s (area-weighted), against HYDAT's 1981–201... | HOLDS | 100_report.txt Hope block |
| 288 | fwapg_mad_method.md:107 | That is plausible for unrouted VIC-GL with no regulation correction. | HOLDS | 100_report.txt Hope block |
| 289 | fwapg_mad_method.md:108 | fwapg has no value here (order ≥ 8). | HOLDS | 100_report.txt Hope block |
| 290 | fwapg_mad_method.md:116 | **Covered denominator:** negligible for most segments, but **54 change by more than 5 %... | HOLDS | 100_report.txt sensitivity |
| 291 | fwapg_mad_method.md:118 | 29 segments are NA under area sampling only. | HOLDS | 100_report.txt sensitivity |
| 292 | fwapg_mad_method.md:29 | TABLE-LEAD(for table at 31): Two small LSAL polygons (wscode `100.591289`) sit upstream... | HOLDS | table lead-ins: SALR tables vs issue-1 findings; Fraser tables vs 100_report.txt |
| 293 | fwapg_mad_method.md:43 | TABLE-LEAD(for table at 45): **Verified:** 2026-09-25 (the same run and record) | HOLDS | table lead-ins: SALR tables vs issue-1 findings; Fraser tables vs 100_report.txt |
| 294 | fwapg_mad_method.md:82 | TABLE-LEAD(for table at 84): The subset has 21,648 cells; the 6,694 NA cells lie outsid... | HOLDS | table lead-ins: SALR tables vs issue-1 findings; Fraser tables vs 100_report.txt |
| 295 | fwapg_mad_method.md:93 | TABLE-LEAD(for table at 95): A cause counts as reproduced only when rebuilding with it ... | HOLDS | table lead-ins: SALR tables vs issue-1 findings; Fraser tables vs 100_report.txt |
| 296 | fwapg_mad_method.md:110 | TABLE-LEAD(for table at 112): **Sensitivity at basin scale** (per segment, vs the live ... | HOLDS | table lead-ins: SALR tables vs issue-1 findings; Fraser tables vs 100_report.txt |
| 297 | README.md:10 | How fwapg builds `fwa_stream_networks_discharge` (read at its current code), how closel... | HOLDS (limit) | note's cause table: all differences attributed; 786 'consistent with, not reproduced' |
| 298 | README.md:12 | How measured flow is set against its normal: the daily sources and where they meet, ice... | HOLDS | README rows vs the two notes' sections |
| 299 | README.md:13 | each box's held-out scores; | HOLDS | README rows vs the two notes' sections |
| 300 | README.md:13 | change from 1951–1980 to 2016–2025 by stream and life history timing window, on the shi... | HOLDS | README rows vs the two notes' sections |
| 301 | chinook_sites.md:115 [R] | Under the Bulkley windows the median is +0.04 (migration) and +0.19 (spawning); in the ... | HOLDS | gosnell_bulk/morr normal-error rows: medians, q75, median /r/ 0.315/0.155 and 0.232/0.126 recomputed |
| 302 | chinook_sites.md:115 [R] | Under the Morice's the medians are +0.05 and −0.00, and the spawning upper quartile is ... | HOLDS | gosnell_bulk/morr normal-error rows: medians, q75, median /r/ 0.315/0.155 and 0.232/0.126 recomputed |
| 303 | chinook_sites.md:115 [R] | The spawning-window normal is the weak part: over the 29, its median absolute log error... | HOLDS | gosnell_bulk/morr normal-error rows: medians, q75, median /r/ 0.315/0.155 and 0.232/0.126 recomputed |
| 304 | chinook_sites.md:111 [R] | **Snow gauges. | HOLDS | snow reports 'Snow gauges' lines; departure_sites.csv snow_gauges |
| 305 | chinook_sites.md:111 [R] | Maxan's (08EE003, 08EE013) are named in the site table. | HOLDS | snow reports 'Snow gauges' lines; departure_sites.csv snow_gauges |
| 306 | chinook_sites.md:111 [R] | They can therefore depend on the windows: Swift's are 08LB038 and 08KA007 under UFRA an... | HOLDS | snow reports 'Snow gauges' lines; departure_sites.csv snow_gauges |

## Findings
- **[severity: bug]** research/station_flow_departure.md:25 (member 92) — "08EE003 ran April or May to October from 1981 to 1998" is false for three of those years. In HYDAT 20260717 `DLY_FLOWS`, 1982, 1983 and 1984 run April to 30 September, with no October day (1981 has one October day, 1 October). The sentence was written in 170bec24, on this branch; origin/main said "April/May–October until 2010". The header's re-read list names only the ice and August figures from HYDAT, so nothing re-derived this one. Fix: "April or May to September or October (September only from 1982 to 1984; November days in some years from 1985)". The November qualifier is needed too: 1991 ends on 25 October.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
- **[severity: fragile]** research/chinook_sites.md:3 (member 146) — the Verified line says "every figure below" was re-read against the use report, the site, snow, pilot and donor reports, with the pre-registration counts being "the rule header's". That is wider than the sources. "east of about −118.5°" is in none of those reports (it comes from the #126 archive; no data/checks file listed holds it). That 08EE003, 08EE013 and 08JA016 hold no record from 1952 to 1970 comes from HYDAT (it holds, re-derived this round; the reports show only the 10-year base). The rule header's "as seen before registration" block has no box counts ("Maxan and Gosnell hold 2 such stations ... Naver 6"), and the note's own body says those come from probes with no tracked producer. Fix: "the figures below against ... except the −118.5° longitude (#126's archive), the 1952–1970 donor gap (HYDAT) and the probes' box counts".
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
