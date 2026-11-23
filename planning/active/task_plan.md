# Task: Backlog move 6: Pilot PCIC's channel-scale output on the FWA (#168)

**If we do it:** PCIC's channel-scale output (VIC-GL-Raven, CMIP6) is compared at about six representative FWA sites with wet's accumulation, routed PCIC and HYDAT, with every manual step and crosswalk mismatch recorded, and a decision on whether to use it where it covers the network. **If we never do:** scenarios (#4) and coverage (#5) are built on gridded CMIP5 without knowing whether the routed CMIP6 product is better.

Carries #9 (batch 9 of `planning/backlog.md`). Its verdict is the oracle move 7 (#169: #4 scenarios, #5 coverage) waits on, in `research/pcic_channel_scale.md`.

## Decided at the gate

No plan gate in this pane: `/backlog-dispatch` claimed #168 for this session under a running `/coordinator` (`GATE=coordinator`, soul#928), so the plan was drafted without the owner and parked for the coordinator's plan gate. A Plan review ran before the baseline (`review-plan.md`); its corrections are folded in below, each phase naming what it changed. Every decision #168 reserves for the owner, and every scope change the drafted plan made to #9, was listed as an open decision with a recommendation; the phases are written for the recommended answers, which the owner chose at the resume (below).

What the exploration found (details in `findings.md`), which the recommendations rest on:

- **The channel-scale product looks like hydromosaic, the run wet already publishes.** The portal (`services.pacificclimate.org/chyp`) reads `bbox-server` collections keyed on PCIC's `subid`; hydromosaic (`services.` and `beehive.pacificclimate.org/hydromosaic`, the host fwapg's crosswalk fetched from) lists, at outlet 4008184, the models, scenarios and variables the portal describes: streamflow, water_temp and DO_sat for PNWNAmet (`historical`, 1950–2012, 23,011 days) and 9 CMIP6 GCMs × `historical, ssp245` / `historical, ssp585` (1950–2100, 55,152 days). The portal's bundle names no hydromosaic path and no streamflow download (only GeoJSON), so the identity rests on the shared `subid` network, runs and variables; Phase 1 tries to confirm it. fwapg's crosswalk (fwapg#5, #25, #42) places hydromosaic's outlets on the FWA, and wet publishes the PNWNAmet run as `pcic_routed`, scored at 283 gauges (`scripts/pcic_routed_compare.R`, `scripts/gauge_monthly_compare.R`).
- **What is still unknown:** whether the published segment equals PCIC's own outlet series (`research/monthly_error.md`, "What check 1 does not reach"); whether the CMIP6 runs' 1981–2010 flow matches PNWNAmet's; and whether fwapg's crosswalk can hold a CMIP6 run, whose outlets with series may differ from PNWNAmet's (fwapg refuses a run whose crosswalk differs from the stored one).

### The owner's answers, 2026-11-22 (at the resume)

The recommended option of each: 1 (d), 2 accepted as listed, 3 (b), 4 (a), 5 (a). The decisions as asked:

1. **What the pilot measures.** Every option but (b) also carries three scope changes to #9: no portal downloads and no hand crosswalk (fwapg's crosswalk already did both province-wide); fwapg's `mad_m3s` dropped as a comparison (a stale snapshot, which `scripts/mad_basin.R` already attributes against wet's own accumulation, read here instead); no `R/` reader (a pilot reads hydromosaic in its script; a reader joins the package only if move 7 builds on the API). And a CMIP6 verdict means scenarios built on PCIC's routing, with wet's own balance checking only their historical run ("own estimates first").
   - (d, recommended) Rules 1 and 2 below at every scored calibration gauge whose segment is a placed outlet's own segment (from the 283 the segment-discharge article scores), through hydromosaic's bulk endpoint (streamflow only: PNWNAmet and the 9 GCMs' historical part, about 1 GB), with the six sites showing one case of each mismatch type and the size of the sampling difference.
   - (a) The same rules at the six sites only: four or five gauges' evidence for the verdict move 7 builds on.
   - (b) #9 as written: portal downloads and a hand crosswalk at six sites, repeating fwapg's crosswalk.
   - (c) Close #9 as answered by fwapg's crosswalk and plan move 7 from CMIP6 through fwapg's job, with no comparison.
2. **The six sites,** all in the Fraser (checked by the review against HYDAT 20260717): small headwater (< 10 km², ungauged, chosen by the Phase 1 rule: in practice an interior segment of a sub-basin, sub-basins averaging about 20 km²); mid-size gauged tributary, 08KC001 Salmon River near Prince George (4,226 km², 25 full years); lake outlet, 08KH001 Quesnel River at Likely (5,964 km², 30); confluence, by the Phase 1 rule; large mainstem, 08MF005 Fraser River at Hope (216,600 km², 30, regulated since 1952 by Kenney Dam, which PCIC does not model, so PCIC runs high there by construction); glacier-fed, 08MG005 Lillooet River near Pemberton (2,076 km², 29). No gauged site is under 1,000 km²; under 1 (d) the scored gauges cover small basins, under 1 (a) one of SALR's neighbouring small gauges (`research/water_balance_method.md`) should replace or join one. Alternative: swap a site for a coastal one (a Bulkley gauge).
3. **CMIP5 gridded at the sites.** (b, recommended) Leave CMIP5 to move 7: rule 3 lets change signals decide nothing, and the Fraser bbox is about 40 GB (12 runs × 90 years × RUNOFF and BASEFLOW) with an unmeasured fetch time. Move 7 then takes 2070–2099 (the CMIP5 runs end 2099-12-31), checks the runs' calendars first (HadGEM2-ES runs natively on 360 days, and `wet_pcic_index()` assumes a standard calendar), and notes that the CMIP5 runs carry no glacier model, so their change at Lillooet lacks glacier retreat. (a) Annual CMIP5 at the five sites other than Hope, small bboxes, 1981–2010 and 2070–2099.
4. **Water temperature.** (a, recommended) Fetch PNWNAmet `water_temp` at the six outlets and report its 1981–2010 monthly climatology; score it against water-temp-bc daily means (`wet_temp_daily()`) only on the same days, within 2002–2012, at a site whose station has them, after checking coverage (year-round records are sparse before the 2010s, so expect few or none). No verdict on temperature. (b) Leave temperature out.
5. **How strict the verdict is.** (a, recommended, with 1 d) A domain passes rule 1 when at least 90 % of its outlet-segment gauges agree, and rule 2 when the median over its gauges meets it; failing gauges are listed with their mismatch type. (b) Every gauged site must pass (with 1 a: one gauge sinks the Fraser).

## Open decisions

None open. A fork met during the build is written here.

## Phase 1: Database, probes and the registered rule

Review: added (O1–O3, B1, B3, G1, G3–G6, G11, G12, A2, X1): the local database was not running, the probes that shape the rule run before it, and the rule is rewritten.

- [x] Ask the owner to start the local fwapg (a machine change), then probe with `DBI::dbConnect(..., connect_timeout = 10)`; read the routed run's fingerprint against `pcic.runs` (`routed_fingerprint()`), and confirm `WET_FWAPG_COMMIT` from the fwapg checkout that built the schema (the database does not record it).
- [x] Probes that read no flow value: the PNWNAmet series end (2012-12-31, 23,011 days; already listed at 4008184) and a GCM's (2100-12-31, 55,152); CMIP6 series at one placed outlet per domain (Fraser, coast, Peace, Columbia: `GET /outlets/{subid}/timeseries`); whether the portal's per-feature CSV download is hydromosaic's series (from the portal's docs or one download; if it cannot be settled, the report says the identity rests on the shared network, runs and variables). Under 1 (d), the scored gauges whose segment is an outlet's own segment (`pcic.fwa_crosswalk.linear_feature_id`), and their count by domain.
- [x] `scripts/channel_scale_pilot.R` header, committed before any flow value is read; the report prints this commit's sha and time, the md5 of the rule block as run, and the UTC time of the first fetch from the fetch log:
  - Site rules: the headwater is the smallest-area segment under 10 km² with a `pcic.segment_weights` row in the 08KC001 basin; the confluence is, among fwapg's junctions where a tributary's flow still lands on the segment above (`extras/pcic_crosswalk/README.md`, about 680 of 19,000), the one nearest a scored gauge, else the largest such junction in the Fraser.
  - Rule 1 (the crosswalk reproduces PCIC), on an outlet's own segment: the published 1981–2010 annual flow (the plain mean of the 12 monthly means, as month 0 is published) within 1 % of the raw outlet series' annual flow taken the same way, and each month within max(2 %, 1e-4 m³/s); the ratio is reported, and anything past 1e-4 relative is flagged "not exact". Where it fails on an outlet with `flag` NULL, the series is fetched again from beehive (and compared with fwapg's `data/nc/PNWNAmet_historical/` cache if the build machine has it) before a mismatch type is named, since a series revised since fwapg's build would read as a crosswalk failure. At an interior segment (the headwater), the published value is rebuilt from raw series, `sum raw(upstream_subids) + (raw(subid) − sum raw(children)) × share`, which checks the arithmetic only; the share itself is compared with wet's area-based accumulation.
  - Rule 2 (CMIP6 usable): from the `historical, ssp245` series (after asserting `historical, ssp585` equals it before 2015, or reporting that it does not), `|median_GCM − PNWNAmet| / Q_HYDAT ≤ 0.05` on 1981–2010 annual flow, and the 9-GCM median's monthly share NSE (`wet:::wet_nse()` on twelve monthly shares against the gauge's, as `scripts/gauge_monthly_compare.R` does) no more than 0.05 below PNWNAmet's.
  - Rule 3 (the verdict for move 7, by domain, under decision 5's form): in the Fraser, the one domain with both CMIP5 gridded and CMIP6 routed, CMIP6 through fwapg's crosswalk where rules 1 and 2 pass; on the coast it is CMIP6 or nothing (no CMIP5 gridded); in the Peace and Columbia, CMIP5 until PCIC adds them, unless the domain probe found CMIP6 series there. Move 7's first check, stated in the verdict: whether each CMIP6 run's outlets with series match PNWNAmet's, which fwapg's crosswalk needs. Change signals are reported and decide nothing.
  - The share of placed outlets by `flag` (NULL, `no_candidate`, `no_series`, `broken_chain`, `demoted`) in the Fraser and on the coast, from `pcic.fwa_crosswalk`, answering #9's "what share needs flags".

## Phase 2: Sites

Review: 08KC001 replaces "SALR's Salmon River gauge" (it drains part of SALR but is not in it); Hope's regulation is a column, not a filter (B2, A1).

- [x] `scripts/channel_scale_sites.csv`, one row per site type: `site_id, type, name, station, blue_line_key, downstream_route_measure, linear_feature_id, wsg_code, regulated`, from decision 2's answer and Phase 1's site rules (the site-table convention: the script takes a site id).
- [x] Gauged sites take their segment from the snapped stations in `data/wb/stations_<release>.rds` (the scored set); full years are counted directly (≥ 20 complete years in 1981–2010, the count `wet_station_select()` uses, without its unregulated filter), with the regulation flag recorded. The report prints each row's checks: station years, regulation, its `pcic.segment_weights` row, its outlet's `pcic.fwa_crosswalk` row (`flag`, `islake`, `distance_to_stream`, `candidate_rank`), upstream area and stream order.

## Phase 3: PCIC's outlet series

Review: the PNWNAmet run ends 2012 (G12); under 1 (d) the bulk endpoint fetches every scored outlet (G2); an interior site needs its upstream and child outlets too (B3); timings stay out of the report (X2).

- [x] Fetch streamflow for PNWNAmet and the 9 GCMs (`historical, ssp245`; `ssp585` too at the six sites, for the change signals and the pre-2015 check) at each site's outlet, and for the headwater also its `upstream_subids` and its sub-basin's child outlets; under 1 (d), the same PNWNAmet and `ssp245` series for every scored outlet-segment gauge through `POST /hydromosaic/bulk-downloads` (one source domain per request, at most 500 outlets, as fwapg's job does). Under 4 (a), PNWNAmet `water_temp` at the six outlets. Host `services.pacificclimate.org`, `curl` with `--max-time` and a generic user agent, into `data/channel_scale/raw/` (gitignored), fetched once and md5-recorded, with the listing's ids and dates.
- [x] Refuse a series whose row count differs from its listing's `num_times` or whose dates leave a gap. Drop day 1 (1950-01-01, as fwapg does; it touches no window used here).
- [x] The fetch log (`data/logs/168/`) records requests, bytes and wall time; the report reads the scaling cost from it, so a rerun from the cache prints the same numbers. Every step done by hand is listed (expected: the site table and starting the database).

## Phase 4: Compare

Review: rule 2 restated (G1); CMIP5 dropped under 3 (b) (S1); the libraries sourced and the data paths named (G8, G10); the frozen copy defined (X3).

- [x] The script runs after `devtools::load_all()`, sourcing `scripts/wb_fit_lib.R` (`wb_hydat()`, `WET_HYDAT_RELEASE`, default `wb_shipped_release`) and `scripts/pcic_routed_lib.R` only, not `wb_cv_lib.R`. Its data inputs (`stations_<release>.rds`, `data/pcic/`) are read under one `data_root` (default `data`), set to the main checkout's `data/` when it runs from this worktree, so the cached 1981–2010 PNWNAmet gridded runoff (`TPS_gridded_obs_init` RUNOFF and BASEFLOW, the Fraser bbox `y120-242_x192-367`) is not fetched again.
- [x] Over 1981–2010, monthly climatology and annual flow at each site and (under 1 d) each scored gauge, from: HYDAT (`wet_station_monthly()`); PCIC's raw PNWNAmet outlet series; routed PCIC as published (`wet_segment_monthly(source = "pcic_routed")` from the parts with `groups`, the manifest's md5 in the report) and from fwapg (`from = "fwapg"`, `routed_report_line()`); the balance as published (`source = "wet_balance"`); each GCM's 1981–2010 flow and the 9-GCM median; and, at the six sites, wet's unrouted accumulation of the gridded runoff (RUNOFF + BASEFLOW; `wet_ws_fetch()` → `wet_ws_sample()` centroid and area → `wet_upstream_mean()` with `wet_upstream_irregular()` pairs → `wet_mm_to_m3s()`, on live accumulated area, not fwapg's stored one), done in the pilot script, not by rerunning `scripts/mad_basin.R` (which rewrites the tracked `data/basin/100_report.txt`).
- [x] Rules 1 and 2 at every site and scored gauge, with the mismatch type named where rule 1 fails: outlet placed on another segment, a lake outlet, a tributary landing on the segment above, an area-share interior segment, a series revised since fwapg's build, or a missing outlet. Hope's HYDAT comparison carries its regulation.
- [x] CMIP6 change signals at the six sites, 2041–2070 and 2070–2099 against 1981–2010, per GCM and SSP, annual and by month (2070–2099 so move 7 can set CMIP5's beside them).
- [x] Under 4 (a), PNWNAmet water temperature at the sites, as decision 4 says.
- [x] Report `data/checks/channel_scale_pilot_<release>.txt`: the rule provenance (sha, block md5, first fetch), the inputs (HYDAT release, routed run, fwapg commit and fingerprint, live manifest md5, series md5s), the domain probe, the flag shares, the site checks, one table per rule, the verdict. Two runs from the same frozen inputs (raw series by md5, the HYDAT release, the database fingerprint, one manifest) give a byte-identical report (log under `data/logs/168/`).

## Phase 5: Verdict, write-up and the issues

- [x] `research/pcic_channel_scale.md` (provenance line, verdict first, per-domain and per-site tables, mismatch types, flag shares, scaling cost, what move 7 builds on per domain and its first check), and its row in `research/README.md`.
- [x] Revise `research/pcic_hydrology.md`'s channel-scale section (the product, the run wet publishes, as far as Phase 1 settled it) and `research/monthly_error.md`'s "does not read PCIC's raw hydromosaic series" paragraph to cite the pilot.
- [x] CLAUDE.md: the pilot script under Scripts; the "PCIC channel-scale" Data Sources line rewritten with the pilot's result.
- [ ] Edit #9's body (its premise, portal downloads and a hand crosswalk, is superseded) and #169's (move 7 reads the verdict, takes 2070–2099 for CMIP5 and checks the runs' calendars); a comment on fwapg#28 naming the verdict, since its first condition is "the option already on the table".
- [ ] Before the worktree is removed, move `data/logs/168/` into the main checkout's `data/logs/`.

## Owed at the end (reported, done after merge)

- [ ] Draft a short note to PCIC with the pilot's result, as #9 asks ("share the result with PCIC if it supports scaling up"); shown to the owner, sent only with their word (outside our repos).

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved: the rule's commit precedes the first fetch (the report prints both, X1); the report is byte-identical across two runs from the same frozen inputs; the report prints each site's checks, the domain probe and the flag shares; the routed fingerprint equals `pcic.runs`'s row; `/code-check` checks that every value in `research/pcic_channel_scale.md` is a line of the tracked report; `gh issue view 9` and `gh issue view 169` show the edited bodies; `devtools::test()` and `lintr` are unchanged by a branch that adds no `R/` code.
