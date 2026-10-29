# Code-check round 1: #123 branch (station sources probe, report, research file)

## Checklist read

- `code-check.md`: all 14 H3s under `## Mechanisms`, prose only (table rows and evidence blocks skipped). Not read: 23 (the 14 "Rules that stand alone", 6 Security, 3 Spreadsheets and PDFs).
- `code-check-r.md`: read 17 of 111. These were `read.delim()` quotes by default; `download.file(quiet = TRUE)` / curl status; as.POSIXct on a Date; `paste()` with a zero-length argument; `data.frame()` recycles; `match()` treats NA; `ifelse()` with an all-NA test; duckdb `LOAD icu`; `sort()`/`order()` collate by `LC_COLLATE`; `unlist()` prefixes split names; `[[` on a named atomic; `$` partial match; `stats::aggregate()`; default curl user-agent on canada.ca; URL handed to a reader (60 s); `on.exit()` at top level; `tempfile()` lives in the session tempdir. Not read: 94.
- `code-check-shell.md`: read 2 of 67 (`curl -o` without `-L`; macOS awk multibyte slice). Not read: 65.
- `code-check-spatial.md`: read 2 of 93 (a coordinate stored as an attribute; a name is not a key). Not read: 91.

## Method

I read the probe, `R/wet_window_stats.R`, `scripts/wb_fit_lib.R` (`wb_release()`, `wb_hydat()`), the research file and the report in full, and the planning notes for private pointers. I did not run the probe. I did run some read-only checks:
- awk and `cut` over the cached provincial CSVs: ids, timestamps, sub-hourly rows, `l/s` stations, values above 1,000 m³/s with their grades;
- the Water Tool station list, for duplicate or NA `nid`s, and its CSV units and analyses;
- a read-only query of HYDAT 20260717 for the near-miss gauges.

What checked out:
- Timestamps are `Date/Time(UTC)` throughout, all on the hour, and no day has more than 24 rows. So the UTC-day rule is right.
- Ids carry no whitespace, so the dedup over `(id, t)` holds.
- The Water Tool's discharge is all `m3/s`. Its 7 duplicated `nid`s are co-located repeats, and the one kept has the longest record.
- `code_md5` in the report equals the script's md5.
- Every cbwaterhub "same site, new years" match is a HYDAT site discontinued by 1998.
- The research numbers 110, 211/153/57/1, 147/140, 44, 39/38, the grade shares, the NaN count, Tofino/CRD/EAO/GeoBC/OGIN/BCCF/BCER, the 1998–2020 and 2021–2026 match rates, the coordinates, the USGS years, Bulkley and Nechako all match report lines.

## Findings

- **[bug: wrong claim] research/station_sources.md:78–79.** "360 new discharge stations at 345 sites hold any daily record outside HYDAT" and "323 of them … have at least one complete window-year" describe the wrong populations.
  - The 360 is `sum(st$new)` (probe :467, :524). `new` is only `class != "duplicate"` with a discharge basis. So it includes:
    - all 95 non-duplicate Water Hub datasets, which have no daily values, only a listed period;
    - the 15 provincial stations with no complete day.
  - Nothing tests "outside HYDAT". From the report's "Per network" rows: 210 bcenv + 53 Tool + 95 Water Hub + 2 USGS = 360. Only 250 of those hold a daily record.
  - The 323 (`st$new & window_years_new >= 1`) includes the 85 Water Hub stations whose window-years are the [I] period proxy. The bar (line 30) says such a proxy is not a complete year. On daily values the figure is 238 (185 bcenv + 51 Tool + 2 USGS).
  - Fix: restate both bullets by what is counted, or make the probe report the daily-only figures (and their site counts) and quote those.

- **[bug: wrong claim] research/station_sources.md:12.** "the third-party networks in the BC Water Tool: 35 more stations pass the station test" overcounts.
  - 4 of the 35, Tofino 2601–2604, are the Tool's shorter (2013–2016) copies of the provincial 08HC0001–0004. Those four are already among the 110 (report rows for 08HC0001–0004 and 2601–2604, column "same site listed as").
  - The cause is that `wt_own` (probe :440) drops Tool stations only when their `nid` equals a provincial id, and Tofino's `nid`s differ.
  - The Tool adds 31 stations. Line 46 notes the overlap, but the opening answer does not.

