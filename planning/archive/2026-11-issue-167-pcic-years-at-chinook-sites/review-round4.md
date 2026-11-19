# Code-check round 4: the enumeration that closes section 6's empty-pool class (#147)

## Checklist read

- **code-check.md:** I read these three in full: "Zero-length, empty, and unset are three different things", "One fact derived twice" (including its rule to end on an enumeration of every derived column with its population), and "A guard that fails toward pass". I read the other Mechanisms H3s through the index only.
- **code-check-r.md:** I read these two in full: "`paste()` with a zero-length argument returns length ONE, not zero" and "`data.frame()` recycles a scalar against a zero-length column". I re-checked "`$` on a list partial-matches" against the rds names (`cov`, `cov_series`, `cov_fits`). The rest I read through the index only.
- **code-check-shell.md and code-check-spatial.md:** index only, because the fixes add no shell or spatial code.

**What I read and ran:**

- The code as it stands at d5435ccb: `scripts/departure_site.R` (lines 366-404 and 1230-1438), `scripts/departure_site_snow.R` (lines 170-300 and 488-566), `scripts/departure_site_lib.R` (the parity helpers and `site_carry_ship`), `R/wet_departure_carry.R`, `R/wet_donor_weights.R`, `routed_weights()`, and both data-raw consumers.
- Snippets, run in a scratch copy at `scratchpad/r4.R`: the 0-row and 1-row `held` builds, `quantile` on empty and all-NA columns, the `med_na` km path, a `cov_mx` entry with no years, `donor_km` with zero donors, the 0-row `routed_weights` assignment, and `seq_len(nrow(NULL))`.
- The working-tree `data/checks/departure_site_maxan_bulk_20260717.txt` (a pre-fix run, see the last finding), as evidence of how the main path runs.

## Enumeration

Every place below is either one of round 3's places or one the fixes added. "Holds" means the value printed or stored is the one its sentence names, or the run refuses on a real defect.

