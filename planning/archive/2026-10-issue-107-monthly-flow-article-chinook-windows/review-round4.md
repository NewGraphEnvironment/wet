# Code-check round 4 (#107): commit 691dae2 and 2b3cfe5 on top of rounds 1–3

Reviewed read-only at HEAD 2b3cfe5 (691dae2 plus one line wrap). Diff read in full
(`scratchpad/branch.diff`, merge-base 5bc6cc2), plus the full files `vignettes/monthly-flow.Rmd`,
`scripts/vignette_map_lib.R`, `data-raw/monthly_vignette_map.R`, `data-raw/station_vignette_map.R`,
`data-raw/monthly_vignette_data.R`, `tests/testthat/test-vignette_data.R`, `inst/cartography/wet_segment.csv`,
the CLAUDE.md paragraph, `scripts/vignette_data_lib.R`, `R/wet_flow_window.R`, `R/wet_values_compare.R`,
`vignettes/station-flow.Rmd` 200–300, the rendered text and `fig1.png`, and both bundles
(`monthly_map.rds`, `monthly_values.rds$provenance`) through `Rscript` in the scratchpad.

## Checklist read

- `code-check.md` (329 KB): every H3 under `## Mechanisms` read in full as prose (table rows skipped):
  A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the
  property; Verification that reads its own output; A guard's scope, escape hatches, and remedies;
  A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires;
  A shared working tree; A wrapper's exit is not the work; Zero-length, empty, and unset; The probe is
  broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One
  fact derived twice. Standalone rules read: Documentation Staleness; An assertion that matches an
  interpolated value cannot see the claim around it; A pluralisation marker. Not read: the other 16
  standalone rules and the Security/Spreadsheets sections (none names a tool or shape this diff uses).
- `code-check-r.md` (175 KB): read in full the sections Moving prose into a code chunk; `expect_gt()`
  takes no `info`; duplicate knitr chunk label; Base name shadowing in formal args; Cross-function
  consistency; `$` partial-matches; `paste()` zero-length; `strsplit()` trailing field;
  `vapply(USE.NAMES = FALSE)`; `source()` config leak; long table cell; `stats::aggregate()` three
  behaviours; `stats::mad()`; `deparse(body())`; `deparse()` non-ASCII; `package_version()`;
  `match()` NA; `tolerance` is RELATIVE; `cli` `{.name}`; `[[` on a named atomic; `data.frame()`
  recycles; `ifelse()` all-NA. Not read: about 85 other headings (pak, DBI/arrow/duckdb internals,
  terra-free database rules, mocks, Rbuildignore, etc.).
- `code-check-spatial.md` (154 KB): read in full bcdata empty result; bcdata `filter()` translation;
  sf name validation and the geometry column; `st_intersection()` GEOMETRYCOLLECTION; reproject the
  polygon for a bbox; offset regex; reader dropping a UTC offset; `geom_sf(data = NULL)`; A name is not
  a key; `summarise()` on a grouped sf; `st_read()` promotes to MULTI; `st_make_valid()` rewrites;
  `st_union()` after `st_transform()`; terra `unique()`/`freq()` on a factor; FWA main flow is not
  edge type 1000; `focal(na.rm)`; `plot()` 500,000 cells; lidR `rasterize_terrain()`; DEM half-cell
  shift. Not read: about 60 other headings (terra, GDAL CLI, STAC, gdalcubes, KML, Wayback).
- `code-check-shell.md` (121 KB): index only. The diff adds no shell; the one `system2("git")` call is
  pre-existing in `vignette_data_lib.R` and already reads `attr(x, "status")`.

## Findings

