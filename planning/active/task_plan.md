# Task: Backlog move 7: Scenarios and coverage, after the channel-scale pilot (#169)

**If we do it:** scenario period means and the coverage-and-comparison map are built on whichever PCIC product move 6's pilot chooses. **If we never do:** wet publishes 1981–2010 normals only, and other groups' products stay unscored by watershed group.

Move 6 (#168, `research/pcic_channel_scale.md`) gave a verdict by registered rule: CMIP6 routed through fwapg's crosswalk on the coast, Columbia and Peace; CMIP5 gridded in the Fraser, scored first. Batch 10 carries #4 (scenario period means), #5 (coverage and comparison) and #205 (re-verify `research/pcic_hydrology.md`).

## What this plan carries, in one pull request

Batch 10 is more than one pull request's work: a whole CMIP6 run is about 17 GiB of series and there are 18 of them, each routed by fwapg's job in another repository; the gridded CMIP5 runs for four periods in the Fraser are about 66 GiB; and publishing scenarios changes stored data. So this pull request carries the first piece of each member and the pattern the rest follow:

1. **#205:** `research/pcic_hydrology.md` re-verified as far as open decision 1 lets it be read, with PCIC's access rules on record.
2. **#4, first piece: what the scenarios can be built on.** The two checks move 6 left open, each under a rule registered before any value is read: what each CMIP6 run lacks against the crosswalk fwapg stores (rule 4), and whether the CMIP5 gridded runs' 1981–2010 flow in the Fraser is PNWNAmet's by the pilot's rule 2 (rule 5). Plus the readers rule 5 needs (a gridded run's months, a fetch that reads its HTTP status).
3. **#5, first piece: which product covers which watershed group.** A tracked report over the 246 watershed groups and a map.

Left for issues filed in Phase 6: building the scenario period means, publishing them, and scoring the products #5 names that no report scores yet.

## Decided at the gate

The owner, 2026-11-25, at the coordinator's plan gate (recorded in #169's body under `## Decisions`):

1. **PCIC's data: ask first, with a fallback (answer (a)).** A short note to PCIC, drafted where outward correspondence is drafted (not in this repository), and sent or not by the owner: thanks, the pilot's result as #9 meant to share it, what move 7 would read, and an open question on how PCIC would like bulk reads done and when the new portal opens. It says that, unless PCIC prefers otherwise, the project would read politely from about mid-December (one request at a time, waiting on every 429, a user agent naming wet), in gentle general language. Until then this pull request makes no new request to a disallowed path; rules 4 and 5 are registered and coded, and their runs wait.
2. **The split: yes**, as "What runs under each answer" sets out.
3. **The Fraser: keep rule 3** and score CMIP5 there (rule 5) before anything is built on it.

#169's body also records (2026-11-25) a second host for PNWNAmet: figshare's `PNWNAmet.nc` (55 GB, collection DOI 10.6084/m9.figshare.c.3965337), with no robots restriction. Rule 5's PNWNAmet side can come from it if the cache misses; the CMIP5 and CMIP6 hydrology still comes from PCIC only.

Mechanism, decided in the draft (2026-11-25), each with its reason:

## What runs under each answer

Decision 1 was answered (a), so the right-hand column runs. Decision 2 yes, decision 3 rule 3.

| | decision 1 (b): fetch | decision 1 (a) or (c): no new request |
|---|---|---|
| Phase 1 | every section re-read; `Fixes #205` | sections under `/data/` keep their old date and say why; #205 stays open, its body edited to what is left |
| Phase 2 | built and tested (no request either way) | the same |
| Phase 3, rule 4 | registered, coded, run | registered and coded; not run |
| Phase 3, rule 5 | registered, coded, parity, fetch, score | registered and coded; the PNWNAmet parity run offline from the cache; no CMIP5 file asked for |
| Phase 4 | after Phase 3's runs, from its listings and one whole-grid day per run named | from the pilot's cached listings by domain and the cached basin subsets, each labelled so |
| #4 at the end | closed, retitled to the piece delivered; the build is a new issue (decision 2 yes) | stays open, rescoped in place: run the registered checks, then build; no scenario issue is filed |

