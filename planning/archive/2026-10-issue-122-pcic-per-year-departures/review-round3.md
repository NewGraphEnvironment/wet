# Review round 3: #122 branch diff (code-check, HEAD 7862dd6)

## Checklist read

- **code-check.md** (37 H3): read the prose of all 14 H3 under `## Mechanisms` (tables skipped). These were a guard that fails toward pass, a fixture that cannot reach the failure mode, a proxy is not the property, verification that reads its own output, a guard's scope, escape hatches and remedies, a fix lands in one of two callers, restore the bug and prove the guard fires, a shared working tree, a wrapper's exit is not the work, zero-length/empty/unset, the probe is broken before the world is, written data outlives the fix, serialization loses meaning silently, and one fact derived twice. Not read in full: 23 (Rules that stand alone, Security, Spreadsheets and PDFs). Only their index lines were read, and none names a tool or shape this diff uses.
- **code-check-r.md** (111 H3): read 8 in full:
  - a database driver's value is not a base R type
  - `match()` treats NA as a value
  - Postgres row order
  - `sprintf("%g")` in SQL
  - Rscript reads a script as it runs
  - `bind_rows()` of all-NULL / typed template
  - testthat counts an uncaught error under `error`
  - `paste()` with a zero-length argument

  The other index lines were checked against the diff. Not read in full: 103. Rounds 1 and 2 read 46 and 17 of them.
- **code-check-shell.md** (67 H3): read 0 in full. The diff's only shell use is `system2("git", ...)`, which the R `system2` entry covers. All 67 are unread.
- **code-check-spatial.md** (93 H3): read 0 in full. The only spatial call is `terra::project()` of a point matrix (4326 to 3005), used for km distances in the report only, and its index line was checked. All 93 are unread.

## What was checked, and how

- I ran the three test files from a `git archive HEAD` copy (`NOT_CRAN=true`, `load_all(copy)`):
  - `departure_carry`: 36 passed
  - `donor_weights`: 25 passed
  - `routed_years`: 28 passed

  All three had 0 failed, 0 error and 0 skipped.
