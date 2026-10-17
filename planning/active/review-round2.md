# /code-check round 2, branch 75-readme-correct-the-link-connection-list (#75)

Reviewed at HEAD 1dba349: `git diff main...HEAD` and the full current README.md, DESCRIPTION,
_pkgdown.yml, data-raw/readme_figure.R, man/wet-package.Rd and
.github/workflows/update-citation-cff.yaml. Re-verified independently; round 1's table was not
relied on.

## Clean

No issues found.

## The round-1 fix (README.md, Installation, the requirements sentence)

> Reading the published flow needs only `duckdb`. Station water temperature also needs
> `tidyhydat`, station flow a HYDAT database (`tidyhydat::download_hydat()`), and building the
> flow the Freshwater Atlas in PostgreSQL through fwapg.

True for each path it names:

| Path | What the code needs | Verdict |
|---|---|---|
| Published flow (`wet_segment_monthly(NULL, ...)`) | `wet_segment_parts()` requires duckdb (R/wet_segment_monthly.R:207), installs httpfs itself; the manifest via `wet_catalog()` uses Imports (curl, jsonlite). No tidyhydat, HYDAT or Postgres. The duckdb check in R/wet_catalog.R:166 is in `wet_manifest_write()` (build side). | supported ("only duckdb") |
| Station water temperature (`wet_temp_daily()`) | duckdb (R/wet_temp_daily.R:98) and, unconditionally, tidyhydat for `tidyhydat::allstations` UTC offsets (`wet_temp_offsets()`, :166-169). No HYDAT database. | supported ("also needs tidyhydat", i.e. duckdb + tidyhydat) |
| Station flow (`wet_station_daily/monthly/select`) | HYDAT sqlite via `wet_hydat_connect()` -> RSQLite (Suggests, unchecked), default path `wet_hydat_path()` -> tidyhydat; provisional source -> duckdb; real-time -> tidyhydat. RSQLite comes with tidyhydat (tidyhydat Imports RSQLite >= 2.0, checked on the installed copy), and naming `tidyhydat::download_hydat()` implies tidyhydat. With "also", duckdb + tidyhydat + a HYDAT database covers every package these reach. | supported |
| Building the flow | `wet_ws_fetch()`, `wet_upstream_pairs()` etc. need fwapg in Postgres (RPostgres). Necessary, not claimed sufficient (climr, terra, ncdf4 and the fwapg fork for the routed table are not listed). | supported, as a detail cut |

Not stated and not claimed: gap filling needs air temperature from `cd::cd_extract_daily()` and
`wet_temp_gsdd()` needs gsdd. The sentence says "station water temperature also needs
tidyhydat", which is true; it does not say "only". Treated as a deliberate detail cut.

## Claim enumeration

