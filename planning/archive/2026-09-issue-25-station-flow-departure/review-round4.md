# Code-check round 4: review of the restructure

Reviewer: subagent, 2026-09-28. Probed in a scratch copy (repo without `data/`). Both test files are green there (62 + 41 pass; the live test and the cd test skip). The real HYDAT 20260717, the water-temp-bc parquet and `tidyhydat::realtime_ws()` were queried read-only.

## Findings

- **[severity: fragile]** R/wet_station_daily.R:74 (`start <- max(c(from, Sys.Date() - 540, ...))`): the realtime reader is still windowed by `from`, so the "whole joined record" handed to `wet_daily_gaps()` is not whole for its last source. When `from` falls inside a hole in the real-time feed, the hole inside that one source is reported as a seam gap between sources, and the dates reported include days the feed actually has. The documentation says holes inside one source are not warned about, and the restructure's premise is that seams and gaps come only from unfiltered rows. This is the round-3 mechanism again: an extent taken from what is at hand (`from`) stands in for the source's record.
  Reproduced with provisional ending at T0-60, and a feed covering T0-59..T0-40 and T0-29..T0-1 (holding a hole of T0-39..T0-30):
  - `from = NULL`: no warning (correct).
  - `from = T0-35`: `gap between sources, left unfilled: 08AA001 2026-07-31 to 2026-08-29 (provisional -> realtime)`. The feed has 2026-07-31..08-19. The only missing days are 08-20..08-29, and they are a hole inside real-time.

  Whether the warning appears, and the dates it names, therefore depend on `from`. The returned flows are right and nothing is lost, but the warning is wrong. Fix: drop `from` from `start` (`start <- max(c(Sys.Date() - 540, if (length(have)) max(have) + 1))`, where the first element is already a Date). Real-time then reads its whole reachable record, like the other two readers, and the single final filter trims it. That costs at most 540 rows per station, and the `start > end` short-circuit, which depends only on `to`, is unchanged. A probe showed `realtime_ws()` serves the full 540 days for 08EE013 (2025-04-06..2026-09-27).

No other defects found.

Measured and clean:
- The provisional archive (all `08*` stations, 157,392 rows, 231 stations) has 0 duplicate station-days after `as.Date(tz = "UTC")`. Timestamps are 08:00 or 07:00 UTC (MST stations), so the day is always the same. `Approval` has one value, `Provisional/Provisoire`.
- `realtime_ws(parameters = 6)` returns daily means at 08:00 UTC with `Approval` `Provisional/Provisoire`, and no duplicate days.

## Enumeration

### Sets and extents derived

| Where | Derived from | Set the rule is defined over | Match? |
|---|---|---|---|
| `stations <- unique(stations)` | argument | requested stations | yes |
| HYDAT record / HYDAT end (`wet_hydat_daily`, then `wet_daily_after` and realtime `have`) | every DLY_FLOWS row for the station, unpivoted to valued days | "HYDAT's approved record" | yes as a proxy; see residual 1 |
| provisional record (`wet_provisional_daily`) | whole `canonical/` archive | the provisional archive | yes (`historic/` is out of scope, water-temp-bc#19, documented) |
| provisional cutoff (`wet_daily_after(pv, out)`) | `out` = the whole HYDAT record | HYDAT's whole record | yes |
| **real-time record** (`start`) | `max(from, today-540, last+1)` | the source's reachable record | **no**: windowed by `from` (finding above) |
| real-time cutoff (`wet_daily_after(rt, out)`, `have`) | `out` = whole HYDAT + provisional after the cutoff | whole prior record | yes |
| real-time end | `min(to, today-1)` | days wanted, excluding today | yes; truncation after the last source feeds nothing |
| seam gaps (`wet_daily_gaps`) | joined record, intersected with from-to | the whole joined record | yes for HYDAT and provisional, **no for real-time** (same finding) |
| final trim | `from`/`to`, once | the result | yes |
| "no flow found" | the trimmed result | what is returned | yes |
| `wet_window_stats` extent `first`/`last` | `x` after dropping NA values, per id | "the series' first and last day" | yes |
| candidate years `y0:y1` | extent; `y0 = first year - 1` covers windows that cross 1 January | window-years inside the extent | yes |
| ids | `x` after dropping NA values | series that have data | yes; thresholds are required only for these, and a missing one is an error |
| `min_frac` denominator | `length(idx)`, every day of the window | the window's days | yes |
| `cov_day` / `min7` | `all(have)` / 7-day runs inside `vv` | the full window / runs inside the window | yes |
| script `with_mad` / `no_mad` | `names(mad)` ∩ `stations` | stations that have a MAD | yes |
| script `nb` counts | `expand.grid(vars, windows$window)` | every window asked for | yes |
| script `dropped` / ice drop | stats rows with `frac_provisional > 0` in windows touching Nov-Apr | window-years resting on any provisional day | yes (real-time rows are `provisional` too, which is right: no ice correction) |
| report source ranges | `daily` (from = NULL, so the whole record) | each source's span | yes |

Challenge to the parent's list: it says "realtime start from the joined whole record". The `last+1` term is taken from the whole record, but `start` also takes `from`, and that `from` term is where the finding comes from.

### Facts computed in more than one place

- **The last day a source holds**, computed in `wet_daily_after` (split/max) and in realtime `max(have)`. Both use the same `out` under the same definition. Consistent.
- **Provisional status**: the `wet_eccc_daily` regex, then `status %in% "provisional"` in `wet_window_series`, then the script's `frac_provisional > 0`. Consistent.
- **"Today"**: `Sys.Date()` is called separately for `to`, `end` and `-540`. The only effect is a midnight race, which is harmless.
- **Nov-Apr** is defined only in `touches_ice`. The header text matches it.
- **The MAD fallback threshold (5)** appears in `station_mad(min_years = 5)`, the header and the "MAD: none" message. Consistent.
- **`min_baseline`, `baseline`**: one variable each, used everywhere. Consistent.

### Residuals (not defects)

1. HYDAT's approved end is taken to be the last day with a value. DLY_FLOWS has no column that states the approved end. For 08EE013 the March 2025 row has `NO_DAYS` 31 and `FULL_MONTH` 0, with values on the 1st and 2nd only. A station whose last approved month ends in NULL days (a gauge outage just before the approved end) would have those days filled by provisional. For 08EE013 and 08EE003 the proxy matches GeoMet's approved end (2025-03-02/04, findings.md), so nothing wrong was measured.
2. A "day with flow" has two definitions. `wet_station_select` / `wet_station_monthly` (pre-existing, not in this diff) count `FLOWn IS NOT NULL` over all 31 columns, impossible days included. `wet_station_daily` drops impossible days. Real HYDAT leaves impossible days NULL, so the two agree on real data. They would diverge only on a fixture like the Feb-30 test's.