- **[fragile]** `vignettes/monthly-flow.Rmd:608-612` (rendered text line 143–144) — the rewrite of the
  scoring paragraph now says routed PCIC is scored "less 11 where the segment carries under 20% of the
  gauge's flow **(a misplaced outlet or snap)**". That parenthetical attributes all 11 far-low gauges
  to one cause. The tracked routed report the bundle is built against
  (`data/checks/pcic_routed_compare_20260717.txt`, lines 45–59, "The 11 gauges whose segment carries
  less than 20 % of observed flow") attributes them three ways: 6 "placement or snap", 4 "unresolved"
  (08KH006, 08DB013, 08EE028, 08DB014) and 1 "PCIC runoff" (08NE039). The prose at 9175569 carried all
  three ("to the outlet's placement or the gauge's snap, to PCIC's runoff, or unresolved"); 691dae2
  compressed it to the first and the sentence is now false for 5 of the 11. Nothing ties it: the
  bundle (`v$gauges`) carries `routed_mm` and `obs_mm`, from which `far` is counted, but no
  attribution, so no `stopifnot()` or inline `r` can reach the claim, and a rebuild under a routed
  report with a different split (the 1981–2010 run's attribution is the report's, #103) changes the
  prose nothing. This is the mechanism rounds 1–3 fixed three times (prose stating a which-set the
  data does not hold), and `code-check.md`'s "Compression runs both ways": the rewrite dropped the
  condition and the shortened sentence reads more confident than the long one. Remedy: drop the
  parenthetical, or restore the three-way wording, or bundle the report's `attribution` column per
  far-low gauge and print the counts from it.

Nothing else reached the bar.

## Checked and not flagged

Prose in 691dae2, sentence by sentence, against its ties (all hold on the committed bundle and are
guarded for a rebuild):

- Map section: "one inside the next", "measures it too", "drains the whole basin above", caption
  "which drains both" — `inside()` > 0.99 twice, in both the builder and the `map-data` chunk; the
  nesting order of the draw (`match(names(part_of), …)`, largest first) is the same vector the scale's
  `breaks` and the guard use. "Buck Creek and Quick are among the gauges the water balance is built on.
  Houston is not" — `not_cal` identical `"08EE003"`. "reads only in open water and has no complete
  year" — `m003` contiguous and no year with 12 months. The areas in the caption are the FWA
  catchments', held within 10% of the fit's by `a_fit`. "just downstream" and "at Houston" are
  positional claims with no distance guard (station-flow's `d_town` check was not carried over); they
  rest on HYDAT coordinates and the GNS point, which a rebuild of the bundle does not move, and
  containment (`inside(buck, houston)`) already fixes the gauge downstream of the confluence.
- Bulkley section: May peak, overshoot, "about a quarter short" (`q_short` in (−33, −20)), "high in
  July and August", in-sample pattern (range of ratios < 0.02, `wb_off` negative, printed signed),
  "Houston ... true estimate for an ungauged site" (`not_cal`).
- Windows section: every count, sign and direction has a `stopifnot()` line in the `windows` chunk
  (`good_w`/`poor_w`, 20–30% overstatement, routed days fall faster than the gauge's and its error
  shrinks, Buck Creek's balance move within 1 point of the gauge's and its remaining error within 2
  points of `wb_off`, Houston's move negative and under half the gauge's, `b003 > 200`); `drop_of()`
  refuses a non-negative move before printing it unsigned. "takes the second half of July" reads the
  window start from `life_history_bulk.csv` (`07-15`, printed in the table) without a `stopifnot()`
  on the start; that file is a cited input the bundle scripts never rewrite, and the wording is
  rounds 1–3's, so not a finding.
- Scores section: 315/290/11/279, the 25 unreached gauges "most of them in the Liard" (`n_un_10 >
  n_un / 2`), April highest, under half within ±20%, 58% of 243, spring/summer medians, 61%/68%,
  "4 months of twelve", basin size and lake outlets — all tied. The one untied claim is the finding
  above.
- Validation: `held_text` is computed from `shape_stations`; "on all three segments" for the
  months-from-days row holds because the builder asserts `compared == nrow(pb_b12)` with
  `nrow(segments) == 2 * 13 * 3`; `day_tie` recorded and asserted ≥ 0.

Map chunk (sf/ggplot traps):

- `scale_fill_manual(values = pal_map$values[part_of], labels = pal_map$labels[part_of], breaks =
  unname(part_of))`: indexing a named vector by a named character index keeps the *matched* names
  (`catchment_quick`, …), not the index's station numbers (checked in R), so `values` keys on the
  breaks; ggplot2 4.0.3 matches named `labels` to breaks by name and the render shows the three
  greys with the right labels in Quick, Houston, Buck order. `scale_colour_manual` and
  `scale_shape_manual` each carry one named value matching the literal aesthetic.
- `[` on sf: the chunk starts with `loadNamespace("sf")` (accepted tradeoff 7), and `map$streams[...]`,
  `catch[...]` keep their geometry; `st_area()` on the one-row subsets is length 1.
- Labels: all four labels and the keymap sit inside the frame in `fig1.png`; the keymap (upper left)
  does not overlap the Quick label or "Telkwa"; the scale bar clears the lake band. The comment
  "keymap: ... in the upper right" is stale (it is placed upper left) — comment only, not flagged.
- `geom_sf(data = NULL)` shape: every `data =` is a bundle layer or a frame built from one; the
  registry lookups `stream_sty`/`lake_sty`/`town_sty` are the same `$` paths station-flow uses, and
  the render shows their colours.

Lib (`scripts/vignette_map_lib.R`) and its callers:

- Behaviour is the pre-refactor code moved verbatim; the one change in `vm_places()` is `==` to
  `%in% names` over a plain local vector, which bcdata's translation inlines (the rule's "plain local
  variable translates fine"); it ran for both scripts. `names` as a formal shadows `base::names` but
  the body never calls `names()`, so no lookup can miss.
- `station_vignette_map.R` now sources `vignette_data_lib.R`, which is function definitions only (no
  top-level guard or connection), and `vd_connect()` reads the same `WET_PG*` variables with the same
  defaults as the inlined `dbConnect()` it replaces.
- `monthly_vignette_map.R` asserts `nrow(places) == 2`, a count rather than the set; the test
  (`expect_setequal(m$places$name, c("Houston", "Telkwa"))`) pins the set on the committed bundle,
  and the bundle holds Houston (District Municipality) and Telkwa (Village). Weaker than the test, but
  caught before merge, so not a finding.

Data script and test:

- The routed re-route keys `id * 512 + doy` (doy ≤ 365 < 512), asserts no NA match, and the tie
  count is subtracted from a `tol = 0` compare over a bijection (1,095 rows both sides, `only_a =
  only_b = 0`). The balance re-make aligns `up_b`, `seg_h` and `q_mon` by one `held` mask; `vapply`
  returns 12 × n, transposed. `aggregate()` over `pb_d` runs on a frame asserted `!anyNA(q_m3s)`, so
  `na.omit` drops nothing. `n_src` extends the compared-count identity to the three new rows.
- Test: `expect_gt()` is called without `info`; `expect_equal(..., tolerance = 1e-9)` on a
  months-from-days identity (the compare's `max_abs_diff` is 2.8e-14); `[[` on the named area
  vector follows a `setequal` on its names; `attr(m, "provenance")$hydat` is a one-key list.
- The five new `wet_segment.csv` rows have 24 fields each, and the vignette's `classes()` asserts
  the class set.
- Citation chunk: `ct[[i]]$doi` on bibentries, `RemoteSha` checked for 40 hex before printing,
  `write_bib` to a tempfile asserted non-empty; rendered lines show one entry per package.
