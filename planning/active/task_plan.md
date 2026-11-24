# Task: Backlog move 14: Regulation per non-HYDAT station (#196)

**If we do it:** every station in wet's non-HYDAT registry, provincial and third-party, carries a regulation status from what sits upstream of it, so the natural ones can be donors for departures at ungauged sites (#118). **If we never do:** `wet_station_select()` keeps leaving every non-HYDAT station out as a donor, because unknown is not natural, and the stations moves 8 and 13 bring serve as records and held-out tests only.

Carries #191 (Regulation per non-HYDAT station, so the natural ones can be donors). One PR under the recommended decisions 3 and 4.

## Decided at the gate

No plan gate in this pane: dispatched by `/coordinator` as `park review` (GATE=coordinator, soul#928). The draft was written and Plan-reviewed here (`planning/active/review-plan.md`); the owner forks are under `## Open decisions` for the coordinator's plan gate. Mechanism decided in the plan (agent-operations §4, mechanism promoted 2026-11-22):

- **A new placement script, not an edit of #53's.** `scripts/wb_gauge_diversion.R` is #53's frozen rule and its report must keep reproducing; it runs only where the full fit is. The new `scripts/station_regulation.R` reuses its method (WFS paging held to the server's count, the licence-row rules of #53's Amendment 1, `fwa_upstream()` on codes plus the stream-position test in the station's own reach) through `scripts/station_regulation_lib.R`, which names each copied piece's source lines so a reader can diff them. #53's script is not touched.
- **The rule lives in its own file, committed with its tests before any placement** (review O1): `scripts/station_regulation_rule.R` (pure functions, constants, name fold, tie rules) and `tests/testthat/test-station_regulation_rule.R`, as `scripts/wb_small_basin_rule.R` and its test do. The script records the rule file's registering sha and md5 in its report and stops if the file differs from that sha (review AC1). A change after placement is a dated amendment in the rule file, its effect reported, as #53's Amendment 1 and Deviation 1 were (review G13).
- **The script never calls `wet_station_list()`** (review B1: it would read its own output, and on a new snapshot `wet_station_list()` would stop before the status file exists). Population from `wet:::wet_bcenv_stations()` and `wet:::wet_bcwatertool_stations()`, folded as `R/wet_station_list.R:63-88` folds them (Tool rows with `is.na(continues)`; the 7 continuing listings are their provincial row); the name test from `regulation_of()` (`scripts/station_sources_lib.R:93`).
- **Code sets are exact and closed** (review B2): the register writes `Regulated`, `Regulated - Part 3 Exempt` (ASCII hyphen) and `Non-Regulated - Including Minor Dam`; the rule names the exact strings, and the script stops on any `DAM_REGULATED_CODE`, `DAM_OPERATION_CODE` or `LICENCE_STATUS` value outside its known set. #53's "every located POD of a shared group is a candidate" assertion (`wb_gauge_diversion.R:163-167`) stays a stop; a failure is a question for the owner (review A3).
- **The snap query** is `wet_station_snap()`'s candidate query (`R/wet_station_snap.R:50-67`) copied into the lib with `c.gnis_name` added (`fwa_indexpoint()` returns it), lines cited (review G1). Tool drainage areas come from `wet:::wet_bcwatertool_read()$meta[["Drainage Area"]]` (`R/wet_bcwatertool.R:195-221`), `"None"` read as NA (review G11); none of the 7 continuing listings states an area, so no provincial row gets one from the Tool.
- **Snapshots and caches:** both WFS layers taken once into `data/station_regulation/raw/<YYYYMMDD>/` (gitignored), md5s and the server's counts in the report. Snap, placement and flows are cached keyed on their inputs (as #53's `place_key`, `wb_gauge_diversion.R:216-218`), the published parts read are held with `wet:::wet_catalog_verify()` and named by `wet:::wet_catalog_digest()` (as `scripts/segment_group.R` and `scripts/departure_site.R` do), and the report carries no timestamp, so a rerun from cache is byte-identical (review AC2, A4).
- **The status file is tied to what it was built from** (review G8): it records both snapshots and the md5 of each registry; the reader refuses a mismatch, as `wet_bcwatertool_against()` (`R/wet_bcwatertool.R:235-249`) does, and `wet_station_list(snapshot = )` for a snapshot with no status file is an error naming the script.
- **The reader is an internal `wet_station_regulation()`** called after `wet_registry_check()` (`R/wet_station_list.R:56`), so the existing tests that mock the registries (`tests/testthat/test-wet_station_list.R:54-73`, `tests/testthat/test-wet_station_daily.R:477,487`) mock it too (review G9).
- **Licences of the registers are measured and published**, not only noted in planning: the research section and the report state each layer's licence as read from its catalogue record, and the status file and `wet_station_list()`'s docs carry its credit line, since derived data ships in `inst/extdata` (review G6).
- **Conservative direction:** a wrong "regulated" loses a donor; a wrong "natural" puts regulated flow in a donor pool. Every recommendation below leans to regulated or unknown when in doubt.

