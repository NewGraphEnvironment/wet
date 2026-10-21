# crate#33 review, round 2 (`origin/main...33-segment-daily-schema`, d507dfb)

Scope: the fix d507dfb and the whole branch diff (0156b4f, ab3e701, d507dfb). origin/main has not moved
under the branch (`git log HEAD..origin/main` empty after fetch). Tests in a `cp -r` copy at d507dfb:
`NOT_CRAN=true devtools::test()` gives 433 pass, 0 fail, 0 error, 0 skip.

YAML parse (`yaml::read_yaml()`): the description folds to the four intended paragraphs, each one line,
with no stray breaks; every column's `notes` folds to one line as written (the `runoff_mm` text reads
"...except in February, where they sum to 28/28.25 of it (the monthly depth is over 28.25 days). NA for
a routed row off its watershed's own line, where the only area available is another line's.").

Checked against the code and found correct:
- "29 February is folded into 28 February": `wet_routed_fold()` (wet `R/wet_routed_days.R:42-50`)
  replaces 28 Feb with the n_days-weighted mean of 28 and 29 Feb, and `doy` 59 is `02-28` on
  `wet_doy_md()`.
- "For pcic_routed each day is routed and clamped at zero on its own, as each month is in
  segment_monthly": `wet_routed_days()` clamps each day (`pmax(raw, 0)`), and fwapg's
  `pcic_crosswalk09_discharge.sql` clamps the period mean `greatest(r.q, 0)` after
  `pcic_crosswalk08_periods.sql` averages the bins `sum(q * n_days) / sum(n_days)`.
- "28 February also carries 29 February's flow, which the published month weights by its number of
  days": 08_periods.sql weights each of the 29 February bins by its `n_days`, so the folded 28 Feb row
  stands for 37 of 847 day-years in 1981-2010 (round 1's Bug 1 is fixed in substance).
- wet_balance "the mean q_m3s of a calendar month's days is that month's segment_monthly value":
  `wet_shape_daily()` is `q[m] * n[m] * w` with `n = wet_doy_days()` (February 28) and refuses weights
  that do not sum to 1 per month (`R/wet_shape_predict.R:96-107`).
- runoff_mm February clause (round 1's Nit 1, fixed): monthly depth is over `wet_month_days()` (28.25),
  so 28 daily depths derived from q sum to 28/28.25 of it. See the Phase 4 pin below.
- "NA for a routed row off its watershed's own line": the only other NA case in `segment_output.R:278`,
  routed segments with no accumulated area, is 0 in the tracked report
  (`data/checks/segment_output_*.txt:16`).
- Registry row, README `crt_files()` block, CLAUDE.md status line, segment_monthly `period` fix and its
  fixture, and the new conform test: as round 1 found; nothing in d507dfb touches them.

## Bug 1: `segment_daily.yaml:23`, "Both are rounded to 5 decimals." can be read as both sources, and wet_balance is not rounded

The paragraph contrasts two sources, and the same file's `period` note (line 65) uses "both sources", so
"Both" reads most easily as wet_balance and pcic_routed. Only pcic_routed is rounded: fwapg's
`round(greatest(r.q, 0)::numeric, 5)` and `wet_routed_days()` (`wet_routed_round()`). The balance is
never rounded: `wet_shape_daily()` has no `round()`, `segment_output.R:166` writes `bm$runoff_mm` and
`bm$discharge_m3s` as `wb_output.R` left them, and there is no `round(` in `wb_output.R`,
`segment_output.R` or `discharge_publish.R` (only a micro-unit checksum at `discharge_publish.R:397`).
Read the intended way ("the days and the published month"), the sentence is true, but it also sits after
the "so" clause it belongs inside: rounding is itself a reason the days need not average to the month
(by up to 5e-6 m3/s, in either direction).

Fix: name the source and move it into the reason, e.g. the rewrite under Bug 2.

## Bug 2: `segment_daily.yaml:21`, "where a clamp applied their mean sits above it" is stronger than the arithmetic

max(x, 0) is convex, so the n_days-weighted mean of the clamped days is at or above the clamped month,
and strictly above only when the month held at least one negative and one positive raw day. Where every
raw day of the month is at or below zero (a losing reach through a dry month), all the days and the month
are 0 and equal, though a clamp applied. And a strict gap under 5e-6 can round to equal or below. The
claim also holds for the weighted mean; the reader's plain mean equals it outside February only (n_days
is 30 for every common day in 1981-2010), which the February clause already covers.

Fix (Bugs 1 and 2 together), lines 19-24:

    value. For pcic_routed each day is routed and clamped at zero on its own, as
    each month is in segment_monthly, and both the days and the months are
    rounded to 5 decimals (wet_balance is not rounded), so a month's days need
    not average to its published value: where a clamp applied their mean is at
    or above it, and 28 February also carries 29 February's flow, which the
    published month weights by its number of days. There is no annual row:
    month 0 of segment_monthly is not the mean of the 365 days.

## Nit 1: `segment_daily.yaml:22-23`, "weights by its number of days": "its" reads as 29 February's

The published month weights each calendar day by how many times the period holds it (fwapg's `n_days`),
not by 29 February's count. Optional fix: "...which the published month counts by how many times the
period holds each day (28 February's row stands for 37 of February's 847 day-years in 1981-2010, not
1 of 28)."

## Nit 2: `segment_daily.yaml:50` and `:65`, wrapping

Line 50 ("over 28.25 days). NA for a routed row off its") is a short line left by the fix; line 65 is a
~100-character plain scalar where segment_monthly folds the same note. Both parse to the intended text;
rewrap for consistency only.

## Pin for wet Phase 4 (not this diff)

The runoff_mm February claim (28/28.25) holds only if `scripts/segment_daily_output.R` derives a balance
day's depth from its q (`q * 86400 / area_m2 * 1000`, as `segment_output.R:181` does for routed months).
Laying the monthly depth on the weights instead (`R_m * w[d]`) makes February's days sum to `R_m` and the
note false. Phase 4's balance-identity check (task_plan line 119) covers q only; add the runoff_mm sum
(28/28.25 in February, 1 elsewhere, relative 1e-9) to it.
