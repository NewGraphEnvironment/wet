# Code review, round 2 (#64, branch 64-segment-discharge-vignette-lead-with-the, HEAD 2bc7a15)

Scope: `git diff main...HEAD`, with the round-1 fixes reviewed in particular (R/wet_values_compare.R and its
test; the single `routed_annual()` call in data-raw/segment_vignette_data.R).

What was run (nothing written to the repo, S3 or a database):
- `NOT_CRAN=true` `testthat::test_file()` on test-wet_values_compare.R (18 pass, 0 fail, no error) and
  test-vignette_data.R (101 pass, 0 fail, no error).
- The vignette rendered from a clone of HEAD in the scratchpad (`rmarkdown::render` after `load_all`): builds
  clean, every stopifnot passes. Rendered numbers agree with the report and segment report: 4,532,843 segments
  with a value = 3,374,133 + 2,904 + 1,155,806; 3,374,133 with both; picks 3,152,838 / 1,380,005; 67 parts,
  1.80 GB; 2,180 of 2,181 SALR segments; 290 of 315 gauges.
- `segment_values.rds`: built at 7b83959 (the round-1 fix) from published build 7c62b9e; published_check
  compared 2,180 and 2,469, differing 0 and 0.

## Round-1 fixes

- `wet_values_compare()`: the new `same` expression has no NA leak (each arm is FALSE, not NA, when its
  operand is NA), Inf vs finite and Inf vs -Inf differ at any tolerance, Inf vs Inf and NA/NaN vs NA/NaN are
  equal, and `max_abs_diff` is over finite pairs. Restoring the old body makes the new Inf test fail at both
  tolerances (old code: tol 1e-9 counts 0 differing; tol 0 gives NA). Old and new agree on everything the
  tracked report at 032242f compared (every `largest diff` there is finite and every `differing` non-NA), so
  the report is still a valid record despite predating the fix.
- `routed_annual(conn, c(seg ids, gauge ids))`: the function `unique()`s its ids and returns one row per id,
  so a segment that is both SALR and a gauge's has one value. Correct.

## Findings

- **[fragile — claim the code does not support]** vignettes/segment-discharge.Rmd:606,
  research/discharge_publish.md (heading "Every published value is checked against its source (#64)"),
  CLAUDE.md Publishing paragraph ("every column with the segment table"), scripts/discharge_publish.R:340-345
  comment ("every column of every segment row") — the BUILD does not check every published value or every
  column. The segment-part comparison covers four columns (`q_m3s`, `runoff_mm`, `coverage`, `pick`;
  `cols_val`, line ~348); `period` is not compared (only its `^[0-9]{4}-[0-9]{4}$` format is asserted in
  `publish_part_prepare()`). The watershed parts are compared on `q_m3s` only (`read_part(..., c(
  "watershed_feature_id", "month", "q_m3s"))`), while crate's watershed schema also publishes `runoff_mm`,
  `coverage` and `bc_fraction` (the BUILD's `setequal(names(x), cols)` with x holding those columns), so about
  3 x 41.9M published watershed values go unchecked. The research doc's table itself is accurate (it names the
  four segment columns and "watershed parts = the fit's output"); the heading, the vignette sentence and the
  CLAUDE.md "every column" are the overclaims. Either compare the remaining columns (cheap: same loop, same
  `wet_values_compare(value = v, tol = 0)` against `output/`'s `runoff_mm`, `coverage`, `bc_fraction`, and
  `period` against the table), or narrow the three sentences to what is compared. The values are copied
  straight from the same frames, so the practical risk is low; the problem is a published "every" that the
  report does not back.

No other issues found. Checked and fine: key arithmetic and duplicate refusal in `wet_values_compare()`;
`read_part()` on a missing part and `rowsum()` on an empty drainage; the `compared ==` totals that keep a
check of nothing from passing (routed against `nrow(rt_all)` with unpublished routed rows counted as differing,
month 0 against `sum(rt$segments)` = both + routed only = 3,377,037, balance against `sum(bt$rows)`, parts
against `sum(seg_t$rows)`, watershed against `sum(ws_t$rows)`); `routed_micro` stays exact in a double
(1.78e14 < 2^53); the value checks run before the report is written and the manifest is moved into place only
after `all(checks)`; the vignette script's report guard (no FAIL, one "parts identical" line naming the live
`wet_commit`, here = same = published = `nrow(cat_pub)`) and its md5 verification before and after the httpfs
read; `unique(rbind(pub_salr, pub_gauge))` (the overlap rows come from the same bytes); the `compared`
identity against `nrow(src_b)`, `nrow(src_r)`; "a segment with no lut watershed gets a value from neither
source" (segment_output.R's design, line 18); the `pick` rule as the vignette states it against
`wet_source_pick()`; the comparison plot's wedge labels (x routed, y balance); the removed registry rows (no
remaining consumer of `segment_map/key`, `skill_nesting/mae`, `product`, `parity`; the vignette's
`classes()` asserts each set it uses).
