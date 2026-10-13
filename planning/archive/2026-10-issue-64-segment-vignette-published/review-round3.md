# Code review, round 3 (#64, branch 64-segment-discharge-vignette-lead-with-the, HEAD 99931f7)

Scope: `git diff main...HEAD`, read in full for the changed files; context from segment_output.R,
pcic_routed_lib.R, discharge_publish_lib.R, wet_source_pick.R, the tracked publish and segment reports, the
crate schemas, and `inst/vignette-data/segment_values.rds`. Nothing was written to the repo, S3 or a database;
no data-raw/ or scripts/ file was run.

## The mechanism behind rounds 1-3

All three earlier findings come from one assumption: a statement covers a whole population that nobody listed
and checked against the thing it describes. The writer's list and the real population matched only by
assumption.

- Round 1: the comparator's idea of "same" was written for finite values. The values a double column can hold
  also include ±Inf (and NA/NaN).
- Round 2: `unique()` assumed that two separately computed doubles are the same value.
- Round 3: the prose said "every value / every column", but the code checks only a list someone typed.

Where this assumption reaches in the diff, with each place checked:

1. **Equality predicates.** Checked: `wet_values_compare()` for NA, NaN, ±Inf, -0, logical `pick`, `tol = 0`
   and the 1e-9 relative tolerance; `match`/`%in%` on its `id * 16 + month` keys; `unique(rbind(pub_salr,
   pub_gauge))`, where both reads come from the same parquet bytes; `identical(routed_total, fp_total)`. All
   fine.
2. **Completeness gates** (`compared == <count>`). Checked: routed vs `nrow(rt_all)`, month 0 vs
   `sum(rt$segments)`, balance vs `sum(bt$rows)`, parts vs `sum(seg_t$rows)`, watershed vs `sum(ws_t$rows)`,
   and, in the data script, `compared` vs `nrow(src_b)`/`nrow(src_r)`. All fine.
3. **Quantified prose** ("every", "each", "all", "only", "them"). Findings 1-5 below come from this check. All
   five are prose, so none of them changes a published number.

## Findings