Decision 3, the other way (CMIP6 everywhere): Phase 2 is not built, rule 5 is not registered, and the right-hand map panel has no "CMIP5 gridded" class. Decision 2, coverage as its own pull request: Phase 4 and #5's part of Phase 6 move to a new issue filed in Phase 6, and #5 stays open.

## Phase 1: PCIC's products and access, re-verified (#205)

Says what PCIC serves now and on what terms, before any new request.

- [x] Before building: `bash "$T/skills/_shared/members_check.sh" "$(git remote get-url origin)" 169 169-backlog-move-7-scenarios-and-coverage-af --batch 10` (`T` from `soul_published_tree`). On a non-zero exit or any line but `FREE`, build nothing of this phase: write the line under `## Open decisions` and stop.
- [x] Under answer (a) to decision 1: draft the note to PCIC and show it to the owner in the session's report (not in this repository). Nothing is sent by the session.
- [x] `research/pcic_hydrology.md`: add "Access and robots.txt" (both hosts' robots.txt as read on 2026-11-25, the 429, which paths wet and fwapg read, and the owner's answer to decision 1), in the form of `research/station_sources.md`'s section.
- [x] Re-read each claim in the sections dated 2026-09-25 against what it describes, and revise in place (no section per issue): the hosts and the catalog (`/portal/hydro_model_out/catalog/catalog.json`, a path robots.txt allows; the count of datasets); the gridded runs table (names, spans, variables); the time axis, with what 2026-11-25's probes read (in `findings.md`) and, under answer (b) only, the other ten CMIP5 runs' `.das` and `.dds`, one at a time; "No CMIP6 hydrology on the portal", which hydromosaic's runs now contradict; the other products (`hydro_stn_cmip5`, the salmon portal, `downscaled_cmip6`) from their pages; the terms page. A claim that could not be re-read says so and keeps its old date.
- [x] The header's `**Verified:**` date and `**Produced by:**` line (the commands, kept in this plan's `findings.md`, which the archive holds); `research/README.md`'s row. Every other copy of a sentence this phase changes is corrected in the same commit, wherever a grep of `research/`, `CLAUDE.md` and `R/` finds it.
- [x] Verify: every sentence changed names what was read and when; the file reads top to bottom with one date per section; a grep for each changed sentence's old wording finds no copy left. Commit with `Fixes #205` under answer (b); otherwise edit #205's body to the claims still unread and leave it open.

Changed by the plan review: the note is drafted first, not after the merge; stale copies are fixed where found, not only searched for; #205 closes only when its `/data/` claims were read.

## Phase 2: A gridded run's months, and a fetch that reads its status (#4)

Tests first; no request is made in this phase (the network is mocked). Not built under the other answer to decision 3.

