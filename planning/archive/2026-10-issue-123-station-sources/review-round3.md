# Code-check round 3: branch 123-station-source-survey-which-networks-bey

Reviewer: subagent, 2026-10-28. Read only. The probe was not run. I checked the report by parsing its "Every station read" table (490 rows) in a scratch R session. The parse reproduces the report's own totals (147 passing; 140/238/227/38 sites at 0.5 km; 95/85/39 proxy), so it is the report's population. HYDAT status came from the cached 20260717 release, opened read-only. The provincial CSVs were read from byte-fixed copies in the scratchpad, which are now deleted.

## Checklist read

- **index_code-check.md, index_code-check-r.md, index_code-check-shell.md, index_code-check-spatial.md**: all four indexes read in full.
- **code-check.md**: read the prose of all 14 H3s under `## Mechanisms` (table rows and evidence skipped): "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A proxy is not the property", "Verification that reads its own output", "A guard's scope, escape hatches, and remedies", "A fix lands in one of two callers that share a harness", "Restore the bug and prove the guard fires", "A shared working tree, and what generators leave in it", "A wrapper's exit is not the work", "Zero-length, empty, and unset are three different things", "The probe is broken before the world is", "Written data outlives the fix", "Serialization loses meaning silently", "One fact derived twice". Not read in full: the 23 standalone, security and spreadsheet H3s (index lines only; none names a tool or shape this diff uses).
- **code-check-r.md**: read in full (17): `download.file(quiet = TRUE)` / curl status; `on.exit()` at top level; `$` partial-matches; `nzchar(NA)`; `paste()` zero-length; CSV whitespace; `sort()`/`order()` collate; `vapply(USE.NAMES = FALSE)`; `match()` NA; `[[` on atomic; `data.frame()` recycles; `tempfile()`; Postgres row order (applied to duckdb aggregation and ties); `c()` dispatch on Date; `read.delim()` quotes; duckdb `icu`; `ifelse()` all-NA. Not read: 94.
- **code-check-shell.md**: read in full (2): "`curl -o` without `-L`", "A sed/awk range can run to EOF". Not read: 65 (no shell in the diff).
- **code-check-spatial.md**: read in full (2): "A coordinate stored as an attribute can disagree with the geometry", "A name is not a key". Not read: 91. The diff's only spatial step is an `sf::st_transform` to 3005 distance.

The code-side checks raised no defect. The parsed-JSON `$` reads use exact keys present in both sources. `match()` sees no NA keys. Sorts are radix or by name. `read.delim` passes `quote = ""`. duckdb needs no icu (`substr` and a VARCHAR→DATE cast). No `(id, t)` key repeats within a file or across files, so the `row_number()` dedup has no ties.

## Mechanism

Counts in the prose are copied from a report line, but the selector behind that line covers a different population from the one the prose names. In practice the line's qualifier gets dropped. Four forms:

1. **The selector uses a broad flag.** `cb_row` (probe :171–174) counts a Water Hub dataset as discharge if it has the Discharge **tag** *or* a discharge parameter. `listed` (:534) and the period proxy then inherit that. The Tool's station list keeps any listing with years (`n_yr > 0`, :260), whatever the series.
2. **A category is assigned by negation, or by a default branch.** In `class` (:133–134), a station that cannot be compared becomes "same site, new years", because `first` is NA.
3. **A parameter is not stated.** Sites are grouped at `same_site_km = 0.5` (:483), but the prose names only the 1 km HYDAT rule.
4. **Summary quantifiers come from a label or verdict column instead of the members.** "Everything else is no", "the rest are …", "no discharge of their own", "every year from 1998 to 2020", and network lists written separately from the total they gloss.

Rounds 1 and 2 fixed instances of this. The table below walks every number and quantifier so the class can be closed.

## Findings

