# Findings — Backlog move 7: Scenarios and coverage, after the channel-scale pilot (#169)

## Issue context

**If we do it:** scenario period means and the coverage-and-comparison map are built on whichever PCIC product move 6's pilot chooses. **If we never do:** wet publishes 1981–2010 normals only, and other groups' products stay unscored by watershed group.

Order: `planning/backlog.md`, move 7. Move 6's verdict has landed (#168, `research/pcic_channel_scale.md`). Run `/planning-init <this issue>`.

## What move 6 decided

- **By domain:** CMIP6 routed through fwapg's crosswalk (`MODEL=<GCM> SCENARIO="historical, ssp245"` and so on) on the coast, Columbia and Peace. CMIP5 gridded in the Fraser, where the CMIP6 runs' 1981–2010 flow sits a median 7.3 % of observed below PNWNAmet's.
- **First check:** whether each CMIP6 run's outlets with series are PNWNAmet's, which fwapg's crosswalk needs. TaiESM1 has no coast series at any outlet scored.
- **CMIP5 in the Fraser:** score the runs by the pilot's rule 2 against PNWNAmet at the same gauges before building on them. Take 2070–2099, not 2071–2100: the CMIP5 runs end 2099-12-31. Check each run's calendar first: HadGEM2-ES runs natively on 360 days, and `wet_pcic_index()` assumes a standard calendar. The CMIP5 runs carry no glacier model, so their change at glacier-fed sites lacks glacier retreat.
- **MBCn corrects each SSP on its own:** the historical half of `historical, ssp585` is not `historical, ssp245`'s, so take each change against the same scenario's 1981–2010.
- **Cost:** a whole CMIP6 run is about 17 GiB of series.

## Batch 10: scenarios and coverage

**Why here:** both rescope from #9's verdict, and both need the coverage of each PCIC product per watershed group.

**Touches:** new scenario readers and scripts, a dataset ID and crate schema if scenarios are published, a coverage report and map.

**Decided at the gate:** CMIP6 channel-scale, gridded CMIP5 or both by domain; whether scenarios are published as a new dataset.

| issue | title |
|---|---|
| #4 | Scenario period means from PCIC CMIP5 runs (and CMIP6 check) |
| #5 | Coverage and comparison: our estimate vs PCIC, BC Water Tool and others |

The body's table names #4 and #5. `planning/backlog.md` (the pass of 2026-11-25) also places #205 in batch 10, and #205's body says so; its row was added to #169's table when this plan was parked, so the member re-check reads it.

## Explored on 2026-11-25, at cbeb3489

### The members

- **#4** asks for period means for 2011–2040, 2041–2070 and 2071–2100 (to 2099) per run, annual and monthly, as absolute values and as changes against each run's own baseline, with an ensemble median and range. Its one comment (2026-09-26) only reports that basin-scale accumulation exists (`scripts/mad_basin.R` as the template); it asks for nothing.
- **#5** asks for a coverage map per watershed group and for each available product scored against ours and HYDAT, with a disagreement log. Already scored by tracked reports: routed PCIC (`pcic_routed_compare`, `gauge_monthly_compare`), PCIC's gridded run through fwapg (`research/water_balance_method.md` §0), WALLY (`wally_compare`), DFO's Fraser table as context. Not scored anywhere: GEOGLOWS v2, TerraClimate runoff, the 1961–1990 isolines, the BC Water Tool's modelled estimates (not released; contact goes through the owner). No comments.
- **#205** asks for `research/pcic_hydrology.md` re-read claim by claim and dated. No comments.
- **#9** (closed, the pilot) holds the verdict this move starts from.

### What a CMIP6 run costs, and who builds it

- fwapg's job (`extras/pcic_crosswalk/pcic_crosswalk.sh` on the fork's integration branch, read at 137fd69) builds one run at a time: a model, a scenario and the years averaged. It fetches every outlet's whole series (500 outlets a request), keeps the NetCDF, and routes a period in about an hour. Its README: "Runs share the staging tables: run them one at a time"; "the CMIP6 runs' outlets are unmeasured: 3 of PNWNAmet's 28 missing outlets were also missing for CNRM-ESM2-1"; a run whose crosswalk differs from the stored one is refused; more than 100 outlets with no series stops the job. So TaiESM1, with no series on the coast (14,605 outlets), cannot run as the job stands.
- 18 runs (9 GCMs × 2 SSPs) × four periods is 72 period builds and about 306 GiB of kept series at the pilot's measured 0.36 MiB an outlet. That is fwapg's work, in another repository, and not one pull request here.
- The local database's `pcic.runs` holds PNWNAmet historical 1951–2012 and 1981–2010 only; `pcic.fwa_crosswalk` has 48,716 outlets, 38,146 placed, 28 `no_series`; `pcic.segment_weights` covers 199 of the 246 watershed groups.

### hydromosaic's API

