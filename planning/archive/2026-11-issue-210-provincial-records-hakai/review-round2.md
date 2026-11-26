# Code-check round 2 (branch 210-backlog-move-17-provincial-station-recor, HEAD d9460851)

## Checklist read

- code-check.md: all 14 `## Mechanisms` H3s, prose only (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice). The other 24 H3s were not read in full.
- code-check-r.md: read in full `stats::aggregate()` has three separate silent behaviours; `on.exit()` at a script's top level never fires; `tempfile()` lives in the session tempdir; `match()` treats NA as a matchable VALUE; `tryCatch()` nests its handlers; A fetcher's test helper must make the network fail; `system2(stdout = TRUE)` warns on a non-zero exit. The other 125 were read as index lines only.
- code-check-shell.md: index lines only. No section read in full, since the diff adds no shell code. 75 not read.
- code-check-spatial.md: index lines only. The one spatial step, the albers distance in data-raw, matches no heading. 98 not read.

## Probes run (read-only; tests and the Hakai report in a detached scratch worktree, since removed)

- `test-wet_station_daily.R` (48 tests) and `test-wet_station_list.R` (11 tests), with `NOT_CRAN=true`: 0 failed, 0 errors.
- `scripts/station_sources_hakai.R`, rerun from cache in the scratch worktree: the tracked report reproduced byte for byte (`git status` clean).
- Hakai days on the pinned file: no negative day. The only days dropped as incomplete are 1, 2 and 1 short days, so the report's "no day negative" holds. Labels run from 2014-08-02 13:00 to 2019-10-01 00:00.
- `wet_hakai_days()` aggregation: the factor levels are `unique(key)`, so `tapply()` output and `!duplicated(g)` are both in first-appearance order. They stay aligned even when a key is not contiguous.
- Portal exports in the main checkout's `data/station_sources/raw/portal/20261125`: no duplicate timestamps in any of the 10 CSVs. The `n == 24` day rule therefore cannot be met by a doubled hour. No grade -2 rows; GAP rows are NaN at +1 s, off the hour. The only lettered provincial numbers are the three H08KC stations, so `startsWith()` in the drainage pick drops nothing eligible.
- The provincial hours' `t` is VARCHAR cast to a naive TIMESTAMP, so the portal hour join does not depend on the machine's time zone.
- Spot-checked against the tracked reports: the research and NEWS claims (99.9-100 % a month Oct 2021 to May 2026; Tool 38-83 % from 2022; 0.1-24 % for Jan-Sep 2021; 80-91 % from June 2026; 7 Chinook-window years instead of 2; 1,885/1,883/1,846 days; 93.4-98.5 % approved; the three stations `unknown` in `regulation_20261028.csv`). All match.

## Clean

No issues found.

index, diff and changed files read from file
