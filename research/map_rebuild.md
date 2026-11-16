# Article maps that rebuild identically

**Verified:** 2026-11-16 · **Issues:** #155, #165; fresh#306 (filed from it) · **Produced by:** `data-raw/*_map.R` through `scripts/vignette_map_lib.R`; logs `data/logs/165/maps_*`, `data/logs/165/bundle_segment_vignette_map*`

A map script rerun on the same FWA, the same database and the same software writes no new bytes: `vm_write()` compares the rebuild with the committed `inst/vignette-data/*_map.rds` layer by layer and leaves the file untouched when nothing differs. Getting there took four kinds of fix, each because `identical()` makes something part of the output that only the content had been:

- **Row order.** Every query orders its rows on a unique key, and every aggregate (`ST_Union`, `ST_Collect`) takes ordered input. Lakes and stream segments come from fresh's fetchers, which order on `waterbody_poly_id` and `linear_feature_id`.
- **Locale.** R-side sorts of names use `method = "radix"`, so a run under another `LC_COLLATE` gives the same order (checked by rebuilding all four `vm_*` maps under `LC_ALL=C`: unchanged).
- **Row names.** A reorder keeps the row names of the frame it reordered (SQLite's return order in `vm_stations()`, `merge()`'s in the chinook gauges), so they are reset.
- **Polygon simplification.** Done in sf, not PostGIS (below).

## PostGIS polygon simplification does not repeat exactly under GEOS 3.9.0

PostGIS 3.5.2 on GEOS 3.9.0-CAPI-1.16.2 (m1's and m4's fwapg, 2026-11-16):

- `ST_NPoints(ST_SimplifyPreserveTopology(geom, 100))` on Tahtsa Reach (`waterbody_poly_id` 700228651), 20 calls in one session: 19 × 557, 1 × 556. Inside `frs_lake_fetch()`'s AOI query, 13 × 557 and 7 × 556.
- With a new session per call it was 557 in 12 of 12. That is why a test of separate runs can find lakes stable on repeat.
- Lines were stable: main-flow rivers in BULK, MORR, LSKE, UFRA and FRAN, merged, simplified at 2,000 m and snapped to 100 m, were identical in 15 of 15 calls in one session, with `ST_SimplifyPreserveTopology()` and with `ST_Simplify()`.
- sf's GEOS 3.13.0 repeats: `st_simplify(preserveTopology = TRUE)` on Tahtsa Reach and Ootsa Lake gave one result in 60 at 25, 50, 100 and 400 m.

So lakes, catchments and the BC outline are fetched unsimplified (catchments and the outline normalised with `ST_Normalize()`) and simplified in sf (`vm_simplify()`). The segment map's rivers are lines and stay simplified in PostGIS. #155 had measured Tahtsa Reach and Ootsa Lake one vertex apart between two databases and read it as a GEOS version difference; it was this, since both databases run GEOS 3.9.0.

## Across databases

The four `vm_*` maps rebuilt against m4's fwapg were identical in every layer to m1's; only the provenance's PostGIS string differs (m4's lists GDAL and raster). Each bundle's provenance carries `postgis_full_version()` and sf's GEOS, so a rebuild elsewhere names its own software.
