# /code-check round 1, branch 75-readme-correct-the-link-connection-list (#75)

Reviewed: `git diff main...HEAD` (HEAD 268ca1a, contains origin/main bfc4210), full current
README.md, DESCRIPTION, _pkgdown.yml, data-raw/readme_figure.R, man/wet-package.Rd,
.github/workflows/update-citation-cff.yaml, and man/figures/readme-pick.png.

## Findings

- **[claim]** README.md:22 — "Reading the published flow and station water temperature needs only
  `duckdb`." False for water temperature. `wet_temp_daily()` calls `wet_temp_offsets()`
  unconditionally before any read (R/wet_temp_daily.R:101), and that function stops with
  "install tidyhydat for station time zones" when tidyhydat is not installed
  (R/wet_temp_daily.R:165-168): it takes each station's UTC offset from
  `tidyhydat::allstations`. So reading station water temperature needs duckdb **and** the
  tidyhydat package (not the HYDAT database; `allstations` ships with tidyhydat). The published
  flow half is true: `wet_segment_monthly(NULL, ...)` needs only duckdb (plus Imports curl/jsonlite
  for the manifest) (R/wet_segment_monthly.R:207-224). Main's README did not say "only".
  Fix: e.g. "Reading the published flow needs only `duckdb`; station water temperature also
  needs `tidyhydat`, and station flow needs HYDAT (`tidyhydat::download_hydat()`) too." or drop
  "only".

Nothing else found. Mechanical checks all passed:

- Every NAMESPACE export (46) is in `_pkgdown.yml`'s index and nothing extra is listed;
  `pkgdown::check_pkgdown()` on a `git archive HEAD` copy: "No problems found".
  `build_reference_index()` there emits `id="water-temperature"`, so README's
  `reference/index.html#water-temperature` anchor will resolve once deployed.
- `data-raw/readme_figure.R`, run in a temp copy with only its declared inputs, reproduces
  `man/figures/readme-pick.png` byte-identically (md5 9d000f6c342f600a1fd027dde49a2688); it
  touches no bucket, fwapg or HYDAT, as its header says.
- `cffr::cff_create(authors_roles = c("aut", "cre", "cph"))` (cffr 1.4.2) runs against the
  branch DESCRIPTION and yields authors Irvine and `name: New Graph Environment Ltd.`.
- Every README link resolves HTTP 200 (21 URLs; github.io ones via the accepted 301).
  `NewGraphEnvironment/fwapg` is public and #6 is a PR merged 2026-10-08 into `newgraph`.
- The example's numbers equal `inst/vignette-data/monthly_values.rds` for segment 17057325
  (snapped from 08EE004 BULKLEY RIVER AT QUICK, group BULK), rounded: routed 118 / 32 / 23 /
  19 / 48 / 223 / 294 / 248 / 185 / 120 / 97 / 74 / 48, balance 118 / 45 / 50 / 48 / 86 / 220 /
  303 / ... .

## Claim enumeration

