# Plan review (#76), Plan agent, delivered 2026-10-24 ~01:50 UTC

Reviewed the branch at 6570077 plus the then-uncommitted Phase 4 edits. Findings as returned (summarised by category; each verified or rejected in findings.md, "Plan review: verdicts").

- **B1** `wb_upstream_identity.R` cannot run the owed check against `e675918817`: it stops if the set-aside run already has snow columns (:51) and unless the new run adds exactly them (:75), and it would overwrite #16's tracked report (:90). Generalise before merge.
- **B2** plan text says `(ia, ib)`; code uses `(ia, id_up)`.
- **G1** `test-wet_upstream_sums.R:120` fixture guard uses base `sum()`, which accumulates in long double where the platform has one (x86_64: both orders give 1, the guard fails). Use `Reduce("+", …)`, rowsum's plain double arithmetic.
- **G2** `vals[valid, ][o, ]` copies twice (~0.5 GB each on the Fraser); `vals[which(valid)[o], ]` once. "~3.2 M rows per basin" is the province total.
- **G3** sweep looked only at sums: `R/wet_station_snap.R:46` + pick at :126-127 breaks exact score/distance ties by fetch order; research :285 already cites #76 for the snap. `mad_parity.R` ref → merge → write.csv follows fetch order within a watershed.
- **G4** stale wording also in `scripts/wb_share_snow.R:18-19, :143`, `wb_upstream_identity.R:86`, research :285, :519.
- **S1** re-keying cascades: `fit_20260717` lives under `e675918817`, so after the next province run wb_output, segment_output, discharge_publish and vignette data have no fit until carried over or refit; `data-raw/monthly_vignette_data.R:410, :439-440` (province_run, md5 of `upstream/400.rds`) go stale; the recipe at research :282-285 names `e675918817`.
- **S2** published parts are sorted (`discharge_publish_lib.R:60`), so only value changes alter their bytes.
- **S3** `wb_term_diagnose.R` `pcic_key` rebuilds (already in findings).
- **A1** "to the bit" also needs the same PostGIS/GEOS/PROJ/terra/GDAL and architecture.
- **A2** the findings' explanation of 6.6e-14 vs ~4e-16 is weak; cancellation in signed layers (`tave_10` near 0) is likelier; the live check used one-signed columns.
- **O1** generalise the identity script before merge. **O2** keep the "should" hedge.
- **AC1** the goal is never checked on real orders: replay basin 200 in `_pre16/962a9cc2c4`'s and `e675918817`'s stored row orders through main's and the branch's sums. After the m4 run, recompute one group's sample and one basin from shuffled inputs against the written files.
- **AC2** the 925 live test pins only the ORDER BY; the real evidence is `live_check.R` (scratchpad). **AC3** fetching twice in one database state is trivially identical.
- Also: `wb_province.R:256` `cols <- unique(unlist(lapply(vals, names)))` over `need <- unique(ws$watershed_group_code)` sets upstream column order by row order; `sort()` it. `wb_cv_lib.R:37` same pattern.
