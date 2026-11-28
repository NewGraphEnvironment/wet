# Task: Backlog move 21: Daily air temperature at every stream segment (#237)

**If we do it:** daily air temperature exists at every stream segment, so a temperature prediction can run at a reach
with no station. **If we never do:** predicted parameters have nothing to run on away from the stations.

One batch (batch 23), one member (#216): one lookup from segment to ERA5-Land cell and one published copy of each
cell's daily series serve every reach. `wet_temp_fill()` takes its air from `cd::cd_extract_daily()` at station points;
nothing in wet gives air temperature on stream segments.

## Decided at the gate

**The owner's answers, 2026-11-27: all ten as recommended** (one question at the resume, "all as recommended"). The options not chosen are kept below each item for the record; the phases are written for the chosen ones.

1. **The dataset's ID and layout.**
   (a) *Recommended.* One tree, `air_temperature/fwa/v1`, at `s3://fresh-bc/air_temperature/fwa/v1/`, holding two
   datasets, `segment_cell` (the lookup) and `cell_daily` (each cell's series), under one manifest and one receipt.
   Parts sit under the discharge tree's Hive keys (`scenario=historical/forcing=ERA5-Land/source=cd_daily`), so
   `wet_catalog()`, the verify and digest code and the upload read the tree as they read discharge, and a
   future-climate series later lands beside it as another `scenario`. It bends three written rules of
   `research/discharge_publish.md`, which Phase 5 restates and the crate pull request records: "two networks can never
   share a dataset" (`cell_daily` is keyed by grid cell under `fwa`); `<unit>_<timebase>` is "the feature a row
   describes and the time step of its values" (`segment_cell` has no time step); and "cd publishes air temperature"
   (here wet publishes a copy keyed for the Freshwater Atlas).
   (b) Two trees: the lookup under `air_temperature/fwa/v1`, the series under `air_temperature/era5land/v1`. Two
   manifests, two receipts, two publishes; only the missing time step is bent.
   (c) The lookup only: the series is read from cd's cube through `cd::cd_extract_daily()` at each cell's centre. No
   second copy of the cube (2.8 GB as published), but a reader then needs cd and raster tooling, and reads one file per
   variable and year. #216 as written asks for (a) or (b).
2. **Columns, rows and variables.**
   *Recommended.* `segment_cell`, one row per segment of `whse_basemapping.fwa_stream_networks_sp` (4,907,441; every
   segment, not only the main-flow tree's 4,510,368, so the table does not go stale when the tree's table is rebuilt),
   one part per watershed group: `linear_feature_id` (key), `watershed_group_code`, the cell's key (decision 3),
   `cell_x`, `cell_y` (the cell centre, degrees), `cell_status` (decision 6), `point_x`, `point_y` (the point that took
   the cell, degrees), `segment_elev_m` (the Freshwater Atlas elevation at that point), and `cell_elev_m` when cd can
   give it (decision 7).
   `cell_daily`, one row per cell and local day (UTC−8, cd's day), one part per year 1950–2025, only the cells some
   segment uses (about 13,940 of the cube's 20,746 with data): the cell's key, `date` (decision 4), `tmean_c`,
   `tmax_c`, `tmin_c`. About 387 million rows. Its bytes are not measured yet: Phase 1 builds one year both ways and
   stops if three variables project past 10 GB.
   Alternatives: `tmean_c` alone (a third of the values; `wet_temp_fill()` reads only the mean); the long shape cd
   returns (`variable`, `value`), three times the rows.
3. **The cell's key.** cd's `cell` is a cell number on the cube's 121 × 261 grid, and it renumbers every cell if cd's
   box grows by a row or column, which it has done once (its northern edge moved from 59.95 to 60.05° N).
   (a) *Recommended.* A key that does not depend on cd's box: `cell_id`, an integer computed from the cell centre on
   ERA5-Land's own 0.1° grid (the formula stated in the schema), with `cell_x`, `cell_y` beside it. A cube on a larger
   box then adds cells and changes none.
   (b) cd's cell number, with the grid recorded in the manifest and a build that refuses another grid: rows join
   straight to `cd_extract_daily()`'s output, and a changed box is a full rebuild under `v2`.
4. **How `date` is stored.** crate's schema types are `integer`, `double`, `string`, `logical` and `datetime`; it has
   no date, and its datetime would stamp 00:00 UTC, which is 16:00 of the previous day on cd's UTC−8 day.
   (a) *Recommended.* A `date` type added to crate, in the same crate pull request as the two schemas, stored as
   parquet's own date. The move then waits on that crate release as it already waits on the schemas.
   (b) A string, `YYYY-MM-DD`: no change to crate's types; parsed on every read of 387 million rows.
   (c) Two integers, `year` and `doy` (1–366).
5. **Which point of a segment takes the cell.**
   (a) *Recommended.* Its midpoint along the line (`ST_LineInterpolatePoint(geom, 0.5)`): on the segment itself, and
   never on another stream's line as a mouth's downstream end is.
   (b) Its downstream end. The two points fall in different cells for 141,708 segments (2.89 %). How many stations sit
   in another cell than their segment's point, under each, is measured in Phase 1.
6. **How segments with no cell are listed.** By the midpoint against the cube's mask of 1 January 2025: 4,864,743
   segments sit in a cell with data, 41,734 (0.85 %) in one of 327 cells without (coast, large lakes) with a data cell
   among the eight around it, 962 (0.020 %) with none, 2 outside the cube's box.
   (a) *Recommended.* In the lookup itself: every segment has a row, and `cell_status` is `own`, `moved` (cd's rule
   gave it the nearest of the eight around it that has data), `no_data` or `outside`; the cell's key is null for the
   last two (964 segments). The report counts each status by watershed group.
   (b) A separate published file listing the segments with no cell, the lookup holding only segments with one.
   (c) As (a) without the move: the 41,734 are `no_data` too, and no neighbour is borrowed. The lookup then differs
   from `cd_extract_daily()` at those points by design, and the station check must expect it.
7. **Cell elevation, which cd does not hold.** cd publishes no elevation for the cube's cells.
   (a) *Recommended.* Publish `v1` now without `cell_elev_m`; file the capability with cd; add the column when cd has
   it (a new column does not bump the version, but rewrites the lookup's parts). A wet issue naming move 21 carries it.
   (b) Wait: build nothing until cd holds the layer, as the move's own rule reads ("a capability cd lacks becomes an
   issue there that this move waits on").
8. **Who publishes, and when.** `air_temperature/*` is a new prefix: anonymous reads there need a bucket-policy change
   made outside this repo, and the upload is a production write.
   (a) *Recommended.* While the pull request is open: the owner opens the prefix and runs the upload from the branch,
   at the commit the tree was built at; the report it rewrites is committed on the branch, and the merge finishes #216
   but for the elevation column. The pull request waits on the owner for those two steps.
   (b) After the merge. The release then ships `wet_air_daily()` with a default manifest address that answers 403
   until the upload; the built tree must survive until then, and the upload's code guard must still pass on main after
   other merges.
9. **#216's station condition.** It reads: at every station, the series through the lookup equals `cd_extract_daily()`
   at the station's point. A station and its segment's point can sit in different cells (the snap picks among
   candidate streams within 1 km by drainage area), and there no lookup keyed on a point of the segment can meet it.
   (a) *Recommended.* Reword it in #216: at every station the series through the lookup equals `cd_extract_daily()` at
   the segment's stored point; against the station's own coordinates it is equal wherever the two share a cell, and
   the stations where they do not are listed with both cells and the distance between the points, not failed.
   (b) Keep it as written and report every station in another cell as a failure of the condition.
10. **A Postgres table.** #216's third condition is "the published tables load by segment id for any watershed group",
   and in this repo "load" is also what `wet_db_load()` does.
   (a) *Recommended.* The reader over the published parts meets it; `wet_db_load()` is not extended, and refuses the
   air tree before fetching a part.
   (b) `wet_db_load()` also writes `air_temperature.fwa_v1_segment_cell` and `air_temperature.fwa_v1_cell_daily`: its
   own issue naming move 21, not this pull request.

**Mechanism**, decided by the plan session (each with its reason):

- **The lookup is made by `cd::cd_extract_daily()` itself**, called for one day at each segment's point, never by a
  copy of cd's cell rule in wet: the lookup then is cd's own answer for that point (under decision 6(a) or (b)).
- **The day that defines the mask is pinned**: the one-day call asks `tmean` for 1 January of the cube's last year,
  because cd decides "has data" from the first band of the first file it opens. The manifest names that file.
- **Statuses come from cd's columns, not from its warning text**: `outside` is a null cell, `moved` is
  `cell_moved`, `no_data` is a cell kept with an NA value on the mask day (cd returns a stranded point's own cell,
  unmoved). cd's two expected warnings are muffled by their opening words and any other warning is raised.
- **The series is read by `cd::cd_extract_daily()` at each used cell's centre**, one variable and year a call. Every
  cell centre maps back to its own cell (checked on all 31,581), so cd returns that cell's values unmoved; the build
  asserts it, and treats any cd warning or an NA `checksum` there (a stale cached file) as a refusal.
- **Checks that do not pass through the code that made the tree**: every `own` row's cell recomputed from `point_x`,
  `point_y` and the grid; every `moved` row's cell recomputed by cd's stated rule (nearest centre by geodesic distance,
  ties to the lower cell number) from the cube's mask; every stored value against the cube read directly.
- **The station check is its own script and report**, not part of the BUILD: the archive's station list grows, and the
  BUILD's report must be byte-identical on a rerun. Its stations are those of the temperature archive with coordinates
  in the pinned HYDAT release that `wet_station_snap()` places.
- **The built tree lives under `WET_DATA_ROOT`** (the main checkout's `data/` when the run is from a worktree), so
  removing the worktree does not remove it; run logs under its `logs/237/`.
- **The upload's code guard compares the files the air build reads**, between the build's commit and HEAD, and a test
  derives that list from the calls `scripts/air_publish.R` and its lib make, so a new dependency fails the test instead
  of slipping past the guard. A guard over all of `R/` and `scripts/`, as discharge has, would stale the air tree on
  every unrelated merge.
- **The new files join `scripts/discharge_publish_own.R`'s list**: the discharge guards compare every file under `R/`
  and `scripts/` not on it, so without the entries this move would read as a change to the discharge tree's code.
- **`/code-check` over `R/` and `scripts/` finishes before the BUILD**, so a review fix does not cost a rebuild.
- **#216's edge premise has moved.** The cube now reaches 60.05° N (read from the 2025 file), so 2 segments fall
  outside it, not every segment north of 59.95° N (25,829).
- **cd's open defect on areas over sea cells does not bite here**: it is about areas, and this move samples points.
- **Names.** `R/wet_air_daily.R` (exported `wet_air_daily()`; internal `wet_air_cells()`), `scripts/air_publish.R`
  with `scripts/air_publish_lib.R`, `scripts/air_station_check.R`, `inst/receipt/air_temperature_fwa_v1.yaml`,
  `data/checks/air_publish_2025.txt` and `data/checks/air_station_check_2025.txt` (named for the cube's last year),
  `research/air_temperature_segments.md`.
- **Installed packages**: cd 0.6.13 is installed and is its checkout's version; crate 0.21.0. The installed wet is
  0.4.44 against 0.6.0 in the tree: reinstall before trusting a lint on a name this branch adds.

## Phase 1: The measurements, the decisions, and what cd and crate must hold

- [x] Before building: `bash "$T/skills/_shared/members_check.sh" <origin> 237 237-backlog-move-21-daily-air-temperature-at --batch 23` (T from `soul_published_tree`). On a non-zero exit or any line but `FREE`, build nothing: write the line under `## Open decisions` and stop.
- [x] Ask every item under `## Open decisions` that is still open; move each answer to "Decided at the gate" and write the decided ID, schema, key, date, point, listing and station condition into #216's body under `## Decisions`, with the stale edge premise corrected there. Where an answer is not the recommended one, revise everything that assumed it before going on, and say so in `progress.md`: the phase it changes, the bullets of "Decided at the gate" (the first and the Names bullet assume 1(a) and 6(a)), the count of crate schemas (6(b) adds one, 1(c) leaves one), the publish phase and "Owed at the end" (8, 7), and the Validation paragraph.
- [x] Measure, from streaming queries (no sort or aggregate in the database) and the cube, and record in `findings.md`: the time of `cd::cd_extract_daily()` for one day of `tmean` at the points of one coastal watershed group and one interior group, projected to the province; one year of `cell_daily` written both ways (three variables, `tmean` alone), its bytes projected to 76 years; and, for the stations the station check will use, how many sit in another cell than their segment's midpoint and than its downstream end.
- [x] Stop rules on those numbers, each written under `## Open decisions` with its measurement when it fires: the lookup projected above 6 hours (the per-point neighbour search is then a capability cd lacks: file it with cd, its own inputs and timings, no workaround here); three variables projected above 10 GB.
- [x] File the cell-elevation capability with cd: ERA5-Land's model elevation on the cube's grid, as a published layer or a column of `cd_extract_daily()`. Link it from #216's body. Under decision 7(a), file the wet issue that adds `cell_elev_m`, naming move 21, and leave it out of `planning/backlog.md`.
- [x] File one wet issue for the stale statement that the cube stops at 59.95° N (`scripts/temp_fill_validate.R` and `research/station_temperature_fill.md`), with the extent read from the cube; edit neither file here.
- [x] After the measurements: open the crate issue and pull request, from a crate worktree, that add the two schemas (`nge`, `air_temperature/fwa/v1/segment_cell` and `air_temperature/fwa/v1/cell_daily`) with their columns and notes as decided, the `date` type under decision 4(a), and a decision record for the naming rules decision 1 bends. Say in `progress.md` that Phase 4 needs it merged, released and installed: the build checks each schema against the installed crate's release tag, as `scripts/discharge_publish.R` does.

## Phase 2: The reader and the cell lookup, on a fixture

- [x] Before building: the member re-check of Phase 1, run again.
- [x] Tests first, in `tests/testthat/test-wet_air_daily.R`, skipped where cd is not installed. The cube cd ships (one year, 5 × 5 cells) has no empty cell, so the tests work on a copy with cells set to no-data: one cell with a data neighbour, one block with none. `wet_air_cells()` gives each of `own`, `moved`, `no_data` and `outside` on points placed for it, a `moved` point taking the neighbour cd's rule names; `wet_air_daily()` returns `cd_extract_daily()`'s columns (`id`, `date`, `variable`, `value`, `cell`, `cell_x`, `cell_y`, `cell_moved`) with `date` a Date, and values `identical()` to `cd::cd_extract_daily()` at the segments' stored points; a segment with no cell and a segment the lookup lacks each return their days with `value` NA; `groups` is required and a segment outside them reads as missing; bad `from`, `to`, `variables` and `segments` are refused.
- [x] `R/wet_air_daily.R`: `wet_air_cells(points)` (internal: one `cd::cd_extract_daily()` call for the pinned day, statuses from its columns) and `wet_air_daily(segments, from, to, variables = "tmean", groups, catalog = NULL)` (exported: the lookup parts of `groups`, then the year parts the dates span, through duckdb, as `wet_segment_daily()` reads its parts; `id` is `linear_feature_id`; `catalog = NULL` reads the air tree's own manifest address, a constant beside `wet_catalog_url`). A runnable example on a bundled tree.
- [x] `data-raw/air_example_data.R` writes that bundled tree under `inst/extdata/air_example/` (a manifest and a few kilobytes of parquet, from the masked copy of cd's example cube and made-up segments, one of them `moved`), byte-identical on a rerun.
- [x] `R/wet_catalog.R`: `wet_receipt_write()` takes its row-count names from the declaration's `result.summary` and its declaration file from the tree's ID, in place of the three discharge datasets and the discharge file; the roxygen of `wet_catalog()` says it reads either tree. `wet_catalog()` and `wet_manifest_write()` already accept the air tree (labels are a caller's vector named by code; the grid and cube files fit a source's `provenance`): a test in `tests/testthat/test-wet_catalog.R` reads the bundled air manifest to hold that, the existing pin on `rows_segment_daily` stays green, and a discharge manifest and receipt written from the existing fixture are byte-identical before and after the change.
- [x] `R/wet_db_load.R`: refuse a dataset of the air tree before any part is fetched (today `cell_daily` is read as a day-of-year table and fails after the download), with a test in `tests/testthat/test-wet_db_load.R`. Skipped under decision 10(b), whose issue is filed instead.
- [x] `scripts/discharge_publish_own.R`: the files this move adds under `R/` and `scripts/`, each a claim that no discharge table reads it; `tests/testthat/test-publish_own.R` still passes.
- [x] `DESCRIPTION`: raise cd's floor in `Suggests` to the version whose `cd_extract_daily()` the build uses (0.6.13 unless a later one is installed) and crate's to the release carrying the schemas; `_pkgdown.yml`: `wet_air_daily` in the reference index; `devtools::document()`, `pkgdown::check_pkgdown()`, lintr compared per file against `origin/main`.

## Phase 3: The build script

- [x] Before building: the member re-check of Phase 1, run again.
- [x] `scripts/air_publish_lib.R`: the tree's ID, bucket address, forcing and source keys, the grid's definition, the pinned mask day, the list of files the build reads, and the functions the script and its tests share (the segment query, the part writers, the report lines, the checks), with `tests/testthat/test-air_publish_lib.R` for those that take no database, among them the test that derives the file list from the scripts' calls. Tests that need the crate schemas before their release run against the crate branch installed into a throwaway library, never the user library, and skip without it.
- [x] `scripts/air_publish.R`, BUILD by default and `WET_PUBLISH=1` to upload, laid out as `scripts/discharge_publish.R` is (its manifest removed first, so a build that refuses leaves nothing publishable; the upload only under a committed report naming the tree's digest and only while the files the build reads are unchanged since its commit; the public manifest read back anonymously after an upload, the report's live-build line rewritten):
  - the segments: `linear_feature_id` (cast off bigint in the query, as `R/wet_station_snap.R` does), `watershed_group_code` and the decided point's longitude, latitude and elevation for every row of `fwa_stream_networks_sp`, one watershed group a query, ordered by `linear_feature_id`, with no sort or aggregate in the database beyond that index order; a null or empty geometry is a refusal, not a dropped row; the rows read are held to the table's `count(*)`;
  - the lookup: `wet_air_cells()` per group, one `segment_cell` part per group, rows ordered by `linear_feature_id`;
  - the series: for each year, `cd::cd_extract_daily()` at the centres of the cells the lookup uses, per variable, asserted to come back on the same cell with `cell_moved` FALSE and a checksum, any cd warning a refusal; one `cell_daily` part per year, rows ordered by cell then `date`, stored at the cube's own numeric type (4-byte float) so no value is rounded;
  - each part conformed to its crate schema; the manifest with each year part's three cube files (name, checksum, `cd_sha`), the mask's file and the grid; `inst/receipt/air_temperature_fwa_v1.yaml` and the receipt (inputs: the digest of the cube's manifest, every distinct cd commit the cube's files name, the fwapg build the segments came from; settings: the crate release, the decided point, the mask day);
  - no run time, host or path inside any part, so a rebuild on the same inputs writes the same bytes.
- [x] `scripts/air_station_check.R`: the station check of decision 9, reading the built tree through `wet_air_daily()` and its local manifest, writing `data/checks/air_station_check_2025.txt` with the archive's station count, the list's md5, the stations not placed and why.
- [x] The source's description and citation in the manifest: ERA5-Land (its publisher's citation and licence notice, read from cd's own notice and the publisher's page, not from memory) and cd's `citation()`.
- [x] `/code-check branch` over the branch so far, its findings fixed, before Phase 4.

## Phase 4: The build, its checks and the reports

- [x] Before building: the member re-check of Phase 1, run again.
- [x] Both crate schemas (and the `date` type under 4(a)) are in the installed crate at a released version; if the crate pull request is not merged and released, write that under `## Open decisions` and stop here.
- [x] Probe the database with a 10-second connect timeout, commit, then run the BUILD in the background with a deadline, its log under `<WET_DATA_ROOT>/logs/237/`; touch nothing it reads while it runs.
- [x] `data/checks/air_publish_2025.txt`, written by the BUILD, holds: the segments read against the table's `count(*)`; the main-flow tree's segments found in the lookup against the tree table's row count (#216: every segment on the tree has a cell or is listed as having none), counted by status for the province and by watershed group; the cells used; rows and bytes per dataset; each year part's cube files; the mask's file; the grid.
- [x] The BUILD's checks, each reported as compared, differing and largest difference, any difference failing it:
  - every `own` row's cell from `point_x`, `point_y` and the grid (terra's rule on the grid's definition; the report says so, since a point computed to lie exactly on a cell edge is where plain `floor()` arithmetic disagrees);
  - every `moved` row: its own cell no-data in the mask, and its cell the one cd's stated rule names, recomputed from the mask and the point; every `no_data` row's nine cells no-data; every `outside` row's point outside the box;
  - completeness: every cell the lookup uses has every day of every year in `cell_daily`, and no other cell is there;
  - every `cell_daily` value against the cube read directly with terra at that cell, for every year.
- [x] Each check shown able to fail, in a copy of the tree: an `own` segment's cell moved to a neighbour; a `moved` segment's cell changed to another of the eight around its own; one `cell_daily` value changed; one cell's rows for one year dropped; one status flipped. Each must turn its own check red; the table of mutation and outcome goes in `findings.md`.
- [x] A second BUILD from the same inputs writes byte-identical parts and report; the report says so by the tree's digest.
- [x] `scripts/air_station_check.R` run on the built tree, and shown able to fail by one station's segment given a neighbour's cell in a copy.
- [x] `wet_air_daily()` reads one segment from each of the 246 watershed groups from the built tree, and one whole group for every year, timed.

## Phase 5: What is known, written down

- [x] Before building: the member re-check of Phase 1, run again.
- [x] `research/air_temperature_segments.md`: the header line (verified date, issues, what produced it), the tree's ID and layout, the cell rule, the point and the mask day, the counts by status, what the checks prove and what they do not (the lookup and the copy, not the air series: both sides read one cube), the day boundary and the missing elevation adjustment as limits, the timings. `research/README.md` gains its row; `research/discharge_publish.md`'s naming rule is restated for a second variable, a dataset with no time step and a dataset keyed to a grid, as decided.
- [x] `CLAUDE.md` above the marker: the architecture paragraph for the air tree, its scripts, reports and reader.
- [x] `NEWS.md` bullet under the development heading; `Bump: minor` in the pull request body.
- [x] #216's body: what was built, the reports' counts, and what is still owed.

## Phase 6: The upload, with the pull request open (decision 8(a))

- [ ] Before building: the member re-check of Phase 1, run again.
- [ ] `/planning-archive`, then `/gh-pr-push`; the pull request body says it waits on the owner for the bucket policy and the upload, with the one command to run and what its first line must read.
- [ ] After the owner's upload: the report it rewrote is committed on the branch; `wet_air_daily()` reads one group over HTTPS, timed, the time added to `research/air_temperature_segments.md`.

## Owed at the end (reported, done after merge)

- [ ] `cell_elev_m`, once cd holds the cube's cell elevation (the wet issue Phase 1 files).
- [ ] Under decision 8(b) only: the bucket policy, the upload, the report's commit through a pull request of its own, and the timed read over HTTPS.

## Validation

- [x] Tests pass
- [x] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [x] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved: the reader and the cell rule by the fixture tests, which compare with `cd::cd_extract_daily()`
on a masked copy of cd's own example cube; the catalog change by the existing tests passing unchanged and a
byte-identical discharge manifest and receipt; the built tree by the BUILD's checks, none of which passes through the
code that made the tree (the cell recomputed from the point and the mask, the values read from the cube, the
completeness count), each shown able to fail by a mutation; the build's determinism by a second BUILD with the same
digest; #216's three conditions by the report's tree count and status counts, the station check as decision 9 words it,
and the reader's read of a segment in every watershed group.