- [x] Before building: the member re-check, as Phase 1's first box.
- [x] Before any edit, record the "before": in a `git worktree` of `origin/main`, `wet_pcic_annual("RUNOFF", <the pilot's Fraser bbox>, 1981, dir = <the cache>)` under `options(wet.pcic_base = "http://127.0.0.1:9")`, its values saved to the scratch directory. The bbox is the pilot's recipe (`scripts/channel_scale_pilot.R`, the extent of `wscode_ltree <@ '100'`, projected to longitude and latitude, padded by one cell); another bbox names another file and would ask PCIC for it.
- [x] `tests/testthat/test-wet_runoff_monthly.R`: on a synthetic two-year daily raster holding a leap year, twelve layers `m01` to `m12`, each the mean over the years of that month's total; the twelve sum to `wet_runoff_annual()`'s layer (`expect_equal`, tolerance 1e-12); an incomplete year and a duplicated date are refused.
- [x] `R/wet_runoff_monthly.R`: `wet_runoff_monthly(r)`, exported, with a runnable example on a small synthetic raster.
- [x] `tests/testthat/test-wet_pcic_monthly.R` and `R/wet_pcic_monthly.R`: `wet_pcic_monthly(variable, bbox, years, run, dir, timeout)`, one year at a time as `wet_pcic_annual()` fetches, returning twelve layers; a year on another grid is refused. The test mocks `wet_pcic_fetch()` and asserts the mock's argument names against `formals(wet_pcic_fetch)`.
- [x] `wet_pcic_fetch()`: download through `curl::curl_fetch_disk()` behind an internal wrapper (`wet_http_disk()`, the one thing tests mock; user agent `wet`) and read the status. 200 goes on to the NetCDF signature check; 429 and 503 wait `Retry-After` (60 s when absent, doubling, five tries) and try again; any other status stops, naming it. A **downloaded** file whose days (terra's time axis) are not exactly `start` to `end` is refused and removed before it is renamed into the cache; a file already in the cache is returned as before, unread. Tests in `tests/testthat/test-wet_pcic_fetch.R`: 429 then 200 keeps the file after one wait (the wait mocked to nothing); 404 stops naming 404; a 200 that is an HTML page is refused; a NetCDF holding other days is refused; the existing cached-file test still passes unchanged. The tests that need a real NetCDF write one with terra and `skip_if_not_installed("ncdf4")`, as `test-wet_pcic_annual.R` does. Restore each defect once and watch its test go red.
- [x] `scripts/discharge_publish_own.R`: after the check its header asks for (that `scripts/segment_output.R`, `scripts/wb_output.R` and `scripts/segment_daily_output.R` neither source nor call them), add `R/wet_pcic_fetch.R`, the two new `R/` files and, as each lands in a later phase, the four new scripts. A file left off only forces a segment rebuild at the next publish.
- [x] `devtools::document()`; the two exports in `_pkgdown.yml`'s reference index beside `wet_pcic_annual`; `pkgdown::check_pkgdown()`; lints compared per file against `origin/main` in a worktree.
- [x] Verify: `devtools::test()` in one call with the failure grep; the branch's `wet_pcic_annual()` on the same cached year, offline as above, is `identical()` to the saved "before".

Known consequence, stated and not acted on: `scripts/wb_term_diagnose.R` hashes `R/wet_pcic_fetch.R` into its cache key, and its tracked report prints the key, so its next run recomputes its tables from the cached daily files under a new key. It is not rerun here.

Changed by the plan review: the days check applies to a download, never to a cached file; a user agent; the publish guards' list; a recorded "before" for the cached-year check; the offline guard; the `wb_term` cache key.

## Phase 3: What the scenarios can be built on (#4)

`scripts/scenario_basis.R` → `data/checks/scenario_basis_<release>.txt` (tracked), with `scripts/scenario_basis_lib.R`. Run with `WET_FWAPG_COMMIT` as the routed report names it and `WET_DATA_ROOT` naming the main checkout's `data/`, where the pilot's caches and the gridded PNWNAmet files are.

- [x] Before building: the member re-check, as Phase 1's first box.
- [x] **Register the rules first, in a commit of their own that holds no fetching code:** the header of `scripts/scenario_basis.R` with the rule block below (rule 5 left out under the other answer to decision 3), between the same two marker lines the pilot uses. The script finds the commit that registered the block as the pilot does, prints it and the time of the first logged fetch ("first fetch: none" when the log does not exist), and refuses to run when a logged fetch precedes the registration.
- [ ] `scripts/scenario_basis_lib.R`: copies of the pilot's `domain_of()`, `h_curl()` (user agent `wet-scenario-basis`), `fetch_log()`, `listing()`, `batch_name()` and the rule-block finder, with the pilot left untouched; `listing()` waits and retries on 429 as Phase 2's fetch does and stops after five refusals in a row. The log is `<data root>/logs/169/scenario_basis_fetch.tsv`; listings are kept under `<data root>/scenario_basis/listing/` (gzip), the report naming the md5 of their md5s. Every gridded file the script causes to be downloaded is logged too: the script calls `wet_pcic_fetch()` one year at a time itself and logs a row (run, variable, year, bytes, seconds) whenever the file was absent before the call.
- [ ] Rule 4 coded. Run under answer (b) to decision 1 only; otherwise its section of the report reads "not run: <the answer>".
- [ ] Rule 5 coded, and its PNWNAmet side run from the cache under `options(wet.pcic_base = "http://127.0.0.1:9")`, so a cache miss fails instead of asking PCIC: the parity lines must hold before any CMIP5 file is asked for. The CMIP5 fetch and score run under answer (b) only; otherwise as for rule 4.
- [ ] The report: provenance (the registration, the first fetch, script commit, routed table fingerprint, bundle md5, cache md5s, and requests, bytes and minutes from the log); rule 4's table (18 runs × 4 domains) and verdicts; rule 5's parity lines, table and verdict, each gauge's accumulated area over the bundle's `area_km2`, and, where the pilot's 0.082 and −0.036 sit beside the new numbers, the three ways rule 5 is not rule 2 (below). Two runs from the cache give a byte-identical report (logs under `data/logs/169/`).
- [ ] Verify, under every answer: the registration guard refuses with a log row dated before it (a scratch log); a parity value moved in the last printed digit refuses; the 73 Fraser gauges equal the pilot report's Domains line. Under answer (b) also: a listing cache missing one outlet refuses. `/code-check` on the script before its first fetch, since a rerun after a fix would repeat requests.

Rule 5 is the pilot's rule 2 in its thresholds, its median over gauges and its gauges, and differs in three ways the report must state: its year is the twelve months' total, where the pilot takes the plain mean of twelve monthly mean flows; its PNWNAmet side is the gridded run accumulated unrouted, where the pilot's is the routed outlet series; and its two sides are different models (VICGL against VICGL-RGM), so a fail can be model structure and not forcing.

The rule block, to be committed as written (amendments after numbers are seen go below it, dated, as the pilot's do):

```
# ---- rules registered before any flow value was read (#169) ------------------------------------
# Rule 4, each CMIP6 run against the stored crosswalk. Known before
# registration, from fwapg's own notes: 3 of PNWNAmet's 28 outlets with no
# series also lacked one for CNRM-ESM2-1 when it was last fetched, so that run
# has series where PNWNAmet has none, and fwapg's job, which refuses a run
# whose crosswalk differs from the stored one, would refuse it. The rule
# therefore measures what each run lacks, not whether the job runs unchanged.
# Population: every outlet of pcic.fwa_crosswalk. The reference set S is the
# outlets the stored crosswalk treats as having a series (flag is not
# no_series). An outlet's row for a run (a model and scenario) is its listing's
# streamflow row for that model and scenario; two such rows at one outlet stop
# the script. A row passes the day test when num_times equals the days from
# start_time to end_time, both ends counted, it starts on or before 1951-01-01
# and it ends on or after 2012-12-31 (PNWNAmet, historical) or 2099-12-31 (a
# GCM under "historical, ssp245" or "historical, ssp585"). An outlet has a
# series for the run when its row passes; an outlet whose row fails is counted
# apart ("listed, fails the day test") and has none. No flow value is read.
# Reported first, deciding nothing: the outlets where PNWNAmet's listing and S
# disagree (hydromosaic may have changed since the build). Then, per run of the
# 9 GCMs x 2 scenarios: A, the outlets of S with no series for the run, and B,
# the outlets outside S with one, each counted over the network, by PCIC
# domain (the pilot's domain_of()) and by crosswalk flag. Verdict per run,
# typed in this order: "runs as the job stands" (A and B empty); "runs on the
# stored crosswalk" (A empty, B not: the job need only keep the stored
# crosswalk and leave B's series out); "lacks series the crosswalk places" (A
# holds an outlet whose flag is NULL), with A's placed outlets by domain and
# whether the run's outlets with no series pass 100, where the job stops;
# otherwise "lacks series at unplaced outlets only". A run is "whole in a
# domain" when A holds none of that domain's outlets. A listing is a proxy for
# what a bulk request returns, which is what fwapg's job reads, so the pilot's
# cache is set against it: every outlet in a kept NetCDF of a model and
# scenario must have a series by its listing, and every single-outlet missing
# marker (batch_name() of the one outlet) must have none; the outlets where
# they disagree are listed and that run's verdict gains "listing and bulk
# disagree at n outlets". Nothing here chooses a GCM.
#
# Rule 5, CMIP5 gridded in the Fraser. Population: the pilot's scored gauges
# with an outlet whose domain is the Fraser (73 in the pilot's report), with
# their segments and observed annual flow as the pilot takes them (q_obs: the
# bundle's month-0 obs_mm over area_km2 at 365.25 days). Depth at a gauge, for
# PNWNAmet (TPS_gridded_obs_init) and for each CMIP5 run: RUNOFF + BASEFLOW,
# each month the mean over 1981-2010 of the month's total per cell
# (wet_pcic_monthly(), on the pilot's bbox for the Fraser), accumulated as the
# pilot's "wet's accumulation" was: the polygons of wet_ws_fetch(conn, "100"),
# centroid sampling, and for each month wet_upstream_mean(ws, <the month>,
# "total", irregular_pairs = wet_upstream_irregular(conn, "100")), read at the
# watershed of the gauge's segment. That gives twelve depths in mm. The annual
# flow is wet_mm_to_m3s(their sum, the accumulated area) at its default 365
# days; the monthly shares are the twelve depths over their sum. Parity before
# any CMIP5 file is asked for: PNWNAmet's annual flow at the pilot's sites
# salmon, quesnel, hope and lillooet (segments from
# scripts/channel_scale_sites.csv) equals the "wet acc" column of the pilot's
# tracked report at its two decimals. The rule is the pilot's rule 2 with the
# six RCP 4.5 runs in place of the nine "historical, ssp245" series, all six
# required at every gauge: |median over the 6 GCMs of annual flow -
# PNWNAmet's| / q_obs <= 0.05, and the share NSE (wet:::wet_nse() against the
# gauge's observed shares, the bundle's twelve obs_mm over their sum) of the
# 6-GCM median month (the median of the six depths month by month, then
# shares) no more than 0.05 below PNWNAmet's. The Fraser passes when the
# median over its gauges of each statistic meets it. RCP 8.5: each GCM's
# RCP 8.5 file is set against its RCP 4.5 file for 1981, 1993 and 2005 (the
# CMIP5 historical experiment ends in 2005), day by day and cell by cell, per
# variable, and the largest absolute difference reported; 2008, where the
# scenarios differ by construction, is compared the same way and only
# reported. Where a difference in 1981, 1993 or 2005 exceeds the larger
# scale_factor of the two files, the rule is scored on the six RCP 8.5 runs
# too, and the Fraser passes only if both sets do. Verdict: pass, "the Fraser
# builds on CMIP5 gridded"; fail, "DECISION TO USER: neither generation meets
# rule 2 in the Fraser", with the pilot's CMIP6 statistics for the Fraser
# beside these. Reported, deciding nothing: each GCM's own statistics; the
# rule with the gauges left out whose watershed is more than 5 % glacier (the
# CMIP5 runs carry no glacier model and PNWNAmet's does); the signed annual
# difference.
# ---- end of registered rules --------------------------------------------------------------------
```

Changed by the plan review: rule 4 no longer asks a question whose answer was known (one run is already refused by the job) and types what each run lacks; its reference is the stored crosswalk, not a listing that must match it exactly; a listed series that fails the day test is counted apart; the bulk comparison says how a marker names its outlet. Rule 5 names the exact accumulation call (`wet_upstream_means()` divides by covered area, the pilot by total), the 365-day year the pilot used, how shares and the median month are formed, observed flow, and where the parity sites' segments come from; the RCP 8.5 check gains a scenario year and a defined step. The gridded fetch is logged; the offline guard; which guards run under each answer.

## Phase 4: Which product covers which watershed group (#5)

`scripts/pcic_coverage.R` → `data/checks/pcic_coverage_<release>.txt` (tracked), and `scripts/pcic_coverage_map.R` → `research/pcic_coverage.png`. Under answer (b) to decision 1 this phase runs after Phase 3's runs, never before them.

- [ ] Before building: the member re-check, as Phase 1's first box.
- [ ] `scripts/pcic_coverage.R`, one row per watershed group (`whse_basemapping.fwa_watershed_groups_poly`, 246, ordered by code):
  - the published 1981–2010 product: month-0 rows and picked rows per source, from the live build's `segment_monthly` parts (read through `wet_catalog()` and duckdb, `INSTALL httpfs; LOAD httpfs`, under `scripts/vignette_data_lib.R`'s guards: a clean tree, the passing publish report, the parts held to their manifest md5s before and after the read). Held to the tracked reports: the picks to the segment report's counts, and each source's month-0 rows to the publish report's rows over 13;
  - routed PCIC's network: placed outlets (`pcic.fwa_crosswalk`, flag NULL) and the PCIC domain or domains of the group's segments (`pcic.segment_weights`, `domain_of()`), with each domain's share of them;
  - PCIC's gridded runs: the share of the group's area on cells with values, by exact polygon cover (not cell centres). Under answer (b), from one whole-grid day each of `TPS_gridded_obs_init` and `CanESM2_rcp45_r1i1p1` (two requests); otherwise from the cached Peace, Fraser and Columbia subsets of `TPS_gridded_obs_init`, the report saying so and that the CMIP5 runs' domain is PCIC's statement, not measured;
  - CMIP6 at the group's placed outlets: from Phase 3's listings when rule 4 ran (the GCMs with a series at every placed outlet of the group), else by domain from the pilot's cached listings, labelled so;
  - what scenarios build on: rule 3's product for each domain the group lies in, with Phase 3's verdicts where they ran;
  - the gauges: calibration gauges in the group (`inst/vignette-data/monthly_values.rds`), the number scored, and each source's mean absolute percent error at month 0 as the segment-discharge article takes it (`mae_of()`): routed as published at the gauges where it carries at least a fifth of observed flow, the balance held out at all of them;
  - then the summary: groups by class in each panel, by domain, and by what scenarios build on; the products #5 names that are not in the table and why (no release, no report yet); and which tracked report scores each product that is (`pcic_routed_compare`, `gauge_monthly_compare`, `wally_compare`).
- [ ] Classes, fixed before the table is read. A group's segments are those with a month-0 row in either source; its routed share is those with a routed row over all of them. Left panel, the published sources: both (routed share 0.95 or more), routed on part (0.05 to 0.95), the balance alone (under 0.05). Right panel, what scenarios build on: one product where the routed share is 0.95 or more and 0.95 of the group's weighted segments lie in domains with that product; "part or mixed" where the routed share is 0.05 to 0.95 or two products each hold 0.05 of the weighted segments; none where the routed share is under 0.05.
- [ ] Commit the report before the second run: `vd_commit()` refuses uncommitted `data/checks`.
- [ ] `inst/cartography/wet_coverage.csv` (gq custom registry: the classes' colours and the line styles; no hex in the script) and `scripts/pcic_coverage_map.R`: two panels across the page on one BC extent in BC Albers, each on a canvas of its own box's shape and the two PNGs joined; `sf::sf_use_s2(FALSE)`; a manual legend from the registry, title case; a scale bar; no title. Layers, each query ordered on a unique key: the 246 group polygons from fwapg, simplified in sf (`vm_simplify()`); the BC outline from `whse_basemapping.fwa_bcboundary` as `scripts/wb_map.R` takes it (the bundled outline is cut for a keymap and would not sit on the groups along the coast); river lines of order 7 and up from `inst/vignette-data/segment_map.rds` (its `order_band`); label points for the Fraser, Peace, Columbia, Skeena and Liard from fwapg's main-flow segments of order 7 and up by `gnis_name`, refused unless each name gives one blue line; Prince George, Vancouver, Kelowna, Fort St. John, Smithers and Fort Nelson through `vm_places()` (a BC Data Catalogue WFS query), kept to populated-place feature types. The drawn layers are stored once under `<data root>/pcic_coverage/` so a second render asks nothing. The script refuses a table that is not the tracked report's (the report names the table's md5).
- [ ] Verify: the report byte-identical on a second run; totals equal the two tracked reports'; every group in exactly one class per panel; the cartography self-review on the PNG at 700 px wide, all fourteen checks, the legend checked against what draws the eye; a second render from the stored layers leaves the PNG's pixels unchanged.

Changed by the plan review: the map's layers (the bundle holds no group polygons and no river names; the bundled outline is too coarse; the towns are named and stored); each class's share is defined and the right panel gains "part or mixed"; the gauges' error is the article's mean, not a median; the gridded mask names its runs; the totals check also holds the rows; the report is committed between runs.

## Phase 5: The findings, where the next reader looks

- [ ] Before building: the member re-check, as Phase 1's first box.
- [ ] `research/pcic_scenarios.md` (new; one header line with the date, issues #4, #5, #169 and both producing scripts): coverage by watershed group with the map; the rules as registered; and, where they ran, what each CMIP6 run lacks and the Fraser's CMIP5 score beside CMIP6's, with what each number is of. Where a rule did not run it says so, why, and what waits on it. Wrong turns kept.
- [ ] `research/pcic_channel_scale.md`: "What move 7 builds on" revised in place to what was measured or what waits, pointing to the new file; `research/README.md`: the new row, and `pcic_hydrology.md`'s.
- [ ] `CLAUDE.md` above the marker: one Scripts bullet each for `scripts/scenario_basis.R` and `scripts/pcic_coverage.R` (with the map), the two new functions in the Architecture line, and the Data Sources bullets for the gridded runs and the channel-scale product revised to what Phases 1 and 3 found (the calendar, robots.txt, the verdicts or what waits).
- [ ] Verify: each number in the three files traced to a report line; a grep for the old "What move 7 builds on" sentences finds none left.

Changed by the plan review: what the file holds when a rule did not run.

## Phase 6: The pieces that are not this pull request

As "What runs under each answer" sets out; the issue bodies below are edited, never appended to.

- [ ] Before building: the member re-check, as Phase 1's first box.
- [ ] **The scenario build.** Under answer (b) to decision 1 and a yes to decision 2: file "Scenario period means: build them on the products move 7 chose", naming move 7 as where it was split from; retitle #4 to the piece delivered and close it with `Fixes #4`. Otherwise: rescope #4 in place and file nothing for it. Either way the body carries: the rules as registered and their verdicts, or that they wait and on what; the build by domain (the CMIP6 runs through fwapg's job, with what rule 4 says each needs; CMIP5 in the Fraser where rule 5 passed, or the owner's decision where it did not); each change taken against the same run's own 1981–2010; 2070–2099, not 2071–2100; how the two generations differ at the Fraser's boundary, which #4 asks to be checked; the costs measured (bytes and minutes per run from the fetch logs); the limits (no glacier model in CMIP5, TaiESM1 on the coast); and its gate's stored-data choices as decision 2 lists them.
- [ ] **The unscored products.** On a yes to decision 2: file "Score the products no report scores yet, with a disagreement log: GEOGLOWS v2, TerraClimate runoff, the runoff isolines, the BC Water Tool's modelled estimates", split from move 7, its body carrying #5's remaining bullets (the disagreement log, each difference attributed as ours, theirs or unresolved; the BC Water Tool's release and the questions for the Province, which go through the owner) and the coverage report's list of what is not in the table; retitle #5 to the piece delivered, say in its body that the map is a research figure and not on the site, and close it with `Fixes #5`.
- [ ] Where rule 4 ran and a run lacks series or needs the stored crosswalk kept, file that in fwapg's repository with the measured counts by domain and flag, and name it in the scenario body. Where rule 4 did not run, file nothing there.
- [ ] #169's body edited to the scope carried and where each other piece went.
- [ ] `planning/backlog.md` is left to `/gh-pr-merge` and the next sweep, which reads a new issue as unplaced and an issue left open after its move merged as open.

Changed by the plan review: #4 closes only when both rules ran; the unrun checks have a home under every answer; #4's boundary check, #5's disagreement log and "published", and the RCP scenario key are each named where they go.

## Owed at the end (reported, done after merge)

- [ ] Any run log this worktree wrote under its own `data/logs/169/` moved into the main checkout's `data/logs/169/` before the worktree is removed.
- [ ] Under answer (a) to open decision 1: PCIC's answer, when it comes, recorded in `research/pcic_hydrology.md`, and the registered checks run under it.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:

- **The readers:** unit tests that fail with the defect restored; `wet_pcic_annual()` on a cached year `identical()` before and after, offline.
- **Rule 4:** the listings against the pilot's cached bulk results before any verdict; the registration before the first fetch, from git and the fetch log.
- **Rule 5:** the parity lines against the pilot's tracked report before any CMIP5 file is asked for; the gauge population against the pilot's Domains line.
- **Coverage:** picks and rows against the two tracked reports; every group classed once per panel; the published parts held to their manifest before and after the read.
- **Both reports:** byte-identical on a second run from the cache.
- **The map:** the fourteen-point self-review at its published width; pixels unchanged on a second render.
- **The research files:** each number traced to a report line; no stale copy of a changed sentence left in `research/`, `CLAUDE.md` or `R/`.
- **No request where none is allowed:** under answers (a) and (c), every run goes under `options(wet.pcic_base = "http://127.0.0.1:9")` and the fetch log stays absent or unchanged.
