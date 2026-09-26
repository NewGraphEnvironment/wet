# Task: Coverage beyond Peace, Fraser and Columbia (#5)

Issue #1 item 4. PCIC gridded hydrology covers only the Peace, Fraser and Columbia. The Skeena, Nass, Stikine, Liard, coastal and northern basins have no modelled per-cell runoff on the portal.

**Done when:** a coverage map shows which product serves each watershed group, and the chosen gap-fill method is validated on HYDAT basins outside the PCIC domain.

**Decisions (2026-09-26):**

- At the plan gate: build the coverage map and a method-agnostic HYDAT validation harness first.
- Revised after the gate (user): **spin our own estimate rather than adopt someone else's.** Other groups' products (PCIC, BC Water Tool) are references to evaluate against, not candidates to adopt, because their model code does not ship with their data. Building our own tells us whether we are on the right track, and the comparison can surface inconsistencies, errors and inaccuracies on either side.
- Method: an **open reimplementation of Chapman, Kerr & Wilford 2018** (the BC Water Tool method). It is like-for-like with BC Water Tool, so a disagreement traces to a step: their data, their fit, or our code.
- The BC Water Tool comparison runs if its data is out by PR time. Otherwise it moves to a follow-up issue and #5 stays open.

## Phase 1: Coverage — PCIC gridded and Raven channel-scale per watershed group
- [ ] `wet_chyp_reaches()`: page the `bbox-server` `rivers` (and `lakes`) collections into one sf, in one R process, cached under `data/coverage/`. Test with a mocked page, plus a live `skip_on_ci()` canary.
- [ ] `scripts/coverage_wsg.R`: PCIC gridded domain mask (one day of RUNOFF, non-NA cells to polygons) ∩ `fwa_watershed_groups_poly`, giving the covered-area fraction per group. Raven reaches ∩ groups gives reach length and fraction per group.
- [ ] Assign a product per group (PCIC gridded / Raven / none yet), with a `bcwt` column left NA until Phase 4. Write the tracked report `data/checks/coverage_wsg.txt`.
- [ ] Coverage map with tmap + gq registry, committed as `research/coverage_wsg.png`. Run the full self-review list (placement 1–7 and communication 8–12).


## Phase 2: HYDAT station set, province-wide
- [ ] `wet_station_select()`: HYDAT natural-flow BC stations with ≥ 20 complete years in 1981–2010, carrying `DRAINAGE_AREA_GROSS` and lat/lon. Tests against the local sqlite (skip if absent).
- [ ] `wet_station_snap()`: `fresh::frs_point_snap(num_features = n)` plus a candidate picker on drainage-area ratio, returning `linear_feature_id`, `watershed_feature_id`, FWA codes, accumulated upstream area and area ratio. Tests on stations at a confluence, a mainstem and a headwater.
- [ ] `wet_station_monthly()`: observed monthly climatology, monthly share of annual runoff, and MAD over the baseline via `fasstr`.
- [ ] Tag each station with watershed group, PCIC-gridded coverage and Raven coverage (from Phase 1). Write the tracked list `data/checks/stations_bc.txt`: counts inside and outside PCIC, area-ratio distribution, rejected snaps with reasons.

## Phase 3: Validation harness
- [ ] `wet_flow_validate(modelled, observed)`: MAD ratio, monthly ratio and bias, % of stations within ±20 % (Chapman's metric), and NSE on the monthly climatology. Grouped by region, season and drainage-area class. Unit tests on synthetic data, including the zero-flow and missing-month cases.
- [ ] Out-of-sample splits: leave-one-basin-out folds on nested stations (a station and everything upstream or downstream of it go in the same fold, via FWA codes). Test that no fold leaks a nested pair.
- [ ] Harness sanity run: PCIC-`wet` at a handful of inside-domain stations, to prove the plumbing end to end (not #6's bias report).

## Phase 4: Our own estimate — open Chapman 2018
- [ ] Pin the method from the paper (JAWRA 54:676) and the nr-bcwat knowledge-transfer doc: inputs, the regression forms, region boundaries and baseline. Record in `findings.md` every place where the paper is silent and what we chose.
- [ ] Inputs: climr 1981–2010 normals (annual and monthly P and T, and an ET term) per fundamental watershed. Region boundaries: Obedkoff (2000) if obtainable as data, otherwise a documented substitute.
- [ ] Annual water balance per fundamental watershed (P − ET), accumulated upstream with `wet_upstream_mean()`. Fit the gauge-residual adjustment by region.
- [ ] Monthly-share regressions per month, fitted to the Phase 2 stations, with shares constrained to sum to 1.
- [ ] Exported functions for each step, one file each, with tests (`wet_wb_annual()`, `wet_wb_adjust()`, `wet_wb_monthly()` or names that fit on inspection).
- [ ] Out-of-sample validation with the Phase 3 folds, inside and outside PCIC. Write the tracked report `data/checks/wb_validation.txt`.

## Phase 5: Evaluate against others' products
- [ ] PCIC-`wet` (VIC-GL) vs ours in the Peace, Fraser and Columbia: per-station and per-group differences.
- [ ] PCIC Raven at the #9 pilot sites, if the pilot has data by then; otherwise leave it to #9.
- [ ] BC Water Tool: check release state. If released, inspect format, licence, regions and ID type (FWA vs Foundry `watershed_feature_id`); `wet_bcwt_read()` parses `fund_rollup_report.watershed_metadata` to `watershed_feature_id` × month; fill the `bcwt` coverage column; compare with ours and with HYDAT (theirs is in-sample, ours out-of-sample). If not released, file a follow-up issue carrying this item.
- [ ] Log every material disagreement in `findings.md` as ours, theirs, or unresolved, with the evidence.

## Phase 6: Record
- [ ] `research/coverage.md` (coverage verdict, Raven OGC endpoint) and `research/water_balance_method.md` (the method as built, the choices where the paper is silent, the validation numbers, the disagreements). Rows in `research/README.md`; add the `bbox-server` endpoint to `research/pcic_hydrology.md`.
- [ ] Edit the #6 issue body to reuse the `wet_station_*` functions, and bring the #5 body up to date with the outcome.
- [ ] NEWS entry; README touched only if the exports need it.

## Validation

- [ ] Tests pass (`devtools::test()`), lintr clean, `devtools::document()`
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
