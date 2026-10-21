# crate#33 review, round 1 (`origin/main...33-segment-daily-schema`, ab3e701)

Scope: `git -C crate diff origin/main...HEAD` (0156b4f, ab3e701). Tests run in a `cp -r` copy:
`NOT_CRAN=true devtools::test()` gives 433 pass, 0 fail, 0 error, 0 skip.

Checked and found correct:
- Registry row `discharge/fwa/v1/segment_daily`: canonical_cols
  `linear_feature_id,watershed_group_code,doy,runoff_mm,q_m3s,coverage,period,pick` are the yaml's
  `canonical.cols`, in the same order. schema_yaml follows the `schemas/<source>/<file_name>.yaml` rule,
  the yaml's `file:` equals file_name, kind is `schema_only` with no handler, and every type is one crate
  implements. The integrity tests walk every registry row and every bundled yaml, so they cover the new
  row without being edited, as 536e8ed's design intended.
- README `crt_files()` block: 8 rows, in registry order (the daily row sits between segment_monthly and
  watershed_monthly, as it does in the CSV). There is no README.Rmd to regenerate.
- The doy note: 59 is 28 February (31 + 28), and 365 is 31 December, on wet's `wet_doy_md()` calendar.
- (a) wet_balance. `wet_shape_daily()` gives `q[d] = Q_m * n_m * w[d]` with `n = wet_doy_days()`
  (February 28) and weights summing to 1 per month (checked to 1e-8). So a calendar month's days average
  to `Q_m` exactly, February included, and the description's q_m3s claim holds. Monthly `Q_m` comes from
  `wet_mm_to_m3s(R_m, A, days = wet_month_days())` (28.25 for February; `scripts/wb_output.R:49,69`,
  `scripts/segment_output.R:118`). So the daily `runoff_mm = q * 86400 / A * 1000` sums over a month to
  `R_m * n_m / d_m`: equal to `R_m` in every month but February, where it is `R_m * 28/28.25`
  (0.99115). The runoff_mm note's claim holds (see Nit 2 on wording).
- (b) Routed days. `wet_routed_days()` (wet, uncommitted) clamps and rounds each day on its own, the
  monthly table clamps the n_days-weighted month mean, and max(x, 0) is convex, so where a clamp applied
  the days' mean is at or above the month. The direction stated is right. Bug 1 covers the incompleteness.
- The segment_monthly `period` fix (ab3e701) and the matching test fixture change are correct since
  wet#103.

## Bug 1: `segment_daily.yaml:19-21`, the routed month-consistency claim is false in February even with no clamp

The text says "For pcic_routed each day is routed and clamped at zero on its own, as PCIC's monthly flow
is per month, so where a clamp applied the mean of a month's days can sit above the published month."
That implies the days average to the published month wherever no clamp applied. In February they do not.
`wet_routed_fold()` folds 29 February into 28 February weighted by n_days (1981-2010: 30 years for each
common day, 7 for 29 February, so 28 February carries 37). `pcic.discharge_monthly` is the
n_days-weighted mean over the 29 bins, which gives 28 February 37/847 of the month. A reader of the
parquet sees 28 equal-weight rows and no n_days, so their plain mean gives 28 February 1/28 of the month.
The two agree only when 28 February equals the rest of the month's weighted mean.

The plan's own Phase 4 and 5 checks compare the n_days-weighted day mean, not the plain one, so they will
pass while the sentence stays false for the mean a reader can compute. A second, smaller gap: the days
and the month are each rounded to 5 decimals, so even with no clamp the mean of the days can sit up to
5e-6 m3/s below the month as well as above it.

The clause "as PCIC's monthly flow is per month" also reads as a reason when it is a comparison.

Fix: reword. For example: "For pcic_routed each day is routed and clamped at zero on its own, as each
month is in segment_monthly, so a month's days need not average to its published value: where a clamp
applied their mean sits above it, and in February 28 February also carries 29 February's flow, which the
published month weights by its number of days." Optionally add "both are rounded to 5 decimals".

## Nit 1: `segment_daily.yaml:48-49`, the runoff_mm February clause states the reason but not the size

"except in February, whose monthly depth is over 28.25 days" is true, but it does not say what the days
sum to, and the plan (Phase 2) promised to state it. Fix: "...except in February, where they sum to
28/28.25 of it (the monthly depth is over 28.25 days)."

Also, line 48 wraps past the others (about 90 characters). Rewrap the folded scalar.

## Nit 2: `tests/testthat/test-crt_registry_integrity.R:94-107`, the canonical_cols check is a subset, not equality or order

The check is `setdiff(from_registry, from_schema)`, so a schema_only row that omits a column, or lists
the columns out of order, passes. The new row is correct today (checked by hand above), but nothing pins
it. The comment allows a subset only for bcfp. Fix (optional, a crate-wide change, so it may belong in its
own issue): for `kind == "schema_only"`, `expect_identical(from_registry, from_schema)`.

## Out of scope (crate-wide, not this diff)

`crt_schema_conform()` coerces `doy = 1.5` to `1L` with no warning (probed), and no schema declares a
range, so a doy of 0 or 366 would pass. `month` in segment_monthly behaves the same way. wet should
assert `doy %in% 1:365` and `is.integer` itself before it conforms.

No NEWS entry is in the diff. That matches 536e8ed, whose NEWS line came with the release (Phase 2's
release step).