- **[medium] research/station_sources.md:13, :49, :81, from probe :171–174 and :534 — the Water Hub's proxy counts include stage-only and report datasets.** (Inside a previous fix: y. Round 2's `listed` selector carries it into 95/85/39. The tag-only rule predates the fixes.) Of the 39 "passing on the proxy", 10 are "Discharge tag only": they have no discharge parameter in any resource. Of the 95 and 85, 20 and 13 are tag-only.
  - Five of the ten are CBWMF streams that `planning/active/sources-b.md` (§1a) records as "stage only or not yet rated": Bjerkness, Carlyle, Gar, Kootenay Joe and MacDonald, at 11, 13, 9, 7 and 12 "window-years".
  - One is `summary-reports-for-slocan-valley-water-monitoring-programs`, a reports dataset credited with 27 window-years.
  - The rest (Hasty, Trail at French St, Trozzo, Winlaw) are datasets the desk research calls "probably spot or manual measurements".
  - Under the bar, stage-only is **no**. A listed period over spot measurements is not a gauged record, so the [I] proxy's "no gaps" assumption fails worst on exactly these datasets.
  - On discharge-parameter datasets only, the counts are 29 passing, 72 with at least one window, and 75 listed-period stations not duplicates. The inventory's "96 datasets with discharge", and its 69/26 split, include the same 20.
  - Fix: count only `discharge == "parameter"` as discharge (keep tag-only as its own reported line), or say in the prose that the counts include 20 tag-only datasets.
- **[low] #118 "More stations" ("The Skeena Knowledge Trust and UNBC hold no discharge of their own"); research/station_sources.md:52 ("No discharge") — UNBC does hold discharge.** (n) The report's Tool network "UNBC (Collected for academic research project)" has `Q 2` (report :43). Its header reads "Data from UNBC research programs" (:158). Two daily "Preliminary Discharge" series, ogc_1001 and ogc_1003 (West and East Kiskatinaw, 2010–2012), hold 1 and 2 window-years. They count among the 51 Water Tool lower-bar stations. The same research row says this ("Two Kiskatinaw stations … in the BC Water Tool"), so the Discharge cell and #118 contradict it.
- **[low] research/station_sources.md:16 "Everything else is **no**"; research/README.md row "the rest are stage only, HYDAT copies or not accessible"; CLAUDE.md line "the rest are test-only or no" — the summaries miss the leads.** (n) The "Also found" table gives four sources the verdict lead/leads, not no: the CRD's ECCC partner feed (22 stations, not read), Rio Tinto (Nechako), UBC East Creek, and the USGS Kootenay study. The README sentence also leaves out the "no discharge" class (Skeena Knowledge Trust, UNBC's own channels, mine baselines not machine-readable), which the research file's own sentence includes.
- **[low] #142, last paragraph — "(CRD, Geoscience BC, the oil and gas industry network, EAO, BCCF, BCER) have 35 stations that pass … (29 beyond the provincial sites)" omits Tofino.** (y: the "29 beyond" came from round 1's fix, and the list was not rechecked.) The 35 includes Tofino's 4 (report :65–74). The six networks named hold 31. The 29 is right, because all four Tofino stations sit at provincial-passing sites.
- **[low] Report-line qualifiers dropped.** (n)
  - research/station_sources.md:62, "The Tool holds 2019–2020 for 20 stations, 0 passing". Report :33 has BC Hydro `read 20  Q 5`. 15 of the 20 have "no discharge series" (forebays, reservoirs, dams). Five carry 2019–2020 discharge, and 2 of those are HYDAT duplicates.
  - research/station_sources.md:47, "2 stations not in the files (08MH0061, H08KC1015)". Report :142 says "with discharge". The Tool's BC ENV network has 78 listings outside the provincial files (:31), and 76 of them have no discharge series. The source here is the probe's planning note, which says "20 BC Hydro station records".
- **[low] research/station_sources.md:18, :78, :79 — site counts use an unstated 0.5 km rule beside a stated 1 km rule.** (y: "The bar's same-site rule is 1 km on the same stream" was added beside "140 distinct sites" in round 1's fix.) The 140, 238 and 227 come from `same_site_km = 0.5` (probe :483; the report says so at :75, and the research file does not). Under the 1 km same-stream rule the file names, the counts are 139, 227 and 219 (recomputed with the probe's own `stream_of()`).
- **[low] research/station_sources.md:104 and #142 "Revisions" — "at least 99.7 % of days in every year from 1998 to 2020".** (n) The by-year table (report :110–136) has no 2004 or 2005: no station-days were compared in those years. The claim holds for the 21 years compared. Say "in every year compared" or name the gap.
- **[low] #142 "Format traps" — "an hour can sit in two files (take the newer)".** (n) Across the eight snapshots, no `(Location ID, Date/Time)` discharge key appears in more than one file (a duckdb query over byte-fixed copies returned 0). Each archive starts where the previous one ends. The sentence restates what the probe's code does (:309, :353) as if it were a fact about the data.
- **[low] research/station_sources.md:49 — "49 of them Living Lakes' CBWMF network".** (n) 49 is the report label "living-lakes-canada (CBWMF)": organisation is Living Lakes *and* the dataset is in the CBWMF group. The CBWMF group itself, the probe's `cbwmf` flag (:195), holds 54 of the 96. Elk River Alliance adds 3 and Harrop-Procter 2, and sources-b gives the same 54 (96 − 42 outside the group). 11 of the 54 are tag-only (stage only).
- **[low] #118 "More stations" — "BC Hydro releases data only by request (#140)".** (n) The research file (:62) says the *archive* is released by request. BC Hydro also publishes 4 days of data openly, and the Tool holds 2019–2020 for 5 stations. Adding "only" makes a claim the source does not.

