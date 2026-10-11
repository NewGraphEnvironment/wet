# Task: Per-segment flow from either source: routed PCIC where placed, open balance elsewhere (#57)

**If we do it:** each segment carries the best estimate available there (PCIC's routed flow where an outlet is placed, our open water balance elsewhere), labelled with its source, and a report can switch sources or take PCIC's projections without a new pipeline. **If we never do:** the per-segment product publishes only the balance, which is the less accurate estimate on the 69 % of segments PCIC's routed flow already covers, or each report picks a source ad hoc.

## Phase 1: Pick rule, tests first
- [x] `tests/testthat/test-wet_source_pick.R`: NA routed → balance; NA balance → routed; both NA → NA; ratio < cut → balance; ratio = cut → routed; balance 0 → routed; vectorised, length-checked
- [x] `R/wet_source_pick.R`: internal (`@noRd`) `wet_source_pick(q_routed, q_balance, far_low = 0.2)` returning `"pcic_routed"`/`"wet_balance"`/NA per segment
- [x] `scripts/pcic_routed_lib.R`: `routed_far_low` stays the one definition of the cut; the scripts pass it in

## Phase 2: Per-segment table
- [x] `scripts/segment_output.R`. It reads the shipped fit's balance output (refusing a fit under other scoring code, as `wb_output.R` does), the routed table (refusing a fingerprint/`WET_FWAPG_COMMIT` other than the tracked routed report's, as `segment_vignette_data.R` does) and the lut. Per basin it writes `data/wb/<key>/fit_<rel>/segment/<CODE>.parquet` with columns:
  - `linear_feature_id, month (0-12), runoff_mm, q_m3s, coverage, source, period, pick`
  - routed annual is the mean of 12 monthly means (`routed_annual`'s definition), and routed `runoff_mm` is over wet's accumulated area (`routed_mm`); routed `coverage` is NA
- [ ] Tracked report `data/checks/segment_output_<release>.txt`:
  - segments by source availability (both / routed only / balance only / neither, with the 369k no-lut);
  - picks by basin and by watershed group;
  - groups where > 50 % of segments flip;
  - the Nechako four by name
- [ ] Copy m4's full `fit_20260717/output/` to m1 (superset of the reduced bundle), then run on m1 and commit the report

## Phase 3: Score the pick, attribute the far-low
- [x] `scripts/pcic_routed_compare.R`: add the default pick as a third column at all 315 gauges (routed where picked, the held-out balance elsewhere, including the 25 uncovered). Rerun it and commit the report.
- [x] Attribute the Nechako zero: PCIC outlets in LEUT/UEUT/UNRS/LNRS (`fwapg.pcic_outlets` placement status, the hydromosaic series at one outlet). Record ours, theirs or unresolved; file in fwapg if it is placement.
- [x] File the fwapg issue: build the routed table over 1981–2010 from hydromosaic's daily PNWNAmet series (with a model/scenario parameter, which also serves the CMIP6 runs)

## Phase 4: Docs and the rule change
- [x] CLAUDE.md "Own estimates first": the balance stays the independent estimate everything is scored against; routed PCIC is published as the default where picked, labelled by source. Add `scripts/segment_output.R` to the Architecture list.
- [ ] `research/water_balance_method.md` §0: the pick, its score at the gauges, the Fraser flip counts and the Nechako attribution, the projection check (hydromosaic CMIP6 on the same `subid`), and the 369k segments with no value
- [x] Vignette guidance sentence (prose only): name the default pick and the Nechako exception, then render to check
- [ ] Edit the #57 body (projection check answered, pick rule, period decision) and #7's columns (`period`, `pick`)

## Validation

- [ ] Tests pass; `lintr::lint_package()` clean
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
