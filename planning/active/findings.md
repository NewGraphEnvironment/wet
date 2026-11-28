# Findings — Backlog move 19: Small-stream logger records into wet (#235)

## Issue context

**If we do it:** small-stream water temperature records load in wet beside the federal gauges, so a prediction can be compared with records from the kind of stream most reaches are. **If we never do:** every comparison comes from year-round gauges, mostly on rivers.

Order: `planning/backlog.md`, move 19. Run `/planning-init <this issue>`: one phase, one PR. It can start now.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 19, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

## Batch 21: small-stream logger records

**Why here:** one inventory, one reader shape, one placement on the network and one logger QA serve every series (#215); each new series after the first is then a data edit.

**Touches:** a new reader under `R/` with its tests, a registry under `inst/extdata/`, a check report under `data/checks/`, `research/station_water_temperature.md` (all named at the plan gate).

**Decided at the gate:** whether loggers are another source of `wet_temp_daily()` or a sibling reader; which series goes first, starting from records already public under an open licence; a series someone else holds comes in only with its holder's agreement, asked through the owner; whether a catalogue that refuses automated clients is read at all (the owner's call).

| issue | title |
|---|---|
| #215 | Small-stream logger temperature in wet: Nechako, Upper Bulkley and Weigert Creek records as a second scoring pool |


### #215 (the batch's one member)

**If we do it:** the baseline and any network model are scored on small streams as well as rivers, and small streams are where most reaches with no station are. **If we never do:** every score comes from year-round gauges, mostly on rivers, and says little about the creeks the product is for.

## Problem

`wet_temp_daily()` reads ECCC hydrometric gauges only. The fill's validation says what that leaves out: its truth set is "year-round ECCC gauges, mostly rivers, not seasonal creek loggers", and "no logger series was held out" ([`research/station_temperature_fill.md`](https://github.com/NewGraphEnvironment/wet/blob/main/research/station_temperature_fill.md)). These logger records are known and none is in wet:

