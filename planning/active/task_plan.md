# Task: Coverage beyond Peace, Fraser and Columbia (#5)

Issue #1 item 4. PCIC gridded hydrology covers only the Peace, Fraser and Columbia. The Skeena, Nass, Stikine, Liard, coastal and northern basins have no modelled per-cell runoff on the portal.

**Done when:** a coverage map shows which product serves each watershed group, and the chosen gap-fill method is validated on HYDAT basins outside the PCIC domain.

**Decision at the plan gate (2026-09-26):** build the coverage map and a method-agnostic HYDAT validation harness now. BC Water Tool ingest and validation is the last phase, run when the data is released. If it has not landed by PR time, that phase moves to a follow-up issue and #5 stays open.

## Phase 1: Coverage — PCIC gridded and Raven channel-scale per watershed group
- [ ] `wet_chyp_reaches()`: page the `bbox-server` `rivers` (and `lakes`) collections into one sf, in one R process, cached under `data/coverage/`. Test with a mocked page, plus a live `skip_on_ci()` canary.
- [ ] `scripts/coverage_wsg.R`: PCIC gridded domain mask (one day of RUNOFF, non-NA cells to polygons) ∩ `fwa_watershed_groups_poly`, giving the covered-area fraction per group. Raven reaches ∩ groups gives reach length and fraction per group.
- [ ] Assign a product per group (PCIC gridded / Raven / none yet), with a `bcwt` column left NA until Phase 4. Write the tracked report `data/checks/coverage_wsg.txt`.
- [ ] Coverage map with tmap + gq registry, committed as `research/coverage_wsg.png`. Run the full self-review list (placement 1–7 and communication 8–12).

## Phase 2: HYDAT validation station set outside PCIC
- [ ] `wet_station_select()`: HYDAT natural-flow BC stations with ≥ 20 complete years in 1981–2010, carrying `DRAINAGE_AREA_GROSS` and lat/lon. Tests against the local sqlite (skip if absent).
- [ ] `wet_station_snap()`: `fresh::frs_point_snap(num_features = n)` plus a candidate picker on drainage-area ratio, returning `linear_feature_id`, `watershed_feature_id`, FWA codes, accumulated upstream area and area ratio. Tests on stations at a confluence, a mainstem and a headwater.
- [ ] `wet_station_monthly()`: observed monthly climatology and MAD over the baseline via `fasstr`.
- [ ] Tag each station with its watershed group, PCIC-gridded coverage (from Phase 1) and Raven coverage. Write the tracked station list `data/checks/stations_outside_pcic.txt` (count, area-ratio distribution, rejected snaps with reasons).

## Phase 3: Method-agnostic validation harness
- [ ] `wet_flow_validate(modelled, observed)`: MAD ratio, monthly ratio and bias, % of stations within ±20 % (Chapman's metric), and NSE on the monthly climatology. Grouped by region, season and drainage-area class. Unit tests on synthetic data, including the zero-flow and missing-month cases.
- [ ] Harness sanity run: PCIC-`wet` at a handful of inside-domain stations, to prove the plumbing end to end (not #6's bias report).

## Phase 4: BC Water Tool ingest and validation (gated on data release)
- [ ] Check release state. If not released: file a follow-up issue carrying this phase, and skip to Phase 5.
- [ ] Inspect the release: format, licence, regions covered, and whether ids are FWA `watershed_feature_id` or Foundry ids (crosswalk check).
- [ ] `wet_bcwt_read()`: parse the per-watershed monthly discharge (`fund_rollup_report.watershed_metadata`) to a `watershed_feature_id` × month table.
- [ ] Fill the `bcwt` column in the coverage report and map.
- [ ] Validate on the Phase 2 stations with `wet_flow_validate()`. Report it as in-sample (BCWT was fitted to WSC stations), and separate stations added after their fit where identifiable.
- [ ] Where PCIC and BCWT overlap, compare BCWT with PCIC-`wet` at the same stations.

## Phase 5: Record
- [ ] `research/coverage.md`: product-by-group verdict, Raven OGC endpoint, BCWT table and id facts, and the validation result or its pending state. Add a row to `research/README.md` and update `research/pcic_hydrology.md`'s channel-scale section with the `bbox-server` endpoint.
- [ ] Edit the #5 and #6 issue bodies: #5 with the coverage verdict and the BCWT status; #6 to reuse the `wet_station_*` functions.
- [ ] NEWS entry, `pkgdown`/README touch only if the exports need it.

## Validation

- [ ] Tests pass (`devtools::test()`), lintr clean, `devtools::document()`
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