| place | condition | holds? | evidence |
|---|---|---|---|
| `cov_seg` build, integer64 mouth id (`:376-382`) | ungauged site | **holds** | `as.numeric()` on both sides before `rbind`, then `as.integer`. `stopifnot(!anyNA, > 0)` refuses the bit-copy 0 that round 1 found. On 0 rows, `all(logical(0))` is TRUE. |
| `routed_weights` call (`:383`) | `cov_seg` empty | **holds** | It is guarded by `if (nrow(cov_seg))`, so `routed_weights`'s own `stopifnot(length(lfid) > 0)` (`pcic_routed_lib.R:196`) is never reached on empty input. `cov_w` is NULL and the `%in% NULL$...` filter gives 0 rows. |
| `routed_weights` returns 0 rows | box gauges snapped but none has a weights row | **holds** | The snippet gives a 0-row frame with `upstream_subids = list()`, no error. `linear_feature_id::int` means `%in%` compares integers, not integer64 bits. |
| ungauged identity `stopifnot` (`:385-388`) | mouth with or without a weights row | **holds** | It compares two logicals of length 1, both on integer ids. |
| PCIC reads (`:394-404`) | no covered segment | **holds** | `cov_check`, `cov_par` and `cov_days` stay NULL, and nothing is downloaded. No sections 1-5 name is shadowed: the new names are used only at `:371-402` and in section 6. No RNG is touched. |
| `mod` (`:1231-1238`) | `cov_days` NULL | **holds** | It is a typed 0-row frame, so `order()` is fine and `covered` is `character(0)`. |
| section 6 header, PCIC line (`:1321`) | `cov_check` NULL | **holds** | It prints "not read, since PCIC covers no box gauge and no target here". It no longer reads `length(NULL$files)` as 0 with a NULL commit. |
| "Covered … The target" line | no covered gauge | **holds** | `sum(... %in% character(0))` is 0, the not-covered list names every pool gauge, and the target reads "NOT covered". |
| `cov_one` guard (`:1265`) | pool of 1, or a gauge related to every other covered gauge (leak-free) | **holds** | `donors ⊆ cp ⊆ dep_pool ⊆ wsel`, so the predicate is exactly "a donor other than g is left", and `cov_na(g)` is returned before `wet_departure_carry` can stop with "no donor rows". |
| `cov_run` bind (`:1297`) | empty pool | **holds** | The snippet gives a 0-row frame with all 7 columns typed (chr, int, num, num, logi, num, num), so the template keeps the columns. `resid` is NULL, and `length(NULL)` is 0 downstream. |
| `cov_run` bind | pool of 1 | **holds** | The snippet gives 1 row: `n = 0L`, NA scores, `fallback = FALSE`. The `stopifnot(identical(is.na(...)))` at `:1299` holds, because `cov_na` sets both columns to NA. |
| `stopifnot` both weightings scored together (`:1299`) | `n ≥ 3` | **holds** | NSE is NA only when the observed series is constant, which is the same for both weightings. Neither `cz` holds an NA, because `yrs` lies within each `a$year`. |
| `cov_carry` covariance path, inside `wet_departure_carry` | every covered segment in g plus donors routes a `min7` to 0 in every year | **holds in practice** | `wet_departure_carry.R:111` stops with "`modelled` has no usable rows". That needs zero routed `min7` at the held-out gauge and every donor at once, and every donor has at least 10 positive observed baseline years. It is not reachable on real routed flow, and if reached it is loud, not silent. |
| table row, n (`:1336`) | all cases | **holds** | `n_of` = `sum(!is.na(covariance_pick))` = the scored gauges, and 0 when the pool is empty. |
| table row, quartiles (`:1334-1335`) | empty, all NA | **holds** | The snippet gives `quantile(numeric(0) or NA, na.rm = TRUE)` = NA NA NA, which prints "-". Same population as n, by `:1299`. |
| table row, `fall` (`:1337`) | gauges carried but not scored (fewer than 3 years) | **fails (cosmetic)** | `sum(h$fallback)` counts every carried gauge. The snippet gives n scored 1, fall 1, on 2 gauges of which one is unscored. See finding 1. |
| table row, km d and km c (`:1338-1339`) | scored only | **holds** | `med_na(h$km_*[!is.na(h$covariance_pick)])` covers the same set as n. When that set is empty, the snippet gives NA, which prints "-". |
| section 3 comparison line (`:1341-1345`) | its counts and median against one gauge set | **holds** | "the %d of these %d scored gauges that section 3 also scores": the first count is `sum(!is.na(s3$nse))` over the section 6 scored set, the second is `sum(!is.na(h6$distance))`, and the median is `med_na(s3$nse)`, over exactly the first count's gauges. `cov_pool ⊆ dep_pool_of("q_mean","migration")`, which is section 3's `dp`, so every scored gauge has a row in `cm$held`, one row per gauge. With nothing scored it reads "0 of these 0 … median -". |
| per-gauge block (`:1347`) | 0 rows | **holds** | `if (nrow(h6)) … else "  none"`. There is no phantom paste line. |
| per-gauge block | all rows `cov_na` | **holds** | It prints "G   0      -      -" for each gauge, as intended. |
| verdict (`:1315`) | empty pool, pool of 1, all NA | **holds** | `site_carry_ship` gets `med_na` NAs and n = 0, and returns distance with "the target is not covered", "%d covered donors, under 5" or "0 and 0 gauges scored, under 10". The `%d` arguments are integers. |
| target route guard (`:1362`) | a statistic with no covered donor while the migration mean has 5 or more | **holds** | It uses the same predicate as `cov_one`. The statistic goes to `cov_none` and is printed as "No covered donor, so not carried: …". Section 4's distance route is unaffected. |
| target route, the held-out run of a carried statistic | its run scored nothing | **holds** | `res_c` is NULL or `numeric(0)`, so `boot` is NA (`:1381`), `ci_c` is NA NA, and both print "-". |
| `is_set` / `which(is_set)` | a non-max combo | **holds** | Exactly one set matches, because leak-free has non-NULL `drop` (the run stops at `:1310` when `related` is NULL). `v == "q_max"` short-circuits before indexing. |
| migration mean always carried when covariance_pick ships | verdict's `donors ≥ 5` | **holds** | The verdict uses `length(setdiff(cov_pool("q_mean","migration"), target))`. The loop's guard is the same set under `wsel` (`cov_pool ⊆ wsel`), so `cov_mx` is never empty, and `"q_mean migration"` is always in it. |
| `cov_mx` entry with no pre, post, ref or recent years | all | **holds** | From the snippet: `carried` is NaN and `fmt(NaN)` prints "-". `pc(NaN)` prints "-". `quantile(NA, na.rm = TRUE)` gives NA NA, so `ci_txt` prints "-". `interval_of` and `cover_of` return NA for fewer than 2 years. `donors_c` is `character(0)`, and `paste` gives "", printing "carried ." as section 5 does. `%4d` gets integer `sum()`s. |
| "Fell back" and "gauges … rest on" loops | `cov_mx` non-empty (above) | **holds** | They loop over the statistics actually carried. A skipped statistic is named once, in "No covered donor". |
| `cov_out` (`:1435-1438`) | no PCIC read | **holds** | `pcic = NULL`, `scores` holds typed 0-row frames, and `mx = NULL`. No consumer reads `cov$pcic` yet. |
| snow script, `pr$cov` partial match | rds names | **holds** | The site rds gains only `cov` (`departure_site.R:1460`), and no other name starts with "cov". A `$cov` read on the snow rds is never made: chinook and short-record read `$series`, `$fits`, `$snow` and `$gauges`, all exact. |
| snow section 6, `cov$verdict` ships distance (`:510-514`) | | **holds** | It prints "ships distance here, so there is no second carried route to fit". `cov_series` and `cov_fits` are NULL and saved as NULL. |
| snow section 6, `cov$mx` lacks a window (`:517`) | spawning mean not carried | **holds** | `cov_w` keeps only the windows present. The header uses `c(migration = "mig", spawning = "spw")[cov_w]`, so the column count matches the series. |
| snow section 6, `cov$mx` lacks both windows | | **holds (unreachable)** | `seq_len(nrow(NULL))` at `:534` would error (the snippet confirms), but the migration mean is always carried when covariance_pick ships (row above). |
| snow `fit_series` on a covariance series | | **holds** | `snow[[target]]` exists, because `polys` holds the target for extend and for ungauged. `data.frame(year = a$year, …, donor = NA_character_)` fails only on 0 rows (the snippet confirms), and `wet_departure_carry` cannot return 0 rows once a donor exists. |
| parity, `site_parity_pilot` | section 6 lines in `out` | **holds** | The change-table regex `"pre post +change +% normal"` does not match section 6's header (`"pre post   carried"`), so `table_of` still finds exactly one table. The rest is set-based: added lines can only satisfy tracked lines, never remove one. I measured on the working-tree report: 0 of the pilot's tracked lines appear in section 6, and every line before `## 6.` is unchanged (`git diff` adds only from line 1056). |
| parity, `site_parity_snow` | snow section 6 lines | **holds** | It is set-based, and section 6's rows carry " cov" labels and 1-2 column per-year rows, so none can equal a tracked line of #121's 6-column table. |
| `chinook_sites_data.R`, rds fields | `x$mx`, `x$race`, `x$carried`, `x$normal`, `x$windows`, `x$baseline`, `s$series`, `s$fits`, `s$snow`, `s$gauges` | **holds** | None of these changed shape. The site rds gains `cov`, the snow rds gains `cov_series` and `cov_fits`, and the `fit_series` refactor is byte-identical (round 3, by execution). |
| `chinook_sites_data.R`, report patterns | `sec(... "^Per gauge, migration mean")[1]` | **holds** | Section 3 always prints "Per gauge, migration mean, k = 5" (`departure_site.R:854`, unconditional) before section 6's line, so `[1]` stays section 3's. The method-row regex `"^  %-6s +n +n +n$"` cannot match a section 6 row (10 fields). The section 5 `held()` rows have 14 fields, and section 6's rows have 13. |
| `chinook_sites_data.R:188`, ungauged per-year `held()` | | **fails toward pass (fragile)** | Section 6 prints the same `"  %4d %9s %9s %3d"` format over the same years (`departure_site.R:1430`). See finding 2. |
| `short_record_vignette_data.R` | every `one_line()` and `grep` | **holds** | Section 6 does not match these: `^%s per year`, `^HEADLINE`, `^Extension pool`, the `$`-anchored score rows, `^Snow per watershed`, `^Log departures per series` ("Its log …" does not start the line), or the fit rows `lab\s+both` (section 6 has "… migration cov both"). `one_line` requires exactly 1 match, so any collision would abort, not pass. |

