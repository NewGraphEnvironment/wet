# Findings — Segment discharge article: reorder for readers, define terms, recommend an estimate, map every named gauge (#39)

## Issue context

**If we do it:** a reader who has never heard of fwapg or PCIC can open the article, find out what mean annual discharge is, how far to trust a segment's number, and which estimate to use, and see every gauge the text names on a map. **If we never do:** the article stays a developer's validation report. Its main finding, how good the numbers are and which to use, sits in the second-to-last section behind undefined terms, and the article never makes a recommendation.

## Problem

`vignettes/segment-discharge.Rmd` (#28) is accurate, but it is ordered for the people who built it:

- It opens by proving that wet reproduces fwapg. That matters only to someone who already knows what fwapg is, and a sentence would carry it as well as the scatter plot does.
- Terms are never defined or linked: fwapg, PCIC, VIC-GL, HYDAT, the Freshwater Atlas, watershed group, stream order, sub-sub-drainage, held out, blocked cross-validation, nested.
- Runoff in mm/yr and discharge in m³/s appear side by side with nothing to connect them.
- Error is shown three ways: % over/under in the table, a log ratio relabelled as % in the skill plot, and four classes on the Bulkley map.
- The Salmon River comparison, which holds the main finding, is one dense paragraph. Four of the five gauges in its table lie outside the map's frame.
- It shows that the two estimates disagree, but never says which to use.

## Proposed Solution

Keep it as one article, reordered around the reader's questions. Longer is fine where definitions or figures need the room.

1. **What mean annual discharge is.** Use a worked unit example (a 100 km² basin at 300 mm/yr carries about 0.95 m³/s). Define every term where it first appears, and link to its source (fwapg, PCIC hydrologic model output, HYDAT, the Freshwater Atlas, Chapman et al. 2018).
2. **Which estimate to use, as a recommendation.** Use wet's open water balance everywhere, with fwapg/PCIC as a yardstick where it exists. This follows the repo rule that we publish our own open estimate and score others' products against it and HYDAT. The recommendation rests on both products scored at the same gauges: the balance's held-out error and fwapg's error at every calibration gauge inside PCIC's coverage (Peace, Fraser, Columbia).
3. **How good it is.** Lead with a plain sentence. Show a province map of the calibration gauges coloured by held-out error, with the outlier zone visible, alongside one error scale used throughout.
4. **The Salmon River and Bulkley as maps that tell the story.** Every gauge the text or a table names appears on its map, labelled. Salmon River: the two products side by side, or their ratio, with the nearby gauges in frame. Bulkley: the balance with its gauges, plus a worked example of one segment against its gauge.
5. **Limits, ordered by what affects a user.**
6. **How it is built, at the end.** The fwapg match in one sentence (no scatter plot), the sampling change, and the recipe.

The 800-word cap on body prose is raised to fit, and the data checks that tie each prose claim to the data stay.


## Re-verified 2026-10-06 at this gate

- 186 of the 290 calibration gauges sit in 07E/07F/08J–08M/08N (the draft said about 185).
- `inst/vignette-data/segment_{values,map}.rds` total 427 KB of the 500 KB budget; `data/wb/` and `data/parity/` are present on m1.
- The fwapg join is at `data-raw/segment_vignette_data.R:139-145`; the word cap is at `vignettes/segment-discharge.Rmd:451`.


## Pre-set recommendation rule (recorded 2026-10-06, before any scoring)

Recommendation to be written: use wet's open water balance everywhere; fwapg/PCIC is a yardstick where it exists.

Scored at the calibration gauges inside PCIC's coverage (those with a fwapg `mad_mm` at the gauge's fundamental watershed), using the same HYDAT observed mean annual runoff (`skill$obs`) for both products:

- balance error = the blocked-CV held-out `err_pct` already in `skill`;
- fwapg error = 100 * (fwapg_mm / obs - 1), same sign convention.

**Rule:** if the balance's mean absolute error at those gauges is more than 5 percentage points worse than fwapg's, stop and bring the evidence to the user before writing the recommendation. Otherwise write it as above. Either way the article says the balance's error is out of sample and fwapg's may be partly in sample (PCIC calibrates VIC-GL to gauges).

## Errors Encountered

| Error | Resolution |
|-------|------------|
