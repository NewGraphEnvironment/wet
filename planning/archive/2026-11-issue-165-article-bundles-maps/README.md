# #165 Backlog move 3: article bundles and maps that rebuild identically, and the docs

## Outcome

Every article map bundle now rebuilds byte for byte on the same FWA, and the segment and monthly bundles read live build a0318b7 (run `768876badf`, routed PCIC at fwapg 5d50cc1) with its receipt. `scripts/vignette_map_lib.R` takes lakes and stream segments from fresh's fetchers, merges streams in R in segment order, simplifies polygons in sf, orders every query and aggregate, sorts names by radix and resets row names; `vm_write()` compares a rebuild with the committed map and leaves it untouched when nothing changed (#155). `data-raw/segment_vignette_data.R` runs the article's group recipe from the committed `.Rmd` and refuses unless it returns BULK's month-0 picks as read part by part, and the data scripts install httpfs before loading it (#74). Routed PCIC is now picked on 99 % of the Nechako Reservoir groups' segments, so the article, its map and the README figure drop the Nechako (decided at the gate). The README's Ecosystem table is rendered from the shared registry and its links go to published sites (#97); `wet_station_snap()`'s docs say why it calls `fwa_indexpoint()` (#55). The durable finding is in [`research/map_rebuild.md`](../../../research/map_rebuild.md): PostGIS's polygon simplification under GEOS 3.9.0 does not repeat exactly within one session, filed as fresh#306.

## Measurement

- Live build, Nechako Reservoir groups (LEUT, LNRS, UEUT, UNRS): 60,213 segments pick routed, 654 the balance. This decided dropping the Nechako from the article.
- Tahtsa Reach, `ST_SimplifyPreserveTopology(geom, 100)`, PostGIS 3.5.2 / GEOS 3.9.0: 19 × 557 and 1 × 556 points over 20 calls in one session (7 of 20 at 556 inside the fetcher's AOI query); 12 of 12 at 557 with a new session per call. sf's GEOS 3.13.0: 1 result in 60 (Tahtsa Reach and Ootsa Lake, 25–400 m). Lines in PostGIS: 15 of 15 identical. The first two-pass run rewrote three maps over that one lake; moving polygon simplification to sf fixed it. The same lakes are what #155 had taken for a GEOS version difference between databases.
- Four `vm_*` maps: second runs left every file untouched; rebuilt on m4's fwapg, every layer identical to m1's; rebuilt under `LC_ALL=C`, untouched. Against main's maps, streams and points were identical and polygons moved within each map's simplify tolerance (largest Hausdorff 49.9, 99.9, 384.4, 4,997.7 m).
- Recipe check: BULK's month-0 picks 29,224 routed and 813 balance. Perturbed recipes were each refused: `month = 1` (30,037 rows, flows differ), no `pick` (60,074), `MORR` (22,218).
- Segment article: routed now scored at 283 gauges (279 before), pick shares 65 % routed, 27 % balance, 3 % far low.
- Tests 3,065 passed, 0 failed, after upgrading m1's crate 0.4.0 → 0.16.0.

## Evidence

`data/logs/165/` (pcic load, map passes `maps_*`, bundles `bundle_*`, `recipe_perturb.log`, `tests.log`); reviews in this directory (`review-plan.md`, `review-round*.md`).

## Owed

- Note on the shared-registry rollout issue that wet's README renders the registry block (one comment)

Closed by: PR (opened after this archive)
