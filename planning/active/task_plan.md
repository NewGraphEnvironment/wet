# Task: Backlog move 26: A newer provincial pin, Hakai's other watersheds, and a HYDAT gauge continued at its site (#242)

**If we do it:** the provincial record is read from a current copy, Hakai's other four watersheds are stations of their own, and a HYDAT gauge whose record stopped, at a site a provincial station now measures, carries its record into recent years, so a departure there is read from the gauge's own baseline. **If we never do:** the province's revised 2021 months and the months since the pinned copy stay unread, four central-coast records stay unread, and the two records at a shared site stay separate.

Order: `planning/backlog.md`, move 26: one phase per batch. Batch 29 carries #232 and #233; batch 30 carries #227. Batch 30 goes in a second PR (answer 5).

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

  The one exception is answer 4: the four off-hour stations are exported afresh on the pin's day.
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
  5. On a fail, delete the uncommitted manifest and registry, stop, and write the failing stations under `### The owner's answers to the plan's open decisions (2026-11-27, at the resume)

1. **The snapshot date** is the UTC date the province's files are downloaded, `YYYYMMDD`.
2. **The 20261028 pin:** the new pin becomes `wet_bcenv_snapshot`; its manifest, registry and regulation file ship, and the Tool and Hakai registries are rebuilt against it. The 20261028 manifest and provincial registry stay shipped, so the harvest still reproduces the survey (tier i); `regulation_20261028.csv` is removed. `wet_station_list(snapshot = "20261028")` refuses with a message naming the shipped pin (tested); `wet_station_daily(snapshot = "20261028")` reads `"bcenv"` and skips `"bcwatertool"` and `"hakai"` with a warning. `scripts/departure_donors.R` stays #211's record, reproducible at its commit.
3. **Hakai's own stations** go by the package's keys: `WTS693`, `WTS708`, `WTS819`, `WTS1015` (whichever the new pin does not hold as an `H08KC` station).
4. **The off-the-hour spans** are checked against a fresh portal export of the four off-hour stations (08HB0031, 08MH0056, 08NM0050, 08NM0054) taken on the pin's own day: four requests, under the disclaimer accepted for #190. The other six stations use the cached 2026-11-25 export, with no request.
5. **Batch 30 (#227) goes in a second PR** from main after this one merges, under this plan and owner decisions 1 and 2. This PR carries batch 29; Phase 2 is not built here.
6. **No new provincial pin in this PR** (the owner's answer, 2026-11-27, after the bar was found failing before the pin was built). The province's `Discharge_Archive_2019Oct_2021Oct.csv` is byte-identical to the 20261028 pin's (md5 `d48e0443…`, Last-Modified 2023-06-09), so a newer pin carries the old January–September 2021 and fails the registered bar at 08MH0054 (3.2 %), 08NM0004 (1.6 %), 08MH0056 (0.03 %) and 08NM0002 (0.0 %). Only `Discharge.csv` and `Discharge_Archive_Post_20251001.csv` changed. This PR ships #233 against the 20261028 pin; #232's body records the measurement and waits until the province republishes that archive. Answers 1, 2 and 4 then have nothing to act on: they stand for #232 when it resumes.


## Phase 1: Batch 29, rescoped to Hakai's other four watersheds (#233; #232 waits, answer 6)

- [x] Before building: `bash "$T/skills/_shared/members_check.sh" "$(git remote get-url origin)" 242 242-backlog-move-26-a-newer-provincial-pin-h --batch 29` (T from `soul_published_tree`). On a non-zero exit or any line but `FREE`, build nothing of this batch: write the line under `## Open decisions` and stop.
- [x] Registered first, in one commit before any new file is read:
  - the bar and its arithmetic, in `research/station_sources.md`, with the old pin's per-station January–September 2021 shares quoted;
  - Amendment 4, dated, in `scripts/station_regulation_rule.R` (population only, no counts).
Rescoped by answer 6: #233 against the 20261028 pin. The pin's tasks (download, pin guards, portal gate, backup, constant move and test sweep, Tool rebuild, harvest split, bound rename, the 20261028 refusal message) are not built; they stay #232's.

