# PCIC hydrologic model output: what exists, where, and on what terms

**Verified:** 2026-11-25, except where a claim says it was read only under `/data/` (2026-09-25; see "Access and robots.txt"); per-year section 2026-10-27 · **Issues:** #1 (found), #3, #4, #5, #6, #7, #9, #168 (the pilot), #169 and #205 (this re-read) · **Produced by:** on 2026-11-25, `curl -L -A wet-research` of each host's `/robots.txt`, of the gridded catalog (`/portal/hydro_model_out/catalog/catalog.json`, md5 `3c9718ad…`) and of PCIC's data portal pages on `www.uvic.ca/pcic/` (gridded, station, channel-scale, downscaled scenarios, analysis tools, terms of use), `ncdump -h` of the cached PNWNAmet subsets under `data/pcic/`, and two RUNOFF `.das`/`.dds` reads (HadGEM2-ES and CanESM2, RCP 8.5) made before the robots.txt was read; before that, the 2026-09-25 commands in `planning/archive/2026-09-issue-1-scope-discharge/`. The 2026-11-25 commands are in the #169 archive's `findings.md`.

## Hosts

- The data service moved from `data.pacificclimate.org` to **`services.pacificclimate.org`**. The old host answers 301 to the same path on the new one (2026-11-25, on `/robots.txt` and the catalog), so any client must follow redirects. `curl -o` without `-L` saves the redirect page: fwapg's `extras/discharge/discharge.sh` still requests the old host without `-L` (on fwapg's `main` and `newgraph`, 2026-11-25).
- Gridded catalog: `https://services.pacificclimate.org/portal/hydro_model_out/catalog/catalog.json`, 169 datasets (13 runs × 13 variables), each an OPeNDAP URL (2026-11-25).
- OPeNDAP: `https://services.pacificclimate.org/data/hydro_model_out/<file>.nc`, with suffixes `.das`, `.dds`, `.ascii?`, and `.nc?VAR[t0:t1][y0:y1][x0:x1]` for a NetCDF subset. `wet_pcic_url()` / `wet_pcic_fetch()` implement this. robots.txt disallows `/data/` (below), so this was not re-read beyond the four metadata reads of 2026-11-25.

## Gridded runs (`hydro_model_out`)

Runs, models, spans, variables and file names from the catalog, 2026-11-25:

| Run | Model | Forcing | Span | Domain |
|---|---|---|---|---|
| `TPS_gridded_obs_init` (catalog: `PNWNAmet`) | VICGL-RGM-HydroConductor (glacier dynamics) | PNWNAmet (observed) | 1945-01-01 to 2012-12-31 | catalog `nwna`; values in Peace, Fraser, Columbia |
| 12 × `<GCM>_<rcp>_<member>` | VICGL (no glacier model) | BCCAQv2-downscaled CMIP5 | 1945-01-01 to 2099-12-31 | catalog `columbia`; the files' attribute reads "COLUMBIA+PEACE+FRASER" (2026-09-25, `/data/`) |

