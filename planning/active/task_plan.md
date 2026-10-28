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
   - **harvest**: discharge (not only stage) with a maintained rating; licence allows use and redistribution of derived values; machine-readable access (API or bulk); and at least 5 BC stations not in HYDAT with ≥ 3 complete years in some Chinook window (05-01–09-15), the size of record the Maxan pilot used.
   - **test-only**: discharge usable for scoring but failing redistribution, QA or the station threshold (we score against it, never publish from it).
   - **no**: stage only, no discharge, duplicates HYDAT, or no access.

## Phase 1: Prior work and verdict rule
- [ ] Enumerate installed NGE packages' exports and `gh api search/code` across the org for each source's name, host and API terms (`datastream`, `columbiabasinwaterhub`, `skeena`, `aquarius`, `unbc`, `hakai`); list `ngr`'s hydrometric functions (`ngr_hyd_q_daily()` ports here, #25). Record every hit or the negative with what was searched.
- [ ] Search open issues and PRs in wet and adjacent repos (water-temp-bc, ngr, fresh, knowledge) for work on any candidate.
- [ ] Write `research/station_sources.md` skeleton: header (Verified / Issues / Produced by), tag legend, verdict rule from decision 3, one empty row per source.

## Phase 2: Per-source desk research
For each of the five, establish the issue's six points from the source's own documents and API, tagged `[S]`/`[M]`/`[I]`:
- [ ] Province's hydrometric stations (ENV Aquarius / BC Water Tool / the federal–provincial agreement): which are already in HYDAT, by station number. Checked, not assumed.
- [ ] Living Lakes Canada, Columbia Basin Water Hub.
- [ ] Skeena Knowledge Trust (and its hydrometric holdings, if any).
- [ ] DataStream hubs (Mackenzie, Pacific/Atlantic etc.): whether any discharge parameter exists beside water quality.
- [ ] UNBC stations (Northern Hydrometeorology Group, Quesnel River Research Centre, etc.).
- [ ] "Also found" table (decision 1).

## Phase 3: Probe and counts
- [ ] `scripts/station_sources_probe.R`: station lists → HYDAT match → per-source counts (total, BC, discharge, not in HYDAT, with ≥ 3 complete Chinook-window years where record lengths are listed), report under `data/checks/`, snapshots under gitignored `data/station_sources/raw/` with md5s.
- [ ] Fill the counts into the research file from the report.

## Phase 4: Verdicts, index, issues
- [ ] Inventory table: one row per source and asset found (accessed or not), with the six points, access status and what blocked it; verdict and reason as a column; a short opening answer (which sources are worth a harvester) and a note on how the counts move under a lower bar (e.g. any non-HYDAT discharge station).
- [ ] `research/README.md` index row; one line in CLAUDE.md's Data Sources pointing to the file.
- [ ] File one wet issue per **harvest** verdict (and one for test-only sources only if a test needs them), and cite them in the file and in #118's body.

## Owed at the end (reported, done after merge)
- [ ] Tick #123 in #118's component list (`/gh-pr-merge` step 3b).

## Validation
- [ ] `/code-check branch` clean (the probe script and docs)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

Verification: rerun `scripts/station_sources_probe.R` and diff the report (identical given the same snapshots); every `[M]` number in the research file greps to a line of the report; every source row has all six points or says "not found" with what was read; every URL in the file answers (curl status); every issue number cited resolves to the right title.
