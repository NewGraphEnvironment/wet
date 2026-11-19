# Code-check round 1: #135 cache and #147 section 6

## Checklist read

- **code-check.md:** all 14 H3s under `## Mechanisms`, prose only, with the table rows and evidence blocks skipped: A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice. I also read Test the cold/create path of idempotent code, not just the warm no-op, and Percent-encode a URL at construction, not at consumption. 22 headings not read.
- **code-check-r.md:**
  - A URL handed to a reader goes through R's 60 s connection timeout
  - `on.exit()` at a script's top level never fires
  - A database driver's value is not a base R type — and it fails twice
  - `tempfile()` lives in the session tempdir, so a path printed in an error names a file R is about to delete
  - A fetcher's test helper must make the network fail, not just mock the reader
  - `c()` dispatches on its first argument, so `c(NULL, <Date>)` is a plain number
  - A `function(...)` mock hides arguments the real callee no longer accepts
  - Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it

  The rest I read through the index only. 114 headings not read.
- **code-check-shell.md:** `curl -o` without `-L` saves the redirect page as the download. 71 headings not read: the diff has no shell code. The download goes through R's curl package, whose `curl_download()` writes to `<dest>.curltmp` and renames it.
- **code-check-spatial.md:** `terra::project()` given only a CRS lets GDAL and PROJ choose the grid and the datum step, and their choices move between versions. It is relevant to `xy_km`, but that is only a report column rounded to whole km, so it is not a finding. 93 headings not read.

## Findings

- **[severity: bug]** `scripts/departure_site.R:373`: an ungauged site's mouth is never covered, so section 6 always reports "NOT covered" for gosnell and ships distance.
  - **What happens:** `cov_seg` comes from `sn_all`, where `linear_feature_id` is a plain double: `wet_station_snap()` casts it `::double precision`. The mouth row's `mouth$segment$linear_feature_id` comes from the earlier `SELECT linear_feature_id ... FROM whse_basemapping.fwa_stream_networks_sp`, and RPostgres returns that bigint as `bit64::integer64`. `rbind(<double column>, data.frame(linear_feature_id = <integer64>))` copies the integer64's raw bits into the double column.
  - **Measured on this machine:** `rbind(data.frame(id = 7e8), data.frame(id = bit64::as.integer64(701234567)))$id` gives `7.0e8 3.46e-315`, and `as.integer()` of that is `0`. The live fwapg column comes back with class `integer64`.
  - **Consequence:** the next line's `as.integer()` makes the mouth's id `0`. `routed_weights()` finds no row for it, and line 377 drops the mouth from `cov_seg`. The target is then absent from `covered`, and `site_carry_ship()` returns "the target is not covered" for both of gosnell's window sets, whatever the scores say. Nothing errors, and the report shows a plausible "The target, gosnell: NOT covered".
  - **Fix:** cast before the rbind, `linear_feature_id = as.numeric(mouth$segment$linear_feature_id)` (or `as.integer`, which works on integer64 through bit64). Better, assert afterwards that the target is in `cov_seg` whenever the mouth has a `pcic.segment_weights` row. Extend sites are unaffected.
  - **Rule:** code-check-r.md "A database driver's value is not a base R type — and it fails twice"

## Checked and clean

- **Sections 1-5 unchanged:**
  - Section 6's code, `say()` calls and draws all come after section 5's last `say()` and before the parity gate.
  - The new pre-loop block consumes no R RNG. `tempfile()` and curl do not touch `.Random.seed`, and every draw in sections 1-5 is reseeded (120, 126, 152, 1520).
  - In gosnell's second window set nothing in sections 1-3 draws before `set.seed(120)`. The only `sample()` in R/ is in `wet_station_snap()`, before the loop.
  - `source("scripts/pcic_routed_lib.R")` defines only `routed_*` and `shipped_heldout`, and none of these collides with a name in the script.
- **No collision with any "exactly one line" check:**
  - `site_parity_pilot()` compares by set. Its change-table header pattern needs `post +change`, and section 6's header has `post +carried`.
  - In `short_record_vignette_data.R` `one_line()`:
    - The `car` pattern is anchored to 6 tokens, and section 6's setting rows have 10.
    - The `ext` pattern needs `ols`.
    - The `two` pattern is anchored to 5 tokens.
    - The per-year header needs `^08EE018 per year`.
    - The change table is restricted to section 4.
  - `chinook_sites_data.R`'s `sec()` takes the first `^Per gauge, migration mean`, which is section 3's.
  - `test-departure_site_parity.R`'s `grep(...)[1]` lookups all hit sections 1-4 first, and only one line starts `^HEADLINE: `.
- **`wet_departure_carry()` contract:**
  - `modelled` holds rows for the held-out gauge or target and every candidate, because donors are a subset of `cov_pool`, which is a subset of `covered`.
  - It has no duplicate keys, because `cov_seg` has unique station numbers.
  - The target's row is in `stations_t` for the cov_mx call.
  - `stations` is the pool for held-out gauges.
  - `distance` passes `modelled = NULL`.
- **`is_set`** picks exactly one run per non-max combo, since leak-free carries a non-NULL `drop`. `related` cannot be NULL once `sn_all` is required.
- **`wet_pcic_years()`:**
  - The partial file is renamed atomically in the same directory.
  - It is unlinked on failure.
  - The stale-partial pattern also catches curl's `.curltmp`.
  - A wrong-size cached file is refused.
  - `WET_PCIC_YEARS` is returned unwritten.
  - The tests stub the downloader to fail by default.
