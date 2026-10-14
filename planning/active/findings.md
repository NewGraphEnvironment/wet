# Findings — Monthly flow vignette (#65)

## Issue context

**If we do it:** we and others get one worked place to explore the published monthly flows: how to pull a stream's twelve months, how the two sources compare with the gauges month by month, and how flow lines up with a species' life-stage windows. Writing it is also the QA pass on the monthly values, and its gaps become the list of what to fix next. **If we never do:** the monthly half of the published product (months 1–12) stays unexamined and unscored, and every user works out the read, the plot and the life-stage overlay on their own.

## Purpose

Three jobs, in this order:

1. **Explore what we have.** The published table (#7) carries months 1–12 per segment for both sources (`pcic_routed`, `wet_balance`) beside the annual value (month 0). Nobody has looked at the monthly values as hydrographs yet.
2. **Show how to use it.** Segment in, twelve months out, plotted, with life-stage windows on the same axis, as code a reader can copy.
3. **QA it and say what is missing.** Score the monthly values against HYDAT at the gauges, show where each source's seasonal shape is right or wrong, and end with the list of what would make it more useful (a fix, a missing source, a coverage gap), each filed as an issue.

## Sketch

- **Place:** the Bulkley (BULK), with the segments at 08EE013 and 08EE003, so it pairs with `vignettes/station-flow.Rmd` (#27). Add a contrasting regime if the first one hides a problem (a coastal rain-fed stream, or a lake outlet).
- **Hydrographs:** for each segment, both sources' twelve monthly means, with the gauge's observed monthly means over the same period beside them. State each source's period (routed 1951–2012, balance 1981–2010) and how that period differs from the gauge record.
- **Monthly accuracy:** error per month at the gauges each source covers, by source: bias and spread, and the share of gauge-months within a band. This is the core of the QA and depends on #6.
- **Life stages:** shade the Chinook windows the station vignette already uses. They come from the organisation's life-history timing table for BULK, pinned at a commit, as `data-raw/station_vignette_data.R` reads it: migration May 1 – Aug 1, spawning Aug 1 – Sep 15, fry migration Jul 15 – Sep 7. Give the flow per window. The windows start and end mid-month, so window flow from monthly means is a day-weighted approximation; say so, and show the daily gauge record where there is one.
- **Recipe:** the same for any stream, from `linear_feature_id`, through `wet_segment_monthly()` (#59) or `wet_catalog()` and the parquet.
- **What's next:** the gaps the exploration finds, each linked to an issue.

## Depends on

- #59 `wet_segment_monthly()`: the read. Until it lands, read through `wet_catalog()` and the parquet directly.
- #6 monthly station check: the monthly scoring. The vignette can carry the first version of that scoring if #6 has not landed, and #6 then takes it over.
- #64: the product page this one links to for what the table is and where it lives.

Relates to #3, #7, #27.


## Plan-mode exploration (2026-10-13)

- #59 and #6 open; #64 closed. Read through `wet_catalog()` + duckdb parquet.
- Local fwapg (m1): BULK 32,472 segments, 30,037 with routed flow (month 1 rows). KISP, LSKE, MORR, SALR similar.
- m1's reduced bundle `data/wb/962a9cc2c4/fit_20260717/output/` holds `100.parquet` and `400.parquet`; `upstream/` holds all basins and `_complete`.
- Calibration stations in 08EE: 08EE004, 08EE008, 08EE012, 08EE013, 08EE020, 08EE025, 08EE028 (all accepted). 08EE005 is in the test set (2 years). 08EE003 is in neither: HYDAT Q 1930–2025, gaps 1952–1970, unregulated; probably seasonal, so no complete years.
- `cv_aet-cfu.rds` stores `cv_ann` (held-out annual), `cv_v$stations` (per-station err and NSE), not held-out monthly values. `predict_cv()` (`scripts/wb_cv_lib.R`) returns `share` (n × 12) per fold; `long()` turns it into monthly mm.
- No source colours in `inst/cartography/`; `wet_station.csv` has `hydrograph/window`.

## Phase 1: guards moved to scripts/vignette_data_lib.R

Rebuilt `segment_values.rds` on m1 (2026-10-14 03:56–03:58 UTC, `WET_FWAPG_COMMIT=341b078`) after the refactor. Against the committed file: `skill`, `gauges_salr` and `provenance` (less `built`, `wet_commit`) identical; `segments` identical once sorted by `linear_feature_id`. The row order comes from the fwapg query, which has no `ORDER BY`, and predates this branch. Committed file kept.

## Phase 2: the monthly bundle

- m1's reduced bundle: `output/*.parquet` month 0 only; `upstream/400.rds` 17 rows (gauged watersheds only). So balance months 1–12 on the Bulkley segments are recomputed only for 08EE013's and 08EE004's watersheds (26 values, max diff 8.5e-14 m³/s); 08EE003's rest on the publish report's check.
- Held-out monthly balance recomputed with `predict_cv(cal, cal$fold, "none")`: annual `identical()` to stored `cv_ann`; per-station scores `all.equal()`.
- Held-out shares floor to 0 in some winter months (07EA002 Jan–Mar `wb_mm` = 0): log ratios need an exclusion rule (review G4).
- 08EE003 snaps to 17093621 (Bulkley River, order 6), 08EE004 to 17057325, 08EE013 to 17094080 (= the fit's snap).

## Errors Encountered

| Error | Resolution |
|-------|------------|
| balance check 36 of 39 differing on first run | m1's `output/` is month 0 only (review B1); recompute months from `upstream/` |
| `setequal(up$watershed_feature_id, ...)` failed | reduced `upstream/400.rds` holds gauged watersheds only; recompute where present |
