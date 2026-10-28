# Task: Second-region Chinook pilots: Swift Creek (UFRA) and Naver Creek (COTR) extended from short records, Gosnell Creek (MORR) with no gauge (#126)

**If we do it:** the Maxan method (#120) and the snow explanation (#121) are tested at three more Chinook streams, with the method fixed in advance, so a result at Maxan is either shown to hold elsewhere or found to be Bulkley-specific, and the method gets its first test at a stream with no gauge at all. **If we never do:** every claim about change in Chinook-window flow rests on one site in one snow regime, and on a stream that was at least gauged for five years.

## Context

The Maxan pilot (#120, extension and carried departures) and its snow regression (#121) rest on one stream in one snow regime. #126 runs the same method, fixed in advance, at three more Chinook streams: two short-record gauges whose records are extended (Swift, Naver), and one stream with no gauge at all, the case #118 is about. The result goes into one comparison article, unlisted until promoted. Everything is keyed on a site table, so a stream swaps in by editing data (memory `abstract-site-code`). Maxan stays on its own scripts in this issue. It gets a row in the table only so the generalised code can be checked against Maxan's tracked reports.

## Decided at the gate (user, 2026-10-28)

- **Morice target fixed in Phase 1: Gosnell Creek** (blue_line_key 360885021, 536.9 km²). It ties with Lamprey on 4 use records and alone has a spawning record (NuSEDS adult presence 2001); `data/checks/chinook_sites_use.txt`.

- **Swift target: 08KA012**, Swift Creek near the mouth. Every Chinook record on Swift Creek, several of them major spawning locations, lies within 6 km of the mouth, around this gauge. 08KA010 is upstream of all of them.
- **Morice target: Gosnell Creek or Lamprey Creek, whichever has more Chinook records and no gauge.** Owen Creek is dropped: the provincial fish observations record no Chinook there (coho, steelhead, pink and bull trout only). Neither Gosnell nor Lamprey has a HYDAT station. Provincial observations so far: Lamprey 4 (1984–2009, "fish observed", lower 1.5 km), Gosnell 3 (1979–1999, inventories). Phase 1 adds the NuSEDS counts and fixes the target.
- **Carried departures weighted by inverse distance, k = 5, as at Maxan.** This keeps the comparison like for like. #122's `covariance_pick` is not used here.
- **The method is fixed at Maxan's: the extension uses OLS, k = 5.** Each box's leave-gauge-out test still scores ols, move1 and ratio, and reports whether #120's rule would pick OLS there. That result decides nothing.
- From the issue: one comparison article in `vignettes/articles/`, under a pkgdown `internal` section. Maxan moves onto the site table later, not here.

## Phase 1: Targets and Chinook use
- [x] Count Chinook records per candidate stream: NuSEDS (open.canada.ca CSV, downloaded once into `data/chinook_sites/raw/` with its md5 reported) plus provincial observations (`bcfishobs.observations` joined to `fwa_stream_networks_sp` on the stream's blue_line_key). Candidates: Swift, Naver, Gosnell, Lamprey.
- [x] Fix the Morice target by record count. Ties go to the stream with a spawning-stage record, then to the larger area. Write the counts and the choice in `research/chinook_sites.md` (new topic file, with a provenance header) and add a row to `research/README.md`.
- [x] Check the issue's window counts for 08KA012 and 08KE014 under the pilot's definition (HYDAT 20260717, `wet_window_stats()` min_frac 0.8).
- [x] Edit the issue body and title: Gosnell replaces Owen, 08KA012 is the Swift target, and the decisions above are added.

## Phase 2: Site table and timing
- [x] `scripts/departure_sites.csv`, one row per site: `site_id`, `name`, `wsg_code`, `kind` (`extend` | `ungauged`), `target_station`, `blue_line_key` (mouth point for ungauged), `lon_min/lon_max/lat_min/lat_max`, `windows` (life-history wsg codes, `BULK` always first), `snow_gauges` (observed long-record gauges regressed beside the target; empty = the snow header's rule), `target_lon/target_lat` (ungauged mouth). `label_keys` dropped: the map labels the target stream by `blue_line_key`. Maxan's row carries its box verbatim. Every other box is the same size as Maxan's (3.8° × 2.2°) and centred on the target.
- [x] `scripts/departure_site_lib.R`: `site_get(id)` reads and validates a row, and refuses an unknown id, a missing field or a box without its target (prefix `site_`, since `scripts/departure_snow_lib.R` already uses `ds_`). `site_windows(site)` returns the site's window sets from the bundled life-history CSVs.
- [x] `data-raw/life_history_data.R` writes `inst/vignette-data/life_history_morr.csv` (MORR rows, same columns as `life_history_bulk.csv`) from knowledge's `data/life_history_timing.csv`. Read with `gh api` at knowledge c97c4d0, as `station_vignette_data.R`. The table is cited to Bustard and Schell (2002): Chinook migration 05-01..09-30, spawning 09-01..10-07. `life_history_bulk.csv` is not touched. UFRA and COTR have no cited windows yet, so they run under the Bulkley windows only, and the reports say so.

## Phase 3: Register the rules (headers only, committed alone, before any body code)
- [x] `scripts/departure_site.R <site_id>` header, which is #120's rule taken over per site:
  - The pools come from the site's box.
  - Extension uses OLS, k = 5. The three-candidate leave-gauge-out race is reported, with "what #120's rule would pick".
  - Carried departures are weighted by distance, k = 5. The method is usable if the box's departure-pool median NSE is ≥ 0.5.
  - The before/after, the bootstrap and `cd_*` are as #120.
  - At an `ungauged` site only carried departures run, applied to a normal taken from wet's published `segment_daily`: `wet_segment_daily(groups = wsg)` at the mouth segment, `pick` rows, then `wet_flow_window(basis = "daily")`.
  - The normal's error is reported beside it, as the log ratio of the published pick's window mean to the observed 1981–2010 window mean at the box gauges with ≥ 10 baseline years and an accepted snap. Calibration gauges are flagged, because the balance publishes observed shares there.
  - The result at the ungauged point itself is stated as untested.
  - A second window set runs where the site names one.
  - **Parity gate:** `maxan` must reproduce the tracked `data/checks/departure_pilot_20260717.txt` headline numbers (pool counts, section-2 medians, carried medians, Maxan's change table), or the script refuses.
- [x] `scripts/departure_site_snow.R <site_id>` header: #121 unchanged per site. The responses are the target's extended and carried series plus the site's `snow_gauges` observed. The watershed comes from the snap, or for an ungauged site from the FWA upstream of the mouth point. **Parity gate:** `maxan` must reproduce `data/checks/departure_snow_20260717.txt`'s fits.
- [x] Commit the two headers alone: "Register #126's rules before any body code".

## Phase 4: The pilot per site
- [ ] Implement `departure_site.R`, adapted from `scripts/departure_pilot.R`'s body with the site's values swapped in for the hard-coded Maxan ones. Reuse `wet_window_extend()`, `wet_departure_carry()`, `wet_station_snap()`, `wet_window_stats()`, `wet_segment_daily()` and `wet_flow_window()`. Outputs: `data/checks/departure_site_<site>_20260717.txt` (tracked, no timestamp) and `data/departure/departure_site_<site>_20260717.rds` (gitignored, `code_md5`).
- [ ] Run `maxan` until it passes the parity gate.
- [ ] Run swift, naver and the Morice site, each from a frozen copy. Rerun each and confirm the report is byte-identical. Commit the reports; run logs stay local under `data/logs/126/` (gitignored).

## Phase 5: Snow per site
- [ ] Implement `departure_site_snow.R` and pass the `maxan` parity gate. Run the three sites, rerun each for byte identity, and commit the reports.

## Phase 6: Comparison article (unlisted)
- [ ] `data-raw/chinook_sites_data.R` → `inst/vignette-data/chinook_sites_values.rds`. Guards as `short_record_vignette_data.R`: `vd_commit()`, each rds's `code_md5` matches its script, and every number is held to its line in the tracked report.
- [ ] `data-raw/chinook_sites_map.R` → `inst/vignette-data/chinook_sites_map.rds`, built with `scripts/vignette_map_lib.R`: the province with the four targets, their boxes and donors. Classes go in `inst/cartography/wet_station.csv`.
- [ ] `vignettes/articles/chinook-sites.Rmd`. It asks whether Maxan's result holds at the other three, side by side: the change in each window statistic, each route's held-out score per box, the snow fits, and the normal's error at the ungauged site. It follows #110's writing convention and ends with "Software and citation".
- [ ] `_pkgdown.yml` gets an `articles:` section listing the four existing articles plus `internal: chinook-sites`. Add `^vignettes/articles$` to `.Rbuildignore`. After `pkgdown::build_site()`, check that the page exists and that the navbar menu and the Articles index don't list it.
- [ ] Add tests in `test-vignette_data.R` for the new bundle and map: size limit, shape, provenance.

## Phase 7: Docs
- [ ] CLAUDE.md: Architecture lines for the site table and the two site scripts. Move the site-table convention from memory into Working Conventions, then delete the memory file and its MEMORY.md line.
- [ ] `research/chinook_sites.md`: the results at each site, with whether the Maxan result holds, attributed. Add a NEWS line.

## Owed at the end (reported, done after merge)
- [ ] File an issue: move Maxan's five files onto the site table and retire `departure_pilot.R` / `departure_snow.R` as separate code paths.
- [ ] File an issue: `covariance_pick` carried departures at the sites, where PCIC covers them.

## Validation
- [ ] Tests pass
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:
- The generalised scripts reproduce Maxan's tracked pilot and snow reports, and the parity gates refuse on a mismatch. To prove a gate fires, perturb one parity value in a copy and watch it refuse.
- Every site report is byte-identical on rerun.
- The article's numbers are held to report lines by `stopifnot()` in the chunks that state them.
- The article renders under pkgdown from the installed branch, and the navbar and index don't list it.

Noted for Phase 4: the issue says Naver's years since 1999 rest on Little Swift, Baker, the Quesnel at Likely and the West Road. Under #120's donor rule, a donor must have a value in every one of the target's observed years (1956–1975), so Little Swift (from 1972) and Baker (from 1964) cannot be donors. The run reports which gauges actually are, and the issue body is corrected to match.

