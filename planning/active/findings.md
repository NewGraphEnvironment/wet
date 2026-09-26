# Findings — Scope: monthly, seasonal and scenario discharge per FWA segment (#1)

## Issue context

**If we do it:** habitat models can use seasonal and monthly flow, not just one mean-annual number, tied to when each species is in the stream, with climate scenarios on the same network. **If we never do:** discharge stays a mean-annual value covering three basins (fwapg's `extras/discharge`). Nothing can ask "is there enough water in this reach during CH spawning or BT incubation, now and in 2050".

## Problem

The only per-segment discharge available is fwapg's `extras/discharge` (`whse_basemapping.fwa_stream_networks_discharge`: `mad_mm`, `mad_m3s`):

- PCIC VIC-GL baseflow + runoff, ~30 km cells, collapsed with `cdo` to one mean annual value over a daily slice spanning roughly 1981–2010. Monthly structure and scenario runs are discarded.
- Fraser, Columbia and Peace only; rivers of order ≥ 8 skipped. Locally, 2.0 M of 2.7 M segments carry a value.
- bash + cdo + SQL, run by hand.

Station data is separate: water-temp-bc holds ~290 ECCC stations (temperature, discharge, level) over the ~18-month realtime window. Long HYDAT records are reachable through `tidyhydat` / `fasstr`, but nothing combines them with modelled flow on the network.

## Proposed Solution (scope to settle here)

1. **Reproduce fwapg's MAD in R** (`terra`/`stars` + the fwapg database for FWA topology), and compare it with `fwa_stream_networks_discharge` as a parity check.
2. **Keep the time axis:** monthly climatologies and seasonal summaries (e.g. Aug–Sep low flow, freshet peak) per segment.
3. **Scenarios:** the PCIC hydrologic model output that is forced by projected climate, as period means (e.g. 2041–2070) next to the historical baseline.
4. **Coverage:** establish what PCIC now covers beyond the three basins, and what fills the gaps (regional regression from HYDAT stations, other published products).
5. **Station check:** compare modelled monthly flow with HYDAT at gauged outlets, and report bias by region and season.
6. **Publish:** per-segment monthly table (`linear_feature_id` × period × month × scenario) as parquet on S3 with a STAC entry, in the pattern of `cd`. fresh joins it like channel width (fresh#114); link matches months to species- and region-specific life-cycle timing.

## Open questions

- Other published products to evaluate before building (PCIC's routed streamflow at stations, provincial water tools, other groups' scenario runs). List them, with licence and coverage, before writing code.
- Segment-level vs fundamental-watershed-level output.
- R package or scripts-plus-data repo.

Relates to NewGraphEnvironment/fresh#114, NewGraphEnvironment/link#284, NewGraphEnvironment/knowledge#19


## Exploration (plan mode, 2026-09-25)


### How fwapg's MAD is built
- Files are under `fwapg/extras/discharge/`: `discharge.sh`, then `sql/discharge02_load.sql`, `discharge03_wsd.sql` and `discharge.sql`.
- Download: PCIC OPeNDAP `allwsbc.TPS_gridded_obs_init.1945to2099.{BASEFLOW,RUNOFF}.nc.nc`, time indices `[13149:24105]` (1981-01-01 to 2010-12-31, daily).
- Per cell: `cdo yearsum` then `timmean`, and runoff + baseflow, giving mm/yr.
- Per fundamental watershed: `ST_Value` at the **centroid** (a single sample, not area-weighted).
- Upstream: area-weighted by `ST_Area(uw)/upstream_area_ha*1e4` through `FWA_Upstream` and `fwa_watersheds_upstream_area`.
  - `mad_m3s = mm * upstream_area_m2 / 31536000000`.
  - A NULL upstream cell drops out of the sum while still counting in the denominator, which biases results low.
  - Mainstems of order ≥ 8 are skipped (`order8rivs` CTE).
- Watershed → segment goes through `fwa_streams_watersheds_lut`.

### Corrections to the issue text
- The grid is **0.0625°** (about 30 km² per cell), not ~30 km.
- The forcing is **PNWNAmet observed** (VICGL+RGM+HydroConductor, historical), not a BCCAQ scenario.
- fwapg's README citation and the `fwa_streams.mad_m3s` column comment mislabel the forcing.

### Earlier R work on PCIC data
- `fish-passage-22/functions.R:123-215` `pcic_dl_sh()` reads PCIC `catalog.json`, uses ncdf4 to resolve OPeNDAP index slices for a bbox and date range, and pulls scenario runs (for example `ACCESS1-0_rcp85`).
- `read-discharge.R` reads the result with tidync.
- There is a 9 GB local historical BASEFLOW file at `~/Projects/repo/pcic/data/baseflow.nc`, but no RUNOFF.
- Nobody has checked whether the endpoints are still live; fwapg moved its README links to uvic.ca in July 2026.

### How fresh consumes discharge (fresh#114)
- fresh joins in Postgres with `frs_col_join(conn, table, from, cols, by = "linear_feature_id")` (`fresh/R/frs_col_join.R:73`).
- A `wet` parquet would therefore need loading into fwapg, or a foreign table or subquery, before fresh can use it.
- The MAD predicate is not wired yet.

### The `cd` pattern
- `cd` is an R package: COGs, `aws s3 sync`, and a hand-built STAC Catalog with items inline. It has no parquet, no Collection, no table extension and no versioning.
- Copy its package and pipeline layout (`R/wet_*`, `scripts/pipeline_*.R`, one test per exported function, a STAC round-trip test). Design the parquet and STAC Collection side fresh; `stac_dem_bc` uses pystac with a Collection and the Version extension.

### Stations
- `water-temp-bc` holds about 290 ECCC stations with no FWA snapping.
- `fresh::frs_point_snap()` wraps `fwa_indexpoint` and takes `num_features`.
- HYDAT is available locally (2025-12-04).
- `fasstr` (CRAN 0.5.3) has `calc_longterm_monthly_stats` and low-flow functions.

### Life-cycle timing (knowledge#19)
- No structured timing table exists apart from a Skeena-only gantt CSV that has been copied into the fish_passage_* repos.
- knowledge#19 plans to build one, and it is the consumer of the monthly output.

### Local tooling
- Installed: terra, stars, arrow, duckdb, fwapgr, tidyhydat.
- Not installed: exactextractr.
- The database follows the `PG_*_SHARE` pattern (`fresh::frs_db_conn`, `link::lnk_db_conn`).


## Phase 1 — Product inventory (2026-09-25)

### Endpoint status

| Endpoint | Status 2026-09-25 |
|---|---|
| `data.pacificclimate.org/...` (host fwapg and `pcic_dl_sh()` use) | **301 → `services.pacificclimate.org/...`** |
| `services.pacificclimate.org/portal/hydro_model_out/catalog/catalog.json` | 200, 169 datasets |
| `services.pacificclimate.org/data/hydro_model_out/<file>.nc` (OPeNDAP: `.das`, `.dds`, `?VAR[t][y][x]`) | 200 |
| `services.pacificclimate.org/portal/hydro_stn_cmip5/` | 200 ("Modelled Streamflow Data" portal) |
| `services.pacificclimate.org/portal/downscaled_cmip6/catalog/catalog.json` | 200 (BCCAQv2 CMIP6 *climate*, not hydrology) |
| `uvic.ca/pcic/data-analysis-tools/data-portal/hydrology-gridded/` | 200 (human docs) |

fwapg's `discharge.sh:13-14` runs `curl -o` **without `-L`**. Against the redirecting host it saves the 301 body, not the NetCDF, so the script is broken as written. Put this in the fwapg issue draft (Phase 5).

### PCIC `hydro_model_out` (gridded VIC-GL), parsed from `catalog.json`

- **Historical:** `VICGL-RGM-HydroConductor`, forcing PNWNAmet (observed), 1945-01-01 to 2012-12-31, domain `nwna`. The file name says "1945to2099" but the data end in 2012. Has 13 variables, including RUNOFF, BASEFLOW, SWE, SNOW_MELT, GLAC_OUTFLOW, PREC and EVAP. This is the run fwapg uses.
- **Scenarios:** `VICGL` (no glacier dynamics), BCCAQ-downscaled CMIP5 driven by 6 GCMs × 2 RCPs = 12 runs, 1945-01-01 to 2099-12-31, domain attribute `columbia`. The title reads "COLUMBIA+PEACE+FRASER_CMIP5_Hydrologic_Projection". There are 13 variables per run in the catalog, and RUNOFF and BASEFLOW are present for every run.
  - GCMs: ACCESS1-0, CanESM2, CCSM4 (r2i1p1), CNRM-CM5, HadGEM2-ES, MPI-ESM-LR (r3i1p1).
- **Grid:** 0.0625°, sliced to lon −139.97…−109.03, lat 41.09…63.97. Only Peace, Fraser and Columbia hold values; the rest is fill.
- **Units:** mm per day, stored as packed shorts (`_FillValue` −32767). Calendar `standard`, time "days since 1945-1-1". Calibration 1985–2005 against the TPS/ClimateWNA target.
- **The historical and scenario model versions differ** (RGM glacier model vs none). A delta computed as scenario minus historical mixes model structure with climate signal. Deltas must come from the same run: scenario future period minus scenario baseline period.
- **Terms:** PCIC terms of use, "AS IS", and cite as "Pacific Climate Impacts Consortium, University of Victoria, (Jan 2020). VIC-GL BCCAQ CMIP5: Gridded Hydrologic Model Output." No open licence is named; confirm redistribution rights before publishing derived values.
- **No CMIP6 hydrology on the portal.**

### PCIC `hydro_stn_cmip5` (routed station streamflow)

- 190 locations in Peace, Fraser and Columbia. VIC-GL runoff routed with RVIC.
- One CSV per station: daily m³/s, 1945–2099, with a PNWNAmet column plus 12 CMIP5 columns. Released Feb 2020.
- Use: an **independent check on the station comparison** — routed modelled flow vs our area-weighted accumulation at the same outlets, plus HYDAT where gauged. Not a per-segment product.

### PCIC Salmon Climate Impacts Portal (Mar 2024)

- VIC-GL coupled to dynWat (streamflow + water temperature), BC coastal domain.
- 10 streamflow/temperature hazard indices at yearly, monthly and daily resolution. 6 CMIP5 GCMs × RCP 4.5/8.5 × historical, 2020s, 2050s, 2080s.
- Regions: watershed group, salmon conservation unit, or a custom outlet. The spatial unit behind them is not documented on the page.
- Terms: PCIC terms of use.

### PCIC VIC-GL → Raven, CMIP6 (announced Feb 2026, NOT yet released)

- PCIC Update Feb 2026, "Improved Modelling of BC's Salmon Habitats".
- VIC-GL runoff drives Raven routing on a **vector (sub-basin + channel) discretisation**, "about a factor of five" finer than VIC-GL's ~25 km² minimum. Outputs are streamflow, water temperature and saturated dissolved oxygen.
- Deployed "across BC's entire coastal domain, including the Fraser Basin" (~405,000 km²), driven by CMIP6. The example is CNRM-ESM2-1, SSP5-8.5.
- "Near completion … will be available from a new data portal." Funded by BCSRIF and BC Hydro.
- **This is the biggest scope risk for `wet`.** It overlaps the monthly, scenario and coverage items for the coastal domain and the Fraser, it adds water temperature, and it is routed. It is not expected to cover the Peace, Columbia or northern interior. Things to find out before building scenarios: the sub-basin geometry (can it be crosswalked to FWA?), the release date, and the licence. Contact Markus Schnorbus (PCIC hydrology lead, named in the NetCDF metadata).

### Provincial and other products

| Product | Coverage | Time axis | Scenarios | Access / licence | Relevance |
|---|---|---|---|---|---|
| BC Water Tools (NEWT: BC Energy Regulator; Omineca, Cariboo, Kootenay-Boundary, NW: FLNRORD; built by Foundry Spatial) | Regional, together covering much of the interior and north | Mean annual + monthly discharge for a user-picked watershed | Climate summary only | Web UI, per-watershed reports. No bulk per-segment download found | A reference to compare against in gap regions (Skeena, north). Not a data source |
| HYDAT (ECCC), via `tidyhydat` | ~ all gauged stations; local sqlite 2025-12-04 | Daily/monthly, long records | None | Open Government Licence – Canada | Station check (item 5); training data for gap-fill regression |
| ECCC realtime (`water-temp-bc`) | ~250 discharge stations | 18-month window | None | OGL-Canada | Short; not useful for climatologies |
| BCUB (ESSD 2025): British Columbia Ungauged Basin attributes | 1.2 M ungauged catchments, BC-wide | Static attributes (terrain, soil, land cover, climate indices) | None | Open (ESSD data paper) | Predictors for a regional regression gap-fill (item 4) |
| Morrison et al. 2012 (Atmos-Ocean), monthly freshwater discharge to BC coastal waters | Coastal BC | Monthly | None | Paper | Method precedent for pluvial vs nival regional regression |
| ClimateBC / `climr` (already used in fwapg `extras/precipitation`) | BC + transboundary | Monthly normals, CMIP6 scenarios | Yes (CMIP6) | Open | Possible precipitation-scaled downscaling of VIC-GL (the fwapg README's "upsampling" idea), or a regression predictor |

### Coverage gap (item 4)

PCIC gridded hydrology covers only Peace, Fraser and Columbia. The Skeena, Nass, Stikine, coastal and northern basins have no VIC-GL product on the portal. The Raven CMIP6 release would add the coastal domain. The north (Liard, Stikine, Nass, Skeena interior) stays uncovered by any modelled product, so it needs regional regression: HYDAT response + BCUB/ClimateBC predictors.

### Corrections to the issue text (confirmed)

- Grid is 1/16° (≈ 30 km², PCIC's own number is ~25 km²), not "~30 km cells".
- fwapg's MAD uses the **historical PNWNAmet run with the RGM glacier model**, not a CMIP5 scenario.
- The raster → watershed step is a **centroid point sample**, not area-weighted.
- The 1981–2010 slice is exact (time indices 13149–24105).
