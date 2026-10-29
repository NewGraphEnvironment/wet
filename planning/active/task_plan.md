# Task: Station source survey: which networks beyond HYDAT hold BC discharge usable as donors or tests (#123)

More gauges is the biggest accuracy lever for departures at ungauged sites: short and seasonal records serve as local donors and as held-out tests. HYDAT, ECCC real-time and the provisional archive wet already reads (`wet_station_daily()`) are federal. Nothing is known yet about the others.

## Context

#118 (flow change at ungauged sites) names more gauges as its biggest accuracy lever: short and seasonal records are local donors and held-out tests for `wet_window_extend()` / `wet_departure_carry()`. wet reads only federal sources today (HYDAT, the water-temp-bc provisional archive, ECCC real-time, through `wet_station_daily()`). #123 is research only: establish, for each network beyond HYDAT that may hold BC discharge, what it holds and whether it is worth a harvester. Output is `research/station_sources.md`; each source that passes gets its own issue. No harvester is written.

Existing context: `research/runoff_prior_art.md` §3 already counts HYDAT's BC stations (2,324; 1,074 with flow) and is the header/tag model (`[S]` source says, `[M]` measured, `[I]` inferred). `research/station_flow_departure.md` holds the Maxan pilot's donor pool (53 natural HYDAT gauges with ≥ 3 migration windows), which gives "useful to #118" a concrete yardstick.

## Decided at the gate

All three decided by the user, 2026-10-28.

