# Code-check round 4: #179 (round 3's fixes, then the enumeration)

## Checklist read

- **code-check.md**: the prose of all 14 H3 under `## Mechanisms` (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness (opening); Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things (opening); The probe is broken before the world is (index line only); Written data outlives the fix; Serialization loses meaning silently (opening); One fact derived twice). `## Rules that stand alone`, `## Security`, `## Spreadsheets and PDFs`: index lines only, none applies to the round-3 fixes; not read in full (about 20 headings).
- **code-check-r.md**: index read in full; sections applied from the index text: `match()` treats NA as a matchable VALUE, so two unknowns join to each other; `[[` on a named ATOMIC vector with an absent key is an error, not `NULL`; `$` on a list partial-matches, so a longer sibling key answers for a missing one; `unlist()` prefixes a `split()` group's name, so reassembling by name silently yields all-NA; `sort()` and `order()` collate by `LC_COLLATE`; Read-back shape must match write-back shape. Full text of the remaining ~140 headings not read (no tool or shape in the round-3 fixes).
- **code-check-shell.md**, **code-check-spatial.md**: index only; nothing in the round-3 fixes uses their tools (the albers()/sf call in scripts/station_sources_lib.R is unchanged by round 3). About 110 and 140 headings not read in full.

## Round 3's fixes

Checked, no defect found in:

- `wet_bcenv_cap()` (R/wet_bcenv_daily.R:178): the reader and `scripts/station_sources_bound.R:76` now call one function, and the bound script's `pv` (`bound = Inf`) holds the same complete, non-negative days the reader takes its median over, so the cap is the same population on both paths. Name indexing `med[ids]` is exact-match `[`, levels are `unique(ids)`, a station with no positive day gets NA and is kept, as documented.
- `differs()`/`moved()` (scripts/station_sources_harvest.R:165-169): element-wise, NA-safe; `wy_new` and `pass` cannot be NA (`count()` returns 0L, `class` is never NA), so the bare `!=` there is safe.
- `reg_fail` kept apart from `fail`, with its own verdict line and exit (lines 186, 222-224, 240-242).
- `reg_site` (line 185): `hydat_km` is `round(d, 2)` on both sides, so the CSV round trip is exact; `t1$hydat` is the match tier (i) verifies against the survey row.
- `reg_missing` (line 182): correct for what it covers (see row 6 below for what it does not).

## Findings

- **[severity: fragile]** inst/extdata/station_sources/bcenv_20261028_hydat.csv `regulation` column (written at data-raw/station_sources_snapshot.R:127, returned by R/wet_station_list.R:43) — a value derived from the station name, read later in place of `regulation_of(name)`, and no check can disagree with it. The harvest recomputes `regulation_of(t1$name)` for the survey row (scripts/station_sources_harvest.R:142) and never reads `st_meta$regulation`; test-wet_station_list.R:12 checks only that each value is one of the two labels. A hand edit, or a change to the data-raw mapping, reaches `wet_station_list()` with every check green. Measured now: 0 of 211 rows differ from `ifelse(regulation_of(name) == "unknown", "unknown", "regulated by name")` (10 regulated by name), so nothing is wrong today. Fix: one more term in `reg_fail`, `differs(st_meta$regulation, ifelse(regulation_of(st_meta$name) == "unknown", "unknown", "regulated by name"))`. This is the review's own mechanism and is missing from the enumeration (row 7 covers name, lon, lat only).
  - **Rule:** code-check.md, "Verification that reads its own output" ("for every field you write that your own code never reads back, name what does read it")

- **[severity: fragile]** scripts/station_sources_bound.R:78 — the report's "median of positive days" column is a second derivation of the median (`split(pv$q_m3s[pv$q_m3s > 0], ...)`), beside the cap column that comes from `wet_bcenv_cap()`. Round 3's point was one definition for the cap; the printed median is not held to it. Today the two agree (same days, same rule), but a change to the median inside `wet_bcenv_cap()` (zeros included, a different window) would leave the report printing a median that is not the one the cap was taken from, with cap/median no longer equal to the printed bound and nothing failing. Fix: derive the column from the cap (`x$cap[1] / wet_bcenv_ratio(x$station_number[1], bound)`) or have `wet_bcenv_cap()` return its median. Enumeration row 10's "one definition, used by both" is therefore true of the cap but not of the report's median column.
  - **Rule:** code-check.md, "One fact derived twice"

## Enumeration audit

Not complete. The mechanism as named (a recorded or derived value read later in place of its source, with no check able to disagree) has members the 17 rows miss, and three rows over-state their guard.

Missing places:

1. **Registry `regulation`** (finding 1): unguarded stand-in for `regulation_of(name)`, returned by `wet_station_list()`.
2. **The bound report's median column** (finding 2): a second derivation beside `wet_bcenv_cap()`; row 10 should say the cap alone is shared.
3. **The harvest's copies of the probe's code** (scripts/station_sources_harvest.R:60-94, the probe query "verbatim"; scripts/station_sources_lib.R, "copied from scripts/station_sources_probe.R"): stand-ins for the probe, which stays unchanged. Guarded, but not listed: the copied query's rows must equal the reader's UTC rows, and the lib's match must reproduce every survey row and the network line, so a drift in either shows in tier (i). I diffed both by eye against the probe today and they match. Worth a row so the set is the whole set.
4. **Registry `hydat_class` and `status`**: written, parsed by `wet_bcenv_stations()`'s `colClasses`, consumed by nothing (`wet_station_list()` drops both). Outside the mechanism today because nothing reads them in place of a source, but `hydat_class` was computed from shipped-rule years while the survey's class uses UTC years, so the first consumer to read it gets a value no check has compared with anything. A row saying "written, unread" closes it.

Rows whose guard or "shown to fire" claim is wrong or narrower than stated:

- **Row 6** (registry station set): `reg_missing` walks only stations with a complete day (`lst` and `utc` are both filtered to `hours >= 20`), 196 of 211. A station that has hours but no complete day, dropped from the registry, passes `reg_missing`, `reg_off` and `reg_site`; it is caught by tier (i)'s "station rows" (the survey lists all 211) and by test-wet_station_list.R's `nrow == 211`, so the run still exits 1, but the registry's own verdict line reads PASS. That is a narrower form of the verdict sharing round 3 fixed. Either walk the stations the files hold (`h`, as data-raw does) or state in row 6 that those 15 rest on tier (i) and the test.
- **Row 10**: true of the cap only (finding 2).
- **Row 16** (survey rows parsed from the report): "counts compared (211 and 211)" is not a gate. The counts are printed (line 200) and do not enter `fail`; the gate is `row_diff`, a symmetric set difference, which would not see a duplicated survey line. A missing line is still caught, through `row_diff`, so the "shown to fire" claim holds for that case; the guard column should name `row_diff`, not a count comparison.

Rows checked and accepted as written: 1-5, 7-9, 11-15, 17. Row 13's mutation counts were not re-run here.