## Findings

- **[severity: fragile]** `scripts/departure_site.R:1337`: the `fall` column is `sum(h$fallback)` over every carried gauge in the pool, including gauges with fewer than 3 years, which are carried but not scored.
  - Every other column on the row covers the scored set: n, both sets of quartiles, and since d5435ccb both km medians.
  - So `fall` can exceed the n printed beside it. A pool of 2 with one unscored gauge that fell back prints n 1, fall 1, where the 1 is the unscored gauge.
  - It decides nothing.
  - Fix: `sum(h$fallback[!is.na(h$covariance_pick)])`. Or say "of the gauges carried" in the legend at `:1343`.
  - **Rule:** code-check.md "One fact derived twice" (its closing rule: enumerate every derived column with its population).
- **[severity: fragile]** `data-raw/chinook_sites_data.R:187-189`: for an ungauged site, each year of the carried distance route is checked with `held(line, rp$lines)`, which tests membership over the whole report.
  - Section 6 now prints the covariance route in the identical `"  %4d %9s %9s %3d"` format, over overlapping years (`departure_site.R:1430`).
  - In years where both weightings rest on the same single donor (n = 1, common before about 1977, as Maxan's section 6 shows), the two lines are byte-identical. So a section 4 line missing or wrong at those years would be passed by its section 6 twin.
  - It cannot fire today, because both lines come from one run. But the guard now fails toward pass on a population it was not written for.
  - Fix: hold the per-year lines against `rp$lines[seq_len(grep("^## 6\\. ", rp$lines)[1] - 1)]`, or against the section 4 block. The data-raw scripts are not on this branch's diff, but section 6 created the duplicate format.
  - **Rule:** code-check.md "A guard that fails toward pass".
- **[severity: fragile]** `data/checks/departure_site_maxan_bulk_20260717.txt` (working tree, modified): its section 6 was written before d5435ccb.
  - It still has the old legend "km d, km c: the median over gauges …" and the old comparison line "at the same 30 gauges".
  - The values may agree, but the text is not what the current code prints. Rerun `scripts/departure_site.R maxan` (and the snow script, whose rds `code_md5` check will refuse the old site rds) before committing any report.
  - **Rule:** code-check.md "Written data outlives the fix".

Nothing else found. In the fixes themselves:

- I found no new defect in the `cov_seg` integer64 handling, the NULL PCIC path, the `cov_one` guard, the 0-row template, the target-route guard, the km medians, the per-gauge `else`, or the section-3 line's counts.
- The four round-3 fails are closed: 1 (abort), 2 (phantom line), 3 (km `na.rm` and population) and 4 (comparison counts).
- The only abort left on a filtered subset is `wet_departure_carry`'s "no usable modelled rows". It needs every covered segment routed to 0, and it is loud, not silent.

/Users/airvine/Projects/repo/wet/planning/active/review-round4.md
