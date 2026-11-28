# Task: Backlog move 19: Small-stream logger records into wet (#235)

**If we do it:** small-stream water temperature records load in wet beside the federal gauges, so a prediction can be
compared with records from the kind of stream most reaches are. **If we never do:** every comparison comes from
year-round gauges, mostly on rivers.

Batch 21 carries one issue, #215 (small-stream logger temperature: Nechako, Upper Bulkley and Weigert Creek records as a
second scoring pool). One PR, for the Nechako records and the machinery every later series reuses. Scoring the baseline
on these records is out of scope (#215) and gets its own issue once they are in.

## Decided at the gate

No plan gate in this pane: the session was dispatched for the coordinator's plan gate, which reads this plan and
`review-plan.md`. The Plan review ran before the baseline and its corrections are folded in below; each phase says what
it changed. What follows is mechanism, decided in the plan. The two questions the backlog lists for this gate (reader
shape and first series) are answered here as recommendations and put to the owner as Decision 4, since answered (below).

- **One entry point, `wet_temp_daily()`** (Decision 4). Ids are split **by registry membership
  only**: an id in a logger registry goes to an internal reader, `wet_logger_daily()` (`R/wet_logger_daily.R`); every
  other id goes to the ECCC query unchanged, keeping its "no water temperature found" warning. Nothing new is refused
  by shape: the ECCC archive holds `08NHX18`, which is not HYDAT-shaped, and `scripts/temp_coverage.R` and
  `scripts/temp_fill_validate.R` pass every archive station (review B1). Why one entry point: `wet_temp_fill()`,
  `wet_temp_gsdd()`, `wet_window_stats()` and the baseline's scripts take one reader's shape, and
  `wet_station_daily()` already reads provincial, Tool and Hakai numbers from their own files.
  - `sources = c("provisional", <series>...)`: the ECCC days keep `source = "provisional"`, as now, and
    `wet_station_daily()` uses one word for both argument and column; a logger day's `source` is its series code.
  - The list of series comes from one constant, `wet_logger_versions <- c(nhg = "15053907")`, so a new series is its
    files plus one line.
  - A failing logger source is skipped with a warning, as `wet_daily_try()` does; the ECCC branch alone needs duckdb
    and tidyhydat, so those checks move inside it.
  - The mixed result is sorted by station and date with `method = "radix"`.
  - Logger days are computed in R, deterministically, not by duckdb's parallel `avg()` (#224).
  - The ECCC query and its days are untouched; move 20 (#236) rewrites that query in the same file and waits on this
    move.
- **Nechako first** (Decision 4): UNBC's Northern Hydrometeorology Group publishes it on Zenodo under
  CC BY 4.0 (reading and republishing with credit), Zenodo records are immutable with published checksums, and it is
  the only named series readable without an owner answer.
  - **Both records are pinned** (review G7, A1): 10.5281/zenodo.15053907 (2019–2024, `01_Data.zip`, 13.8 MB) and
    10.5281/zenodo.6426024 (2019–2021, `Data.zip`, 3.1 MB), under separate Zenodo concepts.
  - A site's days come from the later record where it holds that site, else from the earlier, so the sites #215 says
    the 2024 network model used are not lost. (As built: every earlier site is in the later record, so every day comes
    from the later record and no code reads days from the earlier one.)
  - The check report compares every site-day the two share.
- **Pinned like Hakai's package** (`R/wet_hakai.R`, #192):
  - `<version>` is the Zenodo record id. The tracked manifest `inst/extdata/temp_loggers/nhg_<version>.csv` holds
    `file, bytes, md5, url, fetch`, with the URL checked to contain `/records/<version>/` and the md5 taken from
    Zenodo's `checksum`.
  - Files are cached under `tools::R_user_dir("wet", "cache")/temp_loggers/<series>/<version>/`; zip members are
    extracted to a temporary directory per call, and the members read are listed by name and md5 in the manifest
    (rows with `file` as `<zip>/<member>`).
  - Private backup at `s3://fresh-bc/temp_loggers/<series>/<version>/` (`WET_BACKUP=1`).
  - **`fetch` column (review B2):** `TRUE` lets `wet_logger()` fetch a missing file from its pinned URL, keeping it only
    at the manifest's md5 (Zenodo). `FALSE` stops through `wet_snapshot_unavailable()` naming the backup, as the
    provincial and Tool snapshots do, so no session ever requests from a host whose robots.txt refuses it.
  - Zenodo's robots.txt is read before the first fetch and recorded in the research file.
- **Days as ECCC days are made:** the `valid` range first, local standard time, hourly means, `min_hours` (default 20),
  `t_mean_c` the mean of hourly means, `t_min_c` and `t_max_c` over readings. As built (Phase 2): the
  registry's `clock_offset` says how far the timestamps run ahead of UTC (0 for both Nechako records, which are UTC)
  and `day_offset` the local standard time of the days (the nearest HYDAT station's, −8). The planned `utc_offset`,
  `dst` and `tz` columns were not built: no series read keeps daylight saving (review G9; findings, "Plan corrections").
- **Logger QA, in this order** (review G3): the `valid` range; stuck runs, on hourly means; the hour rule;
  deployment-end days; air days, on days. The stuck, deployment and air rules apply to logger series only; the `valid`
  range and the hour rule are the archive's.
  - **Deployment:** a run of readings with no gap longer than 6 hours. Its first and last calendar days are dropped.
  - **Stuck run:** identical hourly means for more than the stuck threshold in hours. Only open-water months count
    (May–September) and only values above 0.5 °C, so a run near 0 °C under ice is kept (ECCC holds a sensor stuck at
    4.0 °C for two years, 08LG048, so the threshold cannot be the archive's maximum).
  - **Air day:** a day whose diurnal range of hourly means exceeds the month's air threshold.
  - The thresholds are measured by `scripts/temp_logger_thresholds.R` → `data/checks/temp_logger_thresholds.txt` on
    the ECCC archive's open-water days (May–September, diurnal range ≥ 1 °C, as `scripts/temp_day_boundary.R`), under
    the percentiles and station subset Decision 5 sets. They are then hard-coded as constants in
    `R/wet_logger_daily.R`, a test holds the constants to the report, and they are registered in
    `research/station_water_temperature.md` in a commit of their own before any logger day is screened.
  - Where a series ships QA flags of its own, they are read and reported beside ours, not used in their place.
  - Each dropped day is counted by reason.
- **Placement** (review G4, G5) sources `scripts/station_sources_lib.R` (`stream_of()`), `scripts/station_regulation_lib.R`
  (`rg_sql_snap`) and `scripts/station_regulation_rule.R` (`rg_snap_pick()`), as `scripts/station_regulation.R` does.
  - Search: `fwa_indexpoint()` with `rg_snap_tolerance_m` (1000 m) and `rg_snap_candidates` (5).
  - Legs: the candidate on the stream the site's name gives, leg `"name"`. With no name, or no candidate on it (loggers
    carry no drainage area, so `rg_snap_pick()`'s area leg never applies), the nearest candidate within 100 m, leg
    `"nearest"`. Otherwise the site stays unplaced, with the reason.
  - Output: `blue_line_key`, `downstream_route_measure`, `linear_feature_id`, and the main-flow tree segment
    (`whse_basemapping.fwa_stream_networks_mainflow_tree`).
  - The script refuses to run without the tree table and records the table's row count. A snapped segment off the tree
    takes the nearest tree segment on the same `blue_line_key` by measure; with none, it is `"off tree"`.
  - The placement is written once to `inst/extdata/temp_loggers/nhg_<version>_placement.csv` with a `registry_md5`
    column (the precedent is `regulation_<snapshot>.csv`), and the check report reads that file, never the database.
- **Pools** (review G2): the fill pools by the caller's `pool`, which callers build as `substr(station_number, 1, 3)`,
  so an id like `NHG_…` would be cut off from its ECCC peers. The registry therefore carries `subdrainage`,
  `nearest_eccc` and its distance (built as `eccc_km`), as the Tool registry does. The `pool` roxygen in `R/wet_temp_fill.R` and CLAUDE.md's
  fill paragraph say a logger is pooled through `subdrainage`. The report lists logger sites within 0.5 km of an ECCC
  temperature station, so no site enters a pool twice.
- **Counts** (review G1): a complete growing season is a site-year with a `wet_temp_gsdd()` value. That needs 274 of
  the 275 days from 1 March to 30 November observed in one run, so for seasonal loggers the count was expected near
  zero; as built the Nechako series holds 30 at 22 sites, and the report counts them. A season "needing only its shoulders" has every missing window day in 1 March–15 May or
  1 October–30 November and none from 16 May to 30 September, the shape the fill's validation scored
  (`research/station_temperature_fill.md`). The report also gives each site's observed days against
  `wet_temp_fill(min_days = 365)`, since a site with one season cannot be filled at the defaults.
- **Report:** `scripts/temp_loggers.R` → `data/checks/temp_loggers_nhg_<version>.txt`, byte-identical on a rerun from
  cache. That holds because the thresholds are constants, placement is read from its tracked file, and day means are
  computed in R (review AC2). `data-raw/temp_loggers_nhg.R` writes the manifests and the registry
  `inst/extdata/temp_loggers/nhg_<version>_sites.csv`, and refuses any id shaped like a HYDAT number or present in
  the ECCC archive.
- **Other series go to issues of their own** (review S1): Upper Bulkley, under either answer to Decision 1, and
  Weigert Creek or Morice if one turns out readable. Each is filed naming move 19, so this PR stays one reviewable
  piece. The PR says "Closes #215" only if every series that may be read has loaded (Decision 1 answered (b) and
  nothing else readable); otherwise "Relates to #215".
- **A series held by someone else** is inventoried from what is public only; no request goes to its holder from this
  move (any ask goes through the owner).

## Decided by the owner (2026-11-27, at the resume)

1. **Skeena Salmon Data Catalogue:** (a) the owner fetches once by hand with a script written in the Upper Bulkley
   issue (user agent `wet`, each request logged); agent sessions process only the cached copy, pinned with
   `fetch = FALSE` and backed up. No agent sends a request to the catalogue.
2. **Logger site id:** (a) `<SERIES>_<holder's site code>`, upper case, e.g. `NHG_<code>`.
3. **Held series in the research file:** (a) one neutral row, "Skeena logger networks: not published; not read",
   naming them as #215 does.
4. **Reader shape and first series:** one entry point through `wet_temp_daily()`, routed by registry membership;
   Nechako first, both Zenodo records pinned.
5. **QA thresholds:** (a) air days at the 99.9th percentile, by month, of the diurnal range of hourly means on
   open-water days at ECCC stations under 1,000 km² gross drainage area (all stations where a month holds fewer than
   1,000 station-days); stuck runs at the 99.9th percentile of the longest open-water run of identical hourly means
   per station-year above 0.5 °C. `scripts/temp_logger_thresholds.R` reports option (b) beside it.
   **Amendment 1** (the owner, 2026-11-27, after the first measurement, before any screening): the raw archive's
   tails were its own faulty sensors (stuck 687 h from 08LG048 and 07FA004; August air 24.97 °C), so the reference is
   screened first: station-years with a run of identical hourly means of 168 h or more, and days with a range above
   20 °C, are left out, then (a)'s percentiles taken. Shipped: air 12.09, 13.86, 16.83, 16.59, 18.38 °C (May–Sep),
   stuck 154 h.

## Phase 1: Inventory from what is public

Review: Morice, the dashboard and the follow-up rule for Weigert added (G10).

- [x] Before building: `bash "$T/skills/_shared/members_check.sh" <origin> 235 235-backlog-move-19-small-stream-logger-reco --batch 21` (T from `soul_published_tree`); on a non-zero exit or any line but `FREE`, build nothing, write the line under an `## Open decisions` heading and stop
- [x] Zenodo's robots.txt read and recorded before the first file fetch
- [x] Nechako: read both records' ReadMe files and data archives. For each record: holder, licence, sites, years, time step, time zone and daylight saving, units, QA flags shipped, which file carries coordinates and site names (`02_SupplementaryMaterials.zip` or the earlier record's PNG), and file formats (if .xlsx, readxl goes to Suggests). Also which sites and days the two records share
- [x] Weigert Creek (Elk River): its holder and whether it is published, from public sources only; licence, sites, years
- [x] The Skeena Knowledge Trust's Upper Bulkley dashboard (public.tableau.com): read its robots.txt first, then inventory only what it serves (sites, years, whether data can be pulled), or record why not
- [x] Upper Bulkley and Morice: rows from what planning read, and nothing more from the catalogue
- [x] The inventory table drafted in `planning/active/findings.md` (it moves to the research file in Phase 5)

## Phase 2: Nechako pinned, and its registry

Review: both records pinned, `fetch` column, version validation, zip members, pool columns (B2, G6, G7, G2); waits on
Decisions 2 and 4 (O3).

- [x] `data-raw/temp_loggers_nhg.R`:
  - fetch both records' pinned files at Zenodo's checksums into the cache;
  - write the manifests `inst/extdata/temp_loggers/nhg_15053907.csv` and `nhg_6426024.csv`, with zip members listed;
  - write the registry `nhg_15053907_sites.csv`: id, holder's code, record, member, name, lon, lat, elevation,
    `clock_offset`, `day_offset`, `subdrainage`, `nearest_hydat`, `nearest_eccc`, `eccc_km`, first and last reading,
    licence, credit, and the earlier record's code and member;
  - refuse HYDAT-shaped ids and ids in the ECCC archive;
  - back up both records with `WET_BACKUP=1`.
- [x] Internal `wet_logger(series, version)` gives cache paths checked against the manifest; it fetches a missing file only where `fetch` is `TRUE`, and otherwise calls `wet_snapshot_unavailable()`. Add `wet_logger_versions`
- [x] `tests/testthat/helper-temp-loggers.R` and `tests/testthat/test-wet_logger_daily.R` (pin part), with the network made to fail as `test-wet_bcenv.R` does: manifest refusals, a URL without `/records/<version>/`, md5 mismatch, a missing file with `fetch = FALSE`, the registry's shape

## Phase 3: The reader and the logger QA

Review: rules ordered and made concrete, thresholds measured by a named script, registered in a commit of their own,
routing by registry, tests named (B1, G3, G8, O1, O4, AC3); screening waits on Decision 5.

- [x] `scripts/temp_logger_thresholds.R` → `data/checks/temp_logger_thresholds.txt`: both options of Decision 5, measured on the ECCC archive
- [x] Register the rules and the chosen thresholds in `research/station_water_temperature.md` (a new section that stands alone, since move 20 edits the same file), in a commit of their own, before any logger day is screened
- [x] `wet_logger_daily()`: readings to days by the rules above, QA in the stated order; returns the `wet_temp_daily()` shape with `source` the series code, and `status` from the series' approval where it states one, else `"provisional"`; constants for the thresholds
- [x] `wet_temp_daily()`: registry routing, `sources`, duckdb and tidyhydat checks inside the ECCC branch, radix sort; roxygen documents the registry path (`system.file("extdata", "temp_loggers", ...)`) and logger days; `@examples` updated; `devtools::document()`
- [x] Tests:
  - `test-wet_temp_daily.R` passes unchanged, including the `08ZZ999` warning;
  - an id outside the registry that is not HYDAT-shaped still goes to the ECCC query;
  - a logger-only call works with duckdb mocked absent;
  - a bad `sources` value is refused;
  - each QA rule fires on a fixture built to trip it and stays quiet on one that does not (restore the defect and watch it go red), with an ice run at 0 °C kept;
  - the threshold constants equal the report's numbers;
  - zero-row results keep the shape;
  - `wet_temp_gsdd()` and `wet_temp_fill()` accept a logger series pooled by `subdrainage`.
- [x] `R/wet_temp_fill.R`'s `pool` roxygen: logger ids are pooled through the registry's `subdrainage`

## Phase 4: Each site on the network

Review: the name leg's real home, distances, the unnamed-site rule, a separate placement file, the tree required
(G4, G5, O2).

- [x] Placement section of `scripts/temp_loggers.R`, run once to write `inst/extdata/temp_loggers/nhg_15053907_placement.csv` (`registry_md5`, leg, distance, `blue_line_key`, `downstream_route_measure`, `linear_feature_id`, tree segment, reason); refuses without `whse_basemapping.fwa_stream_networks_mainflow_tree` and records its row count; unplaced sites with reasons

## Phase 5: Check report, counts and the research file

Review: counts redefined, overlap with ECCC sites, reproducibility conditions, rows for every series (G1, G11, AC1, AC2).

- [x] `scripts/temp_loggers.R` → `data/checks/temp_loggers_nhg_15053907.txt`:
  - the manifests' md5s, and sites and days read;
  - days dropped by reason, and the series' own flags beside ours;
  - the two records compared on shared site-days;
  - placement, from the tracked file, and sites within 0.5 km of an ECCC station;
  - per site: complete growing seasons, seasons needing only their shoulders, observed days against `min_days = 365`.
  It must be byte-identical on a second run from cache (`cmp`)
- [x] `research/station_water_temperature.md`: one row per series, with holder, licence, sites, years, time step, counts, and read or not and why. Rows for Nechako, Upper Bulkley, Morice, Weigert Creek and the dashboard; the held series as Decision 3 says. Update the header's Verified line and issues
- [x] `CLAUDE.md`: the logger reader, its registry, placement and pool in the water temperature paragraphs; `NEWS.md` bullet under the development heading
- [x] File the follow-up issue: the baseline (#213) scored on the logger pool, naming move 19 (#253)

## Phase 6: Further series as issues of their own

Review: Upper Bulkley split out under both options (S1, O5).

- [x] Upper Bulkley: its own issue naming move 19 (#251), with the inventory row and Decision 1's answer (under (a), the hand-fetch script and `fetch = FALSE` pin are its work)
- [x] Weigert Creek and Morice: an issue each, naming move 19, where Phase 1 found it readable; otherwise their rows say why not (Morice #252; Weigert: no published record, its row says so)

## Validation

- [x] Tests pass (`devtools::test()`, with `NOT_CRAN=true` on any single-file rerun)
- [x] `lintr::lint_package()` adds no lint (per file, linter and line, against a worktree of `origin/main`); `pkgdown::check_pkgdown()` clean
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

Verification:
- **QA guards:** each defect restored in a fixture, and the guard goes red.
- **Reader:** the ECCC path's tests pass unchanged, plus the logger fixtures.
- **Pin:** an md5 mismatch is refused, and a `fetch = FALSE` file is never requested.
- **Report:** a second run from cache compared byte for byte.
- **Research file:** every count it quotes is read from the tracked report.
