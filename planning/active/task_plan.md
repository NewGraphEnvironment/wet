# Task: Backlog move 5: More donors and PCIC's years at the chinook sites (#167)

**If we do it:** departures at the chinook sites are carried by more donors (the province's non-integrated stations and the BC Water Tool's third-party gauges) and by #122's shipped weighting, `covariance_pick`, where PCIC covers the site, and the sites and their article are rerun once with both. **If we never do:** donors stay federal only and the comparison article's carried route stays on inverse distance, the weaker weighting.

Exploration at the plan gate (2026-11-18) found the new networks add no donor at the four sites, so batch 7 (#142, #144) was split out; this move is batch 8 (#135, #147).

## Context


Move 5 batched four issues on the premise that the new station networks (#142 provincial, #144 BC
Water Tool) add carry donors at the four chinook sites, and that #147's `covariance_pick` (with
#135's cache) strengthens their carried route. Exploration disproved the first half:

- Counted from `data/checks/station_sources_20260717.txt` against each box in
  `scripts/departure_sites.csv`: Maxan, Swift and Gosnell gain **no** station with ≥ 3 complete
  chinook-window years; Naver gains 5 provincial stations (08JC0001/2/3/5/6) with 3–4 years, all
  2016–2020. A carry donor needs ≥ 10 baseline years in 1981–2010 (`dep_pool_of()`,
  `scripts/departure_site.R:676`) and the extension ≥ 30, so none can ever be a donor there.
- PCIC's routed flow does reach the Skeena boxes: #122's report scores 08EE and 08ED gauges, and
  Maxan (08EE018) under `covariance_pick` (0.89 against 0.74 by distance).
- The per-year files are public: `https://fresh-bc.s3.us-west-2.amazonaws.com/fwapg/extras/pcic.subbasin_days.PNWNAmet_historical.<year>.parquet` answers 200 anonymously.

## Decided at the gate (user, 2026-11-18)

1. **Batch 7 is split out.** This PR does batch 8 only (#135, #147). #142 and #144 return to the
   backlog as their own move: their value is province-wide (#118), not at these sites. Their gate
   questions (ungraded values, shared-site copy, credit lines) go with them.
2. **#147's rule ships covariance_pick where it wins**, #122's rule per site (below), registered in
   `scripts/departure_site.R`'s header and committed before any body code or run.
3. (Mine, mechanism) The new work is a section 6 appended to the site report, so sections 1–5 and
   every earlier seed stay as they are and the Maxan BULK run still reproduces #120's pilot
   (`site_parity_pilot()`); the snow script keeps its distance series for #121's parity and adds
   the covariance series only where it ships.

## Phase 0: scope

- [x] Edit #167's body: batch 7 moved out, with the box counts above; the move is #135 + #147.
- [x] File a new umbrella issue for batch 7 (#142, #144): #179, and add it to `planning/backlog.md` as its
      own move; move 5's entry names batch 8 only.
- [x] One line in #142's and #144's bodies: what the chinook sites gain (no donors; at most Naver's
      short-record test set), linked to the measurement.
- [x] `research/station_sources.md`: the per-box count, as [M].

## Phase 1: #135, cache PCIC's per-year files

- [x] Tests first, `tests/testthat/test-wet_pcic_years.R`, on the `wet_hydat()` pattern
      (`tests/testthat/test-wet_hydat.R`): the downloader stood in; a missing year is fetched and
      lands only when its size equals its `pcic.series` bytes; a cut-off download never lands and
      leaves no file under the year's name; a present file is not re-fetched; a cached file of the
      wrong size refuses; `WET_PCIC_YEARS` set → that directory, never written to, missing files
      refuse as now.
- [x] `R/wet_pcic_years.R` (internal): `wet_pcic_years_dir(series)` → `WET_PCIC_YEARS`, else
      `tools::R_user_dir("wet", "cache")/pcic_years/<model>_<scenario>/`;
      `wet_pcic_years(years, bytes, series, dir)` downloads missing years from the bucket (option
      `wet.pcic_years_url`) into a `.partial-` tempfile beside them and renames on size match, as
      `wet_hydat_fetch()` does; the download call in its own function so tests can stand it in.
- [x] Callers take the default: `routed_years_check()` (`scripts/pcic_routed_lib.R:230`, used by
      `scripts/gauge_monthly_compare.R`) and `scripts/departure_pcic.R:316`/`:456` read the
      `pcic.series` rows first, fill the cache, then run their per-file checks unchanged. Header
      text and `CLAUDE.md` lines naming `WET_PCIC_YEARS` say it defaults to the cache.
- [ ] Fill m1's cache (62 files, about 8.9 GB) and confirm each file passes `routed_years_check()`.

## Phase 2: register #147's rule (header only, its own commit, before any body code or run)

- [x] Rule registered in `scripts/departure_site.R`'s header ("new in #147"); amended from the plan: a floor of 10 gauges scored under each pool, so a box median rests on enough gauges; the 1981–2010 bins held to that run's climatology because the local database has no 1951–2012 `pcic.subbasin_daily`; seeds 147, 1471, 1472.

In `scripts/departure_site.R`'s header, a "New in #147" block:

- **Covered:** a gauge whose accepted snap (`wet_station_snap()`, as the script already does) lands
  on a segment with a `pcic.segment_weights` row (#58's definition); for an ungauged site, the
  mouth segment. Per-year files held to `pcic.series` by `routed_years_check()` on the 1951–2012 run.
- **Modelled years:** `wet_routed_years()` per covered gauge and target, 1951–2012, through
  `wet_window_stats()` on the site's windows and statistics, as #122 builds them.
- **Scored:** leave-one-gauge-out over the covered departure-pool gauges, `distance` and
  `covariance_pick` (`wet_departure_carry(weights =, modelled =)`, k = 5 of the 15 nearest) on the
  same covered pool and years; median per-gauge centred log NSE, every statistic and window, plus
  the leak-free sensitivity where the box has one.
- **Ships** at a site and window set if, on the migration-window mean, covariance_pick's median
  beats distance's by ≥ 0.01 under leave-one-out and leak-free, the target is covered and has ≥ 5
  covered donors; otherwise distance. One verdict per site and window set, applied to every
  statistic.
- **Where it ships**, section 6 also gives the target's carried route under covariance_pick:
  #126's before/after change with its interval (residual pool from covariance_pick's held-out
  residuals) and #152's 1951–1980 → 2016–2025 change with interval and coverage, under new seeds
  (`set.seed(147)`, `set.seed(1470)`) drawn after everything else.
- Sections 1–5 unchanged; deciding nothing earlier in the report.

## Phase 3: implement section 6

- [ ] Pure decision helper in `scripts/departure_site_lib.R` (`site_carry_ship()`), with a test in
      `tests/testthat/test-departure_site_parity.R`'s neighbour file: margin, leak-free absent,
      uncovered target, too few covered donors.
- [ ] Modelled window statistics helper shared from `scripts/pcic_routed_lib.R` (reading the cache
      through `wet_pcic_years_dir()`); `scripts/departure_site.R` section 6, its report lines, and
      `cov` in the rds (scores, verdict, covariance `mx` entries).
- [ ] `scripts/departure_site_snow.R`: where the site's verdict is covariance_pick, an added
      "carried (covariance_pick)" series; the distance series and #121's lines unchanged.
- [ ] `tests/testthat/test-departure_site_parity.R` passes on the tracked reports.

## Phase 4: rerun the sites

- [ ] Check first: the database (bare `PG*`) holds the 1951–2012 run's `pcic.subbasin_daily`,
      `pcic.segment_weights` and `pcic.series`; probe with `connect_timeout = 10`.
- [ ] `departure_site.R` for maxan, swift, naver, gosnell (BULK) and gosnell (MORR), then
      `departure_site_snow.R` for each, from frozen copies; logs under `data/logs/167/`.
- [ ] `git diff data/checks/departure_site*`: sections 1–5 identical bar the code-md5 lines;
      section 6 new. Maxan BULK still passes both parity gates. Record each site's coverage
      (answers "are the Morice and upper Fraser boxes covered") and verdict.

## Phase 5: article, bundles, docs

- [ ] `data-raw/chinook_sites_data.R`: the carried route from section 6 where the verdict is
      covariance_pick, the weighting and both scores per site held to report lines; rebuild.
- [ ] `vignettes/articles/flow-change-sparse-gauges.Rmd`: say how donors are weighted at each site
      and that PCIC's modelled years chose them where that won; update guards and numbers; word cap
      counted (raise rather than cut a required restatement).
- [ ] Rebuild `data-raw/short_record_vignette_data.R` (the Maxan report's md5 moves); assert every
      element but provenance `identical()` to the old bundle.
- [ ] `research/chinook_sites.md` and `CLAUDE.md` (the #126 paragraph: carry no longer fixed at
      inverse distance everywhere; `WET_PCIC_YEARS` default).
- [ ] Render the article; read guards and word count; offer the rendered page.

## Owed at the end (reported, done after merge)

- [ ] Batch 7's new move picks up #142 and #144 (filed in Phase 0, not owed work here).

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

Verification: the cache by its unit tests and a filled cache passing `routed_years_check()`; the
rule by its header commit preceding every body commit and run (git log); section 6 by the site
reports' diffs (sections 1–5 unchanged) and both parity gates; the article by its `stopifnot()`
guards, the bundle scripts' refusals, and a render.

