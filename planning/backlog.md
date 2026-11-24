# wet backlog: move order

**Verified:** 2026-11-10 against 35 open issues · **Produced by:** a read of every open issue
body (`gh issue list --state open`) and its comments · each older premise grepped against the
tree at b783bc9 (#55: `R/wet_station_snap.R` still says `fresh::frs_point_snap()` wraps the snap;
#74: `data-raw/segment_vignette_data.R` and `data-raw/segment_vignette_map.R` load httpfs without
installing it; #51: `scripts/wb_inputs.R` and `scripts/wb_term_diagnose.R` drop only NA periods;
#108: the live manifest, built 2026-10-24 at b4bbc50, gives the clamp but not the February fold;
#23: the CGIAR and DEM cache keys hold the grid and method only) · the province run key
(`scripts/wb_province.R` hashes the input file names) and `scripts/wb_score_md5.R`'s hashed files,
which decide which changes stale the fit · open issues and pull requests in crate, fwapg, knowledge
and link on each batch's subject

**Verified:** 2026-11-22 against 24 open issues · **Produced by:** a read of every open issue the file did
not place (#171, #176, #177, #178, #181, #182) and its comments, and #67, open after move 4 merged · each premise
grepped against the tree at ddfae39 (#171: `scripts/segment_daily_output.R`'s `own` still lacks `R/wet_segment_daily.R`,
`scripts/vignette_data_lib.R` and `scripts/segment_group.R`; #177: neither segment reader returns `pick`) · soul's
`research_check.sh` (four files flagged as grown into logs: `water_balance_method.md`, `discharge_publish.md`,
`station_flow_departure.md`, `monthly_error.md`) · open issues and pull requests in knowledge, fwapg and fresh on each
new batch's subject

**Verified:** 2026-11-23 against 34 open issues · **Produced by:** a read of every open issue the file did
not place (#190, #191, #192, each split from move 8 at its plan gate) and its comments, and #144's body, edited at the
same gate to say it was split from move 8 too · each premise grepped against move 8's branch (`research/station_sources.md`,
"Two copies that part in 2021" and "Also found"; `R/wet_station_select.R` leaves out stations with no HYDAT regulation
record) · the tree unchanged since ddfae39 but for this file · soul's `research_check.sh` (the same four files flagged,
each already carried by #181, #183, #184 or #185) · open issues and pull requests across the organisation on the provincial
portal, Hakai, station regulation and the station list (none outside this repository)

How to use this file: `/backlog-sweep` writes it. Take the first move in **Moves** that is not
ticked and not **waiting**; `/planning-init <umbrella>` plans it, one phase per batch, one PR.
A move that waits only on other moves is `open`, with them in `waits on`; `**waiting**` is for
a blocker outside this file (the owner, another repo, a PR, a count).
When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue, naming the move it was split from, and leaves it out of this file: the next `/backlog-sweep` reads an issue the file does not name as unplaced, and folds it into a move other than the one it was split from.
`/gh-pr-merge` step 9c ticks the move on merge, and opens a move `**waiting** on PR #N` (this
repo's PR, and no other condition) when that PR merges; `/compact-prep` names the next, skipping a
move whose `waits on` names a move not yet ticked. A plan that defers one of its batches sets that
section's first line to `- [ ] Not yet in a move`: the tick leaves it open and says so, and `next`
names it once the move is done, for the next pass to place. A `NONE` from
`backlog_moves.sh next` that names batch sections means those batches have no move yet, and a
plain `NONE` is not the end either while an open issue is named nowhere here (`/compact-prep`
counts them): run `/backlog-sweep` again, the backlog is not finished.

## Moves

| move | umbrella | batches | state | lane | waits on | model |
|---|---|---|---|---|---|---|
| - [x] 1 | #163 | 1, 2: province inputs and run comparison, the fit's own rules (6 issues) | done: https://github.com/NewGraphEnvironment/wet/pull/170 | — | — | — |
| - [x] 2 | #164 | 3: the published build's record (4 issues) | done: https://github.com/NewGraphEnvironment/wet/pull/172 | — | — | — |
| - [x] 3 | #165 | 4, 5: article bundles and maps, docs (4 issues) | done: https://github.com/NewGraphEnvironment/wet/pull/173 | — | — | — |
| - [x] 4 | #166 | 6: monthly error at the gauges (3 issues) | done: https://github.com/NewGraphEnvironment/wet/pull/175 | — | — | — |
| - [x] 5 | #167 | 8: PCIC's per-year files at the sites (2 issues) | done: https://github.com/NewGraphEnvironment/wet/pull/180 | — | — | — |
| - [x] 6 | #168 | 9: the channel-scale pilot (1 issue) | done: https://github.com/NewGraphEnvironment/wet/pull/193 | A | — | opus |
| - [ ] 7 | #169 | 10: scenarios and coverage (2 issues) | **waiting** on move 6's verdict in `research/pcic_channel_scale.md` | A | 6 | fable then opus |
| - [x] 8 | #179 | 7: stations beyond HYDAT (1 issue) | done: https://github.com/NewGraphEnvironment/wet/pull/194 | B | — | opus |
| - [x] 9 | #186 | 11: the readers return pick, one list of non-inputs (2 issues) | done: https://github.com/NewGraphEnvironment/wet/pull/197 | C | — | sonnet |
| - [ ] 10 | #187 | 12: Swift and Naver creeks under their own windows (1 issue) | **waiting** on knowledge#256 (the owner, 2026-11-23: adopt the UFRA and COTR windows only once knowledge reads NuSEDS dates) | D | — | opus |
| - [x] 11 | #188 | 13: small-basin error and the zone adjustment (4 issues) | done: https://github.com/NewGraphEnvironment/wet/pull/200 | E | — | fable then opus |
| - [ ] 12 | #189 | 14: research files around the current state (3 issues) | open | D | 10 | sonnet |
| - [x] 13 | #195 | 15: second sources for the provincial stations (1 issue) | done: https://github.com/NewGraphEnvironment/wet/pull/201 | B | 8, 9 | opus |
| - [ ] 14 | #196 | 16: regulation per non-HYDAT station (1 issue) | open | B | 13 | fable then opus |

Tracks are separate efforts, not moves: the cross-repo provenance track, whose wet member is #161
(labelled `track:provenance`), batched here in batch 3 because #88 and #160 take its names.

## Order

| # | tracking | batch | issues | gate | why here |
|---|---|---|---:|---|---|
| 1 | #163 | province inputs and run comparison: #23, #51, #24, #21 | 4 | the DEM's key; whether the compare script replaces `scripts/wb_upstream_order.R` | new cache keys change the province run key, so the whole chain reruns once, with the compare script as its oracle |
| 2 | #163 | the fit's own rules: #158, #47 | 2 | a tolerance on the zero-distance test; the main-stem gate's rule, registered before scoring; whether the override retires | both change hashed scoring code, so each stales the fit; one rescore carries both |
| 3 | #164 | the published build's record: #108, #161, #88, #160 | 4 | the receipt in place of the manifest or beside it; the load table's schema; which parts of the fit are published | one format change and one PUBLISH of the manifest, receipt and fit; the parts' bytes do not change |
| 4 | #165 | article bundles and maps: #74, #155 | 2 | which layers move onto fresh's fetchers; the layer comparison's tolerance | one regeneration of `inst/vignette-data/` against one live build |
| 5 | #165 | docs: #97, #55 | 2 | none beyond the README decisions already recorded | no build of their own; the site rebuilds with move 3 |
| 6 | #166 | monthly error at the gauges: #6, #67, #162 | 3 | tracked report or article section; the region unit; the owner approves any text sent to PCIC | one report over the same held-out balance, routed PCIC and observed months |
| 7 | #179 | stations beyond HYDAT: #142, #144 | 2 | keep, flag or drop ungraded values; which copy at shared sites; credit lines | both feed `wet_station_daily()` and meet at six sites; split from #167, where they add no donor at the chinook sites |
| 8 | #167 | PCIC's per-year files at the sites: #135, #147 | 2 | the `covariance_pick` rule at the sites, registered before any run | `covariance_pick` at the sites needs the per-year files at every run |
| 9 | #168 | the channel-scale pilot: #9 | 1 | the six sites; whether it also reads water temperature | the oracle batch 10 waits on |
| 10 | #169 | scenarios and coverage: #4, #5 | 2 | CMIP6 channel-scale, CMIP5 or both by domain; publish scenarios as a new dataset or not | both rescope from batch 9's verdict |
| 11 | #186 | the readers return pick, one list of non-inputs: #177, #171 | 2 | fix #171 now (one daily rerun and BUILD) or defer it; `pick`'s place in both readers | the publish side's readers and guards; #177 edits a file #171's list lacks |
| 12 | #187 | Swift and Naver creeks under their own windows: #182 | 1 | the knowledge commit to pin; a guard that the Bulkley and Morice chinook rows match `c97c4d0`'s | moves wet's one pin on the life history table, which every Bulkley and Morice reader follows |
| 13 | #188 | small-basin error and the zone adjustment: #176, #178, #44, #185 | 4 | the rule, registered before any candidate is scored; which candidates; the hosted WALLY tool only where its terms allow | one oracle, the held-out balance at the gauges; both candidates change the zone adjustment and share one rescore |
| 14 | #189 | research files around the current state: #181, #183, #184 | 3 | none beyond #181's revise-in-place rule | one method over the files soul's research check flags; waits on move 10 for `research/chinook_sites.md` |
| 15 | #195 | second sources for the provincial stations: #144 | 1 | which copy at the six shared sites, and one rule for a second publisher's earlier record under a provincial number; whether the province's portal is read (its click-through disclaimer is the owner's to accept); Hakai's record from its published data package or by request (outward contact, through the owner) | one chaining rule in `wet_station_daily()` and one registry and snapshot rebuild serve all three; #190 says which provincial copy is current before the Tool's copy is set beside it; all three split from move 8 |
| 16 | #196 | regulation per non-HYDAT station: #191 | 1 | the natural, regulated and unknown rule, registered before it is applied; which registers; whether a status can differ by window | one column over the registry batch 15 settles, provincial and Tool stations both; the prerequisite for any non-HYDAT donor (#118) |

### 1. Province inputs and run comparison

- [x] Carried by move 1, #163 (merged in https://github.com/NewGraphEnvironment/wet/pull/170)

#23 keys the CGIAR crop and the DEM on their source data, which renames those inputs and so
changes the province run key: the whole chain (rescore every variant, compare, `wb_validate.R`,
outputs, segment tables, BUILD, PUBLISH) reruns under a new key. #24's committed comparison script
is the oracle that the new run holds the same values, and the same run closes the byte-for-byte
report check #21 left open. `scripts/wb_inputs.R` reruns here anyway, so #51's climr check rows are
fixed in the same pass. #21 and #24 cover a failure that has already happened twice: a first-draft
run comparison passed when it should have failed (in the work for #18 and #19).

Touches `R/wet_cgiar_aet.R`, `R/wet_dem_glo90.R`, `scripts/wb_inputs.R`,
`scripts/wb_term_diagnose.R`, a new `scripts/wb_run_compare.R`, `data/checks/`. Gate: the DEM's key
(tile list with ETags or sizes, or a pinned snapshot); whether the compare script replaces
`scripts/wb_upstream_order.R`.

### 2. The fit's own rules

- [x] Carried by move 1, #163 (merged in https://github.com/NewGraphEnvironment/wet/pull/170)

#158 (donor shares at a calibration gauge turn on an exact-zero distance) makes every rebuild by
another route differ from the published values at calibration gauges, the group builds of #157
among them. #47 scores the main stems in the gate; the shipped fit keeps its zone adjustment only
through a recorded override. Both change files `scripts/wb_score_md5.R` hashes, so each stales the
fit; under one rescore they cost one chain.

Touches `R/wet_donor_mean.R` (shared with `wet_shape_predict()`), `scripts/wb_validate.R`,
`scripts/wb_cv_lib.R`, the fit's `adjust_override.txt`. Gate: a tolerance on the zero-distance test,
or none; the main-stem rule, registered before it is scored on both fits; whether the override
retires.

### 3. The published build's record

- [x] Carried by move 2, #164 (merged in https://github.com/NewGraphEnvironment/wet/pull/172)

#108 (the February fold in the manifest's daily description), #161 (the shared provenance receipt
through crate), #88 (record which parts a database load holds) and #160 (publish the shipped fit
beside the product) all change what the manifest holds or what a reader keeps of it, so one format
change and one PUBLISH carry them. Move 2 follows move 1 so the fit published is the refit one.

Touches `R/wet_manifest_write.R`, `R/wet_catalog.R`, `R/wet_db_load.R`,
`scripts/discharge_publish.R`, `scripts/segment_group.R`, `DESCRIPTION`. Gate: the receipt in place
of the manifest or beside it, and how long `wet_catalog()` reads both; the load table's name and
columns; which parts of the fit are published. Open work in crate on the receipt (a newer form,
`file:checksum`, a table fingerprint that fails on large tables) can change what the receipt holds,
and link reads the table comment; search both repos' open issues for "receipt" and "discharge"
before the plan.

### 4. Article bundles and maps

- [x] Carried by move 3, #165 (merged in https://github.com/NewGraphEnvironment/wet/pull/173)

#74 (install httpfs in the recipe, and run the recipe from the data script) and #155 (map layers
rebuild differently on the same FWA) both regenerate `inst/vignette-data/` under
`scripts/vignette_data_lib.R` and `scripts/vignette_map_lib.R`. The data scripts refuse unless the
tracked publish report names the live build, so this waits on move 2's publish.

Touches `data-raw/segment_vignette_data.R`, `data-raw/segment_vignette_map.R`,
`scripts/vignette_map_lib.R`, every `data-raw/*_map.R`, `inst/vignette-data/`. Gate: which layers
move onto fresh's fetchers; the layer comparison's tolerance on another database. Open work in
knowledge on chinook timing windows can change the life-history tables the bundles read.

### 5. Docs

- [x] Carried by move 3, #165 (merged in https://github.com/NewGraphEnvironment/wet/pull/173)

#97 (README ecosystem table and links) and #55 (`wet_station_snap()` docs: fresh's snap no longer
wraps `fwa_indexpoint()`). Small, with no build of their own; the site rebuilds with move 3.

Touches `README.md`, `R/wet_station_snap.R`, `man/`. Gate: none beyond the recorded README
decisions.

### 6. Monthly error at the gauges

- [x] Carried by move 4, #166 (merged in https://github.com/NewGraphEnvironment/wet/pull/175)

#6 (modelled monthly flow against HYDAT by region and season), #67 (routed PCIC low in March–April,
high in July–August) and #162 (DFO's Fraser threat-layer benchmark) read the same held-out balance
(`cv_share`), routed PCIC at the same gauge segments and the same observed months, so one report
script serves them; #162 names the months to lead with (August and September minimum flows). #162
carries #3's remaining caveat, now closed.

