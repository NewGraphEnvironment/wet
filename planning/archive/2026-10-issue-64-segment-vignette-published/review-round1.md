# Code review, round 1 (#64, branch 64-segment-discharge-vignette-lead-with-the)

Scope: `git diff <merge-base>...HEAD` (R/wet_values_compare.R, its test, scripts/discharge_publish.R,
data-raw/segment_vignette_data.R, data-raw/segment_vignette_map.R, vignettes/segment-discharge.Rmd,
tests/testthat/test-vignette_data.R, inst/cartography/wet_segment.csv).

What was run (nothing written to the repo, S3 or a database):
- `NOT_CRAN=true` `testthat::test_file()` on test-wet_values_compare.R (13 pass) and test-vignette_data.R (all pass).
- The vignette rendered from a copy in the scratchpad (`rmarkdown::render` after `load_all`): builds clean, every
  stopifnot passes, prose numbers consistent with the bundled rds (2,180 of 2,181 SALR segments, 290 of 315 gauges,
  published_check 2180 and 2469 compared, 0 differing).
- Probes of `wet_values_compare()` on non-finite values (below).

## Findings

- **[fragile]** R/wet_values_compare.R:62 — with the default `tol = 1e-9`, a non-finite value on one side passes
  as equal. `far <- !is.na(d) & d > tol * pmax(abs(va), abs(vb))`: for `va = Inf, vb = 5`, `d = Inf` and
  `tol * Inf = Inf`, so `Inf > Inf` is FALSE; `Inf` against `-Inf` passes too. Measured:
  `wet_values_compare(fr(1L,0L,Inf), fr(1L,0L,5))` returns `differing = 0, max_abs_diff = Inf`. With `tol = 0`
  the same pair gives `0 * Inf = NaN`, so `differing = NA`, which downstream turns into an
  "missing value where TRUE/FALSE needed" error rather than a named failure. The tolerant calls are the routed
  month-0 checks (scripts/discharge_publish.R "routed month 0 = mean of 1-12", data-raw/segment_vignette_data.R
  "routed (SALR and gauges) = fwapg mean of 12 months"), so a published Inf there against a finite source would
  be reported as 0 differing: a guard that fails toward pass. Low likelihood with today's data (no Inf exists),
  but it is the exact case a value check exists to catch. Fix: count `is.finite(va) != is.finite(vb)` (or
  `xor(is.infinite(va), is.infinite(vb))` plus sign mismatch) as differing, and compare the tolerance only
  where both are finite.

- **[fragile]** data-raw/segment_vignette_data.R:320 — `src_r <- unique(rbind(seg_routed, ra))` dedups the two
  `routed_annual()` results (SALR segments, gauge segments) by exact value. Each is a separate `avg(q_m3s)`
  query; a float8 `avg` depends on the order rows are aggregated, and a different plan for the two IN lists
  (e.g. a parallel scan with partial aggregates for one of them) can give last-bit-different means for a
  gauge segment that is also an SALR order >= 3 segment. `unique()` then keeps both rows and
  `wet_values_compare()` stops with "`b` has a feature and month twice". Loud, not silent, and it passed on
  this run; dedup by `linear_feature_id` (`src_r[!duplicated(src_r$linear_feature_id), ]`) or one
  `routed_annual()` call over the union of ids removes it.

- **[fragile, low confidence]** scripts/discharge_publish.R:888,938-945 — `routed_total` sums
  `round(q_m3s * 1e6)` in R and compares it as a string with the fingerprint's
  `sum(round(q_m3s::numeric, 6))` from Postgres. The two round differently: Postgres casts float8 to numeric at
  15 significant digits and rounds half away from zero; R rounds the binary product `q * 1e6` half to even. A
  value whose 7th decimal sits at a half-way point after the 15-digit cast can round one way in each, moving
  the total by 1e-6 and FAILing `routed_total` on a table whose every value is identical (the
  `routed_values` check already proves that exactly). It passed on the current table (40.5M values), so the
  values there may already be coarse enough; it would only ever be a spurious FAIL, never a false pass.

No other issues found. Checked and fine: the key arithmetic in `wet_values_compare()` (ids < 2^31, exact in a
double), one-sided keys and empty sides counted as differing, `rowsum()` on an empty drainage (returns a 0-row
matrix, so 800/945/990 compare 0 against 0), a missing part read as an empty frame (its table rows then count as
one-sided), the `compared ==` totals that stop a check of nothing from passing, the report regexes against the
tracked report's actual lines, md5 verification before and after the httpfs read, and the removed registry rows
(no remaining consumer of `product`, `parity`, `segment_map/key` or `skill_nesting/mae`).
