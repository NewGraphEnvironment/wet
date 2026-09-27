# Review: Phase 2 of #11 (HYDAT stations), round 1

## Findings

- **[severity: fragile]** R/wet_station_snap.R:45 (the `c.linear_feature_id` column of the LATERAL query), and scripts/wb_stations.R:52 (`saveRDS`): `fwa_indexpoint()` returns `linear_feature_id` as `bigint`, and RPostgres maps that to `bit64::integer64` by default. The column in `data/wb/stations.rds` is `integer64`, which does not match the `numeric` type `wet_snap_empty()` declares. A later phase that reads the rds in a session where bit64 is not loaded sees the raw bit patterns as doubles. Measured: `readRDS("data/wb/stations.rds")$stations$linear_feature_id` prints `2.573470e-316 ...`, and `match()` against numeric ids returns all `NA` with no error. Any join on `linear_feature_id` would then fail silently (for example to streams or segment measures, or when comparing modelled flow against these stations). The fix is `c.linear_feature_id::double precision` (FWA ids fit in a double), or `as.numeric()` in `wet_snap_pick()`. `watershed_feature_id` is `integer` and is fine.

## Checked and found correct (no action)

- STN_REGULATION has a unique index on STATION_NUMBER, so the JOIN in `wet_station_select()` and the LEFT JOIN in the script cannot duplicate stations. `fwa_streams_watersheds_lut.linear_feature_id`, `fwa_watersheds_poly.watershed_feature_id` and `fwa_watersheds_upstream_area.watershed_feature_id` have no duplicates, so the snap joins cannot multiply candidates. DLY_FLOWS has no duplicated (station, year, month) rows.
- No DLY_FLOWS row has flow past the end of its month (Feb 29 in a non-leap year, Feb 30/31, or day 31 in a 30-day month), so the `IS NOT NULL` day count is a true day count. BC has no negative flows in 1981-2010.
- Report arithmetic: 251 + 2 + 118 + 137 + 352 = 860, the number of distinct BC stations with DLY_FLOWS rows in 1981-2010.
- `wet_station_monthly()` on the real selection returns 352 x 13 rows with no duplicates. I checked it against HYDAT's own MONTHLY_MEAN averaged over the same years: the median relative difference is -2e-5. The few larger differences (up to 13 %) are all months where HYDAT leaves MONTHLY_MEAN NA for partial months (FULL_MONTH = 0), so my probe dropped them and the function did not. They are not a defect in the function.
- No selected station has zero or negative annual flow. The 8 stations with no gross area are all rejected with the right reason.
- Station and wet_mm_to_m3s tests pass: 34 tests, none failed or skipped (run against a copy, with local fwapg and HYDAT).
