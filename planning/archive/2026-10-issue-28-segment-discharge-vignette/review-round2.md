# Review round 2 (#28): staged diff, data-raw/segment_vignette_{map,data}.R

## Is the integer64 fix complete? Yes.

- **Every saved column checked** with readRDS in a session that does not load bit64. In
  segment_values.rds, all id columns are `integer`: parity, sampling, segments, skill. The
  rest are character, double or logical. provenance holds Date, chr, logical, num, and named
  int (`fwapg_discharge_rows`, `upstream_area_100`). In segment_map.rds, all four sf layers
  have `linear_feature_id`, `blue_line_key` and `stream_order` as integer, `area_km2` and
  `area_ha` as double, and the rest character or sfc.
- **DB types (information_schema).** Only `fwa_stream_networks_sp.linear_feature_id` and
  `fwa_streams_watersheds_lut.linear_feature_id` are bigint, and both are cast. These are
  already `integer` and need no cast: `watershed_feature_id`, `blue_line_key`,
  `stream_order`, and `fwa_stream_networks_discharge.linear_feature_id`. `mad_mm`, `area_ha`
  and `ST_Area()` are double precision, so none of them arrives as character. Every
  `count()` is cast `::int`.
- **int32 headroom.** The largest `linear_feature_id` is 868,144,683 and the largest
  `watershed_feature_id` is 1,000,003,721. Both are below 2^31 − 1. If the cast ever does
  overflow, Postgres raises `ERROR: integer out of range` (tested). It does not return NA,
  so the failure would be loud.
- **The guard is not vacuous.** `vapply()` over a data.frame or sf object walks its columns,
  the sfc column included. The guard skips provenance and does not recurse into nested
  lists, but every element of provenance has been checked above and none is integer64. The
  integer64 path in the data script itself (the `%in%` and `match()` calls against DB ids)
  is safe, because every id that reaches R is int4.
- **Other id joins.** parquet `watershed_feature_id` arrives as integer (arrow downcasts it)
  and is unique at month 0 in both basins. The parity CSV ids read back as integer.

## Findings

- **[severity: fragile]** data-raw/segment_vignette_data.R:187: `wet_commit` records
  `git rev-parse --short HEAD` even when the tree is dirty. These outputs were built at
  f587077, and that commit contains neither data-raw script (`git ls-tree` shows 0 files
  matching segment_vignette). The vignette prints "built … at commit f587077" as
  provenance, but that commit cannot regenerate the data. Fix: rebuild after committing the
  scripts, or record `git describe --always --dirty` and refuse a dirty tree.

Nothing else found. In the rest of the diff:

- Every DB-sourced IN-list fails loudly on NA.
- The order ≥ 3 filters are the same in both scripts, and the vignette's merge has a
  row-count guard.
- `wb` values are matched on unique keys.
- The NA-pattern guard on `mad_wb_m3s` and the SALR non-NA guard on `mad_pcic_m3s` would
  both fire on a basin mismatch.
- If the empty-geometry fallback ever let an empty line through, the guard would catch it.
- The two report lines parse to single integers: 644710 polygons, 1731 stale.