Touches a new report script under `scripts/`, `data/checks/`, `research/`. Gate: a tracked report or
an article section; the region unit; the owner approves any text sent to PCIC. Open work in fwapg
places more PCIC outlets, which changes the gauge set.

### 7. Stations beyond HYDAT

- [x] Carried by move 8, #179 (merged in https://github.com/NewGraphEnvironment/wet/pull/194)

#142 (the province's non-integrated hydrometric network) and #144 (the BC Water Tool's third-party
gauges) both feed `wet_station_daily()`, share the QA and regulation questions, and meet at six
sites.

**Touches:** `R/wet_station_daily.R`, `research/station_sources.md`, and new readers, with a report under the checks folder (named at the plan gate)

Gate: keep, flag or drop ungraded values; which copy at the shared sites; each series' credit line.

Split from move 5 at its plan gate (2026-11-18): counted against the four chinook site boxes, these
networks hold no station with a 1981–2010 baseline, so they add no donor there (#167's body).

Split again at move 8's own plan gate (2026-11-22): #142 lands here; #144 is its own PR after it and is carried by
batch 15, with #190, #191 and #192, which move 8 filed for what it left out (#190 and #192 split from batch 15 at move 13's
resume, 2026-11-23, for the next sweep to place).

### 8. PCIC's per-year files at the sites

