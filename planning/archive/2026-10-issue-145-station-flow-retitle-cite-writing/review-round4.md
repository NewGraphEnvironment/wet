# Code check, round 4 (#145): fixes in b88d7f0 (diff 49e8387..b88d7f0)

## Checklist read

- Index (`checklist.txt`): read in full, all four files (lines 1–976).
- code-check.md: the prose of all 14 H3s under `## Mechanisms`, with evidence blocks and `|` rows skipped. The other sections were judged from the index.
- code-check-spatial.md: judged from the index; the fix's pattern (a vector layer queried in one extent, framed in another) is the shape of "A raster's drawn footprint is its valid data, not its extent", which round 3 read in full.
- code-check-r.md, code-check-shell.md: index only. The fix adds two `stopifnot()` lines and caption text, and no pattern an index line names.
- writing.md (soul `conventions/writing.md`): read in full "A caption names every mark the figure draws", "State each claim by the code's definition", "Check that each guard covers the set its sentence names" and "Name, link and cite the software", with the headings of the rest.

## Findings

- **[severity: bug, minor]** vignettes/flow-departure-normal.Rmd:460–461 (caption), guard at :410–412, comment at :406–408. The new caption says that "other streams of order 5 and up (thin) and lakes of 100 ha and up (blue) are drawn only near the catchments". For the lakes this is false at the precision the sentence sets, and the guard cannot see it.
  - **What the code does.** `vm_lakes()` selects every lake of 100 ha or more that *intersects* the 8 km box, then draws each selected lake *whole*, unclipped. The new guard checks the same intersection: `all(lengths(st_intersects(map$lakes, near)) > 0)`. That is the selection rule, true by construction from the query's `ST_Intersects`. It says nothing about where a selected lake is drawn.
  - **Measured** from the installed bundle (md5 333a21c0…, equal to `inst/vignette-data/station_map.rds`), with the article's frame recomputed:
    - François Lake has 11,667 ha drawn inside the frame but outside the 8 km box. It is drawn up to 26.1 km from the catchments, out to the frame's edge, 12.7 km beyond the box.
    - Babine Lake has 4,588 ha drawn the same way: 26.4 km from the catchments, out to the right edge, 12.7 km beyond the box.
    - The other 17 lakes stay inside the box. Decker Lake overshoots it by 0.10 km.
  - **In the rendered map** (docs/articles/flow-departure-normal_files/figure-html/map-1.png):
    - François Lake runs along the bottom and off the right edge.
    - Babine Lake runs off the top-right corner.
    - Both lie in the very strips where the caption now says nothing is drawn, beside streams that stop at the box.
  - **What a reader concludes.** "Drawn only near the catchments" tells them that blank ground away from the catchments was not drawn. The two largest drawn features contradict it, and they draw the eye most. The in-code comment at :407–408 ("so they stop short of the frame") is false for the same two lakes.
  - **The streams are fine at this precision.** Segments that cross the box are drawn whole and overshoot it by at most 0.41 km (measured on all 27 thin streams), which is within "near".
  - **Fix.** Either of these would work:
    - Clip what is drawn to the box. In the article, `sf::st_intersection(map$lakes, near)` (and the same for the thin streams, if wanted). Then guard on extent, not selection, for example `all(sf::st_covered_by(drawn, near))`, or a zero area and length for `st_difference(drawn, near)`.
    - Reword the caption to the selection: "lakes of 100 ha and up that reach within about 8 km of the catchments, drawn whole". Note that the bbox corners put the selection limit at up to about 16 km, so "8 km" would itself need guarding.

    Clipping keeps the caption's present sentence true. Either way, fix the comment at :407–408 too.
  - **Rule:** writing.md "Check that each guard covers the set its sentence names"; writing.md "State each claim by the code's definition"; code-check.md "A proxy is not the property" (the guard tests selection, a proxy for drawn extent); code-check.md "Verification that reads its own output" (the guard re-asks the query's own `ST_Intersects`, so it cannot fail on today's data unless the margin changes).

## (a) The two fixes

1. **Map caption.** The new wording does cover the thin streams: drawn ⊆ order ≥ 5, and every stream touches the box and overshoots it by at most 0.41 km. It does not cover two of the 19 lakes (the finding above). The guard is a selection test. It does fire in the direction that matters if `data-raw/station_vignette_map.R` ever widens its margin, so it is not useless. But it does not test the extent the sentence describes. The fix introduced no failure: the guard passes on the bundle (`TRUE TRUE`), and the chunk renders.
2. **Software line.** This one is correct. `cd::cd_trend()` calls `Kendall::MannKendall(y)` and `zyp::zyp.sen(y ~ yr, …)` (checked in the installed cd), and the Kendall entry's title in the .bib names the Mann–Kendall trend test. Clean.

## (b) Mechanism

Round 3 named it this way: a guard, or the author's check, tests membership in one direction (what is drawn is in the class) while the sentence names another set (the class in the frame is drawn). The instance in front of the author stands in for the set.

The fix repeats it one axis over. The new guard proves each drawn feature *was selected* near the catchments. The sentence claims each is *drawn* only near them. For lines, selection and drawn extent nearly coincide. For lakes drawn whole they do not, and the instance in front of the author (the streams, whose cut ends round 3 measured) stood in for both layers.

`git diff 49e8387 b88d7f0` changes only the caption string, the guard and its comment, and the software bullet. Every other sentence and guard is byte-identical, so no other row of round 3's enumeration moved. The caption's later clauses (Houston labelled, the bar, the inset) only moved into a new sentence, with unchanged content and the same guards (`pl_lab`, `sb_km`, the keymap). No round-3 "covers" row falls under the mechanism after these edits, except the reworded caption row itself (the finding).

## (c) Rendered page

docs/articles/flow-departure-normal.html (gitignored; written 10:26 PDT, the minute of b88d7f0's commit; the branch has nothing after b88d7f0) carries both fixes:
- the figure alt text and caption read "…and lakes of 100 ha and up (blue) are drawn only near the catchments. Houston is labelled, the bar is 30 km…";
- the software list reads "…for the trend test and … for the slope.";
- "trend tests" occurs 0 times.
