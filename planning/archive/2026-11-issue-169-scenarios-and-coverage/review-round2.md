# Code check, round 2 (#169)

## Checklist read

- code-check-r.md (read by heading): "`tryCatch()` nests its handlers, so a `stop()` in one is caught by a later one", "A fetcher's test helper must make the network fail, not just mock the reader", "A library call that dispatches on a global option is not a pure function", "`on.exit()` at a script's top level never fires" (from the index line), "`download.file(quiet = TRUE)` never tells you the HTTP status — read it from `curl`" (from the index line). About 120 headings not read.
- code-check-shell.md (read by heading): none applied (no shell in the diff); all headings not read.
- code-check-spatial.md (read by heading): none read in full; the diff's spatial code (terra, sf in pcic_coverage.R) is unchanged since round 1 and outside the fixes.
- code-check.md: the prose of every H3 under `## Mechanisms`, skipping the `|` rows; "Documentation Staleness".

Index, diff and changed files read from file.

## Round 1's fixes

All three hold.

1. **Request log (`R/wet_pcic_fetch.R`, `scripts/scenario_basis.R` `fetch_run()`).** `wet_request_log()` runs after every `wet_http_disk()` call, including each 429/503 retry, and once with status 0 in the error handler before `stop(e)` re-raises. There is one handler, so nothing nests (the R checklist's `tryCatch()` rule). `fetch_run()` sets the option for each year and restores it after a normal return; on an error the script stops, so nothing runs with a stale closure. A cached year makes no request and logs nothing. Measured in a detached copy at HEAD: test-wet_pcic_fetch.R ran 8 tests with 0 failed and 0 errors (`NOT_CRAN=true`, so nothing was skipped); test-wet_pcic_monthly.R and test-wet_runoff_monthly.R ran 3 tests each, also with 0 failed and 0 errors.
2. **The `undecided` class.** The CSV row has 24 fields like the rest. `gq::gq_reg_custom()` and `gq_tmap_classes()` return `undecided` with its colour and label, so `cls("coverage_scenarios", scen_lev)` passes whenever pcic_coverage.R writes that class.
3. **Listing check before caching (`scripts/scenario_basis_lib.R` `listing()`).** I ran the guard on all 247 listings in the pilot's cache (`data/channel_scale/raw/services/listing/*.json`): it accepts all 247, accepts the `"[]"` written for a 404, and refuses an empty or HTML body because `fromJSON` errors and returns NULL. I also ran rule 4's parsing on those 247 listings. It found no duplicate streamflow row per run, and `num_times` equals the inclusive day count on every row (55152 days for 1950-2100, 23011 for 1950-2012). The bulk-cache step works too: TaiESM1 ssp245's 74 `.missing` markers each resolve to exactly one crosswalk outlet through `batch_name()` (3 s), so the "names no single outlet" stop does not fire on the pilot's cache.

## Findings

- **[severity: fragile]** scripts/wb_small_basin.R:296-327 (caused by the branch's edit to R/wet_pcic_fetch.R) — `scripts/wb_term_diagnose.R:38-42` hashes `R/wet_pcic_fetch.R` into `pcic_key`. The branch moves that key from 7589068ca4 (the tracked `data/checks/wb_term_diagnose_20260717.txt`, line 3) to 114b40232c, which I computed at HEAD by parsing #45's own statements. The plan (task_plan.md:71, review-plan.md item 10) names only #45's consequence: its next run rebuilds under a new key. It misses a second consumer. `scripts/wb_small_basin.R` (#176) re-evaluates #45's `pcic_key` by `parse()` and requires `pcic_upstream_<basin>_<pcic_key>.rds` to exist. No file exists for 114b40232c; the m1 cache holds only 30022867b6 and 7589068ca4. So after merge, `scripts/wb_small_basin.R` stops with "is not what scripts/wb_term_diagnose.R makes from this fit now (no pcic_upstream_300_114b40232c.rds for its current code): rerun it" until #45 is rerun, and that rerun rewrites #45's tracked report line. The refusal is loud and names its remedy, so no wrong number ships. But a merge leaves a documented script unrunnable, and neither the plan, the PR text nor CLAUDE.md says so. The rerun makes no PCIC request when the cached daily files are present.
  - **Rule:** none

## Notes (not findings)

- Rule 4's population is every row of `pcic.fwa_crosswalk`: 48,716 outlets (38,146 placed) by a read-only query of the local fwapg. A first run with `WET_SCENARIO_FETCH=1` therefore makes about 48,716 listing requests, one per outlet. Between successful (200) requests there is no pause; `listing()` waits only on a 429/503. This is the registered rule, not a defect, and the listings are cached as they arrive, so a crash part-way repeats none of them. The count bears on what PCIC is asked for before the fetch is turned on.