- [x] Carried by move 5, #167 (merged in https://github.com/NewGraphEnvironment/wet/pull/180)

#135 caches PCIC's per-year files as `wet_hydat()` caches HYDAT, so #147's `covariance_pick` at the
chinook sites runs without a hand-made directory.

Touches a new internal fetcher, `scripts/departure_site.R`, `scripts/departure_pcic.R`,
`data-raw/chinook_sites_data.R`, the comparison article. Gate: the rule for `covariance_pick` at the
sites, registered before any run; whether the Morice and upper Fraser boxes are covered.

### 9. The channel-scale pilot

- [x] Carried by move 6, #168 (merged in https://github.com/NewGraphEnvironment/wet/pull/193)

#9 compares PCIC's channel-scale output (VIC-GL-Raven, CMIP6) at about six FWA sites with wet's
accumulation, routed PCIC and HYDAT. It is the oracle batch 10 waits on.

**Touches:** `research/pcic_channel_scale.md`, and a new pilot script

Gate: the six sites; whether it also
reads water temperature. Open work in fwapg asks whether to run Raven routing on the FWA itself.

### 10. Scenarios and coverage

- [ ] Carried by move 7, #169

#4 (scenario period means) and #5 (coverage and comparison map) both rescope from #9's verdict and
both need each PCIC product's coverage per watershed group.

