# Task: Scope: monthly, seasonal and scenario discharge per FWA segment (#1)

## Problem

The only per-segment discharge available is fwapg's `extras/discharge` (`whse_basemapping.fwa_stream_networks_discharge`: `mad_mm`, `mad_m3s`):

- PCIC VIC-GL baseflow + runoff, ~30 km cells, collapsed with `cdo` to one mean annual value over a daily slice spanning roughly 1981–2010. Monthly structure and scenario runs are discarded.
- Fraser, Columbia and Peace only; rivers of order ≥ 8 skipped. Locally, 2.0 M of 2.7 M segments carry a value.
- bash + cdo + SQL, run by hand.

Station data is separate: water-temp-bc holds ~290 ECCC stations (temperature, discharge, level) over the ~18-month realtime window. Long HYDAT records are reachable through `tidyhydat` / `fasstr`, but nothing combines them with modelled flow on the network.

## Phase 1 — Product inventory (no code)
- [x] Check that the PCIC endpoints are live: `data.pacificclimate.org/portal/hydro_model_out/catalog/catalog.json`, the OPeNDAP base, and the uvic.ca portal page. Record the working URLs.
- [x] List PCIC hydrologic model output: the historical run (PNWNAmet), the scenario runs (GCMs, RCP/SSP, CMIP5 vs CMIP6), periods, basins covered beyond Fraser/Columbia/Peace, and variables. Include routed streamflow at stations if it exists.
- [x] List other candidate products: provincial water tools, ECCC, other groups' scenario runs, and regional regression from HYDAT. For each, record licence, coverage, resolution, time axis, scenarios and access method.
- [x] Write the inventory table and the issue-text corrections to `findings.md`.

## Phase 2 — Decisions (each one user-approved, recorded in `findings.md` under `## Decisions (user-approved)`)
- [ ] R package vs scripts-plus-data repo. Precedents: `cd`/`fresh`/`link` are packages; `water-temp-bc`/`stac_dem_bc` use `Type: Project`.
- [ ] Output unit: FWA segment (`linear_feature_id`) vs fundamental watershed.
- [ ] Method choices to carry forward:
  - centroid sample vs area-weighted cell extraction
  - NULL-cell handling (divide by covered area vs total area)
  - the order ≥ 8 mainstem skip
  - whether runoff and baseflow are summed before or after averaging
- [ ] Publish shape:
  - parquet key layout and versioning, and which bucket
  - a STAC Collection with the table extension
  - the path into fwapg so `frs_col_join` can consume it (fresh#114)

## Phase 3 — Repo scaffold (per the Phase 2 decisions)
- [ ] DESCRIPTION (package, or `Type: Project` manifest), LICENSE, `.Rbuildignore`, and `R/` + `tests/testthat/` with a `wet_` prefix if it is a package.
- [ ] Add the project section of CLAUDE.md above the marker: language, data sources, database connection pattern, gitignored data directories.

## Phase 4 — MAD parity prototype, one watershed group
- [ ] Pick a **headwater** Fraser/Columbia/Peace watershed group that PCIC covers fully, so upstream accumulation stays inside the group. Confirm in the database that `fwa_stream_networks_discharge` has values there.
- [ ] Fetch BASEFLOW + RUNOFF for 1981–2010 for the group's bbox over OPeNDAP, reusing the index-slicing approach from `pcic_dl_sh()`, and cache it locally.
- [ ] Per cell: annual sum, then mean over years, then runoff + baseflow, giving mm/yr (terra). Match cdo's `yearsum`/`timmean` exactly.
- [ ] Sample at fundamental watershed centroids, then upstream area-weighted accumulation, then segments through `fwa_streams_watersheds_lut`. Replicate fwapg exactly first.
- [ ] Unit tests on small fixtures: annual aggregation including leap years, the mm to m³/s conversion, area weighting with NULL cells.
- [ ] Parity report against `fwa_stream_networks_discharge` (`mad_mm`, `mad_m3s`): the distribution of relative differences, the share of segments within 0.1 %, and an explanation for every residual.
- [ ] Sensitivity: rerun with area-weighted cell extraction and with covered-area normalisation, and report how far each moves the results. This feeds back into the Phase 2 method decision.

## Phase 5 — Close out
- [ ] Post the decision record and parity result as a comment on #1.
- [ ] Open child issues: monthly/seasonal climatologies, scenario period means, coverage gap-fill, station check (HYDAT snapped with `frs_point_snap`, bias by region and season), and publish (parquet + STAC + fwapg load). Cross-reference fresh#114, link#284 and knowledge#19.
- [ ] Open an issue on fwapg about the mislabelled forcing in the README and the `mad_m3s` column comment.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
