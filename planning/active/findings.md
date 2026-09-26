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