**Touches:** new scenario readers and scripts, a dataset ID and crate schema if scenarios are published, a coverage report and map (all new files, named at the plan gate)

Gate: CMIP6 channel-scale, CMIP5 or both by domain; whether scenarios
are published as a new dataset.

### 11. The readers return pick, and one list of non-inputs

- [x] Carried by move 9, #186 (merged in https://github.com/NewGraphEnvironment/wet/pull/197)

#177 (the segment readers return `pick` beside `source`) and #171 (the daily table's list of files that are not inputs of
the monthly table lacks `R/wet_segment_daily.R`, `scripts/vignette_data_lib.R` and `scripts/segment_group.R`). #177 edits
one of those files, so a fix to it alone trips the daily guard.

**Touches:** `R/wet_segment_monthly.R`, `R/wet_segment_daily.R`, `scripts/segment_daily_output.R`, `scripts/discharge_publish.R`, `tests/testthat/`

Gate: fix #171 now (one edit to `scripts/segment_daily_output.R` forces a daily rerun of about 132 minutes and a BUILD where
the full province run is; nothing uploads if every part is identical) or defer it to the next move that reruns the daily
table; where `pick` sits in both readers' columns.

### 12. Swift and Naver creeks under their own windows

- [ ] Carried by move 10, #187

#182 scores Swift (UFRA) and Naver (COTR) creeks under their own cited chinook windows beside the Bulkley's. It moves wet's
one pin on the knowledge life history table (`c97c4d0`), which every Bulkley and Morice reader follows.

