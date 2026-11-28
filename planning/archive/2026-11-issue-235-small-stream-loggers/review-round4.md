# Code-check round 4 (#235)

## Checklist read

- code-check.md: the prose of all 14 H3s under `## Mechanisms` (table rows skipped). The 24 H3s under "Rules that stand alone", "Security" and "Spreadsheets and PDFs" were not read.
- code-check-r.md, read in full (17): "as.POSIXct on character infers ONE format for the whole vector"; "`nzchar(NA)` is TRUE"; "`ifelse()` with an all-NA test returns a logical vector"; "Tests that silently do not run"; "A `skip_if_not()` skips only its own `test_that()` block"; "Under `R CMD check`, tests run from a temp dir against the INSTALLED package"; "A fetcher's test helper must make the network fail"; "`read.delim()` quotes by default"; "`tempfile()` lives in the session tempdir"; "`system2(stdout = TRUE)` warns on a non-zero exit"; "`data.frame()` recycles a scalar against a zero-length column"; "`sort()` and `order()` collate by `LC_COLLATE`"; "`on.exit()` at a script's top level never fires"; "A `data-raw/` script must load the source tree"; "as.POSIXct on a Date pins UTC midnight"; "`match()` treats NA as a matchable VALUE"; "`tryCatch()` nests its handlers". 115 not read.
- code-check-shell.md (1): "An S3 multipart ETag depends on the uploader's part size". 74 not read.
- code-check-spatial.md (3): "A relation between FWA watershed codes is not a place"; "FWA main flow is not edge type 1000 alone"; "FWA lookup area follows watershed codes". 95 not read.

Index, diff and changed files read from file.

## Round-3 fixes checked

- "three more rules" / "three logger rules set among them": roxygen (`R/wet_temp_daily.R` "Logger records"), research ("with three more rules that apply to logger series only ... the hour rule keeps its place between the first two"), CLAUDE.md ("three logger rules set among them, in order: stuck runs ..., the hour rule, deployment ends, air days"). All match the code order in `wet_logger_days()` (stuck hours removed, then `short`, then `ends`, then air). Holds.
- Amendment's "135 open-water days with a range above 20 degC": the report prints 135 *further* days (outside the 6 left-out station-years). Rebuilt from the cached hours (`<main checkout>/data/temp_loggers/eccc_hours.rds`, 342 stations): 135 days above 20 degC in all, 0 inside the 6 station-years. So the unscreened total is also 135, and the header, the research text and the report agree. Holds.
- The same mechanism left uncorrected in `planning/active/task_plan.md` (finding 3).

## Enumeration

