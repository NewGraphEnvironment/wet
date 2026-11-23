# Code-check enumeration: #179, after round 3

Round 3 found a defect inside round 2's fix (the registry check shared tier (i)'s verdict), so by the stopping rule only an enumeration ends the loop.

**Mechanism** (round 3's naming): a stand-in taken as equal to the thing it stands for, made earlier, elsewhere or by the check itself, with no check able to disagree.

**Candidate set:** every value on this branch that is recorded or derived once and read later in place of its source. 17 places. Each row names the source of truth, the guard, and the measurement that the guard fires.

| # | Stand-in | Source of truth | Guard | Shown to fire |
|---|---|---|---|---|
| 1 | Stored days parquet | the snapshot's files + the build code | key = manifest md5 + `wet_bcenv_reader` (`wet_bcenv_days()`) | test "keyed by the manifest and reader version": another manifest is another file. Build code relies on the manual reader version (accepted) |
| 2 | Cached snapshot files | tracked manifest | size + md5 on every build (`wet_bcenv_check()`) | test: a byte changed, and a size changed, each refused |
| 3 | Tracked manifest (20261028) | the survey report's md5s | data-raw step 1 stops on mismatch | ran 2026-11-22: 8 files matched; a mismatch is a `stop()` |
| 4 | S3 backup | the cached files | one PUT per file with Content-MD5 (S3 refuses other bytes), then ETag == md5 and size | ran 2026-11-22 after round 2: all 8 passed. The `.md5` sidecars are informational, not read back (accepted) |
| 5 | Registry `first`/`last` | `wet_bcenv_daily()` now | harvest: per station, fails on a difference | one date shifted: harvest exit 1, "station registry" |
| 6 | Registry station set | stations the reader returns | harvest: a station read but not in the registry fails | one row removed: exit 1, "lacks: 1 (07FC0002)" |
| 7 | Registry name, lon, lat | the survey's station rows | tier (i) station rows, compared with the tracked survey report | the removed-row run also failed "station rows" |
| 8 | Registry `hydat_site`, `hydat_km` | the survey's HYDAT match, which tier (i) verifies through `scripts/station_sources_lib.R` | harvest: per station against tier (i)'s match | one site changed: exit 1, "1 (08EE0001)" |
| 9 | `wet_bcenv_bound` constant | the bound measurement | bound script: `identical()` to its printed line, and that line to the measurement; a test holds the constant to the report line | before the constant was set the script stopped ("not the measured bound") |
| 10 | Each day's cap | one definition | `wet_bcenv_cap()`, used by both the reader and the bound script | both reports unchanged after the refactor (208 days dropped) |
| 11 | Reader UTC days | the probe's own query | tier (i): station-days identical, flows within 1e-12 | run: 215,300 against 215,300 |
| 12 | Expected row count | the file's rows | newline bytes plus a last line without one, against duckdb's count | tests: a blank line refused; a file without a final newline read whole |
| 13 | Fixture days | the rules they test | mutation per rule | 11 mutations (10 at Phase 2, UTC-7 after round 2), each turned at least one test red |
| 14 | Harvest "moved" list | each station's own values | `differs()` element by element, NA-safe; station order asserted | the per-station rerun in round 3 gave the same one station (08NM0005) |
| 15 | Harvest verdicts | each check's own result | tier (i) `fail` and the registry's `reg_fail` kept apart, each with its own verdict line; exit 1 on either | the removed-row run printed both verdicts separately |
| 16 | Survey rows parsed from the tracked report | the survey report | counts compared (211 and 211) and the network line compared whole | a missing line changes the count (round 2's probe) |
| 17 | Report `code_md5` lines | the code that made the report | hash of the script only; the reader's build is keyed by `wet_bcenv_reader` (row 1) | accepted, as row 1 |

Nothing in the set sits above its source of truth unguarded except the two accepted rows (1's build code and 17), which both rest on the documented manual reader version.