**Touches:** `data-raw/life_history_data.R`, `scripts/departure_sites.csv`, `inst/vignette-data/`, `data/checks/departure_site_swift_ufra_20260717.txt`, `data/checks/departure_site_naver_cotr_20260717.txt`, `data/checks/departure_site_snow_swift_ufra_20260717.txt`, `data/checks/departure_site_snow_naver_cotr_20260717.txt`, `data-raw/chinook_sites_data.R`, `vignettes/articles/flow-change-sparse-gauges.Rmd`, `research/chinook_sites.md`

Gate: the knowledge commit to pin; a guard that the Bulkley and Morice chinook rows at that commit equal those at
`c97c4d0`, or differ only in their notes, so the Maxan parity gate cannot break silently. Open work in the knowledge
repository reviews the Skeena timing rows: it keeps the Bulkley spawning row with a note and may revise the Morice rows
(search its open issues for "Life history timing, Skeena").

### 13. Small-basin error and the zone adjustment

- [x] Carried by move 11, #188 (merged in https://github.com/NewGraphEnvironment/wet/pull/200)

#176 diagnoses why the balance runs about 14 % high at gauges under 100 km²; #178 sets WALLY's flows beside ours and tests
its per-zone trait regression as a candidate adjustment; #44 blends the adjustment across zone lines; #185 consolidates
`research/monthly_error.md` so the diagnosis revises it in place. One oracle (the held-out balance at the gauges), and both
candidates change the zone adjustment, so one rescore under one registered rule scores them.

**Touches:** `research/monthly_error.md`, `R/wet_wb_fit.R`, `scripts/wb_validate.R`, and a new diagnosis script and its report under the checks folder, named at the plan gate

Gate: the rule, registered in a script's header before any candidate is scored; which candidates enter; the hosted WALLY
tool used only where its written terms allow.

### 14. Research files around the current state

- [ ] Carried by move 12, #189

#181 (`water_balance_method.md`, `chinook_sites.md`), #183 (`discharge_publish.md`) and #184 (`station_flow_departure.md`,
last verified 2026-09-28): one pass, one method, over the files soul's `research_check.sh` flags as grown into logs. Waits
on move 10, which rewrites `research/chinook_sites.md`.

