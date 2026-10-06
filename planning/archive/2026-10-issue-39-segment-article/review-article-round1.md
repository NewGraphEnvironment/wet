# Review, round 1: segment-discharge article (#39), range `git diff 4afb2cc`

Reviewer ran the purled vignette against the bundled data in a scratch copy, built the article with
`pkgdown::build_article()` in a copy of the repo, and queried the local fwapg to check the
coverage and order-8 claims. No repo file was edited, apart from this one.

## Findings

- **[bug] vignettes/segment-discharge.Rmd:253**: the gap is printed as `format(round(rule_gap, 1), nsmall = 1)`,
  which renders as **"5.0 points worse, just past that line"** when the line is 5. The true gap is 5.03. At one
  decimal the published number equals the threshold, so the sentence says it is past a line it appears to sit on.
  This is the number the decision turns on, and research/water_balance_method.md and findings.md both quote 5.03.
  Print two decimals here, and hold the guard to that: it now accepts anything in (5, 6), so a rebuild giving
  5.04 would still print "5.0".

- **[fragile] vignettes/segment-discharge.Rmd:62-66 vs 207-208, 296**: `err_class()` uses `findInterval()`, so
  intervals are closed on the left. An error of exactly +20 is classed e4, "More than 20% over", but the table and
  `in20` count `abs(e) <= 20` as "within ±20%". An error of exactly −20 goes to e2, "0–20% under", so the two ends
  are treated differently. 0 is classed "0–20% over". The histogram (`geom_histogram`, closed on the right by
  default) puts +20 in the 10–20 bar but fills it with the ">20% over" colour. The same gauge would count as within
  ±20% in the table and as more than 20% over on every map. No current value falls on −20, 0 or +20 (checked:
  `sk$err_pct` and `both$fw_err`), so nothing published is wrong today. Use `findInterval(e, err_breaks,
  left.open = TRUE)`, or match the `<=` tests to the classes, so that one scale means the same thing everywhere.

- **[bug: prose scope] vignettes/segment-discharge.Rmd:718-721** (Limits, "Segments without a watershed"):
  `n_no_value` (8, orders 3–7) counts only the order ≥ 3 segments of SALR and BULK, the two mapped groups
  (`map$segments`: 2,181 + 7,755). The bullet reads as a property of the Freshwater Atlas lookup as a whole ("8
  segments … have no watershed polygon in the Freshwater Atlas lookup"). Scope it to the two mapped groups, or
  query the province-wide count.

- **[fragile: unguarded claim] vignettes/segment-discharge.Rmd:248-250**: "the 18 gauges … mostly large rivers,
  where the balance does best". The chunk guards only the area half (`median(dropped$area_km2) >
  median(both$area_km2)`). Nothing checks that the balance scores better on `dropped` (13.3%) than on `both`
  (30.5%). Add `stopifnot(mean(abs(dropped$err_pct)) < mae_wb)`.

- **[fragile: cartography] map-province, vignettes/segment-discharge.Rmd:350-352**: the group-name labels are
  placed at centroid + 3% of the frame width with an 80%-opaque white box. That box sits over calibration gauges
  just east of each group. In the rendered figure, "Salmon River" covers gauge points east of SALR and "Bulkley
  River" partly covers one between the groups. This map exists to show every gauge's error class. `map_labels()`
  already avoids points on the two group maps, and this label does not. A related minor case on map-bulk: the
  Houston town dot is drawn on top of the 08EE013 gauge symbol, because `map_labels()` draws town points after
  the gauges' `geom_sf`, which hides part of the gauge's fill.

## Checked and clean

- Every number in the "Which estimate to use" prose, the score table and the research/findings additions:
  - 168 gauges; MAE 30.5 vs 25.5; within ±20% 48 vs 60; medians 22.2 vs 16.7.
  - By basin: Peace 21 (19.6/14.2), Fraser 73 (29.4/28.8), Columbia 74 (34.7/25.4).
  - 18 dropped gauges, median 11,859 km², all over 2,500 km², 13.3% MAE.
  - Order-8 counts 13,883 / 38.
- Against fwapg directly:
  - 112 coverage groups, all draining to 100/200/300 (Fraser/Peace/Columbia).
  - 27 null-only groups, and 11 partial Liard groups at 0.02–23.6%.
  - The Fraser (3,647 segments, 1 valued) and the Thompson (681, 1) are among the order ≥ 8 segments.
- `basin_of()`: every in-coverage gauge maps to a basin, and no out-of-coverage gauge does.
- Units:
  - `wet_mm_to_m3s(mm, area_m2, days = 365)`; the 0.95 example holds.
  - The worked-example gauge area (7,340.695 km²) equals the segment's upstream area, so mm and m³/s compare on
    one area.
  - The −9.3% held-out against −7.6% map figures hold.
- SALR facet map: each panel's gauge fill uses that panel's product error, checked against the rendered PNG.
  Every SALR segment with a balance value also has a PCIC value, so no grey NA segments appear.
- Compare plot:
  - Clamping the two gauges beyond +200% does not move either one across a wedge.
  - The wedge labels match the axes.
- Named/drawn guard:
  - Under `pkgdown::build_article()`, `knitr::current_input()` returns "segment-discharge.Rmd" with the
    working directory in vignettes/, so the prose scan and the word cap run (probed in a copy).
  - The station regex works under TRE when read from a file.
  - Every station named in a table or inline (outlet, worked example) is inside a frame.
- No hex literals, no `\@ref`, no footnotes. Colours come from the registries; "black" and "white" are the only
  named literals.
- Test addition (`fwapg_order8`) and data-raw guard: consistent with the bundled provenance.
