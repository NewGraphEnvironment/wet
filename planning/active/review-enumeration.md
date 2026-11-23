# Code-check enumeration: #179, after rounds 3, 4 and 5

Round 3 found a defect inside round 2's fix (the registry check shared tier (i)'s verdict), so by the stopping rule only an enumeration ends the loop.

**Mechanism** (round 3's naming): a stand-in taken as equal to the thing it stands for, made earlier, elsewhere or by the check itself, with no check able to disagree.

**Candidate set:** every value on this branch that is recorded or derived once and read later in place of its source. 25 places: round 3's 17, four round 4's audit found missing (rows 18–21), and four round 5's found (rows 22–25); rows 6, 10, 16 and 19 were corrected after them. Each row names the source of truth, the guard, and the measurement that the guard fires.

| # | Stand-in | Source of truth | Guard | Shown to fire |
|---|---|---|---|---|
| 1 | Stored days parquet | the snapshot's files + the build code | key = manifest md5 + `wet_bcenv_reader` (`wet_bcenv_days()`) | test "keyed by the manifest and reader version": another manifest is another file. Build code relies on the manual reader version (accepted) |
| 2 | Cached snapshot files | tracked manifest | size + md5 on every build (`wet_bcenv_check()`) | test: a byte changed, and a size changed, each refused |
| 3 | Tracked manifest (20261028) | the survey report's md5s | data-raw step 1 stops on mismatch | ran 2026-11-22: 8 files matched; a mismatch is a `stop()` |
| 4 | S3 backup | the cached files | one PUT per file with Content-MD5 (S3 refuses other bytes), then ETag == md5 and size | ran 2026-11-22 after round 2: all 8 passed. The `.md5` sidecars are informational, not read back (accepted) |
| 5 | Registry `first`/`last` | `wet_bcenv_daily()` now | harvest: per station, fails on a difference | one date shifted: harvest exit 1, "station registry" |
| 6 | Registry station set | every station with a usable hour, complete day or not | harvest: a station the stored days hold but the registry lacks fails the registry verdict (round 4: it had covered only stations with a complete day) | a station with complete days removed: exit 1, "lacks: 1 (07FC0002)"; one with hours but no complete day removed (round 5): exit 1, "lacks: 1 (08NK0001)" |
| 7 | Registry name, lon, lat | the survey's station rows | tier (i) station rows, compared with the tracked survey report | the removed-row run also failed "station rows" |
| 8 | Registry `hydat_site`, `hydat_km` | the survey's HYDAT match, which tier (i) verifies through `scripts/station_sources_lib.R` | harvest: per station against tier (i)'s match | one site changed: exit 1, "1 (08EE0001)" |
| 9 | `wet_bcenv_bound` constant | the bound measurement | bound script: `identical()` to its printed line, and that line to the measurement; a test holds the constant to the report line | before the constant was set the script stopped ("not the measured bound") |
| 10 | Each day's cap, and the median the bound report prints | one definition | `wet_bcenv_cap()`, used by the reader and the bound script; the report's median is read back as cap / ratio (round 4: it had been computed a second time) | both reports unchanged after each refactor (208 days dropped, the same medians) |
| 11 | Reader UTC days | the probe's own query | tier (i): station-days identical, flows within 1e-12 | run: 215,300 against 215,300 |
| 12 | Expected row count | the file's rows | newline bytes plus a last line without one, against duckdb's count | tests: a blank line refused; a file without a final newline read whole |
| 13 | Fixture days | the rules they test | mutation per rule | 11 mutations (10 at Phase 2, UTC-7 after round 2), each turned at least one test red |
| 14 | Harvest "moved" list | each station's own values | `differs()` element by element, NA-safe; station order asserted | the per-station rerun in round 3 gave the same one station (08NM0005) |
| 15 | Harvest verdicts | each check's own result | tier (i) `fail` and the registry's `reg_fail` kept apart, each with its own verdict line; exit 1 on either | the removed-row run printed both verdicts separately |
| 16 | Survey rows parsed from the tracked report | the survey report | the rows compared as multisets (sorted, `identical()`), so a line given twice fails as well as a missing or changed one (round 4: a set difference could not see a duplicate); the network line compared whole | a missing line failed "station rows"; a line given twice (round 5) failed "station rows" with "differing rows 0", which the set difference alone would have passed |
| 17 | Report `code_md5` lines | the code that made the report | hash of the script only; the reader's build is keyed by `wet_bcenv_reader` (row 1) | accepted, as row 1 |
| 18 | Registry `regulation` | the name rule it is written by | harvest: per station against `regulation_of(name)` | one value flipped: exit 1, "1 (07FA0001)" |
| 19 | The harvest's copy of the probe's query, and `scripts/station_sources_lib.R`'s copy of its match | `scripts/station_sources_probe.R` | the match: tier (i)'s station rows and network line against the probe's tracked report. The query: compared only with the reader in the same run (the tracked report holds no daily rows), so that it is verbatim rests on reading it; rounds 4 and 5 each compared it by eye with the probe's lines and found it identical (accepted) | the removed-row run failed the station rows |
| 20 | Registry `status` and `hydat_class` | (none: written and parsed, read by nothing; `hydat_class` came from shipped-rule years, not the survey's) | removed from the registry and its reader | the rewritten registry equals the old one with the two columns dropped (`identical()`) |
| 21 | The bound report's median column | see row 10 | see row 10 | see row 10 |
| 22 | Status grades | the grades the files carry | every grade must be in `wet_bcenv_grades`, else refused; `Unverified` counted as ungraded (round 5: it had fallen into "provisional", 99 days) | test: an unknown grade refused; an Unverified hour makes a day unchecked |
| 23 | The UTC-7 rule's coverage, and research's sentence about it | the stations' places | research now names the 14 Elk Valley stations read at UTC-8 and why no day of theirs moves (one value a day) | measured in the cached snapshot (round 5, and again 2026-11-22) |
| 24 | Routing by number shape (`wet_hydat_number`) | the registry's numbers | harvest: a registry number shaped like HYDAT's fails the registry verdict | 0 of 211 today; the check is a `grepl` on the registry |
| 25 | Numbers research copies from the reports | the two tracked reports | none mechanical: research is prose; each number was re-read from the reports at this commit (accepted) | - |

Nothing in the set sits above its source of truth unguarded except the accepted rows: 1's build code and 17, which rest on the documented manual reader version; 19's verbatim query, held by reading; and 25's prose.
