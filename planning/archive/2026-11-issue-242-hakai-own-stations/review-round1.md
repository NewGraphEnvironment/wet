# Code check, round 1 (#242 / #233 branch)

## Checklist read

- **code-check.md**: the prose of all 14 H3s under `## Mechanisms`, table rows skipped (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice). Also Documentation Staleness. Not read: the other 25 stand-alone, Security and Spreadsheets/PDF headings (no tool or shape they cover is in the diff).
- **code-check-r.md**, read for the shapes this diff uses: Read-back shape must match write-back shape; `nzchar(NA)` is TRUE; `match()` treats NA as a matchable VALUE; `data.frame()` recycles a scalar against a zero-length column; `paste()` with a zero-length argument returns length ONE; CSV whitespace: `trim_ws` and `strip.white`; `read.delim()` quotes by default; `ifelse()` with an all-NA test returns a logical vector; `sort()` and `order()` collate by `LC_COLLATE`; `system2(stdout = TRUE)` warns on a non-zero exit; A `function(...)` mock hides arguments the real callee no longer accepts; Tests that silently do not run; Under `R CMD check`, tests run from a temp dir against the INSTALLED package; A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check`; A `data-raw/` script must load the source tree (16). Not read: about 115 others.
- **code-check-shell.md**: none read (the diff holds no shell code; the one `system2("git", ...)` call is R and was checked under the R headings). Not read: about 80.
- **code-check-spatial.md**: none read (no spatial call is added; the regulation snap and placement code is unchanged). Not read: about 105.

## What was checked, beyond reading

- `wet_hakai_hours()`: a Qrate of `"NA"` is dropped only as that exact string; `"NaN"`, `"Inf"`, `""` and other text still refused. The file is read with `na.strings = character()`, so the `== "NA"` test sees the string, and the one such hour in the cached package (line 181006, WTS708 2013-09-08T16:00, SVC) is not also SVD, so the Hakai report's `svd` column (hours read minus hours kept minus NA hours) does not double-subtract it.
- `wet_hakai_station_days()` / `wet_continue_days()`: own numbers pass through `wet_continue_days()` unrenamed and uncut (`is.na(k)`); a continued watershed's own number (WTS626) still returns nothing, as before. No days cache sits in front of the reader, so the new NA rule cannot be masked by a cached build.
- `wet_station_list()`: own rows only where `continues` is NA; `wet_continue_list()` drops NA-`continues` rows before matching; the `regulation` lookup refuses an own station the status file holds under another source (tested).
- `wet_station_regulation()`: the regenerated `regulation_20261028.csv` at HEAD carries one `hakai_version` (8318556d2baf) and one `hakai_registry_md5` (7e1edece...), equal to `md5` of `hakai_8318556d2baf_hydat.csv` at HEAD; bcenv and Tool md5s also match; `why` is non-empty on all 261 rows, so the report's prior/now `!=` comparison never meets NA.
- `scripts/station_regulation.R`: `rule_commit` 82aa3f24 exists, and both rule files at that commit are byte-identical to HEAD (md5 0f52c2f8..., d9dad7b6...). `prior_commit` a08f3207 is an ancestor of origin/main, and the status file and report did not change between it and the merge base. The amendment-heading parser renders Amendment 4's wrapped heading whole in the tracked report.
- The registry CSV, the Hakai report and the regulation report agree with the reader and with each other on station counts, first/last days, window years and statuses. The NEWS, research and CLAUDE.md figures checked (5–6 window-years, 1,885–2,203 days, 85.2–97.6 % approved, 261 stations, 76 unknown, 53 not placed, 0 statuses moved, the WTS708 offset of about 4.9 km) hold against the tracked reports and the registry.
- Ran `tests/testthat/test-wet_station_list.R` and `test-wet_station_daily.R` under `NOT_CRAN=true` with `load_all()` in a detached scratch worktree at HEAD: 11 and 51 tests, 0 failed, 0 errors, 0 skipped (the live Hakai tests ran). The worktree was removed afterwards.

Considered and not flagged: `scripts/station_regulation.R`'s Hakai `data.frame()` block passes scalar `id`/`hydat_site` and would fail on a registry with no own rows (`code-check-r.md` "`data.frame()` recycles a scalar against a zero-length column"), but the pinned registry holds four and any new pin reruns the script, so no run can reach it.

## Clean
No issues found.

index, diff and changed files read from file