- [x] Hakai's four other watersheds, registered before any of their days is counted (`research/station_sources.md`, "The Hakai package in wet"): an hour whose `Qrate` is `NA` is no value and is dropped (one hour, WTS708 2013-09-08T16:00, `SVC` at sensor installation; the reader refused it); WTS708's position from Korver et al. (2022) Table A1 (SSN708), since README Table 1 repeats WTS693's for it.
- [x] #233 in code, tests first, in `test-wet_station_list.R` and `test-wet_station_daily.R`, with fixtures for an own Hakai row:
  - `wet_hakai_hours()` drops an `NA` `Qrate` hour;
  - `wet_hakai_stations()` accepts rows with no `continues`, and requires `continues_before` to be NA exactly there;
  - `wet_hakai_station_days()` returns an own station's days under its own number;
  - `wet_station_list()` lists own Hakai rows: source `"hakai"`, `hydat_site`/`hydat_km` NA, `licence` "CC-BY 4.0", regulation via the regulation file, ordered by source and number;
  - the existing duplicate check gets a test for an own Hakai number another registry holds;
  - the headers of `R/wet_hakai.R` and `data-raw/station_sources_hakai.R`, and both functions' roxygen, describe own stations; `man/` is regenerated.
- [x] `data-raw/station_sources_hakai.R`: classify the seven watersheds against the 20261028 provincial registry by the identity rule (number `H08KC%04d`, the watershed named, 0.5 km); a match continues, none is a station of its own under `WTS<n>` (answer 3), named as the continued rows are, positioned from README Table 1 (WTS708 from Table A1), `first` and `last` from the reader. Rerun it; the three continued rows must come back unchanged.
- [ ] Rerun the regulation status:
  - `scripts/station_regulation.R`: Hakai's own rows join the population (`registry = regulation_of(name)`, `hydat_site` NA), the Hakai registry is added to `reg_path`/`reg_md5`, and the call becomes `wet_registry_check(..., hakai = )`;
  - fix the report's source label, which calls Hakai "tool";
  - write `hakai_version` and `hakai_registry_md5`, and move `rule_commit` to Amendment 4's commit (82aa3f24);
  - `wet_station_regulation()` holds all three registries, with a test that a mismatched `hakai_registry_md5` refuses;
  - rerun with `WET_REG_SNAPSHOT=20261124`, rewriting `regulation_20261028.csv` and `data/checks/station_regulation_20261028.txt`; assert the 257 earlier statuses unchanged (or attribute each that moved) and print the four Hakai statuses.
- [ ] Reports: `scripts/station_sources_hakai.R` extended to the own stations (days, status shares, window-years, the station test); the harvest's registry holds rerun if they read the Hakai registry. A rerun reproduces each byte for byte.
- [ ] Update `research/station_sources.md` ("The answer", "The Hakai package in wet", "Regulation per non-HYDAT station", "Two copies that part in 2021" with the unchanged archive), `CLAUDE.md`'s Hakai and regulation lines, `NEWS.md`; #232's body records why it waits.

## Phase 2: Batch 30: a HYDAT gauge continued by the provincial station at its site (#227)

Not built in this PR: a second PR from main after this one merges (answer 5).

- [ ] Before building: `bash "$T/skills/_shared/members_check.sh" "$(git remote get-url origin)" 242 <branch> --batch 30`. On a non-zero exit or any line but `FREE`, build nothing of this batch: write the line under `## Open decisions` and stop.
- [ ] Register owner decision 2's rule in the header of a new `scripts/station_hydat_continue.R`, committed before the script reads any value, with its mechanics:
  - **Candidates:** provincial stations whose `hydat_site` is a natural HYDAT gauge (`REGULATED = 0`) with a 1981–2010 baseline (`wet_station_select()`'s test), and whose HYDAT record ends before the provincial one begins.
  - **"Nearest":** Albers distance between the gauges.
  - **"Spans both eras":** the reference holds complete months in both the HYDAT pair's years and the provincial station's years, which also defines a complete month and which provincial years count, given HYDAT 20260717's last approved year.
  - **Verdict:** the provincial years' median monthly ratio lies inside the range of the HYDAT years' yearly medians.
  - **If both pairs fail:** the table ships with its verdicts and nothing is joined; the code and tests still land.

  Expected candidates: 08NJ168/08NH0001 and 08JC017/08JC0002.
- [ ] Run it on the shipped provincial pin. Write `inst/extdata/station_sources/hydat_continue_<date>.csv` (`station_number`, `hydat_number`, `hydat_last`, `verdict`, `reason`, `bcenv_snapshot`, `bcenv_days`, `hydat_release`) and `data/checks/station_hydat_continue_<date>.txt`. The report includes the Chinook window-years each joined pair gains.
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