`https://services.pacificclimate.org/hydromosaic/openapi.json` (version 0.1) lists: `POST /bulk-downloads`, `GET /outlets`, `/outlets/{subid}`, `/outlets/{subid}/timeseries`, `/outlets/{subid}/timeseries/{ts_id}` and its `/data`, `/variables`, `/variables/{v_id}`. There is no per-run list of outlets, and the bulk request takes no date range. So "which outlets have a series for this run" is either one listing per outlet (the pilot's log: 247 listings, 34 s, 5.5 MiB) or the whole run's series.

### The gridded runs' time axis

Read from OPeNDAP on 2026-11-25:

| run | units | calendar | days |
|---|---|---|---|
| `HadGEM2-ES_rcp85_r1i1p1` RUNOFF | `days since 1945-1-1 00:00:00` | `standard` | 56,613 |
| `CanESM2_rcp85_r1i1p1` RUNOFF | `days since 1945-1-1 00:00:00` | `standard` | 56,613 |
| `TPS_gridded_obs_init` RUNOFF | `days since 1945-1-1 00:00:00` | `standard` | not read |

56,613 is every day from 1945-01-01 to 2099-12-31 on the standard calendar (155 years and 38 leap days). So the file PCIC serves for HadGEM2-ES is not on 360 days, whatever the GCM ran on, and `wet_pcic_index()`'s day offsets hold for it. The other ten CMIP5 runs were not read.

Commands (each `curl -s -L -A wet-plan-probe`):

```
https://services.pacificclimate.org/data/hydro_model_out/allwsbc.<run>.1945to2099.RUNOFF.nc.das
https://services.pacificclimate.org/data/hydro_model_out/allwsbc.<run>.1945to2099.RUNOFF.nc.dds
https://services.pacificclimate.org/hydromosaic/openapi.json
https://services.pacificclimate.org/robots.txt
https://beehive.pacificclimate.org/robots.txt
```

### Access: robots.txt and a rate limit

- `services.pacificclimate.org/robots.txt` (read 2026-11-25), for every user agent: `Disallow: /data/` under the comment "PDP data backend (heavily rate-limited, large downloads)", `Disallow: /bbox-server`, `Disallow: /hydromosaic`, and other API paths; its header says the policy is to "let crawlers index the app landing pages, keep them off data/API/tile endpoints that are expensive or rate-limited". `/portal/` is not listed.
- `beehive.pacificclimate.org/robots.txt`: `Disallow: /` for every agent.
- The fifth metadata request to `/data/` within a few seconds (TPS's `.das`) answered **429**, and the sixth (its `.dds`) returned nothing; the `.das` a few minutes later answered 200. The 429's headers were not kept, so whether it carries `Retry-After` is not known.
- Requests this session made to disallowed paths, all before the robots.txt was read: `openapi.json` twice and two 404s under `/hydromosaic`, and seven `.das`/`.dds` under `/data/`. None after.
- `wet_pcic_fetch()` uses `download.file()`, which reports no HTTP status, so a 429 would surface as "not NetCDF". The pilot's `h_curl()` reads the status but does not wait on a 429.
- The pilot's archive and `research/pcic_channel_scale.md` do not mention robots.txt. `research/station_sources.md` holds other hosts to theirs and fetched nothing where an API was disallowed.

### What is cached where the pilot ran

- Gridded PNWNAmet RUNOFF and BASEFLOW, 1981–2010, one file a year for three basin boxes (the Fraser's are 23.3 MiB each; 21,648 cells), under the main checkout's `data/pcic/`. No CMIP5 file.
- The pilot's hydromosaic cache (`data/channel_scale/raw/`, 845 MB: 346 NetCDF, 247 listings, split and missing markers) and its fetch log (`data/logs/168/`).
- The glacier cover per watershed from the small-basin work (`data/wb_small_basin/glacier_ws_*.rds`).
- The CMIP5 check's fetch, sized from the cached Fraser files: 6 runs × 2 variables × 30 years = 360 files, about 8.4 GiB, and 48 more (1.1 GiB) for RCP 8.5's four years. All four periods for 12 runs would be about 66 GiB.

### Code the plan builds on

- `R/wet_pcic_url.R`, `wet_pcic_index.R`, `wet_pcic_fetch.R`, `wet_pcic_annual.R`, `wet_runoff_annual.R`: the gridded readers. `wet_pcic_annual()` gives one annual layer; nothing gives months.
- `scripts/channel_scale_pilot.R`: the rule block and its registration finder (lines 38–186), `domain_of()` (206), `h_curl()`, `fetch_log()`, `listing()` (294–332), the scored gauges and their outlets (265–291), rule 2 (771–789), and wet's accumulation over the Fraser (519–534: `wet_ws_fetch(conn, "100")`, `wet_upstream_irregular()`, centroid sampling, `wet_upstream_mean(ws, cen, "total", irregular_pairs = irr)`, `wet_mm_to_m3s()`).
- `data/checks/channel_scale_pilot_20260717.txt`: the Domains table (Fraser: 87 gauges, 73 with an outlet, rule 2 0.082 and −0.036) and the sites' accumulation column.
- `inst/vignette-data/monthly_values.rds`: 315 gauges with `watershed_group_code`, `obs_mm`, `wb_mm`, `routed_mm` per month.
- `scripts/vignette_data_lib.R` (`vd_commit()`, `vd_published()`), `scripts/vignette_map_lib.R` (`vm_places()`, `vm_write()`), `scripts/wb_map.R` (a tracked research map drawn with tmap and gq), `inst/cartography/wet_segment.csv` (the custom registry's columns).
- `research/discharge_publish.md`: the `scenario` / `forcing` / `source` keys were sized for hydromosaic's runs; `period` is a column; `pick` across several periods is "undecided until one is built".

### First-party packages

The first-party stale-package check on 2026-11-25: `gq` 0.25.0 and `crate` 0.21.0 current; `fresh` 0.56.0 behind 0.57.0 and `cd` 0.6.11 behind 0.6.13. This plan uses neither stale one: the map takes its polygons, outline and river labels by its own ordered queries and its rivers from the bundled layer, not through fresh's fetchers.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| HTTP 429 from `services.pacificclimate.org/data/` on the fifth metadata request in a few seconds | Waited; the same request answered 200. The plan's fetches go one at a time and wait on a 429 |

## What the plan review found (2026-11-25)

The review and each finding's verdict are in `review-plan.md`. Facts it added, each checked against the file it cites:

- `wet_upstream_means()` divides by covered area (`R/wet_upstream_means.R`, "with `denom = \"covered\"`"); the pilot's accumulation used `wet_upstream_mean(..., "total")`. The two agree only where coverage is 1.
- `wet_mm_to_m3s()` defaults to 365 days and the pilot used the default; the pilot's observed flow is at 365.25.
- The pilot's parity values are in its tracked report's sites table, column "wet acc", two decimals (salmon 20.45, quesnel 134.18, hope 2476.28, lillooet 99.58), keyed by site id; the sites' segments are in `scripts/channel_scale_sites.csv` (08MF005 is not among the scored gauges' stations file).
- fwapg's notes already say CNRM-ESM2-1 has series at outlets where PNWNAmet has none, so that run's crosswalk would differ from the stored one.
- `scripts/discharge_publish_own.R` is the list both publish guards exclude; a changed file under `R/` or `scripts/` left off it forces a segment rebuild.
- `scripts/wb_term_diagnose.R` hashes `R/wet_pcic_fetch.R` (and `wet_pcic_annual.R`, `wet_runoff_annual.R`) into its cache key.
- `inst/vignette-data/segment_map.rds`'s rivers carry `class`, `order_band` and `segments`, no name and no `blue_line_key`; no bundle holds the watershed group polygons; `vm_places()` is a live WFS query.
- The segment-discharge article's gauge error is a mean absolute percent error (`mae_of()`), not a median.
- `NEWS.md` is touched only by release commits.

## Phase 1 re-read (2026-11-25, answer (a): no request to a disallowed path)

Commands, each `curl -s -L -A wet-research`, one at a time:

```
https://{services,data,beehive,www}.pacificclimate.org/robots.txt, https://www.uvic.ca/robots.txt
https://services.pacificclimate.org/portal/hydro_model_out/catalog/catalog.json   # md5 3c9718ada10337e5fbbea76ecb859f0d
https://www.uvic.ca/pcic/data-analysis-tools/data-portal/{,hydrology-gridded,hydrology-station-data,hydrology-vector,statistically-downscaled-scenarios}/index.php
https://www.uvic.ca/pcic/data-analysis-tools/analysis-tools/index.php
https://www.uvic.ca/pcic/about/terms-of-use/index.php
curl -w '%{http_code} %{redirect_url}' https://data.pacificclimate.org/{robots.txt,portal/.../catalog.json}   # 301 to services.
ncdump -h <main checkout>/data/pcic/TPS_gridded_obs_init_RUNOFF_t13149-13513_y120-242_x192-367.nc
git -C fwapg show origin/{main,newgraph}:extras/discharge/discharge.sh   # curl -o without -L, old host
```

- Catalog: 169 datasets = 13 runs × 13 variables; scenario ids end `_columbia`, PNWNAmet's `_nwna`; PNWNAmet's model `VICGL-RGM-HydroConductor`, span 19450101-20121231; every file name `1945to2099`. No CMIP6 run.
- `/portal/` and `/chyp` are not disallowed; `www.uvic.ca` disallows only search queries and two unrelated paths.
- Data portals page: data "publicly available with an open license" (none named). Terms of use page covers the website only.
- The PCIC note: drafted for the owner outside this repository, addressed to PCIC's hydrology lead as a new message, as the earlier correspondence advised. Not sent.
- #205's body edited to the four claims still unread; it stays open.
