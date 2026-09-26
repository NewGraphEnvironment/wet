# Code review, round 4 (staged diff, #1 Phase 3/4)

Scope: (a) the round-3 fixes, which are `num <- tapply(v * a * cv, key, sum)` used for both denominators in `R/wet_upstream_mean.R`, and `n_flip` in `scripts/mad_parity.R`; (b) the sites round 3 marked correct.

## Findings

- **[severity: fragile]** R/wet_upstream_mean.R:49 (`any_value <- tapply(has, key, any)`). The round-3 fix made the numerator weight by cover, but the no-data guard still tests `has`, meaning "a value is present". It should test "some ground is covered". The two now disagree when a value is present but its `cover` is 0 or `NA`: line 39 turns `NA` cover into 0, so that polygon adds nothing to `num`. If it is the only valued polygon upstream, `any_value` is still TRUE, so `total` mode returns **0** (zero flow) instead of `NA`. That is the round-1 bug again: no data encoded as 0. `covered` mode returns `NA` for the same input, so the two modes disagree about whether data exist.
  - Checked in R: one watershed with upstream polygons 1 and 2 (100 m² each, `up` = 200), polygon 1 `value = 10`, polygon 2 `value = NA`.

    | cover of polygon 1 | `total` value | `covered` value | `coverage` |
    |---|---|---|---|
    | `NA` | **0** | NA | 0 |
    | 0 | **0** | NA | 0 |

  - Reach: not reachable from `wet_ws_sample()`. There, `cover > 0` exactly when `value` is present: centroid gives `cover = !is.na(value)`, and area gives value `NA` whenever `cov == 0`. So no reported number is affected, and parity is unaffected. It is reachable from any hand-built or third-party `values` table, which the exported function accepts without checking. Round 3's line-38 verdict ("a value with cover = NA counts fully in total but is dropped in covered") no longer describes the code. After the fix, that value is dropped in both modes, and in `total` mode it can now produce a false 0.
  - Fix: `any_value <- area_cov > 0`. Then `total` and `covered` share one definition of "no data". In the pipeline it is identical to the current guard, so the tests and fwapg parity are unchanged.

## Round-3 fixes

- `num <- tapply(v * a * cv, key, sum)` for both modes is complete. Numerator and denominator are the same covered-ground population in `covered` mode. In `total` mode, uncovered ground now adds nothing whether it is a whole polygon or part of one. With centroid sampling, `cv` is 0 or 1 and equals `has`, so fwapg parity is unchanged. The only defect in it is the stale guard above. `devtools::test()` passes.
- `n_flip` is correct and complete for its purpose. `j` is an inner merge, but both builds come from `wet_upstream_mean()` over the same `pairs`, so they have identical id sets and the merge drops nothing. `is.na(p) != is.na(s)` counts both directions of change. The median, 1-99% range and ">5%" share still exclude flipped watersheds, but the count is now printed beside them, so the change is visible. For `centroid/covered` against `centroid/total`, `n_flip` is always 0 in the pipeline, because both modes are `NA` exactly when no upstream polygon has a value. That is expected, not a defect.

## Round-3 enumeration re-checked

Apart from the stale line-38 verdict (finding above), I found no site marked correct that is wrong. I re-verified these:

- **Scenario runs and the standard-calendar time index** (`wet_pcic_index`, used by `wet_pcic_fetch(run = ...)`). A 365-day or 360-day GCM calendar would shift the requested window. I checked the OPeNDAP DAS for CanESM2, HadGEM2-ES, CCSM4 and ACCESS1-0 rcp85: all are `calendar "standard"`, `days since 1945-1-1`. No issue.
- **mad_parity.R:80-81, extent check.** `terra::project(SpatExtent)` densifies. A 600 × 200 km BC Albers extent projects to the same envelope as a 1 km-densified polygon, so the within-bbox guard cannot pass on corner points while an edge bulges out.
- **fwapg reference** (`discharge02_load.sql`, `discharge03_wsd.sql`, `discharge.sql`, `discharge.sh`):
  - centroid in 3005, then `ST_Transform`, then `ST_Value`;
  - `SUM` skips absent or `NULL` polygons over the precomputed `upstream_area_ha`;
  - order ≥ 8 mainstem watersheds are excluded from `src`;
  - the 5-decimal rounding is at the watershed level;
  - all `02_load` groups finish before any `03` runs.

  These match round 3's reading and the script's handling (extra wet rows for order-8 watersheds are dropped by `merge(all.x = TRUE)`).
- The remaining `wet_ws_sample`, `wet_runoff_annual`, `wet_pcic_index`, `wet_pcic_fetch`, `wet_upstream_pairs` and `wet_mm_to_m3s` verdicts hold as written.