| # | Where | Claim | Verdict | Evidence |
|---|---|---|---|---|
| 1 | README tagline, DESCRIPTION Title, GitHub About | Stream flow and water temperature for BC's Freshwater Atlas | supported; the three agree | `gh repo view` About = tagline; DESCRIPTION Title |
| 2 | README opening | wet estimates how much water flows in almost every stream in BC | supported | segment_values.rds: of 4,907,441 FWA segments, 4,532,843 (92.4 %) have a pick; 374,598 neither. wet's own balance alone covers ~92 % |
| 3 | opening | as a long-term average for each month, from models | supported | routed 1951–2012, balance 1981–2010 normals; month 1–12 + 0 (`wet_segment_monthly`) |
| 4 | opening | publishes it openly | supported | manifest at fresh-bc/discharge/fwa/v1/ fetched anonymously (67 parts, segment_monthly + watershed_monthly) |
| 5 | opening | tracks flow and water temperature at hydrometric stations in the seasons that matter to fish | supported as a use | `wet_window_stats()` summarises over caller-given month-day windows; the fish (Chinook) windows are the vignettes' choice, not built in |
| 6 | opening | filling gaps in temperature records from air temperature | supported | `wet_temp_fill(temp, air, pool)`, air2stream + Kalman smoother |
| 7 | opening | Habitat models use the flow to rate where fish can spawn and rear | supported | link PR #344: `default_tuned` reads wet's annual pick, BT `spawn_mad_min` / `rear_mad_min`; fresh `mad` rules |
| 8 | opening | station records show how this year compares with normal | supported loosely | per-year window values to cd; flow vignette uses 1981–2010; temperature baseline is 2016–2025 by `wet_temp_daily` docs, and the caller picks the baseline |
| 9 | figure alt | larger rivers coloured by source of default flow | supported | `segment_map.rds` rivers, main flow, order 5–8, class = pick |
| 10 | figure alt | blue for routed PCIC across most of the province | supported | 76.4 % of drawn length routed, 23.3 % balance, 0.27 % none (not drawn) |
| 11 | figure alt | orange in the far north and the Nechako Reservoir | supported (approximate) | of orange length, 88.8 % north of 1,300 km northing, 5.8 % in the Nechako band; ~5 % scattered in the south (Skagit, Okanagan, Kootenay bits), visible as short orange ticks |
| 12 | caption | Where each larger river's default flow comes from | supported | pick on main-flow order ≥ 5; the 458 segments with neither (0.27 % of length) are not drawn |
| 13 | caption | Most take it from PCIC's routed model (blue) | supported | 4,010 of 5,313 drawn segments, 76 % of length |
| 14 | caption | the balance fills in where that model does not reach or reads far too low | supported | `wet_source_pick()`: balance where routed is NA, or routed < far_low (0.2) × balance on its own line |
| 15 | Installation | functions change between releases, see NEWS; pin `@vX.Y.Z` | supported | NEWS.md exists, tags `v0.4.x` exist, NEWS URL 200 |
| 16 | Installation | Reading the published flow needs only duckdb | supported | `wet_segment_parts()` needs duckdb (+httpfs it installs); manifest via Imports |
| 17 | Installation | Reading station water temperature needs only duckdb | **unsupported** | `wet_temp_offsets()` requires tidyhydat (Finding 1) |
| 18 | Installation | Station flow also needs HYDAT (`tidyhydat::download_hydat()`) | supported | `wet_station_daily()` reads HYDAT via `wet_hydat_daily()`, provisional via duckdb, real-time via tidyhydat |
| 19 | Installation | building the flow needs the FWA in PostgreSQL through fwapg | supported (necessary, not sufficient) | `wet_ws_fetch()` etc.; the routed table also needs NGE's fork (named in Data and methods) |
| 20 | Example | `wet_segment_monthly(NULL, 17057325, groups = "BULK")` is the Bulkley at Quick, both sources | supported | monthly_values.rds: 17057325 = 08EE004 BULKLEY RIVER AT QUICK, BULK; both sources present |
| 21 | Example | month 0 is the year | supported | month 0 = mean annual flow (`wet_segment_monthly` docs); 118 = mean of the 12 months for both |
| 22 | Example | printed table | supported | values equal the bundled rds, rounded |
| 23 | Learn more | Stream Discharge per Segment: what it is, which source, how to read, how well each matches gauges | supported | title matches; CLAUDE.md section on the vignette |
| 24 | Learn more | Monthly Flow per Segment: twelve months, hydrographs at three Bulkley gauges, scored across the province | supported | vignettes/monthly-flow.Rmd stations 08EE013/003/004; scored at calibration gauges |
| 25 | Learn more | Chinook Flow at Two Stations: recent flow in three Chinook windows at two Bulkley stations vs 1981–2010 normal | supported | station-flow.Rmd: open-water Chinook windows, last five years, `cd_baseline(…, 1981:2010)` |
| 26 | Learn more | Water temperature functions: daily, gap filling, GSDD | supported | `_pkgdown.yml` group: wet_temp_daily / _fill / _gsdd; anchor built |
| 27 | Ecosystem | fresh / link / cd / gq roles | supported | match link's README rows and each repo's About |
| 28 | Ecosystem | link's habitat models can read wet's published discharge | supported | link PR #344 merged 2026-10-16; `data-raw/discharge_wet_load.R` calls `wet::wet_db_load(conn, wet::wet_catalog(), months = 0, pick_only = TRUE)` |
| 29 | Ecosystem | cd computes the departures from wet's yearly station values | supported | `cd_baseline` / `cd_anomaly` / `cd_trend` on `wet_window_stats()` output |
| 30 | Data | Routed flow is PCIC's VIC-GL routed with Raven (hydromosaic) | supported | CLAUDE.md data sources; same link as segment-discharge.Rmd:118; URL 200 (CHYP portal) |
| 31 | Data | placed on the FWA by New Graph's fork of fwapg (PR #6) | supported | fwapg is a public fork of smnorris/fwapg; PR #6 merged into `newgraph` |
| 32 | Data | water balance follows Chapman et al. (2018) | supported | research/water_balance_method.md: open reimplementation of Chapman's method family; segment-discharge.Rmd:124 |
| 33 | Data | fitted to WSC gauges in HYDAT | supported | `wet_wb_fit()`, 315 calibration gauges |
| 34 | Data | Station data from HYDAT, ECCC real-time, and provisional records archived by water-temp-bc | supported | `wet_station_daily()` sources; `wet_temp_daily()` reads water-temp-bc Parameter 5 |
| 35 | Data | stream network from the BC FWA through fwapg | supported | `wet_ws_fetch()`, lut through fwapg |
| 36 | Citation | `citation("wet")` | supported | inst/CITATION exists and evaluates from DESCRIPTION |
| 37 | License | MIT, see LICENSE | supported | LICENSE + LICENSE.md present |
| 38 | DESCRIPTION | Mean monthly and annual flow for the FWA, published openly per segment | supported | as 3–4 |
| 39 | DESCRIPTION | from two sources: PCIC's routed hydrologic model and an open water balance fitted at HYDAT gauges | supported | `wet_segment_sources()`: exactly `pcic_routed`, `wet_balance` |
| 40 | DESCRIPTION | Daily flow and water temperature at stations summarised per year over month-day windows | supported | `wet_window_stats()` |
| 41 | DESCRIPTION | so each year can be compared with normal | supported loosely | as 8 |
| 42 | DESCRIPTION | Under active development | supported | lifecycle badge, convention wording |
| 43 | _pkgdown.yml group descriptions (8) | e.g. "Read the per-segment and per-watershed discharge wet publishes" | supported | manifest holds segment_monthly and watershed_monthly; group members' Rd titles match each description |
| 44 | readme_figure.R header | same bundled layers as the segment article's map; never touches bucket, fwapg or HYDAT | supported | reads only segment_map.rds, station_map.rds, wet_segment.csv; reproduced byte-identically offline |

/Users/airvine/Projects/repo/wet/planning/active/review-round1.md