**Touches:** `research/water_balance_method.md`, `research/chinook_sites.md`, `research/discharge_publish.md`, `research/station_flow_departure.md`, `CLAUDE.md`, `planning/archive/`

Gate: none beyond #181's rule.

### 15. Second sources for the provincial stations

- [x] Carried by move 13, #195 (merged in https://github.com/NewGraphEnvironment/wet/pull/201)

#144 (the BC Water Tool's third-party gauges, read through the pinned-snapshot pattern #142 set), #190 (which copy of the
province's 2021–2026 discharge is current, read against the province's Aquarius portal) and #192 (Hakai's 2013–2020 record
at its three Calvert and Hecate stations). All three were split from move 8. #144's six shared sites and #192's earlier
years ask one question: how a second publisher's record continues a provincial station under its number, which
`wet_station_daily()` answers today only for HYDAT numbers. One rule serves both. #190 says whether the pinned provincial
snapshot is the current copy before the Tool's copy is set beside it, and a newer snapshot rebuilds the registry this batch
extends anyway.

Split at move 13's resume (2026-11-23): this batch carries #144 and the chaining rule (the owner chose to chain a second
publisher's earlier days under the provincial number). #190 waits on the owner accepting the Aquarius portal's
disclaimer, and #192 on Hakai's data route; each is its own issue again, its owner question in its body, for the next
`/backlog-sweep` to place.

**Touches:** `R/wet_station_daily.R`, `R/wet_station_list.R`, `data-raw/station_sources_snapshot.R`, `inst/extdata/station_sources/`, `research/station_sources.md`, `tests/testthat/test-wet_station_daily.R`, `tests/testthat/test-wet_station_list.R`, and new readers with their tests and a report under the checks folder (named at the plan gate)

Gate: which copy at the six shared sites, and the rule for a second publisher's earlier record under a provincial number
(#144 lists the options; move 8's gate recommended provincial only); whether the province's portal is read, which needs the
owner to accept its click-through disclaimer; Hakai's record from its published data package or by asking Hakai, an outward
request that goes through the owner (if it would wait on a reply, #192 is split off again). Waits on move 8, which lands the
station registry, the snapshot cache and `wet_station_list()`.

### 16. Regulation per non-HYDAT station

- [ ] Carried by move 14, #196

#191 gives each station in the registry a regulation status (natural, regulated or unknown) from what sits upstream of its
snapped point: dams, reservoirs and licensed diversions, placed on the FWA as `scripts/wb_gauge_diversion.R` places water
licences for the calibration gauges. Until then `wet_station_select()` leaves every non-HYDAT station out as a donor, so this
is the prerequisite for any provincial or third-party donor under #118. It follows batch 15 so the status is computed once,
over the provincial and the Tool's stations both.

**Touches:** `R/wet_station_list.R`, `R/wet_station_select.R`, `data-raw/station_sources_snapshot.R`, `inst/extdata/station_sources/`, `research/station_sources.md`, `tests/testthat/test-wet_station_select.R`, and a new placement script with its report under the checks folder (named at the plan gate)

Gate: the rule for natural, regulated and unknown, registered in a script's header before it is applied; which registers
enter (the provincial dam register, licensed diversions, reservoirs) and under what licence; whether a status can differ by
window (a diversion that runs only in summer); where donor selection reads it.

## Singles

- #14: transboundary flow; no shared cost with any batch.
- #67: routed PCIC's seasonal shape; its one open ask is the note to PCIC, which goes only with the owner's approval of its wording. Its checks were done in move 4.
- #76: the `fwa_indexpoint()` tie-break; waits on fwapg's tie rule, and joins move 1 if that lands first (it reruns `scripts/wb_stations.R` and the same chain).
- #111: waits on fwapg's decision on the default downstream walk.
- #113: retest the duckdb icu autoload on duckdb 2.0; an upstream reply needs the owner's approval.
- #118: the frame; closes with its components.
- #124: CABIN; stands alone.
- #137: the chinook section in the Maxan article; waits on knowledge's per-stream salmon records table. The article is no longer listed on the site, so this may close instead.
- #140: BC Hydro data, by request only.

## Closed and transferred

- #3: superseded by #57 and #99, which publish monthly and daily flow per segment; its remaining caveat is carried by #162 in batch 6.
- #37: done: the repo is public. The remaining deprecation of the ngr copy of the daily flow reader belongs in ngr.
