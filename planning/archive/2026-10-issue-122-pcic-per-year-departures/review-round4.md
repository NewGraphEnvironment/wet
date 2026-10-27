# Review round 4: #122 branch diff (code-check, HEAD ad15236)

## Checklist read

- **code-check.md** (37 H3): I read the prose of all 14 H3 under `## Mechanisms`, skipping the tables:
  - a guard that fails toward pass
  - a fixture that cannot reach the failure mode
  - a proxy is not the property
  - verification that reads its own output
  - a guard's scope, escape hatches and remedies
  - a fix lands in one of two callers
  - restore the bug and prove the guard fires
  - a shared working tree
  - a wrapper's exit is not the work
  - zero-length, empty and unset
  - the probe is broken before the world is
  - written data outlives the fix
  - serialization loses meaning silently
  - one fact derived twice

  Not read in full: 23 (Rules that stand alone, Security, Spreadsheets and PDFs). I read only their index lines, and none names a tool or shape in this diff.
- **code-check-r.md** (111 H3): I read 10 in full:
  - a database driver's value is not a base R type (integer64 and `sprintf`)
  - `sprintf("%g")` in SQL
  - `[[` on a named atomic vector with an absent key
  - `match()` treats NA as a value
  - Rscript reads a script as it runs
  - `system2(stdout = TRUE)` status
  - testthat counts an uncaught error under `error`
  - `paste()` with a zero-length argument
  - a `function(...)` mock hides arguments
  - base name shadowing

  Not read in full: 101. I checked their index lines against the round-3 fix diff. Rounds 1 to 3 read 46, 17 and 8 of them.
- **code-check-shell.md** (67 H3): I read 0 in full. The only shell use is `system2("git", c("status", ...))` and `rev-parse`, which the R `system2` entry covers. I checked the index lines (pathspec magic, fetch, push), and none applies. All 67 are unread.
- **code-check-spatial.md** (93 H3): I read 1 in full: `terra::project()` given only a CRS. The script projects a point matrix from EPSG:4326 to EPSG:3005 for km distances that appear in the report only, printed to 0 decimals, so a sub-metre datum step cannot move them. ad15236 does not touch this code. Not read: 92.

## What was checked, and how

- **Tests at HEAD.** I ran the tests in a `git archive HEAD` copy (`NOT_CRAN=true`, `load_all(copy)`, counting `failed | error`). All three files had 0 failed, 0 error and 0 skipped:

  | test file | passed |
  |---|---|
  | `departure_carry` | 43 |
  | `donor_weights` | 25 |
  | `routed_years` | 33 |

- **Mutations.** I ran 39 mutations, each in a fresh copy of the tree. Each deleted or weakened one guard and ran that guard's test file. Results are in the enumeration below, as M1-M14 and the R, C and D rows.
- **Read-only fwapg queries.** `linear_feature_id` is `bigint`. Its range is 2,000,051 to 868,144,683 in `whse_basemapping.fwa_stream_networks_sp`, and 3,000,000 to 868,144,671 in `pcic.segment_weights`.
- **md5 guard.** I copied its code verbatim into a throwaway git repo under the scratchpad and ran it on six cases. The results are under "Round 3's fixes", item 3.
- **R probes:**
  - `sprintf("%.0f", factor)` gives level codes.
  - `sprintf("%.0f", "707")` errors.
  - `anyNA(integer64 NA)` is TRUE (bit64 4.8.6).
  - `as.numeric(integer64)` is exact.
  - `[[` on a zero-length named numeric is "subscript out of bounds".
  - `apply()` over a 0-row matrix gives named NAs.
  - `wet_routed_years()` refuses an NA lfid, character years, empty years, a missing `share` and a non-list `upstream_subids`, each with its own guard's message.

## Round 3's fixes

1. **NA-label refusal** (`R/wet_departure_carry.R:79-81`). Correct.
   - It sits before the duplicate check.
   - It covers all four labels over the whole `modelled`, not only the slice.
   - It works on a tibble.
   - Deleting it reddens all four label cases (M1: 4 failed).
   - Behind it, the new `which()` on line 114 is unobservable. Deleting `which()` leaves the suite green (M6), because no NA label can reach line 114 any more. It is belt and braces, not a guard.
