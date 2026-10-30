# Review: soul#578 pass, round 2 (diff 1eef882..HEAD, vignettes/segment-discharge.Rmd), terminating enumeration

## Checklist read

- code-check.md, `## Mechanisms`: the prose of all fourteen H3s, read in full with their evidence tables stripped. Also read in full: "An assertion that matches an interpolated value cannot see the claim around it" (Rules that stand alone), because this diff is mostly guards beside printed sentences.
- code-check-r.md, full sections: "Moving prose into a code chunk hides it from tools that scan the document" (the footnote's two citations sit in a chunk; no citation scanner reads this article, and the word-count chunk counts body prose only, so it does not apply), "A duplicate knitr chunk label fails the build" (the render passes; my probe chunk had a fresh label), and "`[[` on a named ATOMIC vector with an absent key is an error" (`n_src[["wet_balance"]]`: the key is present).
- code-check-shell.md, code-check-spatial.md: index only. In the spatial index, "A raster's drawn footprint is its valid data, not its extent" is the nearest relative of finding 1 below: the drawn frame is not the data's extent.

## What was run

- Rendered a copy of `vignettes/` in `/private/tmp/claude-501/-Users-airvine-Projects-repo-wet/99f143d4-a2fa-4b85-b39e-43bfe4806845/scratchpad/r2.fyu43m/`, with a final chunk that saves the environment. It renders, every `stopifnot()` passes, and the word cap holds. The four anchors (`ref-chapman2018`, `ref-gottesfeld2007`, `ref-moriasi2007`, `ref-nash1970`) each have exactly one `id=` and at least one `href="#..."`, and the footnote links render as real `<a>` tags.
- Probes on the saved environment, plus one read-only query against the local fwapg (`vd_connect()`). The query asked for streams of order 5 and up that fall inside the article's Bulkley map frame (`bb`) and are not in `bmap$streams`.
- Read `inst/vignette-data/life_history_bulk.csv` and `life_history_morr.csv`, `vignettes/articles/flow-change-sparse-gauges.Rmd:320-326`, and the #126 archive's quote of p. 355 (`planning/archive/2026-10-issue-126-chinook-sites/review-final-round.md:6`).

## Enumeration

Every factual claim the diff adds or changes, in order.

| line | claim | support | verdict |
|---|---|---|---|
| 144-145 | (guard comment) almost every segment has a value, and the balance covers almost all of BC (the prose at "It covers almost all of BC") | `neither` is 7.6 % of 4,907,441 segments (guard < 10 %); the balance is on 4,529,939, or 92.3 % (guard > 90 %). This counts segments, which stand in for area; the segments without the balance are mostly connectors and secondary channels, spread across the province rather than one region | SUPPORTED |
| 212 | "after Chapman et al. ([2018](#ref-chapman2018))" | the anchor resolves to the References entry (DOI, and the PDF that used to be linked inline) | SUPPORTED |
| 284 | province caption: "Labels name the Liard and the Nechako Reservoir" | `setequal(map$regions$name, ...)` guard; `lab` is built from `map$regions` | SUPPORTED |
| 284 | "the scale bar is %d km" (600) | `sb_bc_km` is the value the plot draws and labels | DEFINITIONAL |
| 391-394 | (guard comment) the windows' one source; the fry-migration row's citation carried over from another area's row | `unique(ch$source)` is G&R; the note reads "citation listed under the other area in the template"; MORR's CH `outmigration` row carries `gottesfeld_rabnett2007SkeenaFish` | SUPPORTED |
| 521-522 | "The Bulkley River and Buck Creek are drawn heavier" | `setequal(main_streams$gnis_name, ...)`; line width 0.8 against 0.3 | SUPPORTED |
| 522 | "than the other streams of order 5 and up" | the guard checks only that each drawn non-main stream is order 5 or more (81, 15, 7 and 2 of orders 5 to 8). It does not check that every order-5+ stream in view is drawn, and not all are: **38 blue lines, 381 km of order-5+ stream inside the frame, are missing** (about 17 % of the order-5+ length in view), all in the map's margins | FALSE-OR-OVERSTATED |
| 522 | "lakes" | 64 lakes drawn; the caption claims no completeness (the same margin gap applies) | DEFINITIONAL |
| 522-523 | "the towns of Houston and Telkwa" | `setequal(bmap$places$name, ...)` guard | SUPPORTED |
| 523 | "a %d km scale bar" (60) | `sb_km` is drawn and labelled | DEFINITIONAL |
| 523 | "a keymap (upper left) marking the map's extent in BC" | `annotation_custom()` in the upper left; its rectangle is `bb` | DEFINITIONAL |
| 537 | "The Bulkley River, in west-central BC" | a geographic fact, which the keymap shows | DATA-TRUE-UNGUARDED (same class as the accepted Hazelton line) |
| 537-538 | "flows north-west from Houston past Telkwa" | guard: Quick is 11.4 km west and 24.6 km north of the Houston gauge; Telkwa is 25.6 km west and 33.6 km north of Houston. That Telkwa sits on the river is not guarded, but the map draws it there | SUPPORTED |
| 538 | "to join the Skeena at Hazelton" | accepted tradeoff | (not re-flagged) |
| 538-539 | "Three gauges in its basin sit one inside the next" | `inside()` > 0.99 for both pairs | SUPPORTED |
| 546-549 | the windows' dates (May 1 to Aug 1, Aug 1 to Sep 15, Jul 15 to Sep 7) | inline `span_of()` from the CSV | DEFINITIONAL |
| 549-550 | "the dates New Graph's species-timing table sets for the Bulkley" | `lh` is read from `life_history_bulk.csv` | DEFINITIONAL |
| 550 | "from Gottesfeld and Rabnett (2007)" | `unique(ch$source)` guard | SUPPORTED |
| 550-552 | "who give the early run passing Moricetown Canyon before about July 30 and spawning in August and September (p. 355)" | says no more than the sibling article at 320-323. It drops the sibling's "In the upper Bulkley River" but names no wider place. The page reads "split at the Moricetown Canyon fishways at about July 30" and "Chinook spawn in August and September throughout the system" | SUPPORTED |
| 552-553 | "the fry-migration row's citation is carried over from another area's" | the CSV note plus the `grepl("other area")` guard; MORR's row is the other area's | SUPPORTED |
| 891-892 | "a misplaced outlet changes one gauge's flow" | accepted tradeoff (reasoning) | (not re-flagged) |
| 892 | "not the season at most of them" | each half is guarded at more than 50 % (spring low at 65.9 %, summer high at 67.7 %, 279 gauges). The season the bullet defines, low in March to May **and** high in July and August, holds at only **128 of 279 (45.9 %)**, and nothing guards that | FALSE-OR-OVERSTATED (on the natural reading; true per half only) |
| 854-856 | footnote: "(Nash and Sutcliffe 1970)" and "Ratings follow Moriasi and others (2007)", now links | the anchors resolve; `escape = FALSE` renders real links; the bands are unchanged | SUPPORTED |
| 1004 | "What is a window?" link removed | no claim added; the windows are defined at 546 | (no claim) |
| 1120-1146 | Data list, ten bullets | each repeats the old paragraph's claim, regrouped; nothing is added. "Chinook windows: New Graph's species-timing table, from G&R (2007)" is the same claim as rows 549-550, with the fry caveat in the prose. "Place names: BC Geographic Names" holds for the towns (`vm_places()` reads `GNS_GEOGRAPHICAL_NAMES_SP`); this is unchanged from before | SUPPORTED |
| 1150-1170 | References, four entries | all four are cited; Gottesfeld matches the sibling's entry, and Chapman, Moriasi and Nash keep the old DOIs | SUPPORTED |

Counts: 14 SUPPORTED, 6 DEFINITIONAL, 1 DATA-TRUE-UNGUARDED, 2 FALSE-OR-OVERSTATED (2 accepted tradeoffs and 1 removal with no claim are not counted).

## Findings

- **[severity: bug]** vignettes/segment-discharge.Rmd:522 (guard at 527) — "drawn heavier than the other streams of order 5 and up" claims a set wider than what the map draws. The streams and lakes come from `vm_extent(catch, 8000)` in `data-raw/monthly_vignette_map.R:37-39`: the catchments' bounding box plus 8 km. The article's frame is drawn wider (lines 480-483). It is the catchments plus 3 km, then 20 % of the height added below, then widened to the aspect. So 26 % of the frame lies outside the area anything was fetched from: about 12 km on the west and east and 23 km on the south. Measured against fwapg, 38 blue lines (381 km in view) of order 5 and up fall in those margins and are not drawn. Overlaying them on the article's map shows them along the left and right edges and across the lower right around the scale bar, where the map reads as empty land. The new guard tests the drawn subset (`all(stream_order >= 5)`), the narrower half: it cannot see a missing stream. This is the mechanism again, with a set in place of a number. Fixes, either way: fetch over the drawn frame (build `bb` the same way in the data script, or fetch with a margin that covers it, and regenerate `monthly_map.rds`), then have the bundle carry the fetch extent and guard `bb` inside it. Or reword the caption to what is drawn ("the other streams of order 5 and up that reach within 8 km of the catchments"). The first is the real fix; the lakes have the same gap.
- **[severity: fragile]** vignettes/segment-discharge.Rmd:892 (guard at 818) — "not the season at most of them" was round 1's prescribed wording, and it now runs past its guard in a different way. The bullet defines the season as both halves: low in March to May and high in July and August, "as if its melt started late and ran on". That pattern holds at 128 of 279 gauges (45.9 %), not most. Only each half alone holds at most (65.9 % and 67.7 %), which is what the guard and the sentence before it say. "The season" folds the two halves back into one. Suggested wording, which keeps the argument and matches the guard: "...a misplaced outlet changes one gauge's flow; it would not lower the spring at most gauges and raise the summer at most of them." Alternatively, keep the sentence and say "each half of the season".