- **GCMs:** ACCESS1-0 r1i1p1, CanESM2 r1i1p1, CCSM4 r2i1p1, CNRM-CM5 r1i1p1, HadGEM2-ES r1i1p1, MPI-ESM-LR r3i1p1, each at RCP 4.5 and RCP 8.5. The portal page says the six were chosen to span a wide range of future climate extremes.
- **File names all say `1945to2099`** regardless of span.
- **Variables:** BASEFLOW, RUNOFF, EVAP, GLAC_AREA, GLAC_MBAL, GLAC_OUTFLOW, PET_NATVEG, PREC, RAINF, SNOW_MELT, SOIL_MOIST_TOT, SWE, TRANSP_VEG, the same 13 for every run.
- **Grid:** 0.0625°. 496 lon × 367 lat, centres at lon −139.96875 + 0.0625·i and lat 41.09375 + 0.0625·j (both ascending). Only the three basins hold values. Read 2026-09-25 from `/data/`; not re-read.
- **Time:** daily, `days since 1945-1-1 00:00:00`, standard calendar. On 2026-11-25 the cached PNWNAmet subsets' headers read so, and HadGEM2-ES and CanESM2 RCP 8.5 RUNOFF each read 56,613 days on the standard calendar, every day from 1945-01-01 to 2099-12-31: the file PCIC serves for HadGEM2-ES is not on 360 days, whatever calendar that GCM ran on. The other ten CMIP5 runs were checked on 2026-09-25 (the historical run and four scenario runs) or not at all; `wet_pcic_fetch()` refuses a download whose days are not the ones asked for (#169). Index = day offset, so 1981-01-01 is 13149 and 2010-12-31 is 24105.
- **Units:** mm (per day). Packed shorts with `scale_factor`/`add_offset` and `_FillValue` −32767 (the cached PNWNAmet headers, 2026-11-25); terra and cdo unpack them. The portal page says values of 0.0009 or less should be treated as zero; an all-zero day unpacks to about −2.8e-6 mm (packing floor).
- **Calibration:** 1985–2005 against "Thin plate spline w/ ClimateWNA" (the cached PNWNAmet headers' `model_cal__*` attributes, 2026-11-25).
- **Structure differs between historical and scenario runs** (RGM vs none). Take climate deltas within one run, not scenario minus historical; the portal page says the same ("compare the future to the past within the same GCM-RCP scenario").
- **The gridded portal holds no CMIP6 run** (the catalog, 2026-11-25). PCIC's CMIP6 hydrology is the channel-scale product (below), on reach and lake outlets, not on this grid.

## Other PCIC products

Each from its portal page on `www.uvic.ca/pcic/`, 2026-11-25, unless dated otherwise.

- **`hydro_stn_cmip5`** ("Station hydrologic model output"): routed (RVIC) daily m³/s at 190 locations in the Peace, Fraser and Columbia, WSC and USGS gauges and dam sites, naturalized where flow is regulated. The PNWNAmet run (1945–2012) plus the 12 CMIP5 runs (1945–2099), one CSV per station. Cited as February 2020.
- **Salmon Climate Impacts Portal:** projected changes to streamflow and freshwater temperature for freshwater salmon ecosystems in the BC coastal domain (the analysis-tools page). From the 2026-09-25 read, not re-read: VIC-GL coupled to dynWat, released March 2024, 10 streamflow and water-temperature hazard indices, CMIP5, periods historical/2020s/2050s/2080s, by watershed group, conservation unit or custom outlet.
- **Channel-scale: "VIC-GL-Raven MBCn CMIP6: Vector Hydrologic Model Output"** (cited as May 2026).
  - Portal: `https://services.pacificclimate.org/chyp` (robots.txt allows it). Docs: `uvic.ca/pcic/data-analysis-tools/data-portal/hydrology-vector/`.
  - Model: VIC-GL, coupled to a glacier model, routed by Raven on a vector network of reaches (lines) and lakes (polygons).
  - Variables: daily streamflow (or lake outflow), water temperature and saturated dissolved oxygen, each at the outlet of a reach or lake, naturalized where flow is regulated.
  - Runs: historical driven by PNWNAmet, plus 9 CMIP6 GCMs × SSP2-4.5/SSP5-8.5 (18 projections, 2013–2100), MBCn bias-corrected against PNWNAmet; the whole set covers 1950–2100.
  - Downloads: CSV per feature, NetCDF for upstream/downstream networks.
  - The portal loads `/chyp/fwa_index.json`, a place-name search index keyed on FWA `blue_line_key` and lake keys (2,391 streams, 4,967 lakes; 2026-11-23). It covers names province-wide, so it does **not** show where there is model output.
  - **From PCIC correspondence, 2026-07-20:**
    - The portal is designed for specific sites, not domain-wide extraction.
    - The network is based on the FWA, with "subtle differences … necessary for consistently routing flow", so domain-wide use meets many model/FWA edge cases.
    - PCIC suggests piloting a few representative sites first, then possibly scaling up with their support (#9).
    - The Peace and Upper Columbia were to be added "in the next year or so", the coastal domain and the Fraser being covered (Feb 2026 Update). By 2026-11-23 hydromosaic listed series in all four (the pilot, below).
  - Recommended use: compare PNWNAmet-driven runs with observations, and take climate impacts within one model-scenario combination.
  - **The pilot (#168, 2026-11-23; `pcic_channel_scale.md`):** the portal's product is, as far as can be traced, hydromosaic's series, the run fwapg's crosswalk places on the FWA and wet publishes as routed PCIC; the crosswalk reproduces PCIC's PNWNAmet outlet series at every scored gauge with an outlet. At the scored gauges' outlets hydromosaic lists CMIP6 streamflow in the Peace and Columbia too, and has no TaiESM1 series at any coast outlet scored. The CMIP6 runs' 1981–2010 flow is close to PNWNAmet's except in the Fraser, so move 7 builds on CMIP6 routed outside the Fraser and CMIP5 gridded in it.
- **Statistically downscaled climate** (not hydrology), Canada-wide at about 10 km, 1950–2100: CanDCS-U5 (27 CMIP5 GCMs, BCCAQv2), CanDCS-U6 and CanDCS-M6 (26 CMIP6 GCMs; BCCAQv2 and MBCn), and a 10-member CanESM5 ensemble.

## Access and robots.txt

Read 2026-11-25 (#169):

| Host | robots.txt | What wet and fwapg read there |
|---|---|---|
| services.pacificclimate.org | For every agent: `Disallow: /data/` ("PDP data backend (heavily rate-limited, large downloads)"), `/bbox-server`, `/hydromosaic`, and other map, tile and API paths. Its stated policy: "let crawlers index the app landing pages, keep them off data/API/tile endpoints that are expensive or rate-limited". `/portal/` and `/chyp` are not listed | `/data/`: wet's gridded reader (`wet_pcic_fetch()`) and fwapg's `discharge.sh`. `/hydromosaic`: the channel-scale pilot (#168) and fwapg's crosswalk job. `/portal/`: the catalog |
| data.pacificclimate.org | 301 to the same path on services. (one proxy) | as above |
| beehive.pacificclimate.org | `Disallow: /` for every agent | hydromosaic is served here too; nothing wet reads uses it |
| www.uvic.ca (PCIC's pages) | Disallows search queries and two unrelated paths | The pages this file cites |

- **A rate limit was met.** The fifth OPeNDAP metadata request to `/data/` within a few seconds answered 429; the same request answered 200 a few minutes later. Whether a 429 carries `Retry-After` is not known. Since #169 `wet_pcic_fetch()` reads the status, waits and retries on 429 and 503, and sends a user agent naming wet.
- **The owner's decision (2026-11-25, #169):** ask PCIC first. A note drafted for the owner (not in this repository) asks how PCIC would like bulk reads done and when its new portal opens, and says that, unless PCIC prefers otherwise, the project would read politely (one request at a time, waiting on every 429, a user agent naming wet) from about mid-December. Until then wet makes no new request to a disallowed path; the checks that need one (#4) are registered and coded and wait.
- **A second host for PNWNAmet:** figshare's `PNWNAmet.nc` (55 GB, collection DOI 10.6084/m9.figshare.c.3965337), with no robots restriction. No second host was found for the CMIP5 gridded or station output or the CMIP6 channel-scale output (searched 2026-11-25; #169's body).

## Per-year routed flow and the departure competition (#122)

**Verified:** 2026-10-27 · **Issues:** #122 (component 3 of #118; reads #120's usable threshold), NewGraphEnvironment/fwapg#42 (the per-year product) · **Produced by:** `scripts/departure_pcic.R` → `data/checks/departure_pcic_20260717.txt`, HYDAT 2026-07-17, approved daily flows only; PCIC's PNWNAmet historical run routed per year from fwapg's `pcic.subbasin_days.PNWNAmet_historical.<year>.parquet` (fwapg ea9b199). The rule was registered in the script's header at 5904cd7, before any candidate existed, and amended at a8ff752, 5a67a46 and b518ebc before any run on the product. Two runs from a frozen copy gave a byte-identical report (`data/logs/122/`).

**The verdict.** Donors carry a gauge's year-to-year departures better than PCIC's own routed flow does, and a half-and-half blend adds less than the 0.01 a challenger needed. Choosing donors by how well PCIC's modelled flow at the two sites moves together beats choosing them by distance.

The question is the one #120 left open: at a site with no record, are its departures better carried from gauged neighbours or read off PCIC's modelled flow at the site? The pool is the shipped fit's calibration gauges whose segment has a routed weight, 290, held out one at a time and again with every gauge upstream or downstream of the target removed (leak-free). The score is the centred log NSE of the Chinook migration-window mean (05-01 to 08-01), on the years 1951–2012 every candidate has; 0 means no better than no departure. A challenger ships if it beats the incumbent's median by 0.01 in both pools.

| | candidate | median NSE, held out | median NSE, leak-free |
|---|---|---|---|
| stage 1: how donors are weighted | distance (#120's, incumbent) | 0.67 | 0.64 |
| | PCIC covariance, same 5 nearest | 0.68 | 0.66 |
| | **PCIC covariance, best 5 of 15 nearest (ships)** | **0.72** | **0.69** |
| stage 2: donors, PCIC or a blend | **donors, as stage 1 ships** | **0.72** | **0.69** |
| | PCIC's own departure at the segment | 0.48 | 0.48 |
| | blend, half each in logs | 0.71 | 0.69 |

- **Stage 1.** Picking the five donors whose modelled departures correlate best with the target's, among its 15 nearest, gains 0.054 held out and 0.047 leak-free. Its donors sit a little farther away (median 84 km against 81, held out). Weighting the same five nearest by correlation gains only 0.01 to 0.02: the header expected that near-null, because PNWNAmet's forcing is shared across a region, so modelled correlation among neighbours is high and flat. The gain comes from choosing different donors, not from reweighting the same ones.
- **Stage 2.** PCIC's own departures score 0.24 below donors held out and 0.21 below leak-free. The blend misses the margin both ways (−0.009 held out, +0.008 leak-free), so donors ship. After 2012 only donors carry values in any case.
- **The short-record test set**, deciding nothing, ranks them as the held-out pool does. Over the 60 gauges the weightings score, donors chosen by covariance reach 0.66 and distance 0.50; over the 62 that donors, PCIC and the blend score, donors reach 0.65, the blend 0.60 and PCIC 0.41. At Maxan Creek (08EE018), five years, distance donors score 0.74 from the province pool and covariance-picked donors 0.64.

**PCIC's own skill** at the 290 gauges, as the median centred NSE of its departures (correlation in brackets): Columbia 0.63 (0.81), Fraser 0.49 (0.73), Peace 0.43 (0.73), Coast 0.41 (0.69). It barely moves with drainage area (0.47 under 100 km² to 0.51 over 10,000 km²) and is a little higher at nested gauges (0.53) than at headwaters (0.47). Its correlation is well above its NSE everywhere, so PCIC follows which years run high or low better than it gets their size.

**Sensitivities**, reported and unable to ship, keep the order: donors above PCIC with k = 3 and 8, and in every other window statistic (spawning-window mean 0.67 against 0.27; migration 7-day minimum 0.62 against 0.16). A blend weighted three quarters to donors scores 0.74 held out against donors' 0.72, PCIC's largest gain over donors among the report's medians, in a setting that could not ship.

**Limits.** PCIC publishes no calibration gauges, so its score at a calibration gauge may be partly in sample; donors are always held out, which favours PCIC if anything. Choosing 5 of 15 by a correlation over 62 years selects partly on noise (r's sampling SD is about 0.13), which is why the win had to hold leak-free too. Only the migration-window mean decided. PCIC's run ends in 2012, so the comparison covers 1951–2012 alone.

## Terms

**Verified:** 2026-11-25. Every PCIC data portal page says the data are "subject to PCIC's terms of use" and provided "AS IS" without warranty; the data portals page says PCIC makes its data "publicly available with an open license", naming none. The terms of use page itself covers the website (its use at your own risk; reproduction of the site's material under its copyright notice) and states no data licence. The citation form is "Pacific Climate Impacts Consortium, University of Victoria, (January 2020). VIC-GL BCCAQ CMIP5: Gridded Hydrologic Model Output. Downloaded from <Permalink> on <Date>." **Publishing derived values is not a concern** (airvine, 2026-10-07): wet publishes values derived from PCIC output, cited as above, without seeking separate confirmation. The contact named in the file metadata is Markus Schnorbus (PCIC hydrology).
