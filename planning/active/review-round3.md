# Code-check round 3 (#46): diff b4c9da2...HEAD (b1d9058)

## Clean

No issues found.

## Mechanism behind round 1's defect

The code treated a value from a database driver as the base R type its SQL meaning suggests: a
page count and page size read as "numbers", when RSQLite returns them as R `integer` (32-bit), so
their product overflowed to NA past 2 GiB. The same mechanism covers any DBI or tidyhydat value that
is then multiplied, compared, formatted or matched without its actual class being checked.

## Every place in the diff the mechanism reaches, checked

Classes were measured read-only on the real cache file, 20260717, with RSQLite 3.53.3 and
tidyhydat 1.0.1.

- `wet_hydat_check()`, `PRAGMA page_count` and `page_size`: RSQLite returns `int` (1266498 and
  1024). Both are now `as.numeric()` before the product. `file.size()` is a double, so `==` is
  exact up to 2^53. An `integer64` result (RSQLite's bigint path) would also coerce correctly,
  through bit64's `as.double` method. A zero-row result gives `logical(0)`, which `isTRUE()` turns
  into a refusal.
- `wet_hydat_check()`, `PRAGMA quick_check`: returns `chr` "ok", so `identical(qc, "ok")` is sound.
- `wet_hydat_release()` (pre-existing, but every new path reads through it): VERSION.Date is
  declared `DATETIME` and stored as `text` ("2026-07-17 08:08:08.000"). With wet_hydat_connect's
  default `extended_types = FALSE`, RSQLite returns `chr`. `substr(as.character(.), 1, 10)` would
  also handle a POSIXct. A REAL-stored date fails closed, with an error, not a wrong release. Empty
  or multi-row VERSION tables are refused.
- `identical(got, release)` and `identical(current, release)`: both sides are plain unattributed
  character. `format()` output, `Sys.getenv()` for a length-1 name and `hy_remote()`'s `substr()`
  all return plain character.
- `tidyhydat::hy_remote()`: returns `substr(gsub(...), 1, 8)`. If the page changes, that is
  8 non-digit characters, which the `^[0-9]{8}$` check turns into an unclassed error, as intended.
  `download_hydat()` calls `hy_remote()` again internally, and a release that moved in between is
  caught by the VERSION check on the partial download.
- The data-raw scripts and `station_departure.R` now take the date from
  `as.Date(wet_hydat_release(), "%Y%m%d")`. It formats to the same "2026-07-17" that the old
  `as.Date(VERSION$Date[1])` gave, so `prov$hydat` in station-flow.Rmd is unchanged.
- `mad_basin.R`: `hy_stations()` and `hy_daily_flows()` take `hydat_path` in tidyhydat 1.0.1. The
  new `%s` gets a character release, `%d` an integer `sum()`, and `%.0f` the double
  `DRAINAGE_AREA_GROSS`. `snap$linear_feature_id` (RPostgres bigint) is pre-existing and unchanged.

## Rest of the diff

- The fetch path:
  - The `tempfile()` partial sits under the same root, so the rename is atomic and on one
    filesystem.
  - A rename onto an existing empty target directory succeeds on POSIX. Onto a non-empty one it
    fails, and the existing copy is then used.
  - `on.exit(unlink(partial))` is a no-op after a successful rename.
  - The stale sweep has a race where a directory vanishes between `list.files()` and
    `file.mtime()`. That gives an NA index, and `unlink(NA_character_)` deletes nothing (probed).
- `wet_hydat_check()`: an `on.exit` inside the `tryCatch` expression attaches to the function's own
  frame (the promise evaluates in it), so the connection closes on every exit path.
- `tryCatch` handler nesting: each `tryCatch` has a single handler, so no handler's `stop()` is
  re-caught.
- The `skip()` inside the classed handler in `local_hydat_pinned()` propagates to `test_that`.
- Both live callers of `local_hydat_pinned()` skip on CI before reaching it: the Buck Creek test
  through `skip_on_ci()`, the snap test through `local_fwapg()`.
- No `local_hydat_real` references remain. No script still reads `WET_HYDAT` or tidyhydat's
  directory, except `wet_hydat_path()`, whose interactive default was decided in the issue.
- `release` is validated as `^[0-9]{8}$` before any path is built, so no traversal is possible.
- `tests/testthat/test-wet_hydat.R` was run from a `git archive` copy with `NOT_CRAN=true`:
  12 tests, 0 failed, 0 errors.
- `wet_hydat_check()` on the real cached 20260717 file passes in 0.1 s. The cache was read only;
  its directory listing is unchanged.
