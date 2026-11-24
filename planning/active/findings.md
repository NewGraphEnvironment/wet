# Findings — Backlog move 14: Regulation per non-HYDAT station (#196)

## Issue context

**If we do it:** every station in wet's non-HYDAT registry, provincial and third-party, carries a regulation status from what sits upstream of it, so the natural ones can be donors for departures at ungauged sites (#118). **If we never do:** `wet_station_select()` keeps leaving every non-HYDAT station out as a donor, because unknown is not natural, and the stations moves 8 and 13 bring serve as records and held-out tests only.

Order: `planning/backlog.md`, move 14. Run `/planning-init <this issue>`: one phase, one PR. It starts once move 13 has merged, so the status is computed once, over the provincial and the Tool's stations both.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 14, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

## Batch 16: regulation per non-HYDAT station

**Why here:** one column over the registry move 13 settles; the prerequisite for any non-HYDAT donor. Dams, reservoirs and licensed diversions are placed upstream of each snapped station on the FWA, as `scripts/wb_gauge_diversion.R` places water licences for the calibration gauges.

**Touches:** `R/wet_station_list.R`, `R/wet_station_select.R`, `data-raw/station_sources_snapshot.R`, `inst/extdata/station_sources/`, `research/station_sources.md`, `tests/testthat/test-wet_station_select.R`, and a new placement script with its report under `data/checks/`.

**Decided at the gate:** the rule for natural, regulated and unknown, registered in a script's header before it is applied; which registers enter (the provincial dam register, licensed diversions, reservoirs) and under what licence; whether a status can differ by window (a diversion that runs only in summer); where donor selection reads it.

| issue | title |
|---|---|
| #191 | Regulation per non-HYDAT station, so the natural ones can be donors |

### Carried issue #191

