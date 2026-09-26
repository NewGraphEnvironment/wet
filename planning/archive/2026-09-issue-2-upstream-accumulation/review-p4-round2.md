# Review: Phase 4 (`scripts/mad_basin.R`, research write-up), round 2

Verified by rebuilding the attribution state in R: `scripts/mad_basin.R` lines 16–202 without area sampling, with `devtools::load_all()` and the cached PCIC files. The scratch code is `r2build.R` and `r2c1.R`–`r2c5.R` in the session scratchpad. The rebuild reproduces the report's cause counts exactly.

## Findings

- **[bug] scripts/mad_basin.R:186-193: the lookup test matches `mad_mm` only, and 3 of its 4 "reproduced" watersheds are coincidences.**
  - The test takes any other watershed on the same `blue_line_key` whose `mad_mm` lies within `tol()`. It never checks `mad_m3s`.
  - On a long mainstem, consecutive watersheds differ by only a few hundredths of a mm. On BONP `blue_line_key` 356363594 there are 501 watersheds, with a median spacing of 0.0079 mm against a tolerance of about 9e-6 mm. A hit within tolerance is therefore likely by chance.
  - The 4 BONP segments labelled "lookup older (reproduced)" (watersheds 8529934, 8532377 and 8535749) each match another watershed's `mad_mm` but not its `mad_m3s`. The m³/s tolerance there is about 5.5e-6.
    - 8532377: fwapg reads 6.77255 m³/s, but the "matching" watershed 8531057 reads 2.99242 m³/s. Its stored upstream area is 2,365 km², against 5,352 km² for this watershed. It is a different place on the river.
    - 8529934 matches 8534647: m³/s off by 3.1e-4.
    - 8535749 matches 8532589: m³/s off by 3.4e-4. Its `mad_mm` difference of 8.69e-6 is just inside the 9.0e-6 tolerance.
  - All three watersheds are stale: stored upstream area is 50,837 m² below the live area, the same shortfall as the 9633006 example. Before step 3 overwrote them, they were correctly headed for the "stored area stale" label.
  - Only LILL 7837044 is a real lookup case. It matches 7608754 on both columns: m³/s off by 3.3e-6, mm off by 5.3e-6.
  - **Fix:** also require `abs(o_m3s − mad_m3s) ≤ tol(mad_m3s)`, using `emu2$mad_m3s`. With that change the causes become:

    | Cause | Segments | Watersheds |
    |---|---|---|
    | lookup | 10 | 1 |
    | stale | 786 | 502 |
    | centroid flip | 1,197 | 751 |
    | never valued | 196 | 102 |

- **[bug: wrong numbers] research/fwapg_mad_method.md:86, 87, 90; planning/active/findings.md:101: these counts come from the bug above.**
  - "14 | 4" should read 10 | 1.
  - "782 | 500" should read 786 | 502.
  - "first three causes (1,407 segments)" should read 1,403.
  - "The fourth (782 segments)" should read 786.
  - findings.md "14 from an older fwapg lookup; 782 stale" needs the same corrections.

- **[fragile] scripts/mad_basin.R:166-182, 219-223: a spurious flip cannot be detected, because segments that the flips break are never counted.**
  - Only open mismatches are classified (`open_() & ok2`). Nothing counts segments with `same & !ok2`, that is, segments that matched fwapg before and fail under `emu2`.
  - The rebuild-and-compare guard does not stop a spurious flip either. In fwapg mode, `mad_m3s = mad_mm · stored area / const` on both sides, so the m³/s half of `match_fw` adds nothing beyond the mm check. Any flip that closes a watershed's mm gap therefore also "reproduces" it.
  - The risk grows downstream. The acceptance window `tn = tol(mm) · stored area` grows with area: about 1e7 mm·m² at 2e11 m². The deltas of the 466 candidates are spread over about 1e5–1e9. So on a large stale watershed with many candidates upstream, some near-edge polygon's delta can match the stale gap by chance. That flip would then be labelled "reproduced", and it would silently break matched segments between the polygon and that watershed.
  - It has not happened in this run. `seg$same & !ok1` = 0 and `seg$same & !ok2` = 0, and the 5 flips are the same 5 that round 1 verified by hand (10395424, 8460328, 10099666, 8936758, 8546788; none stale). But the script takes any `WSCODE`, and it would report such a case as a clean attribution.
  - **Fix:** report `sum(seg$same & !ok2, na.rm = TRUE)`, and treat a non-zero count as a failure of the flip set. A genuine flip cannot break a matched segment. A spurious one almost always does.

- **[minor, wrong claim] research/fwapg_mad_method.md:84; planning/active/findings.md:106: the distance and mechanism claims do not match the evidence.**
  - **Distances.** The 5 flipped centroids lie 0.020 m (STHM, y edge) to 0.431 m (USHU) from an edge, not "1 cm to 0.6 m". That range was round 1's loose conversion, and the script's own `dx_m`/`dy_m` give 0.020–0.431.
  - **Mechanism.** "fwapg's centroids came from another FWA geometry version or PROJ pipeline" is stated as fact but was inferred by elimination.
    - None of the 5 flipped polygons is stale: their stored upstream area equals the live area to 1e-9. That is weak evidence against a geometry change.
    - The PROJ route was not tested.
    - The `ST_Value` check ran on a raster rebuilt from the PCIC grid. The local DB holds no fwapg raster table, so fwapg's own `cdo`/`raster2pgsql` raster was not compared.
  - Phrase the mechanism as a likely explanation.

## Checked and fine

- **`up_of()`** is an exact transcription of `whse_basemapping.fwa_upstream(ltree×4)` as defined in the local DB, including the `localcode_b <@ localcode_a` guard and the `localcode_b <@ wscode_a AND localcode_b > localcode_a` guards.
  - `withr::with_collate("C", …)` does switch R's `>` to byte order. Under the session's `en_US.UTF-8` locale, `"a" > "B"` is FALSE by default and TRUE under C.
  - I compared `sum(area_m2[up_of(a, all polygons)])` with the accumulated upstream area for 40 random watersheds, 20 with irregular pairs and the 5 flip sources. The maximum relative difference is 3.1e-14. Irregular candidates are handled, because the function evaluates the SQL predicate directly.
- **Tolerance units** are consistent. In fwapg mode, `emu1$mad_mm = num / stored`, so `(fm − emu1_mm)·up_a` is the numerator gap in mm·m². `tn = tol(fm)·up_a` is the mm tolerance on the same scale.
- **`fw_mm`** is safe. No watershed has a mix of NA and valued fwapg segments, and none has more than one distinct fwapg `mad_mm`. `fm` is never NA, and the `if (abs(gap) <= tn)` test cannot fail on NA.
- **The rest of the Fraser parity section matches the run.**
  - Report and parquet: 99.782 %, 2,189, 56/69, 9,529/7,720/10, 466 near-edge centroids, 5 flips, 1,197/751, 196/102.
  - Sensitivity: −13.56/+24.11 %, 10.178 %, 54 segments, +716 %, 12,723/162, 29.
  - Hope: 2,476/2,477/2,664, 216,659 km².
  - Run log: 3.35 GB = 3,353,034,752 B maximum RSS; 3.4 min.
  - The order-1 flip sources (NICL, UFRA, USHU) and order-5 ones (LNTH, STHM) are confirmed from segment stream orders.
