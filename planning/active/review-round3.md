# Code check round 3 (#169)

## Checklist read

- code-check.md: every H3 under `## Mechanisms` in full prose (14, table rows skipped); no other headings.
- code-check-r.md, by heading (7 read): "A fetcher's test helper must make the network fail, not just mock the reader"; "`on.exit()` at a script's top level never fires"; "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"; "A `function(...)` mock hides arguments the real callee no longer accepts"; "`download.file(quiet = TRUE)` never tells you the HTTP status — read it from `curl`"; "`ifelse()` with an all-NA test returns a logical vector, whatever `yes` and `no` are"; "`$` on a list partial-matches, so a longer sibling key answers for a missing one". The rest not read.
- code-check-shell.md: none read (the diff has no shell).
- code-check-spatial.md: none read in full; index only (terra extent projection and the FWA lut are as the pilot used them, and the PNWNAmet parity passes on them).

Index, diff and changed files read from file.

## The mechanism

Every earlier finding was a hand-kept second copy of a set the producer defines, written from the path the author ran, so it agreed with the producer only there:

- round 1: the statuses a request can end in (the logger knew one: 200);
- round 1: the verdicts rule 5 can emit (the map's classes knew one: pass);
- round 1: the bodies a 200 can carry (the cache accepted every 200 as a listing);
- round 2: the consumers that key on a source file (`wet_pcic_fetch.R` hashed into #45's key, re-derived by `wb_small_basin.R`).

In checklist terms: a fact about another artifact restated rather than read from it (code-check.md "One fact derived twice"), with the consumer-side form, a policy moved into a shared harness whose other callers were written for the old one ("A fix lands in one of two callers that share a harness").

### Every place in this diff it reaches

| # | producer's set | second copy | verdict |
|---|---|---|---|
| A1 | outcomes of a gridded request (`wet_pcic_fetch()`: any status, curl error) | `wet_request_log()` calls; `fetch_run()`'s logger | sound: called on every try, curl error as 0 (R/wet_pcic_fetch.R:45-49) |
| A2 | outcomes of a listing request | `listing()`'s `fetch_log()` | sound: every try logged, curl error as 0 |
| A3 | callers of `wet_pcic_fetch()` | only `scenario_basis.R` sets the logger and the refusing base | **finding 3** (`wb_term_diagnose.R`, `wb_plateau_p.R`: nested retries, unlogged) |
| B1 | rule 5's verdict strings | `pcic_coverage.R:139-141` exact match on the pass string | sound: anything else (incl. a missing line) is "undecided" |
| B2 | "not run" markers in the scenario_basis report | `r4_ran`/`r5_ran` greps | sound: the strings are the producer's (scenario_basis.R:452, 489) |
| B3 | `class_scen` / `class_pub` values (pcic_coverage.R:169-174, asserted at :186-188) | map `scen_lev` (:87), `cls()` expectations, `wet_coverage.csv` | sound: five and three classes agree; the map stops on an unknown class (:92) |
| B4 | rule 4's verdicts | none consumes them | sound by construction |
| C1 | bodies a listing 200 can carry | `listing()` validation before cache | sound (round 1 fix) |
| C2 | a gridded 200 | signature and day checks before `file.rename()` | sound; the day check verified on cached PNWNAmet files (terra 1.9.50 reads `Date`, equal to the asked days, one year and 30 years) |
| C3 | the layers the map script's constants select | `map_layers.rds`, keyed by nothing | **finding 2** |
| D1 | `wet_pcic_fetch()`'s file name (R/wet_pcic_fetch.R:33-35) | `run_files()` (scenario_basis.R:313-319) | sound today (same format and argument order); latent: a missing file gives `md5sum()` NA, which `sort()` drops silently, and the report's "60 one-year files" is a constant, not a count |
| D2 | the pilot's bulk directory name and `batch_name()` | scenario_basis.R:238, :243-245 and the lib's `batch_name()` | sound: identical to channel_scale_pilot.R:333-335, :358; the pilot writes `.missing` only for one-outlet batches (:383-386), so the "names no single outlet" stop cannot fire on the pilot's cache |
| D3 | files that key a cache on R source | #45's `pcic_code` | filed as #226; `wb_province.R`, `wb_score_md5.R`, `wb_shape_daily.R` hash none of the three changed R files |
| D4 | which scripts read the three changed R files | `discharge_publish_own.R`'s new entries and comment | sound: no table script (`segment_output.R`, `wb_output.R`, `segment_daily_output.R`) or what they source calls `wet_pcic_fetch/annual/monthly` or `wet_runoff_monthly`; the comment's "MAD and term scripts" omits `wb_plateau_p.R`, `channel_scale_pilot.R` and `scenario_basis.R`, which changes no exclusion |
| E1 | the pilot report's Domains and sites tables | `pilot_with_outlet()` col 3, `gcm_by_dom` col 4, `pf[4,8,9,10]`, `pilot_wet_acc()` col 6 | sound against the tracked pilot report (lines 19-24, 227-233) |
| F1 | hydromosaic's model, scenario and variable spellings and day counts | `gcms6`, `ssps`, `"PNWNAmet"`, `"historical"`, `"streamflow"`, `day_pass()` | sound against a cached pilot listing (1001920.json): PNWNAmet 23011 = days 1950-01-01..2012-12-31, GCMs 55152 = 1950-01-01..2100-12-31, both pass |
| F2 | PCIC's CMIP5 run names | `cmip5` members | agrees with research/pcic_hydrology.md; not measurable without a request |
| G1 | the request log | read at start for "first fetch", at end for "requests logged" | **finding 1** |

## Findings

- **[severity: bug]** scripts/scenario_basis.R:131 and :437 — `first_fetch` is computed from the fetch log as it stands at the start of the run, while "requests logged" (:424-428) re-reads the log at the end. On the run that makes the requests (`WET_SCENARIO_FETCH=1` with an empty `<data root>/logs/169/scenario_basis_fetch.tsv`, the run whose report is meant to be committed: it is the only one that prints "PCIC access: WET_SCENARIO_FETCH=1"), the report says `first fetch: none` beside `requests logged: 48,7xx…`. The provenance line that shows the requests came after the registration is wrong on exactly the report that needs it, and only a second, fetch-free run would print it right. Remedy: at report time, run `fetch_guard(log, reg$utc)` on the log read at :424 and print that.
  - **Rule:** code-check.md "One fact derived twice"

- **[severity: fragile]** scripts/pcic_coverage_map.R:27, :43-72 — `map_layers.rds` is a fixed name keyed by none of what it is built from (`rivers`, `towns`, `simplify_m`, `main_flow`, the queries). Its guards (`setequal(lab$name, rivers)`, `setequal(pl$name, towns)`) run only on the cold path, so after an edit to any of those constants the script silently draws the old layers into the committed `research/pcic_coverage.png`, and the guard that would compare the stored layers with the edited list never runs. Remedy: key the file on those inputs (as the `pcic_coverage_<release>.tsv` md5 is held), or check the stored layers' names against `rivers` and `towns` on every read.
  - **Rule:** code-check.md "Written data outlives the fix" ; code-check.md "A guard that fails toward pass"

- **[severity: fragile]** R/wet_pcic_fetch.R:41-57 with its other callers, scripts/wb_term_diagnose.R:63-69 and scripts/wb_plateau_p.R:120-127 (not in the diff) — both callers wrap the fetch in their own immediate three-try loops, written when the fetch had no retry. Now the fetch itself makes up to five tries on 429/503 (waits 60-480 s), so on a cache miss a throttled file costs up to 15 requests, and a deterministic refusal (404, a non-NetCDF 200, the new day check) costs three identical full downloads with no wait. Neither caller sets `wet.pcic_request_log` or the refusing `wet.pcic_base`, so none of it is logged, against a host the owner has asked not to be requested until PCIC answers. #226's rerun of `wb_term_diagnose.R` is guarded only by "check that no file is added" under `data/pcic/`, which cannot see a refused or failed request (a refusal adds no file). Remedy: run #226 with `options(wet.pcic_base = "http://127.0.0.1:9")` (or the env equivalent) as `scenario_basis.R` does without `WET_SCENARIO_FETCH`, so a cache miss fails without a request, and say so in #226's body; drop or space out the callers' own loops when they are next touched.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness" ; code-check.md "A proxy is not the property"