- **[fragile: a residue of round 2's finding]** scripts/discharge_publish.R:9-10. The header comment still says
  the BUILD "checks every written value against what it was built from (#64)". Round 2 narrowed the other
  places. This one was probably missed because the sentence wraps across two lines, so a single-line grep for
  "every written value" finds nothing. The BUILD does not check `period`, `watershed_group_code`, or the
  watershed parts' `runoff_mm`, `coverage` and `bc_fraction` value by value. The report heading and the
  comment block at line ~338 now say this correctly ("every published flow, and four segment columns").

- **[fragile: the list of unchecked columns is incomplete]** research/discharge_publish.md, section "Every
  published flow is checked against its source (#64)". The text lists the columns that are not checked value
  by value: "`period`, and the watershed parts' `runoff_mm`, `coverage` and `bc_fraction`". It leaves out
  `watershed_group_code`, which both crate schemas publish (segment_monthly and watershed_monthly, both
  confirmed in the installed crate's yaml). The BUILD fills that column from fwapg (`seg_grp`/`ws_grp`) and
  compares no value of it. `publish_part_prepare()` asserts only that it is not NA. This is the column readers
  filter on for row-group pruning, and the article's read example and the vignette data script select by it.
  The list was typed by hand rather than taken from `publish_schema_cols()`, the same pattern as round 3's
  finding. Fix: add it to the list. The cheap check would compare it against `seg_grp`/`ws_grp` with
  `wet_values_compare(value = "watershed_group_code")`, but the comparator is numeric and a character column
  makes `va - vb` error, so in practice add it to the doc's list.

- **[fragile: an over-claim in the published article]** vignettes/segment-discharge.Rmd:137 and :213, with the
  Limits bullets at :586-589 and :601-603. Line 137 says "wet publishes the mean flow of **every** stream
  segment in British Columbia's Freshwater Atlas". The tracked segment report
  (data/checks/segment_output_20260717.txt) says otherwise:
  - 374,598 of 4,907,441 FWA segments (7.6 %) get no value from either source.
  - 369,217 of those have no lut watershed. The Limits bullet covers these.
  - The other **5,381** have a lut watershed but neither source has a value: 5,238 in drainage 915, and the
    rest in 900, 905, 910, 930, 935, 940, 950 and 955.

  Line 213 says the balance "covers all of BC". In fact the build drops 286,533 NA watershed-month rows
  (roughly 22,000 watersheds), concentrated on the outer coast and islands:
  - 935 (Gold River/Clayoquot/Tahsis): 47,424 NA rows against 49,868 published, about half.
  - 945 (Graham Island): 9,945 NA rows against 10,881 published, about half.
  - 915: 168,012 NA rows against 1,064,518 published, about 14 %.
  - 905: about 22 %.

  The Coverage bullet then says that on the outer coast's islands, where routed reaches only some segments,
  "There `pick` takes the balance". On those same islands the balance is also missing on thousands of
  segments, and the no-value bullet puts every gap down to the missing lut. Fix: change "every" to the measured
  population (4,532,843 segments with a value), and name the coastal balance gaps in Limits. Wherever the
  article states a coverage, take it from `segment_output_<release>.txt`.

- **[fragile: an over-claim in contributor docs]** CLAUDE.md, segment-discharge vignette paragraph: "how both
  score at the shipped fit's 315 calibration gauges". Only the balance is scored at 315. Routed PCIC is scored
  at the 290 gauges whose segment carries it, and the bundled `skill` table has 25 gauges with
  `routed_mm = NA` (19 of them 10x Liard). The vignette itself gets this right ("Routed PCIC has a value at
  `r n_both` of the gauges").

- **[fragile: an over-claim in research]** research/fwapg_mad_method.md:19 says "The tables below are the
  record; `scripts/mad_parity.R SALR` reproduces them." Many tables below come from other scripts:
  - the Fraser parity, cause attribution and basin-scale sensitivity tables, from `scripts/mad_basin.R 100`;
  - the upstream-area results, from `scripts/upstream_area_check.R 100`.

  The file's own **Produced by** line names all three scripts correctly. The new sentence should say "the SALR
  parity and sensitivity tables" rather than "the tables below".

## Checked and fine

- The `wet_values_compare()` semantics listed under point 1 above.
- `max_abs_diff` covers finite pairs only.
- The key arithmetic, and its refusal of a duplicated key, an NA id and a month outside 0-12.
- `read_part()`, for both a missing part and an empty `rowsum()`.
- The routed "none" row counts unpublished fwapg rows as differing. Today this agrees with segment_output.R,
  which publishes a routed segment only with a lut watershed and twelve months. A future fwapg table with such
  segments would fail the BUILD rather than pass it.
- Exact comparison (`tol = 0`) is used everywhere a value is copied from a double. The 1e-9 tolerance applies
  only to month 0 (the BUILD's `rowsum / 12` against segment_output's `aggregate(mean)`, and the data script's
  SQL `avg` against R `mean`). This matches the comments, the research table and the recorded largest
  differences (9.09e-13 and 1.14e-13).
- The data script's report guard: no FAIL, exactly one "parts identical" line naming the live `wet_commit`,
  and here = same = published = `nrow(cat_pub)`.
- The data script's md5 verification before and after the httpfs read, and its `compared` identities.
- In `segment_values.rds`: published_check compared 2,180 and 2,469 values, with 0 differing in each; every
  picked source has a value; and the one segment with neither value is NA on both.
- The vignette's guarded prose:
  - most gauges without routed flow are in the Liard (19 of 25 are 10x);
  - the balance is high at every SALR-area gauge; routed is closer at most of them, the outlet among them;
  - one zone stands out at twice the average;
  - `n_both_src` by inclusion-exclusion, which holds because the BUILD asserts one pick per segment and month;
  - the `pick` rule as stated against `wet_source_pick()`;
  - "runoff_mm NA for a routed row off its own line" (the segment report gives 72,242 off their own line and 0
    with no accumulated area);
  - the err_class ends against the "within ±20 %" test.
- CLAUDE.md's Publishing paragraph lists the checks accurately.

## Enumeration after round 3 (by the session, 2026-10-13)

Round 3's first finding (the header comment at `scripts/discharge_publish.R:9-10`) sat inside round 2's fix: that fix narrowed "every value" with a one-line grep, which missed a sentence wrapping across two lines. Per the stopping rule, the loop ends on an enumeration, not on another round.

Set: every added line in `git diff <merge-base>...HEAD`, excluding `planning/`, the bundled data and `data/checks/`, matching `every|each|all|none|only|whole|always|never|any` (116 lines). Each was checked against the code or report behind it. Two more were loose and are fixed: the vignette's "giving each segment monthly means" (routed reaches only the segments it covers) and "the fit that uses every gauge" (every calibration gauge). The rest hold: code-level `all()`/`any()` were checked by round 3; prose quantities are guarded by the vignette's `stopifnot()` or match `data/checks/segment_output_20260717.txt` and `data/checks/discharge_publish_20260717.txt`.
