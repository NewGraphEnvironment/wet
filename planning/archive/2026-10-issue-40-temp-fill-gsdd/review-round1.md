# Review round 1: wet_temp_fill() (#40)

Reviewer: subagent, 2026-10-07. Probes were run on a copy of the repo in the
scratchpad (`pkgload::load_all()`), not in the working tree.

## Verified correct

- Kalman filter and RTS smoother (linear part). On a 12-day series with 5 gap
  days and no floor binding, `wet_kf_run(smooth = TRUE)` matches the
  brute-force joint-Gaussian posterior (the prior built from the same
  stationary start, conditioned on the observed days). Smoothed means, smoothed
  variances and the log-likelihood (-45.23502 both ways) all agree to 5
  decimals. The indices (`fj[t + 1]`, `pp[t + 1]`, `mp[t + 1]`) and the initial
  state (equilibrium mean, stationary variance) are right.
- Floor Jacobian: `ft = 0`, `pt = q` when the prediction is floored, so
  `g = 0` in the smoother. This matches the documented "does not depend on the
  day before".
- Tibble input works: Date stays Date, n_hours stays integer, filled rows get
  NA t_min_c/t_max_c. A factor `station_number` comes back as character, and a
  factor `source` gets the `air2stream` level added. No duplicate station-days
  between the observed and filled rows. The `fit` attribute survives because it
  is set last. The zero-gap case (`n = 0` filled rows) works. Air with extra
  ids, extra columns and tmax rows is ignored correctly. A station with no air
  rows is returned unfilled, with a warning. The all-stations-short case falls
  back to the typed empty `fit` template.
- cd 0.6.1's `cd_extract_daily()` returns a tibble with `date` as Date and
  `value` in degrees C, so the type check and units match.

## Findings

- **[bug]** R/wet_temp_fill.R:209-210. Empty input aborts with an obscure
  error. A zero-row `temp`, or one whose `t_mean_c` is all NA, leaves `out`
  empty, so `do.call(rbind, out)` is `NULL`. `NULL[order(NULL, NULL), ]` then
  fails with `argument 1 is not a vector` (reproduced both ways).
  `wet_temp_daily()` returns zero rows by design (see its "data.frame() cannot
  recycle the scalar source onto zero rows" comment), so piping
  `wet_temp_daily()` into `wet_temp_fill()` breaks for a station or period with
  no data. It should return a zero-row frame with the documented columns and an
  empty `fit`.

- **[fragile]** R/wet_temp_fill.R:143. A station with exactly one non-NA
  `tmean` air row aborts the whole call for every station. `stats::approx()`
  errors with `need at least two non-NA values to interpolate` (reproduced: one
  extra station with a single air day kills a call that would otherwise fill
  two good stations). Such a station can never reach `min_days`, so it should
  take the "unfilled, with a warning" path, as a station with zero air rows
  already does (`if (!nrow(as_)) return(NULL)`). Guarding with `nrow(as_) < 2`
  would do that. The likelihood is low, because cd returns either all days or
  all NA per point. But when it does happen, everything is lost.

- **[fragile]** R/wet_temp_fill.R:121, 223-227. Output passed back in is taken
  as observed. When `temp` already has `filled`, `t_lo_c` and `t_hi_c` (the
  output of an earlier `wet_temp_fill()` call, e.g. re-run to extend
  `from`/`to` or to add stations), `wet_fill_observed()` overwrites
  `filled = FALSE` and collapses the interval to zero width. The modelled days
  then enter the likelihood and the peer errors as observations. Reproduced:
  re-feeding a result with 166 filled days returns 0 filled days, and the 166
  `source == "air2stream"` rows are now marked `filled = FALSE`. The parameters
  are fitted partly to their own fill, and the interval silently disappears.
  Either drop rows with `filled == TRUE` on input, or refuse a `temp` that
  already carries a `filled` column.

No other issues were found against the R and code-check checklists that apply
here:
- `$` partial matching: every `$` read has an exact key.
- `[[` on named atomics: `n_obs[[s]]` is only read for `s` in `fit_st`.
- Zero-length `data.frame()` recycling: handled with `rep(s, sum(gap))`.
- The typed empty `fit` template: present.
- The tests: no undeclared `pkg::`, no silent skips, and the relative
  tolerances are loose but not wrong.
- Non-ASCII: only in roxygen comments, and `Encoding: UTF-8` is declared.