2. **Slice check** `!any(!is.na(mod$value) & (days | mod$value > 0))` (`:114-119`). Correct on every spelling of empty that round 3 named:

   | slice | result |
   |---|---|
   | no rows (exact-match miss) | refused |
   | all-NA `value` | refused, through `!is.na` (`FALSE & NA` is `FALSE`) |
   | all values `<= 0` for a flow statistic | refused (the accepted tradeoff) |
   | NA labels | refused first, at item 1 |

   Mutations M3 (deleted), M4 (without `!is.na`, which raises `if (NA)`) and M5 (round 2's "rows exist" form) each go red.

   Two limits remain:
   - **The `days |` arm cannot be reached** from `wet_window_stats()` output, because `cov_day >= 1` (`R/wet_window_stats.R:207`). It has no test and needs none.
   - **A mislabel that hits only some stations is still read as r = 0.** That covers a single station's all-NA value, or a partial mislabel. The accepted tradeoff covers it. It is the residue of round 3's mechanism: the check is still "is anything usable in the slice", not round 3's positive test "this station's slice exists and is <= 0". No action under the stated tradeoff.
3. **md5 comparison** (`scripts/departure_pcic.R:297-300`). It compares the right two files:
   - `self`, the file Rscript runs, hashed at line 285 before anything else.
   - The working-tree `scripts/departure_pcic.R`, which the dirty check on the line before ties to HEAD.

   The relative path is safe, because `source("scripts/wb_cv_lib.R")` at line 275 already requires the working directory to be the repo root.

   Probe in the throwaway repo:

   | case | result |
   |---|---|
   | identical copy, in a path with a space (`~+~` decoding) | passes |
   | stale copy | refuses ("COPY DIFFERS") |
   | direct `Rscript scripts/departure_pcic.R` | passes |
   | untracked file in `scripts/` | refuses (the dirty check) |

   One escape hatch remains, and it is a deliberate opt-out rather than a finding. `git update-index --assume-unchanged` (or `skip-worktree`) on the script hides a working-tree edit from both checks. A copy of that edited file then passes, and the report names HEAD. Comparing against `git show HEAD:scripts/departure_pcic.R` would close it. The message's "at HEAD" is accurate only because the dirty check runs first.

   The report line now carries `code_md5`. Its sprintf has 5 placeholders and is given 5 arguments.
4. **tab_of()'s empty branch** (`:596-600`). It works for the consumer it was written for: the test-set tables `tt1` and `tt2` are read with `[` (`tt1$med[weightings]`), which gives named NAs and "-". **Its result cannot be read by the `[[` consumers** (Finding 2).

   An empty test set can also arise earlier, before `tab_of()`. If no candidate is accepted with a segment, `routed_weights(conn, integer(0))` at `:419` stops at `stopifnot(length(lfid) > 0)`. That stop happens at setup, before any stage work, so it fails toward refusal and costs nothing.
5. **routed_weights() `as.numeric`** (`scripts/pcic_routed_lib.R:196-198`).
   - **Precision is not a concern.** FWA ids reach at most 868,144,683, which is under 2^31. So `as.numeric` is exact (2^53 is far off), and the `SELECT linear_feature_id::int` cast cannot overflow.
   - **integer64** now formats correctly (`"868144683"`), and an integer64 NA is still refused by `!anyNA`.
   - **Character ids** now work. Before the fix they errored in `sprintf`.
   - **A factor id** formats as its level codes, both before the fix and after it. It is unreached, because both callers `as.integer()` a numeric column (the stations rds stores `linear_feature_id` as numeric, and `wet_station_snap()` as double). This is not a regression.
6. **Round 3's new tests.**
   - All but one discriminate: M7, M9, M10, M11 and M12 go red, and so do the new label and slice tests.
   - **The exception is the "needs columns" test** (Finding 1).

## Enumeration (final state)

Columns:
- **(a)** implemented
- **(b)** direction on empty, missing, NA, mislabelled or other-type input
- **(c)** firing test, by mutation this round, for R/ code

Markers:
- **CHANGED** means ad15236 changed the row.
- **NEW** means ad15236 added it.
- **OPEN** means the loop's test criterion is unmet.

| # | where (HEAD) | guard / header refusal | (a) | (b) | (c) |
|---|---|---|---|---|---|
| 1 | wet_routed_years.R:43 | duckdb not installed | yes | refuses | none (cannot without uninstalling) |
| 2 | :44-46 | `dir` one existing directory | yes | refuses | red (R2) |
| 3 | :47-50 | `weights` columns, `upstream_subids` a list. **CHANGED (test added)** | yes | refuses (probe: missing `share`, non-list) | **OPEN: green when deleted (M8).** `wet_routed_raw()` (`wet_routed_days.R:60-62`) raises the identical text after the read. Finding 1. |
| 4 | :51 | zero rows. **CHANGED (test added)** | yes | refuses | red (M9) |
| 5 | :52-54 | NA or duplicated `linear_feature_id` | yes | refuses both (probe) | duplicate half red (R5b). **OPEN: the NA half is green when deleted (R5a).** Without it, an NA lfid is routed and returned. |
| 6 | :55-57 | `years` numeric, non-empty, no NA, whole, distinct. **CHANGED (tests added)** | yes | refuses character, empty, fractional, duplicate (probe) | fractional red (M11), duplicate red (M10). **OPEN: the non-numeric and empty halves are green when deleted (R6, R6b).** |
| 7 | :58-60 | `series` one name. **CHANGED (test added)** | yes | refuses | red (M12) |
| 8 | :62-64 | a year without its file | yes | refuses | red (R8) |
| 9 | :66-67 | NA subid (round 1) | yes | refuses NA. A non-integer subid is truncated (unreachable from Postgres `subid integer`). | red (R9) |
| 10 | :78-82 | a sub-basin with no rows | yes | refuses | red (R10) |
| 11 | :83 | NA flow | yes | refuses | red (R11) |
| 12 | :89 | a date outside the years | yes | refuses | red (R12) |
| 13 | :90 | a day twice | yes | refuses | red (R13) |
| 14 | :91-95 | a sub-basin lacking days | yes | refuses | red (R14) |
| 15 | wet_routed_days.R:64 (via :101) | NA share | yes | refuses after the read | pre-existing on main (test-wet_routed_days); not re-run |
| 16 | wet_donor_weights.R:26 | `method` | yes | the caller has already `match.arg`'d it (wet_departure_carry.R:71) | none (D16 green); internal |
| 17 | :45-46 | target or donor not in `known` | yes | refuses a station absent from `modelled` | red (M13) |
| 18 | :51 | r on < 30 years counts as 0 | registered | silent by design | red (D18) |
| 19 | :53 | NA r counts as 0 | registered | silent by design | red (D19) |
| 20 | :63 | every chosen donor weighs 0: fall back, flagged | yes | flagged in `weighting` | red (D20) |
| 21 | :40-44 | `series()` drops NA and <= 0. **CHANGED (status)** | n/a | One station's all-NA or all-<=0 slice reads as r = 0 (accepted tradeoff). A whole slice with no usable value is now refused upstream (row 27). | via 27 |
| 22 | wet_departure_carry.R:73 | covariance without `modelled` | yes | refuses | red (C22) |
| 23 | :74 | `modelled` with distance | yes | refuses | red (C23) |
| 24 | :76-78 | `modelled` missing a column. **CHANGED (test added)** | yes | refuses | red (M7) |
| 56 | :79-81 | NA station, variable, period or year in `modelled`. **NEW** | yes | refuses, whole frame | red (M1, all four labels) |
| 25 | :82-84 | `modelled` duplicate key | yes | refuses | red (M14) |
| 26 | :86-102, 128-131 | x columns, target, k, x duplicates, `stations` row, no donor rows, donor baseline | yes | refuse | baseline red (C26g). The other six are green when deleted (C26a-f). They predate the branch and are unchanged by it, so they are out of scope. |
| 27 | :114-119 | no usable modelled value for the statistic (round 2, rewritten). **CHANGED** | yes | refuses no rows, all NA, all <= 0. NA labels are refused at row 56 first. | red (M3, M4, M5) |
| 57 | :114 | `which()` subscript. **NEW** | yes | redundant behind row 56 | green when deleted (M6): not a guard on its own |
| 28 | pcic_routed_lib.R:26 | `routed_where_period` length 1, `YYYY-YYYY` | yes | refuses | n/a (script lib) |
| 29 | :164-175 | `routed_daily_fingerprint` against `pcic.runs` | yes | refuses (`!isTRUE`) | n/a |
| 30 | :196-198 | `routed_weights` lfid present, not NA. **CHANGED** | yes | Refuses empty and NA. integer64 and character are now exact. A factor gives codes (as before; unreached). | n/a |
| 31 | :204 | one row per segment, array not NULL | yes | refuses | n/a |
| 32 | departure_pcic.R:279 | HYDAT release (header) | yes | refuses | n/a |
| 33 | :281-286 | run by Rscript; md5 readable | yes | refuses | n/a |
| 34 | :294-296 | uncommitted R/ or scripts/ (header) | yes | refuses, untracked files included | n/a |
| 58 | :297-300 | the running copy is the committed script. **NEW** (closes round 3 Finding 2) | yes | Refuses a stale copy (probed). Escape: assume-unchanged or skip-worktree. | n/a |
| 35 | :303 | WET_FWAPG_COMMIT (header) | yes | refuses | n/a |
| 36 | :304-307 | WET_FWAPG_DAYS_COMMIT (header) | yes | refuses | n/a |
| 37 | :308-309 | WET_PCIC_YEARS | yes | refuses | n/a |
| 38 | :310 | `cal` under other scoring code (header) | yes | refuses | n/a |
| 39 | :335-336 | windows are #120's | yes | refuses | n/a |
| 40 | :352 | 1951-2012 tables against `pcic.runs` (header) | yes | refuses | n/a |
| 41 | :358 | cal lfid not NA; cal = held-out stations | yes | refuses | n/a |
| 42 | :404-406 | migration-mean pool < 100 (header) | yes | refuses | n/a |
| 59 | :419 | `routed_weights()` given no accepted test segment (not named by the header) | yes | refuses at setup, before any stage work | n/a |
| 43 | :433 | one stations table, no duplicate | yes | refuses | n/a |
| 44 | :445-447 | a year without its file (header) | yes | refuses | n/a |
| 45 | :453-455 | `pcic.series` every year once | yes | refuses | n/a |
| 46 | :457 | one `pcic.runs` row | yes | refuses | n/a |
| 47 | :458-461 | a row on another crosswalk (header) | yes | refuses | n/a |
| 48 | :466-474 | a file unlike its row; NULL or NaN flow (header) | yes | refuses | n/a |
| 49 | :490-494 | bins and days per read sub-basin (header) | yes | refuses | n/a |
| 50 | :495-500 | parity bound (header) | yes | refuses | n/a |
| 51 | :508 via `wet_routed_years()` | a day twice, NA flow, short (header) | yes (rows 9-14) | refuses | red (rows 9-14) |
| 52 | :509 | chunk rows = segments x 22,646 | yes | refuses | n/a |
| 53 | :519 | mod's stations = seg's | yes | refuses | n/a |
| 54 | :563 | candidates scored at the same gauges and years (header) | yes | refuses | n/a |
| 55 | :596-600 | `tab_of()` on an empty set. **CHANGED** | n/a | The test set now reports. **An empty statistic pool still stops at the report loop (`:766`, `[[`), before `writeLines()` (`:791`).** Finding 2. | n/a |

**Header refusals.** Every refusal the header's "what it refuses" and interface sections name is implemented (rows 32-54 and 58).

**Termination.** Two of the loop's three conditions hold:
- Every guard fails toward refusal or is a registered fact of the rule (rows 18, 19, 21).
- Every header refusal is implemented.

**The third condition does not hold:** "every guard in R/ has a test that makes it fire" is unmet at:
- row 3 (shadowed)
- the NA half of row 5
- the non-numeric and empty halves of row 6
- row 16 (internal, validated by the caller)
- row 1 (cannot be tested)
- row 26's six pre-existing guards (out of scope)

## Findings

- **[severity: fragile] tests/testthat/test-wet_routed_years.R:124 (inside round 3's fix).**
  - **Defect:** `expect_error(routed(w = w[setdiff(names(w), "share")]), "needs columns")` cannot see the guard it was added for. With `R/wet_routed_years.R:47-50` deleted, the test stays green (33 passed, M8). `wet_routed_days()` → `wet_routed_raw()` (`R/wet_routed_days.R:60-62`) raises the identical message, "`weights` needs columns linear_feature_id, subid, share, upstream_subids, upstream_subids a list", after the duckdb read.
  - **Why it matters:** the guard works (probe), but this row of the table claims a firing test it does not have, and a later edit that drops or reorders the guard would go unnoticed.
  - **Fix:** make the outcome differ. For example, pass a `dir` with no year files (`withr::local_tempdir()`): with the guard the error is "needs columns", and without it "has no synthetic_historical file". Do the same for the non-list `upstream_subids` half.

- **[severity: fragile, minor] scripts/departure_pcic.R:596-600 with :634-638 and :766 (also :684-686, :610-614) (inside round 3's fix).**
  - **Defect:** the empty branch of `tab_of()` returns zero-length named `med`, `q25` and `q75`. Only the test-set consumers read them with `[`. The `[[` consumers raise "subscript out of bounds" (probed):
    - `add_sens()` stores `a$med`, and the report loop then reads `s$s1[["distance"]]`.
    - `med_line()` reads `t$q25[[nm]]`.
    - `decide()` reads `t_logo$med[[ch]]`.
  - **Effect:** an empty pool for any reported statistic (`run_set()` over `character(0)` gives `list()`) still stops after both stages are decided and before `writeLines(out, report)`. That is round 3's Finding 4, moved from `tab_of()` to line 766.
  - **Likelihood:** not reached on today's data. The migration-mean pool is held to at least 100, and every other pool is drawn from the same calibration gauges with at least 10 baseline years.
  - **Fix:** return NAs named by the candidate set: pass `names(cands)` into `tab_of()`, or `stats::setNames(rep(NA_real_, length(nm)), nm)` with `nm` given by the caller. The `[[` consumers then print "-" as the `[` ones do.

- **[severity: fragile, minor] R/wet_routed_years.R:52 and :55 (not inside round 3's fix; open in the enumeration since round 3).**
  - **Defect:** three guard halves have no test that fires them. The guards themselves refuse correctly (probe).

    | guard half | without it |
    |---|---|
    | `anyNA(weights$linear_feature_id)` | routes and returns an NA segment silently |
    | `!is.numeric(years)` | ends in a later, less specific error |
    | `!length(years)` | ends in a later, less specific error |

    Deleting each leaves `test-wet_routed_years.R` green (R5a, R6, R6b).
  - **Why it matters:** the loop's own criterion ("every guard in R/ has a test that makes it fire") is unmet for the new exported function. The NA lfid half matters most, because without it the failure is silent.

Not findings, recorded so the next round does not re-derive them:
- The md5 guard's `assume-unchanged` / `skip-worktree` escape (a deliberate opt-out).
- A factor `lfid` in `routed_weights()` gives codes, unchanged by the fix and unreached.
- `which()` at `R/wet_departure_carry.R:114` is redundant behind the NA-label guard.
- The `days |` arm of the slice check cannot be reached from `wet_window_stats()`.
- `wet_departure_carry()`'s six pre-existing untested guards predate the branch.
- Nothing else in the whole diff turned up beyond rounds 1 to 3, re-read this round against HEAD:
  - the product block's SQL, the catalogue and the parity check
  - the stage rules and `decide()`
  - the common-years scoring
  - the rds contents (`by_statistic`)
  - the report's sprintf argument counts

## Closure (the session, after round 4's fixes)

Round 4's fixes: the columns test now runs on an empty directory, so without the guard the error would be the missing year file; tests added for an NA `linear_feature_id`, `years = integer()` and `years = "1981"`; `tab_of()` takes its candidate names and returns NA medians named by them, probed through `med_line()`, the sensitivity readers and `fmt()` (all print "-").

Mutation proofs in a scratch copy, failed test blocks with the guard deleted:

| row | guard | failed blocks |
|---|---|---|
| 3 | `weights` columns check | 1 |
| 5 | `anyNA(weights$linear_feature_id)` half | 1 |
| 6 | `!is.numeric(years)` half | 1 |
| 6 | `!length(years)` half (after the test moved to `integer()`) | 1 |

Rows left open by round 4 and why they end the loop: row 16 is internal and its input is checked by its only caller; row 1 (duckdb absent) cannot fire without uninstalling duckdb; row 26 is six guards on main that predate the branch. Every other row of the 59 fails toward refusal or is a registered fact of the rule, every header refusal is implemented, and every branch-added guard in R/ has a test that goes red without it. The loop ends on this enumeration.
