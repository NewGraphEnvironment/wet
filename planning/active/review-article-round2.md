# Review, round 2: segment-discharge article (#39), range `git diff 4afb2cc`

Reviewer ran the relevant chunks against the bundled data (installed `segment_values.rds` and
`segment_map.rds` are byte-identical to the working tree's) in a scratch dir, and read the rendered copy at
`scratchpad/render/segment-discharge.html`. No repo file was edited, apart from this one.

## Findings

- **[bug] vignettes/segment-discharge.Rmd:494, 502, 557-560**: `close` is a logical vector computed on `ga`
  at line 494, and `ga` is reordered at line 502 (`ga[order(!ga$holds_salr, ga$area_km2), ]`, added in this
  range, absent at 4afb2cc). The inline prose then indexes the reordered `ga` with the stale `close`:
  `signed(max(ga$fw_err[!close]))` to `signed(min(ga$fw_err[!close]))`. After the reorder `!close` selects
  08KC001, 08KC003 and 07ED001 instead of 08KC001, 07ED001 and 08JE001. The rendered article says **"At the 3
  larger ones, fwapg runs −2% to −25%"**; the true range is −14% to −25% (research/water_balance_method.md
  says the same, and the gauge table right below shows 08KC003 at −2% as one of the *small* basins). The
  `stopifnot` at 498-501 runs before the reorder, so it passes and cannot catch this. `sum(close)` /
  `sum(!close)` are order-free, so the 2 / 3 counts are right; only the range is wrong. Fix: store it as a
  column (`ga$close <- abs(ga$fw_err) <= 5`) so it travels with the reorder, or recompute after line 502.
  Reproduced: `max(ga$fw_err[!close])` = −1.84 after the reorder.

- **[fragile: precision hides the claim] vignettes/segment-discharge.Rmd:247-248 and the score table
  (210, "All" row)**: the two MAEs print through `pct()` as integers, "25% against the balance's 30%"
  (true 25.47 and 30.50; 30.4956 rounds down). A reader sees a difference of exactly 5, the line itself, and
  ten lines later reads "5.03 points worse, just past that line". This is the same defect round 1 fixed in the
  gap, now one step upstream in the numbers the gap is made of. At one decimal they print 25.5 and 30.5, still
  a difference of 5.0, so only the two-decimal gap carries the claim. Either print the MAEs so that their
  difference visibly exceeds 5 (e.g. two decimals in this sentence) or say in the prose that the 5.03 is
  computed from unrounded values.

- **[fragile] vignettes/segment-discharge.Rmd:197**: the guard on the rule gap is still `rule_gap > 5,
  rule_gap < 6`, while the prose now prints two decimals. A rebuild with a gap in (5, 5.005) prints "5.00
  points worse, just past that line", the round-1 defect again. Guard on the printed value:
  `round(rule_gap, 2) > rule_cut`.

## Checked and clean

- Every error classification and count now uses one boundary: `err_class()` (e < −20, e < 0, e ≤ 20, else),
  `in20` and `score_row` (`abs(e) <= 20`), so −20 and +20 are both "within" and in the two middle classes.
  The histogram (`geom_histogram`, right-closed bins) puts +20 in the 10–20 bar and −20 in the −30…−20 bar
  with its e2 fill; fills are per gauge (stacked), so no bar is mis-coloured as a whole. Only 0 sits in the
  −10…0 bar with the e3 fill; no gauge has an error within 0.5 of 0, ±20 has none within 0.19
  (nearest −20.04, −19.83, +19.73). Bulk MAE and the compare square do not classify.
- `ga_pts` does carry `fw_err` / `wb_err`: both are columns added at 488-489, `ga` is reordered at 502 and
  `as_pts(ga)` is called at 517, so `g2`'s classes come from the right gauges in the right order.
- Labels: the province group labels (353) are drawn before the gauges (356); `map_labels()` (town points,
  town and gauge labels) comes before the gauge `geom_sf` on both group maps (581/583, 679/681).
- `overlap()` rename: `boxes[-i, ]` still drops item i's own obstacle box (the first nrow(item) rows are the
  items, in order).
- Missing-segment bullet is now scoped to the two mapped groups; the dropped-gauge guard
  (`mean(abs(dropped$err_pct)) < mae_wb`, 13.3 vs 30.5) is in place.
- Other prose numbers checked against data: nested 17 vs headwater 31; >1,000 km² 21 vs <100 km² 43; zone 24
  at 102 against a 2x line of 55.5, the only zone above it; SALR balance +6% to +38%; outlet +38% vs −25%;
  08EE004 worked example 130.7 / 118.5 (−9%) / 120.8 (−8%), held-out and map values distinct at the printed
  precision; dropped 18 gauges, min 2,593 km², median 11,859 km².
