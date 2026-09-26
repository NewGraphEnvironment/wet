# Code review, round 2: staged diff for wet#2 (fixes from round 1)

## Findings

- **[severity: fragile]** R/wet_upstream_mean.R:74-78 and R/wet_upstream_sums.R:88-100: the round 1 fix is correct, but it only catches the case where `irregular_pairs` is `NULL`. If pairs are passed but some are missing, the irregular polygons still drop out without any message.
  - The guard is `is.null(irregular_pairs) && length(irregular)`. Pairs that are present but incomplete pass it silently:
    - `irregular_pairs` fetched with `wet_upstream_irregular(conn, "100.591289")` while `ws` came from `wet_ws_fetch(conn, "100")`;
    - pairs for only one of two `rbind`-ed basins;
    - an empty (0-row) data frame.
  - Duplicated pairs, for example from rbinding the pairs of overlapping basins, are summed twice by `rowsum()`, also with no message.
  - Verified with `random_ws(7, irregular = 4)` (14 polygons, 3 irregular) against `brute_upstream()`:
    - 0-row pairs: 8 of 14 upstream areas wrong, no warning;
    - one irregular polygon's pairs removed: 3 wrong, no warning;
    - pairs duplicated: 8 wrong, no warning.
  - An exact check is possible. `FWA_Upstream(b, b)` is true for every irregular polygon: all 1,457 of them province-wide in the local fwapg, and it also follows from the `Wb == Wa & Lb >= La` branch. So every id in `attr(, "irregular")` must appear in `irregular_pairs$id_up`.
  - Fix: in `wet_upstream_sums()`, warn or stop when `setdiff(irregular, irregular_pairs$id_up)` is non-empty (this also covers `NULL`), and reject duplicated (`watershed_feature_id`, `id_up`) rows.

- **[severity: fragile]** R/wet_upstream_sums.R:1-5, 35 (exported): `wet_upstream_sums()` itself has the same silent drop that round 1 fixed in the mean.
  - The title and first paragraph say it sums "over the set of polygons that fwapg's `FWA_Upstream(...)` counts as upstream". With the default `irregular_pairs = NULL` it does not, and it gives no warning.
  - Only the third paragraph mentions the exclusion. `@return` says the attribute holds the "ids of irregular polygons" but not that they were left out of the sums.
  - Verified: `wet_upstream_sums(ws, "area")` on `random_ws(7, irregular = 4)` gets 8 of 14 upstream areas wrong, with a maximum relative error of 1.0 (100%).
  - On real data round 1 measured 359 wrong watersheds in the Salmon basin, up to 100%. `wet_upstream_mean()`'s warning does not help direct callers of this function, and the package docs point users to it for "additive quantities".
  - Fix: move the warning (with the exact check from the first finding) into `wet_upstream_sums()`. `wet_upstream_mean()` then inherits it. `scripts/upstream_area_check.R:41` excludes the irregular polygons on purpose, so wrap that call in `suppressWarnings()`.
  - The current warning never fires spuriously. Every irregular polygon is at least upstream of itself, so a `NULL`-pairs result with irregular polygons present is always wrong for that polygon's own row, unless its area is 0.

- **[severity: fragile]** scripts/mad_parity.R:119, 152-163: coverage is still reported against the stored (possibly stale) `fwa_watersheds_upstream_area`. This is the assumption that round 1 fixed in the guard at line 94.
  - `parity$coverage`, written to `<WSG>_parity.csv`, and `s$coverage`, printed as "min coverage" and written to the sensitivity CSVs, are both `area_cov / stored`.
  - Dividing MAD by the stored area in parity mode is the accepted tradeoff. Coverage is different: it describes how much of the real upstream ground has data, so a stale denominator gives a wrong fraction and can exceed 1.
  - It is latent for SALR, where stored equals live to 8e-15.
  - Fix: report `coverage` from a live build, since `live$coverage` does not depend on the values' denominator mode.

## Verified clean (no issue found)

- **Round 1 fix 1 (warning in `wet_upstream_mean()`)**:
  - It fires whenever `irregular_pairs` is `NULL` and irregular polygons exist, and never otherwise.
  - The `"irregular"` attribute is kept on the result.
  - It does not fire on correct calls: complete pairs, a 0-row pairs table for a basin without irregular polygons, and the `chain` fixture.
- **Round 1 fix 2 (`scripts/mad_parity.R:94`)**:
  - The guard now uses `live$coverage`, which is the accumulated area with the irregular pairs included.
  - With cover equal to 1, `area_cov` and `area` sum identical leaves, so a fully covered group gives coverage of exactly 1 and cannot trip the `1 - 1e-12` threshold.
- **Pairs and area in `mad_parity.R` are consistent with each other**:
  - `irr` and `ws` are fetched with the same `basin` code.
  - The pairwise cross-check (lines 100-109) divides by the stored area, and so does `parity`.
  - A watershed with no stored row stops loudly (`"no upstream_area row"`) rather than dropping.
- **`scripts/upstream_area_check.R`** uses the stored table only as a first-pass reference and re-checks every mismatch against the live `FWA_Upstream` join. The `NA` merge rows are handled with `na.rm`, and the basin-mouth row is always included.
- **`wet_ws_sample()` with a data frame of points**: projects EPSG:4326 points to the raster CRS, uses the same `cover` definition as the polygon-centroid path, and refuses `"area"`.
- **Codes**: `wet_ws_fetch()` drops NULL-coded polygons with a warning (0 exist in the DB). `wet_upstream_irregular()` never returns such a polygon as `id_up`, because `NOT NULL <@ ...` is NULL.
- **Test suite**: passes.
