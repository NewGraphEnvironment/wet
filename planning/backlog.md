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

How to use this file: `/backlog-sweep` writes it. Take the first move in **Moves** that is not
ticked and not **waiting**; `/planning-init <umbrella>` plans it, one phase per batch, one PR.
`/gh-pr-merge` step 9c ticks the move on merge; `/compact-prep` names the next. A `NONE` from
`backlog_moves.sh next` that names batch sections means those batches have no move yet: run
`/backlog-sweep` again, the backlog is not finished.

## Moves

| move | umbrella | batches | state |
|---|---|---|---|
| - [ ] 1 | #163 | 1, 2: province inputs and run comparison, the fit's own rules (6 issues) | open: start here |
| - [ ] 2 | #164 | 3: the published build's record (4 issues) | open, after move 1 |
| - [ ] 3 | #165 | 4, 5: article bundles and maps, docs (4 issues) | **waiting** on move 2's PUBLISH: the tracked publish report names the build move 2 published |
| - [ ] 4 | #166 | 6: monthly error at the gauges (3 issues) | open |
| - [ ] 5 | #167 | 7, 8: stations beyond HYDAT, PCIC's per-year files at the sites (4 issues) | open |
| - [ ] 6 | #168 | 9: the channel-scale pilot (1 issue) | open |
| - [ ] 7 | #169 | 10: scenarios and coverage (2 issues) | **waiting** on move 6's verdict in `research/pcic_channel_scale.md` |

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
| 7 | #167 | stations beyond HYDAT: #142, #144 | 2 | keep, flag or drop ungraded values; which copy at shared sites; credit lines | both feed `wet_station_daily()` and meet at six sites |
| 8 | #167 | PCIC's per-year files at the sites: #135, #147 | 2 | the `covariance_pick` rule at the sites, registered before any run | the site rerun batch 7's donors need is the one this needs |
| 9 | #168 | the channel-scale pilot: #9 | 1 | the six sites; whether it also reads water temperature | the oracle batch 10 waits on |
| 10 | #169 | scenarios and coverage: #4, #5 | 2 | CMIP6 channel-scale, CMIP5 or both by domain; publish scenarios as a new dataset or not | both rescope from batch 9's verdict |

### 1. Province inputs and run comparison

- [ ] Carried by move 1, #163

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

- [ ] Carried by move 1, #163

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

- [ ] Carried by move 2, #164

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

- [ ] Carried by move 3, #165

#74 (install httpfs in the recipe, and run the recipe from the data script) and #155 (map layers
rebuild differently on the same FWA) both regenerate `inst/vignette-data/` under
`scripts/vignette_data_lib.R` and `scripts/vignette_map_lib.R`. The data scripts refuse unless the
tracked publish report names the live build, so this waits on move 2's publish.

Touches `data-raw/segment_vignette_data.R`, `data-raw/segment_vignette_map.R`,
`scripts/vignette_map_lib.R`, every `data-raw/*_map.R`, `inst/vignette-data/`. Gate: which layers
move onto fresh's fetchers; the layer comparison's tolerance on another database. Open work in
knowledge on chinook timing windows can change the life-history tables the bundles read.

### 5. Docs

- [ ] Carried by move 3, #165

#97 (README ecosystem table and links) and #55 (`wet_station_snap()` docs: fresh's snap no longer
wraps `fwa_indexpoint()`). Small, with no build of their own; the site rebuilds with move 3.

Touches `README.md`, `R/wet_station_snap.R`, `man/`. Gate: none beyond the recorded README
decisions.

### 6. Monthly error at the gauges

- [ ] Carried by move 4, #166

#6 (modelled monthly flow against HYDAT by region and season), #67 (routed PCIC low in March–April,
high in July–August) and #162 (DFO's Fraser threat-layer benchmark) read the same held-out balance
(`cv_share`), routed PCIC at the same gauge segments and the same observed months, so one report
script serves them; #162 names the months to lead with (August and September minimum flows). #162
carries #3's remaining caveat, now closed.

Touches a new report script under `scripts/`, `data/checks/`, `research/`. Gate: a tracked report or
an article section; the region unit; the owner approves any text sent to PCIC. Open work in fwapg
places more PCIC outlets, which changes the gauge set.

### 7. Stations beyond HYDAT

- [ ] Carried by move 5, #167

#142 (the province's non-integrated hydrometric network) and #144 (the BC Water Tool's third-party
gauges) both feed `wet_station_daily()`, share the QA and regulation questions, and meet at six
sites.

Touches `R/wet_station_daily.R` and new readers, `research/station_sources.md`, `data/checks/`.
Gate: keep, flag or drop ungraded values; which copy at the shared sites; each series' credit line.

### 8. PCIC's per-year files at the sites

- [ ] Carried by move 5, #167

#135 caches PCIC's per-year files as `wet_hydat()` caches HYDAT, so #147's `covariance_pick` at the
chinook sites runs without a hand-made directory. The site rerun it needs is the one batch 7's new
donors need.

Touches a new internal fetcher, `scripts/departure_site.R`, `scripts/departure_pcic.R`,
`data-raw/chinook_sites_data.R`, the comparison article. Gate: the rule for `covariance_pick` at the
sites, registered before any run; whether the Morice and upper Fraser boxes are covered.

### 9. The channel-scale pilot

- [ ] Carried by move 6, #168

#9 compares PCIC's channel-scale output (VIC-GL-Raven, CMIP6) at about six FWA sites with wet's
accumulation, routed PCIC and HYDAT. It is the oracle batch 10 waits on.

Touches a new pilot script, `research/pcic_channel_scale.md`. Gate: the six sites; whether it also
reads water temperature. Open work in fwapg asks whether to run Raven routing on the FWA itself.

### 10. Scenarios and coverage

- [ ] Carried by move 7, #169

#4 (scenario period means) and #5 (coverage and comparison map) both rescope from #9's verdict and
both need each PCIC product's coverage per watershed group.

Touches new scenario readers and scripts, a dataset ID and crate schema if scenarios are published,
a coverage report and map. Gate: CMIP6 channel-scale, CMIP5 or both by domain; whether scenarios
are published as a new dataset.

## Singles

- #14: transboundary flow; no shared cost with any batch.
- #44: blend the zone adjustment; waits on batch 2's main-stem gate.
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
