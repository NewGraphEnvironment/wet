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

## Errors Encountered

| Error | Resolution |
|-------|------------|
