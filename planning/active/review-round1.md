# Code-check round 1 (#235)

## Checklist read

- code-check.md: the prose of every H3 under `## Mechanisms` skimmed (table rows skipped), with "A guard that fails toward pass", "A fixture that cannot reach the failure mode" and "Zero-length, empty, and unset are three different things" read in full; the stand-alone rules and security sections not read (not relevant to this diff).
- code-check-r.md, read by heading: "`deparse()` re-encodes non-ASCII, so it answers about itself rather than the file"; "A fetcher's test helper must make the network fail, not just mock the reader"; "A `function(...)` mock hides arguments the real callee no longer accepts"; "`ifelse()` with an all-NA test returns a logical vector, whatever `yes` and `no` are"; "as.POSIXct on character infers ONE format for the whole vector"; "`read.delim()` quotes by default, so a `"` in a field silently swallows rows"; "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires"; "Under `R CMD check`, tests run from a temp dir against the INSTALLED package". The other ~150 headings were not read.
- code-check-shell.md: no heading read (the diff has no shell beyond `system2("aws", ...)`, covered above).
- code-check-spatial.md: no heading read in full; the placement script reuses `scripts/station_regulation_*` snapping already reviewed under #196.

Index, diff and changed files read from file.

## Findings

- **[severity: bug]** R/wet_logger_daily.R:181 — the string literal `"wtmp (°C)"` puts a raw non-ASCII byte in R code (not a comment). `tools:::.check_package_ASCII_code(".", FALSE)` on the branch returns `"R/wet_logger_daily.R"`, and it is the only file it names (every other `°` and `–` in `R/` is in roxygen comments). `R CMD check` runs that predicate under "checking R files for non-ASCII characters" and reports a WARNING whatever `Encoding: UTF-8` says, and the shared R-CMD-check workflow (`NewGraphEnvironment/flows` `r-cmd-check.yaml@v1`) defaults `error-on: '"warning"'`, so the PR's R-CMD-check job fails. Write it `"wtmp (°C)"`; the comparison with the UTF-8-marked header that `read.csv(encoding = "UTF-8")` returns still holds. (The `°` in `tests/testthat/` and `data-raw/` is not checked.)
  - **Rule:** code-check-r.md "`deparse()` re-encodes non-ASCII, so it answers about itself rather than the file"

- **[severity: fragile]** R/wet_logger_daily.R:241-244 — when every hour of a site is in a stuck run, `hours <- hours[!stuck, ]` leaves zero rows, and `df <- c(TRUE, diff(hours$dd) != 0)` is then length 1, not 0, so `dg` is `1` against a zero-length `hours$v` and `order(dg, hours$v, method = "radix")` errors "argument lengths differ". Reproduced: `wet_logger_days(data.frame(time = as.POSIXct("2020-07-01 08:00", tz = "UTC") + (0:799) * 900, t = 8, flag = "P", pass = TRUE))` errors, where a site whose days are all dropped for other reasons returns zero rows of the shape. Through `wet_temp_daily()` (R/wet_temp_daily.R:149) the error is caught for the whole series, so one such file drops every requested site of that series with a "skipped" warning; through `wet_logger_daily()` and `scripts/temp_loggers.R` it stops the run. No Nechako file is stuck today (the report counts none), so this waits for a short or fully stuck file in a later version or series. Guard the empty case after the stuck removal (every day of `all_days` then goes to the `gone` rows, labelled "stuck").
  - **Rule:** code-check.md "Zero-length, empty, and unset are three different things"
