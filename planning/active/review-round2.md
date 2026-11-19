# Code-check round 2: #135 cache and #147 section 6

## Checklist read

- **code-check.md:** I read the prose of all 14 H3s under `## Mechanisms`, skipping table rows and evidence blocks. 22 other headings I read through the index only.
- **code-check-r.md:** I read these sections in full:
  - A database driver's value is not a base R type — and it fails twice
  - `$` on a list partial-matches, so a longer sibling key answers for a missing one
  - Under `R CMD check`, tests run from a temp dir against the INSTALLED package
  - `c()` dispatches on its first argument, so `c(NULL, <Date>)` is a plain number

  I also checked against their index lines: `on.exit()` at top level, `tempfile()` in the session tempdir, A fetcher's test helper, A `skip_if_not()` skips only its own block, Postgres row order, `paste()` zero-length, `bind_rows()` all-NULL, `tolerance` relative, and `sprintf("%g")` in SQL. About 120 headings not read.
- **code-check-shell.md:** none read in full, because the diff has no shell code. 72 headings not read.
- **code-check-spatial.md:** `terra::project()` given only a CRS (index line only). `xy_km` is a report column rounded to whole km, so it is not a finding. About 93 headings not read.

## Findings

- **[severity: fragile]** `scripts/departure_site.R:367-397` and `:1286-1293`: section 6 stops the whole run, sections 1-5 included, at a site where PCIC covers little or nothing. The rule cannot then return its "distance ships" verdict.
  - **No gauge accepted:** `cov_seg` is empty. `routed_weights(conn, integer(0))` fails `stopifnot(length(lfid) > 0)`.
  - **Gauges accepted but no `pcic.segment_weights` row** (a box on the Liard, Yukon, Hay or Skagit, which PCIC does not cover): `cov_w` has 0 rows. `cov_subs` is `integer(0)`, and `routed_years_check()` fails `stopifnot(length(subs) > 0)`.
  - **A covered pool of 1 for any scored statistic, or a leak-free gauge related to every other covered pool gauge:** `cov_carry()` hands `wet_departure_carry()` no donor rows. It stops with "`x` has no donor rows", and no report is written.
  - **Why it matters:** the covered pool is a subset of section 3's pool, so this is likelier than in section 3, and a small nested box can hit the leak-free case. The four current sites are all in covered basins, and 3 of them are in the Skeena. But a new row in `scripts/departure_sites.csv` outside PCIC's coverage would now abort sections 1-5 as well. Its verdict should read "distance ships; the target is not covered" / "under 10 gauges scored".
  - **Rule:** code-check.md "A guard that fails toward pass", in its mirror form: a guard that fails toward abort where a partial result is expected.

- **[severity: fragile]** `scripts/departure_site.R:1318-1321`: the line "Section 3's distance … at the same %d gauges" may compare a different set of gauges than section 6 scored.
  - `s3` is section 3's rows for every gauge in the covered migration-mean pool, scored or not. It counts and takes the median over those whose section-3 NSE is non-NA.
  - Section 6 scores a gauge only where both carried series share at least 3 observed years. Section 3 needs only distance-over-the-whole-pool's years. So a gauge can be NA in section 6 and scored in section 3.
  - The printed count can then differ from the "migration mean" row's `n`, and the median covers a different set, while the sentence says "the same".
  - It decides nothing, but the sentence is a claim the code does not hold. Restricting `s3` to `!is.na(cov_runs[["migration mean"]]$held$distance)` would make it true.
  - **Rule:** none

## Checked and clean

- **Round 1's integer64 fix (lines 371-385):**
  - `as.numeric()` on the mouth's `integer64` dispatches `bit64`'s `as.double.integer64`, which is registered because RPostgres loads bit64. It happens before the `rbind()`.
  - `sn_all$linear_feature_id` is already double (`::double precision` in `wet_station_snap()`).
  - `as.integer()` then gives NA, never a wrong value, past int32, and the `stopifnot(!anyNA, > 0)` catches that. FWA's largest id fits int32.
  - The ungauged identity assertion compares the right quantities.
- **Other driver values in the diff:**
  - `routed_years_dir()` reads `bytes::text`, then `as.numeric()`. `year` goes through `as.integer()`, which also works on integer64.
  - `routed_weights()` casts `linear_feature_id::int` and dedups the ids it is given, so the `merge()` with `cov_seg` joins int to int.
  - The `subid`/`upstream_subids` handling is the pattern `departure_pcic.R` and `gauge_monthly_compare.R` already run.
  - `cov_check$commit` and `catalogue_md5` are character. `cov_par$subbasins` is `length()`, an integer, so `%d` is safe. `worst` goes through `fmt()`.
  - No `sprintf()` formats a driver numeric.
- **Held-out comparison:** both weightings are scored at each gauge on `Reduce(intersect, obs, distance, covariance_pick)` years, against the same centred observed series. The NA pattern is asserted identical across the two weightings. Both draw donors from the same covered pool less the gauge, and the leak-free run drops `related[[g]]` from that pool.
- **`modelled` contract:**
  - It holds the held-out gauge and every donor, because the donors are a subset of `covered`.
  - Its keys are unique, because `cov_seg`'s station numbers are unique.
  - The ungauged target is in it.
  - `known` covers the 15 nearest, since every candidate is covered.
- **Residual pool:** it holds covariance_pick's centred LOO residuals over its own years, at least 3 per gauge, pooled across the gauges of that statistic's non-leak-free run. This mirrors section 3's `carry_score()`. `max` gets no residuals, so its interval is NA, as in section 5.
- **Loop state:**
  - None of section 6's new names (`mod`, `covered`, `xy_km`, `verdict`, `cov_*`, `s3`, `cws`, `is_set`, `qd`, `qc`) is read in sections 1-5.
  - The shared loop variables (`a`, `m`, `v`, `p`, `nm`, `boot`, `cr`, `days`, `j`) are reassigned before each use.
  - In a second window set, `related`, `stations`, `stations_t`, `xy_km`, `mod` (from that set's `windows`), `normal`, `verdict` and `cov_mx` are all rebuilt. `cov_days` and `cov_seg` hold no window-set state, and every seed is reset.
- **Rule helper against the header:**
  - The gain must be at least 0.01 − 1e-9 in both pools.
  - At least 10 gauges must be scored in each pool.
  - The target must be covered.
  - The target's covered migration-mean pool less itself must hold at least 5 gauges.
  - A median that is NA keeps distance.

  All five match the registered text. The tests hit each branch.
- **`wet_pcic_years()`:**
  - The years and bytes passed in stay paired, because `routed_years_dir()` passes `b$year` with `b$bytes`.
  - A wrong-size cached file refuses before any download.
  - A partial file is renamed atomically in the same directory, or unlinked.
  - `WET_PCIC_YEARS` is returned unwritten. `curl` is in Imports.
- **Tests:** `test-departure_site_rule.R` skips under `R CMD check`, where `scripts/` is absent, via a `skip_if_not()` inside each block's call. `test-wet_pcic_years.R` stubs the download to fail by default.
