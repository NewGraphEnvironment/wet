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

## Errors Encountered

| Error | Resolution |
|-------|------------|
