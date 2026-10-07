# Task: Dry-interior runoff: find which term is off, then fix that one (#45)

- In the semi-arid interior, runoff is a small remainder of precipitation, so a small error in either term is a large one in runoff.
- #15 and #18 tried alternative AET products. Neither tested the precipitation side, ERA5-Land evaporation, or a diagnosis of which term is off.
- PCIC's VIC-GL output includes PREC and EVAP (`research/pcic_hydrology.md`). Inside its domain it gives an independent split to compare against, used as a reference, not an input (CLAUDE.md, "Own estimates first").

**Scope (decided at the plan gate, 2026-10-07):** diagnosis plus the written lever choice and rule. Building and scoring the lever goes to a new issue, or to a cd issue on the ERA5-Land branch. The #45 body gets edited to match, and the PR says `Relates to #45`.

What exploration settled:
- **PCIC covers the problem.** 38 of the 40 calibration gauges in zones 15/17/23/24 are in PCIC's coverage, and fwapg has a value at 36. On those, mean error for the balance vs fwapg: zone 24 +93 % vs +22 %, zone 17 +48 vs +13, zone 23 +20 vs +9, zone 15 +3 vs +19. So PCIC's split is a usable reference exactly where we're weak (from `inst/vignette-data/segment_values.rds`).
- **Reuse:**
  - `wet_pcic_annual()` (cached per year), `wet_ws_fetch()`, `wet_ws_sample(method = "area")`, `wet_upstream_means()`;
  - our P, AET and PET at every station watershed are already in `data/wb/962a9cc2c4/upstream/*.rds` on m1 (`p_yr`, `aet_cfu`, `aet_yr`, `aet_mod16`, `pet_yr`, `ppt_tc`, zone shares);
  - obs and held-out predictions are in `fit_20260717/cv_aet-cfu.rds`, and stations in `stations_20260717.rds`.
- **#5 already has #39's gauge-level score**, on the 2025-10-14 fit (168 gauges, 30.5 vs 25.5). The remaining step is refreshing it to the shipped fit (183 gauges, 30.3 vs 25.3; Columbia 33.7 vs 25.0, from §0).
- **The ECCC P check (`data/checks/climr_eccc.txt`) covers only 57 WMO 'A' stations province-wide,** mostly valley floors. It says little about plateau P in the dry zones.
- **No scoring code changes** on this branch, so no fit goes stale and nothing needs m4.

## Phase 1: Diagnose (m1)

- [x] Pre-register the attribution rule in `findings.md` and commit it **before** any PCIC number is computed (rule below)
- [x] `scripts/wb_term_diagnose.R`: PCIC `PREC`, `EVAP`, `RUNOFF` and `BASEFLOW`, 1981–2010 (the fwapg MAD period), mean annual over the Peace/Fraser/Columbia bbox via `wet_pcic_annual()`. Cached under `data/pcic/`, long fetch run in the background with a teed log
- [x] Same script: area-weighted sample per fundamental watershed (`wet_ws_sample`) and upstream means per basin (`wet_upstream_means`) for FWA basins 100/200/300. Keep the calibration gauges' watersheds, joined to our `p_yr`, `aet_cfu`, `pet_yr`, zone, nesting, obs and held-out prediction
- [x] Checks that PCIC is internally sound before it is used as a reference:
  - its RO+BF at the gauges against fwapg's stored MAD (`fwapg_mm`), which should agree;
  - its closure, P − EVAP − (RO+BF): the glacier and storage residual, by zone
- [x] Per gauge and per zone (15, 17, 23, 24, plus every other in-domain zone as contrast):
  - P ratio, ours / PCIC;
  - AET, ours (cfu) against EVAP;
  - gauge-implied AET (P − Q) under each P;
  - implied AET / PET (Hargreaves `pet_yr`): a value above 1 means P is too high, or the gauge loses water
- [x] Independent P check: climr against ECCC 1981–2010 normals at **all** ECCC stations in the four dry zones, not only 'A'. Reuse the `wb_inputs.R` ECCC code path; report station elevation against basin elevation
- [x] Write `data/checks/wb_term_diagnose_20260717.txt` (named by `wb_report()`) (tracked) with the per-zone attribution: ours (P or AET), theirs, gauge side or unresolved
- [x] `research/water_balance_method.md` §0: new subsection "Which term is off in the dry interior (#45)" with header provenance. Update the Follow-ups and the zone 24 "Still unresolved" candidate list
- [ ] Refresh #5's body: the #39 PCIC line moves to the fit_20260717 numbers and points at #45's diagnosis

**Pre-registered attribution rule:** superseded by `findings.md` ("Pre-registered attribution rule" and "Amendment 1"). The text below is the plan-gate proposal, kept for the record. For each zone, using medians over its in-domain gauges:
- PCIC is a usable reference in a zone only if its median absolute log error against obs is ≤ 0.25 and its closure residual is ≤ 10 % of P.
- Decompose our runoff gap against PCIC: (P_o − A_o) − (P_c − E_c) = ΔP − ΔA.
- **P side (ours)** if ΔP ≥ ⅔ of the gap, and at least one independent test agrees: implied AET > PET at ≥ half the zone's gauges, or the median ECCC ratio in the zone is ≥ 1.10.
- **AET side (ours)** if −ΔA ≥ ⅔ of the gap and implied AET under our P is ≤ PET at most gauges.
- **Gauge side (unresolved, withdrawals or groundwater)** if PCIC also overshoots by a similar log error.
- **Theirs** where PCIC is the one off the gauges and our terms sit closer to the implied values.
- **Unresolved** otherwise.

## Phase 2: Pick the lever (written, not built)

- [x] Apply the issue's mapping to the phase-1 verdict for zones 17/23/24 (15 is close already):
  - **P side:** a precipitation correction where climr departs from gauge-implied totals. Specify the candidate layer and how it stays independent of the gauges it is scored on;
  - **AET side:** ERA5-Land total evaporation through cd. File the cd issue for `total_evaporation` in the catalogue (draft shown first);
  - **Gauge side or unresolved:** no lever; name the evidence that would decide it
- [x] Pre-register the scoring rule in the style of #15 (a)–(d), against the #43 baseline (fit_20260717, 27.5 % / 30.7 % headwater), plus a dry-zone criterion. Recorded in `findings.md` and the research subsection
- [ ] File the follow-up issue to build and score the lever (draft shown in the conversation first); edit the #45 body so phases 2–3 point to it

## Phase 3: README accuracy (requested 2026-10-07)
- [x] README states what wet now covers (discharge, station flow departure, water temperature, open water balance), each checked against the exports and vignettes, not restated from memory

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
