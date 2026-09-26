# Code review, round 1: staged diff for wet#2 (join-free upstream sums)

## Findings

- **[severity: fragile]** R/wet_upstream_mean.R:35-58: `irregular_pairs` defaults to `NULL`. When it is `NULL`, `wet_upstream_sums()` leaves the irregular polygons out of every sum (`num`, `area_cov` and `area`) and records them only in `attr(, "irregular")`. `wet_upstream_mean()` then throws that attribute away without a warning. The exported function's own docs say it accumulates "over the `FWA_Upstream` set of every watershed". Called the obvious way, `wet_upstream_mean(ws, values)`, it returns numbers that look right but are wrong for part of the basin.
  - Measured on the Salmon basin (`wet_ws_fetch(conn, "100.591289")`: 12,481 polygons, 6 of them irregular), comparing accumulated area with the stored upstream area.
    - With `wet_upstream_irregular()` pairs: 0 mismatches (max relative difference 8e-15).
    - Without the pairs: 359 watersheds wrong, up to 100% relative error.
  - The scripts always pass `irr`, so the parity results reported for SALR are not affected. The risk is to any other caller.
  - Fix: at minimum, warn when `irregular_pairs` is `NULL` and `attr(s, "irregular")` is non-empty.

- **[severity: fragile]** scripts/mad_parity.R:90-95: the "headwater group" guard checks `parity$coverage[grp] < 1 - 1e-12`. `parity` is built with `upstream_area = stored`, so this coverage is `area_cov / stored`. The stored `fwa_watersheds_upstream_area` is the snapshot that the diff itself shows can disagree with the live polygons.
  - Where stored is larger than live, a fully covered group fails the check and the script stops falsely.
  - Where stored is smaller than live, the ratio is inflated, so a group with real uncovered ground can pass. Its parity figures would then be computed with missing upstream values.
  - It is correct for SALR today: stored equals live to 8e-15 across the whole Salmon basin once the irregular pairs are included. So this is latent, for other groups.
  - Fix: guard on `live$coverage`, which uses the accumulated area.

## Verified clean (no issue found)

- **Range logic and key construction** in `wet_upstream_sums()`:
  - Checked by hand against the live `fwa_upstream(ltree x4)` definition pulled from the DB, including each irregular-a case: L sorts before W (not an ancestor), L is an ancestor of W, L sorts at or after `W/`, and L equals a tributary's wscode.
  - `"W L"`, `"W!"`, `"L/"` and `"W/"` all bound correctly in byte order, and the intersection comes out empty or equal to R1 in exactly the right cases.
  - Fuzzed 1,500 adversarial trees against the brute-force oracle: labels near 000001 and 999998, deep localcodes, localcodes set to tributary, sibling and ancestor wscodes, `"100"`, and off-tree codes. 0 mismatches (tolerance 1e-12).
- **Real-data code shapes**: the fixed-width label assumption holds in 6 groups (FRAN, LFRA, PARS, QUES, THOM, SALR): 0 wscode or localcode values outside `^[0-9]{3}(\.[0-9]{6})*$`, and 0 NULL codes.
- **Helpers**: `wet_count_lt` handles ties correctly (queries sort before equal elements), and the segment-tree indexing, build and query are correct, including a single leaf and empty or inverted ranges.
- **`irregular_pairs` merge**: `rowsum` rownames round-trip to the correct row indices (the `ia` values are integer, so there is no `1e+05` formatting). Pairs whose `a` lies outside `ws` are dropped correctly. The SQL includes the self pair.
- **`wet_upstream_mean()` semantics** (with pairs): fuzzed 200 trees against a brute-force mean with absent polygons, NA values and NA cover, in both denom modes. 0 mismatches.
  - No-data gives `NA`, not 0.
  - The numerator is cover-weighted.
  - The NA guard is on `area_cov > 0`, which cancellation cannot fake, because it is exactly 0 only when every term is 0.
  - The `upstream_area` override is matched by id and errors on missing rows.
- **SQL**: `wet_ws_fetch`, `wet_upstream_irregular` and `wet_ws_geom` are parameterised and input-validated. The irregular SQL's validity test (`NOT localcode <@ wscode`) matches the R `valid` definition.
- **`wet_pcic_annual`**: the per-year sum is averaged over the years, which is equivalent to `-timmean -yearsum`. An incomplete year still errors in `wet_runoff_annual`.
- **Test suite**: passes.