**If we do it:** each station of the province's non-integrated network (and, once #144 lands, the BC Water Tool's third-party stations) carries a regulation status, so the natural ones can serve as donors for departures at ungauged sites (#118). **If we never do:** none of them can be a donor, because `wet_station_select()` leaves out stations whose regulation is unknown, and unknown is not natural.

Today `wet_station_list()` knows regulation only where a station's name says it ("regulated by name": a dam, diversion, intake and similar; 10 provincial stations); every other station is `"unknown"`. Move 8 (#179) brought these stations to `wet_station_daily()` as records and held-out tests only, and left their regulation to this issue.

## To establish

- What upstream of each snapped station regulates its flow: dams (the provincial dam register), reservoirs, and licensed diversions, placed upstream on the FWA as `scripts/wb_gauge_diversion.R` places water licences for the calibration gauges.
- A rule, registered before it is applied, for when a station counts as natural, regulated or unknown, and whether it may differ by window (a diversion that runs only in summer).
- Where the status lives: a column of the station registry `data-raw/station_sources_snapshot.R` writes, read by `wet_station_list()` and by whatever selects donors.

Left out of move 8 (#179, #142).

## Exploration, 2026-11-23 (plan, read-only)

- `wet_station_list()` (`R/wet_station_list.R`) reads the registries' `regulation` column: `"regulated by name"` (from `scripts/station_sources_lib.R`'s `regulation_of()`) or `"unknown"`. Both registries are written by data-raw scripts (`data-raw/station_sources_snapshot.R` step 5; `data-raw/station_sources_bcwatertool.R` line ~252) and the harvest report checks the registries' column against the name rule (`scripts/station_sources_harvest.R` lines 219-220, 384).
- `wet_station_select()` is HYDAT-only: SQL on `STN_REGULATION.REGULATED = 0` and `DLY_FLOWS` complete years. The departure scripts (`scripts/departure_site.R:269`, `scripts/departure_pcic.R:393`) query HYDAT's flag directly for their donor boxes; `wet_window_extend()` takes a `stations` frame "as from `wet_station_select()`".
- `wet_station_snap()` needs `drainage_area_gross_km2` to choose between candidates. Provincial files state no area; 32 of the Tool registry's 53 rows carry `# Drainage Area,<value>` in their file header (21 `None`), measured on the survey's raw copy (`data/station_sources/raw/bcwatertool/`). The Tool's station listing `area` field is -1 throughout.
- #53's method (`scripts/wb_gauge_diversion.R`): WFS layers `WLS_WATER_RIGHTS_LICENCES_SV` and `WRIS_DAMS_PUBLIC_SVW`, paged and held to the server's count; licence rows deduplicated per licensee repeat; classes storage / instream / consumptive by purpose code; placement in FWA watersheds and `fwa_upstream()` on codes, with a stream-position test in the gauge's own reach; flags L ≥ 10 % and S ≥ 10 % of observed runoff.
- Dam register (the cached copy of #53's snapshot, 2026-10-07): 2,490 dams; regulated code Regulated 1,710, `Regulated - Part 3 Exempt` 290, Non-Regulated incl. minor 490; operation Active 2,081, Breached 122, Decommissioned 99, Not Constructed 110, Deactivated 34, Removed 22, Application 22; height median 3 m (165 NA).
- Registries: `bcenv_20261028_hydat.csv` 211 stations; `bcwatertool_20261028_hydat.csv` 53 rows (46 own, 7 continuing a provincial number, which `wet_station_list()` folds into the provincial row).

## Phase 1, 2026-11-24

- **Licences of the registers** [catalogue API `package_search`, read 2026-11-24]: `bc-dams` (`WRIS_DAMS_PUBLIC_SVW`) Open Government Licence - British Columbia; `water-rights-licences-public` (`WLS_WATER_RIGHTS_LICENCES_SV`) "Access Only", publish state PENDING ARCHIVE. The province's copyright page (`www2.gov.bc.ca/gov/content?id=1AAACC9C65754E4D89A118B875E0FBDA`): Data Catalogue material that is "access only" may not be reproduced without written permission. Owner's decision 5: ship derived values only.
- **Successor layer** `water-rights-licences` (`WLS_WATER_RIGHTS_LICENCES_SP`, also Access Only, PUBLISHED) is not on the public WFS: `DescribeFeatureType` returns no fields. The `_SV` layer still answers, 118,717 rows (117,945 on #53's 2026-10-07 snapshot).
- **Tool drainage areas are km^2**: Beatton River at Tommy Lakes Road (Tool) 1852.0 vs HYDAT 07FC008 1851.7 at 0.04 km; Petitot listings 9863.2 and 20410.5 upstream of 10DA001 (22260). 32 of 53 Tool rows state an area; none of the 7 continuing listings does.
- **Code sets in #53's snapshot**: DAM_REGULATED_CODE Regulated 1710 / Regulated - Part 3 Exempt 290 / Non-Regulated - Including Minor Dam 490; DAM_OPERATION_CODE Active 2081, Application 22, Breached (Failed) 122, Deactivated 34, Decommissioned 99, Not Constructed 110, Removed 22; DAM_FUNCTION Conversion 315, Main 1934, Outlet 38, Saddle 171, Spillway 32; LICENCE_STATUS Abandoned 14985, Cancelled 7883, Current 94717, Expired 360. None NA.
- **Border lines** in fwapg: `whse_basemapping.fwa_approx_borders` holds AB_120, USA_49, YTNWT_60 (one line each); no Alaska line, where rivers leave BC rather than enter it.
- **Float edge**: `abs(ratio - 1) <= 0.1` (wet_station_snap()'s comparison) rejects a ratio of exactly 1.1 (1.1 - 1 > 0.1 in doubles); kept as wet_station_snap() has it, tested just inside and outside.

## Phase 2, 2026-11-24

- **WFS snapshot 20261124**: 118,717 licence rows (Current 95,422), 2,485 dams (1,838 regulating for the rule, all located); 70,382 points placed (70,377 fall in an FWA watershed). Run log `data/logs/196/station_regulation_run2.log`, about 50 s from cold (`run1` stopped on a shared licence, Amendment 1).
- **A shared licence with a rediversion POD** (one licence, two purposes, flag M): #53's split halved its quantity at the diversion point and its shared-POD check stopped the first run. Owner's decision: Amendment 1, split over non-rediversion PODs. (Licence identifiers are kept out of tracked text: the layer is Access Only, decision 5.)
- **Snap**: 204 of 257 accepted (name 119, name and area 73, area 12); 43 not snapped name no candidate's stream and state no area, 8 fail the area test on their named stream, 2 have no candidate within 1 km.
- **Status**: natural 92 (67 provincial, 25 Tool), regulated 110, unknown 55 (49 not snapped, 4 outside BC, 2 power).
- **HYDAT's flag at the 58 provincial stations at a HYDAT site** (decides nothing): HYDAT natural 30 (rule 13 natural, 11 regulated, 6 unknown), HYDAT regulated 28 (21 regulated, 6 natural, 1 unknown). The 6 HYDAT-regulated naturals (Deep, Louis x2, Shorts x2, Whiteman) have no regulating dam and use 1-8 %.
- **Rerun from cache**: report and status file byte-identical (`cmp`, run4).
- The shared-POD check is an invariant after Amendment 1 (every term of `candidate` is either in `rg_split_pods()` or constant within a licence-purpose); its test restores #53's split and shows it fire.

## Review round 1, 2026-11-24

- **Groundwater in L and S**: the copied `candidate` has no surface test and the script never applied #53's `base_mask` (`u$surface`), so 9,420 of 67,501 counted rows were wells. Fixed in the script (the rule already said surface). 08GA0005 (44.5 % -> 3.8 %) and 08HA0027 (18.3 % -> 9.1 %) go regulated -> natural.
- **Licence identifiers in tracked text**: the amendment, tests, research, report and findings named a licence number, its POD numbers and quantities, against decision 5. Redacted everywhere, and the five unpushed commits after the registering commit rebuilt so none carries them (old tip kept locally as branch `backup-196-pre-rewrite`, not pushed). The amended rule is now commit 0c6d31ff.
- **No-volume licences**: 1,646 Current surface licence rows that would count state no volume (880 Total Flow, 766 zero or missing). Owner's decision: Amendment 2, such a licence upstream makes an otherwise-natural station unknown. 17 naturals -> unknown.
- **After both**: natural 77 (54 provincial, 23 Tool), regulated 108, unknown 72; HYDAT's flag at the 58 shared sites: HYDAT natural 11/10/9, HYDAT regulated 4 natural (Deep, Shorts x2, Whiteman; use 1-4 %), 21 regulated, 3 unknown. Run log `data/logs/196/station_regulation_run7.log`.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| Script stopped: "cannot read ... at the rule's registering commit" | The full hash had been typed from the short one; taken from `git rev-parse` |
| `local_mocked_bindings()` cannot mock `base::system.file` | Internal `wet_station_sources_path()` the tests mock |
