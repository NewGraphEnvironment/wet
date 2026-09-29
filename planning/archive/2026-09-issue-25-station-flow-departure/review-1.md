# Plan review 1 (Plan agent, 2026-09-28)

The reviewer was read-only, so its findings were returned in its reply and are recorded here. Disposition follows each item.

1. **Blocker.** cd PR #94 aborts on more than one row per variable/period/year, and `cd_anomaly()` drops extra columns. **Adopted:** the script splits per station and re-joins its columns. The id-columns request came out of cd#92 and became cd#95. Verified against the PR #94 diff.
2. **Blocker.** `unit` is the unit of the anomaly (`%` for pct_normal). A dry window with baseline 0 gives NaN under pct_normal. **Adopted:** fixed metric table: `q_mean` and `q_min7` pct_normal `%`; `q_frac_below` and `q_cov_day` absolute.
3. **Gap.** Row-level precedence lets provisional data fill holes inside HYDAT. **Adopted:** per-station cutoffs. Provisional is used only after HYDAT's last date, real-time only after the last date of the sources before it. Warnings are for seams only.
4. **Gap.** `days_below` undercounts, `cov` shifts with missing days, and `min7` rolls over rows. **Adopted:** `q_frac_below` is the fraction of present days. `min7` counts only 7 consecutive calendar days inside the window. `q_cov_day` is kept only for complete window-years. Renamed from `cov_doy`.
5. **Gap.** Leap and year-assignment rules. **Adopted:**
   - start `02-29` is refused;
   - end `02-29` means the last day of February;
   - expected days come from actual dates;
   - `start == end` is a one-day window;
   - window-years ending after the series' last date are dropped;
   - a leap versus non-leap cross-year test is added.
6. **Gap.** cd's `winter` is Dec+Jan+Feb of the same calendar year. **Adopted:** calendar seasons are named `djf`, `mam`, `jja`, `son`, and a DJF window takes the year of its December.
7. **Gap.** Baselines have no floor. **Adopted:** the report states n per window baseline.
8. **Gap.** duckdb httpfs install, region and credentials. **Adopted:** an explicit anonymous S3 secret with region set. `INSTALL` stays (one download per machine) and live tests are skipped on CI.
9. **Assumption.** Timezone. Already `as.Date(x, tz = "UTC")`. **Adopted:** a test with a 07:00 UTC row.
10. **Assumption.** Status and symbols. Status is mapped from `Approval`. The canonical `Symbol` is all NA for these stations (measured). **Adopted:** `frac_ice` is over present days, and `frac_provisional` is added so provisional window-years are visible.
11. **Assumption.** A partial current day from real-time. **Adopted:** days on or after today are dropped.
12. **Assumption.** HYDAT coverage decides whether there is a hole. **Adopted:** the HYDAT download moved up to Phase 2. The script passes the versioned path.
13. **Ordering.** Settle the output contract before the Phase 3 tests. Done in 1 and 2.
14. **Acceptance.** The Feb 30 test tested nothing. **Adopted:** the fixture puts a value in Feb FLOW30.
15. **Acceptance.** cd test skips. **Adopted:** skips on cd, Kendall and zyp, and on cd's #92 behaviour.
16. **Acceptance.** Determinism. **Adopted:** tests pass a fixed `to`; live tests use `skip_on_cran`, `skip_on_ci` and `skip_if_offline`.
17. **CRAN.** **Adopted:** requireNamespace guards; examples use base R only.
18. **Minor.** There is no `_pkgdown.yml`, so that item is dropped. **Adopted:** an unknown station returns empty with a warning.
