# Code check, round 3 (#211)

## Checklist read

- **code-check.md**: the prose of all 14 H3s under `## Mechanisms` (table rows skipped), read closely for "A guard that fails toward pass", "A guard's scope, escape hatches, and remedies" (the compression and quantifier paragraphs), "Written data outlives the fix", "One fact derived twice"; the rest of the file's headings (Rules that stand alone, Security, Spreadsheets and PDFs) not read: about 30.
- **code-check-r.md**: "`on.exit()` at a script's top level never fires", "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent", "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising…", "`tryCatch(warning = )` DISCARDS the value the expression produced", "A design matrix does not hold everything a formula says"; plus, from the index line alone, "Rscript reads a script as it runs…", "`ifelse()` with an all-NA test…", "`paste()` with a zero-length argument…", "`data.frame()` recycles a scalar against a zero-length column", "Postgres row order is never fixed unless the query fixes it…". Not read: about 165.
- **code-check-shell.md**: none read in full (the diff has no shell beyond one `system2("git", …)` to a file); about 110 not read.
- **code-check-spatial.md**: "A relation between FWA watershed codes is not a place" and "FWA lookup area follows watershed codes, so side channels get the river's" from their index lines (the station lookup goes through `fwa_streams_watersheds_lut`; the rule header registers it); about 120 not read.

## Mechanism

Every earlier finding, and every one below, is a claim about a **set** written from the author's
picture of the set rather than enumerated over it from the artifact that produces it. Round 1's
"displaces no HYDAT donor" was a subset check read as a set property; the cache key "covering
every input" listed the inputs the author thought of; round 2's "no station has a value" covered
only the chosen stations. The guard or evidence covers a member or a subset, and the sentence or
comment quantifies over the whole. This round the same shape reaches: the inputs whose *failure*
the key cannot see (finding 1), "each" station given an estimated baseline when only candidates
were (finding 2), "no natural station holds 10 years" measured on one window of two (finding 3),
and two small prose anchors (findings 4, 5).

## Enumeration (a): inputs of each `cached()` block against the key

Key (lines 531–536): release, `dd_snapshot`, `rule_md5`, md5 of the running script, `life_history_bulk.csv`, every file in `inst/extdata/station_sources/` (both registries, both manifests, the regulation file), every `R/*.R` (wet has no `R/sysdata.rda`). Stated exceptions: fwapg, installed packages.

| block | input | how read | covered? |
|---|---|---|---|
| `hydat_stations` | HYDAT 20260717 `STATIONS`, `STN_REGULATION` | `wet_hydat_connect(hydat)`; path from `wb_hydat(release)` (`scripts/wb_fit_lib.R`, not hashed) | yes: release, and `wet_hydat()` refuses another `VERSION`; `wb_fit_lib.R` only resolves the path |
| `hydat_window_stats` | `nat` (from `hy`) | cached block above | yes (same key) |
| | HYDAT daily flows | `wet_station_daily(sources = "hydat")` → `wet_hydat_daily` | yes: release |
| | `windows` | `life_history_bulk.csv` | yes |
| | `stats`, `cols`, `to = NULL` | the script | yes: self md5 |
| | reader and window code | `R/wet_station_daily.R`, `R/wet_window_stats.R` | yes: R code |
| | **a HYDAT read that errors** | `wet_daily_try()` turns it into a warning and zero rows; `suppressWarnings()` hides it | **no**: the empty result is cached; the parity stop catches it, but on every rerun until the cache is removed, with a misleading message |
| `outside_window_stats` | `st_o` station list | `wet_station_list()` → registries and `regulation_20261028.csv` via `system.file()` (source tree under `load_all`) | yes |
| | provincial raw CSVs, Tool entries | per-machine `R_user_dir("wet","cache")/station_sources/…/20261028/` | yes in effect: each read is held to the tracked manifest's bytes and md5 (`wet_bcenv_check()`), and the manifests are in the key |
| | provincial days parquet `days_<manifest md5>_v<reader>.parquet` | per-machine cache | yes in effect, by wet's existing contract (bump `wet_bcenv_reader` with any build change; the constant is in `R/`) |
| | `continues`/`continues_before` cut | Tool registry | yes |
| | `windows`, `stats`, day-status logic (`unchk`) | csv, script | yes |
| | **a provincial or Tool read that errors** (cache file missing or md5 mismatched: the readers never download) | same `wet_daily_try()` → warning → `suppressWarnings()` | **no**: a whole network's days drop silently, the partial result is cached, nothing stops (section 1's `DIFFERS` labels only), and a rerun reproduces it byte for byte. Finding 1 |
| `fwapg` | lookup and upstream area | fwapg tables | stated exception |
| | `st_o$linear_feature_id` | regulation file | yes |
| | `pool_ids` = `nat` with `n_mig_h >= dd_min_years` | cached HYDAT blocks, rule constant | yes (rule_md5) |
| | `wet_station_snap()` | `R/wet_station_snap.R` + fwapg functions | R code yes; fwapg stated exception |
| `results.rds` | written, never read back by `cached()` | — | not a cache input |

