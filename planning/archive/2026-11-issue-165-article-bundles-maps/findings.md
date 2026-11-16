# Findings — Backlog move 3: Article bundles and maps that rebuild identically, and the docs (#165)

## Issue context

**If we do it:** every article's data and map bundle is regenerated once, against the build move 2 publishes, by scripts that run the read recipe the article shows and write the same map file on the same FWA; the README links and the snap docs are corrected in the same pass. **If we never do:** a map rerun rewrites its bundle whether or not anything changed, the segment data script never runs its own recipe, and two data scripts load httpfs without installing it.

Order: `planning/backlog.md`, move 3. Move 2's PUBLISH landed on 2026-11-15 (live build a0318b7), and its tracked publish report reaches `main` with #164's merge, so the vignette data scripts' guard is met from then on. Run `/planning-init <this issue>`: one phase per batch, one PR.

## Batch 4: article bundles and maps

**Why here:** both regenerate `inst/vignette-data/` under the same guards (`scripts/vignette_data_lib.R`, `scripts/vignette_map_lib.R`), so one regeneration against one live build serves both.

**Touches:** `data-raw/segment_vignette_data.R`, `data-raw/segment_vignette_map.R`, `scripts/vignette_map_lib.R`, every `data-raw/*_map.R`, `inst/vignette-data/`.

**Decided at the gate:** which layers move onto fresh's fetchers and which stay in wet; the layer comparison's tolerance for a rebuild on another database. Open work in knowledge on chinook windows can change the life-history tables the bundles read.

| issue | title |
|---|---|
| #74 | segment-discharge recipe: INSTALL httpfs, run it from the data script, point to wet_segment_monthly() |
| #155 | Map layers rebuild differently on the same FWA: fix row and geometry order, lakes and streams via fresh's fetchers |

## Batch 5: docs

**Why here:** small, no build of their own, and the site is rebuilt by this move anyway.

**Touches:** `README.md`, `R/wet_station_snap.R`, `man/`.

**Decided at the gate:** nothing beyond the README convention already recorded.

| issue | title |
|---|---|
| #97 | README: Ecosystem table and links per the recorded README decisions |
| #55 | wet_station_snap() docs: frs_point_snap() no longer wraps fwa_indexpoint() |


## Owed from move 1 (#163), carried by move 2 (#164) to this move

Decided at #164's gate (2026-11-15): this move regenerates every bundle against #164's PUBLISH anyway, and the data scripts refuse until that publish lands, so these are done here. They stay in #164's body too; the merge that does them ticks both copies.

#163 republished the product on province run `768876badf` and fwapg 5d50cc1's routed rebuild, which places the Nechako Reservoir (`fwapg#24`): picks moved on 59,206 segments, almost all in LEUT, LNRS, UEUT and UNRS, and the balance did not move.

- [ ] Regenerate the `inst/vignette-data/` bundles (`data-raw/segment_vignette_{data,map}.R`, `data-raw/monthly_vignette_{data,map}.R`) against the live build. They keep run `92b893c4da` and the old routed build until then.
- [ ] Rewrite the segment-discharge article's Nechako sentences (the `nech_bal > 90` guard and the map's reading) for the placed reservoir.
- [ ] Remake `man/figures/readme-pick.png` (`data-raw/readme_figure.R`); its alt text says the Nechako Reservoir is orange, which no longer holds.
- [ ] On the machine that builds the bundles, reload `pcic` from fwapg 5d50cc1's published export first: the data scripts refuse a routed table other than the tracked routed report's.
- [ ] (#161) The vignette bundles' provenance attributes carry the published receipt's keys (`recipe_id`, the live build's wet commit), since #164 publishes `receipt.json` beside the manifest.

**Touches** (added): `data-raw/`, `inst/vignette-data/`, `vignettes/segment-discharge.Rmd`, `man/figures/readme-pick.png`.


## Planning measurements (2026-11-15, m1)

- Live build a0318b7, month-0 `pick` in the Nechako Reservoir groups: LEUT 6,849 routed / 106 balance; LNRS 9,579 / 31; UEUT 19,962 / 362; UNRS 23,823 / 155; total 60,213 routed, 654 balance (99 % routed). Read with duckdb over the live parts.
- knowledge `data/life_history_timing.csv`: BULK and MORR rows identical at c97c4d0 (pinned) and `main`.
- `fresh::frs_watershed_at_measure()` selects `geom` only; no area column.
- `check_pkg_stale.sh`: fresh 0.52.0 -> 0.53.0, wet installed 0.4.35 (main 0.4.36).
- soul `ecosystem.yml` `readme: true` rows: link, fresh, wet, flooded, drift, fly, cd, knowledge, floodplains, stac_floodplains_bc.
- `chinook_sites_data.R` refuses unless the live digest equals the Gosnell report's; the live digest moved with #163's 13 uploaded parts, so that bundle is checked by part md5 rather than regenerated.


## PostGIS polygon simplification repeats inexactly under GEOS 3.9.0 (2026-11-16, m1)

`SELECT ST_NPoints(ST_SimplifyPreserveTopology(geom, 100)) FROM whse_basemapping.fwa_lakes_poly WHERE waterbody_poly_id = 700228651` (Tahtsa Reach), run 20 times in one psql session: 19 x 557, 1 x 556. Inside the AOI query of `frs_lake_fetch()`: 13 x 557, 7 x 556. A new session per query gave 12 of 12 x 557, which is why fresh#287 saw lakes identical on repeat. PostGIS 3.5.2, GEOS 3.9.0-CAPI-1.16.2. sf 3.13.0's `st_simplify(preserveTopology = TRUE)` on the same rings: 1 distinct result in 60, at 25/50/100/400 m, Tahtsa Reach and Ootsa Lake. Lines (main-flow rivers in BULK, MORR, LSKE, UFRA, FRAN, merged and simplified at 2000 m, snapped to 100 m): 15 of 15 identical with ST_SimplifyPreserveTopology and with ST_Simplify. #155 measured Tahtsa Reach and Ootsa Lake one vertex apart and took it for a difference between databases; it was this.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `st_line_merge.sfc`: `inherits(x, "sfc_MULTILINESTRING") is not TRUE` for a one-segment key | cast the union to MULTILINESTRING first |
| `vm_compare()` read sorted tables as different (row names), and sorted an attribute-less layer to zero rows | reset row names in `sorted()`; skip ordering when there are no keys |
| Map pass 2 rewrote three maps (one lake vertex) | polygons simplified in sf, not PostGIS (above) |
