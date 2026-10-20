# crate#33 review, round 3 (`origin/main...33-segment-daily-schema`, dc8bc41)

Scope: dc8bc41 (round 2's fixes) and the whole branch diff (0156b4f, ab3e701, d507dfb, dc8bc41). origin/main has
not moved under the branch (`git log HEAD..origin/main` empty after fetch). Tests in a scratch clone at dc8bc41:
`NOT_CRAN=true devtools::test()` gives 433 pass, 0 fail, 0 error, 0 skip. dc8bc41 touches only
`segment_daily.yaml`; the registry row, README block, CLAUDE.md line, segment_monthly `period` fix and the tests
are unchanged since round 2 and still correct.

YAML parse (`yaml::read_yaml()`): the description folds to its three paragraphs plus the opening one, each one
line; every `notes` folds to one line as intended. Round 2's Nit 2 (wrapping) is fixed.

Code checked: wet `R/wet_routed_days.R`, `R/wet_shape_predict.R`, `R/wet_doy_month.R`, the uncommitted
`scripts/segment_daily_output.R` (the producer), `scripts/segment_output.R`, `scripts/wb_output.R`,
`scripts/pcic_routed_lib.R` (uncommitted diff), `scripts/discharge_publish.R` (daily parts, lines 341-364);
fwapg `origin/newgraph` (7c30f58) `pcic_crosswalk01_days.sql`, `_08_periods.sql`, `_09_discharge.sql`.

## Arithmetic: 37 / 847

1981-2010 is 30 years; its leap years are 1984, 1988, 1992, 1996, 2000, 2004, 2008 (7; 2000 is divisible by
400). fwapg's `pcic_day_bins.n_days` is `count(*)` of the period's dates per (month, day)
(`_01_days.sql`), so every common day has 30 and 29 February 7. `wet_routed_fold()` gives the folded 28 February
`n[feb28] + n[366]` = 30 + 7 = 37 (`wet_routed_days.R:50`). February holds 28 x 30 + 7 = 847 day-years
(checked by enumerating the dates in R: 847 February dates, 37 of them on the 28th or 29th). 37/847 = 0.0437 vs
1/28 = 0.0357. Correct.

## Claim table

### description

| # | claim | verdict | checked against |
|---|---|---|---|
| 1 | Mean daily discharge per FWA segment, on each day of a 365-day common year | true | producer writes `doy = 1:365` per segment (`segment_daily_output.R:196,240`) |
| 2 | Published by wet (wet#99) as Hive-partitioned parquet at `s3://fresh-bc/discharge/fwa/v1/segment_daily/`, beside segment_monthly | true (as built; not yet uploaded) | `discharge_publish.R:13,145,355` |
| 3 | The file_name is the dataset ID, from which the S3 prefix and the table `discharge.fwa_v1_segment_daily` derive | true | registry `file_name`; `wet_segment_daily.R:21`, `wet_db_load.R:13` |
| 4 | One row per segment, day and source with a value | true | 365 rows per balance and routed segment of the monthly table; `!anyNA(q_m3s)` and no duplicate (segment, source, doy) asserted (`segment_daily_output.R:249,278`) |
| 5 | Hive keys `scenario`, `forcing`, `source` are in the path, as in segment_monthly | true | `publish_part_prepare()` drops `source`; `part_path(ds_day, src, g)`; crate test "Hive keys are not declared" covers segment_daily |
| 6 | Each part file holds one FWA watershed group (`part-<GROUP>.parquet`) | true | `discharge_publish.R:345-355` (one file per group per source; refuses a segment of another group) |
| 7 | so a one-group read opens one file | partly true | one file per source; a one-group read of both sources opens two (Nit 1) |
| 8 | Each day is the mean flow on that day of the year over the period | true | routed: fwapg's day bins over the run's period; balance: 1981-2010 months on a shape fitted over gauges' complete years within 1981-2010 (`wet_station_select(years = 1981:2010)` default, `wb_shape_daily.R:145`) |
| 9 | 29 February is folded into 28 February | true | `wet_routed_fold()` n_days-weighted fold (`:42-50`); balance laid on `wet_doy_days()` (February 28) |
| 10 | wet_balance days are its published months laid out with a within-month shape fitted at HYDAT gauges | true | `wet_shape_predict()` donor = `wet_donor_mean()` of calibration gauges' observed day-of-year weights; producer refuses anything but `shape$method == "donor"` (`:67`) |
| 11 | so the mean q_m3s of a calendar month's days is that month's segment_monthly value | true (to 1e-9 relative) | `wet_shape_daily()` `q*n*w` with weights summing to 1 per month; producer refuses a relative miss over 1e-9 (`:166-172`); segment_monthly's balance q is `output/`'s `discharge_m3s` unrounded (`segment_output.R:168`) |
| 12 | pcic_routed: each day is routed and clamped at zero on its own | true | `pmax(raw, 0)` per column of `wet_routed_raw()` (`segment_daily_output.R:208`); the folded 28 Feb is one routed bin, clamped once |
| 13 | as each month is in segment_monthly | true | `_08_periods.sql` averages q_local/q_acc by n_days, then `_09_discharge.sql` routes and `greatest(r.q, 0)` |
| 14 | both the days and the months are rounded to 5 decimals | true | days `wet_routed_round()` (`:208`); months `round(greatest(r.q, 0)::numeric, 5)` (`_09`). Month 0 (mean of 12) is not rounded, but the sentence says months |
| 15 | (wet_balance is not rounded) | true | no `round(` on q_day or the depths in the producer, `segment_output.R`, `wb_output.R` or `publish_part_prepare()` |
| 16 | so a month's days need not average to its published value | true | the producer's own "plain mean ... against the published month" tally (`:228-233`) |
| 17 | where a clamp applied their mean is at or above it | false by under 1e-5 | true before rounding (max(x, 0) convex; outside February every n_days is 30, so plain = weighted mean), but rounding can put it below (Bug 1) |
| 18 | 28 February also carries 29 February's flow | true | fold, claim 9 |
| 19 | which the published month counts by how many times the period holds each day | true | `_08_periods.sql`: `sum(q * n_days) / sum(n_days)` |
| 20 | 28 February's row stands for 37 of February's 847 day-years in 1981-2010, not 1 of 28 | true | arithmetic above |
| 21 | There is no annual row | true | producer writes doy 1-365 only |
| 22 | month 0 of segment_monthly is not the mean of the 365 days | true (as a definition) | routed month 0 is the plain mean of 12 months (`segment_output.R:154`); balance month 0 is the annual over 365.25 days (`wb_output.R:50,70`); neither is a 365-day mean |

### column notes

| # | column: claim | verdict | checked against |
|---|---|---|---|
| 23 | linear_feature_id: key with doy and the Hive keys | true | no duplicate (segment, source, doy) per part, one scenario/forcing per path |
| 24 | watershed_group_code: the segment's FWA group | true | not written by the producer; added at publish from `fwa_stream_networks_sp` and checked against the file's group (`discharge_publish.R:348-349`) |
| 25 | doy: 1 is 1 January, 59 is 28 February (29 Feb folded in), 365 is 31 December | true | `wet_doy_md()`: 2001-01-01 + 0:364, so doy 59 = `02-28`, 365 = `12-31` |
| 26 | runoff_mm: depth over the segment's upstream area on the day, mm/day | true, as segment_monthly defines it | `q * 86400 / upstream_area_m2 * 1000` of the segment's lut watershed (`:174,197,241`), the area the monthly row used |
| 27 | runoff_mm: for wet_balance a month's days sum to its segment_monthly runoff_mm | true (1e-9) | monthly mm and q share `wet_month_days()` (`wb_output.R:70`); producer refuses a relative miss over 1e-9 (`:176-183`). Round 2's Phase 4 pin is in the producer |
| 28 | except in February, 28/28.25 of it | true | `want <- mm_mon * n_m / wet_month_days()`, `n_m` February 28 |
| 29 | runoff_mm: NA for a routed row off its watershed's own line | true | `area_mm` NA exactly where the monthly month-0 routed row's runoff_mm is NA (`:235-238`); the other monthly NA case (no accumulated area) is 0 in the tracked report |
| 30 | q_m3s: mean discharge on the day, m3/s | true | |
| 31 | coverage: share of the upstream area the balance's inputs cover, 0-1 | true | balance rows copy the monthly month-0 coverage (`:198`), which is `rep(up$coverage, 13)` (`wb_output.R:71`), so the same in every month |
| 32 | coverage: NA for routed rows | true | `coverage = NA_real_` (`:241`) |
| 33 | period: 1981-2010 for both sources in the historical scenario | true | balance `period_balance <- "1981-2010"` (`segment_output.R:122`); routed `routed_run$period` (1981-2010 since #103), and the daily inputs are read under the same `routed_where` (`pcic_routed_lib.R`, `routed_daily_inputs()`) |
| 34 | pick: the segment's default source, the same as in segment_monthly on every day | true | copied from the monthly month-0 row (`:199,242`); monthly pick is one per segment for all 13 months (`segment_output.R:170,185`) |
| 35 | pick: exactly one row per segment, day and scenario is TRUE | true | asserted per piece (`:249-250`) and again per group file at publish (`discharge_publish.R:350-351`) |
| 36 | pick: wet_source_pick(), wet#57 | true | `segment_output.R:160` |

## Bug 1: `segment_daily.yaml:22-23`, "where a clamp applied their mean is at or above it" fails after rounding

Before rounding the claim holds: max(x, 0) is convex, so the n_days-weighted mean of clamped days is at or above
the clamped month, and outside February every n_days is 30, so the reader's plain mean is that weighted mean.
But the same sentence says the days and the month are each rounded to 5 decimals, and that can reverse it by up
to 1e-5. Reproduced: 30 days, one raw day at -1e-7 and 29 at 1.000004. The days publish as 0 and 29 x 1.00000,
plain mean 0.96666667; the month is round(max(mean(raw), 0), 5) = 0.96667. The clamp applied and the days'
mean is 3.3e-6 below the month. (Round 2 noted "a strict gap under 5e-6 can round to equal or below", but its
proposed text still said "at or above".) The producer's report records the largest gap below (`consist[["max_below"]]`),
so a reader of that report can see it.

Fix: hedge by the rounding, e.g. "where a clamp applied their mean is at or above it, to within 1e-5 of
rounding". Or drop the direction: "where a clamp applied their mean can sit above it".

## Nit 1: `segment_daily.yaml:12-13`, "so a one-group read opens one file"

`source` is a path key, so each group has one part per source (`discharge_publish.R:352-355`), and a one-group
read of both sources (`wet_segment_daily()`'s default `source = c("pcic_routed", "wet_balance")`) opens two.
Fix: "so a one-group read opens one file per source".

No other findings.
