# Task: Backlog move 3: Article bundles and maps that rebuild identically, and the docs (#165)

**If we do it:** every article's data and map bundle is regenerated once, against the build move 2 publishes, by scripts that run the read recipe the article shows and write the same map file on the same FWA; the README links and the snap docs are corrected in the same pass. **If we never do:** a map rerun rewrites its bundle whether or not anything changed, the segment data script never runs its own recipe, and two data scripts load httpfs without installing it.

Batches 4 (#74, #155) and 5 (#97, #55) of `planning/backlog.md`, plus the items owed from #163 and #164 (regenerate the bundles against live build a0318b7, the Nechako sentences, the README figure, the pcic reload, #161's receipt keys in provenance).

Measured during planning (2026-11-15, on m1):
- Live build a0318b7 picks routed PCIC on 60,213 of 60,867 segments in LEUT/LNRS/UEUT/UNRS (99 %); the article's `nech_bal > 90` guard and sentence are now false.
- knowledge's `life_history_timing.csv` BULK and MORR rows at `main` equal the pinned c97c4d0: no life-history change.
- fresh 0.52.0 installed (0.53.0 released); installed wet is 0.4.35 (main 0.4.36). m1's fwapg holds pcic from 7c30f58; the tracked routed report names 5d50cc1 (fingerprint 179854603.510890), so the data scripts refuse until pcic is reloaded.
- soul's `ecosystem_registry.py render --readme README.md --member wet` (soul PR #836) renders the Ecosystem table from `ecosystem.yml`; adopting it in each README is soul#835.
- `frs_watershed_at_measure()` returns geometry only (no area), so catchments stay in wet.
- No issue comments on #165, #74, #155 (one, a release notice), #97, #55 ask for anything beyond their bodies.

## Decided at the gate (user, 2026-11-15)

- **Nechako:** drop it from the article: the map label, its region in `segment_map.rds`, the sentence and its guard; README alt text loses "and the Nechako Reservoir"; CLAUDE.md's article description follows.
- **Fetchers:** lakes via `frs_lake_fetch()`, streams' segments via `frs_stream_fetch()` (ordered on `linear_feature_id`, union/merge/simplify per blue line in R). Catchments, the BC outline and the segment map's rivers stay in wet's SQL with ordered aggregate input and `ST_Normalize()`.
- **Second-database tolerance:** report only (identical / identical after sorting / same features, different geometry with vertex counts and largest Hausdorff distance); committed maps built on m1, where two runs must be `identical()`.
- **README Ecosystem:** rendered from soul's registry (the settled route, soul PR #836 / soul#835), not hand-edited; gq's row moves to one line below the block.
- **Bundles not regenerated:** `chinook_sites_values.rds`, `short_record_values.rds`, `station_daily.rds` read nothing move 2 changed (their data come from departure series and HYDAT); checked by holding chinook's bundled part md5s to the live manifest. Their map bundles are rebuilt under #155.
- **Map reruns that change nothing leave the file untouched:** each map script compares its new layers with the committed file and keeps it when every layer and the recipe provenance are identical.

## Phase 1: Setup on m1
- [x] Upgrade fresh 0.52.0 → 0.53.0 (read its NEWS for fetcher changes: none); reinstall wet from the branch before any article build (Phase 6)
- [ ] Reload m1's `pcic` schema from fwapg 5d50cc1's `load/pcic_schema.sql`, `load/pcic.sql`, `load/pcic_run.sql` (1981–2010 run's `subbasin_daily`), from a worktree of fwapg at 5d50cc1; stop unless the fingerprint equals the tracked routed report's 179854603.510890 and the daily fingerprint the tracked daily report's
- [ ] Probe both databases with `connect_timeout = 10` (m1 local; m4's fwapg on the LAN, read only)

## Phase 2: Docs (batch 5: #55, #97)
- [x] #55: `R/wet_station_snap.R` roxygen: replace the "the function `fresh::frs_point_snap()` wraps" parenthetical with why `fwa_indexpoint()` is used (one candidate per stream, which choosing between streams by drainage area needs; `frs_point_snap()` lists per-segment candidates); `devtools::document()`
- [x] #97: wrap README's Ecosystem table in the BEGIN/END `ecosystem.yml` markers and render with `ecosystem_registry.py render --readme README.md --member wet`; gq to a line below the block; keep the link/cd sentence if still true
- [x] #97: link packages and named sources to published sites (`https://www.newgraphenvironment.com/<repo>/`, upstream sites where they exist: fwapg, PCIC, water-temp-bc if it has one); own articles and NEWS via newgraphenvironment.com/wet/
- [x] #97: every link resolves (curl status, following redirects); word count near 582 (report before/after); check README tagline against the registry tagline and report any mismatch (rule 2) without widening scope

## Phase 3: Map layers that rebuild identically (batch 4: #155)
- [x] `vm_lakes()` → `fresh::frs_lake_fetch(conn, aoi = ext$sfc, area_ha_min = min_ha, simplify_m = simplify_m)`, columns renamed to the bundle's (`gnis_name`, `area_ha`, `geom`)
- [x] `vm_streams()` → `fresh::frs_stream_fetch()` twice (order ≥ min_order in the AOI; every segment of `blk`), deduplicated on `linear_feature_id`, ordered, then per blue line: union, line merge, simplify (preserve topology) in sf; same output columns and `main` flag
- [x] `vm_catchments()`: `ST_Normalize()` after the simplify; snap and HYDAT area check unchanged
- [x] `vm_bc()`: parts ordered (by area, then centroid) before `ST_Collect`, `ST_Normalize()` the result
- [x] `vm_places()`: rows sorted on name, then coordinates
- [x] `segment_vignette_map.R` rivers: `ST_Union(geom ORDER BY linear_feature_id)`, `ST_Normalize()`, and an `ORDER BY order_band, blue_line_key, class` on a unique key
- [x] `postgis_full_version()` in every map bundle's provenance (`vm_layers()` and the segment map's list)
- [x] `vm_compare(new, old)` in `scripts/vignette_map_lib.R`: prints per layer identical / identical after sorting / same features with different geometry (vertex counts, largest Hausdorff distance); each map script calls it against the committed file and keeps that file when all layers and recipe provenance are identical
- [x] fresh listed as a `data-raw/` need in the scripts' headers (not DESCRIPTION; the build excludes `data-raw/`)

## Phase 4: The data scripts' recipe, httpfs and receipt (batch 4: #74; owed #161)
- [x] `INSTALL httpfs; LOAD httpfs;` in `data-raw/segment_vignette_data.R`, `data-raw/segment_vignette_map.R`, `data-raw/monthly_vignette_data.R`
- [x] `segment_vignette_data.R` runs the article's `read-group` recipe as written (every monthly part, `scenario = 'historical' AND watershed_group_code = 'BULK' AND month = 0 AND pick`) and refuses unless it returns one row per segment, equal on `linear_feature_id`, `source` and `q_m3s` to the BULK month-0 `pick` rows of the script's own per-part read (routed and balance parts), with parts verified before and after; the recipe's row counts go into provenance
- [x] Bundle provenance carries the published receipt's keys (`recipe_id`, the live build's wet commit) in `segment_values.rds`, `monthly_values.rds` and `segment_map.rds`
- [x] Drop the Nechako region from `segment_vignette_map.R` (Liard only); header comment updated

## Phase 5: Regenerate against the live build, and the article
- [x] (four vm_* maps; the segment map runs with the data scripts) Commit, then run on m1, each twice where it is a map script: `station_vignette_map.R`, `monthly_vignette_map.R`, `short_record_vignette_map.R`, `chinook_sites_map.R`, `segment_vignette_map.R` (`WET_FWAPG_COMMIT=5d50cc1`); every layer `identical()` between the two runs; logs under `data/logs/165/`
- [x] Rebuild each of the four `vm_*` maps once against m4's fwapg (`WET_PGHOST`, `WET_MAP_OUT_DIR` to scratch), record the comparison (report only); the segment map writes a temp table and reads the live build, so it is not rebuilt there
- [ ] Run `segment_vignette_map.R`, `segment_vignette_data.R` and `monthly_vignette_data.R` at one HEAD on one day (`WET_FWAPG_COMMIT=5d50cc1` for the data scripts), committing after all three, against a0318b7; both bundles name one build, read date, fit (768876badf) and routed run
- [ ] Hold `chinook_sites_values.rds`'s bundled part md5s to the live manifest (no regeneration); its article prints the Gosnell report's whole-build digest, which is no longer live (values hold)
- [ ] research/discharge_publish.md and research/water_balance_method.md: the bundles now read a0318b7
- [ ] `vignettes/segment-discharge.Rmd`: drop the Nechako label, sentence, `nech`/`nech_bal` and its guard; caption names only the Liard; re-read every guard against the regenerated numbers
- [ ] `data-raw/readme_figure.R` → `man/figures/readme-pick.png`; README alt text without the Nechako; check the PNG at published width
- [ ] CLAUDE.md: the article description ("the Liard labelled"), the map lib's fetchers, the recipe check

## Phase 6: Verify and review
- [ ] `devtools::document()`, `devtools::test()` (failed + error counted), `lintr` per file vs `origin/main`, `pkgdown::check_pkgdown()`
- [ ] Reinstall wet from the branch; build the segment-discharge article and the four map-reading articles; strip HTML to text and diff against main's render: only the Nechako sentences, caption and changed numbers differ; word count under the 2,000 cap
- [ ] Visual check of every map figure and `readme-pick.png` against main's (chinook river labels can move)
- [ ] Recipe check fires: in a worktree copy, `month = 1`, no `AND pick`, `'MORR'` each refused
- [ ] Render a review copy as a private claude.ai artifact and offer the link
- [ ] `/code-check branch` (three-round floor)

## Owed at the end (reported, done after merge)
- [ ] Note on soul#835 that wet's README renders the registry block (one comment, our repo)

## Validation
- [ ] Tests pass
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

Verification: each map script run twice on m1 writes byte-identical `.rds` (md5 equal; a third run leaves the file's mtime unchanged); second-database comparison recorded; both data scripts pass every guard against a0318b7 and the tracked publish, routed and daily reports; the recipe check is shown to fire by perturbing the recipe's filter in a scratch copy; rendered article text diff limited to intended changes; README links all resolve. The #164 body's owed items for this move are ticked in both issues at the merge.