| # | Where | Claim | Verdict | Code path / measurement |
|---|---|---|---|---|
| 1 | README tagline, DESCRIPTION Title, GitHub About | Stream flow and water temperature for BC's Freshwater Atlas | supported; all three agree | `gh repo view` description equals the tagline |
| 2 | opening | wet estimates how much water flows in almost every stream in BC | supported | segment_values.rds: (3,152,838 routed + 1,380,005 balance) / 4,907,441 FWA segments = 92.4 % with a pick; wet's own balance needs the lut, so it reaches at most 92.5 % (369,217 no_lut) |
| 3 | opening | as a long-term average for each month, from models | supported | months 1-12 and 0 (`wet_timebase()`), routed 1951-2012, balance 1981-2010 normals |
| 4 | opening | publishes it openly | supported | `wet_catalog()` reads the public manifest; parts read anonymously in `wet_segment_parts()` |
| 5 | opening | tracks flow and water temperature at stations in the seasons that matter to fish | supported as a use | `wet_window_stats()` over caller-given month-day windows; Chinook windows in the vignette |
| 6 | opening | filling gaps in temperature records from air temperature | supported | `wet_temp_fill(temp, air, pool)` |
| 7 | opening | habitat models use the flow to rate where fish can spawn and rear | supported | link PR #344 merged 2026-10-16 ("re-set BT's MAD minima"), its data-raw/discharge_wet_load.R:63 calls `wet::wet_db_load(conn, wet::wet_catalog(), months = 0, pick_only = TRUE)` |
| 8 | opening | station records show how this year compares with normal | supported; does not claim wet computes it | wet gives per-year values; departures are cd's (row 30) |
| 9 | figure alt | larger rivers coloured by source of default flow | supported | readme_figure.R draws segment_map.rds rivers with class != "none", by class |
| 10 | figure alt | blue for routed PCIC across most of the province | supported | 76.6 % of drawn length routed, 23.4 % balance (4,010 vs 1,303 segments), measured |
| 11 | figure alt | orange in the far north and the Nechako Reservoir | supported (accepted approximation) | per brief; not re-measured |
| 12 | caption | Where each larger river's default flow comes from | supported | pick on main-flow rivers of order 5+ (`order_width` 5-8) |
| 13 | caption | Most take it from PCIC's routed model (blue) | supported | as 10 |
| 14 | caption | the balance fills in where routed does not reach or reads far too low | supported | `wet_source_pick()` R/wet_source_pick.R:30-33: balance where routed is NA, or routed < far_low x balance on its own line |
| 15 | Installation | functions change between releases; see NEWS; pin `@vX.Y.Z` | supported | NEWS.md, v0.4.x tags |
| 16 | Installation | reading the published flow needs only duckdb | supported | table above |
| 17 | Installation | station water temperature also needs tidyhydat | supported | table above |
| 18 | Installation | station flow needs a HYDAT database (`tidyhydat::download_hydat()`) | supported | table above |
| 19 | Installation | building the flow needs the FWA in PostgreSQL through fwapg | supported (necessary) | table above |
| 20 | Example | Bulkley River at Quick, both sources, month 0 is the year | supported | `wet_segment_monthly(conn = NULL, segments, groups)` signature matches; month 0 = mean annual flow per its docs; 17057325 / 08EE004 per round 1, output accepted as pasted |
| 21 | Learn more | Stream Discharge per Segment: what, which source, how to read, how each matches gauges | supported | vignette title matches; contents per CLAUDE.md |
| 22 | Learn more | Monthly Flow per Segment: hydrographs at three Bulkley gauges, scored across the province | supported | title matches; 08EE013/003/004 |
| 23 | Learn more | Chinook Flow at Two Stations: three Chinook windows, two Bulkley stations, vs 1981-2010 | supported | title matches |
| 24 | Learn more | Water temperature functions: daily, gap filling, GSDD | supported | `_pkgdown.yml` Water temperature group = wet_temp_daily/_fill/_gsdd |
| 25 | Ecosystem | wet row: this package | supported | as 1 |
| 26 | Ecosystem | fresh, link, gq roles | supported | each repo's own description (not re-fetched; unchanged org wording) |
| 27 | Ecosystem | cd: climate departure, baselines, anomalies, trends, ERA5-Land | supported | CLAUDE.md; `wet_snow_normals()` uses cd's ERA5-Land layers |
| 28 | Ecosystem | link's habitat models can read wet's published discharge | supported | as 7 |
| 29 | Ecosystem | cd computes the departures from wet's yearly station values | supported | `wet_window_stats()` emits cd's long format; vignette calls `cd_baseline()`/`cd_anomaly()` |
| 30 | Data | routed flow is PCIC's VIC-GL routed with Raven (hydromosaic), placed on the FWA by NGE's fwapg fork (PR #6) | supported | `wet_segment_sources()` origin text names the fork; fwapg#6 merged |
| 31 | Data | water balance follows Chapman et al. (2018), fitted to WSC gauges in HYDAT | supported | `wet_aet_landcover()`/`wet_chapman_table3()` cite Chapman 2018; `wet_wb_fit()` at HYDAT gauges |
| 32 | Data | station data from HYDAT, ECCC real-time, and provisional records archived by water-temp-bc | supported | `wet_station_daily()` three sources; `wet_temp_daily()` reads water-temp-bc Parameter=5 |
| 33 | Data | stream network from the BC FWA through fwapg | supported | `wet_ws_fetch()` |
| 34 | Citation / License | `citation("wet")`; MIT, see LICENSE | supported | inst/CITATION, LICENSE |
| 35 | DESCRIPTION | mean monthly and annual flow for the FWA, published openly per segment | supported | as 3-4 |
| 36 | DESCRIPTION | from two sources: PCIC's routed model and an open balance fitted at HYDAT gauges | supported | `wet_segment_sources()`: exactly pcic_routed, wet_balance |
| 37 | DESCRIPTION | daily flow and water temperature at stations summarised per year over month-day windows | supported | `wet_window_stats()` |
| 38 | DESCRIPTION | so each year can be compared with normal | supported; the comparison is left to the reader/cd | as 8 |
| 39 | DESCRIPTION | under active development | supported | lifecycle badge |
| 40 | _pkgdown Published discharge | read the per-segment and per-watershed discharge wet publishes | supported | wet_catalog / wet_db_load / wet_segment_monthly; manifest holds segment and watershed datasets |
| 41 | _pkgdown Station flow | daily and monthly flow at stations, and the gauges the balance is fitted at | supported | Rd titles of wet_station_daily/monthly/select/snap |
| 42 | _pkgdown Water temperature | daily temperature, gap filling, GSDD | supported | Rd titles |
| 43 | _pkgdown Date windows | mean flow, or per-year statistics of flow or temperature, over month-day windows | supported | wet_flow_window, wet_window_stats, wet_windows_calendar titles |
| 44 | _pkgdown PCIC gridded runoff | fetch VIC-GL variables and summarise per year | supported | wet_pcic_* and wet_runoff_annual titles |
| 45 | _pkgdown Watersheds and upstream | sample a grid to fundamental watersheds and average over upstream area | supported (group also holds the unit helpers wet_mm_to_m3s, wet_month_days) | Rd titles |
| 46 | _pkgdown Water balance inputs | precipitation, ET, terrain, land cover and snow on a common grid | supported loosely (wet_chapman_table3 is a table, wet_aet_budyko a formula); not material for a group heading | Rd titles |
| 47 | _pkgdown Water balance fit and validation | fit at HYDAT gauges, split into months, score held out | supported | wet_wb_fit, wet_share_fit/predict, wet_cv_folds, wet_flow_validate titles |
| 48 | readme_figure.R header | same bundled layers as the article map; never touches bucket, fwapg or HYDAT | supported | reads only segment_map.rds, station_map.rds, wet_segment.csv |
