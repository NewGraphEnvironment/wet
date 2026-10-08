# Review round 3 — wet_temp_fill() rewrite and wet_temp_gsdd()

Reviewer: code-check round 3, staged diff `diff_r3.patch`. Probes ran on a `cp -r` copy of the repo
(`pkgload::load_all()` of the copy, the sim fixture in `tests/testthat/helper-temp-fill.R`, gsdd
0.3.0.9007). Nothing in the repo was modified except this file. Both new test files are green in the
copy (`NOT_CRAN=true`: fill 67 pass, gsdd 25 pass).

## Findings

- **[fragile]** R/wet_temp_fill.R:176 — air is interpolated linearly across an interior hole of any
  length, and both the fit and the fill then run on the straight line, with an interval that does
  not know. Measured on the sim fixture, Jun–Aug 2019 hidden on 08AA001, air removed for
  2019-05-15..2019-09-15 (a caller who extracted air per season, or a cd extraction with a hole):
  - station alone: RMSE 2.54 °C, mean bias −2.11 °C, 95% interval covers **53%** of true days;
    with complete air the same call gives RMSE 1.00 °C and 95% coverage.
  - with three peers the peer errors mostly rescue it (RMSE 0.72 vs 0.64, coverage 83%).
  No warning. The `nrow(as_) < 2` guard (round 1) is the one-row instance of this; a hole in an
  otherwise long air series is the general one. A maximum interpolation gap (a few days), with the
  days beyond it treated like days outside the air range (not filled, not used in the fit), closes it.

- **[fragile]** R/wet_temp_fill.R:141-143, 170-174 — `from = NA` (or `to = NA`, e.g. a blank cell
  in a parameter table) is not refused: `as.Date(NA)` is `NA`, `from > to` is skipped when the other
  is `NULL`, and the call dies at line 174 with `missing value where TRUE/FALSE needed` — the same
  message and line as round 2's NA-date finding. Reproduced. A length-2 `from`/`to` is not refused
  either: it passes the checks and is recycled in `date >= f_lo` (line 178), so the fill flag
  alternates by row. Refuse anything that is not one non-NA date.

- **[fragile]** R/wet_temp_gsdd.R:68, 77 — rows with an `NA` date are kept (only `NA` values are
  dropped), so one `NA` date stops the call at `seq(min(s$date), max(s$date))` with
  `'from' must be a finite number`. Reproduced. `wet_temp_fill()` now drops `NA` dates (round 2's
  fix), so its output is safe; `x` is documented as also coming from `wet_temp_daily()` or any
  data frame, where the fix was never applied. Two `NA` dates in one series instead raise
  "duplicate dates" (line 70), which names the wrong cause.

- **[fragile]** R/wet_temp_gsdd.R:85-86 — a window endpoint on 29 February fails in every non-leap
  year: `as.Date(paste0(y, "-02-29"))` errors (`character string is not in a standard unambiguous
  format`). Reproduced with `start_date = 1972-09-01, end_date = 1972-02-29` (a winter window ending
  with February): `gsdd::gsdd()` itself accepts it and returns 2018–2020, the wrapper stops. Low
  likelihood, but it is a calendar assumption (every month-day exists every year) that gsdd does
  not make.

## Mechanism

Every earlier finding came from one assumption: **a station has one calendar, and every input row
belongs to it as an observed day.** The code took `min()`/`max()` over whatever rows arrived and
treated the span as simultaneously the record, the air coverage, the fit window and the fill window,
and every row inside it as a real observation with a key. Each finding was an input where one of
those sets was empty (empty `temp`; one air row), `NA` (an `NA` date or station), not an observation
(re-fed filled rows), or a different span from the others (`from`/`to` cutting the fit). The
round-3 findings are the same assumption reached in places the fixes did not touch: a calendar
input that is `NA` (`from`/`to`, gsdd's `date`), a calendar that is not complete between its
`min` and `max` (an air hole), and a month-day that is not in every year.

Every place the mechanism reaches:

| Where | Input shape | Status |
|---|---|---|
| fill:141-143 `from`/`to` parsing | `NA`, length > 1 | **not handled** (finding 2) |
| fill:145 re-fed rows | `filled` TRUE / NA | handled (`%in% TRUE`; NA kept as observed) |
| fill:146 `temp` keys | NA date, station, value | handled |
| fill:151 `air` keys | NA id, date, value, variable | handled (`%in%`) |
| fill:169 air per station | 0 or 1 row | handled (NULL, warned as too few) |
| fill:170-174 lo/hi | `[from,to]` entirely after the air, entirely before it, entirely outside the record | handled: measured 0 filled, no crash, fit fitted on the record; lo > hi gives NULL and an accurate warning |
| fill:170-171 fill range with one side NULL | `to` before the first observation, or `from` after the last | silently fills nothing; consistent with the documented NULL meaning |
| fill:176 air interpolation | interior air hole | **not handled** (finding 1) |
| fill:178 `fill` flag | observed days outside `[from,to]` | handled: returned, used in the fit, gaps outside not filled (test "from and to limit the fill, not the fit") |
| fill:288-296 open-loop start | first calendar day | never extrapolated: the series is clipped to the air and `approx(rule = 1)`; the start moves with `from` when `from` precedes the record, which moved the fill by at most 0.008 °C in a probe (accepted spin-up) |
| fill:198-205, 222 peer errors by date | peers on different spans | handled (exact name lookup, NA off-span) |
| fill:247-257 empty result / fit | no stations, none fitted | handled |
| gsdd:68 | NA value | handled |
| gsdd:68, 77 | NA date | **not handled** (finding 3) |
| gsdd:69 | NA in a `by` column | rows dropped silently by `split()` (no crash) |
| gsdd:77 | days absent from `x` | handled: full calendar, absent = NA to gsdd |
| gsdd:84-88 year-spanning window | `start_date` > `end_date` in month-day | handled: verified Sep–May on a 3-year series, years 2018–2020 and values match `gsdd::gsdd()`; `n_days` 273/274/273; `frac_filled` 31/274 for a December filled in the 2019 season |
| gsdd:85-86 | endpoint on 29 Feb | **not handled** (finding 4) |
| gsdd:81, 104 | no rows / no years | handled |

## Checked and clean

- Kalman filter and RTS smoother: the control input `b * ebar` enters the prediction, and the
  smoother's `mp`/`pp` include it, so the RTS recursions are right; `pp[t+1] >= q > 0`, no division
  by zero; `rho -> 1` makes the likelihood non-finite and is capped at 1e10, so BFGS cannot return it.
- Interval and floor: `half` is from the unfloored estimate and both bounds and the mean are floored
  the same way, so `t_lo_c <= t_mean_c <= t_hi_c` holds.
- `wet_a2s_fit()` cannot see an empty `i` (`min_days >= 10`).
- gsdd year labels: `dtt_study_year()`'s first four digits are the start year, which is the `y` the
  wrapper's window starts in, for both spanning and non-spanning windows (also checked Jan 1–Dec 31).
