# Code-check review, round 1 (#28 data-raw scripts)

## Findings

- **[severity: fragile]** data-raw/segment_vignette_data.R:73-78, 158-163 and data-raw/segment_vignette_map.R:40-45 — `linear_feature_id` is `bigint` in fwapg, so RPostgres returns it as `bit64::integer64`. Both shipped files carry it that way: `segment_values.rds$segments$linear_feature_id` and `segment_map.rds$segments$linear_feature_id` are integer64. `segment_values.rds$parity$linear_feature_id` is a plain integer, because it came through `read.csv`. `readRDS()` does not load bit64, and bit64 is not in DESCRIPTION, so in the vignette integer64 is a double holding the raw bits, with no methods. Measured in a fresh `Rscript` with bit64 not loaded:
  - `match(values$segments$linear_feature_id[SALR], values$parity$linear_feature_id)` matches **0 of 2181**, with no error. A vignette that joins parity (fwapg vs wet) onto the segments or the map gets all-NA without any warning.
  - The ids print as `3.47e-315`.
  - The map-to-values join still works (9936 of 9936), but only because both sides carry the same bit patterns.

  The script's own match at line 162 only works because RPostgres has loaded bit64 by then. Fix: cast in SQL (`linear_feature_id::int`, since FWA ids fit in int32) or `as.integer()` before saving, in both scripts. Everything then shares one key type.

## Checked and clean

- Sampling is like with like. `mm_centroid` comes from `SALR_parity.csv$mad_mm_wet`, which is `build(cen, "total", upstream_area = stored)`. `mm_area` comes from `SALR_area_total.csv`, which is `build(area_vals, "total", upstream_area = stored)`. Both are upstream means over fwapg's stored area. For SALR the stored area does not matter: 0 parity rows differ between `mad_m3s_live` and `mad_m3s_wet`. The same holds for `mad_pcic_m3s` in `segments`.
- Report parsing works:
  - `wb_validation.txt` has one "Adjusted, blocked CV" heading, and field 7 is MAE%.
  - The `upstream_area_100_full.txt` regex picks up 1731.
  - The HYDAT release line is unique.
- `cv_v` is used unconditionally, but `fits$keep_adjust` is TRUE, so the adjusted CV is the shipped fit. This would only matter if `keep_adjust` ever became FALSE, and then the report-row guard would still pass.
- Gauge selection: the `fwa_upstream()` argument order is right. If it were reversed, no station would hold SALR and the `stopifnot(length(outlet) == 1)` would fire. The outlet is 08KC001. `fw_near` is unique per watershed and covers all 5 gauges.
- The parquet has no duplicate `watershed_feature_id` at month 0, so the `match()` at lines 161 and 164 is safe. The lut join was asserted unique.
- Map script: CRS 3005, all LINESTRING, no empty geometries, counts asserted against fwapg, and places spatially filtered rather than matched by name.
