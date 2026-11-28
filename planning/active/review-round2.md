# Code-check round 2 (#242, #233)

## Checklist read

- code-check.md: read the prose (table rows skipped) of the `## Mechanisms` H3s from "A guard that fails toward pass" through the opening of "One fact derived twice": A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice (opening only). Not read: the 24 standalone and security headings.
- code-check-r.md: read `match()` treats NA as a matchable VALUE; `data.frame()` recycles a scalar against a zero-length column; `paste()` with a zero-length argument returns length ONE; `ifelse()` with an all-NA test returns a logical vector; `system2(stdout = TRUE)` warns on a non-zero exit; A `function(...)` mock hides arguments; Read-back shape must match write-back shape; `$` on a list partial-matches. 124 headings not read.
- code-check-shell.md: none read (the diff has no shell code; its one `system2("git", ..., stdout = <file>)` falls under code-check.md's "A wrapper's exit is not the work"). 75 headings not read.
- code-check-spatial.md: none read (the only spatial step, `albers()` in data-raw, is unchanged). 98 headings not read.

## What was checked beyond round 1

- Every caller of the changed functions, found by grep across R/, scripts/, data-raw/, vignettes/ and tests/:
  - `wet_hakai_stations`: R/wet_hakai.R (`wet_hakai_daily`, `wet_hakai_station_days`), R/wet_station_list.R, R/wet_station_daily.R (`wet_bcwatertool_station_days`, which uses it only for `wet_registry_check`, and that check already handles NA `continues` with `na.omit`), scripts/station_regulation.R, scripts/station_sources_hakai.R. None of them now assumes every row continues a provincial station: `wet_continuing()` and `wet_continue_list()` filter on `!is.na(continues)`; `wet_continue_days()` passes rows with other numbers through unchanged; the Hakai report uses `na.omit` and `is.na(cut)`.
  - In the report's registry loop, an own station's `continues_before` compares as `format(as.Date(NA))` (from `pstart[NA_character_]`) against `format(as.Date(NA))`. `identical()` is TRUE, so the run passes, as the tracked report says.
  - `wet_station_list` has one outside caller, scripts/departure_donors.R. It keeps `regulation == "natural"`, and all four Hakai stations are `unknown`, so its population does not move (its cache key changes with the R code, as documented).
  - `wet_station_regulation`: its only caller is `wet_station_list`. The shipped regulation_20261028.csv carries `hakai_version` 8318556d2baf and `hakai_registry_md5` 7e1edece…, and that is the md5 of the shipped hakai_8318556d2baf_hydat.csv (both other md5s match too). It has 261 rows, the four WTS rows under source `hakai`.
  - The test-file copy of the status (`local_status()`) copies the Hakai registry and manifest, so `read_with(r)` still passes.
- `rule_commit` 82aa3f24 is an ancestor of HEAD, and both rule files are byte-identical between it and HEAD. `prior_commit` a08f3207 is the branch's first-parent point. The status file and report are unchanged between it and the merge-base 49afd870. The prior report holds exactly one "catalog digest" line, so `prior_digest` is a scalar.
- `wet_hakai_hours`: only the literal string "NA" is treated as no value. "abc", "Inf", "NaN" and "" are still refused (the file is read with `na.strings = character()`).
- Zero-length cases: `wet_station_list` builds the Hakai frame only under `any(is.na(hakai$continues))`. The regulation population uses `rep()` for its scalars, and the `against` lines are built by `sprintf` over vectors that may be empty.
- The prose claims in NEWS, CLAUDE.md and research (261 stations, 76 unknown with 53 not placed, 0 statuses moved, 1,885–2,203 days, 85.2–97.6 % approved, 5–6 window-years) match the tracked reports at HEAD.

## Clean
No issues found.

index, diff and changed files read from file
