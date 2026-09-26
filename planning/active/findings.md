# Findings — Coverage beyond Peace, Fraser and Columbia (#5)

## Issue context

Issue #1 item 4. PCIC gridded hydrology covers only the Peace, Fraser and Columbia. The Skeena, Nass, Stikine, Liard, coastal and northern basins have no modelled per-cell runoff on the portal.

## Candidates (from #1 Phase 1)

- **PCIC channel-scale VIC-GL-Raven CMIP6**, released May 2026 (https://services.pacificclimate.org/chyp):
  - Streamflow, water temperature and dissolved-oxygen saturation per reach and lake outlet, on a network based on the FWA but not identical to it.
  - Coverage: the coastal domain plus the Fraser now; the Peace and Upper Columbia "in the next year or so" (PCIC, 2026-07-20).
  - PCIC recommends a site pilot before any domain-wide use: #9.
  - That leaves the north and interior (Skeena interior, Nass, Stikine, Liard) uncovered by any model.
- **Regional regression for gaps:** HYDAT monthly flow (local `tidyhydat` sqlite) as the response. BCUB catchment attributes (ESSD 2025, 1.2 M catchments) and ClimateBC/`climr` normals as predictors, split pluvial vs nival (Morrison et al. 2012). Validate with leave-one-basin-out.
- **BC Water Tools (Foundry Spatial), now provincial and open (update 2026-09-26).**
  - Foundry's BC Water Tool IP and discharge data have passed to the Province of BC. For the regions they cover, that means open per-watershed discharge data, expected "in the next few weeks" (correspondence 2026-09-14). This makes it the **leading gap-fill candidate for the north/interior**, instead of a comparison-only reference.
  - Code and application: https://github.com/bcgov/nr-bcwat (public, Apache-2.0). Method notes: `documentation/knowledge_transfer_documentation.md`, section "Process for adding a new region".
  - **Method:** not PCIC; this is the Chapman, Kerr & Wilford 2018 (JAWRA 54:676) approach.
    - Annual water balance: gridded P - ET, adjusted by a regression on the gauge residuals within Obedkoff (2000) regions.
    - Monthly runoff: a regression per month for each month's share of annual runoff, fitted to unregulated WSC stations.
    - Output: mean monthly discharge per FWA fundamental watershed (`watershed_feature_id`), rolled up upstream by FWA watershed code (tables `bcwat_ws.fwa_fund`, `bcwat_ws.fund_rollup_report`).
    - Historical only. Future climate in the reports is ClimateWNA, not scenario flow.
  - The methods documentation is sparse and ships no model code; the Province is reportedly discussing improvements.
  - Once the data arrive: map which watershed groups it covers, join on `watershed_feature_id`, and compare with PCIC-based `wet` output and HYDAT where both exist (#6).

## Done when

- A coverage map shows which product serves each watershed group.
- The chosen gap-fill method is validated on HYDAT basins outside the PCIC domain.

Relates to #1, #9.




## Plan-mode exploration (2026-09-26)

- **Raven channel-scale domain is fetchable in bulk.** The `chyp` portal is backed by an OGC API Features server, `https://services.pacificclimate.org/bbox-server/collections`. `rivers` holds 26,662 reaches (MultiLineString, BC Albers, props `uid`, `dowsubid`, `islake`) and `lakes` is its own collection. That is enough to intersect the Raven domain with watershed groups without per-site downloads.
- **PCIC gridded mask:** one day of `RUNOFF` over the full grid via `wet_pcic_fetch()` (`R/wet_pcic_fetch.R`); non-NA cells are the domain.
- **fwapg** (`fresh-db`): `whse_basemapping.fwa_watershed_groups_poly` has 246 groups. There is no hydrometric table locally, so stations come from HYDAT.
- **HYDAT** (`tidyhydat` sqlite, 2025-12-04): 1,442 natural-flow (`REGULATED = 0`) BC stations. About 400 are in sub-basins outside PCIC: 08B–08H (Stikine, Nass, Skeena, coastal), 08O/08P, 09A, 10A–10D (Liard).
- **Snapping:** `fresh::frs_point_snap(conn, x, y, num_features = n, ...)` (fresh 0.33.0), with a candidate picker on HYDAT `DRAINAGE_AREA_GROSS`, as #6 proposed.
- **BCWT tables** (`nr-bcwat/database_initialization/table_data_types.py`):
  - `fwa_fund` has **both** `watershed_feature_id` and `watershed_feature_id_foundry`, plus `in_study_area`. Foundry's ids may not match FWA's, so a crosswalk check is needed.
  - `fund_rollup_report.watershed_metadata` is a JSON string.
  - Data is staged via S3 CSV exports (`all_data_transfer.py`).
- **In-sample caveat:** Chapman et al. 2018 fitted BCWT to unregulated WSC stations, so a HYDAT comparison is largely in-sample and has to be reported that way.
- Installed: fresh, fasstr, tidyhydat, bcdata, sf, tmap, gq. climr is **not** installed (not needed under this decision).

## Overlap with #6

Station selection, snapping and the observed climatologies are the machinery #6 also needs. They are built here as exported `wet_station_*` functions, and #6's body is edited to reuse them. #6 keeps the PCIC-inside-domain bias report.

## Scope revision (2026-09-26, after the plan gate)

The user redirected the work: do not wait on PCIC or adopt another group's product. Spin our own estimate and evaluate it against other groups' data. The reason: in the past the model code has not shipped with the data (BC Water Tool ships data and sparse method notes, no model code). Building our own tells us whether we are on the right track, and the comparison may surface inconsistencies, errors and inaccuracies on either side.

Method chosen: an open reimplementation of Chapman, Kerr & Wilford 2018 (the BC Water Tool method). It is like-for-like with BC Water Tool, so a disagreement traces to a step. It also runs inside the PCIC basins, where it can be checked against VIC-GL.

- climr is not installed, and it is needed for Phase 4.
- Where Obedkoff (2000) regions exist as data is still unknown.

## Local sweep before building (2026-09-26)

- **The P half of P − ET already exists.** fwapg `extras/precipitation` computes ClimateBC mean annual precipitation per fundamental watershed and the area-weighted upstream mean.
  - Source: `Normal_1991_2020` `MAP.tif` from climatena.ca, cached on NRS object storage. climr mosaics cover transboundary areas.
  - Output: `whse_basemapping.fwa_stream_networks_mean_annual_precip`, which is populated in the local `fresh-db`: 3,075,336 rows, all 246 groups, MAP 12–9,108 mm.
  - It is **annual only and 1991–2020**. Chapman needs monthly P and T, and the PCIC baseline is 1981–2010, so the period is a choice to make.
- NGE packages: no exported runoff, discharge or HYDAT station functions. `ngr` imports tidyhydat for realtime flows only, and `fresh` has watershed delineation (`frs_watershed_at_measure`). Nothing to reuse beyond fresh snapping and delineation.
- Zotero has neither Chapman et al. 2018 nor Obedkoff 2000.

## Errors Encountered

| Error | Resolution |
|-------|------------|
