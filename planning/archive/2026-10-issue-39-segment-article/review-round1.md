# Code review, round 1: staged diff for #39 (data-raw/segment_vignette_data.R, data-raw/segment_vignette_map.R)

## Clean

No issues found.

### What was checked, with probes (2026-10-06, local fwapg and data/ on this machine)

- **integer64**: every new fwapg id is cast in SQL (`watershed_feature_id::int`, `count(...)::int`, `max(...)::int`). `cal$linear_feature_id` comes from `data/wb/stations.rds` as a double (measured: class `numeric`, max about 1.6e8), so `as.integer()` is exact, and the `!anyNA` guard would catch an overflow. Both scripts keep their `no64` guards.
- **`fw_sk` uniqueness**: no calibration watershed has more than one distinct non-null `mad_mm` (query over all 290 watershed ids returned 0 rows), so `!anyDuplicated` holds and `match()` is well defined.
- **`!anyNA(near$fwapg_mm)`**: all five SALR-area gauges (07ED001, 08JE001, 08JE004, 08KC001, 08KC003) have a non-null fwapg value, so the guard, which is tighter than the old `setequal`, passes.
- **Parity summary**: `data/parity/SALR_parity.csv` has 9,000 rows, no zero `mad_m3s_fwapg` (so `max_rel_diff` cannot be Inf or NaN), and all 9,000 match at 5 decimals. Note: the largest absolute difference is 4.999e-6, right at the half-step of the 5-decimal rounding. The equality guard is deterministic for a given input, and if it ever flips it fails loudly; it does not silently write a wrong value. Not a defect.
- **`in_pcic` assertion**: a non-NA `fwapg_mm` implies the group has a value, so it is in `fwapg_groups`. These are the same definition, so the assertion holds by construction.
- **Zone codes**: the map's `sprintf("%02d", HYDZN_NO)` matches the calibration `zone` codes ("01" to "29", measured in the current segment_values.rds). The rebuilt segment_map.rds holds 29 zones, all MULTIPOLYGON, EPSG 3005. `station_map.rds$bc` is EPSG 3005, so `st_intersection` with `bc_box` has matching CRS. In `st_as_binary(precision = 0.01)`, `round(x * 0.01) / 0.01` gives 100 m, as the comment says.
- **Coverage**: one valid MULTIPOLYGON. `places` covers both BULK and the SALR context box, with no duplicate names. `context_streams` has 462 features.
- **Budget**: segment_map.rds is 223 KB plus the current segment_values.rds at 225 KB, which already includes the 9,000-row parity frame that this change removes. That is under the 500 KB `budget_kb`.
- **SQL**: the `sprintf` `%f` envelope values are finite bbox numbers. The `IN (...)` lists are built from internal integer ids and group codes, not user input.
