# Review round 2: wet_temp_fill() (#40)

Reviewer: code-check round 2, staged diff `diff_r2.patch`. Probes ran on a copy of the repo
(`pkgload::load_all()` of the copy, the sim fixture in `tests/testthat/helper-temp-fill.R`).
Nothing in the repo was modified except this file.

## Findings

- **[bug]** R/wet_temp_fill.R:164-165, 173-179 — `from`/`to` limit the data the model is fitted on,
  not only the days filled. The docs say `from`/`to` are the "first and last day to fill" and that
  `min_days` counts "observed days with air temperature", but `series` is cut to `[from, to]` before
  `n_obs` is counted and before both fits run. Measured on the sim fixture (3-year record, 1004-1096
  observed days per station, Jun-Aug 2019 hidden on 08AA001):
  - `wet_temp_fill(obs, air, from = "2019-03-01", to = "2019-11-30")` fills **0** days and warns
    "too few observed days with air temperature to fill: 08AA001, 08AA002, 08AA003, 08AA004",
    which is false for every station.
  - With `min_days = 100` the same call fills, but each station is fitted on its 183-275 in-window
    days instead of 1004-1096, and the fit attribute reports `n_obs` 183/275.
  Calling it once per growing season (the natural way to feed `wet_temp_gsdd()`) therefore returns
  the series unfilled with a misleading warning. A `from` after a station's last observation (or a
  `to` before its first) also returns it unfilled with the same "too few observed days" message
  (`lo > hi` at line 166). Either fit on the whole overlap of record and air and fill only inside
  `[from, to]`, or document that `from`/`to` also restrict the fitting data and make the warning say so.

- **[fragile]** R/wet_temp_fill.R:146, 161-166 — a single `NA` in `temp$date` or
  `temp$station_number`, or in `air$id`, or in `air$variable` on a row with a value, crashes the call
  with `Error in if (lo > hi) return(NULL): missing value where TRUE/FALSE needed`. The cause is logical
  subsetting with `==`: `air[air$variable == "tmean" & ..., ]` and `air[air$id == s, ]` /
  `temp[temp$station_number == s, ]` turn an `NA` comparison into an all-`NA` row, whose `NA` date
  makes `lo`/`hi` `NA`. Reproduced with one `NA` date in `temp`. `temp` is documented as coming
  "from any source (loggers included)", so a stray `NA` date is plausible, and the message names
  nothing about the cause. `%in%` (or `which()`) in those three subsets, plus dropping or refusing
  `NA` dates/stations, closes it.

- **[fragile]** man/wet_temp_fill.Rd (from R/wet_temp_fill.R:10, 66) — the staged commit links
  `[wet_temp_gsdd()]`, but `R/wet_temp_gsdd.R` and `man/wet_temp_gsdd.Rd` are untracked, so at this
  commit `R CMD check` reports a missing Rd cross-reference (a WARNING; red under
  `error-on: "warning"`). Harmless if gsdd is committed before the branch is pushed; a push of this
  commit alone reddens CI.

## Checked and clean

- Empty input: `temp[0, ]` as a data.frame and as a tibble (factor `station_number`) returns 0 rows
  with `names(temp)` + `filled`, `t_lo_c`, `t_hi_c` and the expected classes (character, Date,
  numeric, integer, logical), and a 0-row `fit` attribute. All-short input (every station under
  `min_days`) returns the observed rows with the same columns and types.
- Tibble input with factor `station_number` and a `pool` carrying an extra name: runs, returns a
  tibble, fills 92 days, column classes intact (`wet_fill_rows()`'s `NA`-index slice works on a tibble).
- `NA` in `temp$filled`: such rows are kept as observed (`!NA %in% TRUE` is `TRUE`); a re-fill
  reproduces the same 92 filled days.
- `group[fit_st] == group[[s]]` is only reached for `s %in% fit_st`, so an empty `fit_st` never
  evaluates it; `group[[s]]` always exists because every station is checked against `names(pool)`.
- Clipping: `sigma` comes from `exp()` of a finite `optim()` par (the objective is capped at 1e10, so
  BFGS never returns a non-finite par); `lim` is never `NA`. `Inf` would only disable clipping. No
  integer arithmetic.
- Peer lookup `err[[p]][key]` is exact name matching on `as.character(as.integer(date))`; the
  `vapply()`/`matrix()` reshape is right for `length(key) == 1` and for one peer.
- Gap days never overlap observed rows (gaps are `NA` after the `NA`-`t_mean_c` rows are dropped),
  so `rbind(obs, fl)` cannot duplicate a station-day.
- A constant-valued (dead-sensor) station fits without `NaN` in the smoother (sigma ~2e-4, finite
  interval) and does not break its peers.
