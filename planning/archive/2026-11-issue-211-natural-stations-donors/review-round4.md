# Code check, round 4 (#211): cache coverage and set claims, enumerated from the current tree

Reviewed at d31e2215. Read-only: no repository file changed and `scripts/departure_donors.R` was not run. Numbers below were measured against `data/checks/departure_donors_20260717_20261028.txt` (cited as s1–s6), and where the report prints nothing for a claim, against the cached results under `data/departure_donors/f15e177f2e/` (`results.rds`, `outside_window_stats.rds`, `hydat_window_stats.rds`, `hydat_stations.rds`), read by a scratch script outside the repository.

## Checklist read

- **code-check.md**: all 14 H3s under `## Mechanisms`, in full, skipping `|` table rows. Not read: the 24 H3s under "Rules that stand alone", "Security" and "Spreadsheets and PDFs" (no index line names anything this diff uses).
- **code-check-r.md**, in full: "`on.exit()` at a script's top level never fires"; "A database driver's value is not a base R type — and it fails twice"; "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"; "`tryCatch(warning = )` DISCARDS the value the expression produced"; "Do not abort inside a handler for a warning raised from C++; note it and abort after the call returns"; "`match()` treats NA as a matchable VALUE, so two unknowns join to each other"; "Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it"; "`sprintf("%g", x)` writes `Inf` and `NA` into SQL as bare words, which Postgres reads as column names"; "Verify a float-formatting fix in its consumer, not through `as.numeric()`"; "Rscript reads a script as it runs, so never edit a script while a run of it is in flight"; "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires"; "`tryCatch()` nests its handlers, so a `stop()` in one is caught by a later one"; "`ifelse()` with an all-NA test returns a logical vector, whatever `yes` and `no` are". 119 of 132 not read past their index line.
- **code-check-shell.md**, in full: "Git plumbing calls whose default answers a different question" (the script's `git show <commit>:<file>`). 74 of 75 not read past their index line.
- **code-check-spatial.md**, in full: "FWA lookup area follows watershed codes, so side channels get the river's"; "A relation between FWA watershed codes is not a place" (the station lookup through `fwa_streams_watersheds_lut`, registered in the rule header; accepted in rounds 1 and 3). 96 of 98 not read past their index line.

## Enumeration (a): what each cached block reads, and how it could store an incomplete result

Key (scripts/departure_donors.R:66–73): `release`, `dd_snapshot`, `rule_md5` (equal to the registering commit's, or the run stops), and md5s of the running script (`self`), `inst/vignette-data/life_history_bulk.csv`, every file in `inst/extdata/station_sources/` (5 files: both manifests, both registries, the regulation file; no subdirectories), and every `R/*.R` (no non-`.R` file in `R/`).

| cached block | input read (directly or through wet) | covered by |
|---|---|---|
| `hydat_stations` | HYDAT sqlite `STATIONS`, `STN_REGULATION` via `wb_hydat(release)` → `wet_hydat()` | release (the cache path is per release; `wet_hydat_check()` refuses a file whose VERSION is another release) |
| | `wet_hydat_connect()` | R code |
| | the SQL text | running script |
| `hydat_window_stats` | `nat` (from cached `hydat_stations`, filtered in the script) | cached block + running script |
| | `wet_station_daily(sources = "hydat", to = NULL)` → `wet_hydat_daily()` (`DLY_FLOWS`) | release, R code; `to = NULL` so no `Sys.Date()`; no provisional or realtime source is asked |
| | `windows` from `life_history_bulk.csv`, `stats` | windows file, running script |
| | `wet_window_stats()` | R code |
| | `daily_or_stop()` | running script |
| `outside_window_stats` | `st_o` from `wet_station_list()` (registries, regulation file via `system.file()` under `load_all()`) | station_sources files, R code |
| | `wet_bcenv_daily()` → stored days `days_<manifest md5>_v<wet_bcenv_reader>.parquet`, built from the snapshot CSVs held to `bcenv_20261028.csv` md5s | manifest in key; the parquet by wet's existing contract (`wet_bcenv_reader` is in `R/`; accepted round 3) |
| | `wet_bcenv_bound`, 20-hour rule, status | R code |
| | `wet_bcwatertool_station_days()` → `wet_bcwatertool()` (each CSV held to `bcwatertool_20261028.csv` md5s, `.status` listings tracked), `wet_registry_check()`, `wet_bcwatertool_against()` | manifest and registries in key, R code |
| | windows, stats, the day-status reshape | windows file, running script |
| `fwapg` | `fwa_streams_watersheds_lut`, `fwa_watersheds_poly`, `fwa_watersheds_upstream_area` | stated exception (fwapg) |
| | `st_o$linear_feature_id` from `regulation_20261028.csv` | station_sources files |
| | `pool_ids` from cached HYDAT blocks and `dd_min_years` | cached blocks, rule md5 |
| | `wet_station_snap()` | R code + fwapg (exception) |
| any block | `scripts/wb_fit_lib.R` (`wb_release()`, `wb_hydat()`), not hashed | its only outputs are the release string (in key) and the path `wet_hydat()` returns (R code) |
| any block | installed packages (duckdb, RPostgres, DBI, testthat …) | stated exception |

Ways a cached block could store an incomplete result without stopping:

| path | verdict |
|---|---|
| a reader errors (missing or md5-mismatched cache file, HYDAT read error): `wet_daily_try()` warns `source "…" skipped` and returns no rows | stops: `daily_or_stop()` turns that warning into an error. The handler runs inside `wet_daily_try()`'s `error =` handler, after its `tryCatch()` has unwound, so no enclosing `tryCatch(error =)` catches the `stop()`; the warning comes from R, not C++ |
| two registries claim one number (`wet_registry_conflict`) | stops (re-raised by `wet_daily_try()`) |
| two sources give one station-day | stops (R/wet_station_daily.R:157) |
| a station returns no days ("no flow found" warning, muffled) | not a failure: the registries in the key decide which stations are read; s1 reports "74 return days" |
| a gap between sources (warning, muffled) | not a failure: only one source per station number is asked here |
| a Tool listing held only as `.status` | tracked in the manifest, so the same no-days on every run |
| a window-year with values but no day status | stops (line 152) |
| a station segment absent from the lookup | not a stop: area NA, the station is no candidate (`dd_candidate()`), and s1's "With an upstream area … 75 of 75" shows it |
| a segment with two polygons | stops (line 182) |
| a snap failing | recorded as `accepted = FALSE` and used as such (`related_of()`) |
| an empty `ids` for the lookup | SQL error, stops |
| a write killed mid-way | `saveRDS()` to `.tmp` then `file.rename()` checked; a partial `.tmp` is never read |
| `wet_window_extend()` failing inside `dd_gauge()` | not cached; only the "do not vary" error is caught, by fixed string, everything else re-raised |

Verdict (a): every input is covered by the key or by the header's stated exception, and every incomplete-result path either stops or is reported in the report.

## Enumeration (b): sentences with a number or quantifier that the branch added or changed

| where | sentence (abridged) | source of truth | verdict |
|---|---|---|---|
| CLAUDE.md chinook para | rule registered at a7455e45 before the script existed; the script refuses another version | `git log` (a7455e45 11:22, a2e2d5a2 12:40); `git diff a7455e45 HEAD -- rule` empty; script lines 40–53 | supported |
| CLAUDE.md | test file tests its functions through the real `wet_window_extend()` and `wet_departure_carry()` | test file line 118 and on, `dd_gauge()` | supported |
| CLAUDE.md | the 1981–2010 mean of each station with at least 3 complete window-years through 2024 estimated by OLS | results.rds: 33 stations eligible in total, over every statistic; s1 "Through 2024: at least 3: 33"; s4 lists 33 | supported |
| CLAUDE.md | held out at every natural HYDAT gauge in its own box's departure pool, a box of #126's size centred on it | `held_ids`, `pools$dep` skip, `dd_box()` | supported |
| CLAUDE.md | asserts its pools at 08KA012 and 08KE014 equal the Swift and Naver reports' | lines 309–329; s1 site parity | supported |
| CLAUDE.md | worse: +0.032 leave-one-gauge-out, +0.015 leak-free | s3 0.0317, 0.0147 | supported |
| CLAUDE.md | report byte-identical on a rerun from its cache, keyed on release, snapshot, rule, script, windows, station registries and wet's R code, not fwapg or installed packages | lines 66–73; enumeration (a) | supported |
| CLAUDE.md regulation bullet | #211 "above under 'Chinook pilots'" | the Chinook pilots paragraph is above the bullet | supported |
| CLAUDE.md | none of the natural non-HYDAT stations holds a 1981–2010 baseline | s1 "With at least 10 (a baseline): 0" and "over every statistic and window … with at least 10: 0" | supported |
| CLAUDE.md | on an estimated one they make carried departures worse | s3 | supported |
| NEWS.md | no change to the package's functions | `git diff 3a7c5d94 HEAD -- R/`: roxygen lines only | supported |
| NEWS.md | none holds the 10 years of 1981–2010 record a baseline needs | s1, both lines | supported |
| NEWS.md | the 33 with at least 3 complete window-years through 2024 were each given one | s1 33; s4 33 eligible lines; results.rds 33 over every statistic | supported |
| NEWS.md | +0.032, +0.015, bar −0.01 | s3 | supported |
| NEWS.md | no site report moves | verdict HYDAT-only; the script reads site reports and writes none | supported |
| R/wet_station_list.R | no natural station holds the 10 years …; on an estimated baseline they made departures worse at held-out HYDAT gauges | s1, s3 | supported |
| R/wet_station_select.R | none holds 10 years of 1981–2010 record; on an estimated baseline they made carried departures worse | s1, s3 | supported |
| research/README.md | tested as donors (#211: they make carried departures worse) | s3 | supported |
| station_sources.md | the natural ones made carried departures worse, so they stay out of every donor pool | s3; `wet_station_select()` and the site scripts HYDAT-only | supported |
| station_sources.md Donors (provincial) | 52 natural, 101 regulated, 58 unknown; none holds the 10 years …; worse at held-out HYDAT gauges | s1 (provincial 52); s1, s3 | supported |
| station_sources.md Donors (Tool) | 23 of 46 natural …; records and held-out tests, not donors | s1 (Water Tool 23) | supported |
| station_sources.md header | #211 tested the natural stations for #202 | the report | supported |
| chinook_sites.md header | #202 (via #211; spawned #227) | `gh issue view 227`: "Continue a HYDAT gauge's record with the provincial station at its site", open | supported |
| chinook_sites.md line 387 | stations beyond HYDAT add no donor at these sites, and held out province-wide they make departures worse | s3 | supported |
| chinook_sites.md Registered | before any score existed; the script refuses a changed rule file | git log; lines 40–53 | supported |
| chinook_sites.md As seen | s1 restates the province-wide counts; the box counts from the same probes | s1 holds 75, 71, 185, 179, 36, 33, 58 | supported |
| chinook_sites.md | 75 natural stations, none has 10 migration window-years in 1981–2010, 71 have none | s1 "0 at 71", "With at least 10: 0" | supported |
| chinook_sites.md | 185 window-years, 179 of them in 2010 or later | s1 decades 89 + 90 | supported |
| chinook_sites.md | 36 have at least 3, 33 through 2024 | s1 | supported |
| chinook_sites.md | a third unchecked throughout | s1 58 of 185 (31 %) | supported |
| chinook_sites.md | Maxan and Gosnell 2 stations with 2 window-years each, Swift none, Naver 6 | site boxes from `scripts/departure_sites.csv` against `wet_station_list()` and the cached window-years: Maxan and Gosnell 08EE0001 (2), 08EE0002 (2); Swift none; Naver 08JC0001, 0002, 0005, 0006 (3 each), 08JC0018 (1), 08JC0020 (2) | supported |
| chinook_sites.md | OLS residuals sum to zero …; one or two degrees of freedom at 3 or 4 years | OLS with an intercept and a slope: n − 2 | supported |
| chinook_sites.md The test | every natural HYDAT gauge in its own box's departure pool; k = 5; fit years stop at 2024, later years observed; RMSE over the 2011–2025 years a station is among the donors | `held_ids`, `dd_k`, `dd_fit_years()`, `dd_baseline_rows()`, `dd_scored_years()` | supported |
| chinook_sites.md | ships if both medians are at most −0.01 with at least 10 gauges each | `dd_ship()` | supported |
| chinook_sites.md Result | +0.032 loo (50 gauges, 16 better, 34 worse), +0.015 leak-free (53, 17 better) | s2, s3 | supported |
| chinook_sites.md | the 90 % interval on each median lies above zero | s2 0.0064..0.0629, 0.0049..0.0523 | supported |
| chinook_sites.md | every other scored statistic and window has a positive median, except migration cov_day (−0.08, −0.09), intervals spanning zero | s2: all six other scored lines positive in both pools; cov_day −0.0824, −0.0915; −0.2742..0.1473, −0.3184..0.1055 | supported |
| chinook_sites.md | centred log NSE 0.83 → 0.75; mean signed error −0.012 → −0.021 | s4 0.827, 0.750; −0.0116, −0.0211 | supported |
| chinook_sites.md | fit on 3 to 8 fit years, slopes −3.55 to 6.76 | s4 (migration mean): fit years 3–8; least −3.55 (1AHA040), most 6.76 (HRB2629) | supported (in the migration-mean bullet) |
| chinook_sites.md | at least 5 fit years: +0.013 (23); no unchecked day: +0.077 (23); k = 3 +0.065, k = 8 +0.011; HYDAT-site exclusion +0.037; no sensitivity would ship | s5 | supported |
| chinook_sites.md | "whose gauge is in the box" (code: the box pool) | the natural-flag HYDAT-site gauges outside a box pool (08HA019, 08HB042) have stations with 0 window-years, never candidates, so the two sets exclude the same stations | supported in effect |
| chinook_sites.md | 210 of 263 gauge-years have fewer HYDAT donors; the ones kept always among those without | s4 loo 210 of 263; 0 of 263 | supported |
| chinook_sites.md | years with no chosen station's value: the carry renormalises over the HYDAT donors left; median +0.001 | `wet_departure_carry()` docs line 11 (drops and renormalises); s4 0.0014 (n 52) | supported |
| chinook_sites.md | 225 of 392 have a candidate; among the donors at 75 on the migration mean | s1 | supported |
| chinook_sites.md | 25 distinct stations: 10 (08H), 6 HRB, 4 (08N), 3 (08J), 2 (07F) | s4 list counted: 10 + 6 + 4 + 3 + 2 = 25 | supported |
| chinook_sites.md Attribution | 3 to 8 fit years, starting in 2010 or later at 31 of the 33 eligible stations; 1AHA040's 1999–2002 | s4 (migration mean): 1AHA040 (1999), 61004 (2008) start earlier, so 31 | supported (scope: the migration-mean loss) |
| chinook_sites.md Attribution | Maxan's and Gosnell's two stations 2 each; Swift none; Naver's four with 3 were eligible | box check above; s4 eligible list | supported |
| chinook_sites.md Attribution | **"with the most any station holds now at 8 fit years"** | results.rds: 08NH0001 and 08NM0004 are eligible with **9** fit years in the spawning window (q_mean, q_min7, q_max; 08NH0001 also q_cov_day); `outside_window_stats.rds` agrees. The report prints fit years for the migration mean only (s4), where 8 is the most | **not supported as worded** (finding 1) |
| chinook_sites.md Attribution | two natural HYDAT gauges with a baseline would gain recent years (08JC017, 08NJ168) | s4 flag 0 at both; cached HYDAT: 08JC017 10 baseline migration years, 08NJ168 28; the other natural-flag site gauges hold under 10 (08JC013 3, 08NM246 3, 08NM176 6, the rest 0), except 08GA071 (30), whose station ELA-water holds 0 window-years | supported |

## Findings

- **[severity: fragile]** research/chinook_sites.md:121 — "with the most any station holds now at 8 fit years, the next useful rerun is once several hold 10 or more". The rule fits each statistic and window on its own fit years (`dd_fit_years()` per `v`, `p`), and in the spawning window two eligible stations already hold 9: 08NH0001 (q_mean, q_min7, q_max, q_cov_day) and 08NM0004 (q_mean, q_min7, q_max) (results.rds `eligible$n_fit`; the same from `outside_window_stats.rds`, usable values through 2024). 8 is the most on the migration mean, which is all s4 prints, so the sentence states a migration-mean count as true of every statistic. It is the same mechanism as round 3's baseline finding: a count over one window written as a claim about the set. The number decides when the test is next worth rerunning, and 08NH0001 already holds 10 spawning window-years once 2025 is counted. Fix: scope the sentence ("on the migration mean, the most any station holds now is 8 fit years"), or give the count over every statistic (9).
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

Nothing else in either enumeration is unsupported or uncovered.

index, diff and changed files read from file
