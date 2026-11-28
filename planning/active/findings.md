# Findings — Backlog move 12: Research files around the current state (#189)

## Issue context

**If we do it:** four research notes that grew one section per issue read as what is true now, each number checked against its report, and the revise-in-place rule #181 tests is refined over four files. **If we never do:** readers replay issue-ordered histories to learn what ships today, and `research/station_flow_departure.md` keeps statements last checked on 2026-09-28.

Order: `planning/backlog.md`, move 12. Run `/planning-init <this issue>`: one phase, one PR.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 12, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

## Batch 14: research files around the current state

**Why here:** one pass, one method (rewrite around the current state, move narrative to archive READMEs, check every number, fix links), run over the files soul's research check flags. It waits on move 10, which rewrites `research/chinook_sites.md`.

**Touches:** `research/water_balance_method.md`, `research/chinook_sites.md`, `research/discharge_publish.md`, `research/station_flow_departure.md`, the links into them in `CLAUDE.md`, the articles and `planning/archive/` READMEs.

**Decided at the gate:** none beyond #181's rule; whichever of move 10 and this move lands second folds the other's `research/chinook_sites.md` changes in.

| issue | title |
|---|---|
| #181 | Consolidate research/water_balance_method.md and research/chinook_sites.md around the current state |
| #183 | Consolidate research/discharge_publish.md around the current state |
| #184 | Consolidate research/station_flow_departure.md around the current state, and re-verify it |


## Planning exploration (2026-11-27, at 49afd870)