- **[bug: wrong claim] research/station_sources.md:34.** "10 provincial stations read as regulated by name, and every other station is unknown [M]" is not what the report says.
  - `regulation_of()` is applied to the Tool stations too (probe :294).
  - The report flags 15 Tool listings "regulated? (name) [I]": BC ENV pump stations and ditches, five BC Hydro dams and diversions, and Surrey's Manson canal. One of them has a daily discharge series (BC Hydro `BLC-water`, Boulder Creek above the Diversion).

- **[bug: wrong count] research/station_sources.md:90, from probe :498.** "Reads the station list and 391 per-station CSVs once; 2 stations answer HTTP 500" double-counts the two failures.
  - The report's "bcwatertool/*.csv: 391 per-station files" is `length(wt_files)`. That counts every snapshot entry under `bcwatertool/`, including the 2 `.csv.status` files.
  - So it is 391 stations: 389 CSVs and 2 HTTP 500s. The directory holds 389 CSVs, each with an `Analysis,...` header.
  - The label is wrong in the report itself, and the research file repeats it.

- **[fragile] probe :469, :493–498 (also :196, :519, :562).** The report's order and the "md5 of their md5 list" depend on the locale.
  - These lines use `sort()` and `order()` on character, which collate by `LC_COLLATE`. This machine runs en_US. That is why `bcenv/Discharge.csv` is listed after the `Discharge_Archive_*` files, where C collation would put it first.
  - Under another locale (`LC_ALL=C`, or any other machine) the snapshot list, the station rows and the bcwatertool digest all change.
  - So "a rerun on the same snapshots gives a byte-identical report" (research :96, probe header :26–27) holds only in one locale. Use `method = "radix"` on these sorts and orders.

- **[gap behind a headline claim] near misses never hand-checked; research :9, :18, report "Every station read".** The probe header (:22–23) and the plan say near misses are "listed for a hand check". Neither progress.md nor the research file records that check, and the research file never mentions near misses.
  - 39 of the 147 passing stations carry one.
  - From HYDAT 20260717, at least three passing provincial stations sit on the same named stream 1.4–1.9 km from an active HYDAT gauge whose discharge years cover all of theirs:
    - 08HA0024, Chemainus River 2019–2021, against 08HA001 (1914–2025, 1.42 km);
    - 08LC0006, Bessette Creek 2021–2026, against 08LC042 (1973–2025, 1.85 km);
    - 08MG0002, Fitzsimmons Creek 2014–2026, against 08MG026 (1993–2025, 1.39 km).
  - HRB5454, "Tommy Lakes Rd (Black Swan Energy)", is 0.04 km from 07FC008, Beatton River at Tommy Lakes Road. Its years are still new, because HYDAT holds Q there for 2025 only.
  - Under the stated 1-km rule the 110 and 147 are computed correctly. But they rest on an unreviewed list that includes near-duplicate gauges. Either do and record the hand check, or say in the research file that the counts include unreviewed near misses.

- **[wrong / untraceable [M]] research/station_sources.md:103, :105.**
  - Line 103: Amor De Cosmos Creek (08HD0003) "reaches about 7,000 m³/s on RISC C and Unspecified hours in 2021–2024". In the snapshots, 312 of its 1,335 hours above 1,000 m³/s are RISC U, and 5 fall in 2025. The report gives neither grades nor years, so the [M] traces to no report line.
  - Line 105: "files many 2025–2026 provincial stations under 'Regulator – BC Oil and Gas Commission' [M]". This has no report line either: the report lists only the 11 Regulator stations not in the provincial files. The station list holds 30 Regulator rows, most first listed in 2026.
  - Either add both to the report or name the command beside each.

- **[public text] planning/active/findings.md:46, :56.** Both lines are public; findings.md is committed in a public repo.
  - Line 46 names four private repos in the installed-package list.
  - Line 56 gives a local machine path.
  - Describe both in words, as lines 51–52 already do. I found no other private pointers in research/, CLAUDE.md, README or the commits:
    - no BC Hydro private copy or consultancy is mentioned;
    - no commit carries a `Claude-Session:` line;
    - wet#140 and wet#142 resolve to the right titles.

/Users/airvine/Projects/repo/wet/planning/active/review-round1.md