Not in any block but part of every result: the `scripts/departure_donors_rule.R` functions (rule_md5), `wet_window_extend()`/`wet_departure_carry()` (R code; extensions refitted per run, as the header says).

## Enumeration (b): quantified or numbered sentences this branch added or changed

Report sections cited as s1–s6.

| where | sentence (abridged) | evidence | verdict |
|---|---|---|---|
| CLAUDE.md:50 | rule registered at a7455e45; script refuses another version | `rule_md5` block, lines 503–516 | supported |
| CLAUDE.md:50 | "each station's 1981–2010 mean estimated by OLS extension" | only eligible candidates are extended: 33 stations in s4's eligible list; 39 of 75 hold fewer than 3 window-years (s1: 16+15+8) and are never candidates | **not as worded** (finding 2) |
| CLAUDE.md:50 | held out at every natural HYDAT gauge in its own box's departure pool | `held_ids`, `if (!g %in% pools$dep(v, p)) next` | supported |
| CLAUDE.md:50 | asserts pools at 08KA012 and 08KE014 equal Swift's and Naver's | parity block; s1 "30, 11, 13", "58, 17, 24" | supported |
| CLAUDE.md:50 | +0.032 loo, +0.015 leak-free | s3 0.0317, 0.0147 | supported |
| CLAUDE.md:50 | keyed on release, snapshot, rule, script, windows, registries, wet's R code; not fwapg or packages | lines 531–536 | supported as a list of what is hashed; the failure path in (a) is outside it (finding 1) |
| CLAUDE.md:50 | byte-identical on a rerun from its cache | no timestamp; `set.seed(211)`; radix sorts; not rerun by me | supported by construction (same machine) |
| CLAUDE.md:82 | "#202's test (#211, below under "Chinook pilots")" | the Chinook pilots paragraph is line 50, above line 82 | **not as worded** (finding 4) |
| CLAUDE.md:82 | "found none holds a 1981–2010 baseline" | s1 "With at least 10 (a baseline): 0", migration mean only | supported for the migration window (finding 3) |
| CLAUDE.md:82 | on an estimated one they make carried departures worse | s3 | supported |
| NEWS.md | "No change to the package's functions" | `R/` diffs are roxygen only | supported |
| NEWS.md | "None holds the 10 years of 1981–2010 record a baseline needs" | s1, migration mean only | supported for the migration window (finding 3) |
| NEWS.md | "so each was given one estimated from HYDAT gauges" | as CLAUDE.md:50; s4 eligibility "fewer than 3 fit years 1383; no extension gauge covers its fit years 8" | **not supported** (finding 2) |
| NEWS.md | +0.032 / +0.015 against −0.01 | s3, `dd_margin` | supported |
| NEWS.md | Donor selection stays HYDAT-only; no site report moves | s3 verdict; no site script or report changed | supported |
| R/wet_station_list.R | "No natural station holds the 10 years of 1981–2010 record a baseline needs" | s1, migration mean only | supported for the migration window (finding 3) |
| R/wet_station_list.R | on an estimated baseline they made carried departures worse at held-out HYDAT gauges | s3 | supported |
| R/wet_station_select.R | "none holds 10 years of 1981–2010 record and on an estimated baseline they made carried departures worse" | s1, s3 | as the two rows above |
| research/README.md | tested as donors (#211: they make carried departures worse) | s3 | supported |
| chinook_sites.md:95 | stations beyond HYDAT add no donor at these sites; province-wide worse | site scripts use HYDAT only; s3 | supported |
| chinook_sites.md:98ff | scoring script refuses when the rule file differs | lines 503–516 | supported |
| chinook_sites.md | of 75, none has 10 window-years in 1981–2010; 71 have none | s1 "0 at 71" | supported |
| chinook_sites.md | 185 window-years, 179 in 2010 or later | s1 decades 89 + 90 | supported |
| chinook_sites.md | 36 with at least 3, 33 through 2024 | s1 | supported |
| chinook_sites.md | a third unchecked throughout | s1 58 of 185 (0.31) | supported |
| chinook_sites.md | "the report's section 1 restates them" | s1 restates the counts above, not the box counts that follow | **partly** (finding 5) |
| chinook_sites.md | Maxan and Gosnell 2 stations with 2 window-years each, Swift none, Naver 6 | not in the report; checked here: `regulation_20261028.csv` marks 08EE0001, 08EE0002 and 08JC0001/2/5/6/18/20 natural; s4 gives 08EE0001 2 | true; no producer in the report (finding 5) |
| chinook_sites.md | OLS residuals sum to zero over fit years; 1 or 2 degrees of freedom at 3 or 4 years | intercept and slope: n − 2 | supported |
| chinook_sites.md | test design: every natural HYDAT gauge in its departure pool, k = 5, fit years to 2024, ships at ≤ −0.01 both pools, ≥ 10 gauges | rule header, `dd_ship()` | supported |
| chinook_sites.md Result | +0.032 (50 scored, 16 better, 34 worse), +0.015 (53, 17 better) | s2, s3 | supported |
| chinook_sites.md Result | the 90 % interval on each median lies above zero | s2 0.0064..0.0629, 0.0049..0.0523 | supported |
| chinook_sites.md Result | every other scored statistic and window positive except migration cov_day (−0.08, −0.09 days), intervals spanning zero | s2: spawning mean, both min7, spawning cov_day positive; migration cov_day −0.0824/−0.0915, intervals −0.27..0.15, −0.32..0.11; max is "reported, not scored" | supported |
| chinook_sites.md bullet | centred NSE 0.83 → 0.75 loo; mean signed error −0.012 → −0.021 | s4 0.827/0.750, −0.0116/−0.0211 | supported |
| chinook_sites.md bullet | 3 to 8 fit years; slopes −3.55 to 6.76 on the nearest extension gauge | s4 eligible list (1AHA040 −3.55, HRB2629 6.76; 08NM0004 8 fit years) | supported |
| chinook_sites.md bullet | ≥5 fit years +0.013 (23); no unchecked +0.077 (23); k = 3 +0.065; k = 8 +0.011; HYDAT-site exclusion +0.037; no sensitivity would ship | s5 loo values; all "would not ship" | supported |
| chinook_sites.md bullet | 210 of 263 gauge-years fewer HYDAT donors; the kept ones always among those without | s4 loo "0 of 263", "210 of 263" (leak-free 0 of 282 too) | supported |
| chinook_sites.md bullet | in the years none of the chosen stations has a value the carry renormalises over the HYDAT donors left; median +0.001 | s4 loo 0.0014 (n 52); `wet_departure_carry()` fixes its k donors and renormalises per year (its roxygen) | supported |
| chinook_sites.md bullet | 225 of 392 have a candidate; a station among the five donors at only 75 | s1 | supported |
| chinook_sites.md bullet | 25 distinct stations: 10 08H, 6 HRB, 4 08N, 3 08J, 2 07F | s4 list, counted | supported |
| chinook_sites.md Attribution | "from 3 to 8 recent years" | s4: 1AHA040's fit years are 1999–2002, inside 1981–2010; 61003/61004 2008–2012 | **not true of every member** (finding 5) |
| chinook_sites.md Attribution | Maxan's and Gosnell's two stations 2 window-years each, under the 3 a candidate needs; Swift none | s4 (08EE0001), `dd_min_years`; station_sources table | supported (partly outside the report) |
| chinook_sites.md Attribution | Naver's four stations with 3 window-years were eligible donors here | s4: 08JC0001/0002/0006 3 window-years, 08JC0005 3 fit years, all four in the eligible list | supported (note: `research/station_sources.md`'s older box table, which the line-95 bullet links, gives 08JC0001 and 08JC0006 4 window-years; not this branch's line) |
| chinook_sites.md Attribution | the most any station holds now is 8 fit years | fit years ≤ window-years through 2024; 08NM0003's 9 window-years give 7 fit years | supported |
| chinook_sites.md Attribution | 08JC017, 08NJ168 natural HYDAT gauges with a baseline | s4 flag 0 at both; "with a baseline" not in the report | flag supported; baseline unverified (#227's claim) |
| station_sources.md | the natural ones made carried departures worse, so they stay out of every donor pool | s3; `wet_station_select()` HYDAT-only; site scripts HYDAT-only | supported |
| station_sources.md | 52 natural, 101 regulated, 58 unknown (provincial); 23, 9, 14 (Tool) | `regulation_20261028.csv` tabulated: bcenv 52/101/58, bcwatertool 23/9/14 | supported |
| station_sources.md | none holds the 10 years …; worse at held-out HYDAT gauges | s1, s3 | as finding 3 |

Other set-property statements in the script and report: the header's "Stops … when" list is each checked in code (the no-candidate identity only in the main run, where those gauges are run); the report's "max is reported, not scored" sits beside "migration max … 50 scored" lines (the verdict ignores max; wording only); section 1's comparison with the header's counts labels a difference and never stops, by design, which is what lets finding 1 through.

## Findings

- **[severity: fragile]** scripts/departure_donors.R:573 and :590 — both `wet_station_daily()` calls are wrapped in `suppressWarnings()`. `wet_station_daily()` routes every reader error through `wet_daily_try()` (R/wet_station_daily.R:222), which turns it into the warning `source "bcenv" skipped: …` and zero rows. The provincial and Tool readers stop on a missing or md5-mismatched cache file and never download, so on any machine whose `R_user_dir("wet","cache")` lacks the 20261028 snapshot (or holds a damaged file) a whole network's days vanish silently. `outside_window_stats` then caches the partial result, the key does not change when the cache files are restored, nothing stops (section 1 only labels counts `DIFFERS`), and every rerun writes the same wrong report byte for byte with a verdict computed on fewer stations. On the HYDAT side the parity check stops the run, but the cached empty `hydat_window_stats` makes every rerun fail with "pools differ from the site report" until the cache is removed. The tracked report is not affected (s1 shows days from both sources). Fix: replace `suppressWarnings()` with `withCallingHandlers()` that stops on `^source ".*" skipped` and muffles the rest (the expected "no flow found" and gap warnings).
  - **Rule:** code-check.md "A guard that fails toward pass"
- **[severity: bug]** NEWS.md (new bullet) "None holds … so each was given one estimated from HYDAT gauges" — false for most stations: 39 of the 75 hold fewer than 3 complete migration window-years (s1: 0 at 16, 1 at 15, 2 at 8) and are never candidates, and the eligibility line counts 1,383 gauge-station pairs short of 3 fit years and 8 with no covering extension gauge; 33 stations appear in the eligible list. CLAUDE.md:50 says the same as method ("each station's 1981–2010 mean estimated by OLS extension"). Write "each station with at least 3 window-years in a gauge's box was given one" or similar.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
- **[severity: fragile]** R/wet_station_list.R and R/wet_station_select.R (help), NEWS.md, CLAUDE.md:82, research/station_sources.md — "No natural station holds the 10 years of 1981–2010 record a baseline needs" is measured only on complete migration-mean window-years (s1). The rule's baseline is per statistic and window (`dd_pools()$dep`, `dd_baseline_rows()`), and the report counts no other window. Almost certainly true given s1's decades, but unmeasured for the spawning window; either count both windows in section 1 or scope the sentence to the windows tested.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
- **[severity: fragile]** CLAUDE.md:82 — "#202's test (#211, below under "Chinook pilots")": the Chinook pilots paragraph, where the new sentence sits, is line 50, above the regulation bullet. The pointer sends a reader the wrong way.
  - **Rule:** none
- **[severity: fragile]** research/chinook_sites.md, "Natural stations outside HYDAT as donors" — (i) Attribution: "estimating a 1981–2010 mean from 3 to 8 recent years" is not true of every eligible station: 1AHA040's fit years are 1999–2002, inside the baseline itself, and 61003/61004's 2008–2012 (s4). (ii) "As seen before registration (…; the report's section 1 restates them from its own data)" goes on to the four boxes' counts (Maxan and Gosnell 2, Swift none, Naver 6), which section 1 does not restate. The counts are right (checked against `regulation_20261028.csv`), but the sentence names a producer that does not hold them.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

index, diff and changed files read from file