`research_check.sh` (soul's published copy):

| file | prose words | issue-headed sections | verified | flag |
|---|---|---|---|---|
| `water_balance_method.md` | 16,109 | 16 | 2026-11-13 | words, sections |
| `discharge_publish.md` | 4,546 | 3 | 2026-11-15 | words, sections |
| `station_flow_departure.md` | 3,186 | 5 | 2026-09-28 | words, sections |
| `chinook_sites.md` | 3,221 | 2 | 2026-10-28 | words |
| `fwapg_mad_method.md` | 1,037 | 2 | 2026-09-25 | age |

- In `water_balance_method.md`, a separate count of non-table words gave about 12,500 in section 0 and 3,578 in sections 1–7.
  "Skill with CGIAR AET, as built in #11" is the largest subsection (2,725), and the current routed-PCIC and segment-pick
  statements are nested under it.
- Hashed or registered scripts cite the file by section (`scripts/wb_cv_lib.R`, `wb_gate_rule.R`, `wb_aet_compare.R`,
  `wb_fit_accept.R`), so those anchors cannot move without staling a fit.
- `research/station_snap.md` cites "Reproducing #15 and #18"; `research/station_sources.md` cites chinook_sites'
  "Natural stations outside HYDAT as donors". Many archive READMEs, plans and review files quote section names.
- Links to the five files outside `planning/archive/`: `CLAUDE.md`, `NEWS.md` (past entries, file-level), `research/`,
  two vignettes and one article (file-level links).
- Every plain-named `data/checks/*.txt` or `data/basin/*.txt` path the five files cite exists and is tracked (wildcard
  forms not checked). The upstream-area reports are in `data/checks/`. The Fraser parity report is the tracked
  `data/basin/100_report.txt` (my first listing missed it; the Plan review found it). The SALR parity tables are in the #1
  archive.
- Checked after the Plan review, each disagreeing with its note: the routed-days figures
  (`segment_daily_output_20260717.txt` lines 21-27), the nested selection (`wb_aet_compare_20260717.txt` lines 29, 40,
  47: 30.7), 08EE013's ice days (HYDAT 20260717: 8,101 of 18,620), and the mixed held-out pools in `chinook_sites.md`
  (Maxan's site report, spawning mean: 0.49 in section 3, 0.50 to 0.66 in section 6).
- #76 is open, though `water_balance_method.md`'s follow-ups read "Done in code".
- The main checkout's `data/pcic/` holds cached BASEFLOW and RUNOFF files; the plan reruns nothing, and whether they cover
  the parity runs was not checked.
- Members #181, #183, #184 read `FREE`; #181, #183, #184 and #206 are open with no label; no open pull request. #189's
  body table lacks #206, which `planning/backlog.md`'s batch 14 names.
- None of the member issues carries a comment.

## Phase 1: baseline (2026-11-27, after merging origin/main at f1c698d3)

Moved on main since the park, re-read against the phases: `CLAUDE.md`, `R/wet_station_daily.R`, `research/README.md`,
`research/station_sources.md` (Hakai's four own stations, #233; Phase 3's "sources" check includes them), five
`data/checks/` reports none of the five files cites, and the #235, #238 and #242 archives. The plan stands.
Open PR #257 (move 27) also edits `research/water_balance_method.md`, `research/README.md`, `research/pcic_scenarios.md`
and `CLAUDE.md`.

`research_check.sh` (soul ee19c925) at the merge repeats the planning table exactly: the five files' words, sections,
dates and flags are unchanged.

Cited reports, by file, with the last commit of each beside the file's Verified date:

| file (verified) | cited `data/checks` reports | newest commit among them |
|---|---|---|
| `discharge_publish.md` (2026-11-15) | `discharge_publish_20260717` (11-15), `segment_daily_output_20260717` (11-13) | 2026-11-15 |
| `station_flow_departure.md` (2026-09-28) | `station_departure_report` (09-28), `departure_pilot_20260717` (10-25), `departure_snow_20260717` (10-26), `departure_interval_coverage` (10-30) | 2026-10-30, after Verified |
| `chinook_sites.md` (2026-10-28) | `chinook_sites_use` (10-28), `departure_interval_coverage` (10-30), `departure_donors_20260717_20261028` (11-25), `departure_site[_snow]_*` (11-18 and 11-25) | 2026-11-25, after Verified |
| `fwapg_mad_method.md` (2026-09-25) | `upstream_area_100_full`, `_sample` (09-26) | 2026-09-26, after Verified |
| `water_balance_method.md` (2026-11-13) | about 55 `data/checks` reports, `wb_*` the bulk | 2026-11-25 (`pcic_coverage`, site reports), after Verified |

`planning/active/numbers_check.py` was proven on a copy of `discharge_publish.md`: 0 candidates unchanged; with one
`33.23` removed and `987654` appended, both were listed.

## Phase 2: `research/discharge_publish.md` (#183)

Read on 2026-11-27: the live manifest and `receipt.json` (anonymous GET), `data/checks/discharge_publish_20260717.txt`
(R), `data/checks/segment_daily_output_20260717.txt` (D), `R/wet_db_load.R`, `R/wet_catalog.R`,
`R/wet_segment_monthly.R`, `R/wet_values_compare.R`, `scripts/discharge_publish.R`, `scripts/discharge_publish_lib.R`.

**Disagreed with its source (the note's error: not updated at #163's republish):** routed-day clamp 1.092 % → 1.183 %
(14,577,433), mid-network 0.050 % → 0.054 % (53,610 of 99,306,645), worst day 874 → 944 segments; days-vs-months
1,869,949 (4.614 %) / 1,021,601 → 1,908,991 (4.711 %) / 1,036,583; sizes summing to 33.23 GB (build b4bbc50) →
33.36 GB (1.16 / 0.73 / 31.48); "monthly parts byte-identical to 8ca2dee" (no longer, #163 changed drainage 100);
"Monthly is the finest step both sources share" (daily is published for both). The tracked report's check table
agreed row by row.

| claim kept | source | build it names | verdict |
|---|---|---|---|
| build identity, crate, arrow, duckdb, built 2026-11-15 | manifest `provenance`, `built`; R head | a0318b7 | agrees |
| 512 parts; rows 102,790,688 / 41,904,356 / 2,886,046,240; 43 / 24 / 445; GB; largest SETN 373 MB | manifest `parts` | a0318b7 | agrees |
| 247 fit files, 1.44 GB; parts digest d554e3aa…; recipe_id; receipt bytes and md5 | manifest, R, `wet:::wet_catalog_digest()` on the live catalog | a0318b7 | agrees |
| routed table, 40,524,444 rows, 3,377,037 segments, total, fwapg 5d50cc1 | manifest `sources`, R | a0318b7 | agrees |
| AET refusal | `discharge_publish.R` L243-247 | tree | agrees |
| PUBLISH skips a part already live by md5 | `discharge_publish.R` L111-123 | tree | agrees |
| 2 h 59 min; 759 files hashed in 94 s | #164 archive; R (94 s) | a0318b7 | agrees (duration from the archive) |
| 15,040,448,264 compared; the nine check rows and their diffs; 0 tie steps | R (15 rows, summed) | a0318b7 | agrees |
| 1e-9 tolerance | `wet_values_compare()` default | tree | agrees |
| daily table: 13,961,436 rows, 38,146 sub-basins, 3,377,037 weights | R, D | 5d50cc1 | agrees |
| months rebuilt = fwapg on 40,524,444, 0 ties | D | 5d50cc1 | agrees |
| clamp, mid-network, worst day, days-vs-months, 197.24528, -0.12366 | D L18-27 | 5d50cc1 | corrected (above) |
| fwapg clamp shares 0.978/0.977/0.049/0.048 against 1.092/0.050 | #99 | 7c30f58-era | not re-read: labelled as the earlier build |
| weekly parity in five groups | #99 probe | earlier | not re-run: said so, row count left in #99 |
| 37 of 847 February day-years | 7 leap years in 1981-2010; 30×28+7 | arithmetic | agrees |
| balance days: 38,680,224, 1.2e-15, 1.3e-15 | D L15-16 | 5d50cc1 | agrees |
| row groups of 2,048 segments' days; ~28× rows; ~6 GB part-200 | `discharge_publish.R` L381; manifest rows (28.08); #99 | | agrees |
| 507 row groups in 43 segment parts | R | a0318b7 | agrees |
| fresh subquery 4,532,843 = 3,213,337 + 1,319,506 | R "What a reader sees" | a0318b7 | corrected (the note gave #103's split) |
| reader 3.3 s / 27 s, about 131 of 507 | #59 archive | 2026-10-14 | not re-timed: dated |
| load into `wet_load` 102 s, 43 parts | #164 archive | 2026-11-15 | not re-timed: dated |
| load 23.9 min / 20 GB, 10.7 / 8.5; 39 / 17 GB; reloads 2× and 4× (46.1, 100.6 min) | #7, #77, #103 archives | earlier builds | not re-timed: said so |
| query 6.7 s, 0.7 s, 197 s | #7 archive | earlier build | not re-timed: said so |
| versioning, lifecycle, policy, encryption | the note's own dated probes | 2026-10-12/24 | not re-read (no AWS read): dated |
| hydromosaic 68,716 outlets, 19 series, 9 GCMs | the note's dated probe | 2026-10-12 | not re-read (robots.txt): dated |

Ledger of the old file:

| old paragraph or bullet | disposition |
|---|---|
| Verified line | replaced; short |
| Status paragraph, upload by upload | current build kept ("What is published now"); history already in the #77, #102, #103, #163, #164, #165 archives, or moved to #76, #91, #99, #101, #163; "PUBLISH writes the live line, no BUILD follows" kept in "How a build is checked" |
| Naming rule, table, level bullets, v2 decision, `segment_daily` | kept; two stale sentences fixed (above) |
| Hive block, key table, nine bullets | kept; the routed 1951-2012 history dropped from `period` (in #103) |
| Where: five bullets | kept; the manifest bullet's fingerprint history already in #101/#103, the acb820f source moved to #101 |
| Receipt and fit: three paragraphs | kept; live recipe_id and hashing time added |
| Checks intro, table, tolerance paragraph | kept; table's history parentheses and older fingerprints dropped (in #64, #101, #103); BUILD timings in #64, #99, #163 |
| Article and publish-report paragraph | kept |
| Routed days intro and four bullets | kept with current figures; old rows moved to #163, old clamp bullet to #99; the 4-of-6 tie probe and 200,006 values already in #99 |
| Why not STAC | kept |
| Postgres: join, reader, wet_load, load cost | kept |
| Postgres: 2026-10-13 load, 10-15 and 10-19 reloads | one "Cost of a load" paragraph; dated detail already in #7 and #77, #103's moved there |
| Evidence: hydromosaic, policy, drainage codes | kept |
| Evidence: first publish bullet | already in the #7 discharge-upload README (03:29-03:31, 67 verified, part-400) |

## Phase 3: `station_flow_departure.md` (#184) and `chinook_sites.md` (#181)

### Which facts live where

| facts | home |
|---|---|
| sources and seams, ice and provisional winters, seasonal-gauge baselines, residuals, method choices | `station_flow_departure.md` |
| 2016-2025 against 1981-2010 at the two measured gauges, nested catchments, the resampled range | `station_flow_departure.md` |
| extension and carry rules, the pool, held-out scores, record-size thresholds; `covariance_pick` in one paragraph (pointer to `pcic_hydrology.md`); snow specification, verdict, parity, method limits | `station_flow_departure.md` |
| which streams, windows per group, per-site scores, current changes, snow per site, Gosnell's normal | `chinook_sites.md` |
| Maxan by inverse distance (1931-2024 changes, the pilot's snow slopes and their site-specific limits) | `chinook_sites.md`, "Maxan by inverse distance", pointed to from the method file where the short-record article's link lands |
| natural stations outside HYDAT as donors | `chinook_sites.md` (heading kept) |

### Disagreements found (all ours: a note not updated, or a wider sentence than its source)

| old statement | what the source says |
|---|---|
| 08EE013 ice 7,885 of 18,193 days | HYDAT 20260717: 8,101 of 18,620 (43.5 %). The old count is the 2025-10-14 release's (#25 archive) |
| August 1981-2010 monthly median 0.73 | 0.754 (mean 0.95); range 0.14-4.12 and second-lowest rank agree |
| provisional `Symbol` NA on every row | 2026-11-27: 3 rows (08EE013) and 8 (08EE003) carry PN, PX or SD, none in DJF 2025-26 |
| Buck provisional DJF 2025-26 6.5-15 m3/s (present tense) | true of the 2026-10-01 bundle (6.56, 7.75, 15.0); on 2026-11-27 the archive reads 0.68, 0.65, 0.68. Cause not traced |
| archive "since 2024-10"; an old HYDAT leaves a hole until water-temp-bc#19 | the archive holds both stations from 2016; #19 closed 2026-09-30; 2024 is complete |
| 08EE003 "April/May-October until 2010, year-round from 2011" | seasonal 1981-1998 (from April to 1988, else 1 May; ending 30 September 1982-1984 to 30 November), spot values 2000-2009, none 1999, year-round from September 2010 (round 5 corrected the first draft) |
| "54-87 % below ... August, September and JJA in every year 2023-2026" (moved to #25) | no August 2025 row at 08EE003, no September 2026 row at either; the percentages agree on the rows that exist |
| 08EE003 trend p "0.07-0.32" for the same windows (moved to #25) | JJA, September mean, September min7 and spawning: 0.065-0.26 (0.32 is August min7) |
| Gosnell spawning-normal upper quartile +60 %; 25 of 29 picks routed | the 2026-10-30 report's (build before #163: log q75 0.468). Current report: 0.384 (+47 %), 29 of 29 routed |
| spawning drop comparisons and held-out "from X to Y" pairs | held-out pairs mixed section 3's all-donor pool with section 6's covered pool; the new table is section 6 throughout (Swift's distance too) |
| snow R2 .41/.41/.51/.51 and spawning .01/.16/.02/.04 "at every site" | those are inverse-distance, peak-SWE-only fits; on the shipped route: .42/.41/.53/.48 and .01/.16/.04/.20 |
| "20-30 years of 1951-1980 on every other route" | Gosnell MORR migration min7 17, Naver BULK spawning cov_day 18, Naver COTR migration max 14; and Maxan's carried max has 30, not 10 (code-check round 1) |

The Plan review also called false "the spawning drop is largest at Maxan and Naver" under `covariance_pick`. It is true as a
ranking (-66, -35, then Gosnell -29), and `flow-change-sparse-gauges.Rmd` guards exactly that; the new note prints the
whole order.

The 2023-2026 block: moved to the #25 archive, not kept (its windows were examples pending knowledge#25, since replaced
by the cited windows and 2016-2025).

### Claims kept, by source (verified 2026-11-27)

| claims | source | verdict |
|---|---|---|
| sources table, join rule, 540 days, non-HYDAT numbers | `R/wet_station_daily.R` | agrees |
| archive extent, 2023's 75 days, join with no gap, symbols, DJF provisional values | read-only `wet_provisional_daily()`; bundle `station_daily.rds` | corrected (above) |
| ice shares; March 2025 `NO_DAYS` 31 with two values | HYDAT 20260717 query | corrected (ice), agrees |
| GeoMet approved end | not re-read: dated 2026-09-28 | dated |
| approved Dec, Jan and Feb monthly means from 1981: 0.025-3.94, median 0.55 (round 1: the first draft set winter-pooled range beside a monthly median); August figures | HYDAT 20260717 | restated from the read |
| seasonal gauging; 1 DJF year; complete years 1971, 2011-2024; 10 and 5 year rules | bundle months table; `station_departure_report.txt`; `scripts/station_departure.R` | corrected (months), agrees |
| window rules, min7, cov_day, 0.8 | `R/wet_window_stats.R` | agrees |
| Mann-Kendall message | cd behaviour, not re-read | dated in the header |
| 2016-2025 changes, 12/12, 11, 17/18, Buck 2016, baseline medians, gaps, 85/93 and 37/46 | bundle, recomputed with `wet_window_stats()` | agrees |
| catchments 567 / 2,315 km2, 24 %, 0.997 / 0.998 | `station_map.rds` | agrees |
| coverage 0.834-0.867 | `departure_interval_coverage.txt` | agrees |
| pool 53/21/31/13; blocks 220/218; OLS/MOVE/ratio; leak-free; multi-donor; day-by-day; min7 | `departure_pilot_20260717.txt` s1-2 | agrees |
| carry .63 (.34-.75), .69 of 12, .92, .57, .49, .23 | same, s3 | agrees |
| covariance_pick .72/.67/.48/.71, 290 gauges | `pcic_hydrology.md` / `departure_pcic_20260717.txt` as cited | kept as the pointer's summary |
| Maxan chain, years by donor, changes and ranges, r .93/.78, 80 of 94, 31/30 | same, s4 | agrees |
| snow slopes, r, lag-1, intercepts, over-record change, -17/-11, parity | `departure_snow_20260717.txt` | agrees |
| Chinook use table and gauge notes | `chinook_sites_use.txt` | agrees |
| covered counts, scores, verdicts, shipped-route and extended tables | site reports s3, s5, s6 (7 reports) | agrees (extracted by script) |
| extension race per box; extension pools | site reports s1-2 | agrees (UFRA and COTR added) |
| interval coverage 0.904-1.000 and 0.92+; OLS band 83-85 % | site reports s5, s6, s2 (82.7-85.3) | agrees |
| snow per site, snow gauges, SWE and melt change | `departure_site_snow_*` s2, s3, s6 | corrected (route, above) |
| Gosnell normals and error | `departure_site_gosnell_*` | corrected |
| Naver donors since 1999 | `departure_site_naver_bulk` s4 per-year | agrees |
| donor test result and sensitivities | `departure_donors_20260717_20261028.txt` | agrees; "as seen before registration" counts match its s1 |
| UFRA/COTR windows and pin guard; literature | the old note; `life_history_*.csv` tests | not re-read |
| upstream states | `gh api` 2026-11-27: cd#92, water-temp-bc#19, knowledge#25/#174/#256 closed; cd#95, wet#227, wet#232 open | |

### Ledger

| old section | disposition |
|---|---|
| departure: Sources; What a departure rests on; Residuals; Method choices | kept, corrected; MAD rule kept |
| departure: Result 2023-2026 | moved whole to #25 |
| departure: Species windows first pass | moved whole to #27 station-flow-vignette |
| departure: 2022-2026 | moved whole to #27 chinook-revision; standing facts (nested catchments, 1981-1998 baseline, 2025 gaps, median/mean, dropped winter windows) restated for the current windows |
| departure: 2016-2025 | kept as a table |
| departure: Maxan pilot (#120) | method and held-out kept; Maxan's 1931-2024 results to `chinook_sites.md` |
| departure: Snow (#121) | specification, verdict, parity, method limits kept; slopes, over-record arithmetic and site limits to `chinook_sites.md` |
| chinook: Which streams | kept |
| chinook: What the method finds | moved whole to #126; Gosnell normal, snow gauges and rule amendment, Naver donors restated |
| chinook: 1951-1980 (#152) | moved whole to #152; periods, coverage tests, snow restated; Maxan distance row kept |
| chinook: covariance_pick (#147) | rule, score table, shipped changes kept; three dated bullets to #167 |
| chinook: Swift and Naver own windows | folded into "How each site is run" and the tables; the "bundle gains ..." bullet moved to #187 |
| chinook: Natural stations as donors | kept unchanged but one issue-number parenthesis |

## Phase 5: `research/fwapg_mad_method.md` (#206)

Read 2026-11-27: `smnorris/fwapg` and `NewGraphEnvironment/fwapg` `main` (both 6aa6c2d; `extras/discharge/` last changed
8af59a4, 2026-07-13, before the note's previous date); wet's three scripts and their functions, with the diff since
921f5ce1. Changed on wet's side: #76 (ordered fetches and sums), #169 (`wet_pcic_fetch()`), #46 (Hope's HYDAT release).

**Disagreements:** none in a number. Wording corrected or added: the CMIP5 label is also in fwapg's table docs
(`docs/02_tables_views.md`), not only the README and column comment; the order-8 skip is now stated as the SQL does it; the
centroid groups' source stated; `discharge.sh`'s old host. The 13 s / 2.1 GB timing's report was overwritten by the
full re-check (only the #2 findings hold it); said so. "Count in the report" is now the count, 186.

| claims | source | verdict |
|---|---|---|
| download, cdo, centroid, weighting, rounding, skip, lut, forcing, CMIP5 labels | fwapg at 6aa6c2d: `discharge.sh`, the four SQL files, README, `db/schema.sql`, docs | agrees |
| self counts as upstream; NULL handling | `discharge03_wsd.sql` joins on `FWA_Upstream`; `sum()` skips NULL. Self-inclusion not re-derived (the SALR parity is its evidence) | agrees, dated |
| SALR coverage, parity, sampling tables, LSAL polygons | #1 `findings.md` | agrees; not re-run, dated 2026-09-25 |
| two ranges, segment tree, irregular correction | `R/wet_upstream_sums.R` | agrees |
| 4.4e-16 before #76 | #76 archive (4.41e-16) | agrees |
| 204 / 1,457 irregular; 1,540 trees | #2 review files (`review-p4-round3.md`, `review-round2.md`) | agrees; said where from |
| 13 s, 2.1 GB | #2 findings | not in a current report: said so |
| 1,731 mismatches, 401 sample, 3.6e-14, 3.1 h; code-pair contradiction | `upstream_area_100_full.txt` / `_sample.txt`; #2 findings and README | agrees |
| Fraser parity, causes, flips, Hope, basin sensitivity, 3.4 min | `data/basin/100_report.txt`, `100_run.log` | agrees |
| 60 files, 24 min; order-1 and order-5 flip sources | #2 README and `review-p4-round1.md`, `round2.md`, `round3.md` | agrees |
| LILL, UEUT examples; 1.8e-8 / 5.7e-6 gap | #2 archive reviews and the note's own run | kept as the run's record |

Ledger: every section kept; the headings dropped their issue numbers; one paragraph (the article's worked parity, #28 to
#64, link removed by #71) moved to the #71 archive.

## Phase 6: what the pass did (for the archive README)

Links: no live pointer into the four files quotes a removed heading. Hits for old names are archive history and moved
blocks, left as written. One pointer inside the new notes quoted part of a heading and was made exact.
`CLAUDE.md`'s four pointers still describe their targets; no edit. `research/README.md`: four rows rewritten
(`water_balance_method.md`'s is unchanged, its file now being #261's). `research_check.sh --added origin/main`: no
issue-headed heading added. The diff touches `research/` and `planning/` only.

| file | prose words, before to after | issue-headed sections | verified | flag after |
|---|---|---|---|---|
| `discharge_publish.md` | 4,546 to 3,510 | 3 to 0 | 2026-11-27 | words |
| `station_flow_departure.md` | 3,186 to 2,283 | 5 to 0 | 2026-11-27 | none |
| `chinook_sites.md` | 3,221 to 3,647 (it took Maxan's results from the method file) | 2 to 0 | 2026-11-27 | words |
| `fwapg_mad_method.md` | 1,037 to 1,296 (dated sections) | 2 to 0 | 2026-11-27 | none |
| total | 11,990 to 10,736 (after code-check) | 12 to 0 | | |

**What it says about the revise-in-place rule #181 tests.**
- Every stale number found had been carried over from an earlier build or release under a later Verified date: the routed
  days after #163's republish, Gosnell's normal error after the same rebuild, the ice count after the HYDAT bump. The
  change that rebuilt the artifact updated its report and not the sentences that quote it. Appending a dated section hides
  this; revising in place only helps if the change that rebuilds an artifact also greps `research/` for its old values.
- A header date over a whole file overstates what was re-read. Dates per section (fwapg) or per measurement
  (publish timings) say which is which.
- A claim about a live source can change with no commit here (water-temp-bc's provisional values). Such a claim needs
  its read date in the sentence.
- The 3,000-word line: both files still over it are tables and current facts. `chinook_sites.md` is seven site-window
  sets by four statistics; `discharge_publish.md` is a layout contract. Neither has history left to move, so for a note
  that is a reference table the word flag does not by itself mean a log.
- Checking was the cost, not rewriting. The number checker found departures and inventions but, as designed, none of the
  stale numbers: all of those came from reading each claim against its report.

## Code-check

Five rounds (`review-round1.md` to `review-round5.md`), 17 findings, all fixed. Rounds 1-4: 5, 4, 3, 3; one round-4
finding was inside round 3's fix, so the loop ended on round 5's enumeration of 306 sentences carrying a scope claim
(276 hold, 11 hold with a stated limit, 17 not checkable read-only, 2 wrong, fixed and re-checked against HYDAT and the
reports). The mechanism: a sentence whose scope (route, window set, statistic, site, release, table state) was wider than
its figures, usually after being merged away from the heading that had qualified it. Matching figures against reports,
which the claim tables did, does not catch it.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| A shell function named `d` failed to define (`syntax error near unexpected token`): it is an alias here | Wrote the commands out |
| Read the pilot's spawning intercept range against the two-predictor fits only and "corrected" a right sentence | Restored: the range is over all three models (caught by the homeless-number check) |
