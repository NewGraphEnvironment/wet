# Review: soul#578 pass, round 1 (diff 1eef882..8b7968f, vignettes/segment-discharge.Rmd)

## Checklist read

- code-check.md, `## Mechanisms`: the prose of "A guard that fails toward pass" and "A fixture that cannot reach the failure mode" read in full; the other twelve H3s by heading and first sentence (index).
- code-check-r.md, full sections: "Moving prose into a code chunk hides it from tools that scan the document" (the footnote's citations sit in a chunk; no bib scanner is in use, so it does not apply), "A duplicate knitr chunk label fails the build" (ran the grep: no duplicates), "`[[` on a named ATOMIC vector with an absent key is an error" (`n_src[["wet_balance"]]`: the key is present).
- code-check-spatial.md, full section: "A Freshwater Atlas main stem's downstream end lies on the receiving river's centreline" (orientation guard uses gauge and place points, not stem ends, so it does not apply).

## What was run

- Rendered a copy (`rmarkdown::render()` in a scratch dir, installed bundles): renders, every `stopifnot()` passes, and the word cap holds.
- Rendered HTML: `ref-chapman2018`, `ref-gottesfeld2007`, `ref-moriasi2007`, `ref-nash1970` each have exactly one `id=` and one or more `href="#..."`; no duplicate ids anywhere. The kableExtra footnote with `escape = FALSE` emits real `<a href="#ref-nash1970">` and `<a href="#ref-moriasi2007">` links.
- Data: the balance covers 4,529,939 of 4,907,441 segments (92.3 %, guard > 90 %). In the Bulkley map every drawn stream has order 5 to 8 (82 + 15 + 7 + 3), Buck Creek included. Places are Houston and Telkwa; regions are Liard and Nechako Reservoir; 64 lakes drawn.
- Chinook: the CSV's three rows all carry `gottesfeld_rabnett2007SkeenaFish`; the fry_migration note says "citation listed under the other area in the template", which the guard matches and the prose paraphrases correctly. The p. 355 content matches the sibling article's lines 320–323 and soul#578 item 2. I did not check the report itself.

## Findings

- **[severity: bug]** vignettes/segment-discharge.Rmd:888–891 — The new reason claims more than the numbers in the same sentence show. The sentence gives the spring half at 66 % of gauges and the summer half at 68 %, and soul#578 notes that both halves together hold at 46 %. Then it says "a misplaced outlet changes one gauge's size, not the season at all of them". "At all of them" says the seasonal shift appears at every gauge, but the article's own figures show it at about two thirds, and both halves together at under half. No guard covers "all", and the data contradicts it. This is the soul#578 rule-1 shape: a reworded sentence whose guard (`mean(g_low) > 0.5`, `mean(g_high) > 0.5`) still tests "most". Suggested wording: "...not the season at most of them". Separately, the mechanism ("changes one gauge's size") is stated with no guard. That is acceptable as reasoning, but it is the only support for "the model's, not the placement's".
- **[severity: fragile]** vignettes/segment-discharge.Rmd:521–526 — The Bulkley caption hard-codes "the other streams of order 5 and up", and no guard checks it. The new `stopifnot()` covers the two heavier streams' names and the places, but not the order of the others. It is true today: the minimum drawn order is 5. But the order comes from `vm_streams(min_order = 5)` in `scripts/vignette_map_lib.R`, which this article never reads. The province caption takes its order from `mp$min_order`, but this one is typed. A guard such as `stopifnot(all(bmap$streams$stream_order >= 5))`, or taking the number from the data, would cover what the caption says.

Nothing else found: the anchors resolve, the captions name what the code draws (province map: rivers by source and order, gauges, the two labels, scale bar; Bulkley map: catchments, gauges and labels, heavier main streams, other streams, lakes, towns, scale bar, keymap upper left), the orientation guard holds on the bundled coordinates, the "What is a window?" link is gone with no other sibling-article reference left in prose, and the Data and References lists render as lists.
