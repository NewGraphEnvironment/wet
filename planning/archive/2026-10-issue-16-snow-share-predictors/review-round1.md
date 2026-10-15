# Code-check round 1 (branch 16-snow-predictors-for-the-monthly-shares, diff 6fa5a0a...HEAD)

Reviewer: subagent, 2026-10-14. No repo file edited except this one. Probes ran in a scratch copy
(`git archive HEAD` of R/, tests/, inst/, DESCRIPTION, NAMESPACE) and against the cd cache on this machine.

## Findings

- **[fragile]** scripts/wb_inputs.R:376-377 (manifest rows for the cd layers) — reads `snow_cat$cd_sha` and
  `snow_cat$run_time`, which `cd_catalog()` returns only from cd 0.6.5 (cd NEWS: "cd_catalog() gains ...
  cd_sha, run_time", tag v0.6.5). DESCRIPTION declares `cd (>= 0.5.0)` in Suggests. Under cd 0.5.0 to 0.6.4,
  the tibble `$` returns NULL with a warning, `sprintf()` with a NULL argument returns `character(0)`, and
  `data.frame()` stops with "differing number of rows". That happens in the manifest step, after every
  input, the snow grid included, has been built. On a machine whose cd predates 0.6.5 (m4 has not been
  checked), `wb_inputs.R` fails at the end of a long run. `wet_snow_normals()` itself needs only
  `cd_catalog()` and `cd_cache_fetch()` (cd >= 0.4.0), so the floor that matters is the script's. Raise the
  Suggests floor to `cd (>= 0.6.5)`, or check `packageVersion("cd")` at the top of the script.

- **[fragile]** scripts/wb_share_snow.R:496-503 — the script reads `cv_aet-<AET>.rds` and restates the rule and
  its outcome (KEPT / NOT kept) in a tracked report. It never checks that the file was scored under the
  current code (`cvr$code_md5` against `score_code_md5`). `wb_aet_compare.R` (line 46) and
  `shipped_heldout()` (scripts/pcic_routed_lib.R:63-66) both refuse a cv file made under other code.
  A cv file left over from an earlier scoring run would produce a current-looking breakdown, and a
  `share_spec` that need not match `fits.rds`. It only prints the md5, which a reader cannot check by eye.
  The script states that it is not hashed, which is fine, but it can still `source("scripts/wb_score_md5.R")`
  and stop on a mismatch, as the other readers do.

- **[fragile, report accuracy]** scripts/wb_inputs.R:363-365 and :378-379 — `n_capped` counts cells over the
  whole cd file (`terra::mean()` over the full 0.1° extent, -140.05 to -113.95). `wet_snow_normals()` reads
  and caps only the grid extent plus a margin of two cells. Measured on the cached `swe_max_annual.tif`
  (etag e75574fc…): 590 cells over the whole file and 584 in the window `wet_snow_normals()` crops for the
  province grid (-139.1..-114, 48.2..60.1). So the manifest line "swe_max capped at 3,000 mm on 590
  ERA5-Land cells" overstates the number of cells the grid actually saw capped. The gap is small, but it is
  a tracked number. Count it on the same crop, for example
  `terra::crop(r, terra::extend(terra::ext(grid), 2 * terra::res(r)), snap = "out")`, with `na.rm = TRUE`
  as in the function.

## Checked and found sound (no action)

- `predict_cv()` with `share_specs`. The equal-n guard and the NA guard over the union of the static
  predictors hold. `share` is `sh[[1]]`. In `wb_validate.R`, `cv$share` is overwritten with the shipped
  specification before `cv_v`, `lo` and `plain` read it. `lo` and `plain` pass `share_specs = ship_share`.
  `monthly_vignette_data.R` passes the cv file's `share_spec`, or "base" for a fit made before #16. No other
  script calls `predict_cv()` (`wb_aet_compare.R`, `wb_pooled_test.R`, `wb_term_diagnose.R`,
  `wb_gauge_diversion.R` grep clean).
- The rule does not depend on the AET variant. `wet_share_fit()` uses the CGIAR monthly `aet_MM`, never
  `cal$raw`, and `cal` rows are the same for every variant.
- The upstream identity can hold. `wet_ws_sample()` sets coverage from `complete.cases()` over every layer,
  and the snow layers are mask-exact (the "mask must not have moved" assertion covers them).
  `wet_upstream_sums()` uses `rowsum()` column by column, so the added columns cannot perturb the others.
- The province fill loop terminates within its cap. The grid's top edge is 60.10001 and cd's is 60.05, so
  about 6 rows lie off the source and are filled by focal passes. That is well under 200.
- `wet_snow_normals()` is keyed on band values, not on the file. Tests pass in a scratch copy:
  `test-wet_snow_normals.R` 7/7 and `test-wet_share_fit.R` 4/4, with 0 failed and 0 errors (`NOT_CRAN=true`).
- The `discharge_publish.R` description is byte-identical to before when the spec is "base". The old
  `paste(a, b, c)` and the new `paste(c(a, b, c), collapse = " ")` give the same string.
- `wb_key_dir()` ignores `data/wb/_pre16` (no `upstream/_complete` directly under it). No other glob over
  `data/wb/*` would pick it up.
- The cd catalog has exactly one annual row each for `snowmelt_doy_50` and `swe_max`
  (cd_sha 349f9d7, 2026-10-10).
- Seven ERA5-Land land cells have no melt year (`swe_max` mean about -7e-22, `snowmelt_doy_50` NA in all 30
  years). They are filled with a neighbour's melt date like sea cells. The plan already records this, and
  it is negligible.

## Verdict

No bugs that would produce a wrong shipped number. Three fragile items: one late hard failure under the
declared cd floor, one missing staleness guard on a tracked report, and one misscoped count in the inputs
manifest.
