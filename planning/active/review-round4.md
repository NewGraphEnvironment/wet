# Review round 4 — wet_temp_fill() refactor and the round-3 fixes

Reviewer: code-check round 4, staged diff `diff_r4.patch`. Probes ran on a `cp -r` copy of the repo
(`pkgload::load_all()` of the copy, the sim fixture in `tests/testthat/helper-temp-fill.R`, gsdd
0.3.0.9007). Nothing in the repo was modified except this file. Both test files are green in the
copy (`NOT_CRAN=true`: fill 73 pass, gsdd 28 pass).

## Findings

- **[fragile]** R/wet_temp_fill.R:247-251 — the air-gap check looks only at air dates *inside*
  `[lo, hi]`, so it misses a hole that contains a calendar endpoint, or the whole calendar.
  `approx()` (line 252) still interpolates across the full hole from the air points on either side,
  and the station is fitted and filled on the straight line with no warning. Two reproductions:
  - **Whole calendar inside a hole.** Water for 2019 only; air for 2018 and 2020 only (e.g. air
    extracted per period). `lo`/`hi` = 2019-01-01/2019-12-31, `ad` is empty, `length(ad) > 1` is
    FALSE, so the check never runs. Fitted with no warning: `rmse_open` 8.28 °C, `a1/a2/a3` stuck
    at the optimiser start (0.5, 0.1, 0.05). Jul–Aug hidden (`min_days = 200`): fill RMSE
    **1.91 °C** vs 1.02 °C with complete air.
  - **Record starts inside a hole.** Air missing 2018-03-01..05-31, water from 2018-05-01. `lo` =
    2018-05-01, the first air date in range is 2018-06-01, and the 31-day stretch from `lo` to it is
    not in `diff(ad)`. 1 May–31 May air is a line from 28 Feb to 1 Jun. No warning; fill of
    3–29 May RMSE 1.07 vs 0.92 °C with complete air. The same at `hi` when `to`/the record's end
    sits in a hole that `max(as_$date)` lies beyond.
  The interior case (test "a long hole in the air…") is caught. Fix: test holes on the station's
  whole air series and refuse any that overlaps the calendar, e.g.
  `ad <- sort(as_$date); h <- which(diff(as.numeric(ad)) > wet_air_gap + 1);
  if (any(ad[h] < hi & ad[h + 1] > lo)) …` — both reproductions are flagged by it, the interior one
  still is, and a hole ending exactly on `lo` is not.

## Round-3 enumeration: each "not handled" item

| Round-3 item | Now |
|---|---|
| `from`/`to` NA, length > 1 | handled: `wet_fill_day()` refuses NA, length 0 or 2, unparseable strings (tests at 231-233) |
| interior air hole | handled for a hole strictly inside the calendar; **not** for one holding an endpoint or the whole calendar (finding above) |
| gsdd NA date | handled: dropped at gsdd:68 before `split`/`seq`; two NA dates no longer raise "duplicate" |
| gsdd 29 Feb endpoint | handled, and consistent with gsdd itself: `dayte_seq()` drops 29 Feb in a common year, so a window starting 29 Feb begins 1 Mar and one ending 29 Feb ends 28 Feb, which is what `wet_md_date(start = TRUE/FALSE)` does |

## Checked and clean

- **Refactor is behaviour-preserving.** Round-3 `wet_temp_fill()` (scratchpad `r3copy`) vs this one
  on the sim fixture with a mid-record and a record-start hole, with `pool` and with `from`/`to`
  extending past the record: `identical()` TRUE for both results (rows, columns, `fit` attribute).
- `<<-` inside `lapply` assigns `air_gap` in `wet_fill_prepare()`'s frame (defined at 234); an
  air-gap station has a NULL series, `n_obs` 0, is excluded from `short` by `setdiff` and from
  `fit_st`, so it gets one warning, not two, and is returned unfilled.
- `diff > wet_air_gap + 1` allows exactly 3 missing days (diff 4), refuses 4, as documented.
- `wet_fill_station()` reproduces the old per-station block (`pe` from `prep$group[[s]]`, same
  `ebar`, 180-day rule, start values, smoother); empty `fit_st` gives empty named lists, no error.
- **Swap claim.** Script-style preparation (held station alone, `from`/`to` = its full record
  range, swapped into the full preparation) vs `wet_temp_fill()` on the full data minus the hidden
  days, four stations in two pools:
  - interior holdout (08AA001 Jun–Aug 2019): fill max diff 5e-10 °C, `fit` row identical
    (incl. `n_obs` 1004, `b`, `loglik`).
  - holdout at the record start (08AA002 1 Jan–15 Mar 2018) or end (08AA004 Oct–Dec 2020): the
    default `wet_temp_fill()` fills **nothing** there (the default range is the remaining record),
    while the script fills and scores those days. The script's result equals
    `wet_temp_fill(..., from = min(x$date), to = max(x$date))` for the held station (max diff
    2e-10 °C), which is what its comment intends ("as the default would" on the full record). In
    that call `from`/`to` would also extend a peer's calendar when the held station starts earlier
    than the peer; the script keeps peers on their own range. That moves only the peer's open-loop
    start (the accepted spin-up), so not a defect — but the claim "same as `wet_temp_fill()` on the
    full data with the held days removed" is literally true only for interior holdouts.
  - `n_obs`: taken from `one`, correct. `group`/`pool`: `one` uses `pool[s]`, swap leaves the full
    `group` in place, which already has `s`. `fit_st` order: `s` is already in the full `fit_st`
    whenever the script reaches the swap (same range, `n_obs(keep) <= n_obs(x)`, same air-gap
    verdict), so the append never runs; it would only reorder peer columns in a `rowSums`.
  - Stations absent from the full preparation, or not fitted in `one`: `wet_fill_station()` would
    fail on `prep$group[[s]]` / a NULL `dep`, but neither is reachable from the script (`full_prep`
    is built from the same `water`; `score_one()` returns NULL when `s` is not in `p1$fit_st`).
  - The script calls `wet_fill_prepare()` on `water`/`keep` without `wet_fill_clean()`. Harmless
    for `wet_temp_daily()` output (no NA `t_mean_c`, one row per station-day, character ids).
- Kalman filter, interval floor, `wet_a2s_fit()` empty `i`, gsdd year labels: unchanged since
  round 3's clean checks.
