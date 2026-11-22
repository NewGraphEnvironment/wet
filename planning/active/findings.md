# Findings — Backlog move 6: Pilot PCIC's channel-scale output on the FWA (#168)

## Issue context

**If we do it:** PCIC's channel-scale output (VIC-GL-Raven, CMIP6) is compared at about six representative FWA sites with wet's accumulation, routed PCIC and HYDAT, with every manual step and crosswalk mismatch recorded, and a decision on whether to use it where it covers the network. **If we never do:** scenarios (#4) and coverage (#5) are built on gridded CMIP5 without knowing whether the routed CMIP6 product is better.

Order: `planning/backlog.md`, move 6. Run `/planning-init <this issue>`.

## Batch 9: the channel-scale pilot

**Why here:** it is the oracle move 7 waits on: its verdict decides which runs #4 builds on and what #5 maps.

**Touches:** a new pilot script under `scripts/`, `research/pcic_channel_scale.md`.

**Decided at the gate:** the six sites; whether the pilot also reads the routed product's water temperature. Open work in fwapg asks whether to run Raven routing on the FWA instead of crosswalking PCIC outlets.

| issue | title |
|---|---|
| #9 | Pilot PCIC channel-scale (VIC-GL-Raven CMIP6) output at representative FWA sites |

## Exploration, 2026-11-22

### The portal is hydromosaic

- `https://services.pacificclimate.org/chyp/` is a single-page app (`/chyp/assets/index-Go8VRv5T.js`, 636,357 bytes). Its data calls are `${origin}/bbox-server/collections/{rivers,lakes,upstreams,downstreams}/items...`, keyed on `network_subid` / `subid`, plus `/chyp/fwa_index.json`. `bbox-server/collections.json` lists `downstreams, upstream_feature_collections, downstream_feature_collections, import_status, upstreams, rivers, lakes`; a `rivers` feature carries `dowsubid, islake, uid`.
- `https://services.pacificclimate.org/hydromosaic/openapi.json` is "Hydromosaic Service API" v0.1: `/bulk-downloads`, `/outlets`, `/outlets/{subid}`, `/outlets/{subid}/timeseries`, `.../{ts_id}`, `.../{ts_id}/data`, `/variables`.
- `GET /hydromosaic/outlets/4008184/timeseries` on `services` and on `beehive` (fwapg's host) returns the same 57 series (24,040 bytes each, the same `(model, scenario, variable)` set with the same ids; the files differ in order only): 19 each of `streamflow`, `water_temp`, `DO_sat`, for `PNWNAmet` and `CNRM-ESM2-1, FGOALS-g3, IPSL-CM6A-LR, MIROC-ES2L, MPI-ESM1-2-HR, MRI-ESM2-0, NorESM2-LM, TaiESM1, UKESM1-0-LL` under `historical, ssp245` and `historical, ssp585`. The GCM series run 1950-01-01 to 2100-12-31 (55,152 days); PNWNAmet streamflow runs 1950-01-01 to 2012-12-31 (`historical`, 23,011 days).
- The portal bundle contains no `hydromosaic`, `streamflow`, `water_temp`, `.csv` or OPeNDAP string; its only download builds a GeoJSON blob. So "VIC-GL-Raven MBCn CMIP6: Vector Hydrologic Model Output" and hydromosaic being one product rests on the shared `subid` network and the matching runs and variables, not on a traced download path.
- HYDAT 20260717 `STN_REGULATION`: 08MF005 regulated from 1952; 08KC001, 08KH001 and 08MG005 unregulated.
- If one product, then fwapg's `extras/pcic_crosswalk` (fwapg#5, #25, #42) places its outlets on the FWA (`pcic.fwa_crosswalk`, `pcic.segment_weights`) and wet publishes the PNWNAmet run as `pcic_routed` (1981–2010 since #103).
- fwapg `research/pcic_routed_flow_periods.md` ("CMIP6 runs"): the crosswalk job takes `MODEL` and `SCENARIO`; a full CMIP6 run's fetch is about 1.5 h; none has been built.

### What is already measured, and what is not

- Routed PCIC against HYDAT: 283 gauges in the segment-discharge article; `scripts/pcic_routed_compare.R` and `scripts/gauge_monthly_compare.R`.
- Not measured: `research/monthly_error.md` ("What check 1 does not reach"): the scores rest on fwapg's statement that accumulated flow equals PCIC's outflow where the two networks agree, and do not read PCIC's raw hydromosaic series. fwapg#8 (visual review of placed outlets) is open.
- Not measured: any CMIP6 run on the FWA, or its 1981–2010 flow against PNWNAmet's or HYDAT's.
- fwapg#28 (run Raven on the FWA instead of crosswalking?) says: "First check the option already on the table: PCIC offered to help scale up their channel-scale output if a pilot shows value (NewGraphEnvironment/wet#9)". The exploration shows the scale-up already exists through the crosswalk.

### Code the pilot reuses

- `scripts/pcic_routed_lib.R`: `routed_run`, `routed_where`, `routed_commit()`, `routed_report_line()`, `routed_fingerprint()`, `routed_annual()`, `routed_weights()`.
- `wet_segment_monthly(conn, segments, source, from = c("published", "fwapg"), groups)`, `wet_station_monthly(stations, hydat)`.
- `wet_pcic_fetch(variable, bbox, start, end, run = "TPS_gridded_obs_init")` and `wet_pcic_annual(..., run =)` take a CMIP5 run name; `scripts/mad_basin.R` is the whole-basin accumulation (Fraser at Hope, 08MF005, is its sanity check).
- `scripts/departure_sites.csv` is the site-table pattern.

### The build's inputs

- 2026-11-22: the local fwapg was not accepting connections when the plan was drafted, so the build starts it first and confirms which fwapg commit built its `pcic` schema. The main checkout's `data/pcic/` holds the TPS_gridded_obs_init RUNOFF/BASEFLOW subsets for 1981–2010.