| where | claim | checked against | verdict |
|---|---|---|---|
| NEWS | 32 sites, 2019–2024, 15-minute readings, CC BY 4.0 | registry (32 rows), report (2019-06-27 to 2024-12-15) | holds |
| NEWS | fetched once and held to Zenodo's checksums | `wet_logger()`, manifest md5s = data-raw's Zenodo md5s | holds (zips; members held to md5s wet computed) |
| NEWS | thresholds registered before any logger day was screened | commit order: 150807c9 (rules, 17:07) before fec2cddd (reader, 17:12) | holds |
| NEWS | 30 complete growing seasons at 22 sites; 28 placed on FWA and tree | report "all:" line, Placement | holds |
| NEWS | each site carries its sub-drainage | registry `subdrainage` not NA in 32 rows | holds |
| roxygen | about 340 ECCC stations | cache: 342 stations; findings.md 342 | holds |
| roxygen | 32 sites, 2019-2024, record 15053907, ids `NHG_<site code>` | registry | holds |
| roxygen | stuck: identical hourly means above 0.5 degC, more than 154 h, May–Sep, before the hour rule | `wet_logger_days()` `cand`, `len > stuck_h`, order | holds |
| roxygen | deployment: no gap over 6 h, first and last day dropped | `dep`, `ends` | holds |
| roxygen | air: May–Sep, 12.09 to 18.38 degC | `wet_logger_air_c` min/max | holds |
| roxygen | a series that cannot be read is skipped with a warning | `tryCatch` in `wet_temp_daily()`; test | holds |
| roxygen | example fetches 14 MB | 01_Data.zip 13,830,401 bytes; only that zip is opened for 01FW007 | holds |
| roxygen `sources` | an id whose source is not named returns no days | routing code, test | holds |
| roxygen `@return` | logger `status` is "provisional" | `wet_logger_daily()` | holds |
| `wet_temp_fill` roxygen | logger pooled through registry `subdrainage` | test at test-wet_logger_daily.R:330 | holds |
| `R/wet_logger_daily.R` header | id never a HYDAT, provincial or Tool number | underscore in every id; data-raw refusal | holds |
| `R/wet_logger_daily.R` rules comment | order 1–4, thresholds from report option a | code, report "Shipped" | holds |
| `R/wet_logger_daily.R` | `from = as.Date(-Inf)` default | DESCRIPTION R (>= 4.1) | **contradicted on R < 4.3** (finding 1) |
| data-raw header | 15053907: 32 sites; 6426024: 24 sites, all in the later | registry, `prior_map` (24) | holds |
| data-raw header | clock UTC in both | ReadMe (per script); `clock_offset` 0 | holds as stated |
| data-raw header | sub-drainage and day offset of nearest HYDAT; nearest ECCC and distance; first/last reading UTC | code §4 | holds |
| data-raw | Stellako at Endako's position, "6 km away" | earlier ReadMe SFL 54°04'55.8"N 125°00'19.1"W vs 01FW004: 6.8 km | approximate (truncated); no effect, the script prints the km |
| data-raw | refuses HYDAT-shaped ids and ids in the ECCC archive | code | holds |
| thresholds header | rule a and b, type 7, rounding | code, report | holds |
| thresholds header | 08LG048 4.00 degC 3,314 h; 135 days > 20 degC | report top-10, cache recount (135 total) | holds |
| thresholds header | screen: run of 168 h or more; range above 20 degC | `screen_run_h`, `screen_range_c`, `>=` / `>` | holds |
| thresholds report | 135 = May 14 + Jun 11 + Jul 22 + Aug 66 + Sep 22 | arithmetic | holds |
| temp_loggers.R header | name leg, else nearest within 100 m, else unplaced; tree legs | code | holds |
| temp_loggers.R comment | earlier files stamp an hour twice at autumn and spring clock changes | earlier Data.zip: duplicates on 2019-11-03, 2020-11-01 (5 files) and 2021-03-14 (Whitesail) | holds |
| report | days 650 + 100 + 11 = 34,778 − 34,017 | arithmetic | holds |
| report | sites within 0.5 km of ECCC | unrounded: Nadina 0.498 km, Skins 0.460 km | holds |
| research | rules 1–4 as coded; "Outside those months none applies" | `air_c` names 5–9 | holds |
| research | air subset: every station where small stations hold < 1,000 days; none did | report days<1000 ≥ 17,924 | holds |
| research | "rivers ... daily ranges smaller ... thresholds lean toward keeping a logger's day" | direction of the air rule | **contradicted for the air threshold** (finding 2) |
| research | Amendment: 687 h, Aug 24.97, 6 station-years, 135 days | report | holds |
| research | 87 % equal at the same time | 770,925 / 884,865 = 87.1 % | holds |
| research | Chedakuz 18,684 vs 9,936; Endako 15,581 vs 14,496 | report rows CNR, ESR | holds |
| research | Whitesail about a sixth at every alignment | 5,899 / 6,012 / 5,800 of 36,334 | holds |
| research | day means up to 0.51 at Whitesail and Chedakuz, ≤ 0.08 elsewhere | max_diff 0.503, 0.511; next 0.076 | holds |
| research | flags touch 3,153 kept days | report | holds |
| research | 30 at 22; 24 at 18; 31 of 32 reach 365 | report | holds |
| research | 28 placed, 24 name, 4 nearest within 100 m, all on tree; four lake sites unplaced | placement csv | holds |
| research | 08J at 29 sites, 08K at three near Prince George | registry (01FW005, 024, 025) | holds |
| research table | Nechako 32 sites, 2019-06-27 to 2024-12-15, 15 min; earlier 24 | report, registry | holds; other rows not checkable from tracked files |
| CLAUDE.md | routing, `sources` default, manifest columns, registry columns, cache path, `fetch` | code | holds |
| CLAUDE.md | report reports drops, flags, comparison, placement, seasons; test holds constants | report, test at :249 | holds |
| task_plan decided | registry `utc_offset`, `dst`, `tz`, `nearest_km` (lines 56–59, 88, 149–150, the last in a ticked box) | registry: `clock_offset`, `day_offset`, `eccc_km`, no `dst`/`tz` | **contradicted** (finding 3) |
| task_plan decided | QA list then "Every rule applies to logger series only" (60–61) | `valid` and the hour rule apply to ECCC days too | **contradicted** (finding 3) |
| task_plan decided | "stuck runs, on readings" (60) | rule is on hourly means | **contradicted** (finding 3) |
| task_plan decided | days from the later record, "else from the earlier" (40) | no code reads the earlier record's days | stale (finding 3) |
| task_plan decided | complete seasons "near zero, and the report says so" (92) | report: 30 complete seasons, no such sentence | **contradicted** (finding 3) |
| task_plan decided | Amendment 1, shipped values | report | holds |