- Mutation: I deleted round 2's slice check (`R/wet_departure_carry.R:113`) in a second copy. "a modelled with no rows for the statistic carried is refused" goes red (failed 1), so that test discriminates.
- Probe 1 (`wet_departure_carry(weights = "covariance")` on the covariance test's data, in the copy):

  | modelled as passed | result |
  |---|---|
  | correct | covariance, `D1:1.0000:0.996` |
  | `period` all NA | **returned**, weighting `distance`, every r 0.000 |
  | `variable` all NA | **returned**, weighting `distance`, every r 0.000 |
  | `value` all NA | **returned**, weighting `distance`, every r 0.000 |
  | `value` all 0 | returned, weighting `distance` (the rule's answer when every series is routed to 0) |
  | years shifted +100 | covariance, unchanged (r reads modelled only, as the rule says) |
  | `station_number` a factor | covariance, unchanged |
  | `period` `"Migration"` | refused: "`modelled` has no rows for q_mean migration" |

- Probe 2 (`wet_routed_years()` input types):

  | input | result |
  |---|---|
  | character subid, character, integer64 or numeric lfid, integer64 subid, character share, years given as double | identical values |
  | factor subid | refused, with a misleading message naming codes 1, 2, 3 |
  | non-integer subid 101.4 | silently truncated to 101 |

  Other probes: `sprintf("%.0f", bit64::as.integer64(707104006))` prints `"0"`, and `tab_of(list())` errors with "no input has determined the number of cases".
- Read-only fwapg queries:
  - `pcic.series` does not exist yet locally, as expected before fwapg#42.
  - `pcic.discharge_monthly` covers the same 315 stations-rds segments in the 1951-2012 run and the 1981-2010 run. So `routed_annual()` reading the shipped 1981-2010 run for the report's "#58's definition" count is not a defect.
  - `pcic.segment_weights` has 0 rows with a NULL array or a NULL element (`array_to_string()` would drop one).
  - The stations rds `test`: 137 gauges, 117 accepted. The one with an NA drainage area (08HA066) is not accepted, so it never reaches `wet_station_space()`. That function would refuse it anyway.

## Mechanism

**"No row" encodes two different facts, and the code tells them apart with a set taken from the frame it is checking.**
- `wet_window_stats()` omits a row rather than writing NA: cov_day where `sum(vv) == 0`, and a window under `min_frac`.
- The log statistics drop values <= 0.

So "this station has no usable modelled value for this statistic" can mean either of two things:
- (a) PCIC routes ~0 there. This is a fact about the model, and the rule turns it into r = 0.
- (b) The caller's frame does not carry it: a filter, a mislabel, an NA label, a join miss, a type that formats to the wrong id. This is a defect, and it should refuse.

Every fix so far moved the boundary between (a) and (b) by deriving a list from `modelled` itself:
- first the per-slice station set
- then `known` (every station in `modelled`)
- then "the slice has rows"

Each derived list agrees with the property ("routed to 0", "mislabelled") on the inputs the author pictured, and disagrees on another spelling of empty. That is why each round closes one spelling and the next finds another:
- Round 1: a slice missing one station.
- Round 2: a slice missing every station, spelt by an exact-match miss.
- Round 3: a slice "present" only through NA-subscript phantom rows, or present with no usable value.

The same shape appears in two other places, for the same reason:
- **Round 1's rds finding.** The header's list ("every statistic and window") and the body's saved list (the migration mean) agreed for the deciding statistic only.
- **The `anyNA(sort(unique()))` finding.** A normaliser between the input and its guard removed the NA the guard was looking for.

The discriminating fact for (a) exists positively in the data: the station's modelled q_mean slice exists and is <= 0. A guard can read that fact instead of inferring it from absence.

Places the mechanism reaches (absence or emptiness read as a meaning):

1. `R/wet_departure_carry.R:111-113`, the slice check: `==` subsetting yields phantom NA rows, and a slice with no usable value passes. This is **Finding 1**.
2. `R/wet_donor_weights.R:40-46`: `known` comes from `modelled`'s own station set, and `series()` drops NA and <= 0 values. A station whose rows are all NA reads as "routed to 0". This is part of Finding 1, and the accepted tradeoff covers only a station *without rows*.
3. `scripts/pcic_routed_lib.R:193-197`, `routed_weights()`: absence of a row means "not covered", so an id formatted wrongly (integer64 to `"0"`) reads as uncovered. This is **Finding 3**. It is not reached today.
4. `scripts/departure_pcic.R:356, 418`: `covered` and the test set's "no pcic.segment_weights row" read 3. They are safe today because both id vectors are `as.integer()`'d first (lines 353, 414).
5. `scripts/departure_pcic.R:408-411`: a snap that returns no row reads as "snap not accepted" (`%in% TRUE`). This is report-only, so I did not raise it as a finding.
6. `scripts/departure_pcic.R:526-532`, `pcic_of`, and `obs_of`: an empty series makes the gauge "not scored (fewer than 3 years)". This mixes "routed to 0" with "short record" in one count, but the header registers exactly that count, so it is not a finding.
7. Guarded correctly:
   - mod's station set against seg (line 515, `setequal`)
   - parity bins (line 487: `anyNA` after a full outer merge plus a row count)
   - catalogue years (line 449, `identical`)
   - absent sub-basins in `wet_routed_years()` (line 78)
   - a NA subid (line 66, now before `sort()`)
8. `scripts/departure_pcic.R:435`: `subs <- sort(unique(...))` drops an NA subid, which is the same shape as round 1's finding 3. It is safe because `wet_routed_years()` refuses an NA subid on the same rows before any result is used. Round 1's fix holds there.
9. `scripts/departure_pcic.R:592-594`, `tab_of()`: an empty set of targets reads as an R error rather than "nothing scored". This is **Finding 4**.

## Enumeration

Columns:
- **(a)** implemented
- **(b)** direction on empty, missing, NA, mislabelled or other-type input
- **(c)** for R/ functions, whether a test fires it (pre-existing guards on `main` are marked as such)

| # | where | guard / header refusal | (a) | (b) | (c) |
|---|---|---|---|---|---|
| 1 | wet_routed_years.R:43 | duckdb not installed | yes | refuses | no (cannot without uninstalling) |
| 2 | :44-46 | `dir` not one existing dir | yes | refuses NA, `""`, a vector, a missing dir | yes (test L123) |
| 3 | :47-50 | `weights` columns, `upstream_subids` a list | yes | refuses | no |
| 4 | :51 | zero rows | yes | refuses | no |
| 5 | :52-54 | NA or duplicated `linear_feature_id` | yes | refuses; character and integer64 ids work (probe) | yes (L118, duplicate) |
| 6 | :55-57 | `years` whole, distinct, non-empty | yes | refuses character, factor, NA, fractional, duplicate, empty | no |
| 7 | :58-60 | `series` one name | yes | refuses | no |
| 8 | :62-64 | a year without its file | yes | refuses | yes (L116, L117, L122) |
| 9 | :66-67 | NA subid (round 1's fix) | yes | refuses NA. A non-integer subid is truncated silently (101.4 to 101, probe). A factor is read as its codes and refused with a misleading message. | yes (L121) |
| 10 | :78-82 | a sub-basin with no rows | yes | refuses | yes (L115) |
| 11 | :83 | NA flow | yes | refuses | yes (L112) |
| 12 | :89 | a date outside the years | yes | refuses | yes (L107) |
| 13 | :90 | a day twice | yes | refuses | yes (L102) |
| 14 | :91-95 | a sub-basin lacking days | yes | refuses | yes (L100) |
| 15 | wet_routed_days.R:64 (via 101) | NA share | yes | refuses (after the read) | yes (test-wet_routed_days L98) |
| 16 | wet_donor_weights.R:26 | method | yes | refuses | indirectly |
| 17 | :45-46 | target or donor not in `known` | yes | refuses a station missing from `modelled`. `known` is derived from `modelled`, so it cannot see a station present only through NA labels or values. | yes (dw L89, L91; carry L152, L170) |
| 18 | :51 | r on < 30 years counts as 0 | yes (registered) | silent by design | yes |
| 19 | :53 | NA r counts as 0 | yes (registered) | silent by design | yes |
| 20 | :63 | every chosen donor weighs 0: fall back, flagged | yes | flagged in `weighting` | yes |
| 21 | :41-42 | `series()` drops NA and <= 0 | n/a | **an all-NA station reads as "routed to 0"** (Finding 1) | no |
| 22 | wet_departure_carry.R:73 | covariance without `modelled` | yes | refuses | yes (L150) |
| 23 | :74 | `modelled` with distance | yes | refuses | yes (L151) |
| 24 | :76-78 | `modelled` missing a column | yes | refuses | **no test** |
| 25 | :79-81 | `modelled` duplicate key | yes | refuses | yes (L154) |
| 26 | :83-95, 99, 121-125 | x columns, target, k, x duplicates, stations, no donor rows, donor baseline | yes | refuse (pre-existing, on main) | pre-existing (L80 for baseline) |
| 27 | :113 | empty (variable, period) slice (round 2's fix) | yes | refuses an exact-match miss (probe and mutation). **Passes with an NA `variable` or `period` (phantom NA rows) and with an all-NA `value`** (Finding 1) | yes (L174-181; red under deletion) |
| 28 | pcic_routed_lib.R routed_where_period | length 1, `YYYY-YYYY` | yes | refuses NA, empty, a quote | n/a (script lib) |
| 29 | routed_daily_fingerprint | tables of the period against `pcic.runs` (header: "1951-2012 tables that differ from pcic.runs") | yes | refuses: 0 or 2 run rows, mismatched counts, an NA `same_q` (`!isTRUE`) | n/a |
| 30 | routed_weights `stopifnot(length > 0, !anyNA)` | lfid present | yes | refuses empty and NA. **An integer64 lfid formats to `"0"`, giving an empty result that reads as "not covered"** (Finding 3) | n/a |
| 31 | routed_weights `stopifnot(!dup, !anyNA(up))` | one row per segment, array not NULL | yes | refuses. NULL array elements would be dropped by `array_to_string`; there are 0 today (query) | n/a |
| 32 | departure_pcic.R:278 | WET_HYDAT_RELEASE not 20260717 (header) | yes | refuses (`wb_release()` refuses a malformed value) | n/a |
| 33 | :281-286 | run through Rscript; md5 readable | yes | refuses | n/a |
| 34 | :294-296 | uncommitted R/ or scripts/ (header) | yes | refuses a dirty tree, but **does not tie the running frozen copy to the committed file** (Finding 2) | n/a |
| 35 | :299 | WET_FWAPG_COMMIT unset or not hex (header) | yes (`routed_commit()`) | refuses | n/a |
| 36 | :301-303 | WET_FWAPG_DAYS_COMMIT (header) | yes | refuses an empty value | n/a |
| 37 | :305 | WET_PCIC_YEARS | yes | refuses empty and missing | n/a |
| 38 | :306 | `cal` scored under other code (header) | yes (`shipped_heldout()`) | refuses | n/a |
| 39 | :331-332 | windows are #120's | yes | refuses | n/a |
| 40 | :348 | 1951-2012 tables against `pcic.runs` (header) | yes | refuses | n/a |
| 41 | :354 | cal lfid NA after `as.integer`; cal = held-out stations | yes | refuses | n/a |
| 42 | :400-402 | migration-mean pool < 100 (header) | yes | refuses, including an empty pool | n/a |
| 43 | :429 | one stations table, no duplicate | yes | refuses | n/a |
| 44 | :442-443 | a year of 1951-2012 without its file (header) | yes | refuses | n/a |
| 45 | :449-451 | `pcic.series` has every year once | yes | refuses empty, a gap, a duplicate (`identical`) | n/a |
| 46 | :452-453 | one `pcic.runs` row | yes | refuses | n/a |
| 47 | :454-457 | a row on another crosswalk (header) | yes | refuses. An NA md5 gives `if (NA)`: still a refusal, with R's message | n/a |
| 48 | :463-471 | a file unlike its row; NULL or NaN flow (header) | yes | refuses. An empty file's NA sums fail `identical` | n/a |
| 49 | :486-490 | every read sub-basin has 366 bins with n = n_days (header: "missing from a year, without its 22,646 days") | yes | refuses (full outer merge plus `anyNA` plus row count) | n/a |
| 50 | :491-496 | parity bound in every bin (header) | yes | refuses | n/a |
| 51 | :504 via wet_routed_years | a day twice, NA flow, short (header) | yes (rows 9-14) | refuses | yes (rows 9-14) |
| 52 | :505 | chunk rows = segments x 22,646 | yes | refuses | n/a |
| 53 | :515 | mod's stations = seg's | yes | refuses | n/a |
| 54 | :559 | "a stage whose candidates are not scored at the same gauges on the same years" (header) | yes | refuses; holds by construction (one year set per gauge), so the assertion can fire only on a per-candidate NA NSE | n/a |
| 55 | :592-594 tab_of | (not a guard) an empty target set | n/a | **aborts with an R error before the report is written** (Finding 4) | n/a |

Every refusal the header's "what it refuses" and interface sections name has an implementation (rows 32-54).

## Findings

- **[severity: fragile] R/wet_departure_carry.R:111-113, with R/wet_donor_weights.R:40-46. This lies inside round 2's fix.**
  - **Defect:** the slice check `!nrow(mod)` counts rows produced by `modelled[modelled$variable == v & modelled$period == p, ]`. An NA in `variable` or `period` gives an NA subscript, and `[` returns an all-NA phantom row for it, so the check passes. A slice whose rows all carry an NA `value` also passes. In every such case each `series()` is empty, every r is 0, and the target falls back to distance. Only the `weighting` column shows it.
  - **Probe:** with `period` all NA, `variable` all NA, or `value` all NA, HEAD returns `weighting = "distance"`, `D1:0.4325:0.000 D2:0.2846:0.000 D3:0.2829:0.000`. The same data with `period = "Migration"` is refused.
  - **Why it matters:** the fix exists to refuse a mislabelled `modelled`. An NA label, such as one left by a left join of segments to window statistics, is the mislabel that most often arrives this way, and it still passes.
  - **Not reached by scripts/departure_pcic.R today:** `mod` is an inner `merge()` of `seg` with `wet_window_stats()` output, which writes no NA label or value.
  - **Fix:**
    - Subset with `%in%`, or with `which()`.
    - Refuse when no station in the slice has a usable value: non-NA, and > 0 unless `days`. That is the predicate `series()` already applies.

    A slice whose values are all <= 0 is the rule's own case (every series routed to 0, so r is NA, so the target falls back) and can stay as it is.

- **[severity: fragile] scripts/departure_pcic.R:281-297.**
  - **Defect:** the header's refusal of uncommitted R/ or scripts/ exists "so the recorded commit rebuilds the report". The header also says to run a frozen copy (`$TMPDIR/d.R`).
    - The dirty check reads the repository's `scripts/`, never the copy.
    - `code_md5` (the copy's md5) is not compared with `tools::md5sum("scripts/departure_pcic.R")`.
    - `code_md5` is not printed in the report.

    So a stale or edited copy writes a tracked report stamped with HEAD's commit, and no check fails. Only #130, if it compares the rds's `code_md5` the way `scripts/departure_snow.R:162` does, would see it, and only in the rds.
  - **Sibling:** `scripts/departure_pilot.R:223-228` has the same gap (pre-existing).
  - **Fix:** after the dirty check, refuse unless `identical(code_md5, unname(tools::md5sum("scripts/departure_pcic.R")))`.

- **[severity: fragile, minor] scripts/pcic_routed_lib.R:193-197, `routed_weights()`.**
  - **Defect:** `sprintf("%.0f", unique(lfid))` formats a bit64 `integer64` (RPostgres' bigint) from its raw bits, so every id prints as `"0"`. Probe: `sprintf("%.0f", bit64::as.integer64(707104006))` gives `"0"`. `!anyNA(lfid)` passes, the query returns no rows, and the function documents an absent row as an uncovered segment. So the defect reads as "PCIC covers none of these" rather than as an error.
  - **Not reached today:** departure_pcic.R passes `as.integer()`'d ids (lines 353, 414).
  - **Why it matters:** the helper is described as "Shared by every run", and FWA ids arrive from Postgres as bigint.
  - **Fix:** coerce with `as.numeric(lfid)`, which bit64 makes exact below 2^53, before formatting. Or refuse a non-numeric or classed input.

- **[severity: fragile, minor] scripts/departure_pcic.R:592-594 with 619-623.**
  - **Defect:** if the short-record test set comes out empty, `tab_of(list())` stops with "no input has determined the number of cases" (`complete.cases(NULL)`, probed).
  - **Why it matters:** this happens after stage 1 and stage 2 have been decided and before `writeLines(out, report)`. The registered test set "decides nothing", but its absence loses the deciding report. The header names no such refusal.
  - **Likelihood:** low. The stations rds `test` holds 117 accepted gauges, and 08EE018 is expected from the box rule.
  - **Fix:** return an empty table (`n_scored = 0`, NA medians) when `sc` is empty.

No other finding:
- Round 1's and round 2's fixes hold against their own cases (tests green; mutation red for round 2's check).
- The product block implements every interface-section refusal (rows 44-52).
- `routed_annual()` reading the 1981-2010 run for the "#58's definition" count gives the same coverage as 1951-2012 (315 = 315 on the local fwapg).
