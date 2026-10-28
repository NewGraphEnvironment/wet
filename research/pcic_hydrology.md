# PCIC hydrologic model output: what exists, where, and on what terms

**Verified:** 2026-09-25; channel-scale section 2026-09-26 · **Issues:** #1 (found), #3, #4, #5, #6, #7, #9 (use it) · **Produced by:** `curl` of the PCIC catalogs and OPeNDAP `.das`/`.dds` (commands in `planning/archive/2026-09-issue-1-scope-discharge/`), PCIC web pages and the PCIC Update of Feb 2026.

## Hosts

- The data service moved from `data.pacificclimate.org` to **`services.pacificclimate.org`**. The old host answers 301, so any client must follow redirects. `curl -o` without `-L` saves the redirect page (fwapg `extras/discharge/discharge.sh` does this).
- Gridded catalog: `https://services.pacificclimate.org/portal/hydro_model_out/catalog/catalog.json` (169 datasets).
- OPeNDAP: `https://services.pacificclimate.org/data/hydro_model_out/<file>.nc`, with suffixes `.das`, `.dds`, `.ascii?`, and `.nc?VAR[t0:t1][y0:y1][x0:x1]` for a NetCDF subset. `wet_pcic_url()` / `wet_pcic_fetch()` implement this.

## Gridded runs (`hydro_model_out`)

| Run | Model | Forcing | Span | Domain |
|---|---|---|---|---|
| `TPS_gridded_obs_init` | VICGL-RGM-HydroConductor (glacier dynamics) | PNWNAmet (observed) | 1945-01-01 to 2012-12-31 | `nwna` attribute; values in Peace, Fraser, Columbia |
| 12 × `<GCM>_<rcp>_<member>` | VICGL (no glacier model) | BCCAQ-downscaled CMIP5 | 1945-01-01 to 2099-12-31 | "COLUMBIA+PEACE+FRASER" |

- **GCMs:** ACCESS1-0 r1i1p1, CanESM2 r1i1p1, CCSM4 r2i1p1, CNRM-CM5 r1i1p1, HadGEM2-ES r1i1p1, MPI-ESM-LR r3i1p1, each at RCP 4.5 and RCP 8.5.
- **File names all say `1945to2099`** regardless of span.
- **Variables:** BASEFLOW, RUNOFF, EVAP, GLAC_AREA, GLAC_MBAL, GLAC_OUTFLOW, PET_NATVEG, PREC, RAINF, SNOW_MELT, SOIL_MOIST_TOT, SWE, TRANSP_VEG.
- **Grid:** 0.0625°. 496 lon × 367 lat, centres at lon −139.96875 + 0.0625·i and lat 41.09375 + 0.0625·j (both ascending). Only the three basins hold values.
- **Time:** daily, `days since 1945-1-1`, standard calendar (checked on the historical run and 4 scenario runs). Index = day offset, so 1981-01-01 is 13149 and 2010-12-31 is 24105.
- **Units:** mm (per day). Packed shorts with `scale_factor`/`add_offset` and `_FillValue` −32767; terra and cdo unpack them. An all-zero day unpacks to about −2.8e-6 mm (packing floor), which is negligible.
- **Calibration:** 1985–2005 against TPS/ClimateWNA.
- **Structure differs between historical and scenario runs** (RGM vs none). Take climate deltas within one run, not scenario minus historical.
- **No CMIP6 hydrology** on the portal.

## Other PCIC products

- **`hydro_stn_cmip5`** ("Modelled Streamflow Data"): routed (RVIC) daily m³/s at 190 stations in the three basins. The PNWNAmet run plus 12 CMIP5 runs, one CSV per station, dated Feb 2020.
- **Salmon Climate Impacts Portal** (Mar 2024): VIC-GL coupled to dynWat on the BC coastal domain. 10 streamflow and water-temperature hazard indices, CMIP5, periods historical/2020s/2050s/2080s. Regions: watershed group, conservation unit or custom outlet.
- **Channel-scale: "VIC-GL-Raven MBCn CMIP6: Vector Hydrologic Model Output"** (released May 2026). *Corrects the 2026-09-25 version of this file, which called it unreleased on the strength of the Feb 2026 PCIC Update.*
  - Portal: `https://services.pacificclimate.org/chyp`. Docs: `uvic.ca/pcic/data-analysis-tools/data-portal/hydrology-vector/`.
  - Model: VIC-GL runoff routed by Raven on a vector network of reaches and lakes.
  - Variables: daily streamflow (or lake outflow), water temperature and saturated dissolved oxygen, each at the outlet of a reach or lake.
  - Runs: historical driven by PNWNAmet, plus 9 CMIP6 GCMs × SSP2-4.5/SSP5-8.5, MBCn bias-corrected, to 2100.
  - Downloads: CSV per feature, NetCDF for upstream/downstream networks, GeoJSON geometry.
  - The portal loads `/chyp/fwa_index.json`, a place-name search index keyed on FWA `blue_line_key` and lake keys (2,391 streams, 4,967 lakes). It covers names province-wide, so it does **not** show where there is model output.
  - **From PCIC correspondence, 2026-07-20:**
    - The portal is designed for specific sites, not domain-wide extraction.
    - The network is based on the FWA, with "subtle differences … necessary for consistently routing flow", so domain-wide use meets many model/FWA edge cases.
    - PCIC suggests piloting a few representative sites first, then possibly scaling up with their support (#9).
    - The Peace and Upper Columbia are to be added "in the next year or so". Current coverage is the coastal domain plus the Fraser (Feb 2026 Update).
  - Recommended use: compare PNWNAmet-driven runs with observations, and take climate impacts within one model-scenario combination.
- **`downscaled_cmip6`:** BCCAQv2 CMIP6 *climate* (not hydrology), Canada-wide.

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

The PCIC terms of use provide data "AS IS" and name no open licence. The citation form is "Pacific Climate Impacts Consortium, University of Victoria, (Jan 2020). VIC-GL BCCAQ CMIP5: Gridded Hydrologic Model Output." **Publishing derived values is not a concern** (airvine, 2026-10-07): wet publishes values derived from PCIC output, cited as above, without seeking separate confirmation. The contact named in the file metadata is Markus Schnorbus (PCIC hydrology).
