# Code-check round 3: branch 179-backlog-move-8-stations-beyond-hydat

Reviewed: the round-2 fix diff (e787634f..559e2d4e) first, then the whole branch diff against origin/main (eaa12d9d).
Probes ran in a detached worktree of HEAD (now removed). The per-user cache was only read: the stored-days files
`days_d68c95cfd3_v1.parquet` and `days_utc_d68c95cfd3_v1.parquet` kept their 20:41 and 20:43 mtimes, and the checkout's
`git status` is clean.

## Checklist read

- **code-check.md** (38 H3): read the prose of all 14 under `## Mechanisms`, tables skipped (A guard that fails toward
  pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own
  output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore
  the bug and prove the guard fires; A shared working tree...; A wrapper's exit is not the work; Zero-length, empty, and
  unset...; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning
  silently; One fact derived twice). 24 others not read.
- **code-check-r.md** (130 H3): read `system2(stdout = TRUE)` warns on a non-zero exit...; `match()` treats NA as a
  matchable VALUE...; A `data-raw/` script must load the source tree...; `on.exit()` at a script's top level never
  fires; `ifelse()` with an all-NA test...; A `skip_if_not()` skips only its own `test_that()` block; Tests that
  silently do not run; duckdb in R: the query that autoloads `icu`...; `tempfile()` lives in the session tempdir...;
  `sort()` and `order()` collate by `LC_COLLATE`...; A `function(...)` mock hides arguments.... 119 not read.
- **code-check-shell.md** (73 H3): read An S3 multipart ETag depends on the uploader's part size...; `aws s3 cp` cannot
  tell a missing key from a missing bucket. 71 not read.
- **code-check-spatial.md** (96 H3): none read. The diff does no spatial work: lon/lat pass through as numbers and
  nothing touches FWA geometry or rasters.

## Findings

- **[severity: fragile]** scripts/station_sources_harvest.R:164-166: `moved()` tests `a$first %in% b$first &
  a$last %in% b$last`, which is set membership across all 211 stations, not a per-station comparison. A station whose
  first or last year moves to a year any other station has is reported as unmoved. The same goes for one that gains or
  loses its only complete day (`NA %in% b$first` is TRUE while any station has no complete day, and 15 have none). The
  report's tier (ii) list "Stations whose first-last years, window-years outside HYDAT or pass moved" can therefore
  leave stations out. Measured on the pinned snapshot: an element-wise, NA-safe comparison also gives 1 station
  (08NM0005), so today's tracked report is right. It is right by luck of the data, though, and a rule change or a new
  snapshot can make the list quietly incomplete. `!(c(2001, 2002) %in% c(2002, 2001))` is `FALSE FALSE`. Only
  `wy_new` and `pass` are compared element-wise.
  - **Rule:** code-check.md "A proxy is not the property"
- **[severity: fragile]** scripts/station_sources_harvest.R:178 and 199-200: the round-2 fix adds the registry check
  to the same `fail` vector that tier (i)'s verdict reads. `out` is built after line 178, so a stale registry alone
  prints `verdict: FAIL: station registry` under the "Tier (i): the survey's rules" heading. That line says the survey
  reproduction failed when the survey was in fact reproduced. The exit status is still correct (1). The fix is to
  compute tier (i)'s verdict before tier (ii) appends to `fail`, or keep a separate vector for each tier.
  - **Rule:** none

## Mechanism

**The shared assumption behind round 2's five findings:** a stand-in taken as equal to the thing it names, with no
check able to disagree. In each case the stand-in was produced earlier, elsewhere, or by the check itself:

- a snapshot date stood for the files' content (stored-days key);
- a pin-time copy stood for what the reader returns now (registry first/last);
- metadata the uploader set itself stood for the bytes S3 holds (backup check);
- a count of newline bytes stood for a count of records (row check);
- a constant fixture stood for the offset under test (UTC-7 test).

That is code-check.md's "A proxy is not the property", "Verification that reads its own output", and "A fixture that
cannot reach the failure mode" all at once, plus "Written data outlives the fix" for the two stored artifacts (the
cache and the registry).

**Every place it reaches in the branch:**

| # | Where | Stand-in | Status |
|---|-------|----------|--------|
| 1 | `wet_bcenv_days()` key (R/wet_bcenv_daily.R:91-92) | manifest md5 for the files' content | **Covered.** Each manifest row is the file's md5, and every file is checked against it before a build. `utc` is in the name too. Build code is keyed by the manual `wet_bcenv_reader` (accepted, so not mechanical). |
| 2 | Registry `first`/`last` | pin-time value for the reader now | **Covered** when the harvest runs (exit 1, report line; seen to fail with one date shifted). The live Deep Creek test holds one station. Nothing in the offline suite (accepted). |
| 3 | Registry station set | registry rows (`nrow(t1)`) for "read 211" | **Covered indirectly.** The registry and the reader share `wet_bcenv_hours()`'s `h`, and tier (i)'s frozen-probe row comparison catches a change to `h`. The registry check walks the registry only, so a station the reader returns that the registry lacks is invisible to it. |
| 4 | Registry `name`/`lon`/`lat` | pin-time value | **Covered.** Tier (i)'s station rows compare them with the survey at %.4f. |
| 5 | Registry `hydat_site`/`hydat_km` | pin-time `hydat_match()` output | **Not covered.** Nothing compares them with the lib's current output. Low risk: the site match does not depend on years, and tier (i) holds the lib to the survey. `hydat_class`, which does depend on years, is read by no caller. |
| 6 | `wet_bcenv_bound` constant | constant for the measurement | **Covered.** The bound script and a test hold it to the report's printed line. |
| 7 | Bound script's own median/cap (scripts/station_sources_bound.R:76-79) against `wet_bcenv_daily()`'s (R/wet_bcenv_daily.R:52-55) | one fact derived twice | **Not covered mechanically.** The two agree today (208 dropped days in both reports), but only a reader comparing the two reports would see them diverge. |
| 8 | Manifest | raw files for the survey's md5s | **Covered** for 20261028 (data-raw step 1). |
| 9 | S3 backup | Content-MD5 on the PUT, then ETag | **Covered** for the data files. The check fails toward refusal on an SSE-KMS bucket, where the ETag is not the md5. The `.md5` sidecars are not read back (low: the manifest holds the md5s). |
| 10 | `wet_bcenv_lines()` | newline count plus an unterminated last line | **Covered** for terminated and unterminated files. Empty, header-only, blank-line and embedded-newline files all fail toward refusal ("different number of rows"); none loses a row. |
| 11 | Test fixtures | — | UTC-7 now discriminates (2 against 1 at UTC-8). Newer-file-wins, l/s, Unusable, NaN, 20 hours and the missing final newline all discriminate. 07ZZ0001's lone day (ratio 1) in the per-sub-drainage daily test passes under any bound of at least 1, but the direct `wet_bcenv_ratio()` assertion `c(2, 2, 1000, 1000)` covers the lookup: **covered**. |
| 12 | Harvest `moved()` | set membership for per-station equality | **Not covered:** Finding 1. |
| 13 | Harvest tier (i) verdict | the shared `fail` vector for tier (i)'s outcome | **Not covered:** Finding 2, introduced by the round-2 fix. |
| 14 | Report `code_md5` (harvest and bound) | script md5 for "the code that made it" | **Not covered.** R/wet_bcenv*.R is not hashed, so a reader change without a version bump leaves the header unchanged. This is the accepted manual reader version. |

/Users/airvine/Projects/repo/wet-179/planning/active/review-round3.md
