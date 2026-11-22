# Task: Backlog move 8: Stations beyond HYDAT (#179)

**If we do it:** `wet_station_daily()` reads the province's non-integrated hydrometric stations and the BC Water Tool's third-party gauges, so departures at ungauged sites anywhere in BC (#118) gain donors and held-out tests beyond Water Survey of Canada's network. **If we never do:** donors stay federal only, and basins only the province or a third party gauges keep no local record in wet.

Members: #142 (the province's non-integrated hydrometric discharge) and #144 (the third-party gauge records the BC Water Tool serves). Both feed `wet_station_daily()`, share the QA and regulation questions, and meet at six sites (the Tool's 4 Tofino and 2 BCCF stations sit at provincial sites 08HC0001–0004, 08HB0011, 08HB0008).

## Decided at the gate

No plan gate in this pane: dispatched as `park review` by the coordinator (soul#928), 2026-11-22. The phases below are a draft, revised by a Plan review (`planning/active/review-plan.md`, 2 blockers, both probed and confirmed). Every fork the owner must make is under **Open decisions** with a recommendation, for the coordinator to put to the owner. The phases are written for the recommended answers; where another answer changes a phase, the decision says how.

What the exploration found (2026-11-22, tree at eaa12d9):

- `R/wet_station_daily.R` chains three sources per station (`hydat` → `provisional` → `realtime`), each continuing the one before from its last day (`wet_daily_after()`, lines 98–103: a later source's days before the earlier one's last day are dropped), returning `data.frame(station_number, date, q_m3s, symbol, source, status)`; `R/wet_temp_daily.R` mirrors that shape. `provisional` and `realtime` run for every station asked for (lines 68–86). Callers: `scripts/station_departure.R`, `scripts/wb_shape_daily.R`, `scripts/departure_pcic.R`, `scripts/departure_site.R`, `data-raw/station_vignette_data.R` (all HYDAT ids).
- `scripts/station_sources_probe.R` (#123's survey) already reads both sources from snapshots under the gitignored `data/station_sources/raw/` (747 MB, fetched 2026-10-28): the provincial files through duckdb (CRLF, byte 0x96, `l/s` units, `NaN`, hour → day at ≥ 20 hours on the UTC date, `Unusable` hours left out, newest file wins an hour in two files) and the Tool's per-station CSVs. The readers are lifted from there. The probe itself stays as it is, #123's record.
- IDs: HYDAT `08NM002` (7 characters); provincial `08NM0002` or `H08KC0626`. The Tool's `nid`s are mixed: plain numbers (`4601`, `61001`), `HRB3142`, `ALU-water`, `ogc_1002`, `UC 5` (with a space), `L-307`, `manson`, and provincial-shaped ids that are *not* in the provincial files (BCER's `07FA0003`, `07FC0003`). Each Tool CSV is named by the API's numeric id, not by `nid` (Sharp Creek, `nid` 2601, is `13915.csv`). So a station's source cannot be read from its id's shape.
- The provincial files' time column is `Date/Time(UTC)`; HYDAT and ECCC days are local standard time, and `wet_temp_daily()` refuses UTC days.
- `wet_window_stats()` (line 168) and `wet_temp_gsdd()` count only `status == "provisional"` into `frac_provisional`.
- Regulation: `wet_station_select()` leaves out stations with no HYDAT regulation record (unknown is not natural), and `scripts/departure_site.R` takes `REGULATED = 0` only. Every non-HYDAT station is "unknown" except the 10 provincial and 15 Tool listings whose names read as regulated.
- Precedent for a large external input: `wet_hydat()` and `wet_pcic_years()` cache per machine under `tools::R_user_dir("wet", "cache")`, keyed by a pinned release, landing files by partial file and rename, with a private S3 backup of each pinned HYDAT release.
- At the six shared sites the two copies hold different years: the Tool's BCCF records 2012–2015 against the province's 2021–2026, and the Tool's Tofino records 2013–2018 inside the province's 2013–2024 (the survey's "Every station read").

Decided by the builder (mechanism, from the review):

- **Days are local standard time**, at a fixed offset (UTC−8; UTC−7 for stations in the Peace and Liard drainages, `07*` and `10*`), not `America/Vancouver`, so every source in one `wet_station_daily()` result means the same day. This moves the survey's counts, which the Phase 4 acceptance accounts for.
- **A station's source is looked up, not inferred from its id's shape**: a station registry per snapshot (provincial ids, and under #144 the Tool's `nid`s mapped to their API ids, deduplicated as the probe does at line 263, the Tool's WSC and "BC ENV" copies left out). Only HYDAT's own pattern `^[0-9]{2}[A-Z]{2}[0-9]{3}$` is a shortcut, so a call with HYDAT ids never opens the registry and downloads nothing; `provisional` and `realtime` are limited to HYDAT-form ids.
- **Credit**: `wet_station_list()` carries `licence` and `credit` per station (the provincial files: "Contains information licensed under the Open Government Licence – British Columbia"); no column on every daily row. No wet output publishes these series yet.
- **Names**: internal `wet_bcenv(snapshot)` (returns the cached snapshot's paths, as `wet_hydat(release)` does) with a separate fetch helper tests can stand in for; internal `wet_bcenv_daily()`; exported `wet_station_list()`; each in its own file. Under #144, `wet_bcwatertool()` and `wet_bcwatertool_daily()` the same way.
- **`frac_provisional` counts every status that is not `"approved"`**, in `wet_window_stats()` and `wet_temp_gsdd()`, so a window of unchecked days does not read as approved.
- The snapshot is the survey's, **20261028**, seeded into the cache from the existing raw copy and held to the md5s in `data/checks/station_sources_20260717.txt` (lines 9–16), with a tracked manifest of every file's md5 (`inst/extdata/station_sources/bcenv_20261028.csv`): `Discharge.csv` is rewritten in place by the province, so only a tracked md5 checks a copy. A pinned snapshot is never fetched again; a new one lists the directory and orders the files by period, rather than the probe's eight hard-coded names.

## Open decisions

Each needs the owner's answer before the phase named; the recommendation is first.

1. **Scope of this PR** (before Phase 1). (a) *Recommended, changed by the review:* #142 only, with the pattern #144 follows (the registry, the snapshot cache, the status values, `wet_station_list()`); #144 its own PR after this one, its body edited to say it was split from move 8 and to carry decision 4, the Tool's `nid` registry, its `Units` check, and whether to read the Tool's two "BC ENV" listings that hold discharge the files lack (08MH0061, H08KC1015). Both blockers the review raised are on the Tool's side, and the four phases, a new export and a registered rule already make one PR. (b) Both readers in this PR: Phase 2 and Phase 3 each gain the Tool's half, and decision 4 is needed before Phase 3.
2. **Keep, flag or drop ungraded and unchecked values** (before Phase 2). (a) *Recommended:* keep and flag: a new `status` value `"unchecked"` for a provincial day with any `Undefined` or `Unspecified` hour (and, under #144, a Tool day flagged `0 - Unchecked Quality`); graded provincial days are `"provisional"` (neither source has an approval field); hours graded `Unusable` are left out, as the survey did. Dropping would remove most of the province's stations (134 of 211 are mostly ungraded). (b) Drop them. (c) Keep them unflagged.
3. **Impossible values** (before Phase 2). (a) *Recommended:* drop a day whose flow exceeds a bound measured on HYDAT, under a rule registered before it is measured: its form (a day's flow over its station's median of positive daily flows, over BC HYDAT stations with ten or more years, all stations, natural-only reported beside), the HYDAT release (20260717), and the expected catches (it must drop 08HA0036 and 08HD0003's impossible days and keep the Fraser at Big Bar, 08MD0002/3); then the bound is measured and the top stations reported; negative flows are dropped. (b) The same rule, flagging instead of dropping. (c) A unit-discharge bound (m³/s per km²), with each station's area from `wet_station_snap()` against fwapg.
4. **Which copy at the six shared sites** (#144's plan under 1(a); before Phase 3 under 1(b)). The chain keeps only a later source's days after the earlier one's last day, so "the Tool fills where the province holds none" is not something the chain does. (a) *Recommended:* provincial only; the six Tool listings are not read. At Tofino the Tool adds nothing (its years sit inside the province's); only the two BCCF sites lose 2012–2015. (b) A new rule that takes a second source's days *before* the first one's first day, with its own test, so the BCCF sites keep both copies under the provincial id. (c) Both, each under its own id.
5. **The 57 "same site, new years" provincial stations** (before Phase 3). (a) *Recommended:* each keeps its own id; `wet_station_list()` names the HYDAT station at the same site (number and distance, from the probe's `hydat_match()`, stored as a tracked crosswalk built with the snapshot) so a caller can join the two, and no record is continued across ids. (b) `wet_station_daily()` continues a HYDAT station's record with the provincial one at the same site, under the HYDAT number (an identity choice that changes what a HYDAT id returns).
6. **A backup of the pinned snapshot** (before Phase 1). (a) *Recommended:* a private copy at `s3://fresh-bc/station_sources/bcenv/20261028/` with its md5s, as HYDAT's releases are backed up, because `Discharge.csv` cannot be fetched again as it was. (b) No backup: the raw copy on the machine that holds it is the only one.
7. **Whether a station of unknown regulation can be a donor** (raised by the review; before Phase 4's wording, and for #118). Under `wet_station_select()`'s rule none of these stations can be, so this PR alone does not give #118 new donors. (a) *Recommended:* this PR brings held-out tests and records only, says so in `research/station_sources.md` and `NEWS.md`, and regulation per station is filed as its own issue (dams and licences upstream of each snapped station, as `scripts/wb_gauge_diversion.R` places licences). (b) Admit unknown-regulation stations from these sources as donors.

## Phase 1: the snapshot

- [ ] `wet_bcenv(snapshot)` in `R/wet_bcenv.R` (internal): the cached snapshot's file paths under `tools::R_user_dir("wet", "cache")/station_sources/bcenv/<snapshot>/`, each held to the tracked manifest's md5 and refused if it differs; a missing pinned file is fetched only from the backup (decision 6) or copied in by hand, never from the province; files landed by partial file and rename
- [ ] `data-raw/station_sources_snapshot.R`: seeds the cache from `data/station_sources/raw/bcenv/`, checks the eight files against the survey report's md5s, writes the tracked manifest `inst/extdata/station_sources/bcenv_20261028.csv`, and under decision 6(a) backs the snapshot up to S3; `CLAUDE.md`'s Data Sources says where the snapshot and backup are
- [ ] Tests on fixtures in `tests/testthat/fixtures/` (a few lines of the real format, CRLF and byte 0x96 included): a changed md5 refuses, a missing file is not fetched from the province (the fetch helper mocked to `stop()`)

## Phase 2: the provincial reader

- [ ] Register decision 3's rule in `research/station_sources.md` in its own commit (form, release, expected catches), then measure it with `scripts/station_sources_bound.R` → `data/checks/station_sources_bound_20260717.txt` (the bound, the top stations, natural-only beside) in the next
- [ ] `wet_bcenv_daily(stations, snapshot)` in `R/wet_bcenv_daily.R` (internal): the probe's duckdb read, stored as one derived parquet per snapshot and reader version in the cache, holding hourly-to-daily values *before* status and the bound are applied (so decisions 2 and 3 are applied on read, not baked in), built by partial file and rename; units to m³/s; `NaN` and `Unusable` hours dropped; a day at ≥ 20 hours on the local standard time date; status from the hours' grades (decision 2); the bound of decision 3; row counts held to line counts as the probe holds them. Name the minimum duckdb version `strict_mode = false` needs in `DESCRIPTION`'s Suggests
- [ ] Tests on the fixture: units, the 0x96 byte, a 19- and a 20-hour day, a day that straddles UTC midnight, an `Unusable` hour, a graded and an ungraded day, an impossible and a negative value; each test restores the defect it guards and is seen to fail

## Phase 3: `wet_station_daily()` and the station list

- [ ] `wet_station_daily(sources =, snapshot =)` gains `"bcenv"`, read for ids the snapshot's registry holds; `provisional` and `realtime` only for HYDAT-form ids; the same-site stations as decision 5 settles; `@return` says what `status` means for each source; the bad-`sources` test message in `tests/testthat/test-wet_station_daily.R` updated
- [ ] `frac_provisional` counts every non-`"approved"` status in `R/wet_window_stats.R` and `R/wet_temp_gsdd.R`, with a test of an all-`"unchecked"` window
- [ ] `wet_station_list(sources =, snapshot =)` in `R/wet_station_list.R` (exported): one row per station (`station_number, name, lon, lat, source, network, first, last, regulation, hydat_site, hydat_km, licence, credit`), the HYDAT match read from the tracked crosswalk `inst/extdata/station_sources/bcenv_20261028_hydat.csv` (written by the Phase 1 data script from the probe's `hydat_match()`); its docs say it lists non-HYDAT stations only and point to `wet_station_select()` for HYDAT; a runnable example on a fixture under `inst/extdata/`; `tests/testthat/test-wet_station_list.R`; an entry in `_pkgdown.yml`'s station section
- [ ] Every existing caller's result unchanged: the existing `wet_station_daily()` tests and the live HYDAT tests pass, and a mocked-reader test shows a HYDAT-only call opens neither the registry nor the new reader

## Phase 4: harvest report and research

- [ ] `scripts/station_sources_harvest.R` → `data/checks/station_sources_harvest_20261028.txt`, in two tiers: (i) under the survey's own rules (UTC days, no bound, HYDAT 20260717, the probe's match) the reader reproduces the probe's `prov_q` rows exactly and the 110 passing provincial stations; (ii) under the shipped rules (local standard time days, status, the bound), each station whose count moved is listed with the rule that moved it; per network, stations, days, `status` shares and days dropped by the bound
- [ ] `research/station_sources.md` revised in place: the harvest's verdicts, the bound, the decisions above, what decision 7 means for #118, and the items still open
- [ ] File each item this PR leaves out as its own issue naming move 8 (the Aquarius comparison of the province's 2021–2026 copy; regulation per station; Hakai's 2013–2020 record, which needs Hakai's consent); edit #142's body to say what landed, and #144's to carry what decision 1 moved to it
- [ ] `CLAUDE.md`'s station-flow line names the new source; `NEWS.md` entry

## Owed at the end (reported, done after merge)

- [ ] Tick move 8 in `planning/backlog.md` (`/gh-pr-merge` step 9c); under decision 1(a), #144 stays open for the next `/backlog-sweep` to place

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved: the readers by fixture tests that fail with the defect restored; the cache by a test that a changed md5 refuses and that the province is never fetched for a pinned snapshot; `wet_station_daily()`'s existing behaviour by its tests and a mocked-reader test that HYDAT ids never reach the new source; the harvest by tier (i)'s exact reproduction of the probe's rows and counts, and tier (ii)'s station-by-rule table; `pkgdown::check_pkgdown()`, and `lintr` per file against `origin/main`.