## Enumeration

Columns: claim · report line it rests on · code selector (`scripts/station_sources_probe.R`) · verdict.

- **holds**: the claim matches its line.
- **wrong**: see Findings.
- **untraceable**: no report line or recorded command.
- **[S]**: a cited source, not re-fetched.
- **[desk M]**: measured during desk research and recorded in `planning/active/sources-a.md` or `sources-b.md`, not in the report.

Report line numbers refer to `data/checks/station_sources_20260717.txt` at HEAD ae1b456.

### research/station_sources.md

| line | claim | report line | selector | verdict |
|---|---|---|---|---|
| 3 | spawned wet#142 (harvester) and wet#140 (BC Hydro) | — | — | holds (gh titles) |
| 3 | against HYDAT 2026-07-17 | :2 | :37–38 | holds |
| 9 | one source passes the bar | :65–74 | :479, :525; licence criterion external | holds |
| 9 | OGL-BC | — | :397 (label) | [S] |
| 9 | 110 of its 211 have ≥3 complete window-years HYDAT does not hold | :29, :66 | :479, :460–468 | holds |
| 12 | 35 more Tool stations pass | :65–74 | :529–532 | holds |
| 12 | 6 of them at provincial-passing sites | :80 | :548–552 (0.5 km) | holds (also 6 at 1 km) |
| 12 | no redistribution licence stated | :144–159 | :605–609 (first 100 chars) | holds |
| 13 | Water Hub: 39 stations on the period proxy | :76 | :534–537, :171–174 | **wrong** (10 tag-only, 5 of them stage-only CBWMF, 1 reports) |
| 13 | all preliminary | — | — | [desk M] sources-b :9; holds |
| 13 | a scripted reader needs Living Lakes' consent | — | — | [S] robots.txt / policy |
| 14 | two USGS gauges, below the 5-station threshold | :63, :74 | :479 | holds |
| 16 | everything else is no | Also found :63, :70, :73 rows say lead | — | **wrong** (leads) |
| 16 | BC Hydro by request, wet#140; DataStream key by request | — | — | [S] |
| 18 | 147 stations at 140 distinct sites | :65, :75 | :479, :483–490 (0.5 km) | holds at 0.5 km; **wrong** beside the stated 1 km rule (139) |
| 18 | same-site rule is 1 km on the same stream | :5 | :57, :115 | holds |
| 18 | 3 km: 4 provincial drop out (08HA0024, 08LC0006, 08MG0002, 08NM0006), leaving 143 | :82–87 | :122–123, :553–562 | holds |
| 18 | Bulkley gain is small: 08EE0001, 08EE0002 have 2 window-years each | rows 08EE0001/2 | :467–468 | holds (no other discharge station in the Bulkley in any source; Owens Ck 08EE0003 in the Tool has no discharge series) |
| 18 | Nechako 08JC0001–0006 have 3 or 4 | rows 08JC000x | :468 | holds (5 stations; no 08JC0004 exists) |
| 22 | every source and asset found is recorded | — | — | untraceable (desk process claim) |
| 24–30 | bar definitions (window, `min_frac = 0.8`, proxy cannot reach harvest) | :3–6 | :51–58, :242–245, :140–152 | holds |
| 31–32 | test-only / no definitions; duplicate only where periods overlap | — | :133–134 | holds |
| 34 | 10 provincial flagged regulated by name, 4 passing | :91 | :236–239, :563–567 | holds |
| 34 | 15 Water Tool listings flagged, none passing | :92 | same; over `wt_own` (:449) | holds |
| 34 | every other station is unknown | — | :199, :238, :437 | holds |
| 38 | the definition of "passing" | :6 | :479 | holds |
| 42 | `Discharge.csv` and 7 archive files | :9–16 | :311–314 | holds |
| 42 | ratings by the province and partners incl. City of Surrey [S, "Also found"] | rows: 18 "… - City of Surrey" stations in the provincial files | — | holds by [M]; the cited "Also found" has no Surrey row (mis-tag) |
| 42 | Undefined 58.8 %, Unspecified 7.3 %, RISC A–E/U | :97 | :384 | holds (A, B, C, E, U present) |
| 42 | 134 of 211 mostly ungraded | :98 | :382, :572 | holds |
| 42 | no approval field | — | :339–340 (file columns) | holds |
| 42 | bulk CSV, no login | — | :315 | holds |
| 42 | 1998–2026 | rows (min first 1998, max last 2026) | :390–392 | holds |
| 42 | 211: 153 not in HYDAT, 57 same site new years, 1 duplicate (08NM0015) | :29 | :133–134, :523–524 | holds (all 57 at HYD_STATUS D; 3 with no complete day get the class by the default branch) |
| 42 | 110 passing, 44 seasonal | :29 | :477, :525–526 | holds |
| 43 | some catalogue archive links stale or 404 | — | — | [desk M] |
| 44 | Aquarius click-through disclaimer | — | — | [desk M] |
| 46 | daily "Preliminary Discharge" | — | :279 | holds |
| 46 | QA header flag "1 - Quality Checked …" | — | — | [desk M] sources-a :84 |
| 46 | headers carry attributions and disclaimers, no redistribution licence | :144–159 | :605–609 | holds |
| 46 | robots.txt allows all | — | — | [desk M] |
| 46 | CRD 8, Geoscience BC 7, O&G 7, EAO 5, Tofino 4, BCCF 2, BCER 2 = 35 | :65–74 | :529–532 | holds |
| 46 | Tofino 4 + BCCF 2 at provincial-passing sites (08HC000x, 08HB0011, 08HB0008); 29 beyond | :80, rows "also" | :548–552 | holds |
| 47 | BC ENV series is a copy of the provincial files | :106–136 | :399–405 | holds |
| 47 | 2 stations not in the files (08MH0061, H08KC1015) | :142 ("with discharge") | :601–603 | **wrong** (qualifier dropped; 78 BC ENV listings beyond the files, :31) |
| 47 | OGL-BC (report JSON) | :146 shows no OGL | — | untraceable (the Tool's JSON, not this report) |
| 48 | DFO 14, Delta 6, CVRD 3, Surrey SCADA 2, Wasa 1: no discharge series | :35–41 | :289, :521 | holds |
| 48 | DFO "personal and public non-commercial" | :152 | :605–609 | holds |
| 49 | 96 datasets with discharge | :44–62 (read sum 96) | :171–174 (tag OR parameter) | holds as selected; 20 are tag-only (see finding 1) |
| 49 | 49 of them Living Lakes' CBWMF network | :54 | :194–195 | **wrong** (the CBWMF group holds 54) |
| 49 | all preliminary; flag column empty | — | — | [desk M] sources-b :9 |
| 49 | licences: Amended CC-BY-SA-4.0, CC BY-NC-SA, CC BY-SA | — | :196 (not reported) | [desk M] |
| 49 | robots.txt disallows `/api/`; Anubis wall | — | — | [desk M] |
| 49 | 39 passing on the proxy at 38 sites | :76 | :534–537 | **wrong** population (finding 1) |
| 49 | 69 not in HYDAT, 26 adding years at a discontinued WSC site | :44–62 sums | :133–134, :523–524 | holds (all 26 at HYD_STATUS D); includes tag-only |
| 49 | Redfish Creek duplicates active 08NJ061 | row (laird-creek-waterusers) | :133–134 | holds (08NJ061 status A) |
| 50 | Skeena: no original discharge; mostly "other (closed)" | — | — | [desk M] |
| 51 | DataStream vocabulary, BC holdings, licences, key by form, robots | — | — | [S]/[desk M] |
| 52 | UNBC: no discharge (68 request-form sites) | :43 (Q 2), :158 | :289 | **wrong** (the Tool's 2 UNBC series are discharge) |
| 52 | two Kiskatinaw stations (2010–2012) in the Tool, 0 passing | rows ogc_1001/ogc_1003 | :479 | holds |
| 60 | Hakai ERDDAP: 7 stations, 2013–2026, rated, CC BY 4.0 | — | — | [S]/[desk M] |
| 60 | the province carries three from 2021 (H08KC0626, 0703, 0844); the Tool a fourth (H08KC1015) | rows; :142 | :390–392 | holds |
| 61 | 12355000 adds 2019–2026 beyond 08NP001; 12212390 adds 2013–2026 beyond 08MH152 | rows (08NP001 Q 1929–2018; 08MH152 Q 1984–2012) | :133–134 | holds |
| 61 | waterservices.usgs.gov serves no robots.txt; public domain | — | :448 | [desk M] / [I] |
| 62 | BC Hydro page: 220 stations, 4 days, not QC'd, 7 BC Hydro-operated with discharge | — | — | [S]/[desk M] sources-a :118–121 |
| 62 | the Tool holds 2019–2020 for 20 stations | :33 (read 20, Q 5) | :260 (`n_yr > 0`) | **wrong** (5 with discharge) |
| 62 | 0 passing | :33 | :525 | holds |
| 63 | CRD: 12 stations in the Tool | :34 | :260 | holds |
| 63 | ECCC partner record, 22 stations | — | — | [S] |
| 64 | OBWB/ONA ~75 stations; publishes through the provincial portal | — | — | [S] |
| 65 | RDN/BCCF stations in the provincial database (08HB0021, 08HB0007, 08HB0031, 08HB0011) | rows | — | holds |
| 66 | BCER/Treaty 8: 07FC0001, 10CD0001 in the provincial files, more in the Tool | rows; :71 | — | holds |
| 67–71 | DFO VI Hydromets, PSF, Metro Vancouver, Rio Tinto, mine baselines | — | — | [S]/[I] as tagged |
| 72 | RFC: 522 stations; crosswalk for 7 provincial and 11 USGS | — | — | [desk M] sources-a :71 |
| 73 | DataCite records for UBC and USGS | — | — | [desk M] |
| 78 | 250 stations at 238 sites, a daily record, not duplicates | :77 | :538–541 | holds at 0.5 km (227 sites at 1 km) |
| 79 | 238 at 227 sites with ≥1 window-year: 185 / 51 / 2 | :78 | :539–545 | holds at 0.5 km (219 at 1 km) |
| 80 | 60 seasonal-only | :78 | :476–477, :543 | holds |
| 81 | 95 listed-period non-duplicates; 85 with a whole window; 39 pass on the proxy | :76, :79 | :534–547 | **wrong** population (20/13/10 tag-only) |
| 81 | none of the 39 is at a site that passes on daily values | :76 ("not already a passing site: 38" of 38) | :537 | holds |
| 85–94 | robots.txt per host | — | — | [desk M] |
| 89 | downloads the 8 CSVs once | — | :315, :210–233 | holds |
| 90 | 391 stations: 389 files and 2 HTTP 500s, kept as `.status` | :22 | :504–507 | holds |
| 90 | the 2 answer HTTP 500 "every time" | — | :213–216 (a failure is kept, never retried) | untraceable |
| 91–93 | fetches nothing from the Water Hub, Hakai or DataStream | — | :167–168 (snapshot only); no fetch to them | holds |
| 94 | reads daily values for two USGS sites; OGC `items` not used | — | :415–431 | holds |
| 96 | a rerun gives a byte-identical report | — | — | holds (progress.md :13, two runs) |
| 101 | six Vancouver Island stations report 2016–2019 in l/s | :99 (6 stations) | :357–361 | holds (raw: 08HA/08HB ids, 2016-07-21 to 2019-11-07) |
| 102 | 800,830 NaN at 121 stations; a day needs 20 real hours | :99 | :362–363, :388 | holds |
| 103 | Oliver 2.1 M (RISC C, U, 2021–2024); Amor De Cosmos ~7,000 (C, U, Unspecified, 2021–2025); Big Bar up to 9,887 | :101–104 | :371–375 | holds |
| 103 | complete days do not depend on magnitude | — | :376–378, :388 | holds |
| 104 | ≥99.7 % within 0.1 % in every year 1998–2020 | :110–132 | :588–593 | **wrong** quantifier (no 2004 or 2005 rows) |
| 104 | 61–92 % from 2021 | :133–136 | same | holds (61.1–92.2) |
| 105 | 08JC0002 and 08JC0006 placed 111.6 km off | :137–139 | :406–410 | holds |
| 105 | 17 provincial stations under "Regulator"; BCER's own plus 08NM00xx, 08LC000x, 08LG0019, 08NJ0001, 08MH0062 | :140 | :597–600 | holds (4 + 13 = 17) |
| 109 | no NewGraph package fetches these sources | — | — | untraceable here ([desk M], findings.md) |

### research/README.md row (added)

| claim | report line | verdict |
|---|---|---|
| province's network passes; 110 with ≥3 window-years outside HYDAT; harvester wet#142 | :29, :66 | holds |
| Tool third-party networks, Water Hub and two USGS gauges are test-only | :65–76 | holds |
| "the rest are stage only, HYDAT copies or not accessible" | — | **wrong** (omits no-discharge; leads) |
| province's unit, NaN and impossible-value defects; robots.txt per host | :99–104 | holds |

### CLAUDE.md line (added)

| claim | report line | verdict |
|---|---|---|
| province's non-integrated network is the one harvest candidate (wet#142) | :65–74 | holds |
| "the rest are test-only or no" | — | **wrong** (leads) |

### wet#142 body

| claim | report line | selector | verdict |
|---|---|---|---|
| 110 with ≥3 complete window-years HYDAT does not hold | :29, :66 | :479 | holds |
| `Discharge.csv` and seven archives, about 740 MB | :9–16 | — | holds (738 MB on disk) |
| catalogue archive links stale | — | — | [desk M] |
| 211 stations, from 1998 to now | :29, rows | :390–392 | holds |
| 153 not in HYDAT; 57 add years at a discontinued HYDAT site; 1 overlaps HYDAT | :29 | :133–134 | holds (all 57 HYD_STATUS D; 3 no-complete-day by default branch) |
| provincial IDs are not HYDAT IDs (08NM0002 vs 08NM002) | row 08NM0002 | — | holds ([desk M] sources-a :62) |
| CRLF; byte 0x96 in one name | — | :316–331 | holds |
| six stations report 2016–2019 in l/s | :99 | :357–361 | holds |
| 800,830 NaN | :99 | :362–363 | holds |
| "an hour can sit in two files (take the newer)" | — | :309, :353 | **wrong** (0 keys in two files) |
| Undefined 58.8 %, Unspecified 7.3 %; 134 of 211; no approval field | :97–98 | :382–384 | holds |
| Oliver 2.1 million, Amor De Cosmos about 7,000 | :101–102 | :371–375 | holds |
| ≥99.7 % in every year 1998–2020 | :110–132 | :588–593 | **wrong** quantifier (2004–2005 absent) |
| 61–92 % for 2021–2026 | :133–136 | same | holds |
| names flag 10 as regulated, the rest unknown | :91 | :563–567 | holds |
| the 57 "same site, new years" | :29 | :524 | holds |
| four passing stations 1.4–1.9 km from a same-stream gauge; overlap all or nearly all for three, 3 of 8 for 08NM0006; each fails if counted | :84–87 | :553–562 | holds |
| Hakai's three stations 2013–, CC BY 4.0, ERDDAP disallowed | — | — | [S] (per-station start not measured) |
| networks (CRD, Geoscience BC, O&G, EAO, BCCF, BCER) have 35 that pass, 29 beyond | :65–74, :80 | :529–552 | **wrong** membership (Tofino's 4 omitted; the six named hold 31) |

### wet#118 "More stations" paragraph and the #142 line

| claim | report line | verdict |
|---|---|---|
| #123 surveyed against a bar set before any source was checked | research :22 | holds |
| the province's network is the one harvest candidate; 110 stations | :29, :66 | holds |
| Tool third-party: 35 more, 29 beyond, no redistribution licence | :65–74, :80 | holds |
| Water Hub preliminary, scripted reader needs consent | — | [desk M]/[S] |
| two USGS gauges usable only as held-out tests | :63, :74 | holds |
| Skeena Knowledge Trust holds no discharge of its own | — | [desk M] |
| UNBC holds no discharge of its own | :43, :158 | **wrong** |
| DataStream needs an API key | — | [S]/[desk M] |
| "BC Hydro releases data only by request" (#140) | — | **wrong** quantifier (archive by request; 4-day public page) |
| Bulkley: two provincial stations with two window-years each | rows 08EE0001/2 | holds |
| component line "#142 … After #123" | — | holds (no number) |

Rows marked wrong: 17, counting each claim once per surface (research 10, README 1, CLAUDE.md 1, #142 3, #118 2). That is 10 findings, because some claims appear on more than one surface. No row rests on a report line whose selector I did not read.
