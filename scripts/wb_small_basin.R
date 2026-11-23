# Why the open balance runs high at small basins (#176): the held-out annual balance at the
# shipped fit's calibration gauges under 100 km2, against the larger ones, under the rule below.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/wb_small_basin.R
#
# Reads the shipped fit (scripts/wb_cv_lib.R: `cal`, its blocked folds; <fit>/cv_aet-cfu.rds:
# `station_number`, `raw`, `cv_ann`, `obs`, `zone`), #45's cached PCIC terms
# (data/wb_term/diagnose_<release>.rds) and, for glacier cover, the FWA in fwapg (WET_PG*).
# Writes data/checks/wb_small_basin_<release>.txt (tracked, wb_report()). The verdicts are
# computed by scripts/wb_small_basin_rule.R.
#
# ---- the rule, registered in a commit of its own before this script computed any check ----------
#
# The thresholds of check B were set by the owner on 2026-11-23 (#188, "Decisions"). Nothing
# below may change after the first run; an amendment made after numbers were seen is listed apart,
# at the end of this header, with the verdict as registered beside it.
#
# Known before registration, and disclosed: at the 84 calibration gauges under 100 km2 the median
# error is +1.9 % raw (P - AET) and +14.3 % adjusted (the held-out balance as shipped)
# (data/checks/wb_validation_20260717.txt, lines 63 and 106); at the 231 larger gauges, -15.1 %
# raw and -6.7 % adjusted, as the plan's review read them from cv_aet-cfu.rds. So where the bias
# enters is known: with the adjustment. The script prints all four again.
#
# Definitions:
#   - gauges: the shipped fit's calibration gauges; small: accumulated FWA area under 100 km2.
#     The script stops unless cv_aet-cfu.rds and `cal` hold the same stations in the same order
#     with the same `obs`, and unless it reproduces the four medians above to one decimal and the
#     fit's `code_md5` equals `score_code_md5`.
#   - error: 100 * (modelled - observed) / observed, annual. Raw is P - AET; adjusted is `cv_ann`.
#   - a class with fewer than 5 gauges (on either side, where a check compares two) is printed,
#     marked, and not read.
#
# A. Where the bias enters: described, not judged. The size-blind adjustment lifts both classes.
#    A prints the small-minus-larger contrast in median error, raw and adjusted, over all gauges,
#    then within each class of three splits: dominant hydrologic zone (`zone`), elevation tercile
#    (`elev`) and aridity tercile (`pet_yr / p_yr`), terciles cut over all calibration gauges.
#    Reading: the contrast is "general" if the adjusted contrast is +10 points or more in at least
#    two thirds of the readable classes of every split, otherwise "concentrated", naming the
#    readable classes below +10 (sb_reading_contrast()).
#
# B. Do catchment traits explain it. One model, no search: ordinary least squares of
#    log(cv_ann / obs) on the traits below, fitted on all calibration gauges under the fit's
#    blocked folds (`cal$fold`), each gauge predicted from the model fitted on the folds that
#    exclude it, the traits standardized with each training set's means and standard deviations.
#    Traits: log10(area_km2), p_yr, pet_yr / p_yr, elev, t_yr, swe_max / p_yr, and glacier cover
#    (below). Corrected value: cv_ann / exp(predicted); its error as above.
#    Verdict "traits explain the small-basin error" only if all three hold:
#      1. the small gauges' median corrected error is within +/-5 %;
#      2. their mean absolute % error (mae(), scripts/wb_cv_lib.R) falls by at least 3.0 points;
#      3. that of the gauges of 100 km2 and up rises by no more than 1.0 point (the gate's margin,
#         #47, #83).
#    A 90 % interval on test 1 comes from 1,000 bootstrap draws of the blocked folds, with
#    replacement (seed 188), each draw's statistic the median corrected error of the small gauges
#    in the drawn folds, held-out predictions as made (no refit). If tests 2 and 3 hold and the
#    interval crosses -5 or +5, the verdict is "undecided"; otherwise test 1 decides
#    (sb_verdict_traits()).
#    Beside it, an area-only model (log10(area_km2) alone) under the same tests; if it passes, the
#    report says so, because the small class is defined by area.
#    Deviation from #176, which says "at the small gauges": the model is fitted on all gauges,
#    because the candidate adjustment would be.
#    Caveat, stated and not removed: each training gauge's `cv_ann` came from fits that saw the
#    held-out gauge's `obs`, a second-order leak.
#    A per-trait table (Spearman correlation with the adjusted error at the small gauges, and each
#    trait's standardized coefficient in the all-gauge fit) is printed and decides nothing.
#    Glacier cover: the area of FWA glacier polygons (whse_basemapping.fwa_glaciers_poly)
#    intersected with each fundamental watershed upstream of the gauge, over the gauge's
#    accumulated area.
#    Not tested: average slope and solar exposure. Slope is in 15 of WALLY's 27 zone models and
#    solar exposure in 8 (data/checks/wally_compare_20260717.txt, section 1); both need the DEM,
#    which the machine holding this run lacks, so both are carried to the follow-up issue.
#    `lake` is not a trait: it is a lake-outlet label, true at 1 of the 84 small gauges.
#
# C. Which term, against PCIC, where PCIC's grid reaches. #45's per-basin terms
#    (data/wb_term/diagnose_<release>.rds, `basins`: 192 PCIC-covered basins in the Fraser, Peace
#    and Columbia; one row merges two gauges, so basins are counted, not joined on station_number).
#    C first prints the raw and adjusted median errors on its own small basins and names that
#    population. The rule is #45's (planning/archive/2026-10-issue-45-dry-interior-term/findings.md,
#    steps 1 to 5), which diagnoses an overshoot only: verdict() is copied verbatim from
#    scripts/wb_term_diagnose.R, the copy is held to the stored zone verdicts on all 21 rows, and
#    it is applied to the small class with the ECCC corroboration over the zones the small basins
#    fall in, keeping #45's minimum of 4 basins. #45's step 6, leave-one-basin-out stability, is
#    dropped. Caveat: a PCIC cell is about 30 km2, so a small basin spans a few cells; step 3
#    (PCIC a usable reference) is the guard, and its numbers are printed.
#
# D. Sampling: recorded from the code, no number. The province run samples each fundamental
#    watershed area-weighted (scripts/wb_province.R, wet_ws_sample(st, ws, "area")), so #176's
#    "centroid against area-weighted" candidate does not describe the shipped run.
#
# Attribution (ours, theirs or unresolved): the adjustment's lift at small gauges is ours and was
# known before this rule; A's reading says whether it is general or concentrated. The raw
# small-minus-larger contrast is "ours, P" or "ours, AET" on C's population where C names that
# term with its corroboration, otherwise unresolved there (sb_attribution()). B's verdict is
# reported beside it; a pass enters the trait regression in the follow-up issue's candidates.
#
# Amendments after numbers were seen: none.

stop("scripts/wb_small_basin.R holds the registered rule only; the checks are not written yet")
