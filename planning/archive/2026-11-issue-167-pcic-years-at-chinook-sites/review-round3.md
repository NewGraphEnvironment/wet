# Code-check round 3: #135 cache and #147 sections 6 (site and snow)

## Checklist read

- **code-check.md:** I read the prose of all 14 H3s under `## Mechanisms`, skipping `|` rows and evidence blocks. I read "Zero-length, empty, and unset are three different things", "One fact derived twice" and "A guard that fails toward pass" in full. 24 other H3s I read through the index only.
- **code-check-r.md:** I read these in full:
  - `paste()` with a zero-length argument returns length ONE, not zero
  - `data.frame()` recycles a scalar against a zero-length column
  - `$` on a list partial-matches, so a longer sibling key answers for a missing one
  - A database driver's value is not a base R type — and it fails twice
  - `bind_rows()` of all-`NULL` is a 0 x 0 tibble, and a typed template must take its types from the rows' source
  - `sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent

  116 not read beyond the index.
- **code-check-shell.md:** none read in full, because the diff has no shell code. 72 not read.
- **code-check-spatial.md:** none read in full. The one spatial call, `terra::project()` on a matrix, was checked against its index line, and the result is only a km report column. 94 not read.

## Mechanism

All three earlier findings and the author's catch come from one assumption: code written for a population that is never empty is run on a filtered subset where it can be.

- Sections 3 and 5 run on the validated departure pool, which earlier refusals guarantee holds members.
- Section 6 runs the same idioms on a subset: covered ∩ pool, then per statistic, then less a held-out gauge's related gauges.
- On that subset, empty, a singleton and "no donor left" are all reachable. So are an all-NA score column and a different set of scored gauges.
- R answers each of these with a plausible value, not an error. `paste0` gives one phantom line, `data.frame()` a recycling error, an un-`na.rm`'d `median` an NA, and a count taken from a neighbouring population a "same N" that is not the same.

Every place in the diff that this mechanism reaches:

| Place | Verdict |
|---|---|
| `cov_seg` empty (extend site, no accepted snap) | **holds**. `as.integer`/`stopifnot` pass on length 0, `cov_w` is NULL, the filter gives 0 rows, and no fwapg read is attempted. |
| `cov_w` with 0 rows (no `pcic.segment_weights` row) | **holds**. `cov_seg` is filtered to 0 rows and nothing is read. The ungauged identity assertion compares FALSE with FALSE. |
| `mod` empty | **holds**. It is a typed 0-row frame, and `order()` on it is fine. |
| `covered` empty | **holds**. Every `cov_pool()` is `character(0)`. Each `cov_run` binds under the `cov_na("none")$row[0, ]` template, so the columns and types are kept. The `stopifnot(identical(logical(0), logical(0)))` passes. |
| Covered pool of 1, or a gauge related to every other covered gauge | **holds**. `cov_one` returns `cov_na()` before `wet_departure_carry()` is called. |
| Covered pool smaller than k (2 to 5) | **holds**. `wet_donor_weights()` takes `k <- min(k, length(donors))`, `near` covers every candidate, and every candidate is in `known`. |
| `quantile(..., na.rm = TRUE)` on an empty or all-NA column | **holds**. It returns `NA NA NA`, which prints "-". |
| `sum(h$fallback)` and `n_of()` with `%4d` | **holds**. Both are integer, including 0. |
| `med_na` going into `site_carry_ship` | **holds**. An NA median gives "a median is NA". `donors`, `n_loo` and `n_lf` are integers for `%d`. |
| `median(h$km_distance)` / `median(h$km_covariance_pick)` | **fails** (cosmetic). No `na.rm`, so any `cov_na` gauge in the pool prints "-" (finding 3). |
| `paste0("  ", vapply(split(...)))` for the per-gauge block | **fails** (cosmetic). With 0 held rows it prints one phantom `"  "` line (finding 2). Section 3's same idiom cannot reach 0 rows. |
| Section 3 comparison line, `s3` | **mostly holds** since round 2. It can still count fewer than section 6 scored where section 3 has fewer than 3 years at a gauge section 6 scores (finding 4). |
| Target route under covariance_pick, for each combo | **fails** (abort). The rule's donor floor is checked on the migration mean only. Any other statistic's covered pool can be empty (finding 1). |
| `cov_mx` entry with no pre, post, ref or recent years | **holds**. `boot` is NA, `quantile(na.rm = TRUE)` gives `c(NA, NA)`, and `interval_of`/`cover_of` return NA for fewer than 2 years. `carried` is NaN and `fmt(NaN)` prints "-". `donors_c` is `character(0)`, which prints "carried ." as section 5 already does. |
| `max` combos | **holds**. `is_set` is all FALSE and is not indexed, because `v == "q_max"` short-circuits. For every other combo, `which(is_set)` is exactly 1, since leak-free carries a non-NULL `drop` and the run stops earlier when `related` is NULL. |
| `cov_sets` entries read as `s$drop` | **holds**. There is no key with a "drop" prefix to partial-match. |
| Snow: `pr$cov` absent | **holds**, though the branch is unreachable. An rds without `cov` was written by another `departure_site.R`, and the `code_md5` check refuses it. `$cov` has no sibling to partial-match. |
| Snow: `fit_series` on the covariance carried series | **holds**. The series covers 1931 to 2025 and is joined to snow years 1950 to 2025. `data.frame(year = a$year, ..., donor = NA_character_)` would only fail with 0 carried rows, and `wet_departure_carry` cannot return 0 rows once a donor exists. The existing carried series uses the same construction. |
| Snow: `dep_of()` on a covariance series | **holds**. `s$d` is kept by `fit_series`. |
| Snow: the `fit_series()` refactor | **holds**, checked by execution. I ran the old loop and the new function on synthetic series, including NA departures, a series starting before 1950 and a short series. `identical()` was TRUE for `series`, for `fits` and for the serialized bytes. The row names are automatic 1..N and the `series` column is first and integer in both. No later code reads the old loop's leftover globals (`d`, `sw`, `co`, `ci`, `l1`, `base_*`). |
| Snow and site report readers (`data-raw/chinook_sites_data.R`, `short_record_vignette_data.R`) | **holds**. I checked every `one_line()` pattern and every `grep(...)[1]` against the new section 6 lines. None matches: the label has " cov" appended, the header text differs ("Under covariance_pick …", "Its log departures …"), the column counts differ, and `$` anchors are in place. `held()` checks membership only. |
| `source("scripts/pcic_routed_lib.R")` before sections 1-5 | **holds**. It defines only `routed_*` and `shipped_heldout`. None shadows a name sections 1-5 use, and none touches the RNG. |

## Findings

- **[severity: fragile]** `scripts/departure_site.R:1359`: where covariance_pick ships, the target's route is carried for every combo from `setdiff(cov_pool(v, p), target)`. But `site_carry_ship()`'s `donors >= 5` is checked only on the migration-mean pool (`:1318`).
  - **How it fails:** take a statistic whose covered departure pool is empty while the migration mean's holds 5 or more gauges. The likely case is spawning or migration `min7` in a dry box, where `wsel()` drops min7 ≤ 0 and `dep_pool_of()` then needs 10 positive baseline years. That pool, less the target, is empty, so `wet_departure_carry()` stops with "`x` has no donor rows". The verdict has already been printed.
  - **Why it matters:** the whole run aborts and no report or rds is written for sections 1-5 either. Section 4's distance route survives, because it draws on the uncovered gauges too.
  - **Fix:** check each combo's covered pool before carrying it, and print "-" or "no covered donor" for that row.
  - **Rule:** code-check.md "A guard that fails toward pass" (its mirror, toward abort), and "Zero-length, empty, and unset are three different things".
- **[severity: fragile]** `scripts/departure_site.R:1346`: at a site where PCIC covers no pool gauge, or the covered migration-mean pool is empty, `cov_runs[[1]]$held` has 0 rows. `paste0("  ", vapply(split(integer(0), …), …, ""))` then yields one phantom `"  "` line under "Per gauge, migration mean". This is cosmetic; it decides nothing. It is the zero-length paste the brief asked about. A `if (nrow(...)) … else "  none"` guard, as section 3 uses for its short-record block, closes it.
  - **Rule:** code-check-r.md "`paste()` with a zero-length argument returns length ONE, not zero".
- **[severity: fragile]** `scripts/departure_site.R:1337`: `stats::median(h$km_distance)` and `stats::median(h$km_covariance_pick)` have no `na.rm`.
  - Every `cov_na()` row has `km_* = NA`: a gauge with no donor left, which is most likely in the leak-free row. A single such row makes the column print "-" for the whole setting, while the quartiles beside it use `na.rm = TRUE`.
  - The median also covers gauges not scored (n < 3) whose km is computed. So "the median over gauges" is over a set other than the scored `n` printed on the same row.
  - This is a report value only. Use `med_na()` over the scored gauges.
  - **Rule:** code-check.md "Zero-length, empty, and unset are three different things".
- **[severity: fragile]** `scripts/departure_site.R:1341-1344`: since round 2, `s3` is restricted to the gauges section 6 scored. But it prints `sum(!is.na(s3$nse))`.
  - Section 3 scores a gauge on the years its distance route over the whole pool has. Its 5 nearest donors can differ from the covered pool's 5 nearest, and so can their years.
  - So a gauge can have fewer than 3 years in section 3 and at least 3 in section 6. The line then says "at the same %d gauges" with a count below the migration-mean row's `n`, and its median covers fewer gauges than it claims.
  - It is rare and decides nothing. Taking the median over `!is.na(s3$nse)` and printing both counts when they differ would make the sentence true.
  - **Rule:** code-check.md "One fact derived twice".

Nothing else found. In particular:

- The `fit_series()` refactor is byte-identical in `series` and `fits`, verified by execution.
- #121's and #120's report lines are untouched: every new line comes after section 5, or after the snow report's per-year table, and before the parity gate.
- The #135 cache (`wet_pcic_years`, `routed_years_dir`, the two callers) shows nothing new beyond round 2.
