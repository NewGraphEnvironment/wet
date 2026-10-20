# Plan review (#102), Plan agent, 2026-10-19

The review came back after Phases 1–3 had landed in the working tree. Each finding is listed with what was done about it.

| # | Kind | Finding | Disposition |
|---|---|---|---|
| 1 | Blocker | A shipped donor publishes the gauge's own observed shares at a calibration gauge, so many `wet_balance` checks and sentences in `vignettes/monthly-flow.Rmd` flip (the Bulkley freshet "a month late", windows, groups, Limits). | Real. Phase 6 now lists every dependent check and sentence. Bundle and Rmd change together after the upload; until then CI builds the old bundle with the old Rmd. |
| 2 | Ordering | Run BUILD again after the upload so `vd_published()` sees "identical to the published build". | Added to Phase 5. |
| 3 | Ordering | The clean-tree guards in `segment_output.R` and `discharge_publish.R` mean each report is committed before the next step. | Phase 5 spells out the order. |
| 4 | Ordering | Code-check before the chain: a later fix to a hashed file stales all ten variants. | Added as Phase 4b. |
| 5 | Ordering | The Rmd guard against the bundle (`share_method` missing from the old bundle). | Rmd and bundle change together (Phase 6). The provenance gains `share_method` (done in Phase 3). |
| 6 | Gap | Hash `R/wet_donor_mean.R` in `score_files_for()` and in `wb_shape_daily.R`'s shape_files. | Already done in b053f9d. |
| 7 | Gap | `wb_shape_daily.R` checks `share_spec` only, and labels `cv_share` as the regression. | Fixed: it checks `share_method` and names the method. |
| 8 | Gap | The publish description must stay byte-identical for the regression and be correct for donor. `wb_validate.R`'s "CGIAR monthly AET" line is false for donor. | Fixed. Byte identity was checked by evaluating the old and new expressions. The CGIAR line is now conditional. |
| 9 | Gap | `wb_share_snow.R` wording, and the status in `research/discharge_publish.md`. | `wb_share_snow.R` is accepted as is: the snow predictors still ship, as the donor's space. `research/discharge_publish.md` is added to Phase 6. |
| 10 | Assumption | Fix #16's exact median (0.873517978845096) before m4 overwrites it. | Added to Phase 5's checks. `wb_validate.R` asserts `identical()` within the run. |
| 11 | Assumption | The registered donor (monthly-volume shares, exact-match branch) is not #70's free curve. | Report both: 0.9389 here against #70's 0.9388. |
| 12 | Assumption | `wb_share_snow.R` needs `_pre16` on m4. | Confirmed present on m4. |
| 13 | Assumption | AET independence. | Holds. |
| 14 | Pathology | In-sample donor: gauges publish their own shares, LOO is inflated by co-located and nested gauges (08NM240/08NM241 share watershed 10042373), and there is an observed island around each gauge. | LOO label added in `wb_validate.R`. Limits text goes in Phase 6. The registered method is not changed after scoring. |
| 15–19 | Rule ambiguity | One scored set or per pool; tie; median-dist set; SD per pool; donor's stations. | The probe had already run, so a pre-scoring clarification was no longer possible. The header now records how the code reads each detail, dated after the probe. On this fit none of them moves the outcome: all 315 gauges score in every pool, there is no tie, and the dist and SD conventions are those of the referenced `wet_shape_predict()`. |
| 20 | Scope | Short-record shares are noisier. | Stated in the report line. Blocked by sub-sub-drainage, as `wb_pooled_test.R` does. |
| 21 | Acceptance | Description unchanged if nothing ships; the exact 0.8735 to 1e-9; NA-share counts. | Description identity was verified; the exact value is in Phase 5; `wb_output.R` reports NA shares by method. |
| (b), (e) | Verified | The whole-basin donor is self-contained; the other consumers read the annual only. | No change. |
