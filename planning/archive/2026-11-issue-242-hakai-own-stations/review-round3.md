# Code-check round 3 (#233, #242): the guards, tested by restoring their defects

## Checklist read

- code-check.md (read by heading): the prose of all 14 H3s under `## Mechanisms`, table rows skipped (in particular "Restore the bug and prove the guard fires" and "A fixture that cannot reach the failure mode"). Not read: the 24 H3s under "Rules that stand alone", "Security" and "Spreadsheets and PDFs". None of them names a tool or shape this diff uses.
- code-check-r.md (read by heading), 13 read: "Tests that silently do not run"; "testthat counts an uncaught error under `error`, not `failed`"; "`$` on a list partial-matches..."; "`nzchar(NA)` is TRUE..."; "Under `R CMD check`, tests run from a temp dir against the INSTALLED package"; "CSV whitespace..."; "`match()` treats NA as a matchable VALUE..."; "`expect_message(expr, regexp)` checks only the FIRST condition..."; "`data.frame()` recycles a scalar against a zero-length column"; "`c()` dispatches on its first argument..."; "`read.delim()` quotes by default..."; "A `function(...)` mock hides arguments..."; "`ifelse()` with an all-NA test...". 119 not read.
- code-check-shell.md (read by heading): 0 of 75 read. The diff changes no shell code.
- code-check-spatial.md (read by heading): 0 of 98 read. The diff's spatial code (the regulation script's snap) is unchanged apart from the population it is given.

## Method

I worked in a detached scratch worktree at 51db296d, now removed. For each mutation I made one exact-string edit and asserted it matched exactly once and then landed. I ran `test-wet_station_daily.R` and/or `test-wet_station_list.R` under `NOT_CRAN=true` with `load_all()`, counted `failed > 0 | error` per test, then restored the file with `git checkout`. Baseline: 51 + 11 tests, 0 red, 0 skipped (the live tests ran against this machine's wet cache).

| mutation | red tests (the ones that catch it) |
|---|---|
| M1 `wet_hakai_hours()` keeps the "NA" hour | own-station test (7 failed) |
| M2 hours accept any non-finite Qrate ("abc", "Inf") | own-station test (2 failed: abc and Inf, each on its own) |
| M2b any non-number counts as "no value" | own-station test (1: "abc") |
| M2c "NA" is not special (refused) | own-station test; live own-watersheds test |
| M3 `wet_hakai_stations()` drops the cut-without-continues check | registry-of-its-own test |
| M3b the old guard is back (refuses rows that continue nothing) | 8 daily + 5 list tests |
| M9 `wet_hakai_stations()` drops the duplicate check | registry-of-its-own test |
| M5 `wet_hakai_station_days()` ignores own stations | own-station test; live own-watersheds test |
| M5b own stations returned whether or not they were asked | "a provincial number no Tool gauge continues..." (unit); live 626 test |
| M14 returns empty when only own stations are asked | own-station test; live own-watersheds test |
| M4 hakai entries dropped from `wet_station_regulation()`'s hold | status-file refusal test (2 failed) |
| M4b hakai md5 alone dropped | status-file refusal test (1) |
| M4c hakai version alone dropped | status-file refusal test (1) |
| M10 hold hashes the manifest, not the registry | 8 list tests |
| M6 `wet_station_list()` omits own rows | 3 list tests; live own-watersheds test |
| M7 own rows' regulation read under source "bcenv" | 6 list + 4 daily tests |
| M7b own rows' regulation matched by number, no source check | own-listing test (the `wrong_source` assertion) |
| M8 own rows' `last` taken from `first` | own-listing test; live own-watersheds test |
| M12 own rows' licence NA | own-listing test |
| M15 zero-row guard: `&& any(is.na(hakai$continues))` dropped | **none (51 + 11 green)** |

Every guard the brief named turns at least one test red, and each new assertion I checked can fail on its own (M2/M2b, M4b/M4c). I found no assertion that holds whatever the code does.

## Findings

- **[severity: fragile]** R/wet_station_list.R:104. No test catches removing the zero-row guard `&& any(is.na(hakai$continues))` on the new Hakai own-rows block: with it removed, both files stay green (M15).
  - The guard is not decoration. Under a registry that holds only continuing rows, `wet_station_list("hakai")` returns 0 rows with the guard in place. Without it, the call raises `arguments imply differing number of rows: 0, 1`, because `data.frame()` cannot recycle the scalar `source = "hakai"` onto zero rows. I measured both against a mocked continuing-only registry.
  - The shipped registry (8318556d2baf) has four own rows, so no shipped path reaches the defect today; nothing would notice if a later edit dropped the guard.
  - No unit test reaches the branch. "a Hakai registry built on other provincial days is refused" uses a continuing-only registry, but `wet_registry_against()` errors before the block runs. The no-complete-day list test was narrowed to `c("bcenv", "bcwatertool")` in this branch, so it no longer opens Hakai at all.
  - Round 1 fixed the same zero-row shape in the regulation script.
  - **Rule:** code-check.md "Restore the bug and prove the guard fires" ; code-check-r.md "`data.frame()` recycles a scalar against a zero-length column"

No other issues.

index, diff and changed files read from file
