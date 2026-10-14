# Plan review 1 (#65), Plan agent, 2026-10-14

Spawned 03:56 UTC, delivered about 04:02 UTC; it reviewed the plan after Phase 1 had landed. Summary of findings, with what was done:

- Q1 `predict_cv()` reproduces `cv_ann`: deterministic (lm.fit, rule-based folds); needs `cal$raw`, `cal$fold` and `cv_variant` ("none"), and `shipped_heldout()` first. Shares may differ in last bits across BLAS: compare scores with a tolerance. **Done**: the first run passed `identical()` on the annual and `all.equal()` on the per-station scores.
- Q2 observed 1981–2010 against routed 1951–2012 mixes model error with the period. 08EE013 starts 1973; 08EE003 is seasonal and has almost no data 1999–2009. **Adopted**: measure the observed period difference per month at long-record calibration gauges (HYDAT), and report it beside routed bias; fwapg#25 goes in What's next.
- Q3 guard lib: done, pure move; new SQL gets `ORDER BY`.
- B1 the reduced bundle's `output/400.parquet` holds month 0 only. **Confirmed** (189,441 rows, month 0): the first run failed with 36 of 39 balance values differing (3 segments × 12 months). Fix: recompute months for the segments' watersheds from `upstream/400.rds` as `scripts/wb_output.R` does, checking month 0 against the output exactly.
- B2 do not edit files `score_files_for()` hashes (wb_cv_lib.R, wet_flow_validate.R, ...). Per-month scoring stays in the vignette.
- G1 08EE003 not in the 352: snapped by `wet_station_snap()` (done). Its balance is a real ungauged estimate.
- G2 monthly routed mm by month days; routed month 0 is an unweighted mean of twelve, so shares come from the sum of months.
- G3 08EE003 observed from `station_daily.rds`: hydat source only, ≥ 20 days per month-year.
- G4 rule for zero / near-zero months in log ratios, counted.
- G5 drop routed gauges carrying < 20 % of observed (`routed_far_low`), counted; carry the partly in-sample caveat.
- G6 window approximation like for like: day-weighted monthly means of the observed against daily window means over the same years.
- G7 record md5s of inputs outside the clean-tree guard (cv rds, fits.rds, station_daily.rds).
- G8 the recipe SQL is run by the data script on one segment and checked against the bundled values.
- O1 keep `gauges` province-wide (done). O2 period handling settled before Phase 2 finishes (adopted).
- A1 per-station monthly NSE is already in the tracked report (NSE_mon 0.71): cite it; new here is per-month bias, routed monthly, windows.
- S2 colours under a new `layer_key`.
- C1 test additions; C2 no tracked report: the vignette is the record until #6 takes it over (stated).