## Decided at the plan gate (2026-11-23, issue #196 `## Decisions`)

The owner took the recommended option on each of the four decisions below, the area-only leg included.

1. **The rule for natural, regulated and unknown, and which registers enter.** Recommended:
   - *Registers.* The provincial dam register (`WRIS_DAMS_PUBLIC_SVW`) and water rights licences (`WLS_WATER_RIGHTS_LICENCES_SV`), both BC WFS layers (licence read in Phase 1). Reservoirs enter through the dam register and storage licences, which every licensed reservoir has; FWA man-made waterbodies upstream are reported beside the status and decide nothing.
   - *Snap.* Each station's point is indexed with `fwa_indexpoint()` (1,000 m, 5 candidates, as `wet_station_snap()`). A candidate is accepted when `stream_of(station name) == stream_of(gnis_name)` (`scripts/station_sources_lib.R:35-53`, the survey's fold, which takes the stream up to its first stream noun, so "Unuk River upstream of Sulphurets Creek" matches the Unuk), ties broken by distance, then `linear_feature_id`. Where a drainage area is known (the Tool's header, after its unit is checked against same-stream HYDAT areas; HYDAT's gross area at the 58 provincial stations at a HYDAT site), the accepted candidate's upstream area must be within 10 % of it (`wet_station_snap()`'s `max_dev`). *Option:* an area-only leg, `wet_station_snap()`'s own rule, for stations that state an area but name no stream ("Brucejack Lake Outflow", "126 Road"). Recommended: yes. No accepted candidate: **unknown**. The report gives acceptance by leg and source.
   - *Regulated* when any of: the name says so (`regulation_of()`); an active dam (`DAM_OPERATION_CODE` `Active`) with `DAM_REGULATED_CODE` `Regulated` or `Regulated - Part 3 Exempt` sits upstream on the network (that code is a dam-safety class, by size and consequence, not a statement about flow; any `DAM_FUNCTION`, Main, Saddle, Conversion, Spillway or Outlet, counts); licensed storage S ≥ 10 % of the station's mean annual flow; licensed consumptive use L ≥ 10 % of it (#53's thresholds and licence-row rules). Licences counted: `LICENCE_STATUS == "Current"` on the snapshot date, any `POD_STATUS`, a shared quantity straddling the station split over its PODs (#53's `split`); under Current-only, #53's replacement removal does nothing, and the rule says so.
   - *Unknown*, even with an accepted snap, when: any of the station's upstream area lies outside BC (Kettle-type basins, where the registers do not reach); a power licence (purpose 07A, 07B or 07C, which #53 classes instream and does not count) has a POD upstream; or the snapped segment has no published flow (`wet_segment_monthly()` returns NA, `R/wet_segment_monthly.R:53-55`), so L and S cannot be formed. A dam or the name still makes such a station regulated.
   - *Natural* otherwise.
   - *Mean annual flow* (the denominator of L and S) is wet's published `pick` at the snapped segment, month 0, because most of these records are short or seasonal and their own mean is not an annual one.
   - The 58 provincial stations at a HYDAT site get the rule's status beside HYDAT's flag for that site in the report: the rule's only outside check, which decides nothing.
2. **One status per station, or by window.** The licence layer has no period-of-use field (its `DescribeFeatureType`, read 2026-11-23, lists none; nor did #53 request one), so a window status could rest only on purpose codes. Recommended: one annual status now; a window status waits until a donor pool needs one and a source states the season.
3. **Where donor selection reads it, and how far this PR goes.** Recommended: `wet_station_list()`'s `regulation` column carries the status, and `wet_station_select()` stays HYDAT-only (its SQL reads HYDAT's flag and complete years), its docs pointing to `wet_station_list()` for the natural non-HYDAT stations. Putting those stations into a donor pool (`scripts/departure_site.R`'s box, `wet_window_extend()`) is filed as its own issue naming move 14 and #118, left out of `planning/backlog.md` for the next `/backlog-sweep`. The backlog's touch list names `R/wet_station_select.R` and its test: under this recommendation the function changes by a doc line and its test file not at all.
4. **Where the status is stored.** Recommended: its own tracked file, `inst/extdata/station_sources/regulation_<bcenv snapshot>.csv` (`station_number`, `source`, `regulation`, `why`, `dams_up`, `L_share`, `S_share`, `snap_stream`, `snap_leg`, `snap_m`, the WFS snapshot date, both station snapshots, each registry's md5, and the registers' credit), written by the new script and read by `wet_station_list()` in place of the registries' name-only column. The two pinned registries are not rewritten, so `scripts/station_sources_harvest.R`'s check of the registry against the name rule (lines 219-221, 384) still holds, and regulation can be redone on a new WFS snapshot without re-pinning the station data. The alternative, rewriting the registries' `regulation` column, needs both data-raw writers rerun with their raw copies (`WET_BCWATERTOOL_RAW`) and moves the harvest check: two PRs.
5. **What ships from the licence layer, whose terms are "Access Only"** (met in Phase 1, 2026-11-24). The catalogue record `water-rights-licences-public` (`WLS_WATER_RIGHTS_LICENCES_SV`) gives the licence "Access Only"; the province's copyright page says such materials are "access only and reproduction is not permitted without written permission". The dam register (`bc-dams`) is OGL-BC. Decision 4's status file was to carry each register's credit line; the licence layer has none to carry. Decided by the owner 2026-11-24 (asked in the resume session): the recommended option, ship only values wet computes (status, `why`, `L_share`, `S_share`, counts), never a licence record (number, POD, quantity, location), and state the layer's terms in the docs, the status file and research, as #53's tracked report already publishes per-gauge L and S from the same layer.

## Open decisions

None open.

## Phase 1: Register the rule

- [x] Read each WFS layer's catalogue record and record its licence and credit line (research section, later the report)
- [x] Check the Tool's drainage-area unit against same-stream HYDAT gross areas (the Petitot listings, 9,863.2 and 20,410.5); the result goes into the rule, before it is committed
- [x] `scripts/station_regulation_rule.R`: header registering the rule as decided (open decisions 1 and 2), the population (both registries, folded as `wet_station_list()` folds them), what was seen first, the amendment protocol and the report path; pure functions for the name fold match, the tie break, the area test and the status, with the exact code sets
- [x] `tests/testthat/test-station_regulation_rule.R`: each threshold at its edge, each unknown branch, ties, a name-regulated station never natural, a code outside the set refused
- [x] `research/station_sources.md`: a "Regulation (registered <date>)" section carrying the rule and the registers' licences; committed with the rule file, before the script places any station

## Phase 2: Snapshot, snap and place

- [x] `scripts/station_regulation_lib.R`: WFS paging (held to the server's count, ids in sequence), the licence-row rules, the snap query with `gnis_name`, the placement SQL, each naming its source lines
- [x] `scripts/station_regulation.R`: stops unless the rule file is at its registering sha; snapshot both layers into `data/station_regulation/raw/<date>/` with md5s and counts; stop on a code outside the known sets
- [x] Snap every station by the registered rule (connection from `WET_PG*`, `connect_timeout` set); Tool areas from `wet_bcwatertool_read()`, HYDAT areas at the 58 sites; acceptance by leg and source
- [x] Place dams and licence points in FWA watersheds and test upstream of each accepted snap (codes, then stream position in the station's own reach); upstream area outside BC per station
- [x] Mean annual flow per accepted snap from the published parts (`wet_segment_monthly()`, month 0, `pick`), parts verified with `wet_catalog_verify()` and the digest recorded
- [x] Per station: dams upstream, L, S, power PODs upstream, FWA man-made waterbodies upstream (reported only), the status and its `why`; snap, placement and flows cached keyed on their inputs

## Phase 3: Store and read the status

- [x] Write the status as open decision 4 decides (recommended: `inst/extdata/station_sources/regulation_<snapshot>.csv`, one row per listed station, no NA status)
- [x] Internal `wet_station_regulation()`, called by `wet_station_list()` after `wet_registry_check()`: refuses a status file whose snapshots or registry md5s differ, a missing station, an NA status or one outside the vocabulary; `regulation` takes natural, regulated or unknown; docs say where it comes from, the registers' credit, and that natural stations may be donors
- [x] `R/wet_station_select.R` docs: HYDAT only, pointing to `wet_station_list()` for natural non-HYDAT stations (as open decision 3 decides)
- [x] `R/wet_station_daily.R:22-25` docs: the "not donors until their regulation is known" sentence rewritten
- [x] Tests: `tests/testthat/test-wet_station_list.R` (every station has a status in the vocabulary; a natural station has an accepted snap; a station regulated by name stays regulated; the status file's guards), and `wet_station_regulation()` mocked in the registry-mocking tests of `tests/testthat/test-wet_station_list.R` and `tests/testthat/test-wet_station_daily.R`
- [x] Plant each defect and show its guard fires: in the reader (a station missing from the status file, an NA status, a status outside the vocabulary, a stale registry md5) and in the script (a WFS count short of the server's hits, an out-of-sequence page, a dam code outside the set, a name-regulated station coming out natural, the rule file changed since its registering sha)

## Phase 4: Report and record

- [x] `data/checks/station_regulation_<bcenv snapshot>.txt`: the rule file's sha and md5, snapshot md5s, counts and licences, the catalog digest, snap acceptance by leg and source, each station's status and why, counts by status and source, the stations that change from "unknown", the rule beside HYDAT's flag at the 58 shared sites; rerun from cache and `cmp` byte-identical
- [x] `research/station_sources.md`: the regulation paragraph (line 35), the two **Donors** bullets and **Still open** rewritten from the report; `**Verified:**` and `**Issues:**` updated
- [x] `CLAUDE.md` lines 80-81 (the station-sources bullets: records and held-out tests, not donors): name the status and the script; `NEWS.md` entry (left to `/gh-pr-merge`, whose release commit writes every entry)
- [x] File the donor-pool issue (open decision 3), naming move 14 and #118, not added to `planning/backlog.md` (#202)
- [ ] `devtools::document()`, `lintr` against `origin/main` per file, `devtools::test()`, `pkgdown::check_pkgdown()`

## Owed at the end (reported, done after merge)

- [ ] Close #191 with the PR; tick move 14 in `planning/backlog.md` (`/gh-pr-merge`)

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved: the rule file and its tests are committed before the script exists, and the report names that sha and the script refuses any other; a second run from cache gives a byte-identical report (`cmp`); the reader's tests read the shipped status file; each planted defect is shown failing its guard; the rule's status at the 58 HYDAT sites is reported beside HYDAT's flag.