## Findings

- **[severity: fragile]** `R/wet_logger_daily.R:287`: `wet_logger_daily()` defaults to `from = as.Date(-Inf), to = as.Date(Inf)` with no `origin`. Before R 4.3, `as.Date.numeric()` stops with "'origin' must be supplied", and DESCRIPTION declares `R (>= 4.1)`. The sibling caller, `wet_temp_daily()`, guards exactly this (`R/wet_temp_daily.R`, "numeric as.Date() needs an origin before R 4.3", `origin = "1970-01-01"`). `wet_temp_daily()` always passes both dates, so the exported path is safe. But `tests/testthat/test-wet_logger_daily.R:324` calls `wet_logger_daily("TST_01XX001")` with the defaults, and the defaults are forced at `d$date >= from`, so that test errors on R 4.1 and 4.2. Fix: add `origin = "1970-01-01"` to both defaults.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: fragile]** `research/station_water_temperature.md:54`: "The archive is mostly rivers, whose daily ranges are smaller than small streams', so these thresholds lean toward keeping a logger's day." For the air threshold this is backwards. A reference with smaller daily ranges gives a lower 99.9th percentile, so a small stream's genuine large-range day is more likely to exceed it and be dropped as an air day. The air threshold therefore leans toward *dropping* logger days. The sentence holds only for the stuck threshold: rivers' steadier hourly means give longer reference runs and so a higher hour threshold. "these thresholds" covers both, so a reader takes the air rule as conservative when it is the strict one. Nothing measured the direction. Fix: state the direction per threshold.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (a justification that was never measured)

- **[severity: fragile]** `planning/active/task_plan.md`, "Decided at the gate" and the ticked Phase 2 box. Several statements describe a design the code did not build. `findings.md:129` records the change but the spec was not revised, and it is what the archive README and the next session read.
  - Lines 56–59, 88 and 149–150 (ticked): the registry holds `utc_offset`, `dst`, `tz`, `nearest_km`. The shipped registry has `clock_offset`, `day_offset` and `eccc_km`, and no `dst` or `tz`.
  - Lines 60–61: "the `valid` range; stuck runs, on readings; the hour rule; ... Every rule applies to logger series only." The `valid` range and the hour rule apply to ECCC days too (`wet_temp_eccc()`). Stuck runs are on hourly means, not readings. This is the inherited-scope claim round 3 fixed in the roxygen, research file and CLAUDE.md, left standing here.
  - Line 40: "else from the earlier [record]": no code reads days from record 6426024. It is only compared.
  - Line 92: complete seasons "will be near zero, and the report says so": the report counts 30 complete seasons at 22 sites and says nothing of the kind.

  The open Validation box "PWF checkboxes match landed work" may be meant to catch this. As the tree stands, the spec contradicts the code.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (a restatement inherited from a list whose scope differs; enumerate every claim)
