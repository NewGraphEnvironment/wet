# Review round 1, branch 179-backlog-move-8-stations-beyond-hydat (base eaa12d9d)

## Checklist read

- **code-check-r.md**: read these headings in full or for the parts that apply: "A `data-raw/` script must load the source tree, not the installed package"; "`on.exit()` at a script's top level never fires"; "Tests that silently do not run"; "Under `R CMD check`, tests run from a temp dir against the INSTALLED package"; "A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check` if `pkg` is undeclared"; "A `function(...)` mock hides arguments the real callee no longer accepts"; "A fetcher's test helper must make the network fail, not just mock the reader"; "`deparse()` re-encodes non-ASCII, so it answers about itself rather than the file"; "duckdb in R: the query that autoloads `icu` binds unreliably, so `LOAD icu` before it"; "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"; "Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it"; "`read.delim()` quotes by default, so a `"` in a field silently swallows rows"; "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires"; "Rscript reads a script as it runs, so never edit a script while a run of it is in flight"; "`R CMD build` ships every top-level directory not in `.Rbuildignore`"; "`ifelse()` with an all-NA test returns a logical vector, whatever `yes` and `no` are"; "`[[` on a named ATOMIC vector with an absent key is an error, not `NULL`"; "`identical()` on two reader results tests the reader, not the file"; "`tryCatch()` nests its handlers, so a `stop()` in one is caught by a later one". About 175 headings not read (out of area).
- **code-check-shell.md**: read "An S3 multipart ETag depends on the uploader's part size, so try every size that gives its part count" and "`aws s3 cp` cannot tell a missing key from a missing bucket" (the backup step in data-raw). About 110 not read.
- **code-check-spatial.md**: read "A relation between FWA watershed codes is not a place" only as far as needed to rule it out (the HYDAT match is a name-and-distance rule, copied verbatim from the probe). About 120 not read.
- **code-check.md**: read the prose of all fourteen H3s under `## Mechanisms`; of the rest, "Documentation Staleness". About 30 not read.

## Findings

- **[severity: bug]** R/wet_station_list.R:44 — the `credit` string literal holds a raw en dash (U+2013, "Licence – British Columbia"). `tools:::.check_package_ASCII_code(".", FALSE)`, the check `R CMD check` runs, now returns `R/wet_station_list.R`; at base eaa12d9d it returns `character(0)`. So `R CMD check` gives the WARNING "Found the following file with non-ASCII characters". The repo's R-CMD-check workflow calls `NewGraphEnvironment/flows` r-cmd-check.yaml@v1, whose `error-on` defaults to `'"warning"'`, so the PR's R-CMD-check job will fail. `devtools::test()` does not run this check, which is why the 476 passing tests do not show it. Fix: write the dash as `–` in the literal, or use a plain hyphen. `tests/testthat/test-wet_station_list.R:11` matches the literal en dash with `fixed = TRUE`. It still passes with `–`, because the value is the same; with a hyphen the test must change too.
  - **Rule:** code-check-r.md "`deparse()` re-encodes non-ASCII, so it answers about itself rather than the file"

Nothing else rose to a real defect. What I checked and found sound:
- Local-standard-time offsets for every registry id shape (`1AHA040`, `H08KC0626`, `07FC0001`, `10CD0001`).
- Sub-drainage lookup in `wet_bcenv_ratio()`.
- Median and cap when a station has no positive day: the cap is NA and the day is kept, as the research says.
- Newest-file dedup order. NaN, empty and Unusable handling, which matches the probe's semantics.
- All timestamps on the hour. I probed the cached snapshot: 6,022,264 rows, all `:00:00`, max 24 hours a day.
- No NULL grades in the snapshot, so the `grade <> 'Unusable'` filter drops nothing silently.
- Row-count guard and the non-numeric-value guard.
- Atomic partial-then-rename for the parquet cache.
- Routing of the federal and provincial numbers in `wet_station_daily()`: no registry id matches `wet_hydat_number`.
- `frac_provisional` callers: no producer writes an NA status.
- The bound script's constant check.
- The copy of the probe's HYDAT match is verbatim.
- Mocks: the formals match the real functions, `.env` frames are correct, and curl is made to fail.
- The aws backup checks `system2`'s exit status.