- **Nechako**, UNBC Northern Hydrometeorology Group, on Zenodo. Two records to reconcile: `10.5281/zenodo.6426023` (the sites the 2024 Nechako network model used) and `10.5281/zenodo.15053907` (sub-hourly, 32 sites, CC BY 4.0).
- **Upper Bulkley River** water temperature monitoring program. Three places hold it, and they have not been reconciled with one another:
  - a public dashboard by the Skeena Knowledge Trust: [UBR Water Temperature Monitoring Dashboard](https://public.tableau.com/app/profile/skeena.knowledge.trust/viz/UBRWaterTemperatureMonitoringDashboardDraft/UBRWaterTemp_Dashboard) (Tableau). To inventory: the sites and years it serves, and whether its data can be pulled programmatically;
  - the program's [2016–21 data report and appendices](https://data.skeenasalmon.info/dataset/e0e8cb6b-1bc1-45d5-9d51-799c4c5d7d1e) on the Skeena Salmon Data Catalogue;
  - logger datasets on the same catalogue: [Buck Creek above Bridge 1](https://data.skeenasalmon.info/dataset/water-temperature-monitoring-data-buck-creek-above-bridge), [McQuarrie Creek above Hwy 16](https://data.skeenasalmon.info/dataset/water-temperature-monitoring-data-lower-mcquarrie-creek) and [McQuarrie Creek above North Rd](https://data.skeenasalmon.info/dataset/water-temperature-monitoring-data-mcquarrie-creek-at-north-rd). The catalogue was searched for discharge only ([`research/station_sources.md`](https://github.com/NewGraphEnvironment/wet/blob/main/research/station_sources.md)); a search for temperature has not been run.
- **Other Skeena loggers.** Temperature loggers are also run through the Pacific Salmon Commission, the Skeena Fisheries Commission and the Gitksan Watershed Authorities, among others. Their sites, years and terms are not known to us yet; the inventory below starts with what is already public, and each of these is asked for as the first bullet of the approach says.
- **Weigert Creek** loggers (Elk River).

## Proposed approach

- **Inventory first:** for each series its holder, licence, sites, years, time step and where the files live. A series someone else holds comes in only with its holder's agreement and under its licence; one that cannot be republished is read locally and left out of anything published.
- **Read into the `wet_temp_*` shape:** daily mean, minimum and maximum per site and day, with the source named. Whether that is another source of `wet_temp_daily()` or a sibling reader is settled in this issue's plan.
- **Place each site on the network:** blue line key and measure on the Freshwater Atlas, and its segment on the main-flow tree.
- **QA for loggers,** which gauges do not need: a logger out of the water or reading air, a stuck value, a deployment's first and last partial days.
- **Count what can be scored:** complete growing seasons under `wet_temp_gsdd()`'s rule, and seasons that need only their shoulders filled.

## Out of scope

- Scoring the baseline on these records. That is a second pool for #213 and gets its own issue once they are in; nothing scores on them yet.
- New field deployments.

## Done when

- Each series has a row in `research/station_water_temperature.md` with its holder, licence and counts.
- Each series that may be read loads in the `wet_temp_*` shape and passes the logger QA, with a check report under `data/checks/`.
- The count of sites and complete growing seasons per series is stated.

Relates to #214, #213



## Read at planning (2026-11-26)

- **Zenodo, Nechako (UNBC Northern Hydrometeorology Group), API metadata only.** 10.5281/zenodo.6426024 (concept
  6426023): "Sub-hourly water temperature data ... across the Nechako Watershed, 2019-2021", published 2022-04-08,
  CC BY 4.0, files `NHG Data ReadMe.txt` (8,297 B), `Data.zip` (3,092,827 B), `Logger Locations in Nechako
  Watershed.png`. 10.5281/zenodo.15053907 (concept 15053906): the same title for 2019-2024, published 2025-03-19,
  CC BY 4.0, files `ReadMe.txt` (5,853 B), `01_Data.zip` (13,830,401 B), `02_SupplementaryMaterials.zip`
  (23,591,136 B). Separate concepts, so Zenodo does not mark one as a version of the other.
- **Skeena Salmon Data Catalogue, CKAN.** `package_search?q=temperature` returned 212 datasets. Logger series among
  them: `upper-bulkley-water-temperature-monitoring-data` (DFO Pacific Region, ODC PDDL, modified 2026-10-06; hourly
  aggregated CSV 56 MB, hourly by site ZIP, raw original-format ZIP 21 MB, site coordinates CSV, the 2016-21 data
  report and appendices, the Tableau dashboard link, deployment forms) and `morice-temperature-monitoring` (Morice
  Water Monitoring Trust, CC non-commercial, seven loggers, July to September 2023). The Buck Creek dataset slug
  #215 links was not found under that name. robots.txt: `User-agent: *` `Allow: /` with
  `Content-Signal: search=yes,ai-train=no,use=reference`; `ClaudeBot`, `anthropic-ai`, `Claude-Web` and other AI
  crawlers disallowed by name. Five requests were made before the robots file was read; none after (Open decision 1).
- `R/wet_hakai.R` (#192, merged while this plan was drafted) is the pattern for a published package: manifest with url,
  fetch at md5, private backup.

## Inventory (Phase 1, 2026-11-27)

Requests from this session: Zenodo's robots.txt (`/search`, `/api`, `/records/*/preview` disallowed;
`/api/records/*/files` allowed; crawl-delay 10), both records' `/api/records/<id>/files` listings, and the five files
below from `/records/<id>/files/<name>?download=1`, 10 s apart, user agent `wet`; every md5 equals Zenodo's
`checksum`. Tableau Public's robots.txt (crawl-delay 10, nothing relevant disallowed) and one read of the workbook's
public metadata (`/profile/api/workbook/<name>`). Two web searches for Weigert Creek. No request to the Skeena
catalogue (Decision 1).

| series | holder | licence | sites | years | step | read? |
|---|---|---|---|---|---|---|
| Nechako 2019–2024, 10.5281/zenodo.15053907 | UNBC Northern Hydrometeorology Group (PI S. J. Déry) | CC BY 4.0 | 32 | 2019-06-27 to 2024-12-15 | 15 min | yes |
| Nechako 2019–2021, 10.5281/zenodo.6426024 | same | CC BY 4.0 | 24, all also in the later record | 2019–2021 | 15 min | yes, compared only |
| Upper Bulkley River monitoring | DFO Pacific Region (Skeena Salmon Data Catalogue) | ODC PDDL | not counted (catalogue not read) | from 2016 | hourly | own issue, owner's hand fetch (Decision 1) |
| Upper Bulkley dashboard (Tableau Public) | Skeena Knowledge Trust | none stated | not counted | not counted | — | no: a view of the DFO program (sheets include "Full Dataset" and "Site Info DB"; updated 2026-09-29); read the program's catalogue files instead |
| Morice temperature monitoring | Morice Water Monitoring Trust (catalogue) | CC non-commercial | 7 | Jul–Sep 2023 | — | with the Upper Bulkley issue (same catalogue, same hand fetch); not republishable commercially |
| Weigert Creek (Elk River) | not found | — | — | — | — | no published record found; the Elk River Alliance's tributary loggers are published on the Columbia Basin Water Hub (CanWIN), with no Weigert site among the results read |
| Skeena logger networks (Pacific Salmon Commission, Skeena Fisheries Commission, Gitksan Watershed Authorities) | as named | — | — | — | — | not published; not read (Decision 3) |

### Nechako, read from the files

- **Later record (15053907).** `01_Data.zip` holds 32 CSVs, `01_Data/<code>_<CamelName>.csv`, columns
  `station_code`, `timestamp (UTC)` (`yyyy-mm-dd HH:MM`), `wtmp (°C)` (2 decimals), `wtmp_flag`. 3,850,424 rows,
  no duplicate code-time, every timestamp on :00/:15/:30/:45. Flags: P 3,083,266; M 488,595 (temperature `NA`);
  B 239,843 (x ≤ 0, icing); A 28,970 and C 90 (averaged from several sensors; 01FW002, 01FW005, 01FW013, 01FW024,
  01NE004); S 9,298 (spike or dewatering); V 270 (site visit); E 92 (outside sensor limits; minimum −22.74 °C).
  Temperatures −22.74 to 30.76 °C.
- **Coordinates and names:** `02_SupplementaryMaterials.zip/02_SupplementaryMaterials/Site_Metadata.txt`, tab
  delimited, CRLF, Latin-1, each site name followed by a stray byte (0xA0); columns code, name, lat, lon (WGS84, 4
  decimals), elevation, record start, end. `01FW017` carries an asterisk in its name, which neither the ReadMe nor its site PDF explains.
- **Codes:** `01FWnnn` (25), `01NEnnn` (6), `02FW002` (Ness Lake). Lake sites: Nadina Lake (01FW009) and Ness Lake
  (02FW002), and Cheslatta Lake above Sather Creek (01FW003) and Skins Lake Spillway (01FW010) sit at lake outlets.
- **Earlier record (6426024).** `Data.zip` holds 24 CSVs named by site (`Data/<Site Name>.csv`), columns
  `DateTime (UTC)` (`yyyy-mm-dd HH:MM:SS`), `Temperature (C)`, `Flag`. Coordinates are in `NHG Data ReadMe.txt` (DMS)
  with site visits; three-letter codes (CNR, CSC, ...). Every site matches a later site by name and coordinates
  (Kuzkwa "Terrezon"/"Tezzeron", Whitesail Creek/Whitesail Middle Creek). Disagreements: Stellako (SFL) is given at
  54.0822, −125.0053, Endako's position, where the later record puts it at 54.0441, −124.9247; elevations differ at
  Chilako above Nechako (618/700 m) and Necoslie (586/685 m). The ReadMe also records dewatered spans and a logger
  floating in air at Rhine Creek before 2021-07-21.
- **Time zone:** UTC in both, so `utc_offset = 0`, `dst = FALSE` for every Nechako site; local standard time days
  take −8 h (Pacific).
- **Formats:** CSV only, so no readxl.
- **Consequence for the reader:** every earlier site is in the later record, so every site's days come from the later
  record; the earlier record enters only the check report's comparison.

## Plan corrections (Phase 2, 2026-11-27)

- **Clock and day offsets replace `utc_offset`, `dst`, `tz`.** Both Nechako records stamp readings in UTC, so the
  registry carries `clock_offset` (hours the timestamps run ahead of UTC; 0) and `day_offset` (the local standard
  time of the days, the nearest HYDAT station's `standard_offset` in `tidyhydat::allstations`; −8 at every site).
  No series read keeps daylight saving, so `dst` and `tz` are not built; a series that needs them adds them.
- **Sub-drainage from the nearest HYDAT station** (the Water Tool registry's rule) puts three sites on the lower
  Nechako in 08K: Nechako River at Miworth (01FW005), McMillan Creek above Nechako River (01FW024) and Nechako River at
  Pulpmill Road (01FW025), whose nearest gauges are on the Fraser at Prince George. They pool with 08K in
  `wet_temp_fill()`; the report lists each site's sub-drainage. (An earlier draft of this note named Ness Lake; the
  registry gives it 08J.)
- **The ECCC archive lists 342 stations** on 2026-11-27 (306 in `data/checks/temp_coverage_report.txt`, 2026-10-06);
  no Nechako id is in it.
- **The earlier record's coordinates** are parsed from its ReadMe's DMS; every site lies within 0.01 km of its later
  match except Stellako (6.76 km, the earlier record giving Endako's position), allowed by name in the script.
- **Registry columns added:** `elevation_m`, `nearest_hydat`, and `prior_record`, `prior_code`, `prior_member` (the
  earlier record's file for the same site, for the comparison); `eccc_km` names the distance to `nearest_eccc`.
- **Backup:** both records' files and `.md5`s at `s3://fresh-bc/temp_loggers/nhg/<record>/` (2026-11-27, each
  object's size and ETag checked). A second run of the script wrote the three tracked files byte for byte.

## Phases 4 and 5 (2026-11-27)

- **Placement:** 28 of 32 sites placed, 24 by name and 4 by the nearest leg (Glacier Creek, Otter Creek below Finger
  Lake on FWA's Finger Creek, Nadina River above Nadina Lake, Whitesail Middle Creek: the last three on unnamed or
  differently named FWA streams); all 28 on the main-flow tree. Unplaced: the four lake sites (Cheslatta Lake, Nadina
  Lake, Skins Lake Spillway, Ness Lake), no candidate on the named stream within 100 m.
- **Two sites sit beside ECCC temperature stations:** Skins Lake Spillway 0.46 km from 08JA023, Nadina Lake 0.50 km
  from 08JB007.
- **The earlier record's clock:** its files stamp an hour twice at the autumn and spring clock changes, and at
  Whitesail (WTL) and Chedakuz (CNR) its readings match the later record better with the stamp moved an hour, so its
  "UTC" carries a daylight-saving shift over part of the record; days differ by up to 0.51 °C there and at most 0.08 °C
  elsewhere. The later record has no repeated stamp.
- **Counts:** 34,017 of 34,778 days kept (650 by the hour rule, 100 deployment ends, 11 air days, no stuck run);
  30 complete growing seasons at 22 sites and 24 seasons needing only shoulders at 18 sites, far above the plan's
  "near zero" expectation; 31 of 32 sites reach 365 kept days.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `aws: Unknown options` on `NHG Data ReadMe.txt` | `system2()` passes arguments unquoted: `shQuote()` them |
| `prior_read`: `!anyDuplicated(time)` | the earlier record repeats an hour at clock changes: both copies left out and counted |
