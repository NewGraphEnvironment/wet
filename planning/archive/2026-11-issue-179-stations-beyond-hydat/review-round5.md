# Code-check round 5: #179 (round 4's fixes and the enumeration audit)

## Checklist read

- `code-check.md` (38 H3): read the full prose of all 14 under `## Mechanisms` (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice). Not read in full: 24 (Rules that stand alone, Security, Spreadsheets and PDFs; index lines only).
- `code-check-r.md` (130 H3): read in full the 10 whose index line names a tool or pattern this diff uses: `identical()` on two reader results; `match()` treats NA as a matchable VALUE; `sort()` and `order()` collate by `LC_COLLATE`; A database driver's value is not a base R type; duckdb in R: the query that autoloads `icu`; `$` on a list partial-matches; `system2(stdout = TRUE)` warns on a non-zero exit; `paste()` with a zero-length argument; A `skip_if_not()` skips only its own `test_that()` block; CSV whitespace. Not read in full: 120.
- `code-check-shell.md` (73 H3): index only; 73 not read in full (the diff's only shell use is `system2("aws", ...)`, an accepted tradeoff).
- `code-check-spatial.md` (96 H3): index only; 96 not read in full (the diff's only spatial code is the lib's copy of the probe's `sf` transform, held by tier (i)).

## Findings

- **[severity: fragile]** `research/station_sources.md:131` (and the offset rule it vouches for, `R/wet_bcenv_daily.R:235-236`) — the research verdict "The East Kootenay and Creston also keep Mountain time; none of the snapshot's stations sits there [M, the station registry]" is false against the registry it cites. Fourteen registry stations, 08NK0001–08NK0014 (Fording River, Line Creek, Michel Creek, Greenhills Creek and others, lon −114.67 to −114.88, near Elkford and Sparwood), sit in the Elk Valley, in the East Kootenay, which keeps Mountain time; the build gives every `08N…` station UTC−8. No shipped day moves today, only because none of the 14 has a complete day: measured on the cached snapshot (read-only), each holds one value per day, stamped 08:00 UTC (774, 924, … 1,029 values over 2018–2020), which the 20-hour rule discards whatever the offset. This is the review's mechanism outside the enumeration: a sentence recorded once ("none sits there") stands in for the registry, and it is the only thing guarding the drainage-code-to-time-zone rule; a later snapshot in which these stations report hourly would be read an hour off with the research telling the maintainer it cannot happen. It also leaves unsaid that the 20-hour rule drops 14 stations' whole daily records (about 10,600 daily values), which is why `wet_station_list()` shows them with no first or last day.
  - **Rule:** code-check.md, "A proxy is not the property" (drainage code standing for time zone); agent-operations.md §3, "Documents that share an ancestor corroborate nothing" (a quantifier, "none", not walked over its population).

- **[severity: bug]** `R/wet_bcenv_daily.R:242` (status) with `R/wet_bcenv_daily.R:160` — the "ungraded" set is a literal list, `('Undefined', 'Unspecified')`, never held to the grades the files carry, and unlike units (`R/wet_bcenv_daily.R:281-285`, any other unit refused) an unlisted grade falls silently into `"provisional"`. The snapshot holds a grade `Unverified` (2,385 hours; the survey report lists it at 0.0 %): measured on the cached snapshot, 99 complete days at 08MF0004 and 08LC0001 contain `Unverified` hours and no Undefined/Unspecified hour, and ship as `"provisional"`, the status the docs give a day "whose hours are all graded", although the grade says the hour was not verified. A new snapshot's new grade name would pass the same way. Either classify `Unverified` with the ungraded set, or refuse a grade outside a declared, complete partition of the snapshot's grades (as units are refused), so the partition is a checked set rather than a list that matches today's data.
  - **Rule:** code-check.md, "A guard's scope, escape hatches, and remedies" (a literal set used as a filter grows blind as the data grows; enumerate the complement) and "A guard that fails toward pass" (an unknown grade defaults to the passing label).

Round 4's fixes themselves (the multiset row comparison, `held`, the regulation read-back, the median read back as cap / ratio, the registry without `status` and `hydat_class`) hold: I found no defect inside them. `sort(..., method = "radix")` on `theirs` (marked `unknown` by `readLines()`) would abort on a non-ASCII first element, but the survey's provincial lines and the registry hold no non-ASCII byte (checked), and the survey is fixed.

## Enumeration audit

Not complete: three places are missing and four rows claim more than their guard or proof shows.

**Missing places**

1. The research verdict on Mountain time and the UTC−7 rule it guards (finding 1). False today; no shipped day affected.
2. The status grade partition (finding 2). 99 days mislabelled.
3. `wet_hydat_number` (`R/wet_station_daily.R:131`), the routing rule that stands in for "is not a provincial station": a registry id of HYDAT's shape would be sent to the federal sources and never read from the snapshot (or answered with a HYDAT station's record). Nothing holds the registry against it; today no registry id matches (checked all 211). A one-line guard in `wet_bcenv_stations()` or the harvest would close it.
4. (true today, unguarded) The numbers `research/station_sources.md` copies from the two reports (215,300; 215,168; 208; 214,960; 08NM0005 11 not 12; 110; 66.2 %; 58; 211; 2,490.71; 268.07 over 82; 1,346.56). Each matches the current reports; nothing re-checks them when a report changes ("Written data outlives the fix", enumerate every artifact quoting a derived value).

**Rows that claim more than their guard or proof**

- Row 19: "daily rows ... must equal the probe's tracked output". The probe's tracked output (the survey report) holds no daily rows. The harvest's copy of the probe's query is compared with the reader's UTC days, both computed now; only the aggregated station rows and the network line reach the tracked output. That the copy is verbatim rests on its comment (I compared it by eye with `scripts/station_sources_probe.R:321-389`: the same, less the row-count check the reader carries itself).
- Row 6: the proof ("one row removed: exit 1, lacks: 1 (07FC0002)") removes a station that has complete days, which the pre-round-4 set (`lst` after the 20-hour cut plus `utc`) also caught. The case round 4 added, a station with usable hours and no complete day (any of 08NK0001–08NK0014), was not exercised. By reading, `held` is taken before the 20-hour cut and those 14 stations are in the stored days, so the guard does catch it; the shown-to-fire claim is not that measurement.
- Row 16: the multiset fix exists for a line given twice, but the proof cited is a missing line, which the old set difference already caught. `identical(sort(mine), sort(theirs))` does see a duplicate by reading; it was not shown.
- Row 7: name is held whole, but lon and lat only at the survey's `%.4f` (about 11 m); the registry carries up to 9 decimals, and nothing compares them with the files at full precision. Harmless in effect, but the row should say the precision.

**Places walked, with verdict**

| Place | Row | Verdict |
|---|---|---|
| Tracked manifest | 3 | true (survey md5s, `stop()` on mismatch) |
| Cached files | 2 | true (size + md5, tests change one byte and one size) |
| Stored LST days parquet | 1 | true as stated; build code rests on the reader bump (accepted) |
| Stored UTC days parquet | 1 (not named) | covered better than row 1: tier (i) compares it with the probe query run fresh |
| S3 backup | 4 | true (Content-MD5 PUT, ETag and size read back); sidecars accepted |
| Registry station set | 6, 7 | true by reading (survey multiset both ways; `held` covers the no-complete-day case); proof overclaims (above) |
| Registry name | 7 | true |
| Registry lon, lat | 7 | true at 4 decimals only (above) |
| Registry first, last | 5 | true (per station against `wet_bcenv_daily()`; accepted as pin-time) |
| Registry regulation | 18 | true (against `regulation_of(name)`, name held by row 7) |
| Registry hydat_site, hydat_km | 8 | true (against tier (i)'s match, itself held to the survey rows) |
| Registry status, hydat_class | 20 | true (removed; no reader left: grep of R, scripts, tests, man, CSV) |
| `wet_bcenv_bound` constant | 9 | true (script: printed line = measurement, constant identical; test: constant = printed line) |
| Each day's cap, report median | 10, 21 | true (one `wet_bcenv_cap()`; median = cap / ratio; report diff in round 4 is the md5 line only) |
| Reader UTC days | 11 | true |
| Expected row count | 12 | true |
| Fixture days | 13 | not re-measured; no reason found to doubt |
| Harvest moved list | 14 | true |
| Harvest verdicts | 15 | true (`fail` and `reg_fail` separate; exit 1 on either) |
| Survey rows parsed | 16 | true by reading; proof overclaims (above) |
| Report code_md5 | 17 | accepted |
| Probe query copy, lib match copy | 19 | station rows and network line true; "daily rows equal tracked output" overclaims (above) |
| `regulation_of()` copy, `match_km`/`near_km`, `min_years` | 19 (implicit) | true: each reaches a survey-row or network-line field |
| Survey windows from `life_history_bulk.csv` | none | guarded (`stopifnot` on the four dates); add a row or leave as is |
| UTC−7 drainage rule and its research verdict | none | missing; verdict false (finding 1) |
| Status grade partition | none | missing; 99 days mislabelled (finding 2) |
| `wet_hydat_number` routing | none | missing; true today, unguarded |
| Research numbers copied from reports | none | missing; true today, unguarded |