1. **Scope:** the five named sources in depth, plus an "also found" table for networks met along the way (likely: Hakai Institute's coastal watersheds, BC Hydro, regional districts and Metro Vancouver, Okanagan Basin Water Board, USGS cross-border gauges), each with a one-line verdict and no full six-point check.
2. **Counts by committed probe script:** `scripts/station_sources_probe.R` pulls each source's public station list once (no flows beyond a sample), matches it to HYDAT 2026-07-17 by station number, then by location (within 1 km and same stream name), and writes `data/checks/station_sources_<date>.txt` with the raw snapshot md5s. Every `[M]` count in the research file cites that report.
3. **Record everything, so the bar can be revisited (user):** every source and every asset found is recorded, including ones not accessed (login, request-only, no API, dead link), with what blocked access and per-station facts where known. A verdict is a column over that inventory, not a filter on it; the probe report lists every station read, not only those passing. The bar as drafted, written into the file's header before any source is checked:
   - **harvest**: discharge (not only stage) with a maintained rating; licence allows use and redistribution of derived values; machine-readable access (API or bulk); and at least 5 BC stations not in HYDAT with ≥ 3 complete years in some Chinook window, the size of record the Maxan pilot used. *Pinned after plan review:* a window is the migration (05-01–08-01) or the spawning (08-01–09-15) window of `life_history_bulk.csv`, and a complete year is a row `wet_window_stats()` returns at its default `min_frac = 0.8`, as in `scripts/departure_pilot.R`, never `wet_station_select()`'s 12-month year, which no seasonal gauge passes. A count from a listed period of record, not daily values, is a proxy tagged `[I]` and cannot by itself reach harvest. Regulation is recorded per station (natural, regulated, unknown) beside the count, since the pilot pool was natural only.
   - **test-only**: discharge usable for scoring but failing redistribution, QA or the station threshold (we score against it, never publish from it).
   - **no**: stage only, no discharge, duplicates HYDAT, or no access. A station at a HYDAT site counts as a duplicate only where its period overlaps HYDAT's there; one that adds years at a discontinued HYDAT site (the Maxan case) is counted separately as "same site, new years".

Plan review: `planning/active/review-plan.md`; its findings are folded in above and below (all checked against the code it cites).

## Phase 1: Prior work and verdict rule
- [x] Enumerate installed NGE packages' exports and `gh api search/code` across the org for each source's name, host and API terms (`datastream`, `columbiabasinwaterhub`, `skeena`, `aquarius`, `unbc`, `hakai`); list `ngr`'s hydrometric functions (`ngr_hyd_q_daily()` ports here, #25). Record every hit or the negative with what was searched.
- [x] Search open issues and PRs in wet and adjacent repos (water-temp-bc, ngr, fresh and one more of ours) for work on any candidate.
- [x] Write `research/station_sources.md` skeleton: header (Verified / Issues / Produced by), tag legend, verdict rule from decision 3, one empty row per source.

## Phase 2: Per-source desk research
For each of the five, establish the issue's six points from the source's own documents and API, tagged `[S]`/`[M]`/`[I]`:
- [x] Province's hydrometric stations (ENV Aquarius / BC Water Tool / the federal–provincial agreement): which are already in HYDAT, by station number. Checked, not assumed.
- [x] Living Lakes Canada, Columbia Basin Water Hub.
- [x] Skeena Knowledge Trust (and its hydrometric holdings, if any).
- [x] DataStream hubs (Mackenzie, Pacific/Atlantic etc.): whether any discharge parameter exists beside water quality.
- [x] UNBC stations (Northern Hydrometeorology Group, Quesnel River Research Centre, etc.).
- [x] "Also found" table (decision 1).

## Phase 3: Probe and counts
- [x] `scripts/station_sources_probe.R`: station lists → HYDAT match → per-source counts (total, BC, discharge, not in HYDAT, same site with new years, regulation, record length, and complete Chinook-window years), report under `data/checks/`, snapshots under gitignored `data/station_sources/raw/` with md5s. After the plan review:
  - HYDAT through `WET_HYDAT_RELEASE` → `wb_hydat()` (`scripts/wb_fit_lib.R`), refusing any release but 20260717; HYDAT counts recounted on that release, not taken from `runoff_prior_art.md`, which used an unpinned copy.
  - The match is against all of HYDAT's `STATIONS` (stage-only, discontinued, AB/YT/US), first by WSC number where the source stores one, then by location (≤ 1 km) and a normalised stream name (lower case, `Ck`/`Cr` → `creek`, `R` → `river`, the gauge-position words such as `above`, `near`, `at the mouth` dropped). Near misses (≤ 1 km with another name, or the same name at 1–3 km) are listed for a hand check, never dropped.
  - Daily values are read for every non-HYDAT discharge station whose source serves them, and complete window-years come from `wet_window_stats()`. Where a source serves no dailies, the listed period is the `[I]` proxy.
  - Cache or fetch: it reads `data/station_sources/raw/` when present and fetches only what is missing, so a rerun on the same snapshots reproduces the report. A credential (e.g. a DataStream API key) comes from an env var, is never committed, and the report names the sources that needed one.
  - Report `data/checks/station_sources_20260717.txt`, named by HYDAT release as the pilot's is, with snapshot dates and md5s inside, `code_md5`, and no timestamp.
- [x] Fill the counts into the research file from the report.

## Phase 4: Verdicts, index, issues
- [x] Inventory table: one row per source and asset found (accessed or not), with the six points (the rating's maintainer named under point 1; point 6 answered by the recorded org-wide search), access status and what blocked it; verdict and reason as a column; a short opening answer (which sources are worth a harvester) and a note on how the counts move under a lower bar (e.g. any non-HYDAT discharge station), with seasonal-only stations counted on their own.
- [x] `research/README.md` index row; one line in CLAUDE.md's Data Sources pointing to the file.
- [x] File one wet issue per **harvest** verdict (and one for test-only sources only if a test needs them), and cite them in the file and in #118's body.

## Owed at the end (reported, done after merge)
- [ ] Tick #123 in #118's component list (`/gh-pr-merge` step 3b).

## Validation
- [x] `/code-check branch` clean (the probe script and docs)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

Verification: rerun `scripts/station_sources_probe.R` and diff the report (identical given the same snapshots); every probe-derived `[M]` number in the research file greps to a line of the report (a desk measurement, such as an API field check, says its command beside it); every source row has all six points or says "not found" with what was read; each URL's status as recorded (answers, login, dead) matches a curl of it; every issue number cited resolves to the right title.
