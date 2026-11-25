# Findings — Backlog move 18: Natural non-HYDAT stations as donors (#211)

## Issue context

### #211 (read 2026-11-25; one comment, the claim notice)

**If we do it:** departures at an ungauged or short-record site can borrow from the natural stations outside HYDAT, the province's non-integrated network and the BC Water Tool's gauges, where HYDAT's natural gauges are few or far. **If we never do:** those stations stay records and held-out tests, and every donor box draws on HYDAT alone.

Order: `planning/backlog.md`, move 18. Run `/planning-init <this issue>`: one phase, one PR.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 18, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

#### Batch 20: natural non-HYDAT stations as donors

**Why here:** move 14 gave every listed station a regulation status and, by the owner's decision at its gate, left donor selection HYDAT-only; this is the donor pool that decision deferred. A design-first move: the departure routes were each registered before they ran.

**Touches:** `R/wet_station_select.R`, `R/wet_window_extend.R`, `scripts/departure_site.R`, `scripts/departure_site_lib.R`, `tests/testthat/test-wet_station_select.R`, `research/chinook_sites.md`.

**Decided at the gate:** where the natural non-HYDAT stations enter a donor pool (the site script's box, `wet_window_extend()`'s `stations`, or a selector beside `wet_station_select()` that reads `wet_station_list()`'s `regulation`); what counts as a usable year for short and seasonal records; how provisional and unchecked days are weighed against HYDAT's approved ones; whether a registered rule comes before any shipped number.

| issue | title |
|---|---|
| #202 | Natural non-HYDAT stations as donors for departures |

### #202 (read 2026-11-25; no comments)

**If we do it:** departures at an ungauged or short-record site (#118) can borrow from the natural stations outside HYDAT, the province's non-integrated network and the BC Water Tool's gauges, where HYDAT's natural gauges are few or far. **If we never do:** those stations stay records and held-out tests, and every donor box draws on HYDAT alone.

Filed from backlog move 14 (#196), which gave every station `wet_station_list()` lists a regulation status (natural, regulated or unknown; `inst/extdata/station_sources/regulation_20261028.csv`, `scripts/station_regulation.R`) and, by the owner's decision at its plan gate, left donor selection HYDAT-only. Not in `planning/backlog.md`: the next `/backlog-sweep` places it.

#### To establish

- Where the natural non-HYDAT stations enter a donor pool: `scripts/departure_site.R`'s box (which queries HYDAT's flag directly), `wet_window_extend()` (which takes `stations` "as from `wet_station_select()`"), or a selector beside `wet_station_select()` that reads `wet_station_list()`'s `regulation`.
- What counts as a usable year for these records: most are short or seasonal, and `wet_station_select()`'s complete-year rule (all 12 months) would drop the seasonal ones a chinook window needs.
- How the donors' provisional and unchecked days are weighed against HYDAT's approved ones.
- Whether a registered rule is needed before they enter any shipped number (the departure routes were each registered before they ran).

## The code as it stands (tree at cbeb3489)

- `R/wet_station_select.R`: HYDAT SQL, `REGULATED = 0`, a complete year is 12 months each with `min_days` days; returns `station_number, station_name, prov, lon, lat, drainage_area_gross_km2, n_years`.
- `R/wet_station_list.R`: 257 rows, `regulation` from `regulation_<snapshot>.csv`; returns no drainage area. Its help says "A natural station can serve as a donor where a natural record is needed."
- `R/wet_window_extend.R`: `stations` is any data frame with `station_number, lon, lat, drainage_area_gross_km2`; a donor must hold a value in every year the target has; the target needs at least 3 years. `wet_station_space()` (shared with the carry) takes its SDs over every row given and refuses a missing or non-positive area.
- `R/wet_departure_carry.R`: each donor's departure is from its own mean over `baseline` (1981–2010), and a chosen donor with fewer than `min_baseline` (10) baseline years is an error.
- `scripts/departure_site.R` (lines 264–280 at this tree): the box pool is HYDAT SQL on `STN_REGULATION`, days from `wet_station_daily(sources = "hydat")`; its header fixes "HYDAT approved days only" as #120's. Pools: box (at least 3 complete migration years), extension (at least 30 and a 5-year run), departure (at least 10 baseline years), short-record (3 to 10).
- `scripts/station_regulation.R`: stated areas come from the Water Tool header or HYDAT's gross area at the station's HYDAT site; the snap's upstream area is fwapg's stored `fwa_watersheds_upstream_area` (`scripts/station_regulation_lib.R`). The shipped `regulation_20261028.csv` carries `linear_feature_id`, `snap_leg` and no area.
- Script-rule test pattern: `tests/testthat/test-departure_site_rule.R` sources `scripts/departure_site_lib.R` through `sys.source()` and skips where `scripts/` is absent.
- Rule-registration guard pattern: `scripts/station_regulation.R` lines 30–43 (`rule_commit`, md5 of the file at that commit against the working file). That script reads fwapg through `WET_PG*`; the site script reads libpq's bare `PG*`.
- The snap's codes and area: `rg_sql_snap` in `scripts/station_regulation_lib.R` joins a segment through `fwa_streams_watersheds_lut` to `fwa_watersheds_poly` (the polygon's `wscode_ltree`, `localcode_ltree`) and `fwa_watersheds_upstream_area`.
- `R/wet_window_stats.R`'s `frac_provisional` counts every status but `"approved"`, so it cannot separate unchecked from provisional days.

## Measurements (2026-11-25, HYDAT 20260717, station snapshots 20261028)

Produced by two throwaway probes run with the package loaded from this tree: `wet_station_list()`, `wet_station_daily(sources = c("bcenv", "bcwatertool"), to = NULL)`, and `wet_window_stats()` on the migration window 05-01 to 08-01 at the default `min_frac = 0.8`. Phase 2's report restates each from the script's own data, which becomes their tracked producer.

- Listed 257: provincial 52 natural, 101 regulated, 58 unknown; Water Tool 23 natural, 9 regulated, 14 unknown. Natural 75.
- The 75 natural stations: 74 return days (one has no complete day). First day of record: earliest 1998; 5 start before 2011, none before 1981.
- Days returned for them: 69,619. Provincial 29,359 provisional and 22,996 unchecked; Water Tool 14,778 provisional and 2,486 unchecked.
- Complete migration window-years per station: 0 at 16 stations, 1 at 15, 2 at 8, 3 at 12, 4 at 16, 5 at 3, 6 at 1, 8 at 3, 9 at 1. At least 3: 36. At least 5: 8. At least 10: 0.
- Baseline (1981–2010) migration window-years per station: 0 at 71, 1 at 2, 3 at 1, 4 at 1.
- The 185 window-years by decade: 1990s 1, 2000s 5, 2010s 89, 2020s 90.
- Complete calendar years (12 months of at least 20 days): none at 43 stations; the most is 7.
- Of the 185 window-years: every day provisional in 116, every day unchecked in 58, mixed in 11.
- All 75 natural stations carry a snapped segment in the regulation file: 37 placed by name alone (no stated area), 31 by name and area, 7 by area alone.
- In the site boxes (`scripts/departure_sites.csv`): Maxan and Gosnell 08EE0001 and 08EE0002, 2 window-years each; Swift none; Naver 08JC0001, 08JC0002, 08JC0005 and 08JC0006 with 3 each, 08JC0020 with 2, 08JC0018 with 1 (two more Naver-box stations are regulated). `research/station_sources.md` counts 4 at three of these under the survey's rules; the shipped reader's bound and 20-hour rule give 3.
- 16 natural stations sit at a HYDAT site. HYDAT flags the gauge there natural at 12 and regulated at 4 (08EE022, 08NM151 twice, 08NM180). Three of the natural HYDAT gauges have at least 10 baseline years by the proxy below: 08GA071 (active to 2024, so it gains nothing), 08JC017 (1997–2007; 08JC0002 holds 2016–2020) and 08NJ168 (1983–2015; 08NH0001 holds 2016–2026).

- Fit years (added after the Plan review): the window-years by year are 16 in 2024, 17 in 2025 and 14 in 2026; 22 stations hold one in 2025 or 2026, 14 in 2026. Natural BC HYDAT gauges holding at least 74 May–July days: 272 in 2024, 120 in 2025, none in 2026. `wet_window_extend()` needs a donor with a value in every year the target has, so a station's 2025 and 2026 years would leave it with no donor. Through 2024, 33 stations have at least 3 window-years and 5 have at least 5.
- Box parity (added after the review): 08KA012 sits at −119.2667, 52.83833 and 08KE014 at −122.5889, 53.42639; each rounded to 2 decimals and widened by 1.9° and 1.1° gives its row of `scripts/departure_sites.csv` exactly. The site reports' pool counts: Swift 30 box, 11 extension, 13 departure; Naver 58, 17, 24.

**Proxy for the size of a held-out test** (SQL on HYDAT's `DLY_FLOWS`: a year counts when May, June and July together hold at least 74 days of flow; distance is geographic, not the predictor space the rule uses): 1,522 natural BC gauges with coordinates and an area; 390 with at least 10 such years in 1981–2010; 274 of those with at least 3 since 2011. Of the 274, 44 have a natural station outside HYDAT with at least 3 window-years among their 5 nearest in the combined pool, and 39 share at least 3 years with it. The nearest such station is within 50 km of 62 of the 274 and within 100 km of 122.

## Why an estimated baseline is the only donor route open now

`wet_departure_carry()` needs each donor's own 1981–2010 mean. A station whose record starts after 2010 has none, so its years can depart only from an estimate of that mean. #120 already makes one for a short-record target: `wet_window_extend()` by OLS from the long-record gauges, then departures from the extended series' 1981–2010 mean. Applying that to a donor adds less than it first appears (the Plan review's point, which holds): an OLS fit's residuals sum to zero over its fit years, so the station's average departure over those years is its extension gauge's, scaled by the fitted slope. What the station adds is the year-to-year part around that line, one degree of freedom at 3 fit years and two at 4, from a place nearer the target. An extended value is back-transformed from logs, so it is a median, and a mean of medians runs low: the level error has a known direction, which the report's mean signed error shows.

A centred score would hide exactly that error, since it removes each series' mean over the scored years. So the rule scores the departure itself, uncentred, and reports the centred NSE beside it.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| The first draft of the rule gave `wet_window_extend()` a station's 2025 and 2026 years, which no HYDAT gauge covers, so every active station would have been ineligible | The rule's fit years stop at 2024; later years enter the carry as observed (Plan review, confirmed by count) |
| The first draft asserted that the two carries' HYDAT donors differ only by displacement, which the differing predictor SDs break | Reported as a count instead; the asserted invariant is that no held-out or related gauge reaches a chain or donor string |
