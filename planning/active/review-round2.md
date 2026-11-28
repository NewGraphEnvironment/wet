# Code-check round 2 (#235)

## Checklist read

- code-check.md: the prose of all 14 H3s under `## Mechanisms`, table rows skipped (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice). Not read: the remaining headings under "Rules that stand alone", Security and Spreadsheets (about 25).
- code-check-r.md: A fetcher's test helper must make the network fail, not just mock the reader; Under `R CMD check`, tests run from a temp dir against the INSTALLED package; `read.delim()` quotes by default, so a `"` in a field silently swallows rows; `ifelse()` with an all-NA test returns a logical vector, whatever `yes` and `no` are; Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it; plus the index lines of the rest. About 160 headings not read in full.
- code-check-spatial.md: FWA `upstream_route_measure` misses the next segment's start; index lines of the rest. About 115 headings not read in full.
- code-check-shell.md: index lines only (the diff has no shell scripts beyond `system2("aws", ...)`, covered by code-check-r's `system2` index line). About 95 headings not read in full.

index, diff and changed files read from file

## What was checked beyond reading

- Round 1's fixes: `R/wet_logger_daily.R` has no non-ASCII in code (`tools:::.check_package_ASCII_code(".")` returns `character(0)`); the all-stuck early return gives each day `drop = "stuck"` with the frame's column classes, and the days come out in order.
- `scripts/temp_loggers.R` rerun at HEAD in a detached worktree (`/private/tmp/wet235-r2`) from the cached Zenodo files. It wrote `data/checks/temp_loggers_nhg_15053907.txt` byte for byte (`git status` clean afterwards), so round 1's change to `wet_logger_days()` moved nothing in the report (0 stuck days).
- The manifest, registry and placement md5s in the report match the tracked files. All 32 placement rows carry the registry's md5.
- `wet_temp_daily(c("NHG_01FW007", "NHG_01FW003"), sources = "nhg")` returns 1,503 and 1,198 days, which agrees with the report's kept counts. The shape and the `source`/`status` values are right.
- The threshold script against its report and the library: the stuck rule (months 5-9 by the hour's local day, means > 0.5, breaks on a gap, on a value change and on candidacy, `> 154`) and the air rule (range of hourly means `>` the month's cap) agree between `scripts/temp_logger_thresholds.R` and `wet_logger_days()`. The amendment's screens are `>= 168` h per station-year and `<= 20` degC kept, as registered. The shipped constants equal the report's.
- The research file's numbers checked against the report: 87 %, 34,778/34,017 and 650/100/11, 3,153, 30 at 22 sites and 24 at 18, 31 of 32, 28 placed as 24 + 4, 08J 29 and 08K 3, the two near-ECCC sites, and the Amendment's 6 station-years, 135 days, 687 h and 24.97. All hold, except the one sentence below.
- The earlier record's duplicated stamps, probed in the cached `Data.zip`: they fall at 2019-11-03 and 2020-11-01 08:00 UTC and at 2021-03-14 10:00 UTC, so the research's "autumn and spring clock changes" holds.
- Issue numbers the branch cites (#215, #235, #251, #252, #253) resolve to the right issues.

## Findings

- **[severity: fragile]** research/station_water_temperature.md, "The Nechako loggers" paragraph: the sentence "at Whitesail Middle Creek and Chedakuz Creek the earlier record's stamps fit the later record better moved an hour" names the wrong set, going by the report it cites.
  - In `data/checks/temp_loggers_nhg_15053907.txt`, NHG_01NE002 (Whitesail, WTL) has equal 5,899, eq_-1h 6,012 and eq_+1h 5,800 of 36,334. That is about 16 % at every shift, and the hour back gains 0.3 points. Its records disagree at every alignment, so a moved stamp does not explain the difference. Its max day difference is 0.503 degC.
  - NHG_01FW002 (Endako, ESR) does fit better an hour back: equal 14,496, eq_-1h 15,581 of 21,779, which is 66.6 % against 71.5 %. The sentence leaves it out.
  - Chedakuz (CNR, 9,936 against 18,684) is the one site where the claim clearly holds.
  - So the sentence attributes the earlier record's daylight-saving shift to a site whose numbers do not show it, and omits one that does. That matters because the paragraph is the record of which record's clock to trust. The day-mean sentence after it (0.51 at those two, at most 0.08 elsewhere) is right as stated, since Endako's 0.076 rounds to 0.08.
  - **Rule:** none

No code defects found: the routing in `R/wet_temp_daily.R`, the manifest and registry checks, the pin script, the placement and report script, and the threshold script all do what their headers and the registered rules state, on the inputs checked above.
