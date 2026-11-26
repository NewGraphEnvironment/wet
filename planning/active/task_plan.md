# Task: Backlog move 26: A newer provincial pin, Hakai's other watersheds, and a HYDAT gauge continued at its site (#242)

**If we do it:** the provincial record is read from a current copy, Hakai's other four watersheds are stations of their own, and a HYDAT gauge whose record stopped, at a site a provincial station now measures, carries its record into recent years, so a departure there is read from the gauge's own baseline. **If we never do:** the province's revised 2021 months and the months since the pinned copy stay unread, four central-coast records stay unread, and the two records at a shared site stay separate.

Order: `planning/backlog.md`, move 26: one phase per batch. Batch 29 carries #232 and #233; batch 30 carries #227. Whether batch 30 shares this PR is Open decision 5.

## Decided at the gate

### The owner's decisions, from #242's body (2026-11-26), quoted

> 1. **How a caller reads the joined record (#227).** `wet_station_daily()` returns the provincial days after the HYDAT gauge's last federal day under the HYDAT number. Those days keep `source = "bcenv"` and the provincial `status` (`"provisional"` or `"unchecked"`, never `"approved"`). The provincial station is still listed and read under its own number, and `wet_station_list()` gains a column naming the HYDAT gauge each station continues.
> 2. **The same-flow check (#227).** A rule registered before any value is read. Each record's monthly flow is taken as a ratio to the nearest natural HYDAT gauge whose record spans both eras. A pair joins only where the provincial years' median ratio lies inside the range of the HYDAT years' yearly medians. A pair that fails stays unjoined, with the reason reported. (Neither pair overlaps in time, so no direct comparison exists.)
> 3. **The regulation rule (#233).** A dated Amendment 4 to `scripts/station_regulation_rule.R` grows the population to Hakai's stations of their own, with nothing else changed; the registering commit moves with it.
> 4. **Trusting the new pin (#232).** A rule registered before the new copy is read. At each station the #190 portal comparison picked that both copies hold, the new pin's January–September 2021 must equal the portal's on at least 99.9 % of compared hours. Off-the-hour spans are compared against the portal's points within each hour, at the same bar. A station that fails stops the pin and goes back to the owner.
>
> Not yet decided: the snapshot date (the day the files are downloaded, in the gate's draft).

### Mechanism, decided while planning (2026-11-26; the coordinator's plan gate reads them)

- **The portal check reruns on #190's ten picked stations, as a fixed list, and makes no new portal request for them.** `scripts/station_sources_portal.R` gains a new-pin mode, set by `WET_BCENV_SNAPSHOT` other than 20261028. In that mode:
  - the pick is the ten stations of `data/checks/station_sources_portal_20261125.txt`, parsed from the report and asserted to be ten;
  - the window ends at the export's last day, 2026-10-27;
  - a missing cached portal file stops the run (no fetch);
  - the report is named `station_sources_portal_20261125_<date>.txt`, so #190's record is never overwritten.

  The one exception is Open decision 4.
- **The bar's arithmetic is registered with the bar**, in `research/station_sources.md` under "Two copies that part in 2021", committed before any new file is read. These are the definitions owner decision 4 leaves open:
  - A **compared hour** is one where the pinned copy and the portal both hold a point on the hour at that timestamp. A month that one copy holds and the other lacks is "not held" (owner decision 4's "both copies hold"), reported, and not counted.
  - **Equal** is equal at the files' printed precision.
  - The bar is applied **per station over January–September 2021**: at least 99.9 % of that station's compared hours.
  - The **off-the-hour spans** (08HB0031 2023, 08MH0056 2025, 08NM0050 2025–2026, 08NM0054 2026) compare each pinned hour against the portal's points inside that hour, at the same bar.

  The per station-month table is printed, and the verdict reads it. Before registering, the old pin's per-station January–September 2021 share is computed from the cached 20261028 copy, which is already-read data, and quoted beside the bar.
- **Order of the pin.** The run builds the pin locally, checks it against the portal, and only then backs it up and commits:
  1. Download the files.
  2. Run `data-raw/station_sources_snapshot.R` with `WET_STATION_SOURCES_RAW` set to the new directory and no `WET_BACKUP`. This writes the manifest, seeds the cache and writes the registry, all uncommitted. Under `load_all`, `system.file()` reads the source tree.
  3. Run the portal check.
  4. On a pass, rerun with `WET_BACKUP=1`, then commit and move `wet_bcenv_snapshot`.
  5. On a fail, delete the uncommitted manifest and registry, stop, and write the failing stations under `## Open decisions` (owner decision 4).
- **The pin script refuses a snapshot whose files are already pinned:** one whose md5 set equals any tracked `bcenv_*.csv` manifest's. It also requires `WET_STATION_SOURCES_RAW` for any snapshot other than the survey's, so a new date can never pin the survey's copy.
- **The fetch is recorded:** the directory listing's URL, its md5, each file's URL and the UTC download time, in `data/station_sources/raw/bcenv_<date>/fetch.tsv` and in the harvest report.
- **Amendment 4 names the population by rule only:** the provincial registry, the Tool's own listings, and Hakai's rows with no `continues`. It carries no counts, so it can be registered before the new registry exists. The counts go in the regulation report.
- **The regulation rerun reuses the WFS snapshot 20261124** (`WET_REG_SNAPSHOT=20261124`, cached on m1), so it makes no WFS request.
  - The report attributes each status that moves from the 20261028 run to one cause: a new or dropped station, a moved point or changed name in the registry, the published-flow catalog digest (printed beside the 20261028 run's), or a snap that moved under the same inputs.
  - The four Hakai stations are expected to be `unknown`, as the three continued ones are: their names carry no stream, and the rule takes an area only from a Tool header or a HYDAT site. The report asserts and prints their statuses. It does not assume them.
- **The regulation file records the Hakai registry** as two more columns, `hakai_version` and `hakai_registry_md5`, and `wet_station_regulation()` holds the file to all three registries.
- **Hakai identity is classified against the new pin:** each of the seven watersheds, by the existing rule (number `H08KC%04d`, the watershed named, 0.5 km). A match is a continuation. A watershed with no match is a station of its own, numbered as Open decision 3 says. The names for own rows come from the package README's Table 1, since there is no provincial name to take.
- **The new helpers go in their own lib files.** Portal helpers move to a new `scripts/station_sources_portal_lib.R`, which a test sources. They do not go in `scripts/station_sources_lib.R`, which the regulation script hashes against its rule commit.
- **The harvest splits by snapshot:**
  - Tier (i), provincial and Tool, reproduces the survey on an explicit `survey_snapshot <- "20261028"`.
  - The Tool "shared sites" check recomputes the survey's same-site rule on 20261028 instead of comparing it with the shipped registry.
  - Tier (ii) and the registry holds run on `wet_bcenv_snapshot`.
  - A new section lists what the new pin moves: stations, days, window-years and passing stations, per station.
  - The report is `station_sources_harvest_<date>.txt`.
- **The bound report is renamed** `station_sources_bound_20260717_<date>.txt`, so the 20260717 record stays. A registered expected catch that fails on the new pin stops the run and goes to the owner.
- **Batch 30's table is per snapshot:** `inst/extdata/station_sources/hydat_continue_<date>.csv`. It carries `bcenv_snapshot`, `bcenv_days` and the HYDAT release, and is held to them as `wet_registry_against()` holds a registry. An internal `wet_hydat_continue(snapshot)` returns zero rows where no table exists, so an older snapshot does not error.
- **Where the work runs: m1.** m1 holds the provincial, Tool, portal, Hakai and WFS caches, fwapg and HYDAT 20260717.

### Stop-and-ask conditions (each goes under `## Open decisions`, and nothing that depends on it runs)

- The new pin holds a grade outside `wet_bcenv_grades`, or an archive name `wet_bcenv_order()` cannot place. A new grade decides day status and means bumping `wet_bcenv_reader`, which also moves 20261028's days key.
- Hakai's four own watersheds carry a quality code outside `wet_hakai_codes`.
- A portal station fails the bar (owner decision 4), or a bound catch fails.

## Open decisions

1. **The snapshot date** (the owner left it undecided). *Recommended:* the UTC date the province's files are downloaded, `YYYYMMDD`, the convention 20261028 already follows. Any other date would name a copy by a day it was not taken.
2. **What happens to the 20261028 pin** once a newer one ships (stored data: what the package reads and keeps). The Tool and Hakai registries and the regulation status are each built against one provincial snapshot.
   - (a) *Recommended:* the new pin becomes `wet_bcenv_snapshot`; its manifest, registry and regulation file ship, and the Tool and Hakai registries are rebuilt against it.
     - The 20261028 manifest and provincial registry stay shipped. The harvest can then still reproduce the survey (tier i) and say what the new pin moves. `regulation_20261028.csv` is removed.
     - Cost: `wet_station_list(snapshot = "20261028")` refuses. New code makes its message name the shipped pin, and a test covers it. `wet_station_daily(snapshot = "20261028")` still reads `"bcenv"` but skips `"bcwatertool"` and `"hakai"` with a warning.
     - `scripts/departure_donors.R`, which refuses any other snapshot and reads `regulation_20261028.csv` by path, stays as #211's record, reproducible at its commit.
   - (b) Drop 20261028 entirely. The harvest's survey tier then runs only from that commit.
   - (c) Keep both fully readable, by renaming the Tool and Hakai registries per provincial snapshot. That changes their file names and every reader.
3. **The number Hakai's own stations go by** (a stored identifier). This covers whichever of 693, 708, 819 and 1015 the new pin does not hold as an `H08KC` station.
   - (a) *Recommended:* the package's own `WTS693`, `WTS708`, `WTS819` and `WTS1015`, the registry key the continued rows already use.
   - (b) The province's pattern, `H08KC0693` and so on. The Water Tool already lists `H08KC1015` as a BC ENV station, so a later provincial pin could put one number in two registries, which the registry check refuses.
4. **The off-the-hour spans against a portal export taken 2026-11-25.** Owner decision 4 holds them to 99.9 %. But the province was still revising 2026 at the export (80–91 % agreement a month from June 2026, `data/checks/station_sources_portal_20261125.txt`), so a 2026 span can fail because the province revised it after the export, not because the pin is wrong.
   - (a) *Recommended:* a fresh portal export of the four off-hour stations on the pin's own day. That is four requests to a host whose robots.txt is empty, under the disclaimer the owner accepted for #190.
   - (b) Hold only the months through May 2026 to the bar, and report the later ones.
   - (c) Report the off-hour spans without letting them decide.
5. **Batch 30 in its own PR** (scope).
   - (a) *Recommended:* this PR carries batch 29. Batch 30 (#227) builds in a second PR from main after this one merges, under the same plan and owner decisions 1 and 2. Batch 29 alone is a download, an S3 backup, a go/no-go stop, a regulation rerun, a rewrite of the 555-line harvest, schema changes in three readers, a sweep of five test files and six tracked reports. Batch 30 adds a registered rule, a new script, a new column and a change to an exported function. The new pin adds little to #227's pairs: 08JC0002 ends in 2020, and 08NH0001 gains about a month.
   - (b) One PR for both, as the backlog says.

## Phase 1: Batch 29: a newer provincial pin, and Hakai's other four watersheds (#232, #233)

- [ ] Before building: `bash "$T/skills/_shared/members_check.sh" "$(git remote get-url origin)" 242 242-backlog-move-26-a-newer-provincial-pin-h --batch 29` (T from `soul_published_tree`). On a non-zero exit or any line but `FREE`, build nothing of this batch: write the line under `## Open decisions` and stop.
- [ ] Registered first, in one commit before any new file is read:
  - the bar and its arithmetic, in `research/station_sources.md`, with the old pin's per-station January–September 2021 shares quoted;
  - Amendment 4, dated, in `scripts/station_regulation_rule.R` (population only, no counts).
- [ ] Download every `Discharge*.csv` the province's directory lists into `data/station_sources/raw/bcenv_<date>/` (m1, main checkout), and write `fetch.tsv` there. Run the grade and archive-name stops first: `wet_bcenv_order()` on the names, and the distinct grades against `wet_bcenv_grades`.
- [ ] `data-raw/station_sources_snapshot.R`: require `WET_STATION_SOURCES_RAW` for a non-survey snapshot, and refuse an md5 set already pinned. Run it with no backup to build the manifest, cache and registry locally (uncommitted).
- [ ] The portal check, which is the gate. Move the helpers to `scripts/station_sources_portal_lib.R`, with a test that sources it (the report name, the fixed pick, the window cap, and a refusal on a missing cached file). Add the new-pin mode and the verdict per the registered bar. Run it.
  - On a fail: delete the local manifest and registry, write the failing stations under `## Open decisions`, and stop the phase.
- [ ] On a pass: rerun the pin with `WET_BACKUP=1` and check the backup's ETags. Then, in one commit:
  - the manifest and registry;
  - the portal report;
  - `wet_bcenv_snapshot` moved to `<date>`;
  - the test sweep the move requires. Every fixture that stamps `bcenv_snapshot = "20261028"` under the default snapshot switches to `wet_bcenv_snapshot` and `wet_bcenv_days_key(wet_bcenv_snapshot)`:
    - `helper-bcwatertool.R:61,63`;
    - `test-wet_station_daily.R:390-393, 458-459, 472-473, 497, 511, 567-571, 583-585, 632-634`;
    - `test-wet_station_list.R:65-70, 183-187`.
  - Shipped file names come from `wet_bcenv_snapshot` (`test-wet_station_list.R:101,130-140`).
  - The counts that move are re-measured and asserted:
    - 211/46 at `test-wet_station_list.R:64,74,83`;
    - 58 at `:121`;
    - the moved set at `:93-95`;
    - the 8 files at `test-wet_bcenv.R:45`;
    - `test-wet_bcwatertool.R:101-104,116`;
    - the live Hakai test's dates at `test-wet_station_daily.R:700-716`.
  - New tests: the shipped manifest is not 20261028's, and `max(wet_station_list("bcenv")$last) > as.Date("2026-10-27")`.
- [ ] Rebuild the Tool registry (`data-raw/station_sources_bcwatertool.R`, `WET_BCWATERTOOL_RAW`) against the new pin, then the Hakai registry. The Hakai script reads the Tool registry, so the order matters.
- [ ] #233 in code, tests first, in `test-wet_station_list.R` and `test-wet_station_daily.R`, with fixtures for an own Hakai row:
  - `wet_hakai_stations()` accepts rows with no `continues`, and requires `continues_before` to be NA exactly there;
  - `wet_hakai_station_days()` returns an own station's days under its own number;
  - `wet_station_list()` lists own Hakai rows: source `"hakai"`, `hydat_site`/`hydat_km` NA, `licence` "CC-BY 4.0", regulation via `wet_regulation_of(status, ..., "hakai")`, ordered by source and number;
  - the existing duplicate check gets a test for an own Hakai number another registry holds;
  - the headers of `R/wet_hakai.R` and `data-raw/station_sources_hakai.R`, and both functions' roxygen, describe own stations; `man/` is regenerated.
- [ ] `data-raw/station_sources_hakai.R`: classify the seven watersheds against the new registry by the identity rule. Write own rows (numbers per Open decision 3, names and coordinates from README Table 1) with `first` and `last` from the reader. Rerun it.
- [ ] Rerun the regulation status:
  - `scripts/station_regulation.R`: Hakai's own rows join the population (`registry = regulation_of(name)`, `hydat_site` NA), the third registry is added to `reg_path`/`reg_md5`, and the call becomes `wet_registry_check(..., hakai = )`;
  - fix the report's source label, which calls Hakai "tool" at `:329` and `~:407`;
  - write `hakai_version` and `hakai_registry_md5`, and move `rule_commit` to Amendment 4's commit;
  - `wet_station_regulation()` holds all three registries, with a test that a mismatched `hakai_registry_md5` refuses;
  - add the Open decision 2 refusal message and its test;
  - rerun with `WET_REG_SNAPSHOT=20261124` and write `regulation_<date>.csv` and `data/checks/station_regulation_<date>.txt`, with each moved status attributed.
- [ ] Reports:
  - `scripts/station_sources_bound.R`, renamed report, catches held;
  - `scripts/station_sources_harvest.R`, split as decided, with the "what the new pin moves" section and the fetch record;
  - `scripts/station_sources_hakai.R`, extended to the own stations: days, status shares, window-years and the station test (which may come out 0).

  The proof for each is its registry-against-reader holds, which exit 1 on a difference. A rerun reproduces each byte for byte.
- [ ] Update:
  - `research/station_sources.md`: "The answer", "Two copies that part in 2021", "The provincial files in wet", "The Hakai package in wet" and "Regulation per non-HYDAT station";
  - `CLAUDE.md`'s station-source lines: the snapshot, Hakai, the portal report name, and `departure_donors.R` as a record at its commit;
  - `NEWS.md`.

## Phase 2: Batch 30: a HYDAT gauge continued by the provincial station at its site (#227)

This PR, or a second one from main after this one merges, as Open decision 5 settles.

- [ ] Before building: `bash "$T/skills/_shared/members_check.sh" "$(git remote get-url origin)" 242 <branch> --batch 30`. On a non-zero exit or any line but `FREE`, build nothing of this batch: write the line under `## Open decisions` and stop.
- [ ] Register owner decision 2's rule in the header of a new `scripts/station_hydat_continue.R`, committed before the script reads any value, with its mechanics:
  - **Candidates:** provincial stations whose `hydat_site` is a natural HYDAT gauge (`REGULATED = 0`) with a 1981–2010 baseline (`wet_station_select()`'s test), and whose HYDAT record ends before the provincial one begins.
  - **"Nearest":** Albers distance between the gauges.
  - **"Spans both eras":** the reference holds complete months in both the HYDAT pair's years and the provincial station's years, which also defines a complete month and which provincial years count, given HYDAT 20260717's last approved year.
  - **Verdict:** the provincial years' median monthly ratio lies inside the range of the HYDAT years' yearly medians.
  - **If both pairs fail:** the table ships with its verdicts and nothing is joined; the code and tests still land.

  Expected candidates: 08NJ168/08NH0001 and 08JC017/08JC0002.
- [ ] Run it on the new pin. Write `inst/extdata/station_sources/hydat_continue_<date>.csv` (`station_number`, `hydat_number`, `hydat_last`, `verdict`, `reason`, `bcenv_snapshot`, `bcenv_days`, `hydat_release`) and `data/checks/station_hydat_continue_<date>.txt`. The report includes the Chinook window-years each joined pair gains.
- [ ] `wet_station_daily()`, per owner decision 1, tests first:
  - the join comes from internal `wet_hydat_continue(snapshot)` (zero rows with no table), inside its own `wet_daily_try("bcenv", ...)` after the realtime block;
  - the cut is the later of `hydat_last` and the last day `out` holds for that station, through `wet_daily_after()`, so the cut is the same whichever sources are asked;
  - tests: continued after HYDAT's last day; nothing before it; not continued without `"bcenv"`; `sources = "bcenv"` alone; a failed pair is not continued; asking for both numbers returns each under its own number; a fixture HYDAT day after `hydat_last` is not duplicated; the `hydat -> bcenv` gap warning;
  - the description, `@param sources` and `@param snapshot` docs say a HYDAT number now opens the provincial snapshot when a joined pair exists, and that a caller without the provincial cache sees a skipped-source warning.
- [ ] `wet_station_list()` gains the column naming the HYDAT gauge each station continues (`continues_hydat`; NA without a table or a joined pair), in `wet_station_list_empty()`, `@return` and the `expect_named` tests (`test-wet_station_list.R:62-63,190`). The docs no longer say the two records are never joined.
- [ ] Update `research/station_sources.md` (a section on HYDAT records continued, with the measured verdicts), `CLAUDE.md` and `NEWS.md`.

## Validation

- [ ] Tests pass (`devtools::test()`; `NOT_CRAN=true` on any single-file rerun)
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] `lintr::lint_package()` adds no lint per file against `origin/main`; `pkgdown::check_pkgdown()` passes
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:
- **The pin:** the manifest's md5s equal the downloaded files and the backup's ETags, and `wet_bcenv()` holds the cache to them. Tests that can fail: the shipped manifest is not 20261028's, and the province's last day is after 2026-10-27.
- **The portal:** the verdict reads the printed per-station table against the bar registered before the files were read.
- **The registries:** the harvest's tier (i) reproduces the survey on 20261028. The registry-against-reader holds in the harvest, the Hakai report and the regulation report exit 1 on any difference.
- **#233:** `wet_station_list("hakai")` returns exactly the own stations, and `wet_station_daily("<own number>", sources = "hakai")` returns their days under that number. The regulation report prints their statuses.
- **#227:** the continue report shows the verdict and the window-years each pair gains, and the fixture tests above cover the join, the cut and the refusal.
