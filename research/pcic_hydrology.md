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

## Terms

The PCIC terms of use provide data "AS IS" and name no open licence. The citation form is "Pacific Climate Impacts Consortium, University of Victoria, (Jan 2020). VIC-GL BCCAQ CMIP5: Gridded Hydrologic Model Output." **Redistributing derived values is unconfirmed** (#7). The contact named in the file metadata is Markus Schnorbus (PCIC hydrology).
